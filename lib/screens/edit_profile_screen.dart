import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  File? _avatarFile;
  File? _backgroundFile;
  String? _avatarUrl;
  String? _backgroundUrl;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile.displayName;
    _avatarUrl = widget.profile.avatarUrl.isNotEmpty
        ? widget.profile.avatarUrl
        : null;
    _backgroundUrl = widget.profile.backgroundUrl.isNotEmpty
        ? widget.profile.backgroundUrl
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickBackground() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _backgroundFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? newAvatarUrl = _avatarUrl;
      String? newBackgroundUrl = _backgroundUrl;

      // Upload avatar nếu có
      if (_avatarFile != null) {
        final uploadedUrl = await _uploadImage(
          _avatarFile!,
          'users/${widget.profile.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (uploadedUrl != null) {
          newAvatarUrl = uploadedUrl;
        }
      }

      // Upload background nếu có
      if (_backgroundFile != null) {
        final uploadedUrl = await _uploadImage(
          _backgroundFile!,
          'users/${widget.profile.id}/background_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (uploadedUrl != null) {
          newBackgroundUrl = uploadedUrl;
        }
      }

      // Cập nhật Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profile.id)
          .update({
            'displayName': _nameController.text.trim(),
            'avatarUrl': newAvatarUrl ?? '',
            'backgroundUrl': newBackgroundUrl ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.of(context).pop(true); // Return true để HomeScreen reload
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
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
              onPressed: _saveProfile,
              tooltip: 'Lưu',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Background Image Section
            _buildBackgroundSection(),
            const SizedBox(height: 24),

            // Avatar Section
            _buildAvatarSection(),
            const SizedBox(height: 24),

            // Display Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên hiển thị',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên';
                }
                if (value.trim().length < 2) {
                  return 'Tên phải có ít nhất 2 ký tự';
                }
                return null;
              },
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Email (read-only)
            TextFormField(
              initialValue: widget.profile.email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              enabled: false,
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveProfile,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Đang lưu...' : 'Lưu thay đổi'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.wallpaper),
                const SizedBox(width: 8),
                const Text(
                  'Hình nền',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isLoading ? null : _pickBackground,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Chọn ảnh'),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            color: Colors.grey[300],
            child: _backgroundFile != null
                ? Image.file(_backgroundFile!, fit: BoxFit.cover)
                : _backgroundUrl != null
                ? Image.network(_backgroundUrl!, fit: BoxFit.cover)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text(
                          'Chưa có hình nền',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle),
                const SizedBox(width: 8),
                const Text(
                  'Ảnh đại diện',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isLoading ? null : _pickAvatar,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Chọn ảnh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: _avatarFile != null
                  ? FileImage(_avatarFile!)
                  : _avatarUrl != null
                  ? NetworkImage(_avatarUrl!) as ImageProvider
                  : null,
              child: (_avatarFile == null && _avatarUrl == null)
                  ? Icon(Icons.person, size: 64, color: Colors.grey[600])
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
