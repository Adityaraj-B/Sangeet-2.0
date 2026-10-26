import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/track_artwork.dart';
import '../../home/screens/album_detail_screen.dart';
import '../../main_layout/widgets/mini_player_bar.dart';
import '../../models/models.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../repositories/music_repository.dart';
import '../../theme/theme.dart';

class ArtistDetailScreen extends StatefulWidget {
  final Artist artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  late Artist _currentArtist;
  bool _isLoading = true;
  List<Song> _songs = [];
  List<Album> _albums = [];
  List<Song> _singles = [];
  String? _errorMessage;
  bool _bioExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentArtist = widget.artist;
    _songs = widget.artist.topSongs;
    _albums = widget.artist.topAlbums;
    _singles = widget.artist.singles;

    _loadArtistData();
  }

  Future<void> _loadArtistData() async {
    try {
      final repo = MusicRepository.instance;
      Artist? fullArtist;
      String targetId = widget.artist.id.trim();
      final bool isNumericId = RegExp(r'^\d+$').hasMatch(targetId);

      // 1. If we have a numeric Saavn ID, fetch directly
      if (isNumericId) {
        try {
          fullArtist = await repo.getArtistById(
            targetId,
            songCount: 30,
            albumCount: 20,
          );
        } catch (_) {}
      }

      // 2. If no numeric ID or getArtistById returned an artist without songs, search by artist name
      if ((fullArtist == null || fullArtist.topSongs.isEmpty) &&
          widget.artist.name.trim().isNotEmpty) {
        try {
          final searchMatches =
              await repo.searchArtists(widget.artist.name.trim());
          if (searchMatches.isNotEmpty) {
            final bestMatch = searchMatches.first;
            if (bestMatch.id.isNotEmpty && bestMatch.id != targetId) {
              targetId = bestMatch.id;
              final resolvedArtist = await repo.getArtistById(
                bestMatch.id,
                songCount: 30,
                albumCount: 20,
              );
              if (resolvedArtist != null && resolvedArtist.topSongs.isNotEmpty) {
                fullArtist = resolvedArtist;
              } else if (fullArtist == null && resolvedArtist != null) {
                fullArtist = resolvedArtist;
              }
            }
          }
        } catch (_) {}
      }

      // 3. Extract loaded tracks
      List<Song> songs = fullArtist?.topSongs ?? [];
      List<Album> albums = fullArtist?.topAlbums ?? [];
      List<Song> singles = fullArtist?.singles ?? [];

      // 4. If songs are still empty, try getArtistSongs with targetId if numeric
      if (songs.isEmpty && targetId.isNotEmpty && RegExp(r'^\d+$').hasMatch(targetId)) {
        try {
          final fetched = await repo.getArtistSongs(targetId);
          if (fetched.isNotEmpty) songs = fetched;
        } catch (_) {}
      }

      // 5. If albums are still empty, try getArtistAlbums with targetId if numeric
      if (albums.isEmpty && targetId.isNotEmpty && RegExp(r'^\d+$').hasMatch(targetId)) {
        try {
          final fetched = await repo.getArtistAlbums(targetId);
          if (fetched.isNotEmpty) albums = fetched;
        } catch (_) {}
      }

      // 6. Last resort fallback: search songs by artist name
      if (songs.isEmpty && widget.artist.name.trim().isNotEmpty) {
        try {
          final searched = await repo.searchSongs(widget.artist.name.trim());
          if (searched.isNotEmpty) songs = searched;
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        if (fullArtist != null) {
          _currentArtist = fullArtist;
        }
        _songs = songs.isNotEmpty ? songs : _songs;
        _albums = albums.isNotEmpty ? albums : _albums;
        _singles = singles.isNotEmpty ? singles : _singles;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // If we already have some data from the search result, don't show full failure
      if (_songs.isEmpty && _albums.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load artist discography';
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _playAll({bool shuffle = false}) {
    if (_songs.isEmpty) return;
    HapticFeedback.mediumImpact();
    final tracks = _songs.map((s) => s.toTrack()).toList();
    if (shuffle) tracks.shuffle();

    context.read<PlayerBloc>().add(
          PlayerPlayQueue(tracks, initialIndex: 0),
        );
    PlayerScreen.open(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        content: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Text(
            shuffle
                ? 'Shuffling ${_currentArtist.name}...'
                : 'Playing ${_currentArtist.name}...',
            style: AppTypography.bodySm(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _playSong(Song song) {
    HapticFeedback.lightImpact();
    final tracks = _songs.map((s) => s.toTrack()).toList();
    final idx = tracks.indexWhere((t) => t.id == song.id);
    if (idx != -1) {
      context.read<PlayerBloc>().add(
            PlayerPlayQueue(tracks, initialIndex: idx),
          );
    } else {
      context.read<PlayerBloc>().add(PlayerPlayTrack(song.toTrack()));
    }
    PlayerScreen.open(context);
  }

  String _formatFollowerCount(int? count, String? fanCount) {
    if (fanCount != null && fanCount.isNotEmpty) {
      return '$fanCount fans';
    }
    if (count == null || count <= 0) return 'Verified Artist';
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M Monthly Listeners';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K Monthly Listeners';
    }
    return '$count Monthly Listeners';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 90.0;
    final image = _currentArtist.imageUrl;

    return Scaffold(
      backgroundColor: AppColors.neutralCanvas,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Ambient blurred artist aura background
          if (image.isNotEmpty)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Opacity(
                  opacity: 0.30,
                  child: SafeImage(
                    urlOrPath: image,
                    fit: BoxFit.cover,
                    fallback: const SizedBox(),
                  ),
                ),
              ),
            ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── Sliver App Bar ─────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 360,
                pinned: true,
                stretch: true,
                elevation: 0,
                backgroundColor: AppColors.neutralCanvas.withValues(alpha: 0.8),
                surfaceTintColor: Colors.transparent,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Artist Portrait Header
                      SafeImage(
                        urlOrPath: image,
                        fit: BoxFit.cover,
                        fallback: _defaultArtistAvatar(),
                      ),

                      // Top shadow for app bar actions visibility
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),

                      // Gradient fading into canvas at bottom
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 240,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.neutralCanvas.withValues(alpha: 0.65),
                                AppColors.neutralCanvas,
                              ],
                              stops: const [0.0, 0.6, 1.0],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),

                      // Artist Info overlay at bottom of header
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Verified & Language Tag Row
                            Row(
                              children: [
                                if (_currentArtist.isVerified) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.secondary.withValues(alpha: 0.4),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 13,
                                          color: AppColors.secondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'VERIFIED ARTIST',
                                          style: AppTypography.labelSm(
                                            color: AppColors.secondary,
                                          ).copyWith(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    _currentArtist.dominantLanguage.toUpperCase(),
                                    style: AppTypography.labelSm(
                                      color: AppColors.onSurfaceVariant,
                                    ).copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Artist Name
                            Text(
                              _currentArtist.name,
                              style: AppTypography.headlineXlMobile(
                                color: AppColors.primaryText,
                              ).copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Follower / Listener Count
                            Text(
                              _formatFollowerCount(
                                _currentArtist.followerCount,
                                _currentArtist.fanCount,
                              ),
                              style: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.85),
                              ).copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Play / Shuffle Action Header ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      // Big Play Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _songs.isNotEmpty ? () => _playAll() : null,
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            size: 24,
                            color: Colors.black,
                          ),
                          label: Text(
                            'PLAY TOP SONGS',
                            style: AppTypography.labelMd(
                              color: Colors.black,
                            ).copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.black,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Shuffle Button
                      IconButton.filledTonal(
                        onPressed: _songs.isNotEmpty
                            ? () => _playAll(shuffle: true)
                            : null,
                        icon: const Icon(Icons.shuffle_rounded, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          foregroundColor: AppColors.primaryText,
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Top Songs Section Header ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOP TRACKS',
                        style: AppTypography.labelSm(
                          color: AppColors.secondary,
                        ).copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${_songs.length} SONGS',
                        style: AppTypography.labelSm(
                          color: AppColors.onSurfaceVariant,
                        ).copyWith(letterSpacing: 1.0, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Songs List / Loading / Error ─────────────────────────────
              if (_isLoading && _songs.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                )
              else if (_errorMessage != null && _songs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 40,
                            color: AppColors.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: AppTypography.bodySm(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              _loadArtistData();
                            },
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = _songs[index];
                        return _ArtistSongTile(
                          song: song,
                          index: index + 1,
                          onTap: () => _playSong(song),
                        );
                      },
                      childCount: _songs.length,
                    ),
                  ),
                ),

              // ─── Albums / Discography Section ────────────────────────────
              if (_albums.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ALBUMS & RELEASES',
                          style: AppTypography.labelSm(
                            color: AppColors.secondary,
                          ).copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${_albums.length} ALBUMS',
                          style: AppTypography.labelSm(
                            color: AppColors.onSurfaceVariant,
                          ).copyWith(letterSpacing: 1.0, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 215,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _albums.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final album = _albums[index];
                        return _ArtistAlbumCard(
                          album: album,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AlbumDetailScreen(album: album),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],

              // ─── Singles & EPs (if available) ────────────────────────────
              if (_singles.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Text(
                      'SINGLES & FEATURING',
                      style: AppTypography.labelSm(
                        color: AppColors.secondary,
                      ).copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = _singles[index];
                        return _ArtistSongTile(
                          song: song,
                          index: index + 1,
                          onTap: () => _playSong(song),
                        );
                      },
                      childCount: _singles.length,
                    ),
                  ),
                ),
              ],

              // ─── Bio / About Section ─────────────────────────────────────
              if (_currentArtist.bio.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ABOUT THE ARTIST',
                          style: AppTypography.labelSm(
                            color: AppColors.secondary,
                          ).copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => setState(() => _bioExpanded = !_bioExpanded),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.outlineVariant.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentArtist.bio,
                                  style: AppTypography.bodySm(
                                    color: AppColors.onSurfaceVariant,
                                  ).copyWith(
                                    height: 1.5,
                                    fontSize: 13,
                                  ),
                                  maxLines: _bioExpanded ? 50 : 3,
                                  overflow: _bioExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _bioExpanded ? 'Read Less' : 'Read More',
                                  style: AppTypography.labelSm(
                                    color: AppColors.secondary,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Spacer for mini player
              SliverToBoxAdapter(
                child: SizedBox(height: bottomPad),
              ),
            ],
          ),

          // Floating MiniPlayerBar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 8,
            child: const MiniPlayerBar(),
          ),
        ],
      ),
    );
  }

  Widget _defaultArtistAvatar() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: AppColors.outline,
          size: 80,
        ),
      ),
    );
  }
}

// ─── Artist Song Tile ────────────────────────────────────────────────────────

class _ArtistSongTile extends StatefulWidget {
  final Song song;
  final int index;
  final VoidCallback onTap;

  const _ArtistSongTile({
    required this.song,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ArtistSongTile> createState() => _ArtistSongTileState();
}

class _ArtistSongTileState extends State<_ArtistSongTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final currentTrack = context.watch<PlayerBloc>().state.currentTrack;
    final isPlaying = context.watch<PlayerBloc>().state.isPlaying;
    final isCurrent = currentTrack?.id == widget.song.id;

    final mins = widget.song.duration.inMinutes;
    final secs = widget.song.duration.inSeconds % 60;
    final durationStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        if (isCurrent) {
          context.read<PlayerBloc>().add(const PlayerTogglePlayPause());
        } else {
          widget.onTap();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isCurrent
              ? LinearGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isCurrent
              ? null
              : _pressed
                  ? AppColors.surfaceContainer
                  : AppColors.surfaceContainerLow,
          border: Border.all(
            color: isCurrent
                ? AppColors.secondary.withValues(alpha: 0.35)
                : AppColors.outlineVariant.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Track Number or Playing Indicator
            SizedBox(
              width: 26,
              child: isCurrent
                  ? _MiniEqualizer(isPlaying: isPlaying)
                  : Text(
                      widget.index.toString().padLeft(2, '0'),
                      style: AppTypography.labelSm(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                      ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(width: 8),

            // Artwork
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: TrackArtwork(
                albumArt: widget.song.coverUrl,
                trackId: widget.song.id,
                fit: BoxFit.cover,
                fallback: const Icon(
                  Icons.music_note_rounded,
                  color: AppColors.outline,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title and Album / Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.song.title,
                    style: AppTypography.bodyMd(
                      color: isCurrent ? AppColors.secondary : AppColors.primaryText,
                    ).copyWith(
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.song.artist,
                    style: AppTypography.labelSm(
                      color: AppColors.onSurfaceVariant,
                    ).copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Duration
            Text(
              durationStr,
              style: AppTypography.labelSm(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
              ).copyWith(fontSize: 10.5),
            ),
            const SizedBox(width: 8),

            // Play icon button
            Icon(
              isCurrent && isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              size: 24,
              color: isCurrent ? AppColors.secondary : AppColors.secondary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mini Equalizer Indicator ────────────────────────────────────────────────

class _MiniEqualizer extends StatefulWidget {
  final bool isPlaying;

  const _MiniEqualizer({required this.isPlaying});

  @override
  State<_MiniEqualizer> createState() => _MiniEqualizerState();
}

class _MiniEqualizerState extends State<_MiniEqualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.isPlaying) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _MiniEqualizer old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      if (widget.isPlaying) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.animateTo(0.2, duration: const Duration(milliseconds: 200));
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final offset = (index * 0.3);
            final value = widget.isPlaying
                ? ((_ctrl.value + offset) % 1.0)
                : 0.2;
            final height = 4.0 + (value * 12.0);
            return Container(
              width: 2.8,
              height: height,
              margin: const EdgeInsets.only(right: 2.5),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}

// ─── Artist Album Card (Horizontal) ──────────────────────────────────────────

class _ArtistAlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _ArtistAlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Artwork
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.15),
                  width: 0.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: SafeImage(
                urlOrPath: album.coverUrl,
                fit: BoxFit.cover,
                fallback: _defaultAlbumArt(),
              ),
            ),
            const SizedBox(height: 8),

            // Album Name
            Text(
              album.name,
              style: AppTypography.bodySm(
                color: AppColors.primaryText,
              ).copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Year / Subtitle
            Text(
              [
                if (album.year.isNotEmpty) album.year,
                if (album.songCount > 0) '${album.songCount} tracks',
              ].join(' • '),
              style: AppTypography.labelSm(
                color: AppColors.onSurfaceVariant,
              ).copyWith(fontSize: 10.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAlbumArt() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Center(
        child: Icon(
          Icons.album_rounded,
          color: AppColors.outline,
          size: 36,
        ),
      ),
    );
  }
}
