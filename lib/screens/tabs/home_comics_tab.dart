import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/comic.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/no_internet_widget.dart';
import '../comic_detail_screen.dart';
import '../genre_list_screen.dart';
import '../comic_list_screen.dart';

class HomeComicsTab extends StatefulWidget {
  const HomeComicsTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<HomeComicsTab> createState() => _HomeComicsTabState();
}

class _HomeComicsTabState extends State<HomeComicsTab> {
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _listenToConnectivity();
  }

  void _checkConnectivity() async {
    final isConnected = await ConnectivityService.instance.checkConnection();
    if (mounted) {
      setState(() => _isConnected = isConnected);
    }
  }

  void _listenToConnectivity() {
    ConnectivityService.instance.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() => _isConnected = isConnected);
        if (isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã kết nối internet'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mất kết nối internet'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _onRefresh() async {
    _checkConnectivity();
    // Delay để hiển thị animation
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              child: NoInternetWidget(onRetry: _onRefresh),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBanner(context),
              _buildCategoryButtons(context),
              _buildSection(
                context,
                title: 'KHUYẾN KHÍCH ĐỌC 🔥',
                icon: Icons.local_fire_department,
                query: FirestoreService.instance.comics
                    .orderBy('rating', descending: true)
                    .limit(10),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: 'TRUYỆN MỚI CẬP NHẬT',
                icon: Icons.fiber_new,
                query: FirestoreService.instance.comics
                    .orderBy('updatedAt', descending: true)
                    .limit(10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Comic>>(
      stream: FirestoreService.instance.comics
          .orderBy('views', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            height: 300,
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final featured = snapshot.data!.docs.first.data();

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ComicDetailScreen(comic: featured, profile: widget.profile),
              ),
            );
          },
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              image: featured.coverUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(featured.coverUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[800],
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    featured.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.remove_red_eye,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatNumber(featured.views),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        featured.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCategoryButton(
            context,
            icon: Icons.list,
            label: 'Thể Loại',
            color: Colors.purple,
          ),
          _buildCategoryButton(
            context,
            icon: Icons.star,
            label: 'Top User',
            color: Colors.amber,
          ),
          _buildCategoryButton(
            context,
            icon: Icons.fiber_new,
            label: 'Mới nhất',
            color: Colors.pink,
          ),
          _buildCategoryButton(
            context,
            icon: Icons.create,
            label: 'Sáng Tác',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        if (label == 'Thể Loại') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GenreListScreen(profile: widget.profile),
            ),
          );
        } else {
          // TODO: Implement other category actions
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chức năng "$label" đang phát triển')),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.6)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Query<Comic> query,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Determine sort type based on section title
                  String sortType = 'latest';
                  String screenTitle = title;

                  if (title.contains('KHUYẾN KHÍCH')) {
                    sortType = 'rating';
                    screenTitle = 'Truyện được khuyến khích đọc';
                  } else if (title.contains('MỚI CẬP NHẬT')) {
                    sortType = 'latest';
                    screenTitle = 'Truyện mới cập nhật';
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ComicListScreen(
                        profile: widget.profile,
                        initialSort: sortType,
                        title: screenTitle,
                      ),
                    ),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Xem tất cả'),
                    Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot<Comic>>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final comics = snapshot.data!.docs
                .map((doc) => doc.data())
                .toList();

            if (comics.isEmpty) {
              return const SizedBox(
                height: 100,
                child: Center(child: Text('Chưa có truyện')),
              );
            }

            return SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: comics.length,
                itemBuilder: (context, index) {
                  return _buildComicCard(context, comics[index]);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildComicCard(BuildContext context, Comic comic) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ComicDetailScreen(comic: comic, profile: widget.profile),
          ),
        );
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Container(
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: comic.coverUrl.isNotEmpty
                        ? Image.network(
                            comic.coverUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 48),
                          )
                        : const Center(child: Icon(Icons.image, size: 48)),
                  ),
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
                        child: const Text(
                          'VIP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
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
}
