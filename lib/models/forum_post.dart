import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class ForumPost {
  const ForumPost({
    required this.id,
    required this.authorId,
    required this.content,
    required this.attachments,
    required this.reactions,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String authorId;
  final String content;
  final List<String> attachments;
  final Map<String, int> reactions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ForumPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ForumPost(
      id: doc.id,
      authorId: data['authorId']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      attachments: List<String>.from(data['attachments'] ?? const <String>[]),
      reactions: Map<String, int>.from(
        (data['reactions'] as Map<String, dynamic>? ??
                const <String, dynamic>{})
            .map((key, value) => MapEntry(key, (value as num).toInt())),
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
