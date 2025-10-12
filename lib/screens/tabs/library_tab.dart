import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';

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
    final favorites = widget.profile.favorites;

    return Column(
      children: [
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement sync
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đang đồng bộ...')),
                    );
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Đồng bộ'),
                ),
              ),
            ],
          ),
        ),
        // Comic list
        Expanded(
          child: favorites.isEmpty
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
                    return _buildComicCard(favorites[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    final history = widget.profile.history;

    return Column(
      children: [
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement sync
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đang đồng bộ...')),
                    );
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Đồng bộ'),
                ),
              ),
            ],
          ),
        ),
        // Comic list
        Expanded(
          child: history.isEmpty
              ? const Center(child: Text('Bạn chưa đọc truyện nào gần đây'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    return _buildComicCard(history[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDownloadedTab() {
    return Column(
      children: [
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement sync
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đang đồng bộ...')),
                    );
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Đồng bộ'),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                onPressed: () {
                  // TODO: Implement delete
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa truyện đã tải')),
                  );
                },
                backgroundColor: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
            ],
          ),
        ),
        // Empty state
        const Expanded(child: Center(child: Text('Bạn chưa tải truyện nào'))),
      ],
    );
  }

  Widget _buildComicCard(String comicId) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.book, size: 48),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Truyện: $comicId',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Vừa đọc: Chapter 5',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
