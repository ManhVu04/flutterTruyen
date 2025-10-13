import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class ComicRating {
  const ComicRating({
    required this.userId,
    required this.comicId,
    required this.score,
    required this.createdAt,
  });

  final String userId;
  final String comicId;
  final int score; // 1-5 stars
  final DateTime createdAt;

  factory ComicRating.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ComicRating(
      userId: data['userId']?.toString() ?? '',
      comicId: data['comicId']?.toString() ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'comicId': comicId,
      'score': score,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
