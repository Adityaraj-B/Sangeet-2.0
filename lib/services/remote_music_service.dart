import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/song.dart';
import 'music_api_service.dart';

class RemoteMusicService implements MusicApiService {
  final http.Client _client;

  RemoteMusicService({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<List<Song>> getTrending() async {
    final cacheFile =
        File('${Directory.systemTemp.path}/aura_cache_trending_songs.json');
    List<Song>? cachedSongs;
    if (cacheFile.existsSync()) {
      try {
        final content = cacheFile.readAsStringSync();
        if (content.isNotEmpty) {
          cachedSongs = _parseSongs(content);
        }
      } catch (_) {}
    }

    // If disk cache is available, kick off network refresh in the background and return cache immediately!
    if (cachedSongs != null && cachedSongs.isNotEmpty) {
      _refreshTrendingInBackground(cacheFile);
      return cachedSongs;
    }

    // Otherwise, fetch synchronously from network with timeout
    try {
      final uri = Uri.parse(
        '$kBaseUrl$kSearchSongsEndpoint?query=${Uri.encodeQueryComponent(kTrendingQuery)}&limit=$kDefaultLimit',
      );
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        try {
          cacheFile.writeAsString(response.body);
        } catch (_) {}
        return _parseSongs(response.body);
      }
      if (kDebugMode) {
        print(
          'RemoteMusicService.getTrending failed: ${response.statusCode} ${response.body}',
        );
      }
      return [];
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService.getTrending exception: $e\n$st');
      }
      return [];
    }
  }

  void _refreshTrendingInBackground(File cacheFile) {
    Future(() async {
      try {
        final uri = Uri.parse(
          '$kBaseUrl$kSearchSongsEndpoint?query=${Uri.encodeQueryComponent(kTrendingQuery)}&limit=$kDefaultLimit',
        );
        final response =
            await _client.get(uri).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          await cacheFile.writeAsString(response.body);
        }
      } catch (_) {}
    });
  }

  @override
  Future<List<Song>> searchSongs(String query) async {
    try {
      final uri = Uri.parse(
        '$kBaseUrl$kSearchSongsEndpoint?query=${Uri.encodeQueryComponent(query)}&limit=$kDefaultLimit',
      );
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        return _parseSongs(response.body);
      }
      if (kDebugMode) {
        print(
          'RemoteMusicService.searchSongs failed: ${response.statusCode} ${response.body}',
        );
      }
      return [];
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService.searchSongs exception: $e\n$st');
      }
      return [];
    }
  }

  @override
  Future<List<Artist>> searchArtists(String query) async {
    try {
      final uri = Uri.parse(
        '$kBaseUrl$kSearchArtistsEndpoint?query=${Uri.encodeQueryComponent(query)}&limit=$kDefaultLimit',
      );
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        return _parseArtists(response.body);
      }
      if (kDebugMode) {
        print(
          'RemoteMusicService.searchArtists failed: ${response.statusCode} ${response.body}',
        );
      }
      return [];
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService.searchArtists exception: $e\n$st');
      }
      return [];
    }
  }

  @override
  Future<List<Album>> searchAlbums(String query) async {
    try {
      final uri = Uri.parse(
        '$kBaseUrl$kSearchAlbumsEndpoint?query=${Uri.encodeQueryComponent(query)}&limit=$kDefaultLimit',
      );
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        return _parseAlbums(response.body);
      }
      if (kDebugMode) {
        print(
          'RemoteMusicService.searchAlbums failed: ${response.statusCode} ${response.body}',
        );
      }
      return [];
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService.searchAlbums exception: $e\n$st');
      }
      return [];
    }
  }

  @override
  Future<Artist?> getArtistById(
    String id, {
    int songCount = 20,
    int albumCount = 20,
  }) async {
    try {
      final uri = Uri.parse(
        '$kBaseUrl$kArtistsEndpoint?id=${Uri.encodeQueryComponent(id)}&songCount=$songCount&albumCount=$albumCount',
      );
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] != null) {
          return _parseSingleArtist(decoded['data']);
        }
      }
      if (kDebugMode) {
        print(
          'RemoteMusicService.getArtistById failed: ${response.statusCode} ${response.body}',
        );
      }
      return null;
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService.getArtistById exception: $e\n$st');
      }
      return null;
    }
  }

  @override
  Future<List<Song>> getArtistSongs(String id, {int page = 0}) async {
    try {
      final safeId = Uri.encodeComponent(id);
      final uri = Uri.parse(
        '$kBaseUrl$kArtistsEndpoint/$safeId/songs?page=$page&sortBy=popularity&sortOrder=desc',
      );
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        return _parseSongs(response.body);
      }
      if (kDebugMode) {
        print(
          'RemoteMusicService.getArtistSongs failed: ${response.statusCode} ${response.body}',
        );
      }
      return [];
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService.getArtistSongs exception: $e\n$st');
      }
      return [];
    }
  }

  @override
  Future<List<Album>> getArtistAlbums(String id, {int page = 0}) async {
    try {
      final safeId = Uri.encodeComponent(id);
      final uri = Uri.parse(
        '$kBaseUrl$kArtistsEndpoint/$safeId/albums?page=$page&sortBy=popularity&sortOrder=desc',
      );
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        return _parseAlbums(response.body);
      }
      if (kDebugMode) {
        print(
          'RemoteMusicService.getArtistAlbums failed: ${response.statusCode} ${response.body}',
        );
      }
      return [];
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService.getArtistAlbums exception: $e\n$st');
      }
      return [];
    }
  }

  @override
  Future<Song?> getSongById(String id) async {
    try {
      final safeId = Uri.encodeComponent(id);
      final uri = Uri.parse('$kBaseUrl$kSongsEndpoint/$safeId');
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final songs = _parseSongs(response.body);
        return songs.isNotEmpty ? songs.first : null;
      }
      if (kDebugMode) {
        print(
          'RemoteMusicService.getSongById failed: ${response.statusCode} ${response.body}',
        );
      }
      return null;
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService.getSongById exception: $e\n$st');
      }
      return null;
    }
  }

  @override
  Future<List<Song>> getSongSuggestions(String id) async {
    try {
      final safeId = Uri.encodeComponent(id);
      final uri = Uri.parse(
        '$kBaseUrl$kSongsEndpoint/$safeId/suggestions?limit=$kDefaultLimit',
      );
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        return _parseSongs(response.body);
      }
      if (kDebugMode) {
        print(
          'RemoteMusicService.getSongSuggestions failed: ${response.statusCode} ${response.body}',
        );
      }
      return [];
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService.getSongSuggestions exception: $e\n$st');
      }
      return [];
    }
  }

  @override
  Future<List<Song>> getSongsByAlbum(String albumId) async {
    try {
      final uri = Uri.parse(
        '$kBaseUrl$kAlbumsEndpoint?id=${Uri.encodeQueryComponent(albumId)}',
      );
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        return _parseSongs(response.body);
      }
      if (kDebugMode) {
        print(
          'RemoteMusicService.getSongsByAlbum failed: ${response.statusCode} ${response.body}',
        );
      }
      return [];
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService.getSongsByAlbum exception: $e\n$st');
      }
      return [];
    }
  }

  @override
  Future<List<Song>> getSongsByPlaylist(String playlistId) async {
    try {
      final uri = Uri.parse(
        '$kBaseUrl$kPlaylistsEndpoint?id=${Uri.encodeQueryComponent(playlistId)}',
      );
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        return _parseSongs(response.body);
      }
      if (kDebugMode) {
        print(
          'RemoteMusicService.getSongsByPlaylist failed: ${response.statusCode} ${response.body}',
        );
      }
      return [];
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService.getSongsByPlaylist exception: $e\n$st');
      }
      return [];
    }
  }

  @override
  Future<List<Song>> getAllSongs() async {
    return await getTrending();
  }

  @override
  Future<List<Album>> getTrendingAlbums({int limit = 10}) async {
    final cacheFile =
        File('${Directory.systemTemp.path}/aura_cache_trending_albums.json');
    List<Album>? cachedAlbums;
    if (cacheFile.existsSync()) {
      try {
        final content = cacheFile.readAsStringSync();
        if (content.isNotEmpty) {
          cachedAlbums = _parseAlbums(content);
        }
      } catch (_) {}
    }

    // If disk cache is available, kick off network refresh in the background and return cache immediately!
    if (cachedAlbums != null && cachedAlbums.isNotEmpty) {
      _refreshTrendingAlbumsInBackground(cacheFile, limit);
      return cachedAlbums;
    }

    try {
      final uri = Uri.parse(
        '$kBaseUrl$kSearchAlbumsEndpoint?query=${Uri.encodeQueryComponent('trending')}&limit=$limit',
      );
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        try {
          cacheFile.writeAsString(response.body);
        } catch (_) {}
        return _parseAlbums(response.body);
      }
      if (kDebugMode) {
        print(
          'RemoteMusicService.getTrendingAlbums failed: ${response.statusCode} ${response.body}',
        );
      }
      return [];
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService.getTrendingAlbums exception: $e\n$st');
      }
      return [];
    }
  }

  void _refreshTrendingAlbumsInBackground(File cacheFile, int limit) {
    Future(() async {
      try {
        final uri = Uri.parse(
          '$kBaseUrl$kSearchAlbumsEndpoint?query=${Uri.encodeQueryComponent('trending')}&limit=$limit',
        );
        final response =
            await _client.get(uri).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          await cacheFile.writeAsString(response.body);
        }
      } catch (_) {}
    });
  }

  @override
  Future<Album?> getAlbumById(String id) async {
    try {
      final uri = Uri.parse(
        '$kBaseUrl$kAlbumsEndpoint?id=${Uri.encodeQueryComponent(id)}',
      );
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] != null) {
          final data = decoded['data'];
          final songs = _parseSongs(response.body);
          return _parseSingleAlbum(data, songs: songs);
        }
      }
      if (kDebugMode) {
        print(
          'RemoteMusicService.getAlbumById failed: ${response.statusCode} ${response.body}',
        );
      }
      return null;
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService.getAlbumById exception: $e\n$st');
      }
      return null;
    }
  }

  List<Song> _parseSongs(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is! Map) {
        if (decoded is List) {
          return decoded.map((e) => _parseSingleSong(e)).toList();
        }
        return [];
      }

      final dynamic data = decoded['data'];
      if (data is List) {
        return data.map((e) => _parseSingleSong(e)).toList();
      }

      if (data is Map) {
        final dynamic results = data['results'];
        if (results is List) {
          return results.map((e) => _parseSingleSong(e)).toList();
        }

        final dynamic songs = data['songs'];
        if (songs is List) {
          return songs.map((e) => _parseSingleSong(e)).toList();
        }
      }

      return [];
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService._parseSongs error: $e\n$st');
      }
      return [];
    }
  }

  Song _parseSingleSong(dynamic e) {
    if (e is! Map) {
      return const Song(
        id: '',
        title: 'Unknown',
        artist: 'Unknown Artist',
        coverUrl: '',
        duration: Duration.zero,
      );
    }

    final id = (e['id'] ?? '').toString();

    final rawName = e['name'] ?? e['title'];
    final rawTitle = (rawName != null && rawName.toString().trim().isNotEmpty)
        ? rawName.toString().trim()
        : 'Unknown';
    final title = _unescapeHtml(rawTitle);

    String artist = '';
    String artistId = '';
    final primaryArtists = e['primaryArtists'];
    if (primaryArtists != null && primaryArtists.toString().trim().isNotEmpty) {
      artist = primaryArtists.toString().trim();
    } else if (e['artists'] is Map) {
      final dynamic primary = (e['artists'] as Map)['primary'];
      if (primary is List && primary.isNotEmpty) {
        final names = primary
            .whereType<Map>()
            .map((a) => a['name']?.toString().trim())
            .where((name) => name != null && name.isNotEmpty)
            .cast<String>()
            .toList();
        if (names.isNotEmpty) {
          artist = names.join(', ');
        }
      }
    }
    if (artist.isEmpty) {
      artist = 'Unknown Artist';
    }
    artist = _unescapeHtml(artist);

    // Extract artistId if present in artists.primary
    if (e['artists'] is Map) {
      final dynamic primary = (e['artists'] as Map)['primary'];
      if (primary is List && primary.isNotEmpty && primary.first is Map) {
        artistId = (primary.first['id'] ?? '').toString();
      }
    }
    if (artistId.isEmpty) {
      artistId = artist.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    String coverUrl = '';
    final dynamic images = e['image'];
    if (images is List && images.isNotEmpty) {
      final lastImage = images.last;
      if (lastImage is Map) {
        coverUrl = (lastImage['link'] ?? lastImage['url'] ?? '').toString();
      } else if (lastImage is String) {
        coverUrl = lastImage;
      }
    }

    String? streamUrl;
    final dynamic downloads = e['downloadUrl'];
    if (downloads is List && downloads.isNotEmpty) {
      final lastDownload = downloads.last;
      if (lastDownload is Map) {
        final url = (lastDownload['link'] ?? lastDownload['url'] ?? '').toString();
        if (url.isNotEmpty) {
          streamUrl = url;
        }
      } else if (lastDownload is String && lastDownload.isNotEmpty) {
        streamUrl = lastDownload;
      }
    }

    final durationSec = int.tryParse(e['duration']?.toString() ?? '') ?? 0;
    final duration = Duration(seconds: durationSec);

    final language = (e['language'] ?? 'hindi').toString().toLowerCase().trim();

    // Infer mood from title, album, and keywords
    final combinedText = '$title ${e['album'] is Map ? e['album']['name'] : ''}'.toLowerCase();
    String mood = 'melodic';
    if (combinedText.contains('love') ||
        combinedText.contains('ishq') ||
        combinedText.contains('pyaar') ||
        combinedText.contains('dil') ||
        combinedText.contains('mohabbat') ||
        combinedText.contains('romantic')) {
      mood = 'love';
    } else if (combinedText.contains('sad') ||
        combinedText.contains('dard') ||
        combinedText.contains('judaai') ||
        combinedText.contains('alone') ||
        combinedText.contains('broken') ||
        combinedText.contains('alvida')) {
      mood = 'sad';
    } else if (combinedText.contains('dance') ||
        combinedText.contains('party') ||
        combinedText.contains('nakhra') ||
        combinedText.contains('bhangra') ||
        combinedText.contains('dhol') ||
        combinedText.contains('remix')) {
      mood = 'party';
    } else if (combinedText.contains('chalisa') ||
        combinedText.contains('aarti') ||
        combinedText.contains('bhajan') ||
        combinedText.contains('hanuman') ||
        combinedText.contains('krishna') ||
        combinedText.contains('shree')) {
      mood = 'devotional';
    } else if (combinedText.contains('chill') ||
        combinedText.contains('lofi') ||
        combinedText.contains('acoustic') ||
        combinedText.contains('sukoon') ||
        combinedText.contains('unplugged')) {
      mood = 'chill';
    }

    final genres = <String>[];
    if (language.isNotEmpty) genres.add(language);
    if (combinedText.contains('punjabi')) genres.add('punjabi');
    if (combinedText.contains('sufi')) genres.add('sufi');
    if (combinedText.contains('lofi')) genres.add('lofi');
    if (combinedText.contains('acoustic')) genres.add('acoustic');
    if (genres.isEmpty) genres.addAll(['bollywood', 'pop']);

    return Song(
      id: id,
      title: title,
      artist: artist,
      coverUrl: coverUrl,
      duration: duration,
      streamUrl: streamUrl,
      language: language,
      artistId: artistId,
      mood: mood,
      genres: genres,
    );
  }

  String _unescapeHtml(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  List<Album> _parseAlbums(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is! Map) return [];
      final dynamic data = decoded['data'];
      List<dynamic> items = [];
      if (data is List) {
        items = data;
      } else if (data is Map) {
        if (data['results'] is List) {
          items = data['results'] as List;
        } else if (data['albums'] is List) {
          items = data['albums'] as List;
        }
      }
      return items
          .map((e) => _parseSingleAlbum(e))
          .where((a) => a.id.isNotEmpty)
          .toList();
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService._parseAlbums error: $e\n$st');
      }
      return [];
    }
  }

  Album _parseSingleAlbum(dynamic e, {List<Song>? songs}) {
    if (e is! Map) {
      return const Album(
        id: '',
        name: 'Unknown',
        artist: 'Unknown Artist',
        coverUrl: '',
      );
    }
    final id = (e['id'] ?? '').toString();
    final rawName = e['name'] ?? e['title'] ?? 'Unknown Album';
    final name = _unescapeHtml(rawName.toString().trim());

    String artist = '';
    if (e['artists'] is Map) {
      final dynamic primary = (e['artists'] as Map)['primary'];
      if (primary is List && primary.isNotEmpty) {
        final names = primary
            .whereType<Map>()
            .map((a) => a['name']?.toString().trim())
            .where((n) => n != null && n.isNotEmpty)
            .cast<String>()
            .toList();
        if (names.isNotEmpty) {
          artist = names.join(', ');
        }
      }
    }
    if (artist.isEmpty && e['artist'] != null) {
      artist = e['artist'].toString().trim();
    }
    if (artist.isEmpty && e['description'] != null && e['description'].toString().isNotEmpty) {
      artist = e['description'].toString().trim();
    }
    if (artist.isEmpty) {
      artist = 'Various Artists';
    }
    artist = _unescapeHtml(artist);

    final year = (e['year'] ?? '').toString();
    final songCount = (e['songCount'] is int)
        ? e['songCount'] as int
        : int.tryParse(e['songCount']?.toString() ?? '0') ?? 0;
    final language = (e['language'] ?? 'Hindi').toString();
    final url = (e['url'] ?? '').toString();

    String coverUrl = '';
    if (e['image'] is List && (e['image'] as List).isNotEmpty) {
      final images = e['image'] as List;
      final hq = images.firstWhere(
        (img) =>
            img is Map &&
            (img['quality'] == '500x500' || img['quality'] == '500'),
        orElse: () => images.last,
      );
      if (hq is Map && hq['url'] != null) {
        coverUrl = hq['url'].toString();
      }
    }

    return Album(
      id: id,
      name: name,
      artist: artist,
      year: year,
      coverUrl: coverUrl,
      songCount: songCount > 0 ? songCount : (songs?.length ?? 0),
      language: language,
      url: url,
      songs: songs ?? const [],
    );
  }

  List<Artist> _parseArtists(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is! Map) return [];
      final dynamic data = decoded['data'];
      List results = [];
      if (data is Map && data['results'] is List) {
        results = data['results'] as List;
      } else if (data is List) {
        results = data;
      }
      return results.map((e) => _parseSingleArtist(e)).toList();
    } catch (e, st) {
      if (kDebugMode) {
        print('RemoteMusicService._parseArtists error: $e\n$st');
      }
      return [];
    }
  }

  Artist _parseSingleArtist(dynamic e) {
    if (e is! Map) {
      return const Artist(id: '', name: 'Unknown Artist');
    }
    final id = (e['id'] ?? '').toString();
    final rawName = e['name'] ?? e['title'] ?? 'Unknown Artist';
    final name = _unescapeHtml(rawName.toString().trim());
    final role = (e['role'] ?? 'Artist').toString();
    final url = (e['url'] ?? '').toString();
    final dominantLanguage = (e['dominantLanguage'] ?? 'Hindi').toString();
    final isVerified = e['isVerified'] == true;
    final fanCount = e['fanCount']?.toString();
    final followerCount = e['followerCount'] is int
        ? e['followerCount'] as int
        : int.tryParse(e['followerCount']?.toString() ?? '');

    String bio = '';
    if (e['bio'] is List) {
      final bioList = e['bio'] as List;
      if (bioList.isNotEmpty && bioList.first is Map) {
        bio = _unescapeHtml((bioList.first['text'] ?? '').toString());
      }
    } else if (e['bio'] != null) {
      bio = _unescapeHtml(e['bio'].toString());
    }

    String imageUrl = '';
    if (e['image'] is List && (e['image'] as List).isNotEmpty) {
      final images = e['image'] as List;
      final hq = images.firstWhere(
        (img) =>
            img is Map &&
            (img['quality'] == '500x500' || img['quality'] == '500'),
        orElse: () => images.last,
      );
      if (hq is Map && hq['url'] != null) {
        imageUrl = hq['url'].toString();
      }
    }

    List<Song> topSongs = [];
    if (e['topSongs'] is List) {
      topSongs =
          (e['topSongs'] as List).map((s) => _parseSingleSong(s)).toList();
    }

    List<Album> topAlbums = [];
    if (e['topAlbums'] is List) {
      topAlbums =
          (e['topAlbums'] as List).map((a) => _parseSingleAlbum(a)).toList();
    }

    List<Song> singles = [];
    if (e['singles'] is List) {
      singles =
          (e['singles'] as List).map((s) => _parseSingleSong(s)).toList();
    }

    return Artist(
      id: id,
      name: name,
      role: role,
      imageUrl: imageUrl,
      followerCount: followerCount,
      fanCount: fanCount,
      isVerified: isVerified,
      dominantLanguage: dominantLanguage,
      bio: bio,
      url: url,
      topSongs: topSongs,
      topAlbums: topAlbums,
      singles: singles,
    );
  }
}
