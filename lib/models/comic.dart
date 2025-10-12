import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class Comic {
  const Comic({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.tags,
    required this.status,
    required this.views,
    required this.rating,
    required this.vipTier,
    required this.description,
    required this.authorId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String coverUrl;
  final List<String> tags;
  final String status;
  final int views;
  final double rating;
  final int vipTier;
  final String description;
  final String authorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Comic.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Comic(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      coverUrl: data['coverUrl']?.toString() ?? '',
      tags: List<String>.from(data['tags'] ?? const <String>[]),
      status: data['status']?.toString() ?? 'ongoing',
      views: (data['views'] as num?)?.toInt() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      vipTier: (data['vipTier'] as num?)?.toInt() ?? 0,
      description: data['description']?.toString() ?? '',
      authorId: data['authorId']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'coverUrl': coverUrl,
      'tags': tags,
      'status': status,
      'views': views,
      'rating': rating,
      'vipTier': vipTier,
      'description': description,
      'authorId': authorId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    }..removeWhere((key, value) => value == null);
  }
}

@immutable
class ChapterMeta {
  const ChapterMeta({
    required this.id,
    required this.order,
    required this.title,
    required this.releaseAt,
    required this.pages,
    required this.vipRequired,
    this.freeUntil,
  });

  final String id;
  final int order;
  final String title;
  final DateTime? releaseAt;
  final List<String> pages;
  final int vipRequired;
  final DateTime? freeUntil;

  factory ChapterMeta.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ChapterMeta(
      id: doc.id,
      order: (data['order'] as num?)?.toInt() ?? 0,
      title: data['title']?.toString() ?? '',
      releaseAt: (data['releaseAt'] as Timestamp?)?.toDate(),
      pages: List<String>.from(data['pages'] ?? const <String>[]),
      vipRequired: (data['vipRequired'] as num?)?.toInt() ?? 0,
      freeUntil: (data['freeUntil'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order': order,
      'title': title,
      'releaseAt': releaseAt != null ? Timestamp.fromDate(releaseAt!) : null,
      'pages': pages,
      'vipRequired': vipRequired,
      'freeUntil': freeUntil != null ? Timestamp.fromDate(freeUntil!) : null,
    }..removeWhere((key, value) => value == null);
  }
}
