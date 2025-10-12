import 'package:flutter/material.dart';
import '../models/comic.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class AdminEditComicScreen extends StatefulWidget {
  const AdminEditComicScreen({
    super.key,
    required this.comic,
    required this.profile,
  });

  final Comic comic;
  final UserProfile profile;

  @override
  State<AdminEditComicScreen> createState() => _AdminEditComicScreenState();
}

class _AdminEditComicScreenState extends State<AdminEditComicScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _coverUrlController;
  late TextEditingController _statusController;
  late TextEditingController _viewsController;
  late TextEditingController _ratingController;
  late TextEditingController _vipTierController;

  List<String> _selectedTags = [];
  bool _isSaving = false;

  // Danh sách thể loại có sẵn
  final List<String> _availableTags = [
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
    'Thanh xuân - Vườn trường',
    'Trùng Sinh',
    'Trong sinh',
    'Truyện Sáng Tác',
    'Tu Tiên',
    'Xuyên Không',
    'Đô Thị',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.comic.title);
    _descriptionController = TextEditingController(
      text: widget.comic.description,
    );
    _coverUrlController = TextEditingController(text: widget.comic.coverUrl);
    _statusController = TextEditingController(text: widget.comic.status);
    _viewsController = TextEditingController(
      text: widget.comic.views.toString(),
    );
    _ratingController = TextEditingController(
      text: widget.comic.rating.toString(),
    );
    _vipTierController = TextEditingController(
      text: widget.comic.vipTier.toString(),
    );
    _selectedTags = List.from(widget.comic.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _coverUrlController.dispose();
    _statusController.dispose();
    _viewsController.dispose();
    _ratingController.dispose();
    _vipTierController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    // Validate
    if (_titleController.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập tiêu đề truyện');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedComic = Comic(
        id: widget.comic.id,
        title: _titleController.text.trim(),
        coverUrl: _coverUrlController.text.trim(),
        tags: _selectedTags,
        status: _statusController.text.trim(),
        views: int.tryParse(_viewsController.text.trim()) ?? widget.comic.views,
        rating:
            double.tryParse(_ratingController.text.trim()) ??
            widget.comic.rating,
        vipTier:
            int.tryParse(_vipTierController.text.trim()) ??
            widget.comic.vipTier,
        description: _descriptionController.text.trim(),
        authorId: widget.comic.authorId,
        createdAt: widget.comic.createdAt,
        updatedAt: DateTime.now(),
      );

      await FirestoreService.instance.updateComic(updatedComic);

      if (mounted) {
        _showMessage('Đã cập nhật truyện thành công!');
        Navigator.of(context).pop(updatedComic);
      }
    } catch (e) {
      _showMessage('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa truyện'),
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
              onPressed: _saveChanges,
              tooltip: 'Lưu thay đổi',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              title: 'Thông tin cơ bản',
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: 'Tiêu đề',
                  icon: Icons.title,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Mô tả',
                  icon: Icons.description,
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _coverUrlController,
                  label: 'URL Ảnh bìa',
                  icon: Icons.image,
                ),
                const SizedBox(height: 16),
                if (_coverUrlController.text.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _coverUrlController.text,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 48),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 1),
            _buildSection(
              title: 'Thể loại',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (_) => _toggleTag(tag),
                      backgroundColor: Colors.grey[200],
                      selectedColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.3),
                      checkmarkColor: Theme.of(context).primaryColor,
                    );
                  }).toList(),
                ),
              ],
            ),
            const Divider(height: 1),
            _buildSection(
              title: 'Trạng thái & Thống kê',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _statusController,
                        label: 'Trạng thái',
                        icon: Icons.info,
                        helperText: 'ongoing/completed/hiatus',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _vipTierController,
                        label: 'VIP Tier',
                        icon: Icons.star,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _viewsController,
                        label: 'Lượt xem',
                        icon: Icons.visibility,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _ratingController,
                        label: 'Đánh giá',
                        icon: Icons.star_rate,
                        keyboardType: TextInputType.number,
                        helperText: '0.0 - 5.0',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 1),
            _buildSection(
              title: 'Thông tin bổ sung',
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Tác giả'),
                  subtitle: Text(widget.comic.authorId),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Ngày tạo'),
                  subtitle: Text(
                    widget.comic.createdAt?.toString() ?? 'Không rõ',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.update),
                  title: const Text('Cập nhật lần cuối'),
                  subtitle: Text(
                    widget.comic.updatedAt?.toString() ?? 'Không rõ',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveChanges,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        prefixIcon: Icon(icon),
        helperText: helperText,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }
}
