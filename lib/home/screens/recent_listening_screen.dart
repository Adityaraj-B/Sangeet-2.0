import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/track_artwork.dart';
import '../../main_layout/widgets/mini_player_bar.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../repositories/history_repository.dart';
import '../../repositories/favorites_repository.dart';
import '../../theme/theme.dart';
import '../widgets/add_to_playlist_dialog.dart';

class RecentListeningScreen extends StatelessWidget {
  const RecentListeningScreen({super.key});

  void _showClearHistoryDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          title: Text(
            'Clear history?',
            style: AppTypography.headlineMd(
              color: AppColors.primaryText,
            ).copyWith(fontSize: 17, fontWeight: FontWeight.w500),
          ),
          content: Text(
            'Your recent listening timeline will be wiped. Playlists and library stay untouched.',
            style: AppTypography.bodySm(
              color: AppColors.onSurfaceVariant,
            ).copyWith(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.labelMd(color: AppColors.onSurfaceVariant),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE57373),
              ),
              onPressed: () {
                HistoryRepository.instance.clearHistory();
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    content: Text(
                      'History cleared',
                      style: AppTypography.bodySm(color: AppColors.primaryText),
                    ),
                  ),
                );
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _playAll(
    BuildContext context,
    List<HistoryItem> items, {
    bool shuffle = false,
  }) {
    if (items.isEmpty) return;
    HapticFeedback.mediumImpact();
    final tracks = items.map((i) => i.track).toList();
    if (shuffle) tracks.shuffle();
    context.read<PlayerBloc>().add(PlayerPlayQueue(tracks, initialIndex: 0));
    PlayerScreen.open(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          shuffle ? 'Shuffling...' : 'Playing all...',
          style: AppTypography.bodySm(color: AppColors.primaryText),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 90.0;

    return Scaffold(
      backgroundColor: AppColors.neutralCanvas,
      body: Stack(
        children: [
          // Ambient radial glow — deep behind the header
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondaryAccent.withValues(alpha: 0.08),
                    AppColors.secondaryAccent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          ValueListenableBuilder<List<HistoryItem>>(
            valueListenable: HistoryRepository.instance.historyNotifier,
            builder: (context, items, _) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Premium App Bar ──────────────────────────────────
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 0,
                    backgroundColor: AppColors.neutralCanvas.withValues(
                      alpha: 0.92,
                    ),
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    leadingWidth: 64,
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).maybePop();
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.outlineVariant.withValues(
                                  alpha: 0.18,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 15,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      'Recent Listening',
                      style: AppTypography.bodyLg(color: AppColors.primaryText)
                          .copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                    ),
                    actions: [
                      if (items.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: GestureDetector(
                            onTap: () => _showClearHistoryDialog(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.outlineVariant.withValues(
                                    alpha: 0.18,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 17,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(1),
                      child: Container(
                        height: 0.5,
                        color: AppColors.outlineVariant.withValues(alpha: 0.1),
                      ),
                    ),
                  ),

                  // ── Stats + Action Header ────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${items.length}',
                                      style:
                                          AppTypography.headlineLgMobile(
                                            color: AppColors.primaryText,
                                          ).copyWith(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w300,
                                            letterSpacing: -1.5,
                                            height: 1,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'tracks in your timeline',
                                      style: AppTypography.bodySm(
                                        color: AppColors.onSurfaceVariant,
                                      ).copyWith(fontWeight: FontWeight.w300),
                                    ),
                                  ],
                                ),
                              ),
                              if (items.isNotEmpty)
                                Row(
                                  children: [
                                    _ActionButton(
                                      icon: Icons.shuffle_rounded,
                                      label: 'Shuffle',
                                      onTap: () => _playAll(
                                        context,
                                        items,
                                        shuffle: true,
                                      ),
                                      filled: false,
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.play_arrow_rounded,
                                      label: 'Play all',
                                      onTap: () => _playAll(context, items),
                                      filled: true,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 0.5,
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Empty State ──────────────────────────────────────
                  if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.outlineVariant.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.history_rounded,
                                  size: 30,
                                  color: AppColors.secondaryAccent.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Nothing played yet',
                                style:
                                    AppTypography.headlineMd(
                                      color: AppColors.primaryText,
                                    ).copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Songs you play will appear here.',
                                style: AppTypography.bodySm(
                                  color: AppColors.onSurfaceVariant,
                                ).copyWith(fontWeight: FontWeight.w300),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              GestureDetector(
                                onTap: () => Navigator.of(context).maybePop(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Explore music',
                                    style: AppTypography.bodyMd(
                                      color: AppColors.neutralCanvas,
                                    ).copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    // ── Track List ───────────────────────────────────
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _RecentListeningTile(
                            item: items[index],
                            index: index + 1,
                          ),
                          childCount: items.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Mini Player
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            child: const MiniPlayerBar(),
          ),
        ],
      ),
    );
  }
}

// ── Reusable action button ─────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled
              ? AppColors.secondaryAccent
              : AppColors.surfaceContainerHigh.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: filled
              ? null
              : Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  width: 0.8,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: filled
                  ? AppColors.neutralCanvas
                  : AppColors.secondaryAccent,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: filled ? AppColors.neutralCanvas : AppColors.primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Track tile ────────────────────────────────────────────────────────────
class _RecentListeningTile extends StatefulWidget {
  final HistoryItem item;
  final int index;

  const _RecentListeningTile({required this.item, required this.index});

  @override
  State<_RecentListeningTile> createState() => _RecentListeningTileState();
}

class _RecentListeningTileState extends State<_RecentListeningTile> {
  bool _pressed = false;

  void _playSong(BuildContext context) {
    HapticFeedback.lightImpact();
    context.read<PlayerBloc>().add(PlayerPlayTrack(widget.item.track));
    PlayerScreen.open(context);
  }

  void _showTrackMenu(BuildContext context) {
    HapticFeedback.selectionClick();
    final track = widget.item.track;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.15),
              width: 0.8,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Track identity strip
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: TrackArtwork(
                          albumArt: track.albumArt,
                          trackId: track.id,
                          fit: BoxFit.cover,
                          fallback: const Icon(
                            Icons.music_note_rounded,
                            size: 18,
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style:
                                  AppTypography.bodyMd(
                                    color: AppColors.primaryText,
                                  ).copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              track.artist,
                              style: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ).copyWith(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.12),
                    height: 16,
                  ),
                ),
                _SheetAction(
                  icon: Icons.playlist_play_rounded,
                  label: 'Play next',
                  onTap: () {
                    context.read<PlayerBloc>().add(
                      PlayerAddToQueue(track, playNext: true),
                    );
                    Navigator.of(sheetCtx).pop();
                  },
                ),
                _SheetAction(
                  icon: Icons.queue_music_rounded,
                  label: 'Add to queue',
                  onTap: () {
                    context.read<PlayerBloc>().add(
                      PlayerAddToQueue(track, playNext: false),
                    );
                    Navigator.of(sheetCtx).pop();
                  },
                ),
                _SheetAction(
                  icon: Icons.playlist_add_rounded,
                  label: 'Add to playlist',
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    showAddToPlaylistSheet(context, track);
                  },
                ),
                _SheetAction(
                  icon: FavoritesRepository.instance.isSongLiked(track.id)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: FavoritesRepository.instance.isSongLiked(track.id)
                      ? 'Remove from Liked Songs'
                      : 'Save to Liked Songs',
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    FavoritesRepository.instance.toggleLikeSong(track);
                  },
                ),
                _SheetAction(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove from history',
                  destructive: true,
                  onTap: () {
                    HistoryRepository.instance.removeTrack(track.id);
                    Navigator.of(sheetCtx).pop();
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.item.track;
    final coverArt = track.albumArt ?? '';

    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, playerState) {
        final isCurrentTrack = playerState.currentTrack?.id == track.id;
        final isPlaying = isCurrentTrack && playerState.isPlaying;

        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            if (isCurrentTrack) {
              context.read<PlayerBloc>().add(const PlayerTogglePlayPause());
            } else {
              _playSong(context);
            }
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: _pressed ? 0.6 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isCurrentTrack
                    ? AppColors.surfaceContainerHigh.withValues(alpha: 0.9)
                    : AppColors.surfaceContainerLow.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrentTrack
                      ? AppColors.secondaryAccent.withValues(alpha: 0.35)
                      : AppColors.outlineVariant.withValues(alpha: 0.1),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  // Index / active indicator
                  SizedBox(
                    width: 20,
                    child: isCurrentTrack
                        ? Icon(
                            isPlaying
                                ? Icons.equalizer_rounded
                                : Icons.play_arrow_rounded,
                            size: 15,
                            color: AppColors.secondaryAccent,
                          )
                        : Text(
                            '${widget.index}',
                            style:
                                AppTypography.labelSm(
                                  color: AppColors.outline,
                                ).copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                  const SizedBox(width: 10),

                  // Album art
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        TrackArtwork(
                          albumArt: coverArt,
                          trackId: track.id,
                          fit: BoxFit.cover,
                          fallback: const Icon(
                            Icons.music_note_rounded,
                            size: 18,
                            color: AppColors.outline,
                          ),
                        ),
                        if (isPlaying)
                          Container(
                            color: Colors.black.withValues(alpha: 0.4),
                            child: const Center(
                              child: Icon(
                                Icons.equalizer_rounded,
                                color: AppColors.secondaryAccent,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title + artist + badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style:
                              AppTypography.bodyMd(
                                color: isCurrentTrack
                                    ? AppColors.secondaryAccent
                                    : AppColors.primaryText,
                              ).copyWith(
                                fontWeight: isCurrentTrack
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                fontSize: 14,
                                letterSpacing: -0.1,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                track.artist,
                                style:
                                    AppTypography.bodySm(
                                      color: AppColors.onSurfaceVariant,
                                    ).copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryAccent.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                track.formatBadge.toUpperCase(),
                                style:
                                    AppTypography.labelSm(
                                      color: AppColors.secondaryAccent,
                                    ).copyWith(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Time + duration
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.item.timeAgo,
                        style: AppTypography.labelSm(
                          color: AppColors.secondaryAccent.withValues(
                            alpha: 0.8,
                          ),
                        ).copyWith(fontSize: 10, letterSpacing: 0.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.duration,
                        style: AppTypography.labelSm(
                          color: AppColors.outline,
                        ).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),

                  // More button
                  GestureDetector(
                    onTap: () => _showTrackMenu(context),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 0, 6),
                      child: Icon(
                        Icons.more_vert_rounded,
                        size: 17,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
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

// ── Bottom sheet action row ───────────────────────────────────────────────
class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFE57373) : AppColors.primaryText;
    final iconColor = destructive
        ? const Color(0xFFE57373)
        : AppColors.secondaryAccent;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, size: 20, color: iconColor),
      title: Text(
        label,
        style: AppTypography.bodyMd(color: color).copyWith(fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}
