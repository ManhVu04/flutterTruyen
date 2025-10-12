import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/comic.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'chapter_reader_screen.dart';
import 'admin_edit_comic_screen.dart';
import 'admin_manage_chapters_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _comicId = widget.comic.id;
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
                      _formatNumber((comic.rating * 1000).toInt()),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Add to library
                        },
                        icon: const Icon(Icons.bookmark_border, size: 18),
                        label: const Text('Lưu'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
          // Rating section
          const Divider(),
          const SizedBox(height: 16),
          _buildRatingSection(comic),
        ],
      ),
    );
  }

  Widget _buildRatingSection(Comic comic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đánh giá',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Average rating
            Column(
              children: [
                Text(
                  comic.rating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < comic.rating.floor()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                const Text('152 đánh giá', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(width: 32),
            // Rating bars
            Expanded(
              child: Column(
                children: [
                  _buildRatingBar('5', 0.7),
                  _buildRatingBar('4', 0.15),
                  _buildRatingBar('3', 0.08),
                  _buildRatingBar('2', 0.05),
                  _buildRatingBar('1', 0.02),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Rating tags
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildRatingTag('Cực phẩm (130)'),
            _buildRatingTag('Đáng đọc (7)'),
            _buildRatingTag('Tạm ổn (10)'),
            _buildRatingTag('Chưa ưng lắm (1)'),
            _buildRatingTag('Kén người đọc (4)'),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            // TODO: Write review
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
          ),
          child: const Text('Viết đánh giá ~'),
        ),
      ],
    );
  }

  Widget _buildRatingBar(String stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars ★', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingTag(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          ChapterMeta? firstChapter;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            firstChapter = snapshot.data!.docs.first.data();
          }

          return ElevatedButton(
            onPressed: firstChapter != null
                ? () {
                    final canRead =
                        firstChapter!.vipRequired == 0 ||
                        widget.profile.vipLevel >= firstChapter.vipRequired;
                    if (canRead) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChapterReaderScreen(
                            comic: comic,
                            chapter: firstChapter!,
                            profile: widget.profile,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Cần VIP Level ${firstChapter.vipRequired} để đọc chapter này',
                          ),
                        ),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  firstChapter != null
                      ? 'ĐỌC CHAPTER ${firstChapter.order}'
                      : 'CHƯA CÓ CHAPTER',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward),
              ],
            ),
          );
        },
      ),
    );
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
