import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/comic.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'admin_edit_chapter_screen.dart';

class AdminManageChaptersScreen extends StatefulWidget {
  const AdminManageChaptersScreen({
    super.key,
    required this.comic,
    required this.profile,
  });

  final Comic comic;
  final UserProfile profile;

  @override
  State<AdminManageChaptersScreen> createState() =>
      _AdminManageChaptersScreenState();
}

class _AdminManageChaptersScreenState extends State<AdminManageChaptersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý Chapter - ${widget.comic.title}')),
      body: StreamBuilder<QuerySnapshot<ChapterMeta>>(
        stream: FirestoreService.instance
            .chapters(widget.comic.id)
            .orderBy('order', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chapters = snapshot.data!.docs;

          if (chapters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có chapter nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn nút "+" bên dưới để thêm chapter mới',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminEditChapterScreen(
                            comic: widget.comic,
                            profile: widget.profile,
                            chapter: null,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm Chapter Đầu Tiên'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final doc = chapters[index];
              final chapter = doc.data();
              return _buildChapterCard(chapter);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminEditChapterScreen(
                comic: widget.comic,
                profile: widget.profile,
                chapter: null, // null = create new
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm Chapter'),
      ),
    );
  }

  Widget _buildChapterCard(ChapterMeta chapter) {
    final bool isFree = chapter.vipRequired == 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isFree ? Colors.green : Colors.amber,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isFree ? 'FREE' : 'VIP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              Text(
                '${chapter.order}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          chapter.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chapter.releaseAt != null
                  ? DateFormat('HH:mm dd/MM/yyyy').format(chapter.releaseAt!)
                  : 'Chưa có ngày phát hành',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${chapter.pages.length} trang',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminEditChapterScreen(
                    comic: widget.comic,
                    profile: widget.profile,
                    chapter: chapter,
                  ),
                ),
              );
            } else if (value == 'delete') {
              _confirmDelete(chapter);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ChapterMeta chapter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${chapter.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirestoreService.instance.deleteChapter(
          comicId: widget.comic.id,
          chapterId: chapter.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xóa chapter')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
        }
      }
    }
  }
}
