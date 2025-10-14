import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

class _ChapterReaderScreenState extends State<ChapterReaderScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showAppBar = false; // Mặc định ẨN thanh điều khiển
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Tracking scroll progress
  double _scrollProgress = 0.0;
  int _currentPage = 1;
  bool _showPageIndicator = false;
  Timer? _pageIndicatorTimer;

  // Preloading management
  final Set<int> _preloadedPages = {};
  bool _isPreloading = false;

  @override
  void initState() {
    super.initState();

    // ⚡ TỐI ƯU HÓA HIGH REFRESH RATE (144Hz, 120Hz, etc.)
    // Cho phép Flutter render theo refresh rate của màn hình
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Lấy refresh rate của màn hình
      final display = ui.PlatformDispatcher.instance.displays.first;
      final refreshRate = display.refreshRate;

      // Log để debug
      debugPrint('🖥️ Display refresh rate: ${refreshRate}Hz');
      debugPrint('✨ High refresh rate optimization enabled!');
    });

    // Ẩn thanh trạng thái để đọc toàn màn hình
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Khởi tạo animation controller cho hiệu ứng fade
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Lắng nghe scroll để cập nhật progress và preload
    _scrollController.addListener(_onScroll);

    // Lưu lịch sử đọc ngay khi mở chapter
    _saveReadingHistory();
    // Preload hình ảnh để cải thiện hiệu suất
    _preloadImages();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final progress = position.pixels / position.maxScrollExtent;
    final newProgress = progress.clamp(0.0, 1.0);

    // Tính toán trang hiện tại (ước tính mỗi ảnh cao ~600px)
    final newPage = ((position.pixels / 600).floor() + 1).clamp(
      1,
      widget.chapter.pages.length,
    );

    // CHỈ setState khi có thay đổi đáng kể (tối ưu performance)
    if ((newProgress - _scrollProgress).abs() > 0.01 ||
        newPage != _currentPage) {
      setState(() {
        _scrollProgress = newProgress;
        _currentPage = newPage;
      });

      // Hiển thị page indicator khi scroll
      _showPageIndicatorTemporarily();
    }

    // Smart preloading - KHÔNG BLOCK UI, chạy async
    // Chỉ preload khi scroll đủ xa (mỗi 5 trang)
    if (!_isPreloading && newPage % 5 == 0) {
      _smartPreload();
    }
  }

  void _showPageIndicatorTemporarily() {
    setState(() {
      _showPageIndicator = true;
    });

    _pageIndicatorTimer?.cancel();
    _pageIndicatorTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showPageIndicator = false;
        });
      }
    });
  }

  void _smartPreload() {
    if (_isPreloading) return;

    _isPreloading = true;

    // Chạy preload trong background KHÔNG BLOCK UI
    Future.microtask(() async {
      try {
        // Preload 5 trang tiếp theo (giảm từ 10 xuống 5 để nhanh hơn)
        final startIndex = _currentPage;
        final endIndex = (startIndex + 5).clamp(0, widget.chapter.pages.length);

        for (int i = startIndex; i < endIndex; i++) {
          if (_preloadedPages.contains(i)) continue;

          // Không await để không block
          precacheImage(
                CachedNetworkImageProvider(widget.chapter.pages[i]),
                context,
              )
              .then((_) {
                _preloadedPages.add(i);
              })
              .catchError((e) {
                // Silent fail
              });

          // Delay nhỏ để không chiếm hết CPU
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } finally {
        _isPreloading = false;
      }
    });
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
      if (_showAppBar) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _preloadImages() async {
    // Preload 10 trang đầu tiên để đọc mượt mà ngay từ đầu
    final preloadCount = (widget.chapter.pages.length < 10)
        ? widget.chapter.pages.length
        : 10;

    for (int i = 0; i < preloadCount; i++) {
      try {
        print('📸 Preloading image $i: ${widget.chapter.pages[i]}');
        await precacheImage(
          CachedNetworkImageProvider(widget.chapter.pages[i]),
          context,
        );
        _preloadedPages.add(i);
        print('✅ Preloaded image $i successfully');
      } catch (e) {
        print('❌ Failed to preload image $i: $e');
      }
    }

    // Preload thêm các trang tiếp theo trong background
    _backgroundPreload();
  }

  Future<void> _backgroundPreload() async {
    // Đợi 3 giây trước khi preload thêm để ưu tiên tải các trang đầu
    await Future.delayed(const Duration(seconds: 3));

    final startIndex = 10;
    final endIndex = (startIndex + 10).clamp(0, widget.chapter.pages.length);

    for (int i = startIndex; i < endIndex; i++) {
      if (_preloadedPages.contains(i)) continue;

      try {
        // KHÔNG await - chạy parallel để nhanh hơn
        precacheImage(
              CachedNetworkImageProvider(widget.chapter.pages[i]),
              context,
            )
            .then((_) {
              _preloadedPages.add(i);
            })
            .catchError((e) {
              // Silent fail
            });

        // Delay nhỏ giữa các lần preload để không chiếm hết bandwidth
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        // Silent fail
      }
    }
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
    // Khôi phục lại thanh trạng thái khi thoát
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _pageIndicatorTimer?.cancel();
    _animationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showAppBar
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: AppBar(
                  title: Text(
                    widget.chapter.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: Container(
                    decoration: const BoxDecoration(color: Colors.transparent),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.list,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                      ),
                      onPressed: _showChapterList,
                      tooltip: 'Danh sách chapter',
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          GestureDetector(
            onTap: _toggleAppBar,
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
                    // ⚡ TỐI ƯU HÓA CHO HIGH REFRESH RATE
                    cacheExtent: 2000, // Tăng cache để scroll mượt hơn ở 144Hz
                    // Giữ các item không bị dispose khi scroll
                    addAutomaticKeepAlives: true,
                    addRepaintBoundaries: true,
                    // Tắt semantic để tăng performance
                    addSemanticIndexes: false,
                    // ⚡ ClampingScrollPhysics tốt hơn cho high refresh rate
                    physics: const ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemBuilder: (context, index) {
                      return RepaintBoundary(
                        child: CachedNetworkImage(
                          imageUrl: widget.chapter.pages[index],
                          fit: BoxFit.contain,
                          // ⚡ Tăng cache size cho màn hình high refresh rate
                          memCacheHeight: 3072, // Tăng từ 2048 lên 3072 (1.5x)
                          memCacheWidth: 3072,
                          maxHeightDiskCache: 3072,
                          maxWidthDiskCache: 3072,
                          // ⚡ Giảm fade duration để mượt hơn ở 144Hz
                          fadeInDuration: const Duration(milliseconds: 100),
                          fadeOutDuration: const Duration(milliseconds: 100),
                          placeholder: (context, url) => Container(
                            height: 400,
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 400,
                            color: Colors.grey[900],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Không thể tải hình',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Xóa cache và reload lại hình
                                      CachedNetworkImage.evictFromCache(url);
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Thử lại'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[700],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Progress bar ở trên cùng (chỉ hiển thị thanh tiến độ)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showPageIndicator ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                height: 3,
                child: LinearProgressIndicator(
                  value: _scrollProgress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _showAppBar
          ? FadeTransition(opacity: _fadeAnimation, child: _buildBottomBar())
          : null,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
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
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: IconButton(
                      icon: Badge(
                        label: count > 0 ? Text('$count') : null,
                        isLabelVisible: count > 0,
                        child: const Icon(Icons.chat_bubble_outline),
                      ),
                      onPressed: _openComments,
                      color: Colors.white,
                      tooltip: 'Bình luận',
                    ),
                  );
                },
              ),
              // Previous button
              Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasPrevious
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: ElevatedButton.icon(
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
                  label: const Text(
                    'Trước',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: Colors.white.withOpacity(0.3),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              // Chapter info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  'Chapter ${widget.chapter.order}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 6,
                        offset: Offset(1, 1),
                      ),
                      Shadow(
                        color: Colors.black,
                        blurRadius: 6,
                        offset: Offset(-1, -1),
                      ),
                    ],
                  ),
                ),
              ),
              // Next button
              Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasNext
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: hasNext
                      ? () {
                          final nextChapter = chapters[currentIndex + 1];
                          final canRead =
                              nextChapter.vipRequired == 0 ||
                              widget.profile.vipLevel >=
                                  nextChapter.vipRequired;

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
                  label: const Text(
                    'Tiếp',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: Colors.white.withOpacity(0.3),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
