import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/forum_post.dart';

class ForumService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy danh sách posts (mới nhất)
  static Stream<List<ForumPost>> getPosts({int limit = 20}) {
    return _firestore
        .collection('forumPosts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ForumPost.fromDoc(doc)).toList(),
        );
  }

  // Lấy posts của một user
  static Stream<List<ForumPost>> getUserPosts(String userId) {
    return _firestore
        .collection('forumPosts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ForumPost.fromDoc(doc)).toList(),
        );
  }

  // Tạo post mới
  static Future<String> createPost({
    required String userId,
    required String content,
    List<String> imageUrls = const [],
    String? comicId,
  }) async {
    final now = DateTime.now();
    final docRef = await _firestore.collection('forumPosts').add({
      'authorId': userId,
      'content': content,
      'imageUrls': imageUrls,
      'comicId': comicId,
      'likedBy': [],
      'commentCount': 0,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
    return docRef.id;
  }

  // Toggle like
  static Future<void> toggleLike(String postId, String userId) async {
    final docRef = _firestore.collection('forumPosts').doc(postId);
    final doc = await docRef.get();

    if (!doc.exists) return;

    final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);

    if (likedBy.contains(userId)) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }

    await docRef.update({
      'likedBy': likedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Xóa post
  static Future<void> deletePost(String postId) async {
    // Xóa tất cả comments của post
    final commentsSnapshot = await _firestore
        .collection('forumComments')
        .where('postId', isEqualTo: postId)
        .get();

    for (final doc in commentsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Xóa post
    await _firestore.collection('forumPosts').doc(postId).delete();
  }

  // Lấy comments của một post
  static Stream<List<ForumComment>> getComments(String postId) {
    print('🔍 Getting comments for postId: $postId');
    return _firestore
        .collection('forumComments')
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((snapshot) {
          print('📝 Found ${snapshot.docs.length} comments for post $postId');

          // Lấy comments và sort theo createdAt ở client side
          final comments = snapshot.docs
              .map((doc) => ForumComment.fromDoc(doc))
              .toList();

          // Sort theo createdAt (cũ nhất trước)
          comments.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return a.createdAt!.compareTo(b.createdAt!);
          });

          return comments;
        });
  }

  // Thêm comment hoặc reply
  static Future<void> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId, // Nếu có = đây là reply
    String? replyToUserId, // User được reply
  }) async {
    print('💬 Adding comment to postId: $postId');
    print('   userId: $userId');
    print('   content: $content');
    print('   parentCommentId: $parentCommentId');

    // Thêm comment/reply
    final docRef = await _firestore.collection('forumComments').add({
      'postId': postId,
      'userId': userId,
      'content': content,
      'parentCommentId': parentCommentId,
      'replyToUserId': replyToUserId,
      'replyCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('✅ Comment added with ID: ${docRef.id}');

    // Nếu đây là reply, tăng replyCount của parent comment
    if (parentCommentId != null) {
      await _firestore.collection('forumComments').doc(parentCommentId).update({
        'replyCount': FieldValue.increment(1),
      });
      print('✅ Reply count updated for parent comment: $parentCommentId');
    }

    // Tăng commentCount của post
    await _firestore.collection('forumPosts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Comment count updated for post: $postId');
  }

  // Lấy replies của một comment
  static Stream<List<ForumComment>> getReplies(String parentCommentId) {
    return _firestore
        .collection('forumComments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .snapshots()
        .map((snapshot) {
          final replies = snapshot.docs
              .map((doc) => ForumComment.fromDoc(doc))
              .toList();

          // Sort theo createdAt (cũ nhất trước)
          replies.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return a.createdAt!.compareTo(b.createdAt!);
          });

          return replies;
        });
  }

  // Xóa comment (và tất cả replies của nó)
  static Future<void> deleteComment(
    String commentId,
    String postId, {
    String? parentCommentId,
  }) async {
    // Xóa tất cả replies nếu đây là comment gốc
    final repliesSnapshot = await _firestore
        .collection('forumComments')
        .where('parentCommentId', isEqualTo: commentId)
        .get();

    final replyCount = repliesSnapshot.docs.length;

    for (final doc in repliesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Xóa comment
    await _firestore.collection('forumComments').doc(commentId).delete();

    // Giảm replyCount của parent nếu đây là reply
    if (parentCommentId != null) {
      await _firestore.collection('forumComments').doc(parentCommentId).update({
        'replyCount': FieldValue.increment(-1),
      });
    }

    // Giảm commentCount của post (bao gồm cả replies)
    await _firestore.collection('forumPosts').doc(postId).update({
      'commentCount': FieldValue.increment(-(1 + replyCount)),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
