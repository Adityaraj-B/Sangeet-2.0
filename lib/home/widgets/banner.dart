import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/playlist_skeleton.dart';
import '../../components/track_artwork.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../models/models.dart';
import '../../repositories/music_repository.dart';
import '../../theme/theme.dart';

class _BannerItem {
  final String edition;
  final String kicker;
  final String title;
  final String artist;
  final String formatBadge;
  final String imageUrl;
  final Track track;

  const _BannerItem({
    required this.edition,
    required this.kicker,
    required this.title,
    required this.artist,
    required this.formatBadge,
    required this.imageUrl,
    required this.track,
  });
}

/// Horizontal scrollable banner displaying latest & trending tracks with auto-scroll
/// and direct stream playback. 100% dynamic without hardcoded mock tracks.
class HomeBanner extends StatefulWidget {
  final MusicRepository? musicRepository;

  const HomeBanner({super.key, this.musicRepository});

  /// Clears the session cache so a pull-to-refresh loads latest music.
  static void clearCache() {
    _HomeBannerState._cachedLiveBannerItems = null;
  }

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  static const int _virtualItemCount = 10000;
  static const int _initialPage = 5000;

  // Session cache to prevent redundant network requests
  static List<_BannerItem>? _cachedLiveBannerItems;

  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  List<_BannerItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.92,
    );

    if (_cachedLiveBannerItems != null && _cachedLiveBannerItems!.isNotEmpty) {
      _items = _cachedLiveBannerItems!;
      _currentPage = _initialPage % _items.length;
      _startAutoScroll();
    } else {
      _isLoading = true;
      _loadLatestAndTrending();
    }
  }

  Future<void> _loadLatestAndTrending() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = widget.musicRepository ?? MusicRepository.instance;
      final songs = await repo.getTrending();
      if (!mounted) return;

      if (songs.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No trending showcases available.';
        });
        return;
      }

      final limited = songs.take(6).toList();
      final mapped = <_BannerItem>[];

      for (var i = 0; i < limited.length; i++) {
        final song = limited[i];
        final track = song.toTrack();

        final edition = (i == 0)
            ? 'TRENDING #1'
            : (i == 1)
                ? 'LATEST RELEASE'
                : 'TRENDING #${i + 1}';

        final kicker = (i == 0)
            ? 'TOP CHART HIT · 320 KBPS'
            : (i % 2 == 1)
                ? 'LATEST SINGLE · 320 KBPS'
                : 'STUDIO MASTER · 320 KBPS';

        mapped.add(
          _BannerItem(
            edition: edition,
            kicker: kicker,
            title: song.title,
            artist: song.artist,
            formatBadge: 'LOSSLESS · 320 KBPS',
            imageUrl: song.coverUrl,
            track: track,
          ),
        );
      }

      _cachedLiveBannerItems = mapped;
      if (mounted) {
        setState(() {
          _items = mapped;
          _isLoading = false;
          _errorMessage = null;
          _currentPage = _initialPage % _items.length;
        });
        _startAutoScroll();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to fetch trending tracks: $e';
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_items.isEmpty) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients || _items.isEmpty) return;
      final nextPage = _pageController.page!.round() + 1;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pauseAndRestartAutoScroll() {
    _autoScrollTimer?.cancel();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return const HomeBannerSkeleton();
    }

    if (_errorMessage != null && _items.isEmpty) {
      return HomeBannerErrorCard(
        errorMessage: _errorMessage!,
        onRetry: _loadLatestAndTrending,
      );
    }

    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _virtualItemCount,
            onPageChanged: (idx) {
              setState(() {
                _currentPage = idx % _items.length;
              });
              _pauseAndRestartAutoScroll();
            },
            itemBuilder: (context, index) {
              final item = _items[index % _items.length];
              return _BannerCard(item: item);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_items.length, (idx) {
            final isActive = idx == _currentPage;
            return GestureDetector(
              onTap: () {
                final currentVirtual = _pageController.hasClients
                    ? _pageController.page!.round()
                    : _initialPage;
                final currentMod = currentVirtual % _items.length;
                final diff = idx - currentMod;
                final targetPage = currentVirtual + diff;
                _pageController.animateToPage(
                  targetPage,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 4,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.secondaryAccent
                      : AppColors.outlineVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerCard extends StatefulWidget {
  final _BannerItem item;

  const _BannerCard({required this.item});

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: ClipRRect(
          borderRadius: AppRadii.radiusXl,
          child: GestureDetector(
            onTap: () {
              context.read<PlayerBloc>().add(PlayerPlayTrack(item.track));
              PlayerScreen.open(context);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image with zoom on hover and graceful error fallback
                AnimatedScale(
                  scale: _hovered ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  child: SizedBox.expand(
                    child: Opacity(
                      opacity: 0.85,
                      child: SafeImage(
                        urlOrPath: item.imageUrl,
                        fit: BoxFit.cover,
                        fallback: Container(
                          color: AppColors.surfaceContainerLow,
                          child: const Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 64,
                              color: AppColors.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Gradient scrim
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0xA00E0E0F),
                        AppColors.surfaceContainerLowest,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Edition tag
                Positioned(
                  top: 20,
                  left: 20,
                  child: ClipRRect(
                    borderRadius: AppRadii.radiusSm,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        color: AppColors.surfaceContainerLowest.withValues(
                          alpha: 0.8,
                        ),
                        child: Text(
                          item.edition,
                          style: AppTypography.labelSm(
                            color: AppColors.secondaryAccent,
                          ).copyWith(letterSpacing: 0.2 * 10, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom info + play
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.kicker,
                              style: AppTypography.labelSm(
                                color: AppColors.secondaryAccent.withValues(
                                  alpha: 0.9,
                                ),
                              ).copyWith(
                                fontSize: 10,
                                letterSpacing: 0.18 * 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.title,
                              style: AppTypography.headlineMd(
                                color: AppColors.primaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              item.artist,
                              style: AppTypography.bodyMd(
                                color: AppColors.onSurfaceVariant,
                              ).copyWith(fontWeight: FontWeight.w300),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.formatBadge,
                              style: AppTypography.labelSm(
                                color: AppColors.onSurfaceVariant,
                              ).copyWith(
                                fontSize: 10,
                                letterSpacing: 0.15 * 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Circular play hub
                      BlocBuilder<PlayerBloc, PlayerState>(
                        builder: (context, pState) {
                          final isCurrentPlaying =
                              pState.isPlaying &&
                              pState.currentTrack?.id == item.track.id;
                          return GestureDetector(
                            onTap: () {
                              if (isCurrentPlaying) {
                                context.read<PlayerBloc>().add(
                                  const PlayerTogglePlayPause(),
                                );
                              } else {
                                context.read<PlayerBloc>().add(
                                  PlayerPlayTrack(item.track),
                                );
                                PlayerScreen.open(context);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isCurrentPlaying
                                    ? AppColors.secondaryAccent
                                    : AppColors.primaryText,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 16,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isCurrentPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 32,
                                color: AppColors.neutralCanvas,
                              ),
                            ),
                          );
                        },
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
