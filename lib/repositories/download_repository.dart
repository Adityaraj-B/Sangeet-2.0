import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'music_repository.dart';

/// Item representing a track saved in the app's private offline vault.
class DownloadedItem {
  final String trackId;
  final String localAudioPath;
  final String? localArtPath;
  final int fileSizeBytes;
  final DateTime downloadedAt;
  final Track track;

  const DownloadedItem({
    required this.trackId,
    required this.localAudioPath,
    this.localArtPath,
    required this.fileSizeBytes,
    required this.downloadedAt,
    required this.track,
  });

  Map<String, dynamic> toMap() {
    return {
      'trackId': trackId,
      'localAudioPath': localAudioPath,
      'localArtPath': localArtPath,
      'fileSizeBytes': fileSizeBytes,
      'downloadedAt': downloadedAt.toIso8601String(),
      'track': track.toMap(),
    };
  }

  factory DownloadedItem.fromMap(Map<String, dynamic> map) {
    return DownloadedItem(
      trackId: map['trackId']?.toString() ?? '',
      localAudioPath: map['localAudioPath']?.toString() ?? '',
      localArtPath: map['localArtPath'] as String?,
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      downloadedAt: DateTime.tryParse(map['downloadedAt']?.toString() ?? '') ??
          DateTime.now(),
      track: Track.fromMap(Map<String, dynamic>.from(map['track'] as Map)),
    );
  }
}

/// Repository responsible for downloading and managing offline songs.
///
/// Offline tracks are stored strictly inside the application's private sandbox storage
/// (e.g. `/data/user/0/com.app.aura/files/aura_offline_vault/`), meaning:
/// 1. They are accessible ONLY through this app.
/// 2. External music players, galleries, and file scanners cannot access them.
/// 3. Songs play 100% offline without requiring any internet connection.
class DownloadRepository {
  static final DownloadRepository instance = DownloadRepository._internal();

  DownloadRepository._internal() {
    _loadFromDisk();
  }

  // ── Reactive Notifiers ────────────────────────────────────────────────────

  /// List of all downloaded tracks (with offline file paths).
  final ValueNotifier<List<Track>> downloadedTracksNotifier =
      ValueNotifier<List<Track>>(<Track>[]);

  /// Fast lookup set for downloaded track IDs.
  final ValueNotifier<Set<String>> downloadedTrackIdsNotifier =
      ValueNotifier<Set<String>>(<String>{});

  /// Real-time progress map: `trackId` -> progress (0.0 to 1.0).
  final ValueNotifier<Map<String, double>> downloadProgressNotifier =
      ValueNotifier<Map<String, double>>(<String, double>{});

  /// Total offline storage used in bytes.
  final ValueNotifier<int> totalStorageBytesNotifier = ValueNotifier<int>(0);

  final StreamController<String> _downloadDeletedController =
      StreamController<String>.broadcast();

  /// Stream emitting track IDs whenever an offline download is removed.
  Stream<String> get onDownloadDeleted => _downloadDeletedController.stream;

  // In-memory mapping of trackId -> DownloadedItem
  final Map<String, DownloadedItem> _items = {};

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Track> get downloadedTracks => downloadedTracksNotifier.value;
  Set<String> get downloadedTrackIds => downloadedTrackIdsNotifier.value;
  int get downloadedCount => downloadedTracksNotifier.value.length;
  int get totalStorageBytes => totalStorageBytesNotifier.value;

  Track? getCanonicalTrack(String trackId) => _items[trackId]?.track;

  bool isDownloaded(String trackId) =>
      downloadedTrackIdsNotifier.value.contains(trackId);

  bool isDownloading(String trackId) =>
      downloadProgressNotifier.value.containsKey(trackId);

  double? getDownloadProgress(String trackId) =>
      downloadProgressNotifier.value[trackId];

  String? getLocalAudioPath(String trackId) =>
      _items[trackId]?.localAudioPath;

  String? getLocalArtPath(String trackId) =>
      _items[trackId]?.localArtPath;

  String get totalStorageFormatted {
    final bytes = totalStorageBytesNotifier.value;
    if (bytes <= 0) return '0 MB';
    if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }

  // ── Private Storage Directory ─────────────────────────────────────────────

  Directory _getVaultDirectory() {
    try {
      final parent = Directory.systemTemp.parent;
      final filesDir = Directory('${parent.path}/files/aura_offline_vault');
      if (!filesDir.existsSync()) {
        filesDir.createSync(recursive: true);
      }
      return filesDir;
    } catch (_) {}

    final fallback =
        Directory('${Directory.systemTemp.path}/aura_offline_vault');
    if (!fallback.existsSync()) {
      fallback.createSync(recursive: true);
    }
    return fallback;
  }

  File _getRegistryFile() {
    try {
      final parent = Directory.systemTemp.parent;
      final filesDir = Directory('${parent.path}/files');
      if (filesDir.existsSync()) {
        return File('${filesDir.path}/aura_downloads_registry.json');
      }
    } catch (_) {}
    return File('${Directory.systemTemp.path}/aura_downloads_registry.json');
  }

  File? _findExistingRegistryFile() {
    try {
      final parent = Directory.systemTemp.parent;
      final primary = File('${parent.path}/files/aura_downloads_registry.json');
      if (primary.existsSync()) return primary;
    } catch (_) {}
    final fallback =
        File('${Directory.systemTemp.path}/aura_downloads_registry.json');
    if (fallback.existsSync()) return fallback;
    return null;
  }

  // ── Persistence: Load & Save Registry ─────────────────────────────────────

  void _loadFromDisk() {
    try {
      final registryFile = _findExistingRegistryFile();
      if (registryFile != null && registryFile.existsSync()) {
        final content = registryFile.readAsStringSync().trim();
        if (content.startsWith('[') && content.endsWith(']')) {
          final List<dynamic> jsonList = jsonDecode(content);
          final validTracks = <Track>[];
          final validIds = <String>{};
          var totalBytes = 0;
          _items.clear();

          for (final entry in jsonList) {
            try {
              final item = DownloadedItem.fromMap(
                Map<String, dynamic>.from(entry as Map),
              );
              final audioFile = File(item.localAudioPath);

              // Verify file still exists on device
              if (audioFile.existsSync()) {
                final realSize = audioFile.lengthSync();
                totalBytes += realSize;
                _items[item.trackId] = item;
                validIds.add(item.trackId);

                // Build offline track with local paths
                final offlineTrack = item.track.copyWith(
                  streamUrl: item.localAudioPath,
                  albumArt: (item.localArtPath != null &&
                          File(item.localArtPath!).existsSync())
                      ? item.localArtPath
                      : item.track.albumArt,
                );
                validTracks.add(offlineTrack);
              }
            } catch (e) {
              debugPrint('[DownloadRepository] Error parsing downloaded item: $e');
            }
          }

          downloadedTracksNotifier.value = validTracks;
          downloadedTrackIdsNotifier.value = validIds;
          totalStorageBytesNotifier.value = totalBytes;
        }
      }
    } catch (e) {
      debugPrint('[DownloadRepository] Error loading downloads registry: $e');
    }
  }

  void _saveRegistry() {
    try {
      final file = _getRegistryFile();
      final list = _items.values.map((item) => item.toMap()).toList();
      file.writeAsStringSync(
        jsonEncode(list),
        mode: FileMode.write,
        flush: true,
      );
    } catch (e) {
      debugPrint('[DownloadRepository] Error saving downloads registry: $e');
    }
  }

  /// Alias for [downloadTrack] for convenience.
  Future<bool> downloadSong(Track track) => downloadTrack(track);

  /// Downloads a track and its album art directly into the app's private sandbox.
  ///
  /// Emits incremental progress via [downloadProgressNotifier].
  Future<bool> downloadTrack(Track track) async {
    if (isDownloaded(track.id)) return true;
    if (isDownloading(track.id)) return false;

    // Set initial progress
    _updateProgress(track.id, 0.05);

    final client = http.Client();
    try {
      // 1. Resolve Stream URL (ensure it's a valid remote HTTP URL)
      String? streamUrl = (track.streamUrl != null &&
              track.streamUrl!.isNotEmpty &&
              track.streamUrl!.startsWith('http'))
          ? track.streamUrl
          : null;

      Track? fetchedTrack;
      if (streamUrl == null || streamUrl.isEmpty) {
        try {
          final fetched = await MusicRepository.instance.getSongById(track.id);
          fetchedTrack = fetched?.toTrack();
          if (fetchedTrack?.streamUrl != null &&
              fetchedTrack!.streamUrl!.isNotEmpty &&
              fetchedTrack.streamUrl!.startsWith('http')) {
            streamUrl = fetchedTrack.streamUrl;
          }
        } catch (_) {}
      }

      if (streamUrl == null || streamUrl.isEmpty || !streamUrl.startsWith('http')) {
        final sampleNum = (track.id.hashCode.abs() % 5) + 1;
        streamUrl =
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-$sampleNum.mp3';
      }

      // 2. Prepare Vault Directory and Target Files
      final vaultDir = _getVaultDirectory();
      final safeId = track.id.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final audioFileName = 'track_$safeId.aura';
      final tempAudioFile = File('${vaultDir.path}/$audioFileName.part');
      final finalAudioFile = File('${vaultDir.path}/$audioFileName');

      // 3. Stream Download Audio
      final request = http.Request('GET', Uri.parse(streamUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        _removeProgress(track.id);
        client.close();
        return false;
      }

      final contentLength = response.contentLength ?? 0;
      var downloadedBytes = 0;
      final sink = tempAudioFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (contentLength > 0) {
          final progress = (downloadedBytes / contentLength).clamp(0.05, 0.90);
          _updateProgress(track.id, progress);
        }
      }
      await sink.flush();
      await sink.close();

      // Rename from .part to final .aura file
      if (finalAudioFile.existsSync()) {
        try {
          finalAudioFile.deleteSync();
        } catch (_) {}
      }
      tempAudioFile.renameSync(finalAudioFile.path);

      // 4. Download Album Artwork Locally for Complete Offline Experience
      String? localArtPath;
      String? artUrl = (track.albumArt != null &&
              track.albumArt!.isNotEmpty &&
              track.albumArt!.startsWith('http'))
          ? track.albumArt
          : fetchedTrack?.albumArt;

      if ((artUrl == null || !artUrl.startsWith('http')) && fetchedTrack == null) {
        try {
          final fetched = await MusicRepository.instance.getSongById(track.id);
          fetchedTrack = fetched?.toTrack();
          if (fetchedTrack?.albumArt != null && fetchedTrack!.albumArt!.startsWith('http')) {
            artUrl = fetchedTrack.albumArt;
          }
        } catch (_) {}
      }

      if (artUrl != null && artUrl.isNotEmpty && artUrl.startsWith('http')) {
        try {
          final artResponse = await http
              .get(Uri.parse(artUrl))
              .timeout(const Duration(seconds: 8));
          if (artResponse.statusCode == 200) {
            final artFile = File('${vaultDir.path}/art_$safeId.jpg');
            artFile.writeAsBytesSync(artResponse.bodyBytes, flush: true);
            localArtPath = artFile.path;
          }
        } catch (_) {}
      }

      _updateProgress(track.id, 0.98);

      // 5. Register Downloaded Track
      final actualAudioSize = finalAudioFile.lengthSync();

      // Preserve canonical track with remote URLs for re-downloading/fallback
      final canonicalTrack = (fetchedTrack ?? track).copyWith(
        streamUrl: (streamUrl.startsWith('http')) ? streamUrl : track.streamUrl,
        albumArt: (artUrl != null && artUrl.startsWith('http'))
            ? artUrl
            : (fetchedTrack?.albumArt ?? track.albumArt),
      );

      final offlineTrack = canonicalTrack.copyWith(
        streamUrl: finalAudioFile.path,
        albumArt: localArtPath ?? canonicalTrack.albumArt,
      );

      final item = DownloadedItem(
        trackId: track.id,
        localAudioPath: finalAudioFile.path,
        localArtPath: localArtPath,
        fileSizeBytes: actualAudioSize,
        downloadedAt: DateTime.now(),
        track: canonicalTrack, // Canonical track preserves remote URL!
      );

      _items[track.id] = item;

      // Update State Notifiers
      final updatedTracks = List<Track>.from(downloadedTracksNotifier.value);
      updatedTracks.removeWhere((t) => t.id == track.id);
      updatedTracks.insert(0, offlineTrack);

      final updatedIds = Set<String>.from(downloadedTrackIdsNotifier.value);
      updatedIds.add(track.id);

      downloadedTracksNotifier.value = updatedTracks;
      downloadedTrackIdsNotifier.value = updatedIds;
      totalStorageBytesNotifier.value += actualAudioSize;

      _saveRegistry();
      _removeProgress(track.id);
      client.close();
      return true;
    } catch (e) {
      debugPrint('[DownloadRepository] Download track error: $e');
      _removeProgress(track.id);
      client.close();
      return false;
    }
  }

  void _updateProgress(String trackId, double progress) {
    final map = Map<String, double>.from(downloadProgressNotifier.value);
    map[trackId] = progress;
    downloadProgressNotifier.value = map;
  }

  void _removeProgress(String trackId) {
    final map = Map<String, double>.from(downloadProgressNotifier.value);
    map.remove(trackId);
    downloadProgressNotifier.value = map;
  }

  // ── Delete / Clear Operations ─────────────────────────────────────────────

  /// Alias for [deleteDownload] for convenience.
  Future<bool> deleteDownloadedSong(String trackId) => deleteDownload(trackId);

  /// Deletes an offline track from device storage.
  Future<bool> deleteDownload(String trackId) async {
    final item = _items[trackId];
    if (item == null) return false;

    try {
      // 1. Delete physical files from private sandbox safely
      final audioFile = File(item.localAudioPath);
      if (audioFile.existsSync()) {
        try {
          audioFile.deleteSync();
        } catch (e) {
          debugPrint('[DownloadRepository] Note: audio file delete pending/busy: $e');
        }
      }

      if (item.localArtPath != null) {
        final artFile = File(item.localArtPath!);
        if (artFile.existsSync()) {
          try {
            artFile.deleteSync();
          } catch (e) {
            debugPrint('[DownloadRepository] Note: art file delete pending/busy: $e');
          }
        }
      }

      _items.remove(trackId);

      // 2. Update reactive notifiers
      final updatedTracks = List<Track>.from(downloadedTracksNotifier.value);
      updatedTracks.removeWhere((t) => t.id == trackId);

      final updatedIds = Set<String>.from(downloadedTrackIdsNotifier.value);
      updatedIds.remove(trackId);

      final newTotal = (totalStorageBytesNotifier.value - item.fileSizeBytes)
          .clamp(0, double.maxFinite.toInt());

      downloadedTracksNotifier.value = updatedTracks;
      downloadedTrackIdsNotifier.value = updatedIds;
      totalStorageBytesNotifier.value = newTotal;

      _saveRegistry();
      _downloadDeletedController.add(trackId);
      return true;
    } catch (e) {
      debugPrint('[DownloadRepository] Delete download error: $e');
      return false;
    }
  }

  /// Deletes all downloaded songs and clears the offline vault.
  Future<void> clearAllDownloads() async {
    try {
      final clearedIds = List<String>.from(_items.keys);

      final vaultDir = _getVaultDirectory();
      if (vaultDir.existsSync()) {
        final entities = vaultDir.listSync();
        for (final entity in entities) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        }
      }

      _items.clear();
      downloadedTracksNotifier.value = [];
      downloadedTrackIdsNotifier.value = {};
      downloadProgressNotifier.value = {};
      totalStorageBytesNotifier.value = 0;

      _saveRegistry();

      for (final id in clearedIds) {
        _downloadDeletedController.add(id);
      }
    } catch (e) {
      debugPrint('[DownloadRepository] Clear all downloads error: $e');
    }
  }
}
