import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class HistoryItem {
  final Track track;
  final DateTime playedAt;

  const HistoryItem({
    required this.track,
    required this.playedAt,
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(playedAt);
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${playedAt.day}/${playedAt.month}';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'track': track.toMap(),
      'playedAt': playedAt.toIso8601String(),
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      track: Track.fromMap(Map<String, dynamic>.from(map['track'] as Map)),
      playedAt:
          DateTime.tryParse(map['playedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  HistoryItem copyWith({
    Track? track,
    DateTime? playedAt,
  }) {
    return HistoryItem(
      track: track ?? this.track,
      playedAt: playedAt ?? this.playedAt,
    );
  }
}

class HistoryRepository {
  static final HistoryRepository instance = HistoryRepository._internal();

  static Directory? _cachedPermanentDir;
  static const String _historyFileName = 'aura_permanent_history_v1.json';
  static const String _legacyHistoryFileName = 'aura_cache_history.json';
  static const int maxHistory = 100;

  final ValueNotifier<List<HistoryItem>> historyNotifier =
      ValueNotifier<List<HistoryItem>>(<HistoryItem>[]);

  List<HistoryItem> get history => historyNotifier.value;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _firestoreSubscription;
  String? _currentSubscribedUid;

  HistoryRepository._internal() {
    _loadFromDiskSync();
    _initStorageAndSync();
  }

  static Future<Directory> _resolveStorageDir() async {
    if (_cachedPermanentDir != null) return _cachedPermanentDir!;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _cachedPermanentDir = dir;
      return dir;
    } catch (_) {}
    try {
      final dir = await getApplicationSupportDirectory();
      _cachedPermanentDir = dir;
      return dir;
    } catch (_) {}
    try {
      final parent = Directory.systemTemp.parent;
      final filesDir = Directory('${parent.path}/files');
      if (!filesDir.existsSync()) {
        filesDir.createSync(recursive: true);
      }
      _cachedPermanentDir = filesDir;
      return filesDir;
    } catch (_) {}
    _cachedPermanentDir = Directory.systemTemp;
    return _cachedPermanentDir!;
  }

  static File _getFile(String filename) {
    if (_cachedPermanentDir != null) {
      return File('${_cachedPermanentDir!.path}/$filename');
    }
    try {
      final parent = Directory.systemTemp.parent;
      final filesDir = Directory('${parent.path}/files');
      if (filesDir.existsSync()) {
        return File('${filesDir.path}/$filename');
      }
    } catch (_) {}
    return File('${Directory.systemTemp.path}/$filename');
  }

  void _loadFromDiskSync() {
    try {
      // 1. Check permanent file
      final permFile = _getFile(_historyFileName);
      if (permFile.existsSync()) {
        final content = permFile.readAsStringSync().trim();
        if (content.isNotEmpty &&
            content.startsWith('[') &&
            content.endsWith(']')) {
          final List<dynamic> list = jsonDecode(content);
          final items = list
              .map(
                (e) => _sanitizeHistoryItem(
                  HistoryItem.fromMap(
                    Map<String, dynamic>.from(e as Map),
                  ),
                ),
              )
              .toList();
          if (items.isNotEmpty) {
            historyNotifier.value = items;
            return;
          }
        }
      }

      // 2. Check legacy files in system temp / parent files
      final legacyCandidates = [
        _getFile(_legacyHistoryFileName),
        File('${Directory.systemTemp.path}/$_legacyHistoryFileName'),
      ];

      for (final legacyFile in legacyCandidates) {
        if (legacyFile.existsSync()) {
          final content = legacyFile.readAsStringSync().trim();
          if (content.isNotEmpty &&
              content.startsWith('[') &&
              content.endsWith(']')) {
            final List<dynamic> list = jsonDecode(content);
            final items = list
                .map(
                  (e) => _sanitizeHistoryItem(
                    HistoryItem.fromMap(
                      Map<String, dynamic>.from(e as Map),
                    ),
                  ),
                )
                .toList();
            if (items.isNotEmpty) {
              historyNotifier.value = items;
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[HistoryRepository] Error in _loadFromDiskSync: $e');
    }
  }

  static HistoryItem _sanitizeHistoryItem(HistoryItem item) {
    var trk = item.track;
    bool modified = false;
    if (trk.streamUrl != null && !trk.streamUrl!.startsWith('http')) {
      trk = trk.copyWith(streamUrl: null);
      modified = true;
    }
    if (trk.albumArt != null && !trk.albumArt!.startsWith('http')) {
      trk = trk.copyWith(albumArt: null);
      modified = true;
    }
    return modified ? item.copyWith(track: trk) : item;
  }

  Future<void> _initStorageAndSync() async {
    try {
      final permDir = await _resolveStorageDir();
      final permFile = File('${permDir.path}/$_historyFileName');

      // If permanent file does not exist but we loaded memory history, write to permanent
      if (!permFile.existsSync() && historyNotifier.value.isNotEmpty) {
        _saveToDisk();
      } else if (permFile.existsSync()) {
        final content = await permFile.readAsString();
        final trimmed = content.trim();
        if (trimmed.isNotEmpty &&
            trimmed.startsWith('[') &&
            trimmed.endsWith(']')) {
          final List<dynamic> list = jsonDecode(trimmed);
          final items = list
              .map(
                (e) => _sanitizeHistoryItem(
                  HistoryItem.fromMap(
                    Map<String, dynamic>.from(e as Map),
                  ),
                ),
              )
              .toList();
          if (items.isNotEmpty) {
            historyNotifier.value = items;
          }
        }
      }
    } catch (e) {
      debugPrint('[HistoryRepository] Error in _initStorageAndSync: $e');
    }

    _initFirebaseSync();
  }

  void _saveToDisk() {
    try {
      final file = _getFile(_historyFileName);
      final list = historyNotifier.value.map((e) => e.toMap()).toList();
      final encoded = jsonEncode(list);
      file.writeAsStringSync(encoded);

      if (_cachedPermanentDir != null) {
        final permFile = File('${_cachedPermanentDir!.path}/$_historyFileName');
        if (permFile.path != file.path) {
          permFile.writeAsStringSync(encoded);
        }
      }
    } catch (e) {
      debugPrint('[HistoryRepository] Error saving history to disk: $e');
    }
  }

  void _initFirebaseSync() {
    try {
      if (Firebase.apps.isEmpty) return;
      _authSubscription =
          FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _subscribeToFirestore(user.uid);
        } else {
          _unsubscribeFromFirestore();
        }
      });
    } catch (_) {}
  }

  void _subscribeToFirestore(String uid) {
    if (_currentSubscribedUid == uid) return;
    _currentSubscribedUid = uid;
    _firestoreSubscription?.cancel();

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      _firestoreSubscription = docRef.snapshots().listen((snapshot) {
        if (!snapshot.exists) {
          if (historyNotifier.value.isNotEmpty) {
            _syncToFirestore(uid);
          }
          return;
        }

        final data = snapshot.data();
        if (data == null || data['playbackHistory'] == null) return;

        final rawList = data['playbackHistory'] as List<dynamic>;
        final cloudItems = <HistoryItem>[];
        for (final item in rawList) {
          try {
            cloudItems.add(
              _sanitizeHistoryItem(
                HistoryItem.fromMap(Map<String, dynamic>.from(item as Map)),
              ),
            );
          } catch (_) {}
        }

        _mergeHistory(cloudItems);
      }, onError: (e) {
        debugPrint('[HistoryRepository] Firestore subscription error: $e');
      });
    } catch (_) {}
  }

  void clearLocalSession() {
    historyNotifier.value = [];
    try {
      final permFile = _getFile(_historyFileName);
      if (permFile.existsSync()) permFile.deleteSync();
      final legacyFile = _getFile(_legacyHistoryFileName);
      if (legacyFile.existsSync()) legacyFile.deleteSync();
    } catch (_) {}
  }

  void _unsubscribeFromFirestore() {
    _currentSubscribedUid = null;
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    clearLocalSession();
  }

  void _mergeHistory(List<HistoryItem> remoteItems) {
    if (remoteItems.isEmpty) return;
    final Map<String, HistoryItem> itemMap = {};

    // First add local items
    for (final item in historyNotifier.value) {
      itemMap[item.track.id] = item;
    }

    // Then merge remote items, keeping whichever has newer playedAt
    bool updated = false;
    for (final remote in remoteItems) {
      final sanitizedRemote = _sanitizeHistoryItem(remote);
      final local = itemMap[sanitizedRemote.track.id];
      if (local == null) {
        itemMap[sanitizedRemote.track.id] = sanitizedRemote;
        updated = true;
      } else if (sanitizedRemote.playedAt.isAfter(local.playedAt)) {
        itemMap[sanitizedRemote.track.id] = sanitizedRemote;
        updated = true;
      }
    }

    if (updated || itemMap.length != historyNotifier.value.length) {
      final mergedList = itemMap.values.toList()
        ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
      if (mergedList.length > maxHistory) {
        mergedList.removeRange(maxHistory, mergedList.length);
      }
      historyNotifier.value = mergedList;
      _saveToDisk();
    }
  }

  void _syncToFirestore([String? uid]) {
    try {
      if (Firebase.apps.isEmpty) return;
      final targetUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (targetUid == null) return;

      FirebaseFirestore.instance.collection('users').doc(targetUid).set(
        {
          'playbackHistory':
              historyNotifier.value.map((e) => e.toMap()).toList(),
          'historyUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ).catchError((e) {
        debugPrint('[HistoryRepository] Firestore sync error: $e');
      });
    } catch (_) {}
  }

  void addTrack(Track track) {
    Track trackToSave = track;
    if (track.streamUrl != null && !track.streamUrl!.startsWith('http')) {
      final existingIndex =
          historyNotifier.value.indexWhere((h) => h.track.id == track.id);
      if (existingIndex >= 0) {
        final existingUrl =
            historyNotifier.value[existingIndex].track.streamUrl;
        if (existingUrl != null && existingUrl.startsWith('http')) {
          trackToSave = trackToSave.copyWith(streamUrl: existingUrl);
        } else {
          trackToSave = trackToSave.copyWith(streamUrl: null);
        }
      } else {
        trackToSave = trackToSave.copyWith(streamUrl: null);
      }
    }
    if (track.albumArt != null && !track.albumArt!.startsWith('http')) {
      final existingIndex =
          historyNotifier.value.indexWhere((h) => h.track.id == track.id);
      if (existingIndex >= 0) {
        final existingArt =
            historyNotifier.value[existingIndex].track.albumArt;
        if (existingArt != null && existingArt.startsWith('http')) {
          trackToSave = trackToSave.copyWith(albumArt: existingArt);
        } else {
          trackToSave = trackToSave.copyWith(albumArt: null);
        }
      } else {
        trackToSave = trackToSave.copyWith(albumArt: null);
      }
    }

    final currentList = List<HistoryItem>.from(historyNotifier.value);
    currentList.removeWhere((item) => item.track.id == track.id);
    currentList.insert(
      0,
      HistoryItem(track: trackToSave, playedAt: DateTime.now()),
    );
    if (currentList.length > maxHistory) {
      currentList.removeRange(maxHistory, currentList.length);
    }
    historyNotifier.value = currentList;
    _saveToDisk();
    _syncToFirestore();
  }

  void updateTrackMetadata(Track track) {
    if (track.streamUrl == null || !track.streamUrl!.startsWith('http')) return;
    final currentList = List<HistoryItem>.from(historyNotifier.value);
    final idx = currentList.indexWhere((item) => item.track.id == track.id);
    if (idx != -1) {
      final old = currentList[idx];
      currentList[idx] = old.copyWith(
        track: old.track.copyWith(
          streamUrl: track.streamUrl,
          albumArt: (track.albumArt != null && track.albumArt!.startsWith('http'))
              ? track.albumArt
              : old.track.albumArt,
        ),
      );
      historyNotifier.value = currentList;
      _saveToDisk();
      _syncToFirestore();
    }
  }

  void removeTrack(String trackId) {
    final currentList = List<HistoryItem>.from(historyNotifier.value);
    currentList.removeWhere((item) => item.track.id == trackId);
    historyNotifier.value = currentList;
    _saveToDisk();
    _syncToFirestore();
  }

  void clearHistory() {
    historyNotifier.value = [];
    _saveToDisk();
    _syncToFirestore();
  }

  void dispose() {
    _authSubscription?.cancel();
    _firestoreSubscription?.cancel();
  }
}
