import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../artist/screens/artist_detail_screen.dart';
import '../../components/track_artwork.dart';
import '../../insights/models/listening_insights.dart';
import '../../insights/services/insight_service.dart';
import '../../models/models.dart';
import '../../repositories/history_repository.dart';
import '../../repositories/music_repository.dart';
import '../../theme/theme.dart';
import '../bloc/library_bloc.dart';

class FollowedMastersSection extends StatefulWidget {
  final List<FollowedArtist>? artists;

  const FollowedMastersSection({super.key, this.artists});

  @override
  State<FollowedMastersSection> createState() => _FollowedMastersSectionState();
}

class _FollowedMastersSectionState extends State<FollowedMastersSection> {
  static final Map<String, String> _artistPhotoCache = {};
  static final Map<String, String> _artistIdCache = {};
  static final Set<String> _resolvingArtists = {};

  @override
  void initState() {
    super.initState();
    ListeningInsightsService.instance.addListener(_onDataChanged);
    HistoryRepository.instance.historyNotifier.addListener(_onDataChanged);
    _triggerPhotoResolution();
  }

  @override
  void dispose() {
    ListeningInsightsService.instance.removeListener(_onDataChanged);
    HistoryRepository.instance.historyNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
      _triggerPhotoResolution();
    }
  }

  void _triggerPhotoResolution() {
    final rawTop =
        ListeningInsightsService.instance.getTopListenedArtists(limit: 15);
    for (final a in rawTop) {
      final name = a.artistName.trim();
      if (name.isEmpty ||
          (_artistPhotoCache.containsKey(name) && _artistIdCache.containsKey(name)) ||
          _resolvingArtists.contains(name)) {
        continue;
      }
      _resolvingArtists.add(name);
      MusicRepository.instance.searchArtists(name).then((results) {
        if (results.isNotEmpty && mounted) {
          final first = results.first;
          setState(() {
            if (first.imageUrl.isNotEmpty) {
              _artistPhotoCache[name] = first.imageUrl;
            }
            if (first.id.isNotEmpty && RegExp(r'^\d+$').hasMatch(first.id)) {
              _artistIdCache[name] = first.id;
            }
          });
        }
      }).catchError((_) {}).whenComplete(() {
        _resolvingArtists.remove(name);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawTopArtists =
        ListeningInsightsService.instance.getTopListenedArtists(limit: 15);

    // Guarantee strict deduplication by normalized artist name
    final seen = <String>{};
    final topArtists = <ArtistInsight>[];
    for (final a in rawTopArtists) {
      final key = a.artistName.trim().toLowerCase();
      if (key.isNotEmpty && seen.add(key)) {
        topArtists.add(a);
        if (topArtists.length >= 10) break;
      }
    }

    final hasInsights = topArtists.isNotEmpty;

    final fallbackSeen = <String>{};
    final fallbackList = <FollowedArtist>[];
    for (final a in (widget.artists ?? const <FollowedArtist>[])) {
      final key = a.name.trim().toLowerCase();
      if (key.isNotEmpty && fallbackSeen.add(key)) {
        fallbackList.add(a);
      }
    }

    final int displayCount = hasInsights ? topArtists.length : fallbackList.length;

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
                    hasInsights ? 'TOP LISTENED MASTERS' : 'FOLLOWED MASTERS',
                    style: AppTypography.labelMd(color: AppColors.primary).copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasInsights) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Curated live from your listening insights',
                      style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)
                          .copyWith(fontSize: 10.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: hasInsights
                    ? AppColors.secondary.withValues(alpha: 0.12)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasInsights
                      ? AppColors.secondary.withValues(alpha: 0.3)
                      : AppColors.outlineVariant.withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
              child: Text(
                hasInsights
                    ? '$displayCount TOP ${displayCount == 1 ? 'ARTIST' : 'ARTISTS'}'
                    : '$displayCount COMPOSER${displayCount == 1 ? '' : 'S'}',
                style: AppTypography.labelSm(
                  color: hasInsights ? AppColors.secondary : AppColors.outline,
                ).copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ─── Horizontal Carousel ─────────────────────────────────────────
        SizedBox(
          height: 114,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: displayCount,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              if (hasInsights) {
                final insight = topArtists[index];
                final resolvedPhoto =
                    _artistPhotoCache[insight.artistName] ??
                    (insight.sampleCoverUrl.isNotEmpty
                        ? insight.sampleCoverUrl
                        : '');
                return _InsightArtistItem(
                  insight: insight,
                  resolvedPhoto: resolvedPhoto,
                  rank: index + 1,
                );
              } else {
                final artist = fallbackList[index];
                return _FallbackArtistItem(artist: artist);
              }
            },
          ),
        ),
      ],
    );
  }
}

// ─── Top Listened Artist Item (Driven by Insights) ──────────────────────────

class _InsightArtistItem extends StatefulWidget {
  final ArtistInsight insight;
  final String resolvedPhoto;
  final int rank;

  const _InsightArtistItem({
    required this.insight,
    required this.resolvedPhoto,
    required this.rank,
  });

  @override
  State<_InsightArtistItem> createState() => _InsightArtistItemState();
}

class _InsightArtistItemState extends State<_InsightArtistItem> {
  bool _pressed = false;

  String _formatStat(ArtistInsight a) {
    if (a.totalSeconds >= 3600) {
      final hours = (a.totalSeconds / 3600).toStringAsFixed(1);
      return '${hours}h played';
    } else if (a.totalSeconds >= 60) {
      final mins = a.totalSeconds ~/ 60;
      return '${mins}m played';
    } else {
      final plays = a.playCount;
      return '$plays ${plays == 1 ? 'play' : 'plays'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final insight = widget.insight;
    final isTop = widget.rank == 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();

        final resolvedId = _FollowedMastersSectionState._artistIdCache[insight.artistName] ??
            (RegExp(r'^\d+$').hasMatch(insight.artistKey.trim())
                ? insight.artistKey.trim()
                : (insight.artistKey.isNotEmpty ? insight.artistKey : insight.artistName));

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArtistDetailScreen(
              artist: Artist(
                id: resolvedId,
                name: insight.artistName,
                imageUrl: widget.resolvedPhoto,
                role: isTop ? 'Top Master' : 'Artist',
              ),
            ),
          ),
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar circle with Aura gradient border
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: isTop
                            ? [
                                AppColors.secondary,
                                AppColors.secondary.withValues(alpha: 0.4),
                              ]
                            : [
                                AppColors.secondary.withValues(alpha: 0.5),
                                AppColors.outlineVariant.withValues(alpha: 0.2),
                              ],
                      ),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceContainerHigh,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SafeImage(
                        urlOrPath: widget.resolvedPhoto,
                        fit: BoxFit.cover,
                        fallback: _defaultAvatar(),
                      ),
                    ),
                  ),

                  // Rank 1 Gold Crown/Star Badge
                  if (isTop)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 11,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),

              // Artist Name
              Text(
                insight.artistName,
                style: AppTypography.bodySm(
                  color: _pressed ? AppColors.secondary : AppColors.primaryText,
                ).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),

              // Listening Stats Pill / Subtitle
              Text(
                _formatStat(insight),
                style: AppTypography.labelSm(
                  color: isTop ? AppColors.secondary : AppColors.onSurfaceVariant,
                ).copyWith(
                  fontSize: 9.5,
                  fontWeight: isTop ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Center(
        child: Icon(Icons.person_rounded, color: AppColors.outline, size: 28),
      ),
    );
  }
}

// ─── Fallback Master Item (For New Users Before Plays) ──────────────────────

class _FallbackArtistItem extends StatefulWidget {
  final FollowedArtist artist;

  const _FallbackArtistItem({required this.artist});

  @override
  State<_FallbackArtistItem> createState() => _FallbackArtistItemState();
}

class _FallbackArtistItemState extends State<_FallbackArtistItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArtistDetailScreen(
              artist: Artist(
                id: widget.artist.id,
                name: widget.artist.name,
                imageUrl: widget.artist.imageUrl,
                role: 'Composer',
              ),
            ),
          ),
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.6),
                      AppColors.outlineVariant.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerHigh,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
                    child: SafeImage(
                      urlOrPath: widget.artist.imageUrl,
                      fit: BoxFit.cover,
                      fallback: Container(
                        color: AppColors.surfaceContainerHigh,
                        child: const Icon(Icons.person_rounded, color: AppColors.outline),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),

              // Name
              Text(
                widget.artist.name,
                style: AppTypography.bodySm(
                  color: _pressed ? AppColors.secondary : AppColors.primaryText,
                ).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),

              // Tag
              Text(
                'Composer',
                style: AppTypography.labelSm(
                  color: AppColors.onSurfaceVariant,
                ).copyWith(fontSize: 9.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

