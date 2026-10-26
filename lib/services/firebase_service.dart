import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';
import '../models/models.dart';

/// Central Firebase Service managing Authentication and Firestore operations.
class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal();

  static const String _serverClientId =
      '857660537994-g78eq70mf9noc5ses9je9qojrvctki09.apps.googleusercontent.com';

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  User? get currentUser => auth.currentUser;
  Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Initializes Firebase and Google Sign-In SDKs.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[FirebaseService] Firebase initialized successfully');
    } catch (e) {
      debugPrint('[FirebaseService] Firebase initializeApp error: $e');
    }

    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: _serverClientId,
      );
      debugPrint('[FirebaseService] GoogleSignIn initialized successfully');
    } catch (e) {
      debugPrint('[FirebaseService] GoogleSignIn initialize error: $e');
    }
  }

  // ── Authentication ──────────────────────────────────────────────────────────

  /// Sign in with Email and Password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Sign up with Email, Password, and Display Name.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    if (cred.user != null && displayName.trim().isNotEmpty) {
      await cred.user!.updateDisplayName(displayName.trim());
      await cred.user!.reload();
    }

    // Save basic user profile in Firestore
    if (cred.user != null) {
      try {
        await firestore.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'email': cred.user!.email,
          'displayName': displayName.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'memberTier': 'Atelier Private Listener',
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[FirebaseService] Error creating user profile doc: $e');
      }
    }

    return cred;
  }

  /// Sign in with Google using modern GoogleSignIn v7 Credential Manager.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;

      if (!googleSignIn.supportsAuthenticate()) {
        debugPrint('[FirebaseService] supportsAuthenticate is false on this platform');
        throw UnsupportedError('Google Sign-In is not supported on this device.');
      }

      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);

      // Save user doc in Firestore
      if (userCredential.user != null) {
        try {
          await firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName ?? googleUser.displayName,
            'photoUrl': userCredential.user!.photoURL ?? googleUser.photoUrl,
            'lastLogin': FieldValue.serverTimestamp(),
            'memberTier': 'Atelier Private Listener',
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('[FirebaseService] Error updating Google user doc: $e');
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint('[FirebaseService] Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Send password reset link to email.
  Future<void> sendPasswordReset(String email) async {
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign out from Firebase and Google Sign-In.
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      debugPrint('[FirebaseService] Firebase signOut error: $e');
    }
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('[FirebaseService] GoogleSignIn signOut error: $e');
    }
  }

  // ── Firestore Playlists ─────────────────────────────────────────────────────

  /// Collection reference for user playlists: `users/{userId}/playlists`.
  CollectionReference<Map<String, dynamic>> _userPlaylistsRef(String userId) {
    return firestore.collection('users').doc(userId).collection('playlists');
  }

  /// Fetches all playlists for a specific user.
  Future<List<Playlist>> fetchUserPlaylists(String userId) async {
    try {
      final snapshot = await _userPlaylistsRef(userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Playlist.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[FirebaseService] Error fetching playlists: $e');
      return [];
    }
  }

  /// Real-time stream of user playlists.
  Stream<List<Playlist>> streamUserPlaylists(String userId) {
    return _userPlaylistsRef(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Playlist.fromMap(doc.data()))
          .toList();
    });
  }

  /// Saves or updates a playlist in Firestore for the given user.
  Future<void> saveUserPlaylist(String userId, Playlist playlist) async {
    try {
      await _userPlaylistsRef(userId).doc(playlist.id).set(
            playlist.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('[FirebaseService] Error saving playlist: $e');
    }
  }

  /// Deletes a playlist from Firestore.
  Future<void> deleteUserPlaylist(String userId, String playlistId) async {
    try {
      await _userPlaylistsRef(userId).doc(playlistId).delete();
    } catch (e) {
      debugPrint('[FirebaseService] Error deleting playlist: $e');
    }
  }
}
