import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class FolderImagePickerDialog extends StatefulWidget {
  const FolderImagePickerDialog({super.key});

  @override
  State<FolderImagePickerDialog> createState() =>
      _FolderImagePickerDialogState();
}

class _FolderImagePickerDialogState extends State<FolderImagePickerDialog> {
  String? _selectedComic;
  List<String> _comics = [];
  List<String> _chapters = [];
  final List<String> _selectedChapters = [];
  bool _isLoadingComics = true;
  bool _isLoadingChapters = false;

  @override
  void initState() {
    super.initState();
    _loadComics();
  }

  Future<void> _loadComics() async {
    setState(() => _isLoadingComics = true);
    try {
      final comics = await StorageService.getComicsList();
      setState(() {
        _comics = comics;
        _isLoadingComics = false;
      });
    } catch (e) {
      setState(() => _isLoadingComics = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách truyện: $e')));
      }
    }
  }

  Future<void> _loadChapters(String comicName) async {
    setState(() => _isLoadingChapters = true);
    try {
      final chapters = await StorageService.getChaptersList(comicName);
      setState(() {
        _chapters = chapters;
        _selectedChapters.clear();
        _isLoadingChapters = false;
      });
    } catch (e) {
      setState(() => _isLoadingChapters = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách chapter: $e')),
        );
      }
    }
  }

  Future<List<String>> _loadImagesFromSelectedChapters() async {
    if (_selectedComic == null || _selectedChapters.isEmpty) {
      return [];
    }

    final allImages = <String>[];

    for (final chapter in _selectedChapters) {
      final images = await StorageService.getChapterImages(
        _selectedComic!,
        chapter,
      );
      allImages.addAll(images);
    }

    return allImages;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn ảnh từ thư mục',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Comic selector
            const Text(
              'Chọn truyện:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_isLoadingComics)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedComic,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Chọn truyện'),
                items: _comics.map((comic) {
                  return DropdownMenuItem(value: comic, child: Text(comic));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedComic = value;
                    _chapters.clear();
                    _selectedChapters.clear();
                  });
                  if (value != null) {
                    _loadChapters(value);
                  }
                },
              ),

            const SizedBox(height: 16),

            // Chapter selector
            const Text(
              'Chọn chapter:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (_isLoadingChapters)
              const Center(child: CircularProgressIndicator())
            else if (_chapters.isEmpty)
              const Center(
                child: Text(
                  'Vui lòng chọn truyện trước',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = _chapters[index];
                      final isSelected = _selectedChapters.contains(chapter);
                      return CheckboxListTile(
                        title: Text(chapter),
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedChapters.add(chapter);
                            } else {
                              _selectedChapters.remove(chapter);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Info text
            if (_selectedChapters.isNotEmpty)
              Text(
                'Đã chọn ${_selectedChapters.length} chapter',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),

            const SizedBox(height: 8),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedChapters.isEmpty
                        ? null
                        : () async {
                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              final images =
                                  await _loadImagesFromSelectedChapters();

                              if (mounted) {
                                Navigator.pop(context); // Close loading
                                Navigator.pop(context, images); // Return images
                              }
                            } catch (e) {
                              if (mounted) {
                                Navigator.pop(context); // Close loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e')),
                                );
                              }
                            }
                          },
                    child: const Text('Tải ảnh'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
