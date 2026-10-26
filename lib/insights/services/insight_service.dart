import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/models.dart';
import '../models/listening_insights.dart';
import '../../repositories/favorites_repository.dart';
import '../../repositories/history_repository.dart';

class ListeningInsightsService extends ChangeNotifier {
  static final ListeningInsightsService instance =
      ListeningInsightsService._internal();

  static const String _eventsFileName = 'aura_listening_events_v1.json';
  static const String _likedSongsFileName = 'aura_insights_liked_songs_v1.json';
  static const int _maxStoredEvents = 2500;

  static Directory? _cachedPermanentDir;

  final List<ListeningEvent> _events = [];
  final Map<String, Song> _likedSongs = {};

  ListeningInsightsService._internal();

  List<ListeningEvent> get events => List.unmodifiable(_events);
  List<Song> get likedSongs => _likedSongs.values.toList(growable: false);

  File _getPersistentFile(String filename) {
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

  File? _findExistingFile(String filename) {
    if (_cachedPermanentDir != null) {
      final primary = File('${_cachedPermanentDir!.path}/$filename');
      if (primary.existsSync()) return primary;
    }
    try {
      final parent = Directory.systemTemp.parent;
      final primary = File('${parent.path}/files/$filename');
      if (primary.existsSync()) return primary;
    } catch (_) {}
    final fallback = File('${Directory.systemTemp.path}/$filename');
    if (fallback.existsSync()) return fallback;
    return null;
  }

  Future<void> initialize() async {
    try {
      _cachedPermanentDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      try {
        _cachedPermanentDir = await getApplicationSupportDirectory();
      } catch (_) {}
    }

    try {
      final eventsFile = _findExistingFile(_eventsFileName);
      if (eventsFile != null && eventsFile.existsSync()) {
        final content = eventsFile.readAsStringSync().trim();
        if (content.startsWith('[') && content.endsWith(']')) {
          final List<dynamic> jsonList = jsonDecode(content);
          _events
            ..clear()
            ..addAll(
              jsonList.map(
                (e) => ListeningEvent.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              ),
            );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ListeningInsightsService] Failed to load cached events: $e');
      }
    }

    try {
      final likedFile = _findExistingFile(_likedSongsFileName);
      if (likedFile != null && likedFile.existsSync()) {
        final content = likedFile.readAsStringSync().trim();
        if (content.startsWith('[') && content.endsWith(']')) {
          final List<dynamic> jsonList = jsonDecode(content);
          _likedSongs.clear();
          for (final item in jsonList) {
            try {
              final song = Song.fromJson(Map<String, dynamic>.from(item as Map));
              _likedSongs[song.id] = song;
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ListeningInsightsService] Failed to load cached liked songs: $e');
      }
    }

    // Sync from FavoritesRepository if available
    _syncFavorites();
    FavoritesRepository.instance.likedSongsNotifier.addListener(_syncFavorites);

    notifyListeners();
  }

  /// Wipes all in-memory events and local disk caches on user sign out.
  void clearLocalSession() {
    _events.clear();
    _likedSongs.clear();
    try {
      final eventsFile = _findExistingFile(_eventsFileName);
      if (eventsFile != null && eventsFile.existsSync()) {
        eventsFile.deleteSync();
      }
      final likedFile = _findExistingFile(_likedSongsFileName);
      if (likedFile != null && likedFile.existsSync()) {
        likedFile.deleteSync();
      }
    } catch (_) {}
    notifyListeners();
  }

  void _syncFavorites() {
    final favList = FavoritesRepository.instance.likedSongs;
    final favIds = FavoritesRepository.instance.likedSongIds;
    bool changed = false;

    for (final track in favList) {
      if (!_likedSongs.containsKey(track.id)) {
        _likedSongs[track.id] = track.toSong();
        changed = true;
      }
    }

    _likedSongs.removeWhere((id, _) {
      if (!favIds.contains(id)) {
        changed = true;
        return true;
      }
      return false;
    });

    if (changed) {
      _persistLikedSongs();
      notifyListeners();
    }
  }

  bool isSongLiked(String songId) => _likedSongs.containsKey(songId);

  Future<void> toggleLikeSong(Song song) async {
    if (_likedSongs.containsKey(song.id)) {
      _likedSongs.remove(song.id);
    } else {
      _likedSongs[song.id] = song;
    }
    notifyListeners();
    await _persistLikedSongs();

    if (FavoritesRepository.instance.isSongLiked(song.id) !=
        _likedSongs.containsKey(song.id)) {
      await FavoritesRepository.instance.toggleLikeSong(song.toTrack());
    }
  }

  Future<void> recordPlaybackSession({
    required Song song,
    required Duration listenedDuration,
    DateTime? timestamp,
  }) async {
    final seconds = listenedDuration.inSeconds;
    if (seconds < 5) return;

    final totalSeconds =
        song.duration.inSeconds > 0 ? song.duration.inSeconds : 180;
    final wasSkippedEarly = seconds < 30;
    final wasCompleted =
        seconds >= 30 && (seconds >= totalSeconds * 0.75 || seconds >= 120);

    final event = ListeningEvent(
      songId: song.id,
      title: song.title,
      artistId: song.artistId,
      artist: song.artist,
      coverUrl: song.coverUrl,
      language: song.language.trim().toLowerCase(),
      mood: song.mood.trim().toLowerCase(),
      genres: song.genres.map((g) => g.trim().toLowerCase()).toList(),
      listenedSeconds: seconds.clamp(0, totalSeconds * 2),
      totalDurationSeconds: totalSeconds,
      wasCompleted: wasCompleted,
      wasSkippedEarly: wasSkippedEarly,
      timestamp: timestamp ?? DateTime.now(),
    );

    _events.add(event);
    if (_events.length > _maxStoredEvents) {
      _events.removeRange(0, _events.length - _maxStoredEvents);
    }

    notifyListeners();
    await _persistEvents();
  }

  /// Returns the user's most listened song based on accumulated playback events,
  /// history, or liked tracks.
  Song? getMostListenedSong() {
    if (_events.isNotEmpty) {
      final Map<String, int> playCountMap = {};
      final Map<String, int> secondsMap = {};
      final Map<String, ListeningEvent> eventMap = {};

      for (final e in _events) {
        if (e.wasSkippedEarly) continue;
        playCountMap[e.songId] = (playCountMap[e.songId] ?? 0) + 1;
        secondsMap[e.songId] = (secondsMap[e.songId] ?? 0) + e.listenedSeconds;
        eventMap[e.songId] = e;
      }

      if (secondsMap.isEmpty) {
        for (final e in _events) {
          playCountMap[e.songId] = (playCountMap[e.songId] ?? 0) + 1;
          eventMap[e.songId] = e;
        }
      }

      if (eventMap.isNotEmpty) {
        final topSongId = secondsMap.isNotEmpty
            ? secondsMap.entries.reduce((a, b) => a.value >= b.value ? a : b).key
            : playCountMap.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

        final e = eventMap[topSongId]!;
        final liked = _likedSongs[topSongId];
        return liked ??
            Song(
              id: e.songId,
              title: e.title,
              artist: e.artist,
              coverUrl: e.coverUrl,
              duration: Duration(seconds: e.totalDurationSeconds),
              language: e.language,
              artistId: e.artistId,
              mood: e.mood,
              genres: e.genres,
            );
      }
    }

    // Fallback to recent playback history
    final history = HistoryRepository.instance.history;
    if (history.isNotEmpty) {
      return history.first.track.toSong();
    }

    // Fallback to liked songs
    final liked = FavoritesRepository.instance.likedSongs;
    if (liked.isNotEmpty) {
      return liked.first.toSong();
    }

    return null;
  }

  /// Returns stats for a song: (playCount, totalSeconds)
  (int, int) getSongStats(String songId) {
    int playCount = 0;
    int totalSec = 0;
    for (final e in _events) {
      if (e.songId == songId) {
        if (!e.wasSkippedEarly) playCount++;
        totalSec += e.listenedSeconds;
      }
    }
    if (playCount == 0) {
      final historyMatches = HistoryRepository.instance.history
          .where((h) => h.track.id == songId)
          .length;
      if (historyMatches > 0) {
        return (historyMatches, historyMatches * 180);
      }
    }
    return (playCount, totalSec);
  }

  /// Returns the primary consumed mood (e.g. 'Romantic', 'Melodic', 'Acoustic', etc.)
  String getPrimaryConsumedMood({String defaultMood = 'Romantic'}) {
    final summary = computeSummary();
    if (summary.topMoods.isNotEmpty) {
      return summary.topMoods.first.label;
    }
    final history = HistoryRepository.instance.history;
    if (history.isNotEmpty) {
      final Map<String, int> moodCounts = {};
      for (final h in history) {
        final m = h.track.mood.trim();
        if (m.isNotEmpty && m.toLowerCase() != 'unknown' && m.toLowerCase() != 'neutral') {
          moodCounts[m] = (moodCounts[m] ?? 0) + 1;
        }
      }
      if (moodCounts.isNotEmpty) {
        final top = moodCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
        return _capitalize(top.key);
      }
    }
    return defaultMood;
  }

  /// Returns user's top listened artists derived from verified listening events,
  /// playback history, and liked songs.
  List<ArtistInsight> getTopListenedArtists({int limit = 10}) {
    final Map<String, _MutableArtistAccumulator> artistMap = {};

    // 1. Accumulate from verified listening events
    for (final e in _events) {
      if (!e.wasSkippedEarly) {
        final primaryArtist = _extractPrimaryArtist(e.artist);
        final mapKey = primaryArtist.trim().toLowerCase();
        if (mapKey.isEmpty || mapKey == 'unknown artist') continue;

        final rawArtistId = e.artistId.trim();

        final acc = artistMap.putIfAbsent(
          mapKey,
          () => _MutableArtistAccumulator(
            artistKey: _isNumericId(rawArtistId) ? rawArtistId : primaryArtist,
            artistName: primaryArtist,
            coverUrl: e.coverUrl,
          ),
        );

        if (!_isNumericId(acc.artistKey) && _isNumericId(rawArtistId)) {
          acc.artistKey = rawArtistId;
        }

        acc.playCount += 1;
        acc.totalSeconds += e.listenedSeconds;
        if (acc.coverUrl.isEmpty && e.coverUrl.isNotEmpty) {
          acc.coverUrl = e.coverUrl;
        }
      }
    }

    // 2. Augment from HistoryRepository if any tracks weren't in events
    for (final item in HistoryRepository.instance.history) {
      final primaryArtist = _extractPrimaryArtist(item.track.artist);
      final mapKey = primaryArtist.trim().toLowerCase();
      if (mapKey.isEmpty || mapKey == 'unknown artist') continue;

      final rawArtistId = item.track.artistId.trim();

      final acc = artistMap.putIfAbsent(
        mapKey,
        () => _MutableArtistAccumulator(
          artistKey: _isNumericId(rawArtistId) ? rawArtistId : primaryArtist,
          artistName: primaryArtist,
          coverUrl: item.track.albumArt ?? '',
        ),
      );

      if (!_isNumericId(acc.artistKey) && _isNumericId(rawArtistId)) {
        acc.artistKey = rawArtistId;
      }

      if (!_events.any((e) => e.songId == item.track.id)) {
        acc.playCount += 1;
        acc.totalSeconds += 180;
      }
      if (acc.coverUrl.isEmpty && (item.track.albumArt?.isNotEmpty ?? false)) {
        acc.coverUrl = item.track.albumArt!;
      }
    }

    // 3. Count liked songs
    for (final liked in _likedSongs.values) {
      final mapKey = _extractPrimaryArtist(liked.artist).trim().toLowerCase();
      if (artistMap.containsKey(mapKey)) {
        artistMap[mapKey]!.likedSongsCount += 1;
        if (artistMap[mapKey]!.coverUrl.isEmpty && liked.coverUrl.isNotEmpty) {
          artistMap[mapKey]!.coverUrl = liked.coverUrl;
        }
      }
    }

    final sorted = artistMap.values
        .map(
          (a) => ArtistInsight(
            artistKey: a.artistKey,
            artistName: a.artistName,
            sampleCoverUrl: a.coverUrl,
            playCount: a.playCount,
            totalSeconds: a.totalSeconds,
            likedSongsCount: a.likedSongsCount,
          ),
        )
        .toList()
      ..sort((a, b) {
        final secCmp = b.totalSeconds.compareTo(a.totalSeconds);
        if (secCmp != 0) return secCmp;
        return b.playCount.compareTo(a.playCount);
      });

    return sorted.take(limit).toList();
  }

  UserInsightsSummary computeSummary({DateTime? nowOverride}) {
    final now = nowOverride ?? DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);

    int totalSeconds = 0;
    int currentMonthSeconds = 0;
    int prevMonthSeconds = 0;
    int completedCount = 0;

    final Map<String, _MutableArtistAccumulator> artistMap = {};
    final Map<String, int> moodSeconds = {};
    final Map<String, int> languageSeconds = {};
    final Map<String, int> genreSeconds = {};
    final List<int> hourBuckets = List.filled(24, 0);
    final List<int> weekdaySeconds = List.filled(7, 0);
    final Map<String, DateTime> lastPlayedBySongId = {};

    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekMidnight = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    for (final e in _events) {
      totalSeconds += e.listenedSeconds;
      if (e.wasCompleted) completedCount++;

      if (!e.timestamp.isBefore(currentMonthStart)) {
        currentMonthSeconds += e.listenedSeconds;
      } else if (!e.timestamp.isBefore(prevMonthStart) &&
          e.timestamp.isBefore(currentMonthStart)) {
        prevMonthSeconds += e.listenedSeconds;
      }

      hourBuckets[e.timestamp.hour] += e.listenedSeconds;

      if (!e.timestamp.isBefore(startOfWeekMidnight)) {
        weekdaySeconds[e.timestamp.weekday - 1] += e.listenedSeconds;
      }

      final existingLast = lastPlayedBySongId[e.songId];
      if (existingLast == null || e.timestamp.isAfter(existingLast)) {
        lastPlayedBySongId[e.songId] = e.timestamp;
      }

      if (!e.wasSkippedEarly) {
        final primaryArtist = _extractPrimaryArtist(e.artist);
        final mapKey = primaryArtist.trim().toLowerCase();
        if (mapKey.isEmpty || mapKey == 'unknown artist') continue;

        final rawArtistId = e.artistId.trim();

        final acc = artistMap.putIfAbsent(
          mapKey,
          () => _MutableArtistAccumulator(
            artistKey: _isNumericId(rawArtistId) ? rawArtistId : primaryArtist,
            artistName: primaryArtist,
            coverUrl: e.coverUrl,
          ),
        );

        if (!_isNumericId(acc.artistKey) && _isNumericId(rawArtistId)) {
          acc.artistKey = rawArtistId;
        }

        acc.playCount += 1;
        acc.totalSeconds += e.listenedSeconds;
        if (acc.coverUrl.isEmpty && e.coverUrl.isNotEmpty) {
          acc.coverUrl = e.coverUrl;
        }

        if (e.mood.isNotEmpty) {
          moodSeconds[e.mood] = (moodSeconds[e.mood] ?? 0) + e.listenedSeconds;
        }
        if (e.language.isNotEmpty) {
          languageSeconds[e.language] =
              (languageSeconds[e.language] ?? 0) + e.listenedSeconds;
        }
        for (final g in e.genres) {
          if (g.isNotEmpty) {
            genreSeconds[g] = (genreSeconds[g] ?? 0) + e.listenedSeconds;
          }
        }
      }
    }

    for (final liked in _likedSongs.values) {
      final mapKey = _extractPrimaryArtist(liked.artist).trim().toLowerCase();
      if (artistMap.containsKey(mapKey)) {
        artistMap[mapKey]!.likedSongsCount += 1;
      }
    }

    final topArtists =
        artistMap.values
            .map(
              (a) => ArtistInsight(
                artistKey: a.artistKey,
                artistName: a.artistName,
                sampleCoverUrl: a.coverUrl,
                playCount: a.playCount,
                totalSeconds: a.totalSeconds,
                likedSongsCount: a.likedSongsCount,
              ),
            )
            .toList()
          ..sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));

    final topMoods = _buildCategoryShares(moodSeconds);
    final topLanguages = _buildCategoryShares(languageSeconds);
    final topGenres = _buildCategoryShares(genreSeconds);

    final maxHourSec = hourBuckets.fold<int>(0, max);
    final hourlyNormalized = hourBuckets
        .map((s) => maxHourSec > 0 ? s / maxHourSec : 0.0)
        .toList(growable: false);

    final weeklyMins = weekdaySeconds
        .map((s) => s / 60.0)
        .toList(growable: false);

    final streaks = _calculateStreaks(now);
    final forgottenCutoff = now.subtract(const Duration(days: 14));
    final forgottenLiked = _likedSongs.values
        .where((song) {
          final lastPlayed = lastPlayedBySongId[song.id];
          return lastPlayed == null || lastPlayed.isBefore(forgottenCutoff);
        })
        .take(10)
        .toList();

    final completionRate = _events.isEmpty
        ? 0.0
        : (completedCount / _events.length) * 100.0;

    return UserInsightsSummary(
      totalListeningTime: Duration(seconds: totalSeconds),
      currentMonthListeningTime: Duration(seconds: currentMonthSeconds),
      previousMonthListeningTime: Duration(seconds: prevMonthSeconds),
      totalSongsPlayed: _events.where((e) => !e.wasSkippedEarly).length,
      completionRate: completionRate,
      currentStreakDays: streaks.$1,
      longestStreakDays: streaks.$2,
      likedSongsCount: _likedSongs.length,
      forgottenLikedSongs: forgottenLiked,
      topArtists: topArtists.take(5).toList(),
      topMoods: topMoods.take(5).toList(),
      topLanguages: topLanguages.take(4).toList(),
      topGenres: topGenres.take(5).toList(),
      hourlyActivityDistribution: hourlyNormalized,
      weeklyMinutesByWeekday: weeklyMins,
      listenerPersona: _derivePersona(topMoods, topLanguages, hourBuckets),
      peakListeningWindow: _derivePeakWindow(hourBuckets),
    );
  }

  UserTasteProfile buildTasteProfile() {
    final summary = computeSummary();
    final Map<String, double> artistWeights = {};
    if (summary.topArtists.isNotEmpty) {
      final maxSec = max(1, summary.topArtists.first.totalSeconds);
      for (final artist in summary.topArtists) {
        artistWeights[artist.artistKey] = (artist.totalSeconds / maxSec).clamp(
          0.0,
          1.0,
        );
      }
    }

    final Map<String, double> moodWeights = {
      for (final m in summary.topMoods)
        m.label.toLowerCase(): (m.percentage / 100.0).clamp(0.0, 1.0),
    };

    final Map<String, double> langWeights = {
      for (final l in summary.topLanguages)
        l.label.toLowerCase(): (l.percentage / 100.0).clamp(0.0, 1.0),
    };

    final Map<int, Map<String, int>> hourMoodCounts = {};
    for (final e in _events) {
      if (e.wasSkippedEarly || e.mood.isEmpty) continue;
      final bucket = hourMoodCounts.putIfAbsent(e.timestamp.hour, () => {});
      bucket[e.mood] = (bucket[e.mood] ?? 0) + e.listenedSeconds;
    }

    final Map<int, String> peakMoodByHour = {};
    hourMoodCounts.forEach((hour, moodMap) {
      if (moodMap.isNotEmpty) {
        final topEntry = moodMap.entries.reduce(
          (a, b) => a.value >= b.value ? a : b,
        );
        peakMoodByHour[hour] = topEntry.key;
      }
    });

    return UserTasteProfile(
      artistAffinity: artistWeights,
      moodAffinity: moodWeights,
      languageAffinity: langWeights,
      peakMoodByHour: peakMoodByHour,
      likedSongIds: _likedSongs.keys.toSet(),
    );
  }

  List<CategoryShare> _buildCategoryShares(Map<String, int> map) {
    final total = map.values.fold<int>(0, (sum, v) => sum + v);
    if (total <= 0) return const [];
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map(
          (e) => CategoryShare(
            label: _capitalize(e.key),
            seconds: e.value,
            percentage: (e.value / total) * 100.0,
          ),
        )
        .toList();
  }

  (int, int) _calculateStreaks(DateTime now) {
    if (_events.isEmpty) return (0, 0);
    final uniqueDays =
        _events
            .where((e) => e.listenedSeconds >= 30)
            .map(
              (e) => DateTime(
                e.timestamp.year,
                e.timestamp.month,
                e.timestamp.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (uniqueDays.isEmpty) return (0, 0);

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int currentStreak = 0;
    if (uniqueDays.first == today || uniqueDays.first == yesterday) {
      currentStreak = 1;
      for (int i = 0; i < uniqueDays.length - 1; i++) {
        if (uniqueDays[i].difference(uniqueDays[i + 1]).inDays == 1) {
          currentStreak++;
        } else {
          break;
        }
      }
    }

    int longestStreak = 1;
    int running = 1;
    for (int i = 0; i < uniqueDays.length - 1; i++) {
      if (uniqueDays[i].difference(uniqueDays[i + 1]).inDays == 1) {
        running++;
        if (running > longestStreak) longestStreak = running;
      } else {
        running = 1;
      }
    }

    return (currentStreak, max(currentStreak, longestStreak));
  }

  String _derivePeakWindow(List<int> hourBuckets) {
    final morning = hourBuckets.sublist(5, 12).fold(0, (a, b) => a + b);
    final afternoon = hourBuckets.sublist(12, 17).fold(0, (a, b) => a + b);
    final evening = hourBuckets.sublist(17, 22).fold(0, (a, b) => a + b);
    final night =
        hourBuckets.sublist(22, 24).fold(0, (a, b) => a + b) +
        hourBuckets.sublist(0, 5).fold(0, (a, b) => a + b);

    final windows = {
      'Late Night (10 PM - 5 AM)': night,
      'Morning (5 AM - 12 PM)': morning,
      'Afternoon (12 PM - 5 PM)': afternoon,
      'Evening (5 PM - 10 PM)': evening,
    };

    final top = windows.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return top.value == 0 ? 'Building Activity' : top.key;
  }

  String _derivePersona(
    List<CategoryShare> moods,
    List<CategoryShare> langs,
    List<int> hours,
  ) {
    final topMood = moods.isNotEmpty ? moods.first.label : 'Eclectic';
    final topLang = langs.isNotEmpty ? langs.first.label : 'Global';
    final nightSec =
        hours.sublist(22, 24).fold(0, (a, b) => a + b) +
        hours.sublist(0, 5).fold(0, (a, b) => a + b);
    final totalSec = hours.fold(0, (a, b) => a + b);

    final timeTag = (totalSec > 0 && nightSec / totalSec > 0.4)
        ? 'Night Owl'
        : 'Vibe Curator';
    return '$topLang $topMood • $timeTag';
  }

  String _extractPrimaryArtist(String rawArtist) {
    if (rawArtist.trim().isEmpty) return 'Unknown Artist';
    return rawArtist
        .split(
          RegExp(r'\s*(?:,|&|/|\bfeat\.?|\bft\.?)\s*', caseSensitive: false),
        )
        .first
        .trim();
  }

  bool _isNumericId(String s) => RegExp(r'^\d+$').hasMatch(s.trim());

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _persistEvents() async {
    try {
      final file = _getPersistentFile(_eventsFileName);
      final encoded = jsonEncode(_events.map((e) => e.toJson()).toList());
      await file.writeAsString(encoded);
    } catch (e) {
      if (kDebugMode) {
        print('[ListeningInsightsService] Error persisting events: $e');
      }
    }
  }

  Future<void> _persistLikedSongs() async {
    try {
      final file = _getPersistentFile(_likedSongsFileName);
      final encoded = jsonEncode(
        _likedSongs.values.map((s) => s.toJson()).toList(),
      );
      await file.writeAsString(encoded);
    } catch (e) {
      if (kDebugMode) {
        print('[ListeningInsightsService] Error persisting liked songs: $e');
      }
    }
  }
}

class _MutableArtistAccumulator {
  String artistKey;
  final String artistName;
  String coverUrl;
  int playCount = 0;
  int totalSeconds = 0;
  int likedSongsCount = 0;

  _MutableArtistAccumulator({
    required this.artistKey,
    required this.artistName,
    required this.coverUrl,
  });
}
