import 'package:flutter_test/flutter_test.dart';
import 'package:sangeet/models/models.dart';
import 'package:sangeet/repositories/favorites_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testTrack1 = Track(
    id: 'track-101',
    title: 'Clair de Lune',
    artist: 'Claude Debussy',
    duration: '05:04',
    formatBadge: 'FLAC 24-BIT',
  );

  const testTrack2 = Track(
    id: 'track-102',
    title: 'Gymnopédie No. 1',
    artist: 'Erik Satie',
    duration: '03:12',
    formatBadge: 'DSD 256',
  );

  final testPlaylist = Playlist(
    id: 'pl-test-01',
    name: 'Acoustic Reverie',
    description: 'High-fidelity acoustic pieces',
    tracks: const [testTrack1],
  );

  setUp(() async {
    await FavoritesRepository.instance.clearLikedSongs();
    await FavoritesRepository.instance.clearLikedPlaylists();
  });

  tearDown(() async {
    await FavoritesRepository.instance.clearLikedSongs();
    await FavoritesRepository.instance.clearLikedPlaylists();
  });

  group('FavoritesRepository - Liked Songs & Device Persistence', () {
    test('Initial state is empty after clear', () {
      expect(FavoritesRepository.instance.likedSongs, isEmpty);
      expect(FavoritesRepository.instance.isSongLiked('track-101'), isFalse);
      expect(FavoritesRepository.instance.likedSongsCount, equals(0));
    });

    test('Liking a song stores it and updates notifiers', () async {
      await FavoritesRepository.instance.likeSong(testTrack1);

      expect(FavoritesRepository.instance.likedSongsCount, equals(1));
      expect(FavoritesRepository.instance.isSongLiked('track-101'), isTrue);
      expect(
        FavoritesRepository.instance.likedSongs.first.title,
        equals('Clair de Lune'),
      );
    });

    test('Toggle like toggles between liked and unliked', () async {
      final nowLiked = await FavoritesRepository.instance.toggleLikeSong(
        testTrack1,
      );
      expect(nowLiked, isTrue);
      expect(FavoritesRepository.instance.isSongLiked('track-101'), isTrue);

      final unliked = await FavoritesRepository.instance.toggleLikeSong(
        testTrack1,
      );
      expect(unliked, isFalse);
      expect(FavoritesRepository.instance.isSongLiked('track-101'), isFalse);
    });

    test('Liking multiple songs places most recent on top', () async {
      await FavoritesRepository.instance.likeSong(testTrack1);
      await FavoritesRepository.instance.likeSong(testTrack2);

      expect(FavoritesRepository.instance.likedSongsCount, equals(2));
      expect(
        FavoritesRepository.instance.likedSongs[0].id,
        equals('track-102'),
      );
      expect(
        FavoritesRepository.instance.likedSongs[1].id,
        equals('track-101'),
      );
    });

    test('Bulk adding songs works and avoids duplicates', () async {
      await FavoritesRepository.instance.likeSong(testTrack1);
      final added = await FavoritesRepository.instance.addSongsToLiked([
        testTrack1,
        testTrack2,
      ]);

      expect(added, equals(1)); // only track-102 was new
      expect(FavoritesRepository.instance.likedSongsCount, equals(2));
    });
  });

  group('FavoritesRepository - Liked Playlists', () {
    test('Liking a playlist stores it and updates status', () async {
      expect(
        FavoritesRepository.instance.isPlaylistLiked('pl-test-01'),
        isFalse,
      );

      await FavoritesRepository.instance.likePlaylist(testPlaylist);
      expect(
        FavoritesRepository.instance.isPlaylistLiked('pl-test-01'),
        isTrue,
      );
      expect(FavoritesRepository.instance.likedPlaylistsCount, equals(1));

      await FavoritesRepository.instance.unlikePlaylist('pl-test-01');
      expect(
        FavoritesRepository.instance.isPlaylistLiked('pl-test-01'),
        isFalse,
      );
      expect(FavoritesRepository.instance.likedPlaylistsCount, equals(0));
    });

    test('Toggle like playlist toggles properly', () async {
      final nowLiked = await FavoritesRepository.instance.toggleLikePlaylist(
        testPlaylist,
      );
      expect(nowLiked, isTrue);
      expect(
        FavoritesRepository.instance.isPlaylistLiked('pl-test-01'),
        isTrue,
      );

      final unliked = await FavoritesRepository.instance.toggleLikePlaylist(
        testPlaylist,
      );
      expect(unliked, isFalse);
      expect(
        FavoritesRepository.instance.isPlaylistLiked('pl-test-01'),
        isFalse,
      );
    });
  });
}
