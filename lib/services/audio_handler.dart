import 'dart:async';
import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart' as http;
import '../player/bloc/player_bloc.dart';
import '../models/models.dart';

int parseDuration(String d) {
  final parts = d.split(':');
  if (parts.length == 2) {
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }
  return 0;
}

/// Converts a [Track] to an [audio_service] [MediaItem].
MediaItem trackToMediaItem(Track track) {
  final totalSecs = parseDuration(track.duration);
  Uri? artUri;
  if (track.albumArt != null && track.albumArt!.isNotEmpty) {
    if (track.albumArt!.startsWith('http')) {
      artUri = Uri.tryParse(track.albumArt!);
    } else {
      artUri = Uri.file(track.albumArt!);
    }
  }

  return MediaItem(
    id: track.id,
    title: track.title,
    artist: track.artist,
    duration: Duration(seconds: totalSecs),
    artUri: artUri,
    extras: {'formatBadge': track.formatBadge, 'duration': track.duration},
  );
}

/// [SangeetAudioHandler] bridges the existing [PlayerBloc] with the
/// [audio_service] foreground service so that:
/// - Android shows a rich media notification with artwork, track info, and
///   media controls (previous, play/pause, next, seek).
/// - Lock-screen / Bluetooth / wired headset controls work out of the box.
///
/// Every action from the notification delegates back to [PlayerBloc], and
/// bloc state changes are forwarded to the service via a [StreamSubscription].
class SangeetAudioHandler extends BaseAudioHandler
    with SeekHandler, QueueHandler {
  final PlayerBloc playerBloc;
  late final StreamSubscription<PlayerState> _blocSub;

  SangeetAudioHandler({required this.playerBloc}) {
    // Keep audio_service metadata & playback state in sync with the bloc.
    _blocSub = playerBloc.stream.listen(_syncFromBloc);
    // Initialise with the current state immediately.
    _syncFromBloc(playerBloc.state);
  }

  // ── AudioHandler callbacks (called by the system / notification buttons) ─────

  @override
  Future<void> play() async {
    if (!playerBloc.state.isPlaying) {
      playerBloc.add(const PlayerTogglePlayPause());
    }
  }

  @override
  Future<void> pause() async {
    if (playerBloc.state.isPlaying) {
      playerBloc.add(const PlayerTogglePlayPause());
    }
  }

  @override
  Future<void> stop() async {
    if (playerBloc.state.isPlaying) {
      playerBloc.add(const PlayerTogglePlayPause());
    }
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    playerBloc.add(const PlayerNextTrack());
  }

  @override
  Future<void> skipToPrevious() async {
    playerBloc.add(const PlayerPreviousTrack());
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final queue = playerBloc.state.queue;
    if (index >= 0 && index < queue.length) {
      playerBloc.add(PlayerPlayTrack(queue[index]));
    }
  }

  @override
  Future<void> seek(Duration position) async {
    final track = playerBloc.state.currentTrack;
    if (track == null) return;
    final totalSecs = parseDuration(track.duration);
    if (totalSecs <= 0) return;
    final fraction = (position.inMilliseconds / (totalSecs * 1000)).clamp(0.0, 1.0);
    playerBloc.add(PlayerSeek(fraction));
  }

  @override
  Future<void> fastForward([Duration interval = const Duration(seconds: 10)]) async {
    final track = playerBloc.state.currentTrack;
    if (track == null) return;
    final totalSecs = parseDuration(track.duration);
    if (totalSecs <= 0) return;
    final currentMs = (playerBloc.state.progress * totalSecs * 1000).round();
    final targetMs = (currentMs + interval.inMilliseconds).clamp(0, totalSecs * 1000);
    playerBloc.add(PlayerSeek(targetMs / (totalSecs * 1000)));
  }

  @override
  Future<void> rewind([Duration interval = const Duration(seconds: 10)]) async {
    final track = playerBloc.state.currentTrack;
    if (track == null) return;
    final totalSecs = parseDuration(track.duration);
    if (totalSecs <= 0) return;
    final currentMs = (playerBloc.state.progress * totalSecs * 1000).round();
    final targetMs = (currentMs - interval.inMilliseconds).clamp(0, totalSecs * 1000);
    playerBloc.add(PlayerSeek(targetMs / (totalSecs * 1000)));
  }

  // ── Sync bloc → audio_service ─────────────────────────────────────────────

  void _syncFromBloc(PlayerState state) {
    final track = state.currentTrack;

    // Update media item (title, artist, artwork, duration).
    if (track != null) {
      mediaItem.add(trackToMediaItem(track));
    }

    // Update playback state (playing, buffering, position, controls).
    final totalSecs = track != null ? parseDuration(track.duration) : 0;
    final positionMs = (state.progress * totalSecs * 1000).round();

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          state.isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: state.isPlaying,
        updatePosition: Duration(milliseconds: positionMs),
        bufferedPosition: Duration(milliseconds: positionMs),
        speed: 1.0,
      ),
    );

    // Update the service queue so Android knows the playlist.
    queue.add(
      state.queue.map(trackToMediaItem).toList(),
    );
  }

  /// Fetches a network image as raw [Uint8List] bytes so [audio_service]
  /// can embed it as large notification artwork when artUri is inaccessible
  /// from the background isolate.
  static Future<Uint8List?> fetchArtBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
  }

  @override
  Future<void> onNotificationDeleted() async {
    // User swiped the notification — pause playback gracefully.
    await pause();
  }

  void dispose() {
    _blocSub.cancel();
  }
}

/// Initialises the [audio_service] foreground service and returns the handler
/// bound to [playerBloc]. Call this once from [main] before [runApp].
Future<SangeetAudioHandler> initAudioService(PlayerBloc playerBloc) async {
  return await AudioService.init(
    builder: () => SangeetAudioHandler(playerBloc: playerBloc),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'app.sangeet.in.audio',
      androidNotificationChannelName: 'Sangeet Player',
      androidNotificationChannelDescription:
          'Controls playback for the Sangeet hi-res audio player.',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: true,
      artDownscaleWidth: 300,
      artDownscaleHeight: 300,
      notificationColor: Color(0xFF1A1A2E),
    ),
  );
}
