// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sangeet/models/models.dart';
import 'package:sangeet/player/bloc/player_bloc.dart';
import 'package:sangeet/player/services/autoplay_engine.dart';
import 'package:sangeet/services/music_api_service.dart';

class MockMusicApiService implements MusicApiService {
  final List<Song> suggestions;
  final List<Song> catalog;
  final Map<String, Song> songMap;

  MockMusicApiService({
    this.suggestions = const [],
    this.catalog = const [],
    Map<String, Song>? songMap,
  }) : songMap = songMap ?? {};

  @override
  Future<List<Song>> getSongSuggestions(String id) async => suggestions;

  @override
  Future<List<Song>> getAllSongs() async => catalog;

  @override
  Future<Song?> getSongById(String id) async => songMap[id];

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

class MockJustAudioPlatform extends JustAudioPlatform
    with MockPlatformInterfaceMixin {
  final Map<String, MockAudioPlayerPlatform> players = {};

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    final p = MockAudioPlayerPlatform(request.id);
    players[request.id] = p;
    return p;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async {
    players.remove(request.id);
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async {
    players.clear();
    return DisposeAllPlayersResponse();
  }
}

class MockAudioPlayerPlatform extends AudioPlayerPlatform {
  MockAudioPlayerPlatform(super.id);

  bool isPlaying = false;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    return LoadResponse(duration: const Duration(minutes: 3));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    isPlaying = true;
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    isPlaying = false;
    return PauseResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();

  @override
  Future<SeekResponse> seek(SeekRequest request) async => SeekResponse();

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async => SetShuffleModeResponse();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutoplayEngine Mathematical & Feature Scoring Tests', () {
    late AutoplayEngine engine;
    late MockMusicApiService mockApi;

    final anchor = Song(
      id: 'song-anchor',
      title: 'Anchor Song',
      artist: 'Arijit Singh',
      artistId: 'art-arijit',
      coverUrl: '',
      duration: const Duration(minutes: 3, seconds: 30),
      language: 'hindi',
      mood: 'love',
      genres: const ['bollywood', 'romantic', 'melodic'],
    );

    setUp(() {
      mockApi = MockMusicApiService();
      engine = AutoplayEngine(mockApi);
    });

    test('exact match score incorporates all 5 feature weights', () {
      final candidate = Song(
        id: 'candidate-1',
        title: 'Perfect Match',
        artist: 'Arijit Singh',
        artistId: 'art-arijit',
        coverUrl: '',
        duration: const Duration(minutes: 3),
        language: 'hindi',
        mood: 'love',
        genres: const ['bollywood', 'romantic', 'melodic'],
      );

      // Language = 1.0 * 0.40 = 0.40
      // Mood = 1.0 * 0.30 = 0.30
      // Suggestion = 1.0 * 0.15 = 0.15
      // Genre Jaccard = 3/3 = 1.0 * 0.10 = 0.10
      // Artist Affinity = 1.0 * 0.05 = 0.05
      // Total = 1.00
      final score = engine.calculateSimilarityScore(
        candidate: candidate,
        anchor: anchor,
        isDirectApiSuggestion: true,
      );

      expect(score, closeTo(1.00, 0.001));
    });

    test('completely mismatched candidate receives low score', () {
      final mismatch = Song(
        id: 'mismatch-1',
        title: 'Different Vibe',
        artist: 'Taylor Swift',
        artistId: 'art-taylor',
        coverUrl: '',
        duration: const Duration(minutes: 3),
        language: 'english',
        mood: 'party',
        genres: const ['pop', 'country'],
      );

      // Language = 0, Mood = 0, Suggestion = 0, Genre = 0, Artist = 0
      final score = engine.calculateSimilarityScore(
        candidate: mismatch,
        anchor: anchor,
        isDirectApiSuggestion: false,
      );

      expect(score, closeTo(0.00, 0.001));
    });

    test('early skip adds mood penalty and completed song halves it', () {
      final skippedSong = Song(
        id: 'skipped-1',
        title: 'Party Song',
        artist: 'Badshah',
        coverUrl: '',
        duration: const Duration(minutes: 3),
        language: 'hindi',
        mood: 'party',
      );

      expect(engine.skippedMoodPenalty['party'], isNull);

      // Record early skip (<30s) -> +0.15
      engine.recordSongSkippedEarly(skippedSong);
      expect(engine.skippedMoodPenalty['party'], closeTo(0.15, 0.001));

      // Second skip -> +0.15 = 0.30
      engine.recordSongSkippedEarly(skippedSong);
      expect(engine.skippedMoodPenalty['party'], closeTo(0.30, 0.001));

      // Record completed song with same mood -> halves penalty (0.30 * 0.5 = 0.15)
      engine.recordSongCompleted(skippedSong);
      expect(engine.skippedMoodPenalty['party'], closeTo(0.15, 0.001));
    });

    test('session taste vector adjusts score with mood decay', () {
      // Completed songs with 'melodic' mood instead of 'love'
      final songMelodic = Song(
        id: 'sm',
        title: 'Melodic Song',
        artist: 'Sonu',
        coverUrl: '',
        duration: const Duration(minutes: 3),
        language: 'hindi',
        mood: 'melodic',
      );
      engine.recordSongCompleted(songMelodic);

      final candidate = Song(
        id: 'c1',
        title: 'Love Song',
        artist: 'Other',
        coverUrl: '',
        duration: const Duration(minutes: 3),
        language: 'hindi',
        mood: 'love',
        genres: anchor.genres,
      );

      final score = engine.calculateSimilarityScore(
        candidate: candidate,
        anchor: anchor,
        isDirectApiSuggestion: false,
      );

      // Anchor mood matches (1.0 * 0.65), session mood differs (0.0 * 0.35) -> 0.65 * 0.30 = 0.195
      // Language matches both anchor and session -> 1.0 * 0.40 = 0.40
      // Genre = 1.0 * 0.10 = 0.10
      // Total = 0.40 + 0.195 + 0.10 = 0.695
      expect(score, closeTo(0.695, 0.001));
    });

    test(
      'artist fatigue subtracts 0.25 per recent play in last 2 completed songs',
      () {
        final songA = Song(
          id: 's1',
          title: 'Track 1',
          artist: 'Arijit Singh',
          artistId: 'art-arijit',
          coverUrl: '',
          duration: const Duration(minutes: 3),
          language: 'hindi',
          mood: 'love',
        );
        final songB = Song(
          id: 's2',
          title: 'Track 2',
          artist: 'Arijit Singh',
          artistId: 'art-arijit',
          coverUrl: '',
          duration: const Duration(minutes: 3),
          language: 'hindi',
          mood: 'love',
        );

        engine.recordSongCompleted(songA);
        engine.recordSongCompleted(songB);

        final candidate = Song(
          id: 'c1',
          title: 'Next Track',
          artist: 'Arijit Singh',
          artistId: 'art-arijit',
          coverUrl: '',
          duration: const Duration(minutes: 3),
          language: 'hindi',
          mood: 'love',
          genres: anchor.genres,
        );

        // Base score = 1.00. Artist played 2 times in last 2 tracks -> fatigue = 2 * 0.25 = 0.50
        final score = engine.calculateSimilarityScore(
          candidate: candidate,
          anchor: anchor,
          isDirectApiSuggestion: true,
        );

        // 1.00 base score - 0.50 fatigue = 0.50
        expect(score, closeTo(0.50, 0.001));
      },
    );

    test(
      'generateAutoplayQueue pulls suggestions and backfills from catalog',
      () async {
        final s1 = Song(
          id: 'sug-1',
          title: 'Suggested 1',
          artist: 'Pritam',
          coverUrl: '',
          duration: const Duration(minutes: 3),
          language: 'hindi',
          mood: 'love',
          genres: const ['bollywood'],
        );
        final cat1 = Song(
          id: 'cat-1',
          title: 'Catalog 1',
          artist: 'Shreya',
          coverUrl: '',
          duration: const Duration(minutes: 3),
          language: 'hindi',
          mood: 'love',
          genres: const ['bollywood'],
        );
        final cat2 = Song(
          id: 'cat-2',
          title: 'Catalog 2',
          artist: 'Sonu',
          coverUrl: '',
          duration: const Duration(minutes: 3),
          language: 'hindi',
          mood: 'love',
          genres: const ['bollywood'],
        );

        mockApi = MockMusicApiService(
          suggestions: [s1],
          catalog: [cat1, cat2],
          songMap: {anchor.id: anchor},
        );
        engine = AutoplayEngine(mockApi);

        final queue = await engine.generateAutoplayQueue(
          currentSongId: anchor.id,
          currentSong: anchor,
          limit: 3,
        );

        expect(queue.isNotEmpty, isTrue);
        final ids = queue.map((s) => s.id).toList();
        expect(ids.contains(anchor.id), isFalse);
        expect(ids.contains('sug-1'), isTrue);
      },
    );

    test('resetSession clears played IDs and penalties', () {
      engine.recordSongCompleted(anchor);
      engine.recordSongSkippedEarly(anchor);
      expect(engine.playedSongIds.isNotEmpty, isTrue);

      engine.resetSession();
      expect(engine.playedSongIds.isEmpty, isTrue);
      expect(engine.recentCompletedSongs.isEmpty, isTrue);
      expect(engine.skippedMoodPenalty.isEmpty, isTrue);
    });
  });

  group('PlayerBloc Queue Operations & Autoplay Integration Tests', () {
    late PlayerBloc bloc;
    late MockMusicApiService mockApi;
    late AutoplayEngine mockEngine;

    final sampleCatalog = [
      const Song(
        id: 'cat-1',
        title: 'Cat 1',
        artist: 'Artist 1',
        coverUrl: '',
        duration: Duration(minutes: 3),
        language: 'hindi',
        mood: 'love',
      ),
      const Song(
        id: 'cat-2',
        title: 'Cat 2',
        artist: 'Artist 2',
        coverUrl: '',
        duration: Duration(minutes: 3),
        language: 'hindi',
        mood: 'love',
      ),
      const Song(
        id: 'cat-3',
        title: 'Cat 3',
        artist: 'Artist 3',
        coverUrl: '',
        duration: Duration(minutes: 3),
        language: 'hindi',
        mood: 'love',
      ),
    ];

    setUp(() {
      JustAudioPlatform.instance = MockJustAudioPlatform();
      mockApi = MockMusicApiService(catalog: sampleCatalog);
      mockEngine = AutoplayEngine(mockApi);
      bloc = PlayerBloc(autoplayEngine: mockEngine);
    });

    tearDown(() async {
      await bloc.close();
    });

    test('initial state has empty queue and null track', () {
      expect(bloc.state.isAutoplayEnabled, isTrue);
      expect(bloc.state.isLoadingAutoplay, isFalse);
      expect(bloc.state.queue.isEmpty, isTrue);
      expect(bloc.state.currentTrack, isNull);
    });

    test(
      'playing first song sets it as Now Playing and fills Up Next via autoplay without hardcoded tracks',
      () async {
        const firstTrack = Track(
          id: 'first-play',
          title: 'Kesariya',
          artist: 'Arijit Singh',
          duration: '04:28',
          formatBadge: '320k',
          language: 'hindi',
          mood: 'love',
        );

        bloc.add(const PlayerPlayTrack(firstTrack));
        await pumpEventQueue();

        // Current track is the selected first song
        expect(bloc.state.currentTrack?.id, equals('first-play'));
        expect(bloc.state.queue.first.id, equals('first-play'));

        // Up Next contains the autoplay recommendations from catalog
        final upcoming = bloc.state.queue.sublist(1);
        expect(upcoming.isNotEmpty, isTrue);
        expect(upcoming.every((t) => t.isAutoplay), isTrue);
        // None of the old hardcoded tracks exist
        expect(bloc.state.queue.any((t) => t.title == 'Continuum'), isFalse);
        expect(bloc.state.queue.any((t) => t.title == 'Spaces'), isFalse);
      },
    );

    test(
      'PlayerAddToQueue with playNext inserts immediately after currentIndex',
      () async {
        const track1 = Track(
          id: 't-1',
          title: 'Song 1',
          artist: 'Artist',
          duration: '03:00',
          formatBadge: '320k',
        );
        bloc.add(const PlayerPlayTrack(track1));
        await pumpEventQueue();

        const urgentTrack = Track(
          id: 'urgent-track',
          title: 'Play Next Song',
          artist: 'Artist',
          duration: '03:15',
          formatBadge: '320k',
        );
        final activeIndex = bloc.state.currentIndex;
        bloc.add(const PlayerAddToQueue(urgentTrack, playNext: true));
        await pumpEventQueue();

        expect(bloc.state.queue[activeIndex + 1].id, equals('urgent-track'));
      },
    );

    test(
      'PlayerAddToQueue without playNext adds to end of user queue',
      () async {
        const track1 = Track(
          id: 't-1',
          title: 'Song 1',
          artist: 'Artist',
          duration: '03:00',
          formatBadge: '320k',
        );
        bloc.add(const PlayerPlayTrack(track1));
        await pumpEventQueue();

        const endTrack = Track(
          id: 'end-track',
          title: 'Add To End Song',
          artist: 'Artist',
          duration: '04:00',
          formatBadge: '320k',
        );
        bloc.add(const PlayerAddToQueue(endTrack, playNext: false));
        await pumpEventQueue();

        expect(bloc.state.queue.any((t) => t.id == 'end-track'), isTrue);
      },
    );

    test(
      'PlayerRemoveFromQueue correctly removes track and adjusts index',
      () async {
        const track1 = Track(
          id: 't-1',
          title: 'Song 1',
          artist: 'Artist',
          duration: '03:00',
          formatBadge: '320k',
        );
        const track2 = Track(
          id: 't-2',
          title: 'Song 2',
          artist: 'Artist',
          duration: '03:00',
          formatBadge: '320k',
        );
        bloc.add(const PlayerPlayQueue([track1, track2], initialIndex: 0));
        await pumpEventQueue();

        final initialLength = bloc.state.queue.length;
        bloc.add(const PlayerRemoveFromQueue(1));
        await pumpEventQueue();

        expect(bloc.state.queue.length, equals(initialLength - 1));
        expect(bloc.state.queue.any((t) => t.id == 't-2'), isFalse);
      },
    );

    test('PlayerReorderQueue updates track positions', () async {
      const track1 = Track(
        id: 't-1',
        title: 'Song 1',
        artist: 'Artist',
        duration: '03:00',
        formatBadge: '320k',
      );
      const track2 = Track(
        id: 't-2',
        title: 'Song 2',
        artist: 'Artist',
        duration: '03:00',
        formatBadge: '320k',
      );
      const track3 = Track(
        id: 't-3',
        title: 'Song 3',
        artist: 'Artist',
        duration: '03:00',
        formatBadge: '320k',
      );
      bloc.add(
        const PlayerPlayQueue([track1, track2, track3], initialIndex: 0),
      );
      await pumpEventQueue();

      bloc.add(const PlayerReorderQueue(0, 3));
      await pumpEventQueue();

      expect(bloc.state.queue[2].id, equals('t-1'));
      expect(bloc.state.queue[0].id, equals('t-2'));
    });

    test(
      'PlayerClearUpcomingQueue removes future tracks after currentIndex',
      () async {
        const track1 = Track(
          id: 't-1',
          title: 'Song 1',
          artist: 'Artist',
          duration: '03:00',
          formatBadge: '320k',
        );
        bloc.add(const PlayerPlayTrack(track1));
        await pumpEventQueue();

        final currentIndex = bloc.state.currentIndex;
        // When autoplay is enabled, clearing queue replenishes autoplay recommendations
        bloc.add(const PlayerClearUpcomingQueue());
        await pumpEventQueue();

        final upcoming = bloc.state.queue.sublist(currentIndex + 1);
        expect(upcoming.every((t) => t.isAutoplay), isTrue);

        // When autoplay is disabled, clearing leaves exactly current tracks
        bloc.add(const PlayerToggleAutoplay());
        await pumpEventQueue();
        expect(bloc.state.queue.length, equals(currentIndex + 1));
      },
    );

    test(
      'PlayerToggleAutoplay toggles state and removes autoplay tracks when off',
      () async {
        const track1 = Track(
          id: 't-1',
          title: 'Song 1',
          artist: 'Artist',
          duration: '03:00',
          formatBadge: '320k',
        );
        bloc.add(const PlayerPlayTrack(track1));
        await pumpEventQueue();

        expect(bloc.state.queue.any((t) => t.isAutoplay), isTrue);

        bloc.add(const PlayerToggleAutoplay());
        await pumpEventQueue();
        expect(bloc.state.isAutoplayEnabled, isFalse);
        expect(bloc.state.queue.any((t) => t.isAutoplay), isFalse);
      },
    );

    test(
      'playing song from search via PlayerPlayQueue([track]) sets single anchor and populates Up Next with autoplay mix',
      () async {
        const selectedTrack = Track(
          id: 'search-selected-1',
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          duration: '04:22',
          formatBadge: '320k',
          language: 'hindi',
          mood: 'love',
        );

        bloc.add(const PlayerPlayQueue([selectedTrack], initialIndex: 0));
        await pumpEventQueue();

        // Current track is the selected song
        expect(bloc.state.currentTrack?.id, equals('search-selected-1'));
        expect(bloc.state.currentIndex, equals(0));
        expect(bloc.state.queue.first.id, equals('search-selected-1'));

        // Up Next section is populated by autoplay mix, all marked isAutoplay
        final upNext = bloc.state.queue.sublist(1);
        expect(upNext.isNotEmpty, isTrue);
        expect(upNext.every((t) => t.isAutoplay), isTrue);
        // Ensure arbitrary search results below the song are NOT dumped as user-queued
        final nonAutoplayUpcoming = upNext.where((t) => !t.isAutoplay);
        expect(nonAutoplayUpcoming.isEmpty, isTrue);
      },
    );

    test(
      'playing a new track from search completely replaces previous queue and regenerates autoplay',
      () async {
        // First queue with 5 tracks
        final oldTracks = List.generate(
          5,
          (i) => Track(
            id: 'old-track-$i',
            title: 'Old Track $i',
            artist: 'Old Artist',
            duration: '03:00',
            formatBadge: '320k',
          ),
        );
        bloc.add(PlayerPlayQueue(oldTracks, initialIndex: 0));
        await pumpEventQueue();

        expect(bloc.state.queue.length >= 5, isTrue);

        // Now play a new song selected from global search
        const newTrack = Track(
          id: 'new-search-pick',
          title: 'Kesariya',
          artist: 'Arijit Singh',
          duration: '04:28',
          formatBadge: '320k',
          language: 'hindi',
          mood: 'love',
        );
        bloc.add(const PlayerPlayQueue([newTrack], initialIndex: 0));
        await pumpEventQueue();

        // Old tracks must not be in the queue anymore
        for (final old in oldTracks) {
          expect(bloc.state.queue.any((t) => t.id == old.id), isFalse);
        }

        // New track is current and upcoming tracks are fresh autoplay tracks
        expect(bloc.state.currentTrack?.id, equals('new-search-pick'));
        final upNext = bloc.state.queue.sublist(1);
        expect(upNext.isNotEmpty, isTrue);
        expect(upNext.every((t) => t.isAutoplay), isTrue);
      },
    );
  });
}
