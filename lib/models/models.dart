import 'package:equatable/equatable.dart';
import 'song.dart';

export 'album.dart';
export 'artist.dart';
export 'playlist.dart';
export 'song.dart';

/// Represents a single audio track in the catalogue.
class Track extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String duration;
  final String formatBadge; // e.g. "DSD 256", "96k", "FLAC 192", "320k"
  final String? albumArt; // network image URL
  final String? streamUrl; // 320kbps audio stream URL
  final String language;
  final String artistId;
  final String mood;
  final List<String> genres;
  final bool isAutoplay;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.formatBadge,
    this.albumArt,
    this.streamUrl,
    this.language = 'hindi',
    this.artistId = '',
    this.mood = 'melodic',
    this.genres = const ['bollywood', 'soundtrack'],
    this.isAutoplay = false,
  });

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? duration,
    String? formatBadge,
    String? albumArt,
    String? streamUrl,
    String? language,
    String? artistId,
    String? mood,
    List<String>? genres,
    bool? isAutoplay,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      formatBadge: formatBadge ?? this.formatBadge,
      albumArt: albumArt ?? this.albumArt,
      streamUrl: streamUrl ?? this.streamUrl,
      language: language ?? this.language,
      artistId: artistId ?? this.artistId,
      mood: mood ?? this.mood,
      genres: genres ?? this.genres,
      isAutoplay: isAutoplay ?? this.isAutoplay,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'name': title,
      'artist': artist,
      'duration': duration,
      'formatBadge': formatBadge,
      'albumArt': albumArt,
      'coverUrl': albumArt,
      'streamUrl': streamUrl,
      'language': language,
      'artistId': artistId,
      'mood': mood,
      'genres': genres,
      'isAutoplay': isAutoplay,
    };
  }

  factory Track.fromMap(Map<String, dynamic> map) {
    final cover = map['coverUrl'] as String? ??
        map['albumArt'] as String? ??
        map['image'] as String? ??
        map['imageUrl'] as String?;

    String parseDuration(dynamic val) {
      if (val is String) return val;
      if (val is int) {
        final totalSeconds = val > 1000 ? (val ~/ 1000) : val;
        final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
        final secs = (totalSeconds % 60).toString().padLeft(2, '0');
        return '$mins:$secs';
      }
      return '03:30';
    }

    return Track(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ??
          map['name']?.toString() ??
          'Untitled Track',
      artist: map['artist']?.toString() ?? 'Various Artists',
      duration: parseDuration(map['duration']),
      formatBadge: map['formatBadge']?.toString() ?? '320k',
      albumArt: cover,
      streamUrl: map['streamUrl'] as String?,
      language: map['language'] as String? ?? 'hindi',
      artistId: map['artistId'] as String? ?? '',
      mood: map['mood'] as String? ?? 'melodic',
      genres: (map['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['bollywood', 'soundtrack'],
      isAutoplay: map['isAutoplay'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        duration,
        formatBadge,
        albumArt,
        streamUrl,
        language,
        artistId,
        mood,
        isAutoplay,
      ];
}

extension SongToTrackX on Song {
  Track toTrack({bool isAutoplay = false}) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final formattedDuration =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return Track(
      id: id,
      title: title,
      artist: artist,
      duration: formattedDuration,
      formatBadge: '320k',
      albumArt: coverUrl.isNotEmpty ? coverUrl : null,
      streamUrl: streamUrl,
      language: language,
      artistId: artistId,
      mood: mood,
      genres: genres,
      isAutoplay: isAutoplay,
    );
  }
}

extension TrackToSongX on Track {
  Song toSong() {
    final parts = duration.split(':');
    final mins = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 3 : 3;
    final secs = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return Song(
      id: id,
      title: title,
      artist: artist,
      coverUrl: albumArt ?? '',
      duration: Duration(minutes: mins, seconds: secs),
      streamUrl: streamUrl,
      language: language,
      artistId: artistId,
      mood: mood,
      genres: genres,
    );
  }
}

