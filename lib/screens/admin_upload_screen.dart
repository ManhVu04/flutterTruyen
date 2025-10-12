import 'package:flutter/material.dart';
import '../models/comic.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _comicIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _tagsController = TextEditingController();
  final _statusController = TextEditingController(text: 'ongoing');
  final _descriptionController = TextEditingController();
  final _viewsController = TextEditingController(text: '0');
  final _ratingController = TextEditingController(text: '0');
  final _vipTierController = TextEditingController(text: '0');

  final _chapterIdController = TextEditingController();
  final _chapterTitleController = TextEditingController();
  final _chapterOrderController = TextEditingController();
  final _chapterPagesController = TextEditingController();
  final _chapterVipController = TextEditingController(text: '0');

  bool _isSubmitting = false;

  @override
  void dispose() {
    _comicIdController.dispose();
    _titleController.dispose();
    _coverUrlController.dispose();
    _tagsController.dispose();
    _statusController.dispose();
    _descriptionController.dispose();
    _viewsController.dispose();
    _ratingController.dispose();
    _vipTierController.dispose();
    _chapterIdController.dispose();
    _chapterTitleController.dispose();
    _chapterOrderController.dispose();
    _chapterPagesController.dispose();
    _chapterVipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final comicId = _comicIdController.text.trim();
      final comic = Comic(
        id: comicId,
        title: _titleController.text.trim(),
        coverUrl: _coverUrlController.text.trim(),
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        status: _statusController.text.trim(),
        views: int.tryParse(_viewsController.text.trim()) ?? 0,
        rating: double.tryParse(_ratingController.text.trim()) ?? 0,
        vipTier: int.tryParse(_vipTierController.text.trim()) ?? 0,
        description: _descriptionController.text.trim(),
        authorId: widget.profile.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirestoreService.instance.createComic(comic);

      final chapterTitle = _chapterTitleController.text.trim();
      final pagesRaw = _chapterPagesController.text.trim();

      if (chapterTitle.isNotEmpty && pagesRaw.isNotEmpty) {
        final chapterId = _chapterIdController.text.trim().isEmpty
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : _chapterIdController.text.trim();
        final pages = pagesRaw
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
        final chapter = ChapterMeta(
          id: chapterId,
          order: int.tryParse(_chapterOrderController.text.trim()) ?? 1,
          title: chapterTitle,
          releaseAt: DateTime.now(),
          pages: pages,
          vipRequired: int.tryParse(_chapterVipController.text.trim()) ?? 0,
          freeUntil: null,
        );
        await FirestoreService.instance.addChapter(
          comicId: comicId,
          chapter: chapter,
          chapterId: chapterId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Da luu truyen thanh cong')),
        );
        _formKey.currentState!.reset();
        _chapterPagesController.clear();
      }
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Loi: ${error.toString()}')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Them truyen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _comicIdController,
                decoration: const InputDecoration(labelText: 'Comic ID (slug)'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhap ID truyen'
                    : null,
              ),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tieu de'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhap tieu de'
                    : null,
              ),
              TextFormField(
                controller: _coverUrlController,
                decoration: const InputDecoration(labelText: 'Cover URL'),
              ),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (phan cach bang dau phay)',
                ),
              ),
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Trang thai'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mo ta'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _viewsController,
                decoration: const InputDecoration(labelText: 'Luot xem'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _ratingController,
                decoration: const InputDecoration(labelText: 'Danh gia (0-5)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _vipTierController,
                decoration: const InputDecoration(
                  labelText: 'VIP tier can thiet',
                ),
                keyboardType: TextInputType.number,
              ),
              const Divider(height: 32),
              TextFormField(
                controller: _chapterIdController,
                decoration: const InputDecoration(
                  labelText: 'Chapter ID (bo qua neu tu dong)',
                ),
              ),
              TextFormField(
                controller: _chapterTitleController,
                decoration: const InputDecoration(
                  labelText: 'Tieu de chapter dau tien',
                ),
              ),
              TextFormField(
                controller: _chapterOrderController,
                decoration: const InputDecoration(labelText: 'Thu tu chapter'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _chapterVipController,
                decoration: const InputDecoration(
                  labelText: 'VIP required (0 neu chapter free)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _chapterPagesController,
                decoration: const InputDecoration(
                  labelText: 'Danh sach trang (moi URL 1 dong)',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Luu truyen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
