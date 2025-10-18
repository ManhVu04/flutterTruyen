import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  /// Lấy tất cả URL ảnh từ một thư mục
  static Future<List<String>> getImagesFromFolder(String folderPath) async {
    try {
      // Lấy reference đến thư mục
      final ref = _storage.ref(folderPath);

      // List tất cả items trong thư mục
      final result = await ref.listAll();

      // Lấy download URL cho từng file
      final urls = await Future.wait(
        result.items.map((item) => item.getDownloadURL()),
      );

      // Sắp xếp theo tên file (quan trọng cho thứ tự trang truyện)
      urls.sort();

      return urls;
    } catch (e) {
      print('Error getting images from folder: $e');
      return [];
    }
  }

  /// Lấy danh sách các subfolder (ví dụ: lấy danh sách truyện hoặc chapter)
  static Future<List<String>> getSubfolders(String parentPath) async {
    try {
      final ref = _storage.ref(parentPath);
      final result = await ref.listAll();

      // Trả về tên các subfolder
      final folders = result.prefixes.map((prefix) => prefix.name).toList();
      folders.sort(); // Sắp xếp alphabetically

      return folders;
    } catch (e) {
      print('Error getting subfolders: $e');
      return [];
    }
  }

  /// Lấy danh sách truyện
  static Future<List<String>> getComicsList() async {
    return await getSubfolders('Comis');
  }

  /// Lấy danh sách chapter của một truyện
  static Future<List<String>> getChaptersList(String comicName) async {
    return await getSubfolders('Comis/$comicName');
  }

  /// Lấy ảnh từ một chapter cụ thể
  static Future<List<String>> getChapterImages(
    String comicName,
    String chapterName,
  ) async {
    return await getImagesFromFolder('Comis/$comicName/$chapterName');
  }

  /// Lấy ảnh từ nhiều chapter cùng lúc
  static Future<Map<String, List<String>>> getMultipleChapterImages(
    String comicName,
    List<String> chapterNames,
  ) async {
    final result = <String, List<String>>{};

    for (final chapter in chapterNames) {
      final urls = await getChapterImages(comicName, chapter);
      result[chapter] = urls;
    }

    return result;
  }
}
