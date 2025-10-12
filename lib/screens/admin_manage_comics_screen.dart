import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/comic.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'admin_edit_comic_screen.dart';
import 'admin_upload_screen.dart';

class AdminManageComicsScreen extends StatefulWidget {
  const AdminManageComicsScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<AdminManageComicsScreen> createState() =>
      _AdminManageComicsScreenState();
}

class _AdminManageComicsScreenState extends State<AdminManageComicsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý truyện'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminUploadScreen(profile: widget.profile),
                ),
              );
            },
            tooltip: 'Thêm truyện mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm truyện...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
                const SizedBox(height: 12),
                // Status filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', 'all'),
                      _buildFilterChip('Ongoing', 'ongoing'),
                      _buildFilterChip('Completed', 'completed'),
                      _buildFilterChip('Hiatus', 'hiatus'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Comics list
          Expanded(
            child: StreamBuilder<QuerySnapshot<Comic>>(
              stream: FirestoreService.instance.comics.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comics = snapshot.data!.docs
                    .map((doc) => doc.data())
                    .where((comic) {
                      // Filter by search query
                      if (_searchQuery.isNotEmpty &&
                          !comic.title.toLowerCase().contains(_searchQuery)) {
                        return false;
                      }
                      // Filter by status
                      if (_selectedStatus != 'all' &&
                          comic.status != _selectedStatus) {
                        return false;
                      }
                      return true;
                    })
                    .toList();

                if (comics.isEmpty) {
                  return const Center(child: Text('Không tìm thấy truyện nào'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comics.length,
                  itemBuilder: (context, index) {
                    return _buildComicCard(comics[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedStatus = value);
        },
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }

  Widget _buildComicCard(Comic comic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            comic.coverUrl,
            width: 60,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 60,
              height: 80,
              color: Colors.grey[300],
              child: const Icon(Icons.book),
            ),
          ),
        ),
        title: Text(
          comic.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${comic.views}'),
                const SizedBox(width: 12),
                Icon(Icons.star, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${comic.rating.toStringAsFixed(1)}'),
              ],
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(comic.status, style: const TextStyle(fontSize: 10)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _editComic(comic);
            } else if (value == 'delete') {
              _deleteComic(comic);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _editComic(comic),
      ),
    );
  }

  void _editComic(Comic comic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AdminEditComicScreen(comic: comic, profile: widget.profile),
      ),
    );
  }

  void _deleteComic(Comic comic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa truyện "${comic.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirestoreService.instance.deleteComic(comic.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa truyện thành công')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
