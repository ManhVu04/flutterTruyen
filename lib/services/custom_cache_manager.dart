import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom Cache Manager cho ảnh truyện tranh
/// Tăng thời gian lưu cache và số lượng file cache
class ComicImageCacheManager extends CacheManager {
  static const key = 'comicImageCache';

  static final ComicImageCacheManager _instance = ComicImageCacheManager._();
  factory ComicImageCacheManager() => _instance;

  ComicImageCacheManager._()
    : super(
        Config(
          key,
          // Lưu cache trong 30 ngày
          stalePeriod: const Duration(days: 30),
          // Giữ tối đa 200 file
          maxNrOfCacheObjects: 200,
          // Không có giới hạn kích thước repo
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ),
      );
}
