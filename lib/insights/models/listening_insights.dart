import '../../models/song.dart';

class ListeningEvent {
  final String songId;
  final String title;
  final String artistId;
  final String artist;
  final String coverUrl;
  final String language;
  final String mood;
  final List<String> genres;
  final int listenedSeconds;
  final int totalDurationSeconds;
  final bool wasCompleted;
  final bool wasSkippedEarly;
  final DateTime timestamp;

  const ListeningEvent({
    required this.songId,
    required this.title,
    required this.artistId,
    required this.artist,
    required this.coverUrl,
    required this.language,
    required this.mood,
    required this.genres,
    required this.listenedSeconds,
    required this.totalDurationSeconds,
    required this.wasCompleted,
    required this.wasSkippedEarly,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'songId': songId,
    'title': title,
    'artistId': artistId,
    'artist': artist,
    'coverUrl': coverUrl,
    'language': language,
    'mood': mood,
    'genres': genres,
    'listenedSeconds': listenedSeconds,
    'totalDurationSeconds': totalDurationSeconds,
    'wasCompleted': wasCompleted,
    'wasSkippedEarly': wasSkippedEarly,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ListeningEvent.fromJson(Map<String, dynamic> json) {
    return ListeningEvent(
      songId: (json['songId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      artistId: (json['artistId'] ?? '').toString(),
      artist: (json['artist'] ?? '').toString(),
      coverUrl: (json['coverUrl'] ?? '').toString(),
      language: (json['language'] ?? 'unknown').toString(),
      mood: (json['mood'] ?? 'neutral').toString(),
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      listenedSeconds: (json['listenedSeconds'] ?? 0) as int,
      totalDurationSeconds: (json['totalDurationSeconds'] ?? 180) as int,
      wasCompleted: (json['wasCompleted'] ?? false) as bool,
      wasSkippedEarly: (json['wasSkippedEarly'] ?? false) as bool,
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ArtistInsight {
  final String artistKey;
  final String artistName;
  final String sampleCoverUrl;
  final int playCount;
  final int totalSeconds;
  final int likedSongsCount;

  const ArtistInsight({
    required this.artistKey,
    required this.artistName,
    required this.sampleCoverUrl,
    required this.playCount,
    required this.totalSeconds,
    required this.likedSongsCount,
  });

  double get hoursListened => totalSeconds / 3600.0;
}

class CategoryShare {
  final String label;
  final int seconds;
  final double percentage;

  const CategoryShare({
    required this.label,
    required this.seconds,
    required this.percentage,
  });
}

class UserTasteProfile {
  final Map<String, double> artistAffinity;
  final Map<String, double> moodAffinity;
  final Map<String, double> languageAffinity;
  final Map<int, String> peakMoodByHour;
  final Set<String> likedSongIds;

  const UserTasteProfile({
    this.artistAffinity = const {},
    this.moodAffinity = const {},
    this.languageAffinity = const {},
    this.peakMoodByHour = const {},
    this.likedSongIds = const {},
  });
}

class UserInsightsSummary {
  final Duration totalListeningTime;
  final Duration currentMonthListeningTime;
  final Duration previousMonthListeningTime;
  final int totalSongsPlayed;
  final double completionRate;
  final int currentStreakDays;
  final int longestStreakDays;
  final int likedSongsCount;
  final List<Song> forgottenLikedSongs;
  final List<ArtistInsight> topArtists;
  final List<CategoryShare> topMoods;
  final List<CategoryShare> topLanguages;
  final List<CategoryShare> topGenres;
  final List<double> hourlyActivityDistribution;
  final List<double> weeklyMinutesByWeekday;
  final String listenerPersona;
  final String peakListeningWindow;

  const UserInsightsSummary({
    required this.totalListeningTime,
    required this.currentMonthListeningTime,
    required this.previousMonthListeningTime,
    required this.totalSongsPlayed,
    required this.completionRate,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.likedSongsCount,
    required this.forgottenLikedSongs,
    required this.topArtists,
    required this.topMoods,
    required this.topLanguages,
    required this.topGenres,
    required this.hourlyActivityDistribution,
    required this.weeklyMinutesByWeekday,
    required this.listenerPersona,
    required this.peakListeningWindow,
  });

  double get monthlyGrowthPercent {
    final prevMins = previousMonthListeningTime.inMinutes;
    final currMins = currentMonthListeningTime.inMinutes;
    if (prevMins == 0) return currMins > 0 ? 100.0 : 0.0;
    return ((currMins - prevMins) / prevMins) * 100.0;
  }
}
