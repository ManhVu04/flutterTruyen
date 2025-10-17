import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class ForumPost {
  const ForumPost({
    required this.id,
    required this.authorId,
    required this.content,
    required this.imageUrls,
    this.comicId,
    required this.likedBy,
    required this.commentCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String authorId;
  final String content;
  final List<String> imageUrls; // Hình ảnh đính kèm
  final String? comicId; // Gắn thẻ truyện (optional)
  final List<String> likedBy; // Danh sách userId đã like
  final int commentCount; // Số lượng comment
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get likeCount => likedBy.length;

  factory ForumPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ForumPost(
      id: doc.id,
      authorId: data['authorId']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? const <String>[]),
      comicId: data['comicId']?.toString(),
      likedBy: List<String>.from(data['likedBy'] ?? const <String>[]),
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'content': content,
      'imageUrls': imageUrls,
      'comicId': comicId,
      'likedBy': likedBy,
      'commentCount': commentCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    }..removeWhere((key, value) => value == null);
  }
}

@immutable
class ForumComment {
  const ForumComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.parentCommentId, // ID của comment cha (null nếu là comment gốc)
    this.replyToUserId, // ID của user được reply
    this.replyCount = 0, // Số lượng replies
  });

  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime? createdAt;
  final String? parentCommentId; // null = comment gốc, có giá trị = reply
  final String? replyToUserId; // User được reply
  final int replyCount; // Số replies của comment này

  // Check if this is a reply
  bool get isReply => parentCommentId != null;

  factory ForumComment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ForumComment(
      id: doc.id,
      postId: data['postId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      parentCommentId: data['parentCommentId']?.toString(),
      replyToUserId: data['replyToUserId']?.toString(),
      replyCount: (data['replyCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'content': content,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'parentCommentId': parentCommentId,
      'replyToUserId': replyToUserId,
      'replyCount': replyCount,
    }..removeWhere((key, value) => value == null);
  }
}
