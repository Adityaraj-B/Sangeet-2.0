import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sangeet/services/remote_music_service.dart';
import 'package:sangeet/repositories/music_repository.dart';
import 'package:sangeet/search/bloc/search_bloc.dart';

void main() {
  group('RemoteMusicService Global Search Test', () {
    const mockJson = '''
{
  "success": true,
  "data": {
    "total": 1,
    "start": 0,
    "results": [
      {
        "id": "BeXBcbVK",
        "name": "Believer",
        "type": "song",
        "duration": 204,
        "artists": {
          "primary": [
            {
              "id": "599452",
              "name": "Imagine Dragons",
              "role": "primary_artists"
            }
          ]
        },
        "image": [
          {"quality": "50x50", "url": "https://c.saavncdn.com/artists/50x50.jpg"},
          {"quality": "500x500", "url": "https://c.saavncdn.com/artists/500x500.jpg"}
        ],
        "downloadUrl": [
          {"quality": "12kbps", "url": "https://aac.saavncdn.com/12.mp4"},
          {"quality": "320kbps", "url": "https://aac.saavncdn.com/320.mp4"}
        ]
      }
    ]
  }
}
''';

    test(
      'parses search results with artist, 500x500 cover and 320kbps stream',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, contains('/api/search/songs'));
          expect(request.url.queryParameters['query'], equals('Believer'));
          return http.Response(mockJson, 200);
        });

        final service = RemoteMusicService(client: mockClient);
        final songs = await service.searchSongs('Believer');

        expect(songs.length, equals(1));
        final song = songs.first;
        expect(song.id, equals('BeXBcbVK'));
        expect(song.title, equals('Believer'));
        expect(song.artist, equals('Imagine Dragons'));
        expect(
          song.coverUrl,
          equals('https://c.saavncdn.com/artists/500x500.jpg'),
        );
        expect(song.streamUrl, equals('https://aac.saavncdn.com/320.mp4'));
        expect(song.duration, equals(const Duration(seconds: 204)));
      },
    );

    test(
      'SearchBloc integration updates searchResults on perform search',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(mockJson, 200);
        });
        final repo = MusicRepository(RemoteMusicService(client: mockClient));
        final bloc = SearchBloc(musicRepository: repo);

        final expectation = expectLater(
          bloc.stream,
          emitsThrough(
            predicate<SearchState>(
              (s) =>
                  !s.isLoading &&
                  s.searchResults.length == 1 &&
                  s.searchResults.first.title == 'Believer',
            ),
          ),
        );

        bloc.add(const SearchPerformSearch('Believer'));
        await expectation;
        await bloc.close();
      },
    );

    test('searchArtists parses artist correctly', () async {
      const mockArtistJson = '''
{
  "success": true,
  "data": {
    "total": 1,
    "results": [
      {
        "id": "459320",
        "name": "Arijit Singh",
        "role": "Singer",
        "image": [
          {"quality": "50x50", "url": "https://c.saavncdn.com/artists/Arijit_50.jpg"},
          {"quality": "500x500", "url": "https://c.saavncdn.com/artists/Arijit_500.jpg"}
        ],
        "url": "https://www.jiosaavn.com/artist/arijit-singh/459320"
      }
    ]
  }
}
''';
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/api/search/artists'));
        return http.Response(mockArtistJson, 200);
      });

      final service = RemoteMusicService(client: mockClient);
      final artists = await service.searchArtists('Arijit');

      expect(artists.length, equals(1));
      expect(artists.first.id, equals('459320'));
      expect(artists.first.name, equals('Arijit Singh'));
      expect(artists.first.role, equals('Singer'));
      expect(
        artists.first.imageUrl,
        equals('https://c.saavncdn.com/artists/Arijit_500.jpg'),
      );
    });

    test('searchAlbums parses album correctly', () async {
      const mockAlbumJson = '''
{
  "success": true,
  "data": {
    "total": 1,
    "results": [
      {
        "id": "1149360",
        "name": "Aashiqui 2",
        "year": "2013",
        "artists": {
          "primary": [
            {"id": "459320", "name": "Mithoon"}
          ]
        },
        "image": [
          {"quality": "500x500", "url": "https://c.saavncdn.com/albums/aashiqui2_500.jpg"}
        ],
        "songCount": 11,
        "language": "Hindi"
      }
    ]
  }
}
''';
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/api/search/albums'));
        return http.Response(mockAlbumJson, 200);
      });

      final service = RemoteMusicService(client: mockClient);
      final albums = await service.searchAlbums('Aashiqui');

      expect(albums.length, equals(1));
      expect(albums.first.id, equals('1149360'));
      expect(albums.first.name, equals('Aashiqui 2'));
      expect(albums.first.year, equals('2013'));
      expect(albums.first.artist, equals('Mithoon'));
      expect(
        albums.first.coverUrl,
        equals('https://c.saavncdn.com/albums/aashiqui2_500.jpg'),
      );
    });

    test(
      'getArtistById parses full artist details with topSongs and topAlbums',
      () async {
        const mockArtistDetailJson = '''
{
  "success": true,
  "data": {
    "id": "459320",
    "name": "Arijit Singh",
    "fanCount": "14.2M",
    "followerCount": 14200000,
    "isVerified": true,
    "dominantLanguage": "Hindi",
    "bio": [
      {"text": "Arijit Singh is a celebrated Indian playback singer."}
    ],
    "image": [
      {"quality": "500x500", "url": "https://c.saavncdn.com/artists/arijit.jpg"}
    ],
    "topSongs": [
      {
        "id": "song-1",
        "name": "Tum Hi Ho",
        "duration": 262,
        "artists": {"primary": [{"name": "Arijit Singh"}]},
        "image": [{"quality": "500x500", "url": "https://c.saavncdn.com/tumhiho.jpg"}],
        "downloadUrl": [{"quality": "320kbps", "url": "https://aac.saavncdn.com/tumhiho.mp4"}]
      }
    ],
    "topAlbums": [
      {
        "id": "album-1",
        "name": "Aashiqui 2",
        "year": "2013",
        "image": [{"quality": "500x500", "url": "https://c.saavncdn.com/aashiqui2.jpg"}]
      }
    ]
  }
}
''';
        final mockClient = MockClient((request) async {
          expect(request.url.path, contains('/api/artists'));
          return http.Response(mockArtistDetailJson, 200);
        });

        final service = RemoteMusicService(client: mockClient);
        final artist = await service.getArtistById('459320');

        expect(artist, isNotNull);
        expect(artist!.id, equals('459320'));
        expect(artist.name, equals('Arijit Singh'));
        expect(artist.isVerified, isTrue);
        expect(artist.followerCount, equals(14200000));
        expect(artist.fanCount, equals('14.2M'));
        expect(artist.bio, contains('Arijit Singh is a celebrated'));
        expect(artist.topSongs.length, equals(1));
        expect(artist.topSongs.first.title, equals('Tum Hi Ho'));
        expect(artist.topAlbums.length, equals(1));
        expect(artist.topAlbums.first.name, equals('Aashiqui 2'));
      },
    );
  });
}
