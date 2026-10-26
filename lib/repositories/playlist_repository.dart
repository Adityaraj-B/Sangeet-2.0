import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/playlist_service.dart';

class PlaylistRepository {
  static final PlaylistRepository instance = PlaylistRepository._internal();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription? _firestoreSubscription;
  String? _currentSubscribedUid;
  Timer? _syncTimeoutTimer;

  PlaylistRepository._internal() {
    _loadDiskCache();
    _initFirebaseSync();
  }

  final ValueNotifier<List<Playlist>> playlistsNotifier =
      ValueNotifier<List<Playlist>>(<Playlist>[]);

  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(true);

  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  List<Playlist> get playlists => playlistsNotifier.value;
  bool get isLoading => isLoadingNotifier.value;
  String? get error => errorNotifier.value;
  bool get hasError => errorNotifier.value != null;

  Playlist? getPlaylist(String playlistId) {
    try {
      return playlistsNotifier.value.firstWhere((p) => p.id == playlistId);
    } catch (_) {
      return null;
    }
  }

  void _loadDiskCache() {
    try {
      final file = File('${Directory.systemTemp.path}/aura_cache_playlists.json');
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(content);
          final cached = jsonList
              .map((item) => Playlist.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList();
          if (cached.isNotEmpty) {
            playlistsNotifier.value = cached;
            isLoadingNotifier.value = false;
          }
        }
      }
    } catch (e) {
      debugPrint('[PlaylistRepository] Error loading playlist disk cache: $e');
    }
  }

  void _saveDiskCache(List<Playlist> playlists) {
    try {
      final file = File('${Directory.systemTemp.path}/aura_cache_playlists.json');
      final jsonList = playlists.map((p) => p.toMap()).toList();
      file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[PlaylistRepository] Error saving playlist disk cache: $e');
    }
  }

  void _initFirebaseSync() {
    try {
      _authSubscription =
          FirebaseService.instance.authStateChanges.listen((user) {
        if (user != null) {
          _subscribeToFirestore();
        } else {
          _unsubscribeFromFirestore();
        }
      });

      if (FirebaseAuth.instance.currentUser != null) {
        _subscribeToFirestore();
      } else if (playlistsNotifier.value.isEmpty) {
        isLoadingNotifier.value = false;
      }
    } catch (e) {
      debugPrint('[PlaylistRepository] Error setting up auth listener: $e');
      isLoadingNotifier.value = false;
      errorNotifier.value = 'Failed to initialize session: $e';
    }
  }

  void retryFetch() {
    _currentSubscribedUid = null;
    _subscribeToFirestore();
  }

  void refreshPlaylists() {
    _currentSubscribedUid = null;
    _subscribeToFirestore();
  }

  void _subscribeToFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _currentSubscribedUid = null;
      _firestoreSubscription?.cancel();
      _firestoreSubscription = null;
      isLoadingNotifier.value = false;
      playlistsNotifier.value = [];
      return;
    }

    // Prevent duplicate stream listeners if already listening to the same user
    if (_currentSubscribedUid == user.uid && _firestoreSubscription != null) {
      return;
    }
    _currentSubscribedUid = user.uid;

    _firestoreSubscription?.cancel();

    // If we already have playlists (from disk cache), keep UI interactive without full skeleton flash
    if (playlistsNotifier.value.isEmpty) {
      isLoadingNotifier.value = true;
    }
    errorNotifier.value = null;

    // Fast safety timeout: Never leave the user stuck on "SYNCING..." skeleton for more than 2.5s
    _syncTimeoutTimer?.cancel();
    _syncTimeoutTimer = Timer(const Duration(milliseconds: 2500), () {
      if (isLoadingNotifier.value) {
        isLoadingNotifier.value = false;
      }
    });

    try {
      debugPrint(
          '[PlaylistRepository] Subscribing to Firestore playlists for user ${user.uid}');
      _firestoreSubscription = PlaylistService.instance
          .playlistsStream()
          .listen((snapshot) {
        _syncTimeoutTimer?.cancel();
        debugPrint(
            '[PlaylistRepository] Firestore emitted ${snapshot.docs.length} playlists');

        final fetched = <Playlist>[];
        for (final doc in snapshot.docs) {
          try {
            fetched.add(Playlist.fromFirestore(doc.id, doc.data()));
          } catch (e) {
            debugPrint('[PlaylistRepository] Error parsing playlist ${doc.id}: $e');
          }
        }

        // Sort by creation date descending
        fetched.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        playlistsNotifier.value = fetched;
        isLoadingNotifier.value = false;
        errorNotifier.value = null;
        _saveDiskCache(fetched);
      }, onError: (err) {
        _syncTimeoutTimer?.cancel();
        debugPrint('[PlaylistRepository] Firestore playlists stream error: $err');
        isLoadingNotifier.value = false;
        if (playlistsNotifier.value.isEmpty) {
          errorNotifier.value = 'Unable to fetch playlists. Please check your connection.';
        }
      });
    } catch (e) {
      _syncTimeoutTimer?.cancel();
      debugPrint('[PlaylistRepository] Subscription error: $e');
      isLoadingNotifier.value = false;
      if (playlistsNotifier.value.isEmpty) {
        errorNotifier.value = 'Subscription error: $e';
      }
    }
  }

  void _unsubscribeFromFirestore() {
    _syncTimeoutTimer?.cancel();
    _currentSubscribedUid = null;
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    playlistsNotifier.value = [];
    isLoadingNotifier.value = false;
    errorNotifier.value = null;
    try {
      final file = File('${Directory.systemTemp.path}/aura_cache_playlists.json');
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  /// Creates a new playlist, updates local state immediately, and writes to Firestore.
  Playlist createPlaylist({
    required String name,
    String description = 'Curated by you',
    String? coverUrl,
    List<Track> initialTracks = const [],
    String telemetryBadge = 'STUDIO MASTER',
  }) {
    final newPlaylist = Playlist(
      id: 'pl-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Untitled Curation' : name.trim(),
      description: description,
      customCoverUrl: coverUrl,
      tracks: initialTracks,
      telemetryBadge: telemetryBadge,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updated = List<Playlist>.from(playlistsNotifier.value);
    updated.insert(0, newPlaylist);
    playlistsNotifier.value = updated;

    // Sync to Firestore
    if (PlaylistService.instance.hasUser) {
      PlaylistService.instance.createPlaylist(
        newPlaylist.name,
        customId: newPlaylist.id,
        initialData: newPlaylist.toMap(),
      ).catchError((e) {
        debugPrint('[PlaylistRepository] createPlaylist Firestore error: $e');
        return '';
      });
    }

    return newPlaylist;
  }

  /// Deletes a playlist by ID locally and in Firestore.
  bool deletePlaylist(String playlistId) {
    final updated = List<Playlist>.from(playlistsNotifier.value);
    final countBefore = updated.length;
    updated.removeWhere((p) => p.id == playlistId);
    if (updated.length != countBefore) {
      playlistsNotifier.value = updated;

      if (PlaylistService.instance.hasUser) {
        PlaylistService.instance.deletePlaylist(playlistId).catchError((e) {
          debugPrint('[PlaylistRepository] deletePlaylist Firestore error: $e');
        });
      }

      return true;
    }
    return false;
  }

  /// Renames and optionally updates the description of a playlist.
  bool renamePlaylist(
    String playlistId,
    String newName, {
    String? newDescription,
  }) {
    final updated = List<Playlist>.from(playlistsNotifier.value);
    final idx = updated.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = updated[idx];
      final modified = current.copyWith(
        name: newName.trim().isEmpty ? current.name : newName.trim(),
        description: newDescription ?? current.description,
        updatedAt: DateTime.now(),
      );
      updated[idx] = modified;
      playlistsNotifier.value = updated;

      if (PlaylistService.instance.hasUser) {
        PlaylistService.instance.renamePlaylist(playlistId, modified.name).catchError((e) {
          debugPrint('[PlaylistRepository] renamePlaylist Firestore error: $e');
        });
      }

      return true;
    }
    return false;
  }

  /// Adds a single track to the playlist if not already present.
  bool addTrackToPlaylist(String playlistId, Track track) {
    final updated = List<Playlist>.from(playlistsNotifier.value);
    final idx = updated.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = updated[idx];
      final currentTracks = List<Track>.from(current.tracks);
      // If already present, don't duplicate
      if (currentTracks.any((t) => t.id == track.id)) {
        return false;
      }
      currentTracks.add(track);
      final modified = current.copyWith(
        tracks: currentTracks,
        updatedAt: DateTime.now(),
      );
      updated[idx] = modified;
      playlistsNotifier.value = updated;

      if (PlaylistService.instance.hasUser) {
        PlaylistService.instance.addSongToPlaylist(
          playlistId,
          track.id,
          track.toMap(),
        ).catchError((e) {
          debugPrint('[PlaylistRepository] addSongToPlaylist Firestore error: $e');
        });
      }

      return true;
    }
    return false;
  }

  /// Adds multiple tracks to the playlist.
  int addTracksToPlaylist(String playlistId, List<Track> tracks) {
    final updated = List<Playlist>.from(playlistsNotifier.value);
    final idx = updated.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = updated[idx];
      final currentTracks = List<Track>.from(current.tracks);
      var addedCount = 0;
      for (final t in tracks) {
        if (!currentTracks.any((existing) => existing.id == t.id)) {
          currentTracks.add(t);
          addedCount++;
        }
      }
      if (addedCount > 0) {
        final modified = current.copyWith(
          tracks: currentTracks,
          updatedAt: DateTime.now(),
        );
        updated[idx] = modified;
        playlistsNotifier.value = updated;

        if (PlaylistService.instance.hasUser) {
          PlaylistService.instance.updatePlaylistSongs(
            playlistId,
            currentTracks.map((t) => t.id).toList(),
            currentTracks.map((t) => t.toMap()).toList(),
          ).catchError((e) {
            debugPrint('[PlaylistRepository] updatePlaylistSongs Firestore error: $e');
          });
        }
      }
      return addedCount;
    }
    return 0;
  }

  /// Removes a track from a playlist by ID.
  bool removeTrackFromPlaylist(String playlistId, String trackId) {
    final updated = List<Playlist>.from(playlistsNotifier.value);
    final idx = updated.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = updated[idx];
      final currentTracks = List<Track>.from(current.tracks);
      final countBefore = currentTracks.length;
      currentTracks.removeWhere((t) => t.id == trackId);
      if (currentTracks.length != countBefore) {
        final modified = current.copyWith(
          tracks: currentTracks,
          updatedAt: DateTime.now(),
        );
        updated[idx] = modified;
        playlistsNotifier.value = updated;

        if (PlaylistService.instance.hasUser) {
          PlaylistService.instance.updatePlaylistSongs(
            playlistId,
            currentTracks.map((t) => t.id).toList(),
            currentTracks.map((t) => t.toMap()).toList(),
          ).catchError((e) {
            debugPrint('[PlaylistRepository] removeTrack Firestore error: $e');
          });
        }

        return true;
      }
    }
    return false;
  }

  /// Reorders a track within a playlist.
  bool reorderTrack(String playlistId, int oldIndex, int newIndex) {
    final updated = List<Playlist>.from(playlistsNotifier.value);
    final idx = updated.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = updated[idx];
      final currentTracks = List<Track>.from(current.tracks);
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      if (oldIndex >= 0 &&
          oldIndex < currentTracks.length &&
          newIndex >= 0 &&
          newIndex < currentTracks.length) {
        final item = currentTracks.removeAt(oldIndex);
        currentTracks.insert(newIndex, item);
        final modified = current.copyWith(
          tracks: currentTracks,
          updatedAt: DateTime.now(),
        );
        updated[idx] = modified;
        playlistsNotifier.value = updated;

        if (PlaylistService.instance.hasUser) {
          PlaylistService.instance.updatePlaylistSongs(
            playlistId,
            currentTracks.map((t) => t.id).toList(),
            currentTracks.map((t) => t.toMap()).toList(),
          ).catchError((e) {
            debugPrint('[PlaylistRepository] reorderTrack Firestore error: $e');
          });
        }

        return true;
      }
    }
    return false;
  }

  void dispose() {
    _authSubscription?.cancel();
    _firestoreSubscription?.cancel();
  }
}
