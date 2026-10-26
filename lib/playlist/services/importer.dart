import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../models/models.dart';
import '../../repositories/playlist_repository.dart';
import '../../services/remote_music_service.dart';
import '../../theme/theme.dart';

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => message;
}

class ParseException implements Exception {
  final String message;
  const ParseException(this.message);

  @override
  String toString() => message;
}

class PlaylistTrack {
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final String coverUrl;

  const PlaylistTrack({
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.coverUrl,
  });

  String get formattedDuration {
    if (durationMs <= 0) return '--:--';
    final totalSeconds = durationMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class SpotifyPlaylistService {
  final http.Client _client;
  String? lastPlaylistTitle;

  SpotifyPlaylistService({http.Client? client})
      : _client = client ?? http.Client();

  static String? extractPlaylistId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    if (RegExp(r'^[a-zA-Z0-9]{22}$').hasMatch(trimmed)) {
      return trimmed;
    }

    if (trimmed.startsWith('spotify:playlist:')) {
      final parts = trimmed.split(':');
      if (parts.length >= 3 && RegExp(r'^[a-zA-Z0-9]{22}$').hasMatch(parts[2])) {
        return parts[2];
      }
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    if (uri.hasAuthority &&
        !uri.host.endsWith('spotify.com') &&
        !uri.host.endsWith('spotify.link')) {
      return null;
    }

    final pathSegments = uri.pathSegments;
    final playlistIdx = pathSegments.indexOf('playlist');
    if (playlistIdx != -1 && pathSegments.length > playlistIdx + 1) {
      final id = pathSegments[playlistIdx + 1];
      if (RegExp(r'^[a-zA-Z0-9]{22}$').hasMatch(id)) return id;
    }

    return null;
  }

  Future<List<PlaylistTrack>> importSpotifyPlaylist(String urlOrId) async {
    final playlistId = extractPlaylistId(urlOrId);
    if (playlistId == null) {
      throw const FormatException(
        'Invalid Spotify playlist link. Please enter a valid Spotify playlist URL or ID.',
      );
    }

    final embedUrl =
        Uri.parse('https://open.spotify.com/embed/playlist/$playlistId');
    late final http.Response response;
    try {
      response = await _client.get(
        embedUrl,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );
    } catch (e) {
      throw NetworkException('Network error while contacting Spotify: $e');
    }

    if (response.statusCode != 200) {
      throw NetworkException(
        'Failed to load Spotify playlist (HTTP ${response.statusCode}).',
      );
    }

    final match = RegExp(
      r'<script\s+id="__NEXT_DATA__"\s+type="application/json">\s*(\{.+?\})\s*</script>',
      dotAll: true,
    ).firstMatch(response.body);

    if (match == null || match.groupCount < 1) {
      throw const ParseException('Could not parse Spotify playlist data.');
    }

    try {
      final data = jsonDecode(match.group(1)!) as Map<String, dynamic>;
      final props = data['props'] as Map<String, dynamic>? ?? {};
      final pageProps = props['pageProps'] as Map<String, dynamic>? ?? {};
      final state = pageProps['state'] as Map<String, dynamic>? ?? {};
      final stateData = state['data'] as Map<String, dynamic>? ?? {};
      final entity = stateData['entity'] as Map<String, dynamic>? ?? {};

      lastPlaylistTitle =
          entity['title']?.toString() ?? entity['name']?.toString();

      final coverArt = entity['coverArt'] as Map<String, dynamic>?;
      final sources = coverArt?['sources'] as List<dynamic>?;
      String playlistCover = '';
      if (sources != null && sources.isNotEmpty) {
        playlistCover = sources.last['url']?.toString() ?? '';
      }

      final rawTracks = entity['trackList'] as List<dynamic>? ?? [];
      final List<PlaylistTrack> tracks = [];

      for (final item in rawTracks) {
        if (item is! Map<String, dynamic>) continue;
        final title = item['title']?.toString() ?? '';
        if (title.isEmpty) continue;

        final artist = item['subtitle']?.toString() ?? 'Unknown Artist';
        final durationMs =
            int.tryParse(item['duration']?.toString() ?? '') ?? 0;
        final album =
            item['albumName']?.toString() ?? lastPlaylistTitle ?? 'Spotify';

        tracks.add(
          PlaylistTrack(
            title: title,
            artist: artist,
            album: album,
            durationMs: durationMs,
            coverUrl: playlistCover,
          ),
        );
      }

      if (tracks.isEmpty) {
        throw const ParseException(
          'No playable tracks found. Ensure the Spotify playlist is set to Public.',
        );
      }

      return tracks;
    } catch (e) {
      if (e is ParseException) rethrow;
      throw ParseException('Failed to extract tracks from Spotify: $e');
    }
  }
}


enum ImportPlatform { spotify, youtube }

enum _TrackFilter { all, matched, unmatched }

class SpotifyImportScreen extends StatefulWidget {
  final ImportPlatform initialPlatform;

  const SpotifyImportScreen({
    super.key,
    this.initialPlatform = ImportPlatform.spotify,
  });

  @override
  State<SpotifyImportScreen> createState() => _SpotifyImportScreenState();
}

class _SpotifyImportScreenState extends State<SpotifyImportScreen> {
  static const Color _spotifyGreen = Color(0xFF1DB954);
  static const Color _youtubeRed = Color(0xFFFF0033);
  static const int _batchConcurrency = 3;
  static const int _minMatchScore = 45;

  static const List<String> _variantKeywords = [
    'lofi',
    'lo-fi',
    'slowed',
    'reverb',
    'karaoke',
    'instrumental',
    '8d',
    'ringtone',
    'cover',
    'mashup',
    'sped up',
  ];

  final _urlController = TextEditingController();
  late final TextEditingController _playlistNameController;
  final _spotifyService = SpotifyPlaylistService();
  final _youtubeService = _YouTubePlaylistImporter();
  final _musicService = RemoteMusicService();

  late ImportPlatform _platform;
  List<PlaylistTrack> _tracks = [];
  final Set<int> _selectedIndices = {};
  final Map<int, Song?> _matchedSongs = {};
  final Set<int> _syncedIndices = {};

  bool _isLoading = false;
  bool _isSaving = false;
  bool _cancelRequested = false;
  bool _isSaved = false;
  String? _createdPlaylistId;
  String? _error;
  int _matchProgress = 0;
  _TrackFilter _activeFilter = _TrackFilter.all;

  @override
  void initState() {
    super.initState();
    _platform = widget.initialPlatform;
    _playlistNameController = TextEditingController(
      text: _defaultPlaylistName(_platform),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _playlistNameController.dispose();
    super.dispose();
  }

  Color get _brandColor =>
      _platform == ImportPlatform.spotify ? _spotifyGreen : _youtubeRed;

  String get _platformLabel =>
      _platform == ImportPlatform.spotify ? 'Spotify' : 'YouTube';

  String _defaultPlaylistName(ImportPlatform platform) =>
      platform == ImportPlatform.spotify ? 'Spotify Import' : 'YouTube Import';

  int get _matchedCount =>
      _matchedSongs.values.where((song) => song != null).length;

  int get _unmatchedCount =>
      _matchedSongs.entries.where((e) => e.value == null).length;

  List<int> get _visibleIndices {
    final indices = List<int>.generate(_tracks.length, (i) => i);
    switch (_activeFilter) {
      case _TrackFilter.all:
        return indices;
      case _TrackFilter.matched:
        return indices.where((i) => _matchedSongs[i] != null).toList();
      case _TrackFilter.unmatched:
        return indices
            .where(
              (i) => _matchedSongs.containsKey(i) && _matchedSongs[i] == null,
            )
            .toList();
    }
  }

  void _switchPlatform(ImportPlatform nextPlatform) {
    if (_platform == nextPlatform || _isLoading || _isSaving) return;
    final prevDefault = _defaultPlaylistName(_platform);
    setState(() {
      _platform = nextPlatform;
      _error = null;
      if (_playlistNameController.text.trim().isEmpty ||
          _playlistNameController.text.trim() == prevDefault) {
        _playlistNameController.text = _defaultPlaylistName(nextPlatform);
      }
    });
  }

  void _autoDetectPlatformFromUrl(String rawUrl) {
    final lower = rawUrl.toLowerCase();
    if (lower.contains('youtube.com') ||
        lower.contains('youtu.be') ||
        lower.contains('music.youtube.com') ||
        rawUrl.startsWith('PL') ||
        rawUrl.startsWith('OLAK5uy_')) {
      _switchPlatform(ImportPlatform.youtube);
    } else if (lower.contains('spotify.com') || lower.startsWith('spotify:')) {
      _switchPlatform(ImportPlatform.spotify);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;

    _autoDetectPlatformFromUrl(text);
    setState(() {
      _urlController.text = text;
    });

    final lower = text.toLowerCase();
    if (lower.contains('spotify.com') ||
        lower.startsWith('spotify:') ||
        lower.contains('youtube.com') ||
        lower.contains('youtu.be')) {
      _importPlaylist();
    }
  }

  Future<void> _importPlaylist() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    _autoDetectPlatformFromUrl(url);
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
      _tracks = [];
      _selectedIndices.clear();
      _matchedSongs.clear();
      _syncedIndices.clear();
      _isSaved = false;
      _createdPlaylistId = null;
      _matchProgress = 0;
      _activeFilter = _TrackFilter.all;
    });

    try {
      final tracks = _platform == ImportPlatform.spotify
          ? await _spotifyService.importSpotifyPlaylist(url)
          : await _youtubeService.importYouTubePlaylist(url);

      final fetchedTitle = _platform == ImportPlatform.spotify
          ? _spotifyService.lastPlaylistTitle
          : _youtubeService.lastPlaylistTitle;

      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _selectedIndices.addAll(List.generate(tracks.length, (i) => i));
        _isLoading = false;
        if (fetchedTitle != null &&
            fetchedTitle.trim().isNotEmpty &&
            (_playlistNameController.text.trim().isEmpty ||
                _playlistNameController.text.trim() ==
                    _defaultPlaylistName(_platform))) {
          _playlistNameController.text = fetchedTitle.trim();
        }
      });
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } on ParseException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to fetch $_platformLabel playlist: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToSangeet({bool retryUnmatchedOnly = false}) async {
    if (_tracks.isEmpty || _isSaving) return;

    final targetIndices = retryUnmatchedOnly
        ? _selectedIndices
              .where(
                (i) => _matchedSongs.containsKey(i) && _matchedSongs[i] == null,
              )
              .toList()
        : (_selectedIndices.toList()..sort());

    if (targetIndices.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
      _cancelRequested = false;
      _error = null;
      _matchProgress = 0;
    });

    try {
      String? playlistId = _createdPlaylistId;
      final playlistTitle = _playlistNameController.text.trim().isEmpty
          ? _defaultPlaylistName(_platform)
          : _playlistNameController.text.trim();

      if (playlistId == null) {
        final firstCover = _tracks
            .firstWhere(
              (t) => t.coverUrl.isNotEmpty,
              orElse: () => _tracks.first,
            )
            .coverUrl;

        final playlist = PlaylistRepository.instance.createPlaylist(
          name: playlistTitle,
          description:
              'Imported from $_platformLabel (${_tracks.length} tracks)',
          coverUrl: firstCover.isNotEmpty ? firstCover : null,
          telemetryBadge: _platform == ImportPlatform.spotify
              ? 'SPOTIFY IMPORT'
              : 'YT IMPORT',
        );

        playlistId = playlist.id;
        _createdPlaylistId = playlistId;
      }

      int newlyMatched = 0;

      for (
        int start = 0;
        start < targetIndices.length;
        start += _batchConcurrency
      ) {
        if (_cancelRequested || !mounted) break;

        final end = min(start + _batchConcurrency, targetIndices.length);
        final batch = targetIndices.sublist(start, end);

        final batchResults = await Future.wait(
          batch.map((index) => _searchAndMatchTrack(_tracks[index])),
        );

        for (int j = 0; j < batch.length; j++) {
          if (_cancelRequested || !mounted) break;
          final trackIndex = batch[j];
          final matchedSong = batchResults[j];
          _matchedSongs[trackIndex] = matchedSong;

          if (matchedSong != null && !_syncedIndices.contains(trackIndex)) {
            PlaylistRepository.instance.addTrackToPlaylist(
              playlistId,
              matchedSong.toTrack(),
            );
            _syncedIndices.add(trackIndex);
            newlyMatched++;
          }
        }

        if (!mounted) return;
        setState(() {
          _matchProgress = end;
        });

        if (end < targetIndices.length && !_cancelRequested) {
          await Future.delayed(const Duration(milliseconds: 120));
        }
      }

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isSaved = _syncedIndices.isNotEmpty;
      });

      if (_cancelRequested) {
        _showSnackBar(
          'Import paused ($_matchedCount matched so far)',
          icon: Icons.pause_circle_filled_rounded,
        );
      } else {
        _showSnackBar(
          retryUnmatchedOnly
              ? 'Recovered $newlyMatched additional songs'
              : 'Imported $_matchedCount of ${targetIndices.length} songs to "$playlistTitle"',
          icon: Icons.check_circle_rounded,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error saving playlist: $e';
        _isSaving = false;
      });
    }
  }

  Future<Song?> _searchAndMatchTrack(PlaylistTrack track) async {
    try {
      final cleanTitle = _cleanTitle(track.title);
      final primaryArtist = _extractArtists(track.artist).firstOrNull ?? '';
      final primaryQuery = '$cleanTitle $primaryArtist'.trim();

      var results = await _musicService.searchSongs(primaryQuery);
      var best = _pickBestMatch(results, track);

      if (best == null && cleanTitle.isNotEmpty && cleanTitle != primaryQuery) {
        results = await _musicService.searchSongs(cleanTitle);
        best = _pickBestMatch(results, track);
      }

      return best;
    } catch (_) {
      return null;
    }
  }

  Song? _pickBestMatch(List<Song> results, PlaylistTrack track) {
    if (results.isEmpty) return null;

    final rawTargetTitle = track.title.toLowerCase().trim();
    final cleanTargetTitle = _cleanTitle(track.title).toLowerCase();
    final targetTokens = _tokenize(cleanTargetTitle);
    final targetArtists = _extractArtists(track.artist);

    Song? best;
    int bestScore = -1;

    for (final song in results) {
      int score = 0;
      final rawSongTitle = song.title.toLowerCase().trim();
      final cleanSongTitle = _cleanTitle(song.title).toLowerCase();
      final songTokens = _tokenize(cleanSongTitle);
      final songArtists = _extractArtists(song.artist);

      if (cleanSongTitle == cleanTargetTitle ||
          rawSongTitle == rawTargetTitle) {
        score += 90;
      } else if (cleanSongTitle.startsWith(cleanTargetTitle) ||
          cleanTargetTitle.startsWith(cleanSongTitle)) {
        score += 65;
      } else if (cleanSongTitle.contains(cleanTargetTitle) ||
          cleanTargetTitle.contains(cleanSongTitle)) {
        score += 45;
      }

      final tokenOverlap = _diceCoefficient(targetTokens, songTokens);
      score += (tokenOverlap * 40).round();

      int artistMatches = 0;
      for (final tArtist in targetArtists) {
        final matched = songArtists.any(
          (sArtist) => sArtist.contains(tArtist) || tArtist.contains(sArtist),
        );
        if (matched) artistMatches++;
      }

      if (artistMatches > 0) {
        score += 35 + min((artistMatches - 1) * 10, 20);
      } else {
        score -= _platform == ImportPlatform.youtube ? 5 : 15;
      }

      if (track.durationMs > 0 && song.duration.inMilliseconds > 0) {
        final diff = (song.duration.inMilliseconds - track.durationMs).abs();
        if (diff <= 4000) {
          score += 25;
        } else if (diff <= 15000) {
          score += 12;
        } else if (diff > 60000) {
          score -= 20;
        }
      }

      for (final keyword in _variantKeywords) {
        final targetHasVariant = rawTargetTitle.contains(keyword);
        final candidateHasVariant = rawSongTitle.contains(keyword);
        if (!targetHasVariant && candidateHasVariant) {
          score -= 45;
        } else if (targetHasVariant && candidateHasVariant) {
          score += 15;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        best = song;
      }
    }

    return bestScore >= _minMatchScore ? best : null;
  }

  String _cleanTitle(String input) {
    var cleaned = input
        .split('|')
        .first
        .replaceAll(
          RegExp(
            r'\s*[\(\[][^)\]]*(?:feat|ft|from|remaster|version|edit|live|mono|stereo|official|lyrical|lyrics|video|audio|full\s+song|4k|hd)[^)\]]*[\)\]]',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\s*-\s*(?:remastered|from\s+.*|radio\s+edit|original.*|bonus.*|official.*|lyrical.*|full\s+video.*).*$',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? input.trim() : cleaned;
  }

  Set<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((w) => w.trim())
        .where((w) => w.length > 1)
        .toSet();
  }

  List<String> _extractArtists(String artistString) {
    return artistString
        .toLowerCase()
        .replaceAll(RegExp(r'\s*-\s*topic$'), '')
        .split(RegExp(r'\s*(?:,|&|/|\bfeat\.?|\bft\.?|\bx\b)\s*'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  double _diceCoefficient(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final intersection = a.intersection(b).length;
    return (2.0 * intersection) / (a.length + b.length);
  }

  Future<void> _openManualMatchSheet(int index) async {
    final track = _tracks[index];
    final initialQuery =
        '${_cleanTitle(track.title)} ${_extractArtists(track.artist).firstOrNull ?? ''}'
            .trim();

    final selectedSong = await showModalBottomSheet<Song>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualMatchSheet(
        track: track,
        initialQuery: initialQuery,
        currentMatch: _matchedSongs[index],
        musicService: _musicService,
        accentColor: _brandColor,
      ),
    );

    if (selectedSong != null && mounted) {
      final hadPreviousSync = _syncedIndices.contains(index);
      setState(() {
        _matchedSongs[index] = selectedSong;
        _selectedIndices.add(index);
      });

      if (_createdPlaylistId != null && !hadPreviousSync) {
        PlaylistRepository.instance.addTrackToPlaylist(
          _createdPlaylistId!,
          selectedSong.toTrack(),
        );
        if (!mounted) return;
        setState(() {
          _syncedIndices.add(index);
          _isSaved = true;
        });
        _showSnackBar(
          'Added "${selectedSong.title}" to playlist',
          icon: Icons.check_circle_rounded,
        );
      }
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIndices.length == _tracks.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices.addAll(List.generate(_tracks.length, (i) => i));
      }
    });
  }

  void _showSnackBar(String message, {IconData icon = Icons.info_outline_rounded}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(milliseconds: 2600),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.secondaryAccent.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: AppColors.secondaryAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: AppTypography.bodySm(color: AppColors.primaryText).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralCanvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildPlatformSelector(),
            _buildUrlInput(),
            if (_tracks.isNotEmpty && !_isLoading) _buildPlaylistConfigBar(),
            if (_error != null) _buildErrorBanner(),
            if (_isLoading) _buildLoadingIndicator(),
            if (_isSaving) _buildSaveProgress(),
            if (_tracks.isNotEmpty && !_isLoading)
              Expanded(child: _buildTrackList()),
            if (_tracks.isNotEmpty && !_isLoading && !_isSaving)
              _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primaryText,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CURATION BRIDGE',
                  style: AppTypography.labelSm(
                    color: AppColors.secondaryAccent,
                  ).copyWith(
                    letterSpacing: 2.0,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Import Playlist',
                  style: AppTypography.headlineLgMobile(
                    color: AppColors.primaryText,
                  ).copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _brandColor.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _platform == ImportPlatform.spotify
                      ? Icons.music_note_rounded
                      : Icons.play_circle_fill_rounded,
                  color: _brandColor,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  _platformLabel.toUpperCase(),
                  style: AppTypography.labelSm(
                    color: _brandColor,
                  ).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildPlatformOption(
                platform: ImportPlatform.spotify,
                label: 'Spotify',
                icon: Icons.music_note_rounded,
                activeColor: _spotifyGreen,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPlatformOption(
                platform: ImportPlatform.youtube,
                label: 'YouTube Music',
                icon: Icons.play_circle_fill_rounded,
                activeColor: _youtubeRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformOption({
    required ImportPlatform platform,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _platform == platform;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        _switchPlatform(platform);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceContainerHighest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? activeColor
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppTypography.labelMd(
                color: isSelected
                    ? AppColors.primaryText
                    : AppColors.onSurfaceVariant,
              ).copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlInput() {
    final hasText = _urlController.text.isNotEmpty;
    final hint = _platform == ImportPlatform.spotify
        ? 'Paste Spotify playlist URL or ID...'
        : 'Paste YouTube playlist URL or ID...';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: TextField(
                controller: _urlController,
                style: AppTypography.bodyMd(color: AppColors.primaryText),
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _importPlaylist(),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(
                    fontSize: 13.5,
                  ),
                  prefixIcon: const Icon(
                    Icons.link_rounded,
                    color: AppColors.secondaryAccent,
                    size: 20,
                  ),
                  suffixIcon: hasText
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.onSurfaceVariant,
                            size: 18,
                          ),
                          onPressed: () {
                            _urlController.clear();
                            setState(() {});
                          },
                        )
                      : IconButton(
                          tooltip: 'Paste from clipboard',
                          icon: const Icon(
                            Icons.content_paste_rounded,
                            color: AppColors.secondaryAccent,
                            size: 18,
                          ),
                          onPressed: _pasteFromClipboard,
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (val) {
                  _autoDetectPlatformFromUrl(val);
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isLoading || _isSaving ? null : _importPlaylist,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondaryAccent.withValues(alpha: 0.85),
                    AppColors.secondaryAccent,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryAccent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.neutralCanvas,
                        ),
                      )
                    : Text(
                        'FETCH',
                        style: AppTypography.labelSm(
                          color: AppColors.neutralCanvas,
                        ).copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistConfigBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.queue_music_rounded,
              color: AppColors.secondaryAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _playlistNameController,
                enabled: !_isSaving && _createdPlaylistId == null,
                style: AppTypography.bodyMd(color: AppColors.primaryText).copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: 'DESTINATION PLAYLIST',
                  labelStyle: AppTypography.labelSm(
                    color: AppColors.secondaryAccent,
                  ).copyWith(
                    fontSize: 9.5,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _error!,
                style: AppTypography.bodySm(color: AppColors.error).copyWith(
                  fontSize: 12.5,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _error = null),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.error,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.secondaryAccent,
                strokeWidth: 2.2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'PARSING $_platformLabel STREAM...',
              style: AppTypography.labelSm(color: AppColors.secondaryAccent).copyWith(
                letterSpacing: 1.8,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Resolving track titles, durations, and metadata',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveProgress() {
    final totalToProcess = _selectedIndices.isEmpty
        ? _tracks.length
        : _selectedIndices.length;
    final progress = totalToProcess > 0
        ? (_matchProgress / totalToProcess).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: AppColors.secondaryAccent,
                    strokeWidth: 1.8,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'MATCHING AUDIO MASTERS: $_matchProgress / $totalToProcess ($_matchedCount matched)',
                    style: AppTypography.labelSm(color: AppColors.primaryText).copyWith(
                      fontSize: 10.5,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _cancelRequested = true),
                  child: Text(
                    'PAUSE',
                    style: AppTypography.labelSm(color: AppColors.error).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.secondaryAccent,
                ),
                minHeight: 3.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackList() {
    final visible = _visibleIndices;
    final hasProcessedAny = _matchedSongs.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
          child: Row(
            children: [
              GestureDetector(
                onTap: _isSaving ? null : _toggleSelectAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedIndices.length == _tracks.length
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: AppColors.secondaryAccent,
                      size: 19,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_selectedIndices.length}/${_tracks.length} SELECTED',
                      style: AppTypography.labelSm(color: AppColors.primaryText).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (hasProcessedAny) ...[
                _buildFilterChip(
                  label: 'All (${_tracks.length})',
                  filter: _TrackFilter.all,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: 'Matched ($_matchedCount)',
                  filter: _TrackFilter.matched,
                ),
                if (_unmatchedCount > 0) ...[
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'Missing ($_unmatchedCount)',
                    filter: _TrackFilter.unmatched,
                  ),
                ],
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: visible.length,
            itemBuilder: (context, idx) {
              final index = visible[idx];
              final track = _tracks[index];
              final matched = _matchedSongs[index];
              final wasProcessed = _matchedSongs.containsKey(index);
              final isSelected = _selectedIndices.contains(index);

              return ListTile(
                onTap: _isSaving
                    ? null
                    : () {
                        if (wasProcessed) {
                          _openManualMatchSheet(index);
                        } else {
                          setState(() {
                            if (isSelected) {
                              _selectedIndices.remove(index);
                            } else {
                              _selectedIndices.add(index);
                            }
                          });
                        }
                      },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 3,
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: track.coverUrl.isNotEmpty
                      ? Image.network(
                          track.coverUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _placeholderArt(),
                        )
                      : _placeholderArt(),
                ),
                title: Text(
                  track.title,
                  style: AppTypography.bodyMd(
                    color: isSelected ? AppColors.primaryText : AppColors.outline,
                  ).copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${track.artist} • ${track.album}',
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (wasProcessed && matched != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'MATCHED: ${matched.title}',
                          style: AppTypography.labelSm(
                            color: AppColors.secondaryAccent,
                          ).copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (wasProcessed && matched == null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(alpha: 0.4),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          'TAP TO MANUALLY MATCH',
                          style: AppTypography.labelSm(
                            color: AppColors.onSurfaceVariant,
                          ).copyWith(
                            fontSize: 9.5,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (wasProcessed)
                      IconButton(
                        tooltip: 'Fix match',
                        icon: Icon(
                          matched != null
                              ? Icons.check_circle_rounded
                              : Icons.tune_rounded,
                          color: matched != null
                              ? AppColors.secondaryAccent
                              : AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () => _openManualMatchSheet(index),
                      )
                    else ...[
                      Text(
                        track.formattedDuration,
                        style: AppTypography.labelSm(color: AppColors.outline).copyWith(
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? AppColors.secondaryAccent
                            : AppColors.outlineVariant.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required _TrackFilter filter,
  }) {
    final isSelected = _activeFilter == filter;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _activeFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceContainerHighest
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryAccent.withValues(alpha: 0.5)
                : AppColors.outlineVariant.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSm(
            color: isSelected
                ? AppColors.secondaryAccent
                : AppColors.onSurfaceVariant,
          ).copyWith(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _placeholderArt() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
          width: 0.6,
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: AppColors.outline,
        size: 22,
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasUnmatched = _unmatchedCount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_isSaved && hasUnmatched) ...[
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _saveToSangeet(retryUnmatchedOnly: true),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text('RETRY MISSING ($_unmatchedCount)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondaryAccent,
                    side: BorderSide(
                      color: AppColors.secondaryAccent.withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppTypography.labelSm(
                      color: AppColors.secondaryAccent,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaved || _isSaving || _selectedIndices.isEmpty
                    ? null
                    : () => _saveToSangeet(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaved
                      ? AppColors.surfaceContainerHighest
                      : AppColors.secondary,
                  foregroundColor: _isSaved
                      ? AppColors.secondaryAccent
                      : AppColors.onSecondary,
                  disabledBackgroundColor:
                      AppColors.surfaceContainerHighest.withValues(alpha: 0.4),
                  disabledForegroundColor: AppColors.outline,
                  elevation: _isSaved ? 0 : 4,
                  shadowColor: AppColors.secondaryAccent.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: _isSaved
                        ? BorderSide(
                            color: AppColors.secondaryAccent.withValues(alpha: 0.4),
                            width: 0.8,
                          )
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isSaved
                          ? Icons.check_circle_rounded
                          : Icons.download_done_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isSaved
                          ? 'IMPORTED ($_matchedCount/${_selectedIndices.length})'
                          : 'SAVE TO SANGEET (${_selectedIndices.length})',
                      style: AppTypography.labelMd(
                        color: _isSaved
                            ? AppColors.secondaryAccent
                            : AppColors.onSecondary,
                      ).copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualMatchSheet extends StatefulWidget {
  final PlaylistTrack track;
  final String initialQuery;
  final Song? currentMatch;
  final RemoteMusicService musicService;
  final Color accentColor;

  const _ManualMatchSheet({
    required this.track,
    required this.initialQuery,
    required this.currentMatch,
    required this.musicService,
    required this.accentColor,
  });

  @override
  State<_ManualMatchSheet> createState() => _ManualMatchSheetState();
}

class _ManualMatchSheetState extends State<_ManualMatchSheet> {
  late final TextEditingController _searchController;
  List<Song> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _runSearch(widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await widget.musicService.searchSongs(query.trim());
      if (!mounted) return;
      setState(() {
        _results = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.70,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'MANUAL MATCH RESOLUTION',
                  style: AppTypography.labelSm(
                    color: AppColors.secondaryAccent,
                  ).copyWith(
                    letterSpacing: 2.0,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Match for "${widget.track.title}"',
                  style: AppTypography.headlineMd(
                    color: AppColors.primaryText,
                  ).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.track.artist,
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTypography.bodyMd(color: AppColors.primaryText),
                    textInputAction: TextInputAction.search,
                    onSubmitted: _runSearch,
                    decoration: InputDecoration(
                      hintText: 'Search Saavn manually...',
                      hintStyle: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.secondaryAccent,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.secondaryAccent,
                          size: 20,
                        ),
                        onPressed: () => _runSearch(_searchController.text),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.secondaryAccent,
                            strokeWidth: 2,
                          ),
                        )
                      : _results.isEmpty
                      ? Center(
                          child: Text(
                            'No results found on Saavn',
                            style: AppTypography.bodySm(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _results.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: AppColors.outlineVariant.withValues(alpha: 0.12),
                          ),
                          itemBuilder: (context, i) {
                            final song = _results[i];
                            final isCurrent =
                                widget.currentMatch?.id == song.id;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: song.coverUrl.isNotEmpty
                                    ? Image.network(
                                        song.coverUrl,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 44,
                                        height: 44,
                                        color: AppColors.surfaceContainerHigh,
                                        child: const Icon(
                                          Icons.music_note_rounded,
                                          color: AppColors.outline,
                                        ),
                                      ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMd(
                                  color: AppColors.primaryText,
                                ).copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySm(
                                  color: AppColors.onSurfaceVariant,
                                ).copyWith(fontSize: 12),
                              ),
                              trailing: isCurrent
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.secondaryAccent,
                                      size: 20,
                                    )
                                  : const Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: AppColors.outline,
                                      size: 20,
                                    ),
                              onTap: () => Navigator.pop(context, song),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _YouTubePlaylistImporter {
  final http.Client _client;
  String? lastPlaylistTitle;

  _YouTubePlaylistImporter({http.Client? client})
    : _client = client ?? http.Client();

  static String? extractPlaylistId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    if (RegExp(
      r'^(PL|OLAK5uy_|RDCLAK5uy_|UU|FL|LL)[a-zA-Z0-9_-]{10,}$',
    ).hasMatch(trimmed)) {
      return trimmed;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    final isYouTube =
        host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('music.youtube.com');

    if (!isYouTube) return null;

    final listParam = uri.queryParameters['list'];
    if (listParam != null && listParam.trim().isNotEmpty) {
      return listParam.trim();
    }

    return null;
  }

  Future<List<PlaylistTrack>> importYouTubePlaylist(String urlOrId) async {
    final playlistId = extractPlaylistId(urlOrId);
    if (playlistId == null) {
      throw const FormatException(
        'Invalid YouTube playlist link. Make sure the URL contains a "list=" parameter.',
      );
    }

    final url = Uri.parse(
      'https://www.youtube.com/playlist?list=$playlistId&hl=en',
    );

    late final http.Response response;
    try {
      response = await _client.get(
        url,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );
    } catch (e) {
      throw NetworkException('Network error while contacting YouTube: $e');
    }

    if (response.statusCode != 200) {
      throw NetworkException(
        'Failed to load YouTube playlist (HTTP ${response.statusCode}).',
      );
    }

    final jsonMap = _extractYtInitialData(response.body);
    if (jsonMap == null) {
      throw ParseException('Could not parse YouTube playlist data.');
    }

    final title = _extractPlaylistTitle(jsonMap);
    if (title != null && title.trim().isNotEmpty) {
      lastPlaylistTitle = title.trim();
    }

    final tracks = _parseTracksFromInitialData(jsonMap);
    if (tracks.isEmpty) {
      throw const ParseException(
        'No playable tracks found. Ensure the YouTube playlist is set to Public or Unlisted.',
      );
    }

    return tracks;
  }

  String? _extractPlaylistTitle(Map<String, dynamic> data) {
    final header = data['header'] as Map<String, dynamic>?;
    if (header != null) {
      final plHeader =
          header['playlistHeaderRenderer'] as Map<String, dynamic>?;
      if (plHeader != null) {
        final title = _readRunsText(plHeader['title']).isNotEmpty
            ? _readRunsText(plHeader['title'])
            : _readSimpleText(plHeader['title']);
        if (title.isNotEmpty) return title;
      }
    }
    final metadata = data['metadata'] as Map<String, dynamic>?;
    if (metadata != null) {
      final plMeta =
          metadata['playlistMetadataRenderer'] as Map<String, dynamic>?;
      if (plMeta != null && plMeta['title'] != null) {
        return plMeta['title'].toString();
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractYtInitialData(String html) {
    final patterns = [
      RegExp(r'var\s+ytInitialData\s*=\s*(\{.+?\});\s*</script>', dotAll: true),
      RegExp(r'window\["ytInitialData"\]\s*=\s*(\{.+?\});', dotAll: true),
      RegExp(r'ytInitialData\s*=\s*(\{.+?\});', dotAll: true),
    ];

    for (final regex in patterns) {
      final match = regex.firstMatch(html);
      if (match != null && match.groupCount >= 1) {
        try {
          return jsonDecode(match.group(1)!) as Map<String, dynamic>;
        } catch (_) {}
      }
    }
    return null;
  }

  List<PlaylistTrack> _parseTracksFromInitialData(Map<String, dynamic> data) {
    final List<Map<String, dynamic>> videoRenderers = [];
    _collectVideoRenderers(data, videoRenderers);

    final List<PlaylistTrack> tracks = [];
    for (final renderer in videoRenderers) {
      final rawTitle = _readRunsText(renderer['title']);
      if (rawTitle.isEmpty ||
          rawTitle == '[Deleted video]' ||
          rawTitle == '[Private video]') {
        continue;
      }

      final rawChannel = _readRunsText(renderer['shortBylineText']).isNotEmpty
          ? _readRunsText(renderer['shortBylineText'])
          : _readRunsText(renderer['longBylineText']);

      final parsedMeta = _normalizeYouTubeTitleAndArtist(rawTitle, rawChannel);

      final lengthSeconds =
          int.tryParse(renderer['lengthSeconds']?.toString() ?? '') ??
          _parseDurationText(_readSimpleText(renderer['lengthText']));

      final thumbnails =
          renderer['thumbnail']?['thumbnails'] as List<dynamic>? ?? const [];
      final coverUrl = thumbnails.isNotEmpty
          ? (thumbnails.last['url']?.toString() ?? '')
          : '';

      tracks.add(
        PlaylistTrack(
          title: parsedMeta.$1,
          artist: parsedMeta.$2,
          album: 'YouTube',
          durationMs: lengthSeconds * 1000,
          coverUrl: coverUrl,
        ),
      );
    }

    return tracks;
  }

  void _collectVideoRenderers(
    dynamic node,
    List<Map<String, dynamic>> collected,
  ) {
    if (node is Map<String, dynamic>) {
      if (node.containsKey('playlistVideoRenderer') &&
          node['playlistVideoRenderer'] is Map<String, dynamic>) {
        collected.add(node['playlistVideoRenderer'] as Map<String, dynamic>);
        return;
      }
      for (final value in node.values) {
        _collectVideoRenderers(value, collected);
      }
    } else if (node is List) {
      for (final item in node) {
        _collectVideoRenderers(item, collected);
      }
    }
  }

  (String, String) _normalizeYouTubeTitleAndArtist(
    String rawTitle,
    String rawChannel,
  ) {
    var channel = rawChannel
        .replaceAll(RegExp(r'\s*-\s*Topic$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*Official$', caseSensitive: false), '')
        .trim();

    var cleanedTitle = rawTitle
        .replaceAll(
          RegExp(
            r'\s*[\(\[][^)\]]*(?:official|lyrical|lyrics|video|audio|full\s+song|4k|hd|8k|remaster|mv|visualizer)[^)\]]*[\)\]]',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    if (cleanedTitle.contains('|')) {
      final segments = cleanedTitle
          .split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (segments.isNotEmpty) {
        cleanedTitle = segments.first;
        if (segments.length >= 2 && _isRecordLabelChannel(channel)) {
          channel = segments[1];
        }
      }
    }

    if (cleanedTitle.contains(' - ')) {
      final parts = cleanedTitle
          .split(' - ')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.length == 2) {
        if (_isRecordLabelChannel(channel) ||
            parts[0].toLowerCase() == channel.toLowerCase()) {
          channel = parts[0];
          cleanedTitle = parts[1];
        }
      }
    }

    cleanedTitle = cleanedTitle
        .replaceAll(
          RegExp(
            r'\b(?:full\s+video|official\s+video|lyrical\s+video|video\s+song|audio\s+song)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return (
      cleanedTitle.isEmpty ? rawTitle.trim() : cleanedTitle,
      channel.isEmpty ? 'Unknown Artist' : channel,
    );
  }

  bool _isRecordLabelChannel(String channel) {
    final lower = channel.toLowerCase();
    const labels = [
      't-series',
      'sony music',
      'zee music',
      'yrf',
      'tips official',
      'saregama',
      'speed records',
      'desi melodies',
      'vyrl originals',
      'universal music',
      'warner music',
      'vevo',
      'think music',
      'aditya music',
      'lahari music',
    ];
    return labels.any((l) => lower.contains(l));
  }

  String _readRunsText(dynamic node) {
    if (node is! Map<String, dynamic>) return '';
    if (node['simpleText'] != null) return node['simpleText'].toString();
    final runs = node['runs'] as List<dynamic>?;
    if (runs == null || runs.isEmpty) return '';
    return runs.map((r) => r['text']?.toString() ?? '').join().trim();
  }

  String _readSimpleText(dynamic node) {
    if (node is! Map<String, dynamic>) return '';
    return (node['simpleText'] ?? _readRunsText(node)).toString().trim();
  }

  int _parseDurationText(String text) {
    if (text.isEmpty) return 0;
    final parts = text
        .split(':')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .toList();
    if (parts.length == 2) {
      return parts[0] * 60 + parts[1];
    } else if (parts.length == 3) {
      return parts[0] * 3600 + parts[1] * 60 + parts[2];
    }
    return 0;
  }
}
