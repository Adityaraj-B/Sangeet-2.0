class Song {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final Duration duration;
  final String? streamUrl;
  final String language;
  final String artistId;
  final String mood;
  final List<String> genres;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.duration,
    this.streamUrl,
    this.language = 'hindi',
    this.artistId = '',
    this.mood = 'melodic',
    this.genres = const ['bollywood', 'soundtrack'],
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? coverUrl,
    Duration? duration,
    String? streamUrl,
    String? language,
    String? artistId,
    String? mood,
    List<String>? genres,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      coverUrl: coverUrl ?? this.coverUrl,
      duration: duration ?? this.duration,
      streamUrl: streamUrl ?? this.streamUrl,
      language: language ?? this.language,
      artistId: artistId ?? this.artistId,
      mood: mood ?? this.mood,
      genres: genres ?? this.genres,
    );
  }

  @override
  String toString() {
    return 'Song(id: $id, title: $title, artist: $artist, coverUrl: $coverUrl, duration: $duration, streamUrl: $streamUrl, language: $language, artistId: $artistId, mood: $mood, genres: $genres)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Song &&
        other.id == id &&
        other.title == title &&
        other.artist == artist &&
        other.coverUrl == coverUrl &&
        other.duration == duration &&
        other.streamUrl == streamUrl &&
        other.language == language &&
        other.artistId == artistId &&
        other.mood == mood;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'coverUrl': coverUrl,
      'duration': duration.inSeconds,
      'streamUrl': streamUrl,
      'language': language,
      'artistId': artistId,
      'mood': mood,
      'genres': genres,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      artist: json['artist']?.toString() ?? 'Unknown',
      coverUrl: json['coverUrl']?.toString() ?? '',
      duration: Duration(seconds: json['duration'] is int ? json['duration'] : 0),
      streamUrl: json['streamUrl'] as String?,
      language: json['language'] as String? ?? 'hindi',
      artistId: json['artistId'] as String? ?? '',
      mood: json['mood'] as String? ?? 'melodic',
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['bollywood', 'soundtrack'],
    );
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        artist.hashCode ^
        coverUrl.hashCode ^
        duration.hashCode ^
        streamUrl.hashCode ^
        language.hashCode ^
        artistId.hashCode ^
        mood.hashCode;
  }
}
