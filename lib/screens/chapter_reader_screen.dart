import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comic.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/reading_history_service.dart';
import '../services/chapter_comment_service.dart';
import 'chapter_comments_screen.dart';

class ChapterReaderScreen extends StatefulWidget {
  const ChapterReaderScreen({
    super.key,
    required this.comic,
    required this.chapter,
    required this.profile,
  });

  final Comic comic;
  final ChapterMeta chapter;
  final UserProfile profile;

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showAppBar = true;

  @override
  void initState() {
    super.initState();
    // Lưu lịch sử đọc ngay khi mở chapter
    _saveReadingHistory();
  }

  Future<void> _saveReadingHistory() async {
    await ReadingHistoryService.instance.saveHistory(
      userId: widget.profile.id,
      comicId: widget.comic.id,
      chapterId: widget.chapter.id,
      chapterTitle: widget.chapter.title,
      chapterOrder: widget.chapter.order,
    );
  }

  Stream<int> _getCommentCountStream() {
    return ChapterCommentService.instance
        .getChapterComments(
          comicId: widget.comic.id,
          chapterId: widget.chapter.id,
        )
        .map((snapshot) => snapshot.docs.length);
  }

  void _openComments() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChapterCommentsScreen(
          comic: widget.comic,
          chapter: widget.chapter,
          profile: widget.profile,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showAppBar
          ? AppBar(
              title: Text(widget.chapter.title),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: _showChapterList,
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showAppBar = !_showAppBar;
          });
        },
        child: widget.chapter.pages.isEmpty
            ? const Center(
                child: Text(
                  'Chapter chưa có hình ảnh',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                itemCount: widget.chapter.pages.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    widget.chapter.pages[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 400,
                        color: Colors.grey[900],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 400,
                        color: Colors.grey[900],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.white54,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Không thể tải hình',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
      bottomNavigationBar: _showAppBar ? _buildBottomBar() : null,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: StreamBuilder<QuerySnapshot<ChapterMeta>>(
        stream: FirestoreService.instance
            .chapters(widget.comic.id)
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(height: 50);
          }

          final chapters = snapshot.data!.docs
              .map((doc) => doc.data())
              .toList();
          final currentIndex = chapters.indexWhere(
            (ch) => ch.id == widget.chapter.id,
          );

          final hasPrevious = currentIndex > 0;
          final hasNext = currentIndex < chapters.length - 1;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Comment button
              StreamBuilder<int>(
                stream: _getCommentCountStream(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return IconButton(
                    icon: Badge(
                      label: count > 0 ? Text('$count') : null,
                      isLabelVisible: count > 0,
                      child: const Icon(Icons.chat_bubble_outline),
                    ),
                    onPressed: _openComments,
                    color: Colors.white,
                    tooltip: 'Bình luận',
                  );
                },
              ),
              // Previous button
              ElevatedButton.icon(
                onPressed: hasPrevious
                    ? () {
                        final prevChapter = chapters[currentIndex - 1];
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => ChapterReaderScreen(
                              comic: widget.comic,
                              chapter: prevChapter,
                              profile: widget.profile,
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Trước'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[900],
                  disabledForegroundColor: Colors.grey[600],
                ),
              ),
              // Chapter info
              Text(
                'Chapter ${widget.chapter.order}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Next button
              ElevatedButton.icon(
                onPressed: hasNext
                    ? () {
                        final nextChapter = chapters[currentIndex + 1];
                        final canRead =
                            nextChapter.vipRequired == 0 ||
                            widget.profile.vipLevel >= nextChapter.vipRequired;

                        if (canRead) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => ChapterReaderScreen(
                                comic: widget.comic,
                                chapter: nextChapter,
                                profile: widget.profile,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Cần VIP Level ${nextChapter.vipRequired} để đọc chapter tiếp theo',
                              ),
                            ),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Tiếp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[900],
                  disabledForegroundColor: Colors.grey[600],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChapterList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return StreamBuilder<QuerySnapshot<ChapterMeta>>(
          stream: FirestoreService.instance
              .chapters(widget.comic.id)
              .orderBy('order', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final chapters = snapshot.data!.docs
                .map((doc) => doc.data())
                .toList();

            return ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final isCurrent = chapter.id == widget.chapter.id;
                final canRead =
                    chapter.vipRequired == 0 ||
                    widget.profile.vipLevel >= chapter.vipRequired;

                return ListTile(
                  selected: isCurrent,
                  selectedTileColor: Colors.blue.withOpacity(0.2),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: chapter.vipRequired == 0
                          ? Colors.green
                          : Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        chapter.vipRequired == 0 ? 'FREE' : 'VIP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    chapter.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: canRead
                      ? const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.white,
                        )
                      : const Icon(Icons.lock, size: 16, color: Colors.white54),
                  onTap: canRead
                      ? () {
                          Navigator.of(context).pop();
                          if (!isCurrent) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => ChapterReaderScreen(
                                  comic: widget.comic,
                                  chapter: chapter,
                                  profile: widget.profile,
                                ),
                              ),
                            );
                          }
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Cần VIP Level ${chapter.vipRequired} để đọc chapter này',
                              ),
                            ),
                          );
                        },
                );
              },
            );
          },
        );
      },
    );
  }
}
