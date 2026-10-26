import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';

/// Repository responsible for persisting and syncing user's Liked Songs
/// and Liked Playlists.
///
/// Ensures offline persistence on device storage so data is never lost when
/// the app is closed, and provides real-time Firestore sync when authenticated.
class FavoritesRepository {
  static final FavoritesRepository instance = FavoritesRepository._internal();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _firestoreSubscription;
  String? _currentSubscribedUid;

  FavoritesRepository._internal() {
    _loadFromDisk();
    _initFirebaseSync();
  }

  // ── Reactive State Notifiers ──────────────────────────────────────────────

  /// List of liked songs in order (most recently liked first).
  final ValueNotifier<List<Track>> likedSongsNotifier =
      ValueNotifier<List<Track>>(<Track>[]);

  /// Fast lookup set for liked song IDs.
  final ValueNotifier<Set<String>> likedSongIdsNotifier =
      ValueNotifier<Set<String>>(<String>{});

  /// List of liked playlists.
  final ValueNotifier<List<Playlist>> likedPlaylistsNotifier =
      ValueNotifier<List<Playlist>>(<Playlist>[]);

  /// Fast lookup set for liked playlist IDs.
  final ValueNotifier<Set<String>> likedPlaylistIdsNotifier =
      ValueNotifier<Set<String>>(<String>{});

  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Track> get likedSongs => likedSongsNotifier.value;
  Set<String> get likedSongIds => likedSongIdsNotifier.value;
  int get likedSongsCount => likedSongsNotifier.value.length;

  List<Playlist> get likedPlaylists => likedPlaylistsNotifier.value;
  Set<String> get likedPlaylistIds => likedPlaylistIdsNotifier.value;
  int get likedPlaylistsCount => likedPlaylistIdsNotifier.value.length;

  bool isSongLiked(String trackId) => likedSongIdsNotifier.value.contains(trackId);
  bool isPlaylistLiked(String playlistId) =>
      likedPlaylistIdsNotifier.value.contains(playlistId);

  // ── File Storage Helpers (On-Device Persistence) ──────────────────────────

  File _getPersistentFile(String filename) {
    try {
      final parent = Directory.systemTemp.parent;
      final filesDir = Directory('${parent.path}/files');
      if (filesDir.existsSync()) {
        return File('${filesDir.path}/$filename');
      }
    } catch (_) {}
    return File('${Directory.systemTemp.path}/$filename');
  }

  File? _findExistingFile(String filename) {
    try {
      final parent = Directory.systemTemp.parent;
      final primary = File('${parent.path}/files/$filename');
      if (primary.existsSync()) return primary;
    } catch (_) {}
    final fallback = File('${Directory.systemTemp.path}/$filename');
    if (fallback.existsSync()) return fallback;
    return null;
  }

  void _loadFromDisk() {
    try {
      // 1. Load Liked Songs
      final songsFile = _findExistingFile('aura_liked_songs.json');
      if (songsFile != null && songsFile.existsSync()) {
        final content = songsFile.readAsStringSync().trim();
        if (content.startsWith('[') && content.endsWith(']')) {
          final List<dynamic> jsonList = jsonDecode(content);
          final parsed = <Track>[];
          final ids = <String>{};
          for (final item in jsonList) {
            try {
              final track = Track.fromMap(Map<String, dynamic>.from(item as Map));
              if (track.id.isNotEmpty && !ids.contains(track.id)) {
                parsed.add(track);
                ids.add(track.id);
              }
            } catch (e) {
              debugPrint('[FavoritesRepository] Error parsing cached song: $e');
            }
          }
          likedSongsNotifier.value = parsed;
          likedSongIdsNotifier.value = ids;
        }
      }

      // 2. Load Liked Playlists
      final playlistsFile = _findExistingFile('aura_liked_playlists.json');
      if (playlistsFile != null && playlistsFile.existsSync()) {
        final content = playlistsFile.readAsStringSync().trim();
        if (content.startsWith('[') && content.endsWith(']')) {
          final List<dynamic> jsonList = jsonDecode(content);
          final parsed = <Playlist>[];
          final ids = <String>{};
          for (final item in jsonList) {
            try {
              final pl = Playlist.fromMap(Map<String, dynamic>.from(item as Map));
              if (pl.id.isNotEmpty && !ids.contains(pl.id)) {
                parsed.add(pl);
                ids.add(pl.id);
              }
            } catch (e) {
              debugPrint('[FavoritesRepository] Error parsing cached playlist: $e');
            }
          }
          likedPlaylistsNotifier.value = parsed;
          likedPlaylistIdsNotifier.value = ids;
        }
      }
    } catch (e) {
      debugPrint('[FavoritesRepository] Error loading favorites from disk: $e');
    }
  }

  void _saveToDisk() {
    try {
      // 1. Save Liked Songs
      final songsFile = _getPersistentFile('aura_liked_songs.json');
      final songsList = likedSongsNotifier.value.map((t) => t.toMap()).toList();
      songsFile.writeAsStringSync(jsonEncode(songsList), flush: true);

      // 2. Save Liked Playlists
      final playlistsFile = _getPersistentFile('aura_liked_playlists.json');
      final playlistsList =
          likedPlaylistsNotifier.value.map((p) => p.toMap()).toList();
      playlistsFile.writeAsStringSync(jsonEncode(playlistsList), flush: true);
    } catch (e) {
      debugPrint('[FavoritesRepository] Error saving favorites to disk: $e');
    }
  }

  // ── Firebase Cloud Sync ───────────────────────────────────────────────────

  void _initFirebaseSync() {
    try {
      if (Firebase.apps.isEmpty) return;
      _authSubscription = FirebaseService.instance.authStateChanges.listen((user) {
        if (user != null) {
          _subscribeToFirestore(user.uid);
        } else {
          _unsubscribeFromFirestore();
        }
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _subscribeToFirestore(user.uid);
      }
    } catch (e) {
      debugPrint('[FavoritesRepository] Firebase sync init error: $e');
    }
  }

  DocumentReference<Map<String, dynamic>> _userFavoritesDoc(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('library')
        .doc('favorites');
  }

  void _subscribeToFirestore(String uid) {
    if (_currentSubscribedUid == uid && _firestoreSubscription != null) return;
    _currentSubscribedUid = uid;
    _firestoreSubscription?.cancel();

    try {
      _firestoreSubscription = _userFavoritesDoc(uid).snapshots().listen(
        (docSnap) {
          if (!docSnap.exists || docSnap.data() == null) {
            // First time this user logs in or doc doesn't exist: push local cache up
            if (likedSongs.isNotEmpty || likedPlaylists.isNotEmpty) {
              _syncToFirestore(uid);
            }
            return;
          }

          final data = docSnap.data()!;
          final remoteSongsRaw = data['songs'] as List<dynamic>? ?? [];
          final remotePlaylistsRaw = data['playlists'] as List<dynamic>? ?? [];

          final mergedSongs = List<Track>.from(likedSongsNotifier.value);
          final songIds = Set<String>.from(likedSongIdsNotifier.value);

          for (final item in remoteSongsRaw) {
            try {
              final track = Track.fromMap(Map<String, dynamic>.from(item as Map));
              if (track.id.isNotEmpty && !songIds.contains(track.id)) {
                mergedSongs.add(track);
                songIds.add(track.id);
              }
            } catch (_) {}
          }

          final mergedPlaylists = List<Playlist>.from(likedPlaylistsNotifier.value);
          final playlistIds = Set<String>.from(likedPlaylistIdsNotifier.value);

          for (final item in remotePlaylistsRaw) {
            try {
              final pl = Playlist.fromMap(Map<String, dynamic>.from(item as Map));
              if (pl.id.isNotEmpty && !playlistIds.contains(pl.id)) {
                mergedPlaylists.add(pl);
                playlistIds.add(pl.id);
              }
            } catch (_) {}
          }

          likedSongsNotifier.value = mergedSongs;
          likedSongIdsNotifier.value = songIds;
          likedPlaylistsNotifier.value = mergedPlaylists;
          likedPlaylistIdsNotifier.value = playlistIds;

          _saveToDisk();
        },
        onError: (err) {
          debugPrint('[FavoritesRepository] Firestore subscription error: $err');
        },
      );
    } catch (e) {
      debugPrint('[FavoritesRepository] Firestore subscribe error: $e');
    }
  }

  void clearLocalSession() {
    likedSongsNotifier.value = [];
    likedSongIdsNotifier.value = {};
    likedPlaylistsNotifier.value = [];
    likedPlaylistIdsNotifier.value = {};
    try {
      final songsFile = _getPersistentFile('aura_liked_songs.json');
      if (songsFile.existsSync()) songsFile.deleteSync();
      final playlistsFile = _getPersistentFile('aura_liked_playlists.json');
      if (playlistsFile.existsSync()) playlistsFile.deleteSync();
    } catch (_) {}
  }

  void _unsubscribeFromFirestore() {
    _currentSubscribedUid = null;
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    clearLocalSession();
  }

  void _syncToFirestore([String? uid]) {
    try {
      if (Firebase.apps.isEmpty) return;
      final currentUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      _userFavoritesDoc(currentUid).set(
        {
          'songIds': likedSongIds.toList(),
          'songs': likedSongs.map((t) => t.toMap()).toList(),
          'playlistIds': likedPlaylistIds.toList(),
          'playlists': likedPlaylists.map((p) => p.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ).catchError((e) {
        debugPrint('[FavoritesRepository] Firestore sync error: $e');
      });
    } catch (_) {}
  }

  // ── Liked Songs Mutations ─────────────────────────────────────────────────

  /// Toggles like status of a song.
  /// Returns `true` if track is now liked, `false` if unliked.
  Future<bool> toggleLikeSong(Track track) async {
    final currentlyLiked = isSongLiked(track.id);
    if (currentlyLiked) {
      await unlikeSong(track.id);
      return false;
    } else {
      await likeSong(track);
      return true;
    }
  }

  /// Adds a track to Liked Songs (most recently liked at top).
  Future<void> likeSong(Track track) async {
    final currentList = List<Track>.from(likedSongsNotifier.value);
    currentList.removeWhere((t) => t.id == track.id);
    currentList.insert(0, track);

    final currentIds = Set<String>.from(likedSongIdsNotifier.value);
    currentIds.add(track.id);

    likedSongsNotifier.value = currentList;
    likedSongIdsNotifier.value = currentIds;

    _saveToDisk();
    _syncToFirestore();
  }

  /// Removes a track from Liked Songs by ID.
  Future<void> unlikeSong(String trackId) async {
    final currentList = List<Track>.from(likedSongsNotifier.value);
    final countBefore = currentList.length;
    currentList.removeWhere((t) => t.id == trackId);

    if (currentList.length != countBefore) {
      final currentIds = Set<String>.from(likedSongIdsNotifier.value);
      currentIds.remove(trackId);

      likedSongsNotifier.value = currentList;
      likedSongIdsNotifier.value = currentIds;

      _saveToDisk();
      _syncToFirestore();
    }
  }

  /// Bulk add multiple tracks to Liked Songs.
  Future<int> addSongsToLiked(List<Track> tracks) async {
    final currentList = List<Track>.from(likedSongsNotifier.value);
    final currentIds = Set<String>.from(likedSongIdsNotifier.value);
    var addedCount = 0;

    for (final track in tracks) {
      if (!currentIds.contains(track.id)) {
        currentList.insert(0, track);
        currentIds.add(track.id);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      likedSongsNotifier.value = currentList;
      likedSongIdsNotifier.value = currentIds;
      _saveToDisk();
      _syncToFirestore();
    }

    return addedCount;
  }

  /// Clears all liked songs.
  Future<void> clearLikedSongs() async {
    likedSongsNotifier.value = [];
    likedSongIdsNotifier.value = {};
    _saveToDisk();
    _syncToFirestore();
  }

  // ── Liked Playlists Mutations ─────────────────────────────────────────────

  /// Toggles like status of a playlist.
  /// Returns `true` if playlist is now liked, `false` if unliked.
  Future<bool> toggleLikePlaylist(Playlist playlist) async {
    final currentlyLiked = isPlaylistLiked(playlist.id);
    if (currentlyLiked) {
      await unlikePlaylist(playlist.id);
      return false;
    } else {
      await likePlaylist(playlist);
      return true;
    }
  }

  /// Adds a playlist to Liked Playlists.
  Future<void> likePlaylist(Playlist playlist) async {
    final currentList = List<Playlist>.from(likedPlaylistsNotifier.value);
    currentList.removeWhere((p) => p.id == playlist.id);
    currentList.insert(0, playlist);

    final currentIds = Set<String>.from(likedPlaylistIdsNotifier.value);
    currentIds.add(playlist.id);

    likedPlaylistsNotifier.value = currentList;
    likedPlaylistIdsNotifier.value = currentIds;

    _saveToDisk();
    _syncToFirestore();
  }

  /// Removes a playlist from Liked Playlists by ID.
  Future<void> unlikePlaylist(String playlistId) async {
    final currentList = List<Playlist>.from(likedPlaylistsNotifier.value);
    final countBefore = currentList.length;
    currentList.removeWhere((p) => p.id == playlistId);

    if (currentList.length != countBefore) {
      final currentIds = Set<String>.from(likedPlaylistIdsNotifier.value);
      currentIds.remove(playlistId);

      likedPlaylistsNotifier.value = currentList;
      likedPlaylistIdsNotifier.value = currentIds;

      _saveToDisk();
      _syncToFirestore();
    }
  }

  /// Clears all liked playlists.
  Future<void> clearLikedPlaylists() async {
    likedPlaylistsNotifier.value = [];
    likedPlaylistIdsNotifier.value = {};
    _saveToDisk();
    _syncToFirestore();
  }

  void dispose() {
    _authSubscription?.cancel();
    _firestoreSubscription?.cancel();
  }
}
