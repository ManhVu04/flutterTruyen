import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.comicId,
    required this.views,
    required this.period,
  });

  final int rank;
  final String comicId;
  final int views;
  final String period;

  factory LeaderboardEntry.fromMap(Map<String, dynamic> data) {
    return LeaderboardEntry(
      rank: (data['rank'] as num?)?.toInt() ?? 0,
      comicId: data['comicId']?.toString() ?? '',
      views: (data['views'] as num?)?.toInt() ?? 0,
      period: data['period']?.toString() ?? 'weekly',
    );
  }
}

@immutable
class LeaderboardSnapshot {
  const LeaderboardSnapshot({
    required this.id,
    required this.period,
    required this.generatedAt,
    required this.entries,
  });

  final String id;
  final String period;
  final DateTime? generatedAt;
  final List<LeaderboardEntry> entries;

  factory LeaderboardSnapshot.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawEntries = data['entries'] as List<dynamic>? ?? const <dynamic>[];
    return LeaderboardSnapshot(
      id: doc.id,
      period: data['period']?.toString() ?? doc.id,
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate(),
      entries: rawEntries
          .map(
            (entry) => LeaderboardEntry.fromMap(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
    );
  }
}
