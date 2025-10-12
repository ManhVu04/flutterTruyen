import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comic.dart';
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
}
