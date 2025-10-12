import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleSignIn? _googleSignIn;
  OAuthCredential? _pendingCredential;
  String? _pendingEmail;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (displayName != null && displayName.isNotEmpty) {
      await credential.user?.updateDisplayName(displayName);
    }
    await _ensureProfile(credential.user);
    await _maybeLinkPendingCredential(credential.user);
    return credential;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _ensureProfile(credential.user);
    await _maybeLinkPendingCredential(credential.user);
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      final credential = await _auth.signInWithPopup(googleProvider);
      await _ensureProfile(credential.user);
      return credential;
    }

    final googleUser = await (_googleSignIn ??= GoogleSignIn()).signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Google sign-in was cancelled',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = await _auth.signInWithCredential(
      GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      ),
    );
    await _ensureProfile(credential.user);
    await _maybeLinkPendingCredential(credential.user);
    return credential;
  }

  Future<UserCredential> signInWithFacebook() async {
    if (kIsWeb) {
      final facebookProvider = FacebookAuthProvider();
      final credential = await _auth.signInWithPopup(facebookProvider);
      await _ensureProfile(credential.user);
      return credential;
    }

    final loginResult = await FacebookAuth.instance.login();
    if (loginResult.status != LoginStatus.success ||
        loginResult.accessToken == null) {
      throw FirebaseAuthException(
        code: loginResult.status.name,
        message: loginResult.message ?? 'Facebook sign-in failed',
      );
    }

    final oauthCredential = FacebookAuthProvider.credential(
      loginResult.accessToken!.tokenString,
    );
    final credential = await _auth.signInWithCredential(oauthCredential);
    await _ensureProfile(credential.user);
    await _maybeLinkPendingCredential(credential.user);
    return credential;
  }

  Future<UserCredential> signInWithGitHub() async {
    final provider = GithubAuthProvider()
      ..addScope('read:user')
      ..addScope('user:email')
      ..setCustomParameters({'allow_signup': 'false'});

    final credential = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);

    await _ensureProfile(credential.user);
    await _maybeLinkPendingCredential(credential.user);
    return credential;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await (_googleSignIn ??= GoogleSignIn()).signOut();
      await FacebookAuth.instance.logOut();
    }
    await _auth.signOut();
  }

  Future<String?> handleAuthException(FirebaseAuthException error) async {
    if (error.code != 'account-exists-with-different-credential' ||
        error.email == null ||
        error.credential == null) {
      return error.message;
    }

    final credential = error.credential;
    if (credential is OAuthCredential) {
      _pendingCredential = credential;
      _pendingEmail = error.email;
    } else {
      _pendingCredential = null;
      _pendingEmail = null;
      return error.message;
    }

    return 'Email ${error.email} da duoc dang ky voi nha cung cap khac. Dang nhap bang nha cung cap ban da dung truoc, sau do thu lai de lien ket tai khoan.';
  }

  Future<void> _maybeLinkPendingCredential(User? user) async {
    if (user == null ||
        _pendingCredential == null ||
        _pendingEmail == null ||
        user.email?.toLowerCase() != _pendingEmail?.toLowerCase()) {
      return;
    }

    try {
      await user.linkWithCredential(_pendingCredential!);
    } on FirebaseAuthException {
      // ignore: If linking fails we keep original provider active.
    } finally {
      _pendingCredential = null;
      _pendingEmail = null;
    }
  }

  Future<void> _ensureProfile(User? user) async {
    if (user == null) return;
    final doc = _firestore.collection('users').doc(user.uid);
    final snapshot = await doc.get();

    if (snapshot.exists) return;

    await doc.set({
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'level': 'Luyen Khi Tang 1',
      'vip': false,
      'favorites': <String>[],
      'readingProgress': <String, Map<String, dynamic>>{},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateReadingProgress({
    required String comicId,
    required int chapter,
    required int page,
  }) async {
    final user = currentUser;
    if (user == null) return;
    final doc = _firestore.collection('users').doc(user.uid);
    await doc.set({
      'readingProgress': {
        comicId: {
          'chapter': chapter,
          'page': page,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleFavorite(String comicId) async {
    final user = currentUser;
    if (user == null) return;
    final doc = _firestore.collection('users').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      final favorites = List<String>.from(
        snapshot.data()?['favorites'] ?? <String>[],
      );
      if (favorites.contains(comicId)) {
        favorites.remove(comicId);
      } else {
        favorites.add(comicId);
      }
      transaction.update(doc, {
        'favorites': favorites,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
