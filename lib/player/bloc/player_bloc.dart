import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' as ja;
import '../../models/models.dart';
import '../../repositories/music_repository.dart';
import '../../repositories/history_repository.dart';
import '../../repositories/favorites_repository.dart';
import '../../repositories/download_repository.dart';
import '../../insights/services/insight_service.dart';
import '../services/autoplay_engine.dart';
import 'player_models.dart';

export 'player_models.dart';

/// PlayerBloc manages audio playback, master queue state, dynamic autoplay,
/// seek, volume, and playback lifecycle.
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final ja.AudioPlayer _player;
  final AutoplayEngine _autoplayEngine;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<ja.PlayerState>? _playerStateSub;
  StreamSubscription<String>? _downloadDeletedSub;

  DateTime? _currentTrackStartTime;
  bool _completedRecorded = false;
  bool _isTransitioningTrack = false;
  String? _lastCompletedTrackId;
  bool _waitingForNextFromAutoplay = false;
  int _autoplayRequestId = 0;

  PlayerBloc({
    ja.AudioPlayer? player,
    AutoplayEngine? autoplayEngine,
  })  : _player = player ?? ja.AudioPlayer(),
        _autoplayEngine = autoplayEngine ?? AutoplayEngine(MusicRepository.instance),
        super(const PlayerState(
          queue: [],
          currentTrack: null,
          totalTime: '00:00',
          isAutoplayEnabled: true,
          isLoadingAutoplay: false,
        )) {
    on<PlayerPlayTrack>(_onPlayTrack);
    on<PlayerPlayQueue>(_onPlayQueue);
    on<PlayerAddToQueue>(_onAddToQueue);
    on<PlayerRemoveFromQueue>(_onRemoveFromQueue);
    on<PlayerReorderQueue>(_onReorderQueue);
    on<PlayerClearUpcomingQueue>(_onClearUpcomingQueue);
    on<PlayerToggleAutoplay>(_onToggleAutoplay);
    on<PlayerAutoplayReplenished>(_onAutoplayReplenished);
    on<PlayerTogglePlayPause>(_onTogglePlayPause);
    on<PlayerSeek>(_onSeek);
    on<PlayerNextTrack>(_onNextTrack);
    on<PlayerPreviousTrack>(_onPreviousTrack);
    on<PlayerToggleShuffle>(_onToggleShuffle);
    on<PlayerToggleRepeat>(_onToggleRepeat);
    on<PlayerToggleLike>(_onToggleLike);
    on<PlayerSyncLikeStatus>(_onSyncLikeStatus);
    on<PlayerSetVolume>(_onSetVolume);
    on<PlayerPositionChanged>(_onPositionChanged);
    on<PlayerDurationChanged>(_onDurationChanged);
    on<PlayerPlaybackStateChanged>(_onPlaybackStateChanged);
    on<PlayerDownloadDeleted>(_onDownloadDeleted);
    on<PlayerTrackUpdated>(_onTrackUpdated);

    _initAudioSession();
    _initPlayerListeners();
    FavoritesRepository.instance.likedSongIdsNotifier.addListener(_syncLikeStatus);
    _downloadDeletedSub =
        DownloadRepository.instance.onDownloadDeleted.listen((trackId) {
      if (!isClosed) {
        add(PlayerDownloadDeleted(trackId));
      }
    });
    _syncTasteProfile();
  }

  void _syncLikeStatus() {
    if (isClosed) return;
    final currentId = state.currentTrack?.id;
    if (currentId != null) {
      final isLiked = FavoritesRepository.instance.isSongLiked(currentId);
      if (state.isLiked != isLiked) {
        add(PlayerSyncLikeStatus(isLiked));
      }
    }
  }

  void _syncTasteProfile() {
    final profile = ListeningInsightsService.instance.buildTasteProfile();
    _autoplayEngine.updateTasteProfile(profile);
  }

  void _recordInsightsSession(Track track, int elapsedSeconds) {
    final song = track.toSong();
    ListeningInsightsService.instance.recordPlaybackSession(
      song: song,
      listenedDuration: Duration(seconds: elapsedSeconds),
    );
    _syncTasteProfile();
  }

  @visibleForTesting
  AutoplayEngine get autoplayEngine => _autoplayEngine;

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      if (kDebugMode) print('AudioSession error: $e');
    }
  }

  void _initPlayerListeners() {
    _player.setVolume(state.volume);

    _positionSub = _player.positionStream.listen((pos) {
      if (!isClosed) {
        add(PlayerPositionChanged(pos));
      }
    });

    _durationSub = _player.durationStream.listen((dur) {
      if (!isClosed && dur != null) {
        add(PlayerDurationChanged(dur));
      }
    });

    _playerStateSub = _player.playerStateStream.listen((ps) {
      final isPlaying = ps.playing;
      final isBuffering = ps.processingState == ja.ProcessingState.buffering ||
          ps.processingState == ja.ProcessingState.loading;

      if (!isClosed) {
        add(PlayerPlaybackStateChanged(
          isPlaying: isPlaying,
          isBuffering: isBuffering,
        ));
      }

      if (ps.processingState == ja.ProcessingState.completed) {
        if (_isTransitioningTrack) return;

        final currentId = state.currentTrack?.id;
        if (currentId != null && currentId == _lastCompletedTrackId) {
          return;
        }

        if (state.isRepeat) {
          _player.seek(Duration.zero);
          unawaited(_player.play());
        } else {
          _isTransitioningTrack = true;
          _lastCompletedTrackId = currentId;
          if (state.currentTrack != null) {
            _completedRecorded = true;
            final song = state.currentTrack!.toSong();
            _autoplayEngine.recordSongCompleted(song);
            final elapsed = _currentTrackStartTime != null
                ? DateTime.now().difference(_currentTrackStartTime!).inSeconds
                : _player.position.inSeconds;
            _recordInsightsSession(state.currentTrack!, elapsed);
          }
          add(const PlayerNextTrack());
        }
      }
    });
  }

  Track _resolveOfflineTrack(Track track) {
    final localArt = DownloadRepository.instance.getLocalArtPath(track.id);
    final localAudio = DownloadRepository.instance.getLocalAudioPath(track.id);

    final canonical = DownloadRepository.instance.getCanonicalTrack(track.id);
    final remoteUrl = (track.streamUrl != null && track.streamUrl!.startsWith('http'))
        ? track.streamUrl
        : (canonical?.streamUrl != null && canonical!.streamUrl!.startsWith('http')
            ? canonical.streamUrl
            : null);

    final remoteArt = (track.albumArt != null && track.albumArt!.startsWith('http'))
        ? track.albumArt
        : (canonical?.albumArt != null && canonical!.albumArt!.startsWith('http'))
            ? canonical.albumArt
            : null;

    final resolvedAudio = (localAudio != null && File(localAudio).existsSync())
        ? localAudio
        : (track.streamUrl != null && File(track.streamUrl!).existsSync()
            ? track.streamUrl
            : null);

    final resolvedArt = (localArt != null && File(localArt).existsSync())
        ? localArt
        : (track.albumArt != null && File(track.albumArt!).existsSync()
            ? track.albumArt
            : null);

    return track.copyWith(
      streamUrl: remoteUrl ?? resolvedAudio,
      albumArt: resolvedArt ?? remoteArt,
    );
  }

  void _onTrackUpdated(
    PlayerTrackUpdated event,
    Emitter<PlayerState> emit,
  ) {
    final updatedQueue = state.queue.map((t) {
      return t.id == event.track.id ? event.track : t;
    }).toList();

    emit(state.copyWith(
      currentTrack: state.currentTrack?.id == event.track.id
          ? event.track
          : state.currentTrack,
      queue: updatedQueue,
    ));
  }

  Future<void> _onDownloadDeleted(
    PlayerDownloadDeleted event,
    Emitter<PlayerState> emit,
  ) async {
    if (state.currentTrack?.id == event.trackId) {
      final current = state.currentTrack!;
      String? remoteUrl = (current.streamUrl != null &&
              current.streamUrl!.isNotEmpty &&
              current.streamUrl!.startsWith('http'))
          ? current.streamUrl
          : null;

      Track? fetched;
      if (remoteUrl == null) {
        try {
          final song = await MusicRepository.instance.getSongById(current.id);
          fetched = song?.toTrack();
          if (fetched?.streamUrl != null &&
              fetched!.streamUrl!.isNotEmpty &&
              fetched.streamUrl!.startsWith('http')) {
            remoteUrl = fetched.streamUrl;
          }
        } catch (_) {}
      }

      remoteUrl ??= _getFallbackUrl(current.id);

      final updatedTrack = (fetched ?? current).copyWith(
        streamUrl: remoteUrl,
        albumArt: (fetched?.albumArt != null && fetched!.albumArt!.startsWith('http'))
            ? fetched.albumArt
            : ((current.albumArt != null && current.albumArt!.startsWith('http'))
                ? current.albumArt
                : null),
      );

      final updatedQueue = state.queue.map((t) {
        if (t.id == event.trackId) {
          return t.copyWith(
            streamUrl: remoteUrl,
            albumArt: updatedTrack.albumArt ?? t.albumArt,
          );
        }
        return t;
      }).toList();

      emit(state.copyWith(
        currentTrack: updatedTrack,
        queue: updatedQueue,
      ));
      HistoryRepository.instance.updateTrackMetadata(updatedTrack);

      final isPlayingLocalFile =
          _player.audioSource?.toString().contains(event.trackId) ?? false;
      if (isPlayingLocalFile) {
        final currentPos = _player.position;
        final wasPlaying = _player.playing;
        try {
          if (wasPlaying) {
            await _player.pause();
          }
          await _player.setUrl(remoteUrl, initialPosition: currentPos);
          if (wasPlaying) {
            await _player.play();
          }
        } catch (e) {
          if (kDebugMode) {
            print('PlayerBloc: failed to switch to remote stream: $e');
          }
        }
      }
    }
  }

  Future<void> prepareForDownloadDeletion(String trackId) async {
    if (state.currentTrack?.id == trackId) {
      final current = state.currentTrack!;
      String? remoteUrl = (current.streamUrl != null &&
              current.streamUrl!.isNotEmpty &&
              current.streamUrl!.startsWith('http'))
          ? current.streamUrl
          : null;

      Track? fetched;
      if (remoteUrl == null) {
        try {
          final song = await MusicRepository.instance.getSongById(current.id);
          fetched = song?.toTrack();
          if (fetched?.streamUrl != null &&
              fetched!.streamUrl!.isNotEmpty &&
              fetched.streamUrl!.startsWith('http')) {
            remoteUrl = fetched.streamUrl;
          }
        } catch (_) {}
      }

      remoteUrl ??= _getFallbackUrl(current.id);

      final updatedTrack = (fetched ?? current).copyWith(
        streamUrl: remoteUrl,
        albumArt: (fetched?.albumArt != null && fetched!.albumArt!.startsWith('http'))
            ? fetched.albumArt
            : ((current.albumArt != null && current.albumArt!.startsWith('http'))
                ? current.albumArt
                : null),
      );

      add(PlayerTrackUpdated(updatedTrack));
      HistoryRepository.instance.updateTrackMetadata(updatedTrack);

      final isPlayingLocalFile =
          _player.audioSource?.toString().contains(trackId) ?? false;
      if (isPlayingLocalFile) {
        final currentPos = _player.position;
        final wasPlaying = _player.playing;
        try {
          if (wasPlaying) {
            await _player.pause();
          }
          await _player.setUrl(remoteUrl, initialPosition: currentPos);
          if (wasPlaying) {
            await _player.play();
          }
        } catch (e) {
          if (kDebugMode) {
            print('PlayerBloc: failed to prepare for download deletion: $e');
          }
        }
      }
    }
  }

  Future<void> _onPlayTrack(
    PlayerPlayTrack event,
    Emitter<PlayerState> emit,
  ) async {
    final track = _resolveOfflineTrack(event.track);
    final idx = state.queue.indexWhere((t) => t.id == track.id);
    List<Track> updatedQueue;
    int activeIndex;

    if (idx >= 0) {
      updatedQueue = List<Track>.from(state.queue);
      activeIndex = idx;
    } else {
      updatedQueue = [track];
      activeIndex = 0;
      _autoplayRequestId++;
    }

    _currentTrackStartTime = DateTime.now();
    _completedRecorded = false;
    _isTransitioningTrack = true;

    HistoryRepository.instance.addTrack(track);

    emit(state.copyWith(
      queue: updatedQueue,
      currentTrack: track,
      currentIndex: activeIndex,
      isPlaying: true,
      isBuffering: true,
      progress: 0.0,
      currentTime: '00:00',
      totalTime: track.duration,
      isLiked: FavoritesRepository.instance.isSongLiked(track.id),
      isLoadingAutoplay: idx < 0 ? false : state.isLoadingAutoplay,
    ));

    _checkAutoplayReplenish(
      track,
      updatedQueue,
      activeIndex,
      emit,
      force: idx < 0,
    );
    await _playAudio(track, emit);
  }

  Future<void> _onPlayQueue(
    PlayerPlayQueue event,
    Emitter<PlayerState> emit,
  ) async {
    if (event.tracks.isEmpty) return;
    final validIndex = event.initialIndex.clamp(0, event.tracks.length - 1);
    final track = _resolveOfflineTrack(event.tracks[validIndex]);
    final resolvedQueue = event.tracks.map(_resolveOfflineTrack).toList();

    HistoryRepository.instance.addTrack(track);

    _currentTrackStartTime = DateTime.now();
    _completedRecorded = false;
    _isTransitioningTrack = true;
    _autoplayRequestId++;

    emit(state.copyWith(
      queue: resolvedQueue,
      currentTrack: track,
      currentIndex: validIndex,
      isPlaying: true,
      isBuffering: true,
      progress: 0.0,
      currentTime: '00:00',
      totalTime: track.duration,
      isLiked: FavoritesRepository.instance.isSongLiked(track.id),
      isLoadingAutoplay: false,
    ));

    _checkAutoplayReplenish(
      track,
      resolvedQueue,
      validIndex,
      emit,
      force: true,
    );
    await _playAudio(track, emit);
  }

  void _onAddToQueue(PlayerAddToQueue event, Emitter<PlayerState> emit) {
    final List<Track> updated = List<Track>.from(state.queue);
    if (updated.isEmpty) {
      add(PlayerPlayTrack(event.track));
      return;
    }

    if (event.playNext) {
      final insertPos = (state.currentIndex + 1).clamp(0, updated.length);
      updated.insert(insertPos, event.track);
    } else {
      final firstAutoplayIdx = updated.indexWhere(
        (t) => t.isAutoplay,
        state.currentIndex + 1,
      );
      if (firstAutoplayIdx != -1) {
        updated.insert(firstAutoplayIdx, event.track);
      } else {
        updated.add(event.track);
      }
    }

    emit(state.copyWith(queue: updated));
  }

  Future<void> _onRemoveFromQueue(
    PlayerRemoveFromQueue event,
    Emitter<PlayerState> emit,
  ) async {
    if (event.index < 0 || event.index >= state.queue.length) return;
    final List<Track> updated = List<Track>.from(state.queue);
    updated.removeAt(event.index);

    if (event.index == state.currentIndex) {
      if (updated.isEmpty) {
        await _player.stop();
        emit(state.copyWith(
          queue: const [],
          currentTrack: null,
          currentIndex: 0,
          isPlaying: false,
        ));
        return;
      }
      final newIdx = event.index < updated.length ? event.index : updated.length - 1;
      final nextTrack = updated[newIdx];
      emit(state.copyWith(
        queue: updated,
        currentIndex: newIdx,
        currentTrack: nextTrack,
      ));
      await _playAudio(nextTrack, emit);
    } else {
      final newIdx = event.index < state.currentIndex
          ? state.currentIndex - 1
          : state.currentIndex;
      emit(state.copyWith(queue: updated, currentIndex: newIdx));
    }

    if (state.currentTrack != null) {
      _checkAutoplayReplenish(state.currentTrack!, updated, state.currentIndex, emit);
    }
  }

  void _onReorderQueue(PlayerReorderQueue event, Emitter<PlayerState> emit) {
    if (event.oldIndex < 0 || event.oldIndex >= state.queue.length) return;
    int newIdx = event.newIndex;
    if (newIdx < 0) newIdx = 0;
    if (newIdx > state.queue.length) newIdx = state.queue.length;

    final List<Track> updated = List<Track>.from(state.queue);
    final currentTrack = state.currentTrack;
    final item = updated.removeAt(event.oldIndex);
    if (newIdx > event.oldIndex) newIdx--;
    updated.insert(newIdx, item);

    final activeIdx = currentTrack != null
        ? updated.indexWhere((t) => t.id == currentTrack.id)
        : 0;

    emit(state.copyWith(
      queue: updated,
      currentIndex: activeIdx >= 0 ? activeIdx : 0,
    ));
  }

  void _onClearUpcomingQueue(
    PlayerClearUpcomingQueue event,
    Emitter<PlayerState> emit,
  ) {
    if (state.queue.isEmpty) return;
    final updated = state.queue.sublist(0, state.currentIndex + 1);
    emit(state.copyWith(queue: updated));

    if (state.isAutoplayEnabled && state.currentTrack != null) {
      _checkAutoplayReplenish(state.currentTrack!, updated, state.currentIndex, emit);
    }
  }

  void _onToggleAutoplay(PlayerToggleAutoplay event, Emitter<PlayerState> emit) {
    final newEnabled = !state.isAutoplayEnabled;
    List<Track> updated = List<Track>.from(state.queue);

    if (!newEnabled) {
      final currentPos = state.currentIndex;
      final before = updated.sublist(0, currentPos + 1);
      final after = updated.sublist(currentPos + 1).where((t) => !t.isAutoplay).toList();
      updated = [...before, ...after];
    }

    emit(state.copyWith(isAutoplayEnabled: newEnabled, queue: updated));

    if (newEnabled && state.currentTrack != null) {
      _checkAutoplayReplenish(state.currentTrack!, updated, state.currentIndex, emit);
    }
  }

  void _onAutoplayReplenished(
    PlayerAutoplayReplenished event,
    Emitter<PlayerState> emit,
  ) {
    if (event.requestId != null && event.requestId != _autoplayRequestId) {
      return;
    }

    if (event.newTracks.isEmpty) {
      _waitingForNextFromAutoplay = false;
      emit(state.copyWith(isLoadingAutoplay: false));
      return;
    }

    final existingIds = state.queue.map((t) => t.id).toSet();
    final unique = event.newTracks.where((t) => !existingIds.contains(t.id)).toList();
    final updated = [...state.queue, ...unique];

    emit(state.copyWith(queue: updated, isLoadingAutoplay: false));

    if (_waitingForNextFromAutoplay && unique.isNotEmpty) {
      _waitingForNextFromAutoplay = false;
      add(PlayerPlayTrack(unique.first));
    }
  }

  void _checkAutoplayReplenish(
    Track current,
    List<Track> queue,
    int index,
    Emitter<PlayerState> emit, {
    bool force = false,
  }) {
    if (!state.isAutoplayEnabled) return;
    if (state.isLoadingAutoplay && !force) return;
    final remaining = queue.length - 1 - index;
    if (remaining <= 2) {
      final reqId = ++_autoplayRequestId;
      emit(state.copyWith(isLoadingAutoplay: true));
      unawaited(() async {
        try {
          final queuedIds = queue.map((t) => t.id).toSet();
          final songs = await _autoplayEngine.generateAutoplayQueue(
            currentSongId: current.id,
            currentSong: current.toSong(),
            limit: 6,
            queuedSongIds: queuedIds,
          );
          if (_autoplayRequestId != reqId) return;
          final newTracks = songs
              .map((s) => s.toTrack(isAutoplay: true))
              .where((t) => !queuedIds.contains(t.id))
              .toList();

          if (!isClosed && _autoplayRequestId == reqId) {
            add(PlayerAutoplayReplenished(newTracks, requestId: reqId));
          }
        } catch (e) {
          if (kDebugMode) print('Autoplay replenishment error: $e');
          if (!isClosed && _autoplayRequestId == reqId) {
            add(PlayerAutoplayReplenished(const [], requestId: reqId));
          }
        }
      }());
    }
  }

  Future<void> _playAudio(Track track, [Emitter<PlayerState>? emit]) async {
    // 1. Check if track is downloaded and local offline file exists (Play without internet)
    final localPath = DownloadRepository.instance.getLocalAudioPath(track.id);
    if (localPath != null && File(localPath).existsSync()) {
      try {
        if (_player.playing) {
          await _player.pause();
        }
        await _player.setFilePath(localPath, initialPosition: Duration.zero);
        await _player.seek(Duration.zero);
        _isTransitioningTrack = false;
        unawaited(_player.play());
        return;
      } catch (e) {
        if (kDebugMode) {
          print('PlayerBloc: failed to play offline file $localPath: $e');
        }
      }
    }

    // Also check if streamUrl itself points to an offline local file
    if (track.streamUrl != null &&
        !track.streamUrl!.startsWith('http') &&
        !track.streamUrl!.contains('..') &&
        RegExp(r'\.(aura|mp3|m4a|aac|wav|ogg|flac)$', caseSensitive: false)
            .hasMatch(track.streamUrl!) &&
        File(track.streamUrl!).existsSync()) {
      try {
        if (_player.playing) {
          await _player.pause();
        }
        await _player.setFilePath(track.streamUrl!, initialPosition: Duration.zero);
        await _player.seek(Duration.zero);
        _isTransitioningTrack = false;
        unawaited(_player.play());
        return;
      } catch (e) {
        if (kDebugMode) {
          print('PlayerBloc: failed to play streamUrl local file: $e');
        }
      }
    }

    // 2. Otherwise fallback to online stream URL
    String? streamUrl = (track.streamUrl != null &&
            track.streamUrl!.isNotEmpty &&
            track.streamUrl!.startsWith('http'))
        ? track.streamUrl!
        : null;

    Track? refreshedTrack;
    if (streamUrl == null || streamUrl.isEmpty) {
      try {
        final song = await MusicRepository.instance.getSongById(track.id);
        if (song?.streamUrl != null &&
            song!.streamUrl!.isNotEmpty &&
            song.streamUrl!.startsWith('http')) {
          streamUrl = song.streamUrl;
          refreshedTrack = song.toTrack();
        }
      } catch (e) {
        if (kDebugMode) {
          print('PlayerBloc: failed to fetch streamUrl for track ${track.id}: $e');
        }
      }
    }

    streamUrl ??= _getFallbackUrl(track.id);

    // Refresh currentTrack and HistoryRepository if streamUrl or metadata was refreshed
    if (refreshedTrack != null || streamUrl != track.streamUrl) {
      final updatedTrack = (refreshedTrack ?? track).copyWith(
        streamUrl: streamUrl,
        albumArt: (refreshedTrack?.albumArt != null &&
                refreshedTrack!.albumArt!.startsWith('http'))
            ? refreshedTrack.albumArt
            : track.albumArt,
      );
      if (state.currentTrack?.id == track.id && emit != null) {
        emit(state.copyWith(currentTrack: updatedTrack));
      }
      HistoryRepository.instance.updateTrackMetadata(updatedTrack);
    }

    try {
      if (_player.playing) {
        await _player.pause();
      }
      await _player.setUrl(streamUrl, initialPosition: Duration.zero);
      await _player.seek(Duration.zero);
      _isTransitioningTrack = false;
      unawaited(_player.play());
    } catch (e) {
      _isTransitioningTrack = false;
      if (kDebugMode) {
        print('PlayerBloc: failed to play stream from $streamUrl: $e');
      }
      if (emit != null) {
        emit(state.copyWith(isBuffering: false, isPlaying: false));
      }
    }
  }

  Future<void> _onTogglePlayPause(
    PlayerTogglePlayPause event,
    Emitter<PlayerState> emit,
  ) async {
    if (state.currentTrack == null && state.queue.isNotEmpty) {
      add(PlayerPlayTrack(state.queue.first));
      return;
    }

    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.audioSource == null && state.currentTrack != null) {
        await _playAudio(state.currentTrack!, emit);
      } else {
        if (_player.processingState == ja.ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        unawaited(_player.play());
      }
    }
  }

  Future<void> _onSeek(PlayerSeek event, Emitter<PlayerState> emit) async {
    final clamped = event.progress.clamp(0.0, 1.0);
    final totalSecs =
        _player.duration?.inSeconds ?? _parseDuration(state.totalTime);

    if (totalSecs > 0) {
      final targetMs = (clamped * totalSecs * 1000).round();
      try {
        await _player.seek(Duration(milliseconds: targetMs));
      } catch (e) {
        if (kDebugMode) print('Seek error: $e');
      }
    }

    emit(state.copyWith(
      progress: clamped,
      currentTime: _formatTime(clamped, state.totalTime),
    ));
  }

  void _onNextTrack(PlayerNextTrack event, Emitter<PlayerState> emit) {
    _lastCompletedTrackId = null;
    if (state.queue.isEmpty) {
      _isTransitioningTrack = false;
      return;
    }

    if (!_completedRecorded && state.currentTrack != null) {
      final elapsedSecs = _currentTrackStartTime != null
          ? DateTime.now().difference(_currentTrackStartTime!).inSeconds
          : _player.position.inSeconds;
      final song = state.currentTrack!.toSong();
      if (elapsedSecs < 30) {
        _autoplayEngine.recordSongSkippedEarly(song);
      } else {
        _autoplayEngine.recordSongCompleted(song);
      }
      _recordInsightsSession(state.currentTrack!, elapsedSecs);
    }

    if (state.currentIndex + 1 < state.queue.length) {
      add(PlayerPlayTrack(state.queue[state.currentIndex + 1]));
    } else {
      if (state.isRepeat) {
        add(PlayerPlayTrack(state.queue.first));
      } else if (state.isAutoplayEnabled && state.currentTrack != null) {
        _waitingForNextFromAutoplay = true;
        _checkAutoplayReplenish(state.currentTrack!, state.queue, state.currentIndex, emit);
      } else {
        add(PlayerPlayTrack(state.queue.first));
      }
    }
  }

  void _onPreviousTrack(PlayerPreviousTrack event, Emitter<PlayerState> emit) {
    _lastCompletedTrackId = null;
    _waitingForNextFromAutoplay = false;
    if (state.queue.isEmpty) return;
    if (_player.position.inSeconds > 3) {
      _player.seek(Duration.zero);
      return;
    }
    final prev =
        (state.currentIndex - 1 + state.queue.length) % state.queue.length;
    add(PlayerPlayTrack(state.queue[prev]));
  }

  Future<void> _onToggleShuffle(
    PlayerToggleShuffle event,
    Emitter<PlayerState> emit,
  ) async {
    final newShuffle = !state.isShuffle;
    await _player.setShuffleModeEnabled(newShuffle);
    emit(state.copyWith(isShuffle: newShuffle));
  }

  Future<void> _onToggleRepeat(
    PlayerToggleRepeat event,
    Emitter<PlayerState> emit,
  ) async {
    final newRepeat = !state.isRepeat;
    await _player.setLoopMode(newRepeat ? ja.LoopMode.one : ja.LoopMode.off);
    emit(state.copyWith(isRepeat: newRepeat));
  }

  Future<void> _onToggleLike(
    PlayerToggleLike event,
    Emitter<PlayerState> emit,
  ) async {
    final track = state.currentTrack;
    if (track == null) return;
    final isLikedNow = await FavoritesRepository.instance.toggleLikeSong(track);
    emit(state.copyWith(isLiked: isLikedNow));
  }

  void _onSyncLikeStatus(
    PlayerSyncLikeStatus event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(isLiked: event.isLiked));
  }

  Future<void> _onSetVolume(
    PlayerSetVolume event,
    Emitter<PlayerState> emit,
  ) async {
    final vol = event.volume.clamp(0.0, 1.0);
    await _player.setVolume(vol);
    emit(state.copyWith(volume: vol));
  }

  void _onPositionChanged(
    PlayerPositionChanged event,
    Emitter<PlayerState> emit,
  ) {
    if (_isTransitioningTrack) return;
    final totalSecs =
        _player.duration?.inSeconds ?? _parseDuration(state.totalTime);
    if (totalSecs <= 0) return;
    final progress =
        (event.position.inMilliseconds / (totalSecs * 1000)).clamp(0.0, 1.0);
    final formatted = _formatDuration(event.position);
    emit(state.copyWith(
      progress: progress,
      currentTime: formatted,
    ));
  }

  void _onDurationChanged(
    PlayerDurationChanged event,
    Emitter<PlayerState> emit,
  ) {
    if (_isTransitioningTrack) return;
    if (event.duration.inSeconds > 0) {
      emit(state.copyWith(totalTime: _formatDuration(event.duration)));
    }
  }

  void _onPlaybackStateChanged(
    PlayerPlaybackStateChanged event,
    Emitter<PlayerState> emit,
  ) {
    if (_isTransitioningTrack) return;
    emit(state.copyWith(
      isPlaying: event.isPlaying,
      isBuffering: event.isBuffering,
    ));
  }

  int _parseDuration(String d) {
    final parts = d.split(':');
    if (parts.length == 2) {
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }
    return 0;
  }

  String _formatTime(double progress, String totalTime) {
    final total = _parseDuration(totalTime);
    final elapsed = (progress * total).round();
    final m = elapsed ~/ 60;
    final s = elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _getFallbackUrl(String id) {
    final sampleNum = (id.hashCode.abs() % 5) + 1;
    return 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-$sampleNum.mp3';
  }

  @override
  Future<void> close() {
    FavoritesRepository.instance.likedSongIdsNotifier.removeListener(_syncLikeStatus);
    _downloadDeletedSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    return super.close();
  }
}
