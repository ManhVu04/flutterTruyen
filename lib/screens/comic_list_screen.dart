import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comic.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'comic_detail_screen.dart';

class ComicListScreen extends StatefulWidget {
  const ComicListScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<ComicListScreen> createState() => _ComicListScreenState();
}

class _ComicListScreenState extends State<ComicListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'latest'; // latest, views, rating
  List<String> _selectedGenres = [];

  final List<String> _genres = [
    'Cổ Đại',
    'Hiện đại',
    'Huyền Huyễn',
    'Hai Hước',
    'Hàn Quốc',
    'Hậu Cung',
    'Hệ Thống',
    'Kinh Dị',
    'Lịch Sử',
    'Mạt Thế',
    'Ngôn Tình',
    'Truyện Sáng Tác',
    'Trong sinh',
    'Tu Tiên',
    'Xuyên Không',
    'Đô Thị',
    'Thanh xuân - Vườn trường',
    'Trùng Sinh',
  ];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh Sách Truyện'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Đang ra'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComicList(null),
          _buildComicList('ongoing'),
          _buildComicList('completed'),
        ],
      ),
    );
  }

  Widget _buildComicList(String? status) {
    return Column(
      children: [
        // Sort buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          child: Row(
            children: [
              const Text('Xếp theo: '),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Ngày cập nhật'),
                selected: _sortBy == 'latest',
                onSelected: (selected) {
                  if (selected) setState(() => _sortBy = 'latest');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Lượt xem'),
                selected: _sortBy == 'views',
                onSelected: (selected) {
                  if (selected) setState(() => _sortBy = 'views');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Đánh giá'),
                selected: _sortBy == 'rating',
                onSelected: (selected) {
                  if (selected) setState(() => _sortBy = 'rating');
                },
              ),
            ],
          ),
        ),
        // Comic grid
        Expanded(
          child: StreamBuilder<QuerySnapshot<Comic>>(
            stream: _getComicsStream(status),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final comics = snapshot.data!.docs
                  .map((doc) => doc.data())
                  .toList();

              if (comics.isEmpty) {
                return const Center(child: Text('Chưa có truyện nào'));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: comics.length,
                itemBuilder: (context, index) {
                  return _buildComicCard(comics[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot<Comic>> _getComicsStream(String? status) {
    Query<Comic> query = FirestoreService.instance.comics;

    // Filter by status
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    // Filter by genres
    if (_selectedGenres.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: _selectedGenres);
    }

    // Sort
    switch (_sortBy) {
      case 'latest':
        query = query.orderBy('updatedAt', descending: true);
        break;
      case 'views':
        query = query.orderBy('views', descending: true);
        break;
      case 'rating':
        query = query.orderBy('rating', descending: true);
        break;
    }

    return query.limit(50).snapshots();
  }

  Widget _buildComicCard(Comic comic) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ComicDetailScreen(comic: comic, profile: widget.profile),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Expanded(
            child: Stack(
              children: [
                Container(
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
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 48),
                          )
                        : const Center(child: Icon(Icons.image, size: 48)),
                  ),
                ),
                // VIP badge
                if (comic.vipTier > 0)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'VIP',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                // Views
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.remove_red_eye,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatNumber(comic.views),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Title
          Text(
            comic.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Thể loại',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedGenres.clear();
                          });
                        },
                        child: const Text('Xóa lọc'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _genres.length,
                      itemBuilder: (context, index) {
                        final genre = _genres[index];
                        final isSelected = _selectedGenres.contains(genre);
                        return FilterChip(
                          label: Text(genre),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedGenres.add(genre);
                              } else {
                                _selectedGenres.remove(genre);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
