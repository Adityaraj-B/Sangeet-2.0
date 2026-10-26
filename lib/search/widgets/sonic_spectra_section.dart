import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../components/track_artwork.dart';
import '../../home/screens/album_detail_screen.dart';
import '../../insights/services/insight_service.dart';
import '../../models/models.dart';
import '../../repositories/history_repository.dart';
import '../../repositories/music_repository.dart';
import '../../theme/theme.dart';
import '../bloc/search_bloc.dart';

class SonicSpectraSection extends StatefulWidget {
  final List<SonicSpectrumCategory>? categories;

  const SonicSpectraSection({super.key, this.categories});

  @override
  State<SonicSpectraSection> createState() => _SonicSpectraSectionState();
}

class _SonicSpectraSectionState extends State<SonicSpectraSection> {
  List<Album> _allAlbums = [];
  List<Album> _moodAlbums = [];
  List<Album> _artistAlbums = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _lastCacheKey;
  String _activeFilter = 'ALL'; // 'ALL', 'MOOD', 'ARTIST'

  @override
  void initState() {
    super.initState();
    _loadPersonalizedAlbums();
    ListeningInsightsService.instance.addListener(_onInsightsChanged);
    HistoryRepository.instance.historyNotifier.addListener(_onInsightsChanged);
  }

  @override
  void dispose() {
    ListeningInsightsService.instance.removeListener(_onInsightsChanged);
    HistoryRepository.instance.historyNotifier.removeListener(_onInsightsChanged);
    super.dispose();
  }

  void _onInsightsChanged() {
    if (mounted) {
      _loadPersonalizedAlbums();
    }
  }

  Future<void> _loadPersonalizedAlbums() async {
    final insights = ListeningInsightsService.instance;
    final summary = insights.computeSummary();
    final topMood = insights.getPrimaryConsumedMood(defaultMood: 'Romantic');
    final topArtists = summary.topArtists;
    final topArtistName = topArtists.isNotEmpty ? topArtists.first.artistName : null;
    final topSong = insights.getMostListenedSong();

    // Cache key to avoid redundant API queries
    final currentKey = '${topMood}_${topArtistName ?? ''}_${topSong?.id ?? ''}';
    if (_lastCacheKey == currentKey && _allAlbums.isNotEmpty) {
      if (mounted && _isLoading) setState(() => _isLoading = false);
      return;
    }
    _lastCacheKey = currentKey;

    if (mounted) {
      setState(() {
        _isLoading = _allAlbums.isEmpty;
        _errorMessage = null;
      });
    }

    try {
      final repo = MusicRepository.instance;
      final List<Future<List<Album>>> tasks = [];

      // Task 1: Albums for user's top consumed mood (e.g. Romantic, Melodic, etc.)
      final moodQuery = topMood.toLowerCase() == 'romantic'
          ? 'romantic'
          : topMood;
      tasks.add(repo.searchAlbums(moodQuery).catchError((_) => <Album>[]));

      // Task 2: Albums for user's top consumed artist
      if (topArtistName != null && topArtistName.isNotEmpty) {
        tasks.add(repo.searchAlbums(topArtistName).catchError((_) => <Album>[]));
      } else {
        // Fallback to trending
        tasks.add(repo.getTrendingAlbums(limit: 6).catchError((_) => <Album>[]));
      }

      // Task 3: 2nd top artist or general trending albums
      if (topArtists.length > 1) {
        tasks.add(repo.searchAlbums(topArtists[1].artistName).catchError((_) => <Album>[]));
      } else {
        tasks.add(repo.getTrendingAlbums(limit: 6).catchError((_) => <Album>[]));
      }

      final results = await Future.wait(tasks);
      final moodList = results[0];
      final artistList = results[1];

      final Set<String> seenIds = {};
      final List<Album> merged = [];

      // Interleave results to provide balanced diversity between mood & artist
      int maxLen = results.fold(0, (max, list) => list.length > max ? list.length : max);
      for (int i = 0; i < maxLen; i++) {
        for (final list in results) {
          if (i < list.length) {
            final album = list[i];
            if (album.id.isNotEmpty && !seenIds.contains(album.id)) {
              seenIds.add(album.id);
              merged.add(album);
            }
          }
        }
      }

      if (!mounted) return;

      if (merged.isNotEmpty) {
        setState(() {
          _allAlbums = merged.take(10).toList();
          _moodAlbums = moodList;
          _artistAlbums = artistList;
          _isLoading = false;
        });
      } else {
        // Fallback to trending albums
        final fallback = await repo.getTrendingAlbums(limit: 6);
        if (mounted) {
          setState(() {
            _allAlbums = fallback;
            _moodAlbums = fallback;
            _artistAlbums = fallback;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (_allAlbums.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load recommended albums.';
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insights = ListeningInsightsService.instance;
    final summary = insights.computeSummary();
    final topMood = insights.getPrimaryConsumedMood(defaultMood: 'Romantic');
    final topArtist = summary.topArtists.isNotEmpty ? summary.topArtists.first.artistName : null;

    // Filter displayed albums based on tab
    List<Album> displayedAlbums = _allAlbums;
    if (_activeFilter == 'MOOD' && _moodAlbums.isNotEmpty) {
      displayedAlbums = _moodAlbums;
    } else if (_activeFilter == 'ARTIST' && _artistAlbums.isNotEmpty) {
      displayedAlbums = _artistAlbums;
    }

    final moodLabel = topMood.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header Row ──────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sonic Spectra',
                    style: AppTypography.headlineMd(color: AppColors.primary).copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Albums aligned with your music consumption',
                    style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)
                        .copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Text(
                'TASTE: $moodLabel',
                style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─── Interactive Insight Filter Pills ────────────────────────────
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildFilterPill(
                keyName: 'ALL',
                label: 'All For You',
                isSelected: _activeFilter == 'ALL',
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                keyName: 'MOOD',
                label: '$topMood Albums',
                isSelected: _activeFilter == 'MOOD',
              ),
              if (topArtist != null && topArtist.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildFilterPill(
                  keyName: 'ARTIST',
                  label: '$topArtist Releases',
                  isSelected: _activeFilter == 'ARTIST',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ─── Content / Loading / Albums Grid ─────────────────────────────
        if (_isLoading && _allAlbums.isEmpty)
          _buildLoadingGrid()
        else if (_errorMessage != null && _allAlbums.isEmpty)
          _buildErrorWidget()
        else
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedAlbums.length > 6 ? 6 : displayedAlbums.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final album = displayedAlbums[index];
              return _PersonalizedAlbumCard(
                album: album,
                topMood: topMood,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AlbumDetailScreen(album: album),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterPill({
    required String keyName,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeFilter = keyName);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.secondary
                : AppColors.outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelSm(
              color: isSelected ? Colors.black : AppColors.onSurfaceVariant,
            ).copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.outline, size: 32),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Could not load recommended albums.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _loadPersonalizedAlbums,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Personalized Album Card ─────────────────────────────────────────────────

class _PersonalizedAlbumCard extends StatefulWidget {
  final Album album;
  final String topMood;
  final VoidCallback onTap;

  const _PersonalizedAlbumCard({
    required this.album,
    required this.topMood,
    required this.onTap,
  });

  @override
  State<_PersonalizedAlbumCard> createState() => _PersonalizedAlbumCardState();
}

class _PersonalizedAlbumCardState extends State<_PersonalizedAlbumCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    final topMoodUpper = widget.topMood.toUpperCase();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _pressed
                  ? AppColors.secondary.withValues(alpha: 0.4)
                  : AppColors.outlineVariant.withValues(alpha: 0.14),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x38000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Square Artwork with overlays
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeImage(
                      urlOrPath: album.coverUrl,
                      fit: BoxFit.cover,
                      fallback: _defaultAlbumCover(),
                    ),

                    // Subtle top & bottom shadow gradient
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xD90E0E0F),
                            Colors.transparent,
                            Color(0x660E0E0F),
                          ],
                          stops: [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),

                    // Top Affinity Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.35),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          album.year.isNotEmpty ? album.year : topMoodUpper,
                          style: AppTypography.labelSm(
                            color: AppColors.secondary,
                          ).copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),

                    // Quick Play Icon Button
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Metadata at bottom of card
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      album.name,
                      style: AppTypography.bodySm(
                        color: AppColors.primaryText,
                      ).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      album.artist.isNotEmpty
                          ? album.artist
                          : album.language.toUpperCase(),
                      style: AppTypography.labelSm(
                        color: AppColors.onSurfaceVariant,
                      ).copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            album.songCount > 0
                                ? '${album.songCount} Tracks • Master'
                                : 'High Fidelity Master',
                            style: AppTypography.labelSm(
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.75),
                            ).copyWith(fontSize: 9.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAlbumCover() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Center(
        child: Icon(
          Icons.album_rounded,
          color: AppColors.outline,
          size: 40,
        ),
      ),
    );
  }
}
