import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/comic.dart';
import '../models/comic_review.dart';
import '../models/user_profile.dart';
import '../models/chapter_comment.dart';
import '../services/firestore_service.dart';
import '../services/reading_history_service.dart';
import '../widgets/comic_rating_widget.dart';
import '../widgets/user_name_display.dart';
import 'chapter_reader_screen.dart';
import 'admin_edit_comic_screen.dart';
import 'admin_manage_chapters_screen.dart';
import 'write_review_screen.dart';
import 'chapter_comments_screen.dart';

class ComicDetailScreen extends StatefulWidget {
  const ComicDetailScreen({
    super.key,
    required this.comic,
    required this.profile,
  });

  final Comic comic;
  final UserProfile profile;

  @override
  State<ComicDetailScreen> createState() => _ComicDetailScreenState();
}

class _ComicDetailScreenState extends State<ComicDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDescriptionExpanded = false;
  late String _comicId;
  bool _isFollowing = false;
  bool _isLoadingFollow = true;
  int _followerCount = 0;
  bool _followerCountLoaded = false;
  ReadingHistory? _readingHistory;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _comicId = widget.comic.id;
    // Tăng lượt xem
    _incrementViews();
    // Kiểm tra trạng thái theo dõi
    _checkFollowingStatus();
    // Load số lượng followers
    _loadFollowerCount();
    // Load lịch sử đọc
    _loadReadingHistory();
  }

  Future<void> _loadReadingHistory() async {
    final history = await ReadingHistoryService.instance.getHistory(
      userId: widget.profile.id,
      comicId: _comicId,
    );
    if (mounted) {
      setState(() {
        _readingHistory = history;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _loadFollowerCount() async {
    final count = await _getFollowerCount(_comicId);
    if (mounted) {
      setState(() {
        _followerCount = count;
        _followerCountLoaded = true;
      });
    }
  }

  Future<void> _incrementViews() async {
    try {
      await FirestoreService.instance.incrementComicViews(_comicId);
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _checkFollowingStatus() async {
    try {
      final isFollowing = await FirestoreService.instance.isFollowing(
        userId: widget.profile.id,
        comicId: _comicId,
      );
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _isLoadingFollow = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFollow = false;
        });
      }
    }
  }

  Future<int> _getFollowerCount(String comicId) async {
    try {
      // Đếm số user có favorites chứa comicId này
      // NOTE: Field name phải khớp với field trong Firestore (favorites, không phải followedComics)
      final snapshot = await FirestoreService.instance.users
          .where('favorites', arrayContains: comicId)
          .get();

      debugPrint('🔍 Follower count for $comicId: ${snapshot.docs.length}');
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Error getting follower count: $e');
      return 0;
    }
  }

  Future<void> _toggleFollow() async {
    setState(() {
      _isLoadingFollow = true;
    });

    try {
      final newStatus = await FirestoreService.instance.toggleFavorite(
        userId: widget.profile.id,
        comicId: _comicId,
      );

      if (mounted) {
        setState(() {
          _isFollowing = newStatus;
          _isLoadingFollow = false;
          // Cập nhật số lượng followers ngay lập tức
          if (newStatus) {
            _followerCount++;
          } else {
            _followerCount--;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'Đã thêm vào danh sách theo dõi'
                  : 'Đã xóa khỏi danh sách theo dõi',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFollow = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng StreamBuilder để tự động cập nhật khi có thay đổi
    return StreamBuilder<DocumentSnapshot<Comic>>(
      stream: FirestoreService.instance.comicRef(_comicId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Đang tải...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final comic = snapshot.data!.data()!;

        return Scaffold(
          appBar: AppBar(
            title: Text(comic.title),
            actions: [
              // Admin edit button
              if (widget.profile.isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminEditComicScreen(
                          comic: comic,
                          profile: widget.profile,
                        ),
                      ),
                    );
                    // Không cần setState, StreamBuilder sẽ tự động cập nhật
                  },
                  tooltip: 'Chỉnh sửa truyện',
                ),
              // Admin manage chapters button in header
              if (widget.profile.isAdmin)
                IconButton(
                  icon: const Icon(Icons.list_alt),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminManageChaptersScreen(
                          comic: comic,
                          profile: widget.profile,
                        ),
                      ),
                    );
                  },
                  tooltip: 'Quản lý Chapter',
                ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: Share functionality
                },
              ),
              IconButton(
                icon: const Icon(Icons.cloud_download),
                onPressed: () {
                  // TODO: Download functionality
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(comic),
                      _buildTabs(),
                      _buildTabContent(comic),
                    ],
                  ),
                ),
              ),
              _buildBottomButton(comic),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Comic comic) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: comic.coverUrl.isNotEmpty
                  ? Image.network(
                      comic.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 48),
                    )
                  : const Center(child: Icon(Icons.image, size: 48)),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comic.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: comic.tags.take(2).map((tag) {
                    return Chip(
                      label: Text(
                        '#$tag',
                        style: const TextStyle(fontSize: 12),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                // Stats
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _formatNumber(comic.views),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      _followerCountLoaded
                          ? _formatNumber(_followerCount)
                          : '...',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _isLoadingFollow
                          ? const Center(
                              child: SizedBox(
                                height: 36,
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: _toggleFollow,
                              icon: Icon(
                                _isFollowing
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                size: 18,
                              ),
                              label: Text(_isFollowing ? 'Đã lưu' : 'Lưu'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                backgroundColor: _isFollowing
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1)
                                    : null,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Share
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Chia sẻ'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Giới thiệu'),
          Tab(text: 'Danh sách chương'),
        ],
        onTap: (index) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildTabContent(Comic comic) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: _tabController.index == 0
          ? _buildIntroTab(comic)
          : _buildChaptersTab(comic),
    );
  }

  Widget _buildIntroTab(Comic comic) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge from source
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 16),
                SizedBox(width: 4),
                Text(
                  'Top Manhua',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Title
          const Text(
            'Giới thiệu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            comic.description,
            maxLines: _isDescriptionExpanded ? null : 3,
            overflow: _isDescriptionExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: const TextStyle(height: 1.5),
          ),
          if (comic.description.length > 100)
            TextButton(
              onPressed: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Text(_isDescriptionExpanded ? 'Thu gọn' : 'Đọc thêm'),
            ),
          const SizedBox(height: 16),
          // Rating section - Click to open full modal
          const Divider(),
          _buildRatingSection(comic),
          const SizedBox(height: 16),
          // Chapter comments section
          const Divider(),
          _buildChapterCommentsSection(comic),
        ],
      ),
    );
  }

  Widget _buildRatingSection(Comic comic) {
    return InkWell(
      onTap: () {
        _showRatingAndReviewsModal(comic);
      },
      child: ComicRatingWidget(
        comicId: comic.id,
        userId: widget.profile.id,
        onRated: () {
          // Widget tự reload khi rating thay đổi
        },
      ),
    );
  }

  Widget _buildChapterCommentsSection(Comic comic) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chapterComments')
          .where('comicId', isEqualTo: comic.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Lỗi: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Convert và sort trong code (KHÔNG CẦN INDEX PHỨC TẠP!)
        final allComments =
            snapshot.data!.docs
                .map(
                  (doc) => ChapterComment.fromFirestore(
                    doc as DocumentSnapshot<Map<String, dynamic>>,
                  ),
                )
                .toList()
              ..sort(
                (a, b) => b.createdAt.compareTo(a.createdAt),
              ); // Mới nhất trước

        final displayComments = allComments.take(3).toList(); // Show first 3

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bình luận chương (${allComments.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (allComments.length > 3)
                    TextButton(
                      onPressed: () => _showAllChapterCommentsModal(comic),
                      child: const Text('Xem tất cả'),
                    ),
                ],
              ),
            ),
            // Comments preview
            if (displayComments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Chưa có bình luận nào cho các chương',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...displayComments.map((comment) {
                return _buildChapterCommentPreviewItem(comic, comment);
              }),
          ],
        );
      },
    );
  }

  Widget _buildChapterCommentPreviewItem(Comic comic, ChapterComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  comment.userName.isNotEmpty
                      ? comment.userName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserNameDisplay(
                      userId: comment.userId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    FutureBuilder<String>(
                      future: _getChapterTitle(comic.id, comment.chapterId),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Đang tải...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Text(
                _formatTimeAgo(comment.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Comment content
          Text(
            comment.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          // Stats
          Row(
            children: [
              Icon(Icons.favorite, size: 14, color: Colors.red[300]),
              const SizedBox(width: 4),
              Text(
                '${comment.likes}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (comment.replies.isNotEmpty) ...[
                const SizedBox(width: 16),
                Icon(Icons.reply, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${comment.replies.length} phản hồi',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<String> _getChapterTitle(String comicId, String chapterId) async {
    try {
      final doc = await FirestoreService.instance
          .chapters(comicId)
          .doc(chapterId)
          .get();
      if (doc.exists) {
        return doc.data()?.title ?? 'Chapter không xác định';
      }
      return 'Chapter không tồn tại';
    } catch (e) {
      return 'Lỗi tải chapter';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  void _showAllChapterCommentsModal(Comic comic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Tất cả bình luận chương',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chapterComments')
                      .where('comicId', isEqualTo: comic.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Lỗi: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Sort trong code
                    final comments =
                        snapshot.data!.docs
                            .map(
                              (doc) => ChapterComment.fromFirestore(
                                doc as DocumentSnapshot<Map<String, dynamic>>,
                              ),
                            )
                            .toList()
                          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    if (comments.isEmpty) {
                      return const Center(child: Text('Chưa có bình luận nào'));
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return InkWell(
                          onTap: () async {
                            // Navigate to chapter and open comments
                            Navigator.pop(context); // Close modal

                            // Get chapter info
                            final chapterDoc = await FirestoreService.instance
                                .chapters(comic.id)
                                .doc(comment.chapterId)
                                .get();

                            if (chapterDoc.exists && mounted) {
                              final chapter = chapterDoc.data()!;

                              // Open chapter comments screen
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChapterCommentsScreen(
                                    comic: comic,
                                    chapter: chapter,
                                    profile: widget.profile,
                                  ),
                                ),
                              );
                            }
                          },
                          child: _buildChapterCommentPreviewItem(
                            comic,
                            comment,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show modal with rating details and reviews
  void _showRatingAndReviewsModal(Comic comic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Đánh giá',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the close button
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Full rating widget with stats
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ComicRatingWidget(
                          comicId: comic.id,
                          userId: widget.profile.id,
                          onRated: () {},
                        ),
                      ),
                      const Divider(thickness: 8),
                      // Reviews section
                      _buildReviewsSection(comic),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection(Comic comic) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.instance
          .reviews(comic.id)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Lỗi: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final reviews = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with write button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Bình luận (${reviews.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(context); // Close modal first
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WriteReviewScreen(
                            comic: comic,
                            profile: widget.profile,
                          ),
                        ),
                      );
                      if (result == true) {
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Viết đánh giá'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.pink.shade700,
                    ),
                  ),
                ],
              ),
            ),
            // Reviews list
            if (reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Chưa có đánh giá nào')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index].data() as ComicReview?;
                  return _buildReviewItem(review, reviews[index].id);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildChaptersTab(Comic comic) {
    return StreamBuilder<QuerySnapshot<ChapterMeta>>(
      stream: FirestoreService.instance
          .chapters(comic.id)
          .orderBy('order', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Lỗi: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final chapters = snapshot.data!.docs.map((doc) => doc.data()).toList();

        if (chapters.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Chưa có chapter nào')),
          );
        }

        return Column(
          children: [
            // Admin manage chapters button
            if (widget.profile.isAdmin)
              Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade400,
                      Colors.deepOrange.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminManageChaptersScreen(
                            comic: comic,
                            profile: widget.profile,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'QUẢN LÝ CHAPTER (ADMIN)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Chapter range buttons
            Padding(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Đảo chương ↓'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('200 - 220'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('150 - 200'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('100 - 150'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('50 - 100'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('0 - 50'),
                    ),
                  ],
                ),
              ),
            ),
            // Chapter list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                return _buildChapterItem(comic, chapters[index]);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildChapterItem(Comic comic, ChapterMeta chapter) {
    final bool isFree = chapter.vipRequired == 0;
    final bool canRead =
        isFree || widget.profile.vipLevel >= chapter.vipRequired;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isFree ? Colors.green : Colors.amber,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            isFree ? 'FREE' : 'VIP',
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
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        chapter.releaseAt != null
            ? DateFormat('HH:mm dd/MM/yyyy').format(chapter.releaseAt!)
            : '',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: canRead
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : const Icon(Icons.lock, size: 16),
      onTap: canRead
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChapterReaderScreen(
                    comic: comic,
                    chapter: chapter,
                    profile: widget.profile,
                  ),
                ),
              );
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
  }

  Widget _buildBottomButton(Comic comic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot<ChapterMeta>>(
        stream: FirestoreService.instance
            .chapters(comic.id)
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'CHƯA CÓ CHAPTER',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            );
          }

          final allChapters = snapshot.data!.docs;
          ChapterMeta? targetChapter;
          String buttonText;
          IconData buttonIcon;

          // Kiểm tra lịch sử đọc
          if (_readingHistory != null && !_isLoadingHistory) {
            // Tìm chapter đã đọc gần nhất
            final lastReadChapter = allChapters
                .where((doc) => doc.data().id == _readingHistory!.chapterId)
                .firstOrNull;

            if (lastReadChapter != null) {
              targetChapter = lastReadChapter.data();
              buttonText = 'TIẾP TỤC ĐỌC CHAP ${targetChapter.order}';
              buttonIcon = Icons.play_arrow;
            } else {
              // Chapter đã đọc không còn tồn tại → đọc từ đầu
              targetChapter = allChapters.first.data();
              buttonText = 'ĐỌC TỪ ĐẦU';
              buttonIcon = Icons.arrow_forward;
            }
          } else {
            // Chưa có lịch sử → đọc từ đầu
            targetChapter = allChapters.first.data();
            buttonText = 'ĐỌC TỪ ĐẦU';
            buttonIcon = Icons.arrow_forward;
          }

          return ElevatedButton(
            onPressed: () => _openChapter(comic, targetChapter!),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: _readingHistory != null
                  ? Colors.green.shade600
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(buttonIcon),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openChapter(Comic comic, ChapterMeta chapter) async {
    final canRead =
        chapter.vipRequired == 0 ||
        widget.profile.vipLevel >= chapter.vipRequired;

    if (!canRead) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cần VIP Level ${chapter.vipRequired} để đọc chapter này',
          ),
        ),
      );
      return;
    }

    // Navigate to chapter reader
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChapterReaderScreen(
          comic: comic,
          chapter: chapter,
          profile: widget.profile,
        ),
      ),
    );

    // Reload lịch sử sau khi đọc xong
    _loadReadingHistory();
  }

  Widget _buildReviewItem(ComicReview? review, String reviewId) {
    if (review == null) return const SizedBox.shrink();

    final rating = review.rating;
    final comment = review.comment;
    final userName = review.userName;
    final likes = review.likes;
    final createdAt = review.createdAt;
    final likedBy = review.likedBy;
    final isLiked = likedBy.contains(widget.profile.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Comment
          Text(comment, style: Theme.of(context).textTheme.bodyMedium),

          // Images if any
          if (review.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  itemBuilder: (context, index) {
                    final imageUrl = review.images[index];
                    return GestureDetector(
                      onTap: () {
                        // Show full image
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: InteractiveViewer(
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              InkWell(
                onTap: () async {
                  await FirestoreService.instance.toggleReviewLike(
                    comicId: _comicId,
                    reviewId: reviewId,
                    userId: widget.profile.id,
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 20,
                      color: isLiked ? Colors.blue : null,
                    ),
                    const SizedBox(width: 4),
                    Text('$likes'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (review.userId == widget.profile.id) ...[
                InkWell(
                  onTap: () {
                    // TODO: Edit review
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 4),
                      Text('Sửa'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xóa đánh giá'),
                        content: const Text(
                          'Bạn có chắc muốn xóa đánh giá này?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await FirestoreService.instance.deleteReview(
                        comicId: _comicId,
                        reviewId: reviewId,
                      );
                    }
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 4),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} năm trước';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }
}
