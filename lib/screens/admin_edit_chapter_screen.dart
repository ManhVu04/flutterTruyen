import 'package:flutter/material.dart';
import '../models/comic.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../widgets/folder_image_picker_dialog.dart';

class AdminEditChapterScreen extends StatefulWidget {
  const AdminEditChapterScreen({
    super.key,
    required this.comic,
    required this.profile,
    this.chapter,
  });

  final Comic comic;
  final UserProfile profile;
  final ChapterMeta? chapter; // null = create new

  @override
  State<AdminEditChapterScreen> createState() => _AdminEditChapterScreenState();
}

class _AdminEditChapterScreenState extends State<AdminEditChapterScreen> {
  late TextEditingController _titleController;
  late TextEditingController _orderController;
  late TextEditingController _vipRequiredController;
  late TextEditingController _pagesController;

  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final chapter = widget.chapter;
    _titleController = TextEditingController(text: chapter?.title ?? '');
    _orderController = TextEditingController(
      text: chapter?.order.toString() ?? '1',
    );
    _vipRequiredController = TextEditingController(
      text: chapter?.vipRequired.toString() ?? '0',
    );
    _pagesController = TextEditingController(
      text: chapter?.pages.join('\n') ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _orderController.dispose();
    _vipRequiredController.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final pages = _pagesController.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      final chapter = ChapterMeta(
        id:
            widget.chapter?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        order: int.tryParse(_orderController.text.trim()) ?? 1,
        title: _titleController.text.trim(),
        releaseAt: DateTime.now(),
        pages: pages,
        vipRequired: int.tryParse(_vipRequiredController.text.trim()) ?? 0,
        freeUntil: widget.chapter?.freeUntil,
      );

      if (widget.chapter == null) {
        // Create new
        await FirestoreService.instance.addChapter(
          comicId: widget.comic.id,
          chapter: chapter,
          chapterId: chapter.id,
        );
      } else {
        // Update existing
        await FirestoreService.instance.updateChapter(
          comicId: widget.comic.id,
          chapterId: chapter.id,
          chapter: chapter,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.chapter == null
                  ? 'Đã thêm chapter mới!'
                  : 'Đã cập nhật chapter!',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _loadImagesFromFolder() async {
    try {
      final urls = await showDialog<List<String>>(
        context: context,
        builder: (context) => const FolderImagePickerDialog(),
      );

      if (urls != null && urls.isNotEmpty) {
        // Thêm URLs vào cuối text hiện có
        final currentText = _pagesController.text;
        final newText = currentText.isEmpty
            ? urls.join('\n')
            : '$currentText\n${urls.join('\n')}';

        setState(() {
          _pagesController.text = newText;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã thêm ${urls.length} trang từ thư mục')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.chapter == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Thêm Chapter Mới' : 'Chỉnh Sửa Chapter'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
              tooltip: 'Lưu',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề chapter *',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập tiêu đề'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _orderController,
                      decoration: const InputDecoration(
                        labelText: 'Thứ tự *',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nhập thứ tự';
                        }
                        if (int.tryParse(value.trim()) == null) {
                          return 'Phải là số';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _vipRequiredController,
                      decoration: const InputDecoration(
                        labelText: 'VIP Required',
                        prefixIcon: Icon(Icons.star),
                        border: OutlineInputBorder(),
                        helperText: '0 = Free',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nhập VIP level';
                        }
                        if (int.tryParse(value.trim()) == null) {
                          return 'Phải là số';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pagesController,
                decoration: const InputDecoration(
                  labelText: 'Danh sách trang (mỗi URL 1 dòng) *',
                  prefixIcon: Icon(Icons.image),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập ít nhất 1 trang'
                    : null,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _loadImagesFromFolder,
                icon: const Icon(Icons.folder),
                label: const Text('Tải ảnh từ thư mục Storage'),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Đang lưu...' : 'Lưu Chapter'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (!isNew) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Chapter ID'),
                  subtitle: Text(widget.chapter!.id),
                ),
                if (widget.chapter!.releaseAt != null)
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Ngày phát hành'),
                    subtitle: Text(widget.chapter!.releaseAt.toString()),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
