import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/track_artwork.dart';
import '../../home/screens/recent_listening_screen.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../repositories/history_repository.dart';
import '../../theme/theme.dart';
import '../bloc/library_bloc.dart';

class RecentPlaybackSection extends StatelessWidget {
  final List<LibraryRecentTrack>? tracks;

  const RecentPlaybackSection({super.key, this.tracks});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<HistoryItem>>(
      valueListenable: HistoryRepository.instance.historyNotifier,
      builder: (context, historyItems, _) {
        final itemCount =
            historyItems.length > 4 ? 4 : historyItems.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'RECENT PLAYBACK HISTORY',
                  style: AppTypography.labelMd(color: AppColors.primary).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                if (historyItems.isNotEmpty)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecentListeningScreen(),
                        ),
                      );
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'VIEW ALL',
                            style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 9,
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Tracks List or Empty State
            if (historyItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.headphones_rounded,
                      color: AppColors.secondaryAccent,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No Playback History Yet',
                      style: AppTypography.bodySm(color: AppColors.primaryText).copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tracks you listen to will appear in your playback history.',
                      style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemCount,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final hItem = historyItems[index];
                  return _DynamicRecentTrackTile(item: hItem);
                },
              ),
          ],
        );
      },
    );
  }
}

class _DynamicRecentTrackTile extends StatefulWidget {
  final HistoryItem item;

  const _DynamicRecentTrackTile({required this.item});

  @override
  State<_DynamicRecentTrackTile> createState() => _DynamicRecentTrackTileState();
}

class _DynamicRecentTrackTileState extends State<_DynamicRecentTrackTile> {
  bool _pressed = false;

  void _playTrack(BuildContext context) {
    HapticFeedback.lightImpact();
    context.read<PlayerBloc>().add(PlayerPlayTrack(widget.item.track));
    PlayerScreen.open(context);
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.item.track;
    final coverUrl = track.albumArt ?? '';

    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, pState) {
        final isCurrent = pState.currentTrack?.id == track.id;
        final isPlaying = isCurrent && pState.isPlaying;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            if (isCurrent) {
              context.read<PlayerBloc>().add(const PlayerTogglePlayPause());
            } else {
              _playTrack(context);
            }
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.surfaceContainerHigh
                    : _pressed
                        ? AppColors.surfaceContainerHigh
                        : AppColors.surfaceContainerLow.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent
                      ? AppColors.secondary.withValues(alpha: 0.45)
                      : _pressed
                          ? AppColors.secondary.withValues(alpha: 0.3)
                          : AppColors.outlineVariant.withValues(alpha: 0.12),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  // 44x44 Album art thumbnail
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        TrackArtwork(
                          albumArt: coverUrl,
                          trackId: track.id,
                          fit: BoxFit.cover,
                          fallback: Container(
                            color: AppColors.surfaceContainerHigh,
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: AppColors.outline,
                              size: 20,
                            ),
                          ),
                        ),
                        if (isPlaying)
                          Container(
                            color: Colors.black.withValues(alpha: 0.4),
                            child: const Center(
                              child: Icon(
                                Icons.equalizer_rounded,
                                color: AppColors.secondary,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title, Badge & Artist
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                track.title,
                                style: AppTypography.bodyMd(
                                  color: isCurrent ? AppColors.secondary : AppColors.primary,
                                ).copyWith(
                                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 13.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                track.formatBadge.toUpperCase(),
                                style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                                  fontSize: 8.5,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                track.artist,
                                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(
                                  fontSize: 11.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• ${widget.item.timeAgo}',
                              style: AppTypography.labelSm(color: AppColors.outline).copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Duration
                  Text(
                    track.duration,
                    style: AppTypography.labelSm(color: AppColors.outline).copyWith(
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Play/Pause icon button
                  Icon(
                    isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_outline_rounded,
                    size: 22,
                    color: isCurrent ? AppColors.secondary : AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

