import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cho bình luận chapter
class ChapterComment {
  final String id;
  final String comicId;
  final String chapterId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime createdAt;
  final List<String> likedBy;
  final int likes;
  final String? parentCommentId; // null = comment gốc, có giá trị = reply
  final List<String> replies; // Danh sách ID của replies

  ChapterComment({
    required this.id,
    required this.comicId,
    required this.chapterId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
    required this.likedBy,
    required this.likes,
    this.parentCommentId,
    required this.replies,
  });

  factory ChapterComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChapterComment(
      id: doc.id,
      comicId: data['comicId'] as String? ?? '',
      chapterId: data['chapterId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      userAvatar: data['userAvatar'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      likes: data['likes'] as int? ?? 0,
      parentCommentId: data['parentCommentId'] as String?,
      replies: List<String>.from(data['replies'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'comicId': comicId,
      'chapterId': chapterId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likedBy': likedBy,
      'likes': likes,
      'parentCommentId': parentCommentId,
      'replies': replies,
    };
  }

  ChapterComment copyWith({
    String? id,
    String? comicId,
    String? chapterId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    DateTime? createdAt,
    List<String>? likedBy,
    int? likes,
    String? parentCommentId,
    List<String>? replies,
  }) {
    return ChapterComment(
      id: id ?? this.id,
      comicId: comicId ?? this.comicId,
      chapterId: chapterId ?? this.chapterId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likedBy: likedBy ?? this.likedBy,
      likes: likes ?? this.likes,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
    );
  }
}
