import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/playlist_skeleton.dart';
import '../../components/track_artwork.dart';
import '../../models/models.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../repositories/music_repository.dart';
import '../../theme/theme.dart';
import '../screens/album_detail_screen.dart';

class TrendingAlbumsSection extends StatefulWidget {
  const TrendingAlbumsSection({super.key});

  /// Clears the session cache so a pull-to-refresh loads latest albums.
  static void clearCache() {
    _TrendingAlbumsSectionState._cachedAlbums = null;
  }

  @override
  State<TrendingAlbumsSection> createState() => _TrendingAlbumsSectionState();
}

class _TrendingAlbumsSectionState extends State<TrendingAlbumsSection> {
  static List<Album>? _cachedAlbums;
  List<Album> _albums = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (_cachedAlbums != null && _cachedAlbums!.isNotEmpty) {
      _albums = _cachedAlbums!;
      _isLoading = false;
    } else {
      _loadTrendingAlbums();
    }
  }

  Future<void> _loadTrendingAlbums() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched =
          await MusicRepository.instance.getTrendingAlbums(limit: 10);
      if (!mounted) return;

      if (fetched.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No trending albums available.';
        });
        return;
      }

      _cachedAlbums = fetched;
      setState(() {
        _albums = fetched;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to fetch trending albums: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _albums.isEmpty) {
      return const _TrendingAlbumsSkeleton();
    }

    if (_errorMessage != null && _albums.isEmpty) {
      return _TrendingAlbumsErrorCard(
        errorMessage: _errorMessage!,
        onRetry: _loadTrendingAlbums,
      );
    }

    if (_albums.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trending Albums',
                    style: AppTypography.bodyLg(color: AppColors.primaryText)
                        .copyWith(fontWeight: FontWeight.w400),
                  ),
                  Text(
                    'STUDIO MASTERS & SOUNDTRACKS',
                    style: AppTypography.labelSm(
                      color: AppColors.onSurfaceVariant,
                    ).copyWith(fontSize: 10, letterSpacing: 0.14 * 10),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.album_rounded,
                      size: 11,
                      color: AppColors.secondaryAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_albums.length} RELEASES',
                      style: AppTypography.labelSm(
                        color: AppColors.secondaryAccent,
                      ).copyWith(fontSize: 9.5, letterSpacing: 0.1 * 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _albums.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, i) => _AlbumCard(album: _albums[i]),
          ),
        ),
      ],
    );
  }
}

class _TrendingAlbumsSkeleton extends StatelessWidget {
  const _TrendingAlbumsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AcousticShimmer(
                    child: SkeletonBox(
                      width: 140,
                      height: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AcousticShimmer(
                    child: SkeletonBox(
                      width: 190,
                      height: 10,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) => const _AlbumSkeletonCard(),
          ),
        ),
      ],
    );
  }
}

class _AlbumSkeletonCard extends StatelessWidget {
  const _AlbumSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return AcousticShimmer(
      child: Container(
        width: 250,
        height: 240,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.radiusXl,
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
            width: 0.8,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SkeletonBox(
              width: 60,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 10),
            SkeletonBox(
              width: 170,
              height: 15,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            SkeletonBox(
              width: 110,
              height: 11,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingAlbumsErrorCard extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _TrendingAlbumsErrorCard({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.radiusXl,
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.album_rounded,
              color: AppColors.outline,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'Trending Albums Unavailable',
              style: AppTypography.bodySm(color: AppColors.primaryText).copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Could not load trending releases right now.',
              style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onRetry();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'RETRY',
                  style: AppTypography.labelSm(color: AppColors.secondaryAccent).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Backwards-compatible alias for CuratedSoundscapes
typedef CuratedSoundscapes = TrendingAlbumsSection;

class _AlbumCard extends StatefulWidget {
  final Album album;
  const _AlbumCard({required this.album});

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
  bool _hovered = false;

  void _openAlbum(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(album: widget.album),
      ),
    );
  }

  Future<void> _playAlbumDirectly() async {
    HapticFeedback.mediumImpact();
    final playerBloc = context.read<PlayerBloc>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Loading ${widget.album.name}...',
          style: AppTypography.bodySm(color: AppColors.primaryText),
        ),
      ),
    );

    try {
      final songs =
          await MusicRepository.instance.getSongsByAlbum(widget.album.id);
      if (!mounted) return;
      if (songs.isNotEmpty) {
        final tracks = songs.map((s) => s.toTrack()).toList();
        playerBloc.add(PlayerPlayQueue(tracks, initialIndex: 0));
        PlayerScreen.open(context);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    final cover = album.coverUrl;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _openAlbum(context),
        child: SizedBox(
          width: 250,
          child: ClipRRect(
            borderRadius: AppRadii.radiusXl,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background cover artwork with smooth zoom
                AnimatedScale(
                  scale: _hovered ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      image: safeImageProvider(cover) != null
                          ? DecorationImage(
                              image: safeImageProvider(cover)!,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: safeImageProvider(cover) == null
                        ? const Center(
                            child: Icon(
                              Icons.album_rounded,
                              size: 48,
                              color: AppColors.outline,
                            ),
                          )
                        : null,
                  ),
                ),

                // Gradient scrim overlay
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x800E0E0F),
                        AppColors.surfaceContainerLowest,
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                ),

                // Top year & language pill
                Positioned(
                  top: 14,
                  left: 14,
                  child: ClipRRect(
                    borderRadius: AppRadii.radiusSm,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        color: AppColors.surfaceContainerLowest
                            .withValues(alpha: 0.75),
                        child: Text(
                          [
                            if (album.language.isNotEmpty)
                              album.language.toUpperCase(),
                            if (album.year.isNotEmpty) album.year,
                          ].join(' • '),
                          style: AppTypography.labelSm(
                            color: AppColors.secondaryAccent,
                          ).copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Quick Play Button on top-right
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _playAlbumDirectly,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest
                            .withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondaryAccent.withValues(
                            alpha: 0.4,
                          ),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 20,
                          color: AppColors.secondaryAccent,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom album details
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        album.name,
                        style: AppTypography.headlineMd(
                          color: AppColors.primaryText,
                        ).copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        album.artist,
                        style: AppTypography.bodySm(
                          color: AppColors.onSurfaceVariant,
                        ).copyWith(
                          fontWeight: FontWeight.w300,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'STUDIO MASTER · 320K',
                              style: AppTypography.labelSm(
                                color: AppColors.secondaryAccent,
                              ).copyWith(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          if (album.songCount > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${album.songCount} Tracks',
                              style: AppTypography.labelSm(
                                color: AppColors.outline,
                              ).copyWith(fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                    ],
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
