import '../exceptions/music_exception.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/song.dart';
import '../services/connectivity_service.dart';
import '../services/music_api_service.dart';
import '../services/remote_music_service.dart';

class MusicRepository implements MusicApiService {
  final MusicApiService _apiService;
  final Map<String, dynamic> _cache = <String, dynamic>{};

  static final MusicRepository instance = MusicRepository(RemoteMusicService());

  MusicRepository([MusicApiService? apiService])
      : _apiService = apiService ?? RemoteMusicService();

  @override
  Future<List<Song>> getTrending() async {
    try {
      const key = 'trending';
      if (_cache.containsKey(key)) {
        return (_cache[key] as List<dynamic>).cast<Song>();
      }
      final songs = await _apiService.getTrending();
      _cache[key] = songs;
      return songs;
    } catch (e, st) {
      ConnectivityService.instance.notifyNetworkError();
      if (e is MusicException) rethrow;
      throw MusicException(
        'Failed to get trending songs',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<Song>> searchSongs(String query) async {
    try {
      return await _apiService.searchSongs(query);
    } catch (e, st) {
      if (e is MusicException) rethrow;
      throw MusicException(
        'Failed to search songs for query: $query',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<Artist>> searchArtists(String query) async {
    try {
      return await _apiService.searchArtists(query);
    } catch (e, st) {
      if (e is MusicException) rethrow;
      throw MusicException(
        'Failed to search artists for query: $query',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<Album>> searchAlbums(String query) async {
    try {
      return await _apiService.searchAlbums(query);
    } catch (e, st) {
      if (e is MusicException) rethrow;
      throw MusicException(
        'Failed to search albums for query: $query',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Song?> getSongById(String id) async {
    try {
      final key = 'song_$id';
      if (_cache.containsKey(key)) {
        return _cache[key] as Song?;
      }
      final song = await _apiService.getSongById(id);
      if (song != null) {
        _cache[key] = song;
      }
      return song;
    } catch (e, st) {
      if (e is MusicException) rethrow;
      throw MusicException(
        'Failed to get song by id: $id',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<Song>> getSongSuggestions(String id) async {
    try {
      final key = 'suggestions_$id';
      if (_cache.containsKey(key)) {
        return (_cache[key] as List<dynamic>).cast<Song>();
      }
      final suggestions = await _apiService.getSongSuggestions(id);
      _cache[key] = suggestions;
      return suggestions;
    } catch (e, st) {
      if (e is MusicException) rethrow;
      throw MusicException(
        'Failed to get song suggestions for id: $id',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<Song>> getSongsByAlbum(String albumId) async {
    try {
      return await _apiService.getSongsByAlbum(albumId);
    } catch (e, st) {
      if (e is MusicException) rethrow;
      throw MusicException(
        'Failed to get songs by album: $albumId',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<Song>> getSongsByPlaylist(String playlistId) async {
    try {
      return await _apiService.getSongsByPlaylist(playlistId);
    } catch (e, st) {
      if (e is MusicException) rethrow;
      throw MusicException(
        'Failed to get songs by playlist: $playlistId',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<Song>> getAllSongs() async {
    try {
      const key = 'all_songs';
      if (_cache.containsKey(key)) {
        return (_cache[key] as List<dynamic>).cast<Song>();
      }
      final songs = await _apiService.getAllSongs();
      _cache[key] = songs;
      return songs;
    } catch (e, st) {
      if (e is MusicException) rethrow;
      throw MusicException(
        'Failed to get all songs',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<Album>> getTrendingAlbums({int limit = 10}) async {
    try {
      final key = 'trending_albums_$limit';
      if (_cache.containsKey(key)) {
        return (_cache[key] as List<dynamic>).cast<Album>();
      }
      final albums = await _apiService.getTrendingAlbums(limit: limit);
      if (albums.isNotEmpty) {
        _cache[key] = albums;
      }
      return albums;
    } catch (e, st) {
      ConnectivityService.instance.notifyNetworkError();
      if (e is MusicException) rethrow;
      throw MusicException(
        'Failed to get trending albums',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Album?> getAlbumById(String id) async {
    try {
      final key = 'album_$id';
      if (_cache.containsKey(key)) {
        return _cache[key] as Album?;
      }
      final album = await _apiService.getAlbumById(id);
      if (album != null) {
        _cache[key] = album;
      }
      return album;
    } catch (e, st) {
      if (e is MusicException) rethrow;
      throw MusicException(
        'Failed to get album by id: $id',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Artist?> getArtistById(
    String id, {
    int songCount = 20,
    int albumCount = 20,
  }) async {
    try {
      final key = 'artist_${id}_${songCount}_$albumCount';
      if (_cache.containsKey(key)) {
        return _cache[key] as Artist?;
      }
      final artist = await _apiService.getArtistById(
        id,
        songCount: songCount,
        albumCount: albumCount,
      );
      if (artist != null) {
        _cache[key] = artist;
      }
      return artist;
    } catch (e, st) {
      if (e is MusicException) rethrow;
      throw MusicException(
        'Failed to get artist by id: $id',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<Song>> getArtistSongs(String id, {int page = 0}) async {
    try {
      final key = 'artist_songs_${id}_$page';
      if (_cache.containsKey(key)) {
        return (_cache[key] as List<dynamic>).cast<Song>();
      }
      final songs = await _apiService.getArtistSongs(id, page: page);
      _cache[key] = songs;
      return songs;
    } catch (e, st) {
      if (e is MusicException) rethrow;
      throw MusicException(
        'Failed to get artist songs: $id',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<Album>> getArtistAlbums(String id, {int page = 0}) async {
    try {
      final key = 'artist_albums_${id}_$page';
      if (_cache.containsKey(key)) {
        return (_cache[key] as List<dynamic>).cast<Album>();
      }
      final albums = await _apiService.getArtistAlbums(id, page: page);
      _cache[key] = albums;
      return albums;
    } catch (e, st) {
      if (e is MusicException) rethrow;
      throw MusicException(
        'Failed to get artist albums: $id',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
