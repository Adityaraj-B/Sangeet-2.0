import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/track_artwork.dart';
import '../../insights/services/insight_service.dart';
import '../../models/models.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../repositories/history_repository.dart';
import '../../theme/theme.dart';

class CuratedSessionsSection extends StatefulWidget {
  const CuratedSessionsSection({super.key});

  @override
  State<CuratedSessionsSection> createState() => _CuratedSessionsSectionState();
}

class _CuratedSessionsSectionState extends State<CuratedSessionsSection> {
  @override
  void initState() {
    super.initState();
    HistoryRepository.instance.historyNotifier.addListener(_onHistoryChanged);
    ListeningInsightsService.instance.addListener(_onHistoryChanged);
  }

  @override
  void dispose() {
    HistoryRepository.instance.historyNotifier.removeListener(_onHistoryChanged);
    ListeningInsightsService.instance.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onHistoryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<HistoryItem> _getRecentItems() {
    final historyList = List<HistoryItem>.from(HistoryRepository.instance.history);
    if (historyList.isNotEmpty) {
      return historyList;
    }

    // Fallback to events from ListeningInsightsService if history was cleared/empty
    final events = ListeningInsightsService.instance.events.reversed.toList();
    final seenIds = <String>{};
    final List<HistoryItem> fallback = [];

    for (final e in events) {
      if (!seenIds.contains(e.songId)) {
        seenIds.add(e.songId);
        final mins = (e.totalDurationSeconds ~/ 60).toString().padLeft(2, '0');
        final secs = (e.totalDurationSeconds % 60).toString().padLeft(2, '0');

        fallback.add(
          HistoryItem(
            track: Track(
              id: e.songId,
              title: e.title,
              artist: e.artist,
              duration: '$mins:$secs',
              formatBadge: '320k',
              albumArt: e.coverUrl.isNotEmpty ? e.coverUrl : null,
              language: e.language,
              artistId: e.artistId,
              mood: e.mood,
              genres: e.genres,
            ),
            playedAt: e.timestamp,
          ),
        );
      }
    }

    return fallback;
  }

  void _playTrack(BuildContext context, Track track, List<Track> queue) {
    HapticFeedback.lightImpact();
    final idx = queue.indexWhere((t) => t.id == track.id);
    if (queue.length > 1) {
      context.read<PlayerBloc>().add(
            PlayerPlayQueue(queue, initialIndex: idx != -1 ? idx : 0),
          );
    } else {
      context.read<PlayerBloc>().add(PlayerPlayTrack(track));
    }
    PlayerScreen.open(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.graphic_eq_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Playing ${track.title} • ${track.artist}',
                style: AppTypography.bodySm(color: AppColors.primaryText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentItems = _getRecentItems();
    final hasRecent = recentItems.isNotEmpty;

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
                    'Curated Sessions',
                    style: AppTypography.headlineMd(color: AppColors.primary).copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Recently listened tracks from your personal vault',
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
                hasRecent ? '${recentItems.length} RECENT' : 'HISTORY',
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

        // ─── Recent Songs List or Empty State ─────────────────────────────
        if (hasRecent)
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentItems.length > 10 ? 10 : recentItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = recentItems[index];
              return _RecentSongTile(
                item: item,
                onTap: () {
                  final allRecentTracks = recentItems.map((h) => h.track).toList();
                  _playTrack(context, item.track, allRecentTracks);
                },
              );
            },
          )
        else
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 32,
              color: AppColors.outline,
            ),
            const SizedBox(height: 10),
            Text(
              'No recent sessions yet',
              style: AppTypography.bodySm(color: AppColors.primaryText).copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Songs you play will appear here in your personal session index.',
              style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)
                  .copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent Song Tile ────────────────────────────────────────────────────────

class _RecentSongTile extends StatefulWidget {
  final HistoryItem item;
  final VoidCallback onTap;

  const _RecentSongTile({required this.item, required this.onTap});

  @override
  State<_RecentSongTile> createState() => _RecentSongTileState();
}

class _RecentSongTileState extends State<_RecentSongTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final track = widget.item.track;
    final currentTrack = context.watch<PlayerBloc>().state.currentTrack;
    final isPlaying = context.watch<PlayerBloc>().state.isPlaying;
    final isCurrent = currentTrack?.id == track.id;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.surfaceContainerHigh
                : _pressed
                    ? AppColors.surfaceContainer
                    : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCurrent
                  ? AppColors.secondary.withValues(alpha: 0.4)
                  : _pressed
                      ? AppColors.secondary.withValues(alpha: 0.3)
                      : AppColors.outlineVariant.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 48x48 Thumbnail with play overlay
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TrackArtwork(
                      albumArt: track.albumArt,
                      trackId: track.id,
                      fit: BoxFit.cover,
                      fallback: _defaultCover(),
                    ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      child: Center(
                        child: Icon(
                          isCurrent && isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: isCurrent ? AppColors.secondary : AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle with timeAgo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: AppTypography.bodyMd(
                        color: isCurrent ? AppColors.secondary : AppColors.primary,
                      ).copyWith(
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${track.artist} • ${widget.item.timeAgo}',
                      style: AppTypography.labelSm(
                        color: AppColors.onSurfaceVariant,
                      ).copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Duration text
              Text(
                track.duration,
                style: AppTypography.labelSm(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                ).copyWith(fontSize: 10.5),
              ),
              const SizedBox(width: 8),

              // Audio Format Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  track.formatBadge.isNotEmpty ? track.formatBadge : '320k',
                  style: AppTypography.labelSm(color: AppColors.secondary)
                      .copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              const SizedBox(width: 4),

              // Play icon button
              IconButton(
                icon: Icon(
                  isCurrent && isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  size: 24,
                  color: isCurrent ? AppColors.secondary : AppColors.secondary.withValues(alpha: 0.8),
                ),
                onPressed: widget.onTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultCover() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          color: AppColors.outline,
          size: 22,
        ),
      ),
    );
  }
}
