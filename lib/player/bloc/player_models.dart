import 'package:equatable/equatable.dart';
import '../../models/models.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();
  @override
  List<Object?> get props => [];
}

class PlayerPlayTrack extends PlayerEvent {
  final Track track;
  const PlayerPlayTrack(this.track);
  @override
  List<Object?> get props => [track];
}

class PlayerPlayQueue extends PlayerEvent {
  final List<Track> tracks;
  final int initialIndex;
  const PlayerPlayQueue(this.tracks, {this.initialIndex = 0});
  @override
  List<Object?> get props => [tracks, initialIndex];
}

class PlayerAddToQueue extends PlayerEvent {
  final Track track;
  final bool playNext;
  const PlayerAddToQueue(this.track, {this.playNext = false});
  @override
  List<Object?> get props => [track, playNext];
}

class PlayerRemoveFromQueue extends PlayerEvent {
  final int index;
  const PlayerRemoveFromQueue(this.index);
  @override
  List<Object?> get props => [index];
}

class PlayerReorderQueue extends PlayerEvent {
  final int oldIndex;
  final int newIndex;
  const PlayerReorderQueue(this.oldIndex, this.newIndex);
  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class PlayerClearUpcomingQueue extends PlayerEvent {
  const PlayerClearUpcomingQueue();
}

class PlayerToggleAutoplay extends PlayerEvent {
  const PlayerToggleAutoplay();
}

class PlayerAutoplayReplenished extends PlayerEvent {
  final List<Track> newTracks;
  final int? requestId;
  const PlayerAutoplayReplenished(this.newTracks, {this.requestId});
  @override
  List<Object?> get props => [newTracks, requestId];
}

class PlayerTogglePlayPause extends PlayerEvent {
  const PlayerTogglePlayPause();
}

class PlayerSeek extends PlayerEvent {
  final double progress;
  const PlayerSeek(this.progress);
  @override
  List<Object?> get props => [progress];
}

class PlayerNextTrack extends PlayerEvent {
  const PlayerNextTrack();
}

class PlayerPreviousTrack extends PlayerEvent {
  const PlayerPreviousTrack();
}

class PlayerToggleShuffle extends PlayerEvent {
  const PlayerToggleShuffle();
}

class PlayerToggleRepeat extends PlayerEvent {
  const PlayerToggleRepeat();
}

class PlayerToggleLike extends PlayerEvent {
  const PlayerToggleLike();
}

class PlayerSyncLikeStatus extends PlayerEvent {
  final bool isLiked;
  const PlayerSyncLikeStatus(this.isLiked);
  @override
  List<Object?> get props => [isLiked];
}

class PlayerProgressTick extends PlayerEvent {
  const PlayerProgressTick();
}

class PlayerSetVolume extends PlayerEvent {
  final double volume;
  const PlayerSetVolume(this.volume);
  @override
  List<Object?> get props => [volume];
}

class PlayerPositionChanged extends PlayerEvent {
  final Duration position;
  const PlayerPositionChanged(this.position);
  @override
  List<Object?> get props => [position];
}

class PlayerDurationChanged extends PlayerEvent {
  final Duration duration;
  const PlayerDurationChanged(this.duration);
  @override
  List<Object?> get props => [duration];
}

class PlayerPlaybackStateChanged extends PlayerEvent {
  final bool isPlaying;
  final bool isBuffering;
  const PlayerPlaybackStateChanged({
    required this.isPlaying,
    required this.isBuffering,
  });
  @override
  List<Object?> get props => [isPlaying, isBuffering];
}

class PlayerDownloadDeleted extends PlayerEvent {
  final String trackId;
  const PlayerDownloadDeleted(this.trackId);
  @override
  List<Object?> get props => [trackId];
}

class PlayerTrackUpdated extends PlayerEvent {
  final Track track;
  const PlayerTrackUpdated(this.track);
  @override
  List<Object?> get props => [track];
}

// ─── State ───────────────────────────────────────────────────────────────────

class PlayerState extends Equatable {
  final Track? currentTrack;
  final List<Track> queue;
  final int currentIndex;
  final bool isPlaying;
  final bool isBuffering;
  final bool isShuffle;
  final bool isRepeat;
  final bool isLiked;
  final double progress;
  final double volume;
  final String currentTime;
  final String totalTime;
  final bool isAutoplayEnabled;
  final bool isLoadingAutoplay;

  const PlayerState({
    this.currentTrack,
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isShuffle = false,
    this.isRepeat = false,
    this.isLiked = false,
    this.progress = 0.0,
    this.volume = 0.72,
    this.currentTime = '00:00',
    this.totalTime = '00:00',
    this.isAutoplayEnabled = true,
    this.isLoadingAutoplay = false,
  });

  PlayerState copyWith({
    Track? currentTrack,
    List<Track>? queue,
    int? currentIndex,
    bool? isPlaying,
    bool? isBuffering,
    bool? isShuffle,
    bool? isRepeat,
    bool? isLiked,
    double? progress,
    double? volume,
    String? currentTime,
    String? totalTime,
    bool? isAutoplayEnabled,
    bool? isLoadingAutoplay,
  }) =>
      PlayerState(
        currentTrack: currentTrack ?? this.currentTrack,
        queue: queue ?? this.queue,
        currentIndex: currentIndex ?? this.currentIndex,
        isPlaying: isPlaying ?? this.isPlaying,
        isBuffering: isBuffering ?? this.isBuffering,
        isShuffle: isShuffle ?? this.isShuffle,
        isRepeat: isRepeat ?? this.isRepeat,
        isLiked: isLiked ?? this.isLiked,
        progress: progress ?? this.progress,
        volume: volume ?? this.volume,
        currentTime: currentTime ?? this.currentTime,
        totalTime: totalTime ?? this.totalTime,
        isAutoplayEnabled: isAutoplayEnabled ?? this.isAutoplayEnabled,
        isLoadingAutoplay: isLoadingAutoplay ?? this.isLoadingAutoplay,
      );

  @override
  List<Object?> get props => [
        currentTrack,
        queue,
        currentIndex,
        isPlaying,
        isBuffering,
        isShuffle,
        isRepeat,
        isLiked,
        progress,
        volume,
        currentTime,
        totalTime,
        isAutoplayEnabled,
        isLoadingAutoplay,
      ];
}
