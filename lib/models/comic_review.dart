import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class ComicReview {
  const ComicReview({
    required this.id,
    required this.userId,
    required this.comicId,
    required this.rating,
    required this.comment,
    required this.userName,
    required this.userAvatar,
    this.images = const [],
    required this.createdAt,
    required this.updatedAt,
    this.likes = 0,
    this.likedBy = const [],
  });

  final String id;
  final String userId;
  final String comicId;
  final int rating; // 1-5 stars
  final String comment;
  final String userName;
  final String userAvatar;
  final List<String> images; // URLs of attached images
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likes;
  final List<String> likedBy; // User IDs who liked this review

  factory ComicReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ComicReview(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      comicId: data['comicId']?.toString() ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 5,
      comment: data['comment']?.toString() ?? '',
      userName: data['userName']?.toString() ?? 'Người dùng',
      userAvatar: data['userAvatar']?.toString() ?? '',
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'comicId': comicId,
      'rating': rating,
      'comment': comment,
      'userName': userName,
      'userAvatar': userAvatar,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likes': likes,
      'likedBy': likedBy,
    };
  }

  ComicReview copyWith({
    String? id,
    String? userId,
    String? comicId,
    int? rating,
    String? comment,
    String? userName,
    String? userAvatar,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likes,
    List<String>? likedBy,
  }) {
    return ComicReview(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      comicId: comicId ?? this.comicId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}
