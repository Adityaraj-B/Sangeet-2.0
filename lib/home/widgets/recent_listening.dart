import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/track_artwork.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../repositories/history_repository.dart';
import '../../theme/theme.dart';
import '../screens/recent_listening_screen.dart';

class RecentListening extends StatelessWidget {
  const RecentListening({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Listening',
                style: AppTypography.bodyLg(
                  color: AppColors.primaryText,
                ).copyWith(fontWeight: FontWeight.w400),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              // Clickable HISTORY button navigating to RecentListeningScreen
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'HISTORY',
                          style: AppTypography.labelSm(
                            color: AppColors.secondaryAccent,
                          ).copyWith(
                            letterSpacing: 0.15 * 10,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 9,
                          color: AppColors.secondaryAccent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dynamic grid backed by HistoryRepository
          ValueListenableBuilder<List<HistoryItem>>(
            valueListenable: HistoryRepository.instance.historyNotifier,
            builder: (context, items, _) {
              if (items.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: AppRadii.radiusXl,
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.headphones_rounded,
                        color: AppColors.secondaryAccent,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Recent Listening Will Appear Here',
                        style: AppTypography.bodySm(color: AppColors.primaryText).copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Play any track from Search or Playlists to begin',
                        style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }

              final displayed = items.take(4).toList();

              return GridView.count(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
                children: displayed
                    .map((item) => _RecentGridCard(item: item))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentGridCard extends StatefulWidget {
  final HistoryItem item;
  const _RecentGridCard({required this.item});

  @override
  State<_RecentGridCard> createState() => _RecentGridCardState();
}

class _RecentGridCardState extends State<_RecentGridCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final track = widget.item.track;
    final coverArt = track.albumArt ?? '';

    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, pState) {
        final isCurrent = pState.currentTrack?.id == track.id;
        final isPlaying = isCurrent && pState.isPlaying;

        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (isCurrent) {
                context.read<PlayerBloc>().add(const PlayerTogglePlayPause());
              } else {
                context.read<PlayerBloc>().add(PlayerPlayTrack(track));
                PlayerScreen.open(context);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.surfaceContainerHigh
                    : _hovered
                        ? AppColors.surfaceContainer
                        : AppColors.surfaceContainerLow,
                borderRadius: AppRadii.radiusXl,
                border: Border.all(
                  color: isCurrent
                      ? AppColors.secondaryAccent.withValues(alpha: 0.45)
                      : _hovered
                          ? AppColors.outlineVariant.withValues(alpha: 0.3)
                          : AppColors.outlineVariant.withValues(alpha: 0.12),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Album art
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadii.radiusLg,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedScale(
                            scale: _hovered ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 400),
                            child: TrackArtwork(
                              albumArt: coverArt,
                              trackId: track.id,
                              fit: BoxFit.cover,
                              fallback: Container(
                                color: AppColors.surfaceContainerHighest,
                                child: const Center(
                                  child: Icon(
                                    Icons.music_note_rounded,
                                    color: AppColors.outline,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Playing state overlay
                          if (isPlaying)
                            Container(
                              color: Colors.black.withValues(alpha: 0.4),
                              child: const Center(
                                child: Icon(
                                  Icons.equalizer_rounded,
                                  color: AppColors.secondaryAccent,
                                  size: 28,
                                ),
                              ),
                            ),

                          // Hi-Res format badge
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: ClipRRect(
                              borderRadius: AppRadii.radiusSm,
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  color: AppColors.surfaceContainerLowest
                                      .withValues(alpha: 0.8),
                                  child: Text(
                                    track.formatBadge.toUpperCase(),
                                    style: AppTypography.labelSm(
                                      color: AppColors.secondaryAccent,
                                    ).copyWith(fontSize: 8.5, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    track.title,
                    style: AppTypography.bodyMd(
                      color: isCurrent ? AppColors.secondaryAccent : AppColors.primaryText,
                    ).copyWith(
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),

                  // Artist
                  Text(
                    track.artist,
                    style: AppTypography.bodySm(
                      color: AppColors.onSurfaceVariant,
                    ).copyWith(fontWeight: FontWeight.w300, fontSize: 11.5),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),

                  // Relative time / Meta
                  Text(
                    widget.item.timeAgo.toUpperCase(),
                    style: AppTypography.labelSm(
                      color: isCurrent
                          ? AppColors.secondaryAccent
                          : AppColors.outline,
                    ).copyWith(letterSpacing: 0.12 * 10, fontSize: 9.5),
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
