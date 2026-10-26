import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/song.dart';
import '../../services/music_api_service.dart';
import '../../insights/models/listening_insights.dart';

class ScoredSong {
  final Song song;
  final double score;

  const ScoredSong({required this.song, required this.score});

  @override
  String toString() =>
      'ScoredSong(title: ${song.title}, score: ${score.toStringAsFixed(3)})';
}

class AutoplayEngine {
  final MusicApiService _api;
  final Random _random;

  final LinkedHashSet<String> _playedSongIds = LinkedHashSet<String>();
  final List<Song> _recentCompletedSongs = [];
  final Map<String, double> _skippedMoodPenalty = {};
  final Map<String, double> _skippedArtistPenalty = {};
  List<Song>? _catalogCache;
  UserTasteProfile _tasteProfile = const UserTasteProfile();

  static const int _maxSessionWindow = 5;
  static const int _maxPlayedHistory = 100;

  static const Map<String, Map<String, double>> _moodAdjacency = {
    'sad': {
      'melancholic': 0.80,
      'emotional': 0.75,
      'heartbreak': 0.85,
      'chill': 0.50,
      'acoustic': 0.55,
      'lofi': 0.55,
      'party': -0.25,
      'happy': -0.20,
      'workout': -0.30,
      'dance': -0.25,
    },
    'love': {
      'romantic': 0.85,
      'soulful': 0.70,
      'acoustic': 0.60,
      'chill': 0.50,
      'emotional': 0.55,
      'workout': -0.25,
    },
    'romantic': {
      'love': 0.85,
      'soulful': 0.70,
      'acoustic': 0.60,
      'chill': 0.50,
      'workout': -0.25,
    },
    'chill': {
      'lofi': 0.80,
      'acoustic': 0.70,
      'relaxing': 0.80,
      'sad': 0.45,
      'love': 0.45,
      'workout': -0.25,
      'party': -0.20,
    },
    'party': {
      'dance': 0.85,
      'upbeat': 0.80,
      'energetic': 0.75,
      'happy': 0.65,
      'workout': 0.60,
      'sad': -0.30,
      'melancholic': -0.30,
    },
    'happy': {
      'upbeat': 0.80,
      'feel good': 0.85,
      'party': 0.65,
      'dance': 0.65,
      'sad': -0.25,
      'heartbreak': -0.30,
    },
  };

  AutoplayEngine(this._api, [Random? random]) : _random = random ?? Random();

  void updateTasteProfile(UserTasteProfile profile) {
    _tasteProfile = profile;
  }

  @visibleForTesting
  Set<String> get playedSongIds => Set.unmodifiable(_playedSongIds);

  @visibleForTesting
  List<Song> get recentCompletedSongs =>
      List.unmodifiable(_recentCompletedSongs);

  @visibleForTesting
  Map<String, double> get skippedMoodPenalty =>
      Map.unmodifiable(_skippedMoodPenalty);

  @visibleForTesting
  Map<String, double> get skippedArtistPenalty =>
      Map.unmodifiable(_skippedArtistPenalty);

  @visibleForTesting
  List<Song> interleaveArtists(List<Song> songs, [Song? seedSong]) =>
      _interleaveArtists(songs, seedSong);

  void recordSongCompleted(Song song) {
    _trackPlayedId(song.id);
    _recentCompletedSongs.add(song);
    if (_recentCompletedSongs.length > _maxSessionWindow) {
      _recentCompletedSongs.removeAt(0);
    }

    final moodKey = song.mood.trim().toLowerCase();
    if (_skippedMoodPenalty.containsKey(moodKey)) {
      final updated = (_skippedMoodPenalty[moodKey]! * 0.5).clamp(0.0, 1.0);
      if (updated < 0.02) {
        _skippedMoodPenalty.remove(moodKey);
      } else {
        _skippedMoodPenalty[moodKey] = updated;
      }
    }

    for (final artistKey in _extractArtistKeys(song)) {
      if (_skippedArtistPenalty.containsKey(artistKey)) {
        final updated = (_skippedArtistPenalty[artistKey]! * 0.5).clamp(
          0.0,
          1.0,
        );
        if (updated < 0.02) {
          _skippedArtistPenalty.remove(artistKey);
        } else {
          _skippedArtistPenalty[artistKey] = updated;
        }
      }
    }
  }

  void recordSongSkippedEarly(Song song) {
    _trackPlayedId(song.id);
    final moodKey = song.mood.trim().toLowerCase();
    if (moodKey.isNotEmpty) {
      _skippedMoodPenalty[moodKey] =
          ((_skippedMoodPenalty[moodKey] ?? 0.0) + 0.15).clamp(0.0, 0.6);
    }

    for (final artistKey in _extractArtistKeys(song)) {
      _skippedArtistPenalty[artistKey] =
          ((_skippedArtistPenalty[artistKey] ?? 0.0) + 0.20).clamp(0.0, 0.5);
    }
  }

  void resetSession() {
    _playedSongIds.clear();
    _recentCompletedSongs.clear();
    _skippedMoodPenalty.clear();
    _skippedArtistPenalty.clear();
  }

  void _trackPlayedId(String id) {
    _playedSongIds.remove(id);
    _playedSongIds.add(id);
    while (_playedSongIds.length > _maxPlayedHistory) {
      _playedSongIds.remove(_playedSongIds.first);
    }
  }

  Future<List<Song>> generateAutoplayQueue({
    required String currentSongId,
    Song? currentSong,
    int limit = 10,
    Set<String> queuedSongIds = const {},
  }) async {
    Song? seedSong = currentSong;
    if (seedSong == null || seedSong.id != currentSongId) {
      try {
        final fetched = await _api.getSongById(currentSongId);
        if (fetched != null) seedSong = fetched;
      } catch (e) {
        if (kDebugMode) print('AutoplayEngine: getSongById error: $e');
      }
    }

    seedSong ??=
        currentSong ??
        Song(
          id: currentSongId,
          title: 'Current Track',
          artist: 'Current Artist',
          coverUrl: '',
          duration: const Duration(minutes: 3),
        );

    _trackPlayedId(seedSong.id);

    List<Song> suggestions = [];
    try {
      suggestions = await _api.getSongSuggestions(currentSongId);
    } catch (e) {
      if (kDebugMode) print('AutoplayEngine: suggestions error: $e');
    }

    final suggestedIds = suggestions.map((s) => s.id).toSet();
    final Map<String, Song> candidateMap = {
      for (final s in suggestions) s.id: s,
    };

    final seedLang = seedSong.language.trim().toLowerCase();
    final seedMood = seedSong.mood.trim().toLowerCase();

    final matchingSuggestionsCount = suggestions
        .where(
          (s) =>
              s.language.trim().toLowerCase() == seedLang &&
              _moodSimilarity(s.mood, seedMood) >= 0.70 &&
              !_playedSongIds.contains(s.id) &&
              !queuedSongIds.contains(s.id),
        )
        .length;

    if (matchingSuggestionsCount < limit) {
      try {
        _catalogCache ??= await _api.getAllSongs();
        for (final song in _catalogCache!) {
          candidateMap.putIfAbsent(song.id, () => song);
        }
      } catch (e) {
        if (kDebugMode) print('AutoplayEngine: catalog backfill error: $e');
      }
    }

    final hardExcludedIds = {...queuedSongIds, seedSong.id};
    var candidates = candidateMap.values
        .where(
          (s) =>
              !hardExcludedIds.contains(s.id) && !_playedSongIds.contains(s.id),
        )
        .toList();

    if (candidates.length < (limit ~/ 2).clamp(1, 5) &&
        _playedSongIds.length > 1) {
      final recentProtected = _playedSongIds.toList().reversed.take(5).toSet();
      candidates = candidateMap.values
          .where(
            (s) =>
                !hardExcludedIds.contains(s.id) &&
                !recentProtected.contains(s.id),
          )
          .toList();
    }

    if (candidates.isEmpty) return const [];

    final sameLanguageCandidates = candidates
        .where((s) => s.language.trim().toLowerCase() == seedLang)
        .toList();

    final activePool = sameLanguageCandidates.length >= (limit ~/ 2).clamp(1, 5)
        ? sameLanguageCandidates
        : candidates;

    final now = DateTime.now();
    final scoredCandidates = activePool.map((candidate) {
      final score = calculateSimilarityScore(
        candidate: candidate,
        anchor: seedSong!,
        isDirectApiSuggestion: suggestedIds.contains(candidate.id),
        now: now,
      );
      return ScoredSong(song: candidate, score: score);
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    return _selectTopWithDiversity(scoredCandidates, limit, seedSong);
  }

  @visibleForTesting
  double calculateSimilarityScore({
    required Song candidate,
    required Song anchor,
    required bool isDirectApiSuggestion,
    DateTime? now,
  }) {
    final double languageScore = _computeLanguageScore(candidate, anchor);
    final double moodScore = _computeMoodScore(candidate, anchor);
    final double genreScore = _jaccardSimilarity(
      candidate.genres,
      anchor.genres,
    );
    final double suggestionScore = isDirectApiSuggestion ? 1.0 : 0.0;
    final double artistScore = _computeArtistAffinity(candidate, anchor);
    final double durationBonus = _computeDurationCoherence(candidate, anchor);
    final double artistFatigue = _computeArtistFatigue(candidate);
    final double skipMoodPenalty =
        _skippedMoodPenalty[candidate.mood.trim().toLowerCase()] ?? 0.0;
    final double skipArtistPenalty = _computeSkippedArtistPenalty(candidate);
    final double personalizationBonus =
        _computeHistoricalPersonalizationBonus(candidate, now ?? DateTime.now());

    return (languageScore * 0.40) +
        (moodScore * 0.30) +
        (suggestionScore * 0.15) +
        (genreScore * 0.10) +
        (artistScore * 0.05) +
        durationBonus +
        personalizationBonus -
        artistFatigue -
        skipMoodPenalty -
        skipArtistPenalty;
  }

  double _computeHistoricalPersonalizationBonus(Song candidate, DateTime now) {
    if (_tasteProfile.artistAffinity.isEmpty &&
        _tasteProfile.moodAffinity.isEmpty &&
        _tasteProfile.languageAffinity.isEmpty) {
      return 0.0;
    }

    double bonus = 0.0;

    final candArtistKeys = _extractArtistKeys(candidate);
    double maxArtistAffinity = 0.0;
    for (final key in candArtistKeys) {
      final nameKey = key.startsWith('id:') ? key : key;
      final affinity = _tasteProfile.artistAffinity[nameKey] ?? 0.0;
      if (affinity > maxArtistAffinity) maxArtistAffinity = affinity;
    }
    bonus += 0.06 * maxArtistAffinity;

    final candMood = candidate.mood.trim().toLowerCase();
    bonus += 0.04 * (_tasteProfile.moodAffinity[candMood] ?? 0.0);

    final candLang = candidate.language.trim().toLowerCase();
    bonus += 0.03 * (_tasteProfile.languageAffinity[candLang] ?? 0.0);

    final peakMood = _tasteProfile.peakMoodByHour[now.hour];
    if (peakMood != null && peakMood == candMood) {
      bonus += 0.06;
    }

    if (_tasteProfile.likedSongIds.contains(candidate.id)) {
      bonus += 0.04;
    }

    return bonus;
  }

  double _computeLanguageScore(Song candidate, Song anchor) {
    final cLang = candidate.language.trim().toLowerCase();
    final aLang = anchor.language.trim().toLowerCase();
    final double anchorMatch = cLang == aLang ? 1.0 : 0.0;

    if (_recentCompletedSongs.isEmpty) return anchorMatch;

    double weightedMatches = 0.0;
    double totalWeight = 0.0;

    for (int i = 0; i < _recentCompletedSongs.length; i++) {
      final weight = (i + 1) / _recentCompletedSongs.length;
      if (_recentCompletedSongs[i].language.trim().toLowerCase() == cLang) {
        weightedMatches += weight;
      }
      totalWeight += weight;
    }

    final sessionMatch = totalWeight > 0 ? weightedMatches / totalWeight : 0.0;
    return (anchorMatch * 0.70) + (sessionMatch * 0.30);
  }

  double _computeMoodScore(Song candidate, Song anchor) {
    final cMood = candidate.mood.trim().toLowerCase();
    final aMood = anchor.mood.trim().toLowerCase();
    final double anchorMatch = _moodSimilarity(cMood, aMood);

    if (_recentCompletedSongs.isEmpty) return anchorMatch;

    double weightedMatches = 0.0;
    double totalWeight = 0.0;

    for (int i = 0; i < _recentCompletedSongs.length; i++) {
      final weight = (i + 1) / _recentCompletedSongs.length;
      final histMood = _recentCompletedSongs[i].mood.trim().toLowerCase();
      weightedMatches += weight * _moodSimilarity(cMood, histMood);
      totalWeight += weight;
    }

    final sessionMatch = totalWeight > 0 ? weightedMatches / totalWeight : 0.0;
    return (anchorMatch * 0.65) + (sessionMatch * 0.35);
  }

  double _moodSimilarity(String moodA, String moodB) {
    final a = moodA.trim().toLowerCase();
    final b = moodB.trim().toLowerCase();
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a == b) return 1.0;
    return _moodAdjacency[a]?[b] ?? _moodAdjacency[b]?[a] ?? 0.0;
  }

  double _jaccardSimilarity(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final setA = a
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    final setB = b
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (setA.isEmpty || setB.isEmpty) return 0.0;

    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    return union == 0 ? 0.0 : intersection / union;
  }

  Set<String> _extractArtistKeys(Song song) {
    final Set<String> keys = {};
    if (song.artistId.trim().isNotEmpty) {
      keys.add('id:${song.artistId.trim().toLowerCase()}');
    }
    if (song.artist.trim().isNotEmpty) {
      final tokens = song.artist
          .toLowerCase()
          .split(RegExp(r'\s*(?:,|&|/|\bfeat\.?|\bft\.?|\bx\b)\s*'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      keys.addAll(tokens);
    }
    return keys;
  }

  double _computeArtistAffinity(Song candidate, Song anchor) {
    if (candidate.artistId.isNotEmpty &&
        anchor.artistId.isNotEmpty &&
        candidate.artistId == anchor.artistId) {
      return 1.0;
    }
    if (candidate.artist.isNotEmpty &&
        candidate.artist.trim().toLowerCase() ==
            anchor.artist.trim().toLowerCase()) {
      return 1.0;
    }

    final candTokens = _extractArtistKeys(candidate);
    final anchorTokens = _extractArtistKeys(anchor);
    if (candTokens.isEmpty || anchorTokens.isEmpty) return 0.0;

    final overlap = candTokens.intersection(anchorTokens).length;
    return overlap > 0 ? 0.80 : 0.0;
  }

  double _computeArtistFatigue(Song candidate) {
    if (_recentCompletedSongs.isEmpty) return 0.0;
    final candKeys = _extractArtistKeys(candidate);
    if (candKeys.isEmpty) return 0.0;

    final recentTail = _recentCompletedSongs.reversed.take(2);
    final count = recentTail.where((s) {
      final histKeys = _extractArtistKeys(s);
      return candKeys.intersection(histKeys).isNotEmpty;
    }).length;

    return count * 0.25;
  }

  double _computeSkippedArtistPenalty(Song candidate) {
    if (_skippedArtistPenalty.isEmpty) return 0.0;
    double maxPenalty = 0.0;
    for (final key in _extractArtistKeys(candidate)) {
      final p = _skippedArtistPenalty[key] ?? 0.0;
      if (p > maxPenalty) maxPenalty = p;
    }
    return maxPenalty;
  }

  double _computeDurationCoherence(Song candidate, Song anchor) {
    final candSec = candidate.duration.inSeconds;
    final anchorSec = anchor.duration.inSeconds;
    if (candSec <= 0 || anchorSec <= 0) return 0.0;
    final diff = (candSec - anchorSec).abs();
    if (diff > 240) return -0.05;
    return 0.0;
  }

  List<Song> _selectTopWithDiversity(
    List<ScoredSong> ranked,
    int limit,
    Song? seedSong,
  ) {
    if (ranked.length <= limit) {
      return _interleaveArtists(ranked.map((e) => e.song).toList(), seedSong);
    }

    final List<Song> selected = [];
    final List<ScoredSong> pool = ranked.take(limit * 3).toList();
    final Map<String, int> artistCountInBatch = {};

    if (seedSong != null) {
      final seedKey = _primaryArtistKey(seedSong);
      artistCountInBatch[seedKey] = 1;
    }

    while (selected.length < limit && pool.isNotEmpty) {
      final adjustedScores = pool.map((item) {
        final artistKey = _primaryArtistKey(item.song);
        final artistPenalty = (artistCountInBatch[artistKey] ?? 0) * 0.30;
        return item.score - artistPenalty;
      }).toList();

      final maxScore = adjustedScores.reduce(max);
      final weights = adjustedScores
          .map((score) => exp((score - maxScore) * 4.0))
          .toList();

      final totalWeight = weights.fold(0.0, (sum, w) => sum + w);
      int chosenIndex = 0;

      if (totalWeight > 0 && !totalWeight.isNaN && !totalWeight.isInfinite) {
        double roll = _random.nextDouble() * totalWeight;
        for (int i = 0; i < weights.length; i++) {
          roll -= weights[i];
          if (roll <= 0) {
            chosenIndex = i;
            break;
          }
        }
      }

      final chosen = pool.removeAt(chosenIndex).song;
      selected.add(chosen);
      final artistKey = _primaryArtistKey(chosen);
      artistCountInBatch[artistKey] = (artistCountInBatch[artistKey] ?? 0) + 1;
    }

    return _interleaveArtists(selected, seedSong);
  }

  String _primaryArtistKey(Song song) {
    if (song.artistId.trim().isNotEmpty) {
      return song.artistId.trim().toLowerCase();
    }
    final keys = _extractArtistKeys(song);
    return keys.isNotEmpty ? keys.first : song.artist.trim().toLowerCase();
  }

  List<Song> _interleaveArtists(List<Song> songs, Song? seedSong) {
    if (songs.length <= 2) return songs;
    final List<Song> remaining = List.from(songs);
    final List<Song> ordered = [];
    String? lastArtist = seedSong != null ? _primaryArtistKey(seedSong) : null;

    while (remaining.isNotEmpty) {
      int pickIndex = remaining.indexWhere(
        (s) => _primaryArtistKey(s) != lastArtist,
      );
      if (pickIndex == -1) pickIndex = 0;
      final picked = remaining.removeAt(pickIndex);
      ordered.add(picked);
      lastArtist = _primaryArtistKey(picked);
    }

    return ordered;
  }
}
