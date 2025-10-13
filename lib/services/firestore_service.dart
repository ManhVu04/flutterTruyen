import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comic.dart';
import '../models/comic_rating.dart';
import '../models/comic_review.dart';
import '../models/forum_post.dart';
import '../models/leaderboard.dart';
import '../models/user_profile.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<UserProfile> get users => _db
      .collection('users')
      .withConverter<UserProfile>(
        fromFirestore: (snapshot, _) => UserProfile.fromDoc(snapshot),
        toFirestore: (profile, _) => profile.toMap(),
      );

  CollectionReference<Comic> get comics => _db
      .collection('comics')
      .withConverter<Comic>(
        fromFirestore: (snapshot, _) => Comic.fromDoc(snapshot),
        toFirestore: (comic, _) => comic.toMap(),
      );

  DocumentReference<Comic> comicRef(String id) => comics.doc(id);

  CollectionReference<ChapterMeta> chapters(String comicId) => comicRef(comicId)
      .collection('chapters')
      .withConverter<ChapterMeta>(
        fromFirestore: (snapshot, _) => ChapterMeta.fromDoc(snapshot),
        toFirestore: (chapter, _) => chapter.toMap(),
      );

  CollectionReference<ForumPost> get posts => _db
      .collection('posts')
      .withConverter<ForumPost>(
        fromFirestore: (snapshot, _) => ForumPost.fromDoc(snapshot),
        toFirestore: (post, _) => {
          'authorId': post.authorId,
          'content': post.content,
          'attachments': post.attachments,
          'reactions': post.reactions,
          'createdAt': post.createdAt != null
              ? Timestamp.fromDate(post.createdAt!)
              : FieldValue.serverTimestamp(),
          'updatedAt': post.updatedAt != null
              ? Timestamp.fromDate(post.updatedAt!)
              : FieldValue.serverTimestamp(),
        },
      );

  CollectionReference<LeaderboardSnapshot> get leaderboards => _db
      .collection('leaderboards')
      .withConverter<LeaderboardSnapshot>(
        fromFirestore: (snapshot, _) => LeaderboardSnapshot.fromDoc(snapshot),
        toFirestore: (snapshot, _) => {
          'period': snapshot.period,
          'generatedAt': snapshot.generatedAt != null
              ? Timestamp.fromDate(snapshot.generatedAt!)
              : FieldValue.serverTimestamp(),
          'entries': snapshot.entries
              .map(
                (entry) => {
                  'rank': entry.rank,
                  'comicId': entry.comicId,
                  'views': entry.views,
                  'period': entry.period,
                },
              )
              .toList(),
        },
      );

  Stream<UserProfile?> watchProfile(String uid) {
    return users.doc(uid).snapshots().map((snap) => snap.data());
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    final snap = await users.doc(uid).get();
    return snap.data();
  }

  Future<void> upsertProfile(UserProfile profile) {
    return users.doc(profile.id).set(profile, SetOptions(merge: true));
  }

  Future<void> createComic(Comic comic) async {
    await comics.doc(comic.id).set(comic);
  }

  Future<void> updateComic(Comic comic) async {
    await comics.doc(comic.id).update(comic.toMap());
  }

  Future<void> deleteComic(String comicId) async {
    await comics.doc(comicId).delete();
  }

  Future<void> addChapter({
    required String comicId,
    required ChapterMeta chapter,
    String? chapterId,
  }) async {
    final ref = chapters(comicId).doc(chapterId ?? chapter.id);
    await ref.set(chapter);
  }

  Future<void> updateChapter({
    required String comicId,
    required String chapterId,
    required ChapterMeta chapter,
  }) async {
    await chapters(comicId).doc(chapterId).update(chapter.toMap());
  }

  Future<void> deleteChapter({
    required String comicId,
    required String chapterId,
  }) async {
    await chapters(comicId).doc(chapterId).delete();
  }

  // Rating methods
  CollectionReference<ComicRating> ratings(String comicId) => comicRef(comicId)
      .collection('ratings')
      .withConverter<ComicRating>(
        fromFirestore: (snapshot, _) => ComicRating.fromDoc(snapshot),
        toFirestore: (rating, _) => rating.toMap(),
      );

  /// Submit or update a rating for a comic
  Future<void> rateComic({
    required String comicId,
    required String userId,
    required int score,
  }) async {
    if (score < 1 || score > 5) {
      throw ArgumentError('Score must be between 1 and 5');
    }

    final rating = ComicRating(
      userId: userId,
      comicId: comicId,
      score: score,
      createdAt: DateTime.now(),
    );

    // Use userId as document ID to ensure one rating per user
    await ratings(comicId).doc(userId).set(rating);

    // Update comic's average rating
    await _updateComicRating(comicId);
  }

  /// Get user's rating for a comic
  Future<ComicRating?> getUserRating({
    required String comicId,
    required String userId,
  }) async {
    final doc = await ratings(comicId).doc(userId).get();
    return doc.data();
  }

  /// Calculate and update comic's average rating
  Future<void> _updateComicRating(String comicId) async {
    final ratingsSnapshot = await ratings(comicId).get();

    if (ratingsSnapshot.docs.isEmpty) {
      // No ratings yet, set to 0
      await comics.doc(comicId).update({'rating': 0.0});
      return;
    }

    // Calculate average
    final totalScore = ratingsSnapshot.docs.fold<int>(
      0,
      (total, doc) => total + doc.data().score,
    );
    final averageRating = totalScore / ratingsSnapshot.docs.length;

    // Update comic
    await comics.doc(comicId).update({'rating': averageRating});
  }

  /// Get rating statistics for a comic
  Future<Map<String, dynamic>> getComicRatingStats(String comicId) async {
    final ratingsSnapshot = await ratings(comicId).get();

    if (ratingsSnapshot.docs.isEmpty) {
      return {
        'average': 0.0,
        'total': 0,
        'distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }

    final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    var totalScore = 0;

    for (final doc in ratingsSnapshot.docs) {
      final rating = doc.data();
      totalScore += rating.score;
      distribution[rating.score] = (distribution[rating.score] ?? 0) + 1;
    }

    return {
      'average': totalScore / ratingsSnapshot.docs.length,
      'total': ratingsSnapshot.docs.length,
      'distribution': distribution,
    };
  }

  /// Increment comic views count
  Future<void> incrementComicViews(String comicId) async {
    await comics.doc(comicId).update({'views': FieldValue.increment(1)});
  }

  /// Add comic to user's favorites (follow)
  Future<void> addToFavorites({
    required String userId,
    required String comicId,
  }) async {
    await users.doc(userId).update({
      'favorites': FieldValue.arrayUnion([comicId]),
    });
  }

  /// Remove comic from user's favorites (unfollow)
  Future<void> removeFromFavorites({
    required String userId,
    required String comicId,
  }) async {
    await users.doc(userId).update({
      'favorites': FieldValue.arrayRemove([comicId]),
    });
  }

  /// Check if user is following a comic
  Future<bool> isFollowing({
    required String userId,
    required String comicId,
  }) async {
    final userDoc = await users.doc(userId).get();
    final profile = userDoc.data();
    return profile?.favorites.contains(comicId) ?? false;
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite({
    required String userId,
    required String comicId,
  }) async {
    final isCurrentlyFollowing = await isFollowing(
      userId: userId,
      comicId: comicId,
    );

    if (isCurrentlyFollowing) {
      await removeFromFavorites(userId: userId, comicId: comicId);
      return false;
    } else {
      await addToFavorites(userId: userId, comicId: comicId);
      return true;
    }
  }

  // ============ REVIEWS ============

  /// Get reviews collection for a comic
  CollectionReference<ComicReview> reviews(String comicId) => comicRef(comicId)
      .collection('reviews')
      .withConverter<ComicReview>(
        fromFirestore: (snapshot, _) => ComicReview.fromDoc(snapshot),
        toFirestore: (review, _) => review.toMap(),
      );

  /// Add or update a review
  Future<void> addReview({
    required String comicId,
    required String userId,
    required int rating,
    required String comment,
    required String userName,
    String userAvatar = '',
    List<String> images = const [],
    String? reviewId,
  }) async {
    final now = Timestamp.now();
    final reviewData = {
      'userId': userId,
      'comicId': comicId,
      'rating': rating,
      'comment': comment,
      'userName': userName,
      'userAvatar': userAvatar,
      'images': images,
      'updatedAt': now,
      'likes': 0,
      'likedBy': [],
    };

    if (reviewId != null) {
      // Update existing review (keep original createdAt)
      await _db
          .collection('comics')
          .doc(comicId)
          .collection('reviews')
          .doc(reviewId)
          .update(reviewData);
    } else {
      // Add new review
      reviewData['createdAt'] = now;
      await _db
          .collection('comics')
          .doc(comicId)
          .collection('reviews')
          .add(reviewData);
    }

    // Also update the simple rating
    await rateComic(comicId: comicId, userId: userId, score: rating);
  }

  /// Get user's review for a comic
  Future<ComicReview?> getUserReview({
    required String comicId,
    required String userId,
  }) async {
    final snapshot = await reviews(
      comicId,
    ).where('userId', isEqualTo: userId).limit(1).get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data();
  }

  /// Delete a review
  Future<void> deleteReview({
    required String comicId,
    required String reviewId,
  }) async {
    await reviews(comicId).doc(reviewId).delete();
  }

  /// Like/Unlike a review
  Future<void> toggleReviewLike({
    required String comicId,
    required String reviewId,
    required String userId,
  }) async {
    final reviewDoc = await reviews(comicId).doc(reviewId).get();
    final review = reviewDoc.data();

    if (review == null) return;

    final likedBy = List<String>.from(review.likedBy);
    final isLiked = likedBy.contains(userId);

    if (isLiked) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }

    await reviews(
      comicId,
    ).doc(reviewId).update({'likes': likedBy.length, 'likedBy': likedBy});
  }
}
