import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:sangeet/insights/models/listening_insights.dart';
import 'package:sangeet/insights/services/insight_service.dart';
import 'package:sangeet/models/album.dart';
import 'package:sangeet/models/artist.dart';
import 'package:sangeet/models/song.dart';
import 'package:sangeet/player/services/autoplay_engine.dart';
import 'package:sangeet/services/music_api_service.dart';

class _FakeMusicApiService implements MusicApiService {
  final List<Song> catalog;
  _FakeMusicApiService(this.catalog);

  @override
  Future<List<Song>> getAllSongs() async => catalog;

  @override
  Future<List<Song>> getSongSuggestions(String id) async =>
      catalog.where((s) => s.id != id).toList();

  @override
  Future<Song?> getSongById(String id) async {
    for (final s in catalog) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<List<Song>> getTrending() async => catalog;

  @override
  Future<List<Song>> searchSongs(String query) async => catalog;

  @override
  Future<List<Song>> getSongsByAlbum(String albumId) async => [];

  @override
  Future<List<Song>> getSongsByPlaylist(String playlistId) async => [];

  @override
  Future<List<Album>> getTrendingAlbums({int limit = 10}) async => [];

  @override
  Future<Album?> getAlbumById(String id) async => null;

  @override
  Future<List<Artist>> searchArtists(String query) async => [];

  @override
  Future<List<Album>> searchAlbums(String query) async => [];

  @override
  Future<Artist?> getArtistById(
    String id, {
    int songCount = 20,
    int albumCount = 20,
  }) async => null;

  @override
  Future<List<Song>> getArtistSongs(String id, {int page = 0}) async => [];

  @override
  Future<List<Album>> getArtistAlbums(String id, {int page = 0}) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListeningInsights Models & Aggregation Tests', () {
    test('ListeningEvent JSON serialization round-trip', () {
      final now = DateTime.now();
      final event = ListeningEvent(
        songId: 'song-1',
        title: 'Tum Hi Ho',
        artistId: 'art-1',
        artist: 'Arijit Singh',
        coverUrl: 'https://example.com/cover.jpg',
        language: 'hindi',
        mood: 'romantic',
        genres: const ['bollywood', 'soundtrack'],
        listenedSeconds: 150,
        totalDurationSeconds: 200,
        wasCompleted: true,
        wasSkippedEarly: false,
        timestamp: now,
      );

      final json = event.toJson();
      final restored = ListeningEvent.fromJson(json);

      expect(restored.songId, equals('song-1'));
      expect(restored.title, equals('Tum Hi Ho'));
      expect(restored.artist, equals('Arijit Singh'));
      expect(restored.language, equals('hindi'));
      expect(restored.mood, equals('romantic'));
      expect(restored.genres, contains('bollywood'));
      expect(restored.listenedSeconds, equals(150));
      expect(restored.wasCompleted, isTrue);
      expect(restored.wasSkippedEarly, isFalse);
    });

    test(
      'ListeningInsightsService ignores accidental taps < 5 seconds',
      () async {
        final service = ListeningInsightsService.instance;
        final initialCount = service.events.length;

        const song = Song(
          id: 'accidental-tap',
          title: 'Quick Skip',
          artist: 'Artist',
          coverUrl: '',
          duration: Duration(minutes: 3),
          streamUrl: 'https://example.com/stream.mp3',
          language: 'hindi',
          artistId: 'a1',
          mood: 'chill',
          genres: ['pop'],
        );

        await service.recordPlaybackSession(
          song: song,
          listenedDuration: const Duration(seconds: 3),
        );

        expect(service.events.length, equals(initialCount));
      },
    );

    test(
      'ListeningInsightsService records skip vs completion thresholds correctly',
      () async {
        final service = ListeningInsightsService.instance;
        const song = Song(
          id: 'eval-song',
          title: 'Threshold Test',
          artist: 'Test Artist',
          coverUrl: '',
          duration: Duration(seconds: 100),
          streamUrl: 'https://example.com/stream.mp3',
          language: 'hindi',
          artistId: 'a1',
          mood: 'sad',
          genres: ['bollywood'],
        );

        // Play 15s -> Skipped early
        await service.recordPlaybackSession(
          song: song,
          listenedDuration: const Duration(seconds: 15),
        );
        final skipEvent = service.events.last;
        expect(skipEvent.wasSkippedEarly, isTrue);
        expect(skipEvent.wasCompleted, isFalse);

        // Play 80s out of 100s -> Completed
        await service.recordPlaybackSession(
          song: song,
          listenedDuration: const Duration(seconds: 80),
        );
        final completeEvent = service.events.last;
        expect(completeEvent.wasSkippedEarly, isFalse);
        expect(completeEvent.wasCompleted, isTrue);
      },
    );

    test(
      'UserInsightsSummary computeSummary aggregates streak and persona',
      () {
        final service = ListeningInsightsService.instance;
        final now = DateTime(2026, 10, 26, 23, 0); // 11 PM

        final summary = service.computeSummary(nowOverride: now);

        expect(summary.hourlyActivityDistribution.length, equals(24));
        expect(summary.weeklyMinutesByWeekday.length, equals(7));
        expect(summary.listenerPersona, isNotEmpty);
        expect(summary.peakListeningWindow, isNotEmpty);
        expect(summary.monthlyGrowthPercent, isA<double>());
      },
    );

    test('buildTasteProfile returns normalized affinities', () {
      final service = ListeningInsightsService.instance;
      final profile = service.buildTasteProfile();

      for (final val in profile.artistAffinity.values) {
        expect(val, inInclusiveRange(0.0, 1.0));
      }
      for (final val in profile.moodAffinity.values) {
        expect(val, inInclusiveRange(0.0, 1.0));
      }
      for (final val in profile.languageAffinity.values) {
        expect(val, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('AutoplayEngine Personalization & Closed-Loop Refinement Tests', () {
    late AutoplayEngine engine;
    late _FakeMusicApiService api;

    final songA = Song(
      id: 's1',
      title: 'Kesariya',
      artist: 'Arijit Singh & Pritam',
      coverUrl: 'https://example.com/1.jpg',
      duration: const Duration(minutes: 4),
      streamUrl: 'https://example.com/1.mp3',
      language: 'hindi',
      artistId: 'arijit',
      mood: 'romantic',
      genres: const ['bollywood', 'love'],
    );

    final songB = Song(
      id: 's2',
      title: 'Channa Mereya',
      artist: 'Arijit Singh',
      coverUrl: 'https://example.com/2.jpg',
      duration: const Duration(minutes: 4),
      streamUrl: 'https://example.com/2.mp3',
      language: 'hindi',
      artistId: 'arijit',
      mood: 'sad',
      genres: const ['bollywood'],
    );

    final songC = Song(
      id: 's3',
      title: 'Party All Night',
      artist: 'Yo Yo Honey Singh',
      coverUrl: 'https://example.com/3.jpg',
      duration: const Duration(minutes: 3),
      streamUrl: 'https://example.com/3.mp3',
      language: 'punjabi',
      artistId: 'honeysingh',
      mood: 'party',
      genres: const ['club', 'dance'],
    );

    setUp(() {
      api = _FakeMusicApiService([songA, songB, songC]);
      engine = AutoplayEngine(api, Random(42));
    });

    test(
      'Taste Profile personalization bonus enhances candidate similarity score',
      () {
        final now = DateTime(2026, 10, 26, 14, 0); // 2 PM

        // Default score without taste profile
        final baseScore = engine.calculateSimilarityScore(
          anchor: songA,
          candidate: songB,
          isDirectApiSuggestion: false,
          now: now,
        );

        // Inject taste profile prioritizing Arijit Singh, Hindi, and Sad
        final profile = UserTasteProfile(
          artistAffinity: {'arijit': 1.0},
          moodAffinity: {'sad': 0.9},
          languageAffinity: {'hindi': 1.0},
          peakMoodByHour: {14: 'sad'},
          likedSongIds: {'s2'},
        );
        engine.updateTasteProfile(profile);

        final personalizedScore = engine.calculateSimilarityScore(
          anchor: songA,
          candidate: songB,
          isDirectApiSuggestion: false,
          now: now,
        );

        expect(personalizedScore, greaterThan(baseScore));
      },
    );

    test(
      'Mood adjacency matrix rewards compatible moods and penalizes clash',
      () {
        final now = DateTime(2026, 10, 26, 12, 0);

        // Sad candidate vs Sad anchor
        final sadScore = engine.calculateSimilarityScore(
          anchor: songB, // sad
          candidate: songB,
          isDirectApiSuggestion: false,
          now: now,
        );

        // Party candidate vs Sad anchor -> clashes
        final clashScore = engine.calculateSimilarityScore(
          anchor: songB, // sad
          candidate: songC, // party
          isDirectApiSuggestion: false,
          now: now,
        );

        expect(sadScore, greaterThan(clashScore));
      },
    );

    test(
      'Multi-artist collaboration matches solo artist for fatigue and affinity',
      () {
        // Record completion of songA (Arijit Singh & Pritam)
        engine.recordSongCompleted(songA);

        // Candidate songB (Arijit Singh solo) should receive artist fatigue penalty
        final now = DateTime(2026, 10, 26, 12, 0);
        final scoreAfterPlay = engine.calculateSimilarityScore(
          anchor: songA,
          candidate: songB,
          isDirectApiSuggestion: false,
          now: now,
        );

        engine.resetSession();
        final scoreFresh = engine.calculateSimilarityScore(
          anchor: songA,
          candidate: songB,
          isDirectApiSuggestion: false,
          now: now,
        );

        expect(scoreAfterPlay, lessThan(scoreFresh));
      },
    );

    test('Early skip accumulates artist penalty alongside mood penalty', () {
      engine.recordSongSkippedEarly(songA);

      expect(engine.skippedMoodPenalty, contains('romantic'));
      expect(engine.skippedArtistPenalty, contains('id:arijit'));
    });

    test(
      'Interleave artists prevents consecutive tracks from same primary artist',
      () {
        final songs = [
          songA, // Arijit
          songB, // Arijit
          songC, // Honey Singh
        ];

        final interleaved = engine.interleaveArtists(songs);

        expect(interleaved.length, equals(3));
        if (interleaved.length >= 2) {
          expect(
            interleaved[0].artistId == interleaved[1].artistId &&
                interleaved[0].artistId.isNotEmpty,
            isFalse,
          );
        }
      },
    );
  });
}
