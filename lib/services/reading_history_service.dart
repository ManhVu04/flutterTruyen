import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

/// Service quản lý lịch sử đọc truyện
/// - Lưu tạm vào cache (SharedPreferences)
/// - Có thể sync lên Firestore
class ReadingHistoryService {
  static final ReadingHistoryService instance = ReadingHistoryService._();
  ReadingHistoryService._();

  static const String _keyPrefix = 'reading_history_';

  /// Lấy lịch sử đọc của user cho một truyện cụ thể
  /// Returns: chapterId đã đọc gần nhất, hoặc null nếu chưa đọc
  Future<ReadingHistory?> getHistory({
    required String userId,
    required String comicId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + userId;
      final data = prefs.getString(key);

      if (data == null) return null;

      final Map<String, dynamic> allHistory = jsonDecode(data);
      if (!allHistory.containsKey(comicId)) return null;

      final historyData = allHistory[comicId] as Map<String, dynamic>;
      return ReadingHistory.fromJson(historyData);
    } catch (e) {
      print('❌ Error getting reading history: $e');
      return null;
    }
  }

  /// Lưu lịch sử đọc vào cache
  Future<void> saveHistory({
    required String userId,
    required String comicId,
    required String chapterId,
    required String chapterTitle,
    required int chapterOrder,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + userId;
      final data = prefs.getString(key);

      Map<String, dynamic> allHistory = {};
      if (data != null) {
        allHistory = jsonDecode(data);
      }

      allHistory[comicId] = {
        'chapterId': chapterId,
        'chapterTitle': chapterTitle,
        'chapterOrder': chapterOrder,
        'lastReadAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(key, jsonEncode(allHistory));
      print('✅ Saved reading history: $comicId -> Chapter $chapterOrder');
    } catch (e) {
      print('❌ Error saving reading history: $e');
    }
  }

  /// Xóa tất cả lịch sử đọc trong cache (khi user clear cache)
  Future<void> clearCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + userId;
      await prefs.remove(key);
      print('✅ Cleared reading history cache for user: $userId');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Đồng bộ lịch sử đọc từ cache lên Firestore
  Future<void> syncToCloud({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + userId;
      final data = prefs.getString(key);

      if (data == null) {
        print('⚠️ No reading history to sync');
        return;
      }

      final Map<String, dynamic> allHistory = jsonDecode(data);

      // Lưu vào Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'readingHistory': allHistory,
        'lastSyncAt': FieldValue.serverTimestamp(),
      });

      print('✅ Synced reading history to cloud: ${allHistory.length} comics');
    } catch (e) {
      print('❌ Error syncing to cloud: $e');
      rethrow;
    }
  }

  /// Load lịch sử đọc từ Firestore về cache
  Future<void> loadFromCloud({required String userId}) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      if (data == null || !data.containsKey('readingHistory')) return;

      final readingHistory = data['readingHistory'] as Map<String, dynamic>;

      // Lưu vào cache
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + userId;
      await prefs.setString(key, jsonEncode(readingHistory));

      print(
        '✅ Loaded reading history from cloud: ${readingHistory.length} comics',
      );
    } catch (e) {
      print('❌ Error loading from cloud: $e');
    }
  }

  /// Lấy tất cả lịch sử đọc của user (để hiển thị trong tab "Vừa xem")
  Future<Map<String, ReadingHistory>> getAllHistory({
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + userId;
      final data = prefs.getString(key);

      if (data == null) return {};

      final Map<String, dynamic> allHistory = jsonDecode(data);
      final Map<String, ReadingHistory> result = {};

      allHistory.forEach((comicId, historyData) {
        result[comicId] = ReadingHistory.fromJson(historyData);
      });

      return result;
    } catch (e) {
      print('❌ Error getting all history: $e');
      return {};
    }
  }
}

/// Model cho lịch sử đọc
class ReadingHistory {
  final String chapterId;
  final String chapterTitle;
  final int chapterOrder;
  final DateTime lastReadAt;

  ReadingHistory({
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterOrder,
    required this.lastReadAt,
  });

  factory ReadingHistory.fromJson(Map<String, dynamic> json) {
    return ReadingHistory(
      chapterId: json['chapterId'] as String,
      chapterTitle: json['chapterTitle'] as String,
      chapterOrder: json['chapterOrder'] as int,
      lastReadAt: DateTime.parse(json['lastReadAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'chapterOrder': chapterOrder,
      'lastReadAt': lastReadAt.toIso8601String(),
    };
  }
}
