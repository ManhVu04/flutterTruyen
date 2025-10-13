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
  final _titleController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _status = 'ongoing';
  int _vipTier = 0;
  final List<String> _selectedTags = [];

  bool _isSubmitting = false;

  // Danh sách thể loại có sẵn
  static const List<String> _availableTags = [
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

  static const List<String> _statusOptions = ['ongoing', 'completed', 'hiatus'];

  @override
  void dispose() {
    _titleController.dispose();
    _coverUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một thể loại')),
      );
      return;
    }
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // Tạo ID tự động từ title
      final comicId = _titleController.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'-+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');

      final comic = Comic(
        id: comicId,
        title: _titleController.text.trim(),
        coverUrl: _coverUrlController.text.trim(),
        tags: _selectedTags,
        status: _status,
        views: 0, // Bắt đầu từ 0
        rating: 0.0, // Sẽ tự động tính khi có đánh giá
        vipTier: _vipTier,
        description: _descriptionController.text.trim(),
        authorId: widget.profile.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirestoreService.instance.createComic(comic);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã tạo truyện thành công! Vào chi tiết để thêm chapter.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${error.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm truyện mới'),
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: const Icon(Icons.check),
            label: const Text('Lưu'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thông tin cơ bản
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin cơ bản',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên truyện *',
                        hintText: 'Nhập tên truyện',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập tên truyện'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _coverUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL ảnh bìa *',
                        hintText: 'https://...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.image),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập URL ảnh bìa'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả *',
                        hintText: 'Nhập mô tả truyện',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập mô tả'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Thể loại
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thể loại *',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chọn ít nhất một thể loại cho truyện',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                          selectedColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Trạng thái & VIP
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạng thái & Thông tin VIP',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(),
                      ),
                      items: _statusOptions.map((status) {
                        String label;
                        switch (status) {
                          case 'ongoing':
                            label = 'Đang cập nhật';
                            break;
                          case 'completed':
                            label = 'Hoàn thành';
                            break;
                          case 'hiatus':
                            label = 'Tạm ngưng';
                            break;
                          default:
                            label = status;
                        }
                        return DropdownMenuItem(
                          value: status,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _vipTier,
                      decoration: const InputDecoration(
                        labelText: 'VIP Tier yêu cầu',
                        border: OutlineInputBorder(),
                        helperText: 'Cấp VIP cần thiết để đọc truyện này',
                      ),
                      items: List.generate(6, (index) => index).map((tier) {
                        return DropdownMenuItem(
                          value: tier,
                          child: Text(tier == 0 ? 'Free (0)' : 'VIP $tier'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _vipTier = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Thông tin tự động
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Thông tin tự động',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.blue.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Lượt xem: Sẽ tự động tăng khi người dùng xem truyện\n'
                      '• Đánh giá: Sẽ tự động tính dựa trên đánh giá của người đọc\n'
                      '• Chapter: Thêm chapter sau khi tạo truyện thành công',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload),
                label: Text(
                  _isSubmitting ? 'Đang tạo truyện...' : 'Tạo truyện',
                ),
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
