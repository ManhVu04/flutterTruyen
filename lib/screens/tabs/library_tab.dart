import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/comic.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../services/reading_history_service.dart';
import '../comic_detail_screen.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key, required this.user, required this.profile});

  final User user;
  final UserProfile profile;

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.bookmark), text: 'Theo dõi'),
              Tab(icon: Icon(Icons.access_time), text: 'Vừa xem'),
              Tab(icon: Icon(Icons.download), text: 'Đã tải'),
            ],
          ),
        ),
        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFollowingTab(),
              _buildHistoryTab(),
              _buildDownloadedTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowingTab() {
    return StreamBuilder<DocumentSnapshot<UserProfile>>(
      stream: FirestoreService.instance.users.doc(widget.user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = snapshot.data!.data()!;
        final favorites = profile.favorites;

        return favorites.isEmpty
            ? const Center(child: Text('Bạn chưa theo dõi truyện nào'))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  return _buildComicCardWithData(favorites[index], profile);
                },
              );
      },
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<Map<String, ReadingHistory>>(
      future: ReadingHistoryService.instance.getAllHistory(
        userId: widget.user.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final historyMap = snapshot.data!;

        if (historyMap.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có lịch sử đọc truyện',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hãy bắt đầu đọc truyện để lưu lịch sử',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                _buildSyncButton(),
              ],
            ),
          );
        }

        // Sắp xếp theo thời gian đọc gần nhất
        final sortedEntries = historyMap.entries.toList()
          ..sort((a, b) => b.value.lastReadAt.compareTo(a.value.lastReadAt));

        return Column(
          children: [
            // Header với nút đồng bộ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Lịch sử đọc truyện (${historyMap.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  _buildSyncButton(),
                ],
              ),
            ),
            // Danh sách truyện đã đọc
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: sortedEntries.length,
                itemBuilder: (context, index) {
                  final entry = sortedEntries[index];
                  final comicId = entry.key;
                  final history = entry.value;
                  return _buildHistoryCard(comicId, history);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSyncButton() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.cloud_sync,
        color: Theme.of(context).colorScheme.primary,
      ),
      tooltip: 'Đồng bộ lịch sử',
      onSelected: (value) async {
        switch (value) {
          case 'upload':
            await _syncToCloud();
            break;
          case 'download':
            await _loadFromCloud();
            break;
          case 'clear':
            await _clearCache();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'upload',
          child: Row(
            children: [
              Icon(Icons.cloud_upload, size: 20),
              SizedBox(width: 12),
              Text('Tải lên cloud'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'download',
          child: Row(
            children: [
              Icon(Icons.cloud_download, size: 20),
              SizedBox(width: 12),
              Text('Tải xuống từ cloud'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'clear',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Xóa cache', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(String comicId, ReadingHistory history) {
    return FutureBuilder<DocumentSnapshot<Comic>>(
      future: FirestoreService.instance.comicRef(comicId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(title: Text('Lỗi: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 60,
                height: 80,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              title: const Text('Đang tải...'),
            ),
          );
        }

        final comic = snapshot.data!.data()!;
        final timeAgo = _formatTimeAgo(history.lastReadAt);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ComicDetailScreen(comic: comic, profile: widget.profile),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover image
                  Container(
                    width: 70,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: comic.coverUrl.isNotEmpty
                        ? Image.network(
                            comic.coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 32),
                          )
                        : const Icon(Icons.book, size: 32),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tên truyện
                        Text(
                          comic.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Chapter đã đọc
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_circle_outline,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Đọc đến: ${history.chapterTitle}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Thời gian đọc
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red,
                    tooltip: 'Xóa khỏi lịch sử',
                    onPressed: () =>
                        _confirmDeleteHistory(comicId, comic.title),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
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

  Future<void> _confirmDeleteHistory(String comicId, String comicTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch sử'),
        content: Text('Bạn có chắc muốn xóa "$comicTitle" khỏi lịch sử đọc?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Implement delete single history
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Tính năng đang phát triển'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _syncToCloud() async {
    try {
      await ReadingHistoryService.instance.syncToCloud(userId: widget.user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ Đã đồng bộ lịch sử lên cloud'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi đồng bộ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadFromCloud() async {
    try {
      await ReadingHistoryService.instance.loadFromCloud(
        userId: widget.user.uid,
      );
      if (mounted) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ Đã tải lịch sử từ cloud'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi tải xuống: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Xóa cache'),
          ],
        ),
        content: const Text(
          'Bạn có chắc muốn xóa tất cả lịch sử đọc trên thiết bị này?\n\n'
          'Lưu ý: Nếu đã đồng bộ lên cloud, bạn có thể tải lại sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ReadingHistoryService.instance.clearCache(widget.user.uid);
        setState(() {}); // Refresh UI
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('✅ Đã xóa cache lịch sử đọc'),
                ],
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi xóa cache: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildDownloadedTab() {
    return Column(
      children: [
        // Action button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: FloatingActionButton(
              onPressed: () {
                // TODO: Implement delete
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xóa truyện đã tải')),
                );
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
          ),
        ),
        // Empty state
        const Expanded(child: Center(child: Text('Bạn chưa tải truyện nào'))),
      ],
    );
  }

  Widget _buildComicCardWithData(String comicId, UserProfile profile) {
    return FutureBuilder<DocumentSnapshot<Comic>>(
      future: FirestoreService.instance.comicRef(comicId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(child: Center(child: Text('Lỗi: ${snapshot.error}')));
        }

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return Card(
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        final comic = snapshot.data!.data()!;

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ComicDetailScreen(comic: comic, profile: profile),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover image
                Expanded(
                  child: Stack(
                    children: [
                      comic.coverUrl.isNotEmpty
                          ? Image.network(
                              comic.coverUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 48),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.book, size: 48),
                            ),
                      // New badge if recently added
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'mới',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Info
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comic.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<QuerySnapshot<ChapterMeta>>(
                        future: FirestoreService.instance
                            .chapters(comic.id)
                            .orderBy('order', descending: true)
                            .limit(1)
                            .get(),
                        builder: (context, chapterSnapshot) {
                          if (chapterSnapshot.hasData &&
                              chapterSnapshot.data!.docs.isNotEmpty) {
                            final latestChapter = chapterSnapshot
                                .data!
                                .docs
                                .first
                                .data();
                            return Text(
                              'Chapter ${latestChapter.order} mới',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            );
                          }
                          return const Text(
                            'Chưa có chapter',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
