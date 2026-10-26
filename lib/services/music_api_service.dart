import '../models/album.dart';
import '../models/artist.dart';
import '../models/song.dart';

abstract class MusicApiService {
  Future<List<Song>> getTrending();
  Future<List<Song>> searchSongs(String query);
  Future<List<Artist>> searchArtists(String query);
  Future<List<Album>> searchAlbums(String query);
  Future<Song?> getSongById(String id);
  Future<List<Song>> getSongSuggestions(String id);
  Future<List<Song>> getSongsByAlbum(String albumId);
  Future<List<Song>> getSongsByPlaylist(String playlistId);
  Future<List<Song>> getAllSongs();
  Future<List<Album>> getTrendingAlbums({int limit = 10});
  Future<Album?> getAlbumById(String id);
  Future<Artist?> getArtistById(String id, {int songCount = 20, int albumCount = 20});
  Future<List<Song>> getArtistSongs(String id, {int page = 0});
  Future<List<Album>> getArtistAlbums(String id, {int page = 0});
}
