import 'package:equatable/equatable.dart';
import 'models.dart';

/// Represents a user or curated playlist containing dynamic tracks.
class Playlist extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? customCoverUrl;
  final List<Track> tracks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String telemetryBadge;

  Playlist({
    required this.id,
    required this.name,
    this.description = 'Curated by you',
    this.customCoverUrl,
    List<Track>? tracks,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.telemetryBadge = 'STUDIO MASTER',
    // Backwards-compatibility parameters
    String? title,
    String? subtitle,
    String? category,
    String? duration,
    String? coverArt,
  })  : tracks = tracks ?? const [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Backward compatibility getters
  String get title => name;
  String get subtitle => description;
  String get category => 'Playlist';
  String get duration => formattedDuration;
  String? get coverArt => coverUrl.isNotEmpty ? coverUrl : null;

  int get songCount => tracks.length;
  int get trackCount => tracks.length;

  /// Returns the top song's cover if present, otherwise customCoverUrl, or empty.
  String get coverUrl {
    for (final track in tracks) {
      if (track.albumArt != null && track.albumArt!.isNotEmpty) {
        return track.albumArt!;
      }
    }
    if (customCoverUrl != null && customCoverUrl!.isNotEmpty) {
      return customCoverUrl!;
    }
    return '';
  }

  /// Calculates total playlist duration from track duration strings (mm:ss).
  Duration get totalDuration {
    var totalSeconds = 0;
    for (final track in tracks) {
      final parts = track.duration.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        totalSeconds += (m * 60) + s;
      }
    }
    return Duration(seconds: totalSeconds);
  }

  String get formattedDuration {
    final dur = totalDuration;
    if (dur.inMinutes == 0 && dur.inSeconds == 0) return '0 min';
    if (dur.inHours > 0) {
      final rem = dur.inMinutes % 60;
      return '${dur.inHours} hr ${rem > 0 ? '$rem min' : ''}';
    }
    return '${dur.inMinutes} min';
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? customCoverUrl,
    List<Track>? tracks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? telemetryBadge,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      customCoverUrl: customCoverUrl ?? this.customCoverUrl,
      tracks: tracks ?? List<Track>.from(this.tracks),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      telemetryBadge: telemetryBadge ?? this.telemetryBadge,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'customCoverUrl': customCoverUrl,
      'telemetryBadge': telemetryBadge,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'songIds': tracks.map((t) => t.id).toList(),
      'songs': tracks.map((t) => t.toMap()).toList(),
      'tracks': tracks.map((t) => t.toMap()).toList(),
    };
  }

  factory Playlist.fromFirestore(String docId, Map<String, dynamic> data) {
    return Playlist.fromMap(data, documentId: docId);
  }

  factory Playlist.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic val) {
      if (val != null && val.runtimeType.toString().contains('Timestamp')) {
        try {
          return (val as dynamic).toDate() as DateTime;
        } catch (_) {}
      }
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      if (val is int) {
        return DateTime.fromMillisecondsSinceEpoch(val);
      }
      return DateTime.now();
    }

    final rawTracks = map['songs'] as List<dynamic>? ??
        map['tracks'] as List<dynamic>? ??
        [];
    final parsedTracks = <Track>[];
    for (final item in rawTracks) {
      if (item is Map<String, dynamic>) {
        parsedTracks.add(Track.fromMap(item));
      } else if (item is Map) {
        parsedTracks.add(Track.fromMap(Map<String, dynamic>.from(item)));
      }
    }

    final resolvedId = (documentId != null && documentId.isNotEmpty)
        ? documentId
        : (map['id'] as String? ?? 'pl-${DateTime.now().millisecondsSinceEpoch}');

    return Playlist(
      id: resolvedId,
      name: map['name'] as String? ?? map['title'] as String? ?? 'Untitled Playlist',
      description: map['description'] as String? ?? 'Curated by you',
      customCoverUrl: map['customCoverUrl'] as String? ?? map['coverUrl'] as String?,
      telemetryBadge: map['telemetryBadge'] as String? ?? 'STUDIO MASTER',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt'] ?? map['createdAt']),
      tracks: parsedTracks,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        customCoverUrl,
        tracks,
        createdAt,
        updatedAt,
        telemetryBadge,
      ];
}
