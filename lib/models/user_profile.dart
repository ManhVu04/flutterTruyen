import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.vipLevel,
    required this.coins,
    required this.favorites,
    required this.history,
    required this.downloads,
    required this.readingProgress,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final String email;
  final String avatarUrl;
  final String role;
  final int vipLevel;
  final int coins;
  final List<String> favorites;
  final List<String> history;
  final List<String> downloads;
  final Map<String, dynamic> readingProgress;
  final Map<String, dynamic> settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserProfile(
      id: doc.id,
      displayName: data['displayName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      avatarUrl: data['avatarUrl']?.toString() ?? '',
      role: data['role']?.toString() ?? 'reader',
      vipLevel: (data['vipLevel'] as num?)?.toInt() ?? 0,
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      favorites: List<String>.from(data['favorites'] ?? const <String>[]),
      history: List<String>.from(data['history'] ?? const <String>[]),
      downloads: List<String>.from(data['downloads'] ?? const <String>[]),
      readingProgress: Map<String, dynamic>.from(
        data['readingProgress'] ?? const <String, dynamic>{},
      ),
      settings: Map<String, dynamic>.from(
        data['settings'] ?? const <String, dynamic>{},
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role,
      'vipLevel': vipLevel,
      'coins': coins,
      'favorites': favorites,
      'history': history,
      'downloads': downloads,
      'readingProgress': readingProgress,
      'settings': settings,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    }..removeWhere((key, value) => value == null);
  }

  factory UserProfile.initial({
    required String id,
    String? email,
    String? displayName,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? '',
      email: email ?? '',
      avatarUrl: '',
      role: 'reader',
      vipLevel: 0,
      coins: 0,
      favorites: const <String>[],
      history: const <String>[],
      downloads: const <String>[],
      readingProgress: const <String, dynamic>{},
      settings: const {
        'theme': 'system',
        'language': 'vi',
        'notifications': true,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? role,
    int? vipLevel,
    int? coins,
    List<String>? favorites,
    List<String>? history,
    List<String>? downloads,
    Map<String, dynamic>? readingProgress,
    Map<String, dynamic>? settings,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      vipLevel: vipLevel ?? this.vipLevel,
      coins: coins ?? this.coins,
      favorites: favorites ?? this.favorites,
      history: history ?? this.history,
      downloads: downloads ?? this.downloads,
      readingProgress: readingProgress ?? this.readingProgress,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
