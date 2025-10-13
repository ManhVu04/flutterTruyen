import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chapter_comment.dart';

/// Service quản lý bình luận chapter
class ChapterCommentService {
  static final ChapterCommentService instance = ChapterCommentService._();
  ChapterCommentService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference cho comments
  CollectionReference<ChapterComment> get comments => _firestore
      .collection('chapterComments')
      .withConverter<ChapterComment>(
        fromFirestore: (doc, _) => ChapterComment.fromFirestore(doc),
        toFirestore: (comment, _) => comment.toFirestore(),
      );

  /// Lấy stream comments của một chapter (chỉ root comments)
  Stream<QuerySnapshot<ChapterComment>> getChapterComments({
    required String comicId,
    required String chapterId,
  }) {
    return comments
        .where('comicId', isEqualTo: comicId)
        .where('chapterId', isEqualTo: chapterId)
        .where('parentCommentId', isNull: true) // Chỉ lấy comment gốc
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Lấy stream replies của một comment
  Stream<QuerySnapshot<ChapterComment>> getReplies({
    required String parentCommentId,
  }) {
    return comments
        .where('parentCommentId', isEqualTo: parentCommentId)
        .orderBy('createdAt', descending: false) // Replies: cũ -> mới
        .snapshots();
  }

  /// Thêm comment mới
  Future<void> addComment({
    required String comicId,
    required String chapterId,
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
    String? parentCommentId, // null = comment gốc, có giá trị = reply
  }) async {
    try {
      final comment = ChapterComment(
        id: '', // Firestore sẽ tự generate
        comicId: comicId,
        chapterId: chapterId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
        createdAt: DateTime.now(),
        likedBy: [],
        likes: 0,
        parentCommentId: parentCommentId,
        replies: [],
      );

      final docRef = await comments.add(comment);

      // Nếu là reply, cập nhật danh sách replies của parent comment
      if (parentCommentId != null) {
        await comments.doc(parentCommentId).update({
          'replies': FieldValue.arrayUnion([docRef.id]),
        });
      }

      print('✅ Added comment: ${docRef.id}');
    } catch (e) {
      print('❌ Error adding comment: $e');
      rethrow;
    }
  }

  /// Toggle like comment
  Future<void> toggleLike({
    required String commentId,
    required String userId,
  }) async {
    try {
      final doc = await comments.doc(commentId).get();
      if (!doc.exists) return;

      final comment = doc.data()!;
      final isLiked = comment.likedBy.contains(userId);

      if (isLiked) {
        // Unlike
        await comments.doc(commentId).update({
          'likedBy': FieldValue.arrayRemove([userId]),
          'likes': FieldValue.increment(-1),
        });
      } else {
        // Like
        await comments.doc(commentId).update({
          'likedBy': FieldValue.arrayUnion([userId]),
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('❌ Error toggling like: $e');
      rethrow;
    }
  }

  /// Xóa comment
  Future<void> deleteComment({
    required String commentId,
    required String userId,
  }) async {
    try {
      final doc = await comments.doc(commentId).get();
      if (!doc.exists) return;

      final comment = doc.data()!;

      // Chỉ cho phép user tự xóa comment của mình
      if (comment.userId != userId) {
        throw Exception('Bạn không có quyền xóa comment này');
      }

      // Xóa tất cả replies trước
      for (final replyId in comment.replies) {
        await comments.doc(replyId).delete();
      }

      // Nếu là reply, xóa khỏi danh sách replies của parent
      if (comment.parentCommentId != null) {
        await comments.doc(comment.parentCommentId!).update({
          'replies': FieldValue.arrayRemove([commentId]),
        });
      }

      // Xóa comment
      await comments.doc(commentId).delete();

      print('✅ Deleted comment: $commentId');
    } catch (e) {
      print('❌ Error deleting comment: $e');
      rethrow;
    }
  }

  /// Đếm số lượng comments của một chapter
  Future<int> getCommentCount({
    required String comicId,
    required String chapterId,
  }) async {
    try {
      final snapshot = await comments
          .where('comicId', isEqualTo: comicId)
          .where('chapterId', isEqualTo: chapterId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting comment count: $e');
      return 0;
    }
  }

  /// Lấy tất cả comments của một comic (cho admin)
  Stream<QuerySnapshot<ChapterComment>> getAllComicComments({
    required String comicId,
  }) {
    return comments
        .where('comicId', isEqualTo: comicId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
