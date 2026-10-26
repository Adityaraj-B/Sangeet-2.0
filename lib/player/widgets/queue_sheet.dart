import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/models.dart';
import '../../components/track_artwork.dart';
import '../../theme/theme.dart';
import '../bloc/player_bloc.dart';

/// Opens the Master Queue & Autoplay bottom sheet.
void showQueueBottomSheet(BuildContext context) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.neutralCanvas,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<PlayerBloc>(),
      child: const QueueSheet(),
    ),
  );
}

class QueueSheet extends StatefulWidget {
  const QueueSheet({super.key});

  @override
  State<QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends State<QueueSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _barsController;

  @override
  void initState() {
    super.initState();
    _barsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _barsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        final currentTrack = state.currentTrack;
        final allTracks = state.queue;
        final currentIndex = state.currentIndex;

        // Upcoming tracks are tracks that come strictly after currentIndex
        final upcomingTracks = currentIndex < allTracks.length - 1
            ? allTracks.sublist(currentIndex + 1)
            : <Track>[];

        final userQueued = upcomingTracks.where((t) => !t.isAutoplay).toList();
        final autoplayQueued = upcomingTracks.where((t) => t.isAutoplay).toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (sheetCtx, scrollController) {
            return SafeArea(
              top: false,
              child: Column(
                children: [
                  // 1. Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 2. Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'MASTER QUEUE',
                          style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${allTracks.length}',
                            style: AppTypography.labelSm(color: AppColors.primary).copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (upcomingTracks.isNotEmpty)
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              context.read<PlayerBloc>().add(const PlayerClearUpcomingQueue());
                            },
                            child: Text(
                              'Clear Upcoming',
                              style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.onSurfaceVariant),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: const EdgeInsets.only(left: 8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // 3. Scrollable Queue Body
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      children: [
                        // Now Playing Section
                        if (currentTrack != null) ...[
                          _buildSectionHeader('NOW PLAYING'),
                          const SizedBox(height: 8),
                          _buildNowPlayingCard(context, currentTrack, state.isPlaying),
                          const SizedBox(height: 20),
                        ],

                        // Up Next (User Queue) Section
                        _buildSectionHeader(
                          'UP NEXT',
                          badge: '${userQueued.length}',
                          trailingNote: userQueued.isNotEmpty ? 'Drag to reorder' : null,
                        ),
                        const SizedBox(height: 8),
                        if (userQueued.isEmpty)
                          _buildEmptyQueueNote('No user-queued tracks. Songs you add will appear here.')
                        else
                          _buildUserQueueList(context, state, userQueued),
                        const SizedBox(height: 20),

                        // Autoplay Recommendations Section
                        if (state.isAutoplayEnabled) ...[
                          _buildSectionHeader(
                            'AUTOPLAY MIX',
                            badge: '${autoplayQueued.length}',
                            icon: Icons.auto_awesome_rounded,
                            trailingNote: state.isLoadingAutoplay ? 'Generating mix...' : 'Session vector',
                          ),
                          const SizedBox(height: 8),
                          if (state.isLoadingAutoplay && autoplayQueued.isEmpty)
                            _buildLoadingShimmer()
                          else if (autoplayQueued.isEmpty)
                            _buildEmptyQueueNote('Autoplay is searching for matching mood and language tracks...')
                          else
                            _buildAutoplayList(context, state, autoplayQueued),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? badge,
    IconData? icon,
    String? trailingNote,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: AppColors.secondary),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: AppTypography.labelSm(color: AppColors.onSurfaceVariant).copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (trailingNote != null)
          Text(
            trailingNote,
            style: AppTypography.labelSm(
              color: AppColors.outline.withValues(alpha: 0.8),
            ).copyWith(fontSize: 10),
          ),
      ],
    );
  }

  Widget _buildNowPlayingCard(BuildContext context, Track track, bool isPlaying) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail with animated acoustic equalizer overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TrackArtwork(
                  albumArt: track.albumArt,
                  trackId: track.id,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              if (isPlaying)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: _AcousticSoundBars(controller: _barsController),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Title & Artist
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PLAYING',
                        style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      track.formatBadge,
                      style: AppTypography.labelSm(color: AppColors.outline).copyWith(
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  track.title,
                  style: AppTypography.bodySm(color: AppColors.primary).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track.artist,
                  style: AppTypography.labelSm(color: AppColors.onSurfaceVariant).copyWith(
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          Text(
            track.duration,
            style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserQueueList(
    BuildContext context,
    PlayerState state,
    List<Track> userQueued,
  ) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userQueued.length,
      onReorder: (oldIdx, newIdx) {
        HapticFeedback.selectionClick();
        final globalOldIdx = state.queue.indexOf(userQueued[oldIdx]);
        int globalNewIdx;
        if (newIdx < userQueued.length) {
          globalNewIdx = state.queue.indexOf(userQueued[newIdx]);
        } else {
          final lastTrack = userQueued.last;
          globalNewIdx = state.queue.indexOf(lastTrack) + 1;
        }
        if (globalOldIdx != -1 && globalNewIdx != -1) {
          context.read<PlayerBloc>().add(PlayerReorderQueue(globalOldIdx, globalNewIdx));
        }
      },
      itemBuilder: (context, index) {
        final track = userQueued[index];
        final globalIndex = state.queue.indexOf(track);

        return Container(
          key: ValueKey(track.id),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.12),
              width: 0.8,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TrackArtwork(
                albumArt: track.albumArt,
                trackId: track.id,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              track.title,
              style: AppTypography.bodySm(color: AppColors.primary).copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${track.artist} · ${track.duration}',
              style: AppTypography.labelSm(color: AppColors.onSurfaceVariant).copyWith(
                fontSize: 10.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                  color: AppColors.outline,
                  tooltip: 'Remove',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (globalIndex != -1) {
                      context.read<PlayerBloc>().add(PlayerRemoveFromQueue(globalIndex));
                    }
                  },
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: AppColors.outline,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<PlayerBloc>().add(PlayerPlayTrack(track));
            },
          ),
        );
      },
    );
  }

  Widget _buildAutoplayList(
    BuildContext context,
    PlayerState state,
    List<Track> autoplayQueued,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: autoplayQueued.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final track = autoplayQueued[index];
        final globalIndex = state.queue.indexOf(track);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.15),
              width: 0.8,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TrackArtwork(
                albumArt: track.albumArt,
                trackId: track.id,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    track.title,
                    style: AppTypography.bodySm(color: AppColors.primary).copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 12.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'AUTOPLAY',
                    style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '${track.artist} · ${track.mood} · ${track.duration}',
              style: AppTypography.labelSm(color: AppColors.onSurfaceVariant).copyWith(
                fontSize: 10.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.playlist_add_rounded, size: 20),
                  color: AppColors.secondary,
                  tooltip: 'Play Next',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.read<PlayerBloc>().add(PlayerAddToQueue(track, playNext: true));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.outline,
                  tooltip: 'Dismiss',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (globalIndex != -1) {
                      context.read<PlayerBloc>().add(PlayerRemoveFromQueue(globalIndex));
                    }
                  },
                ),
              ],
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<PlayerBloc>().add(PlayerPlayTrack(track));
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyQueueNote(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: AppTypography.labelSm(color: AppColors.outline).copyWith(
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Analyzing session taste vector & querying suggestions...',
            style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcousticSoundBars extends StatelessWidget {
  final AnimationController controller;

  const _AcousticSoundBars({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final val = controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar((12 + 10 * val).clamp(6.0, 22.0)),
            const SizedBox(width: 2.5),
            _bar((20 - 12 * val).clamp(6.0, 22.0)),
            const SizedBox(width: 2.5),
            _bar((10 + 14 * val).clamp(6.0, 22.0)),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
