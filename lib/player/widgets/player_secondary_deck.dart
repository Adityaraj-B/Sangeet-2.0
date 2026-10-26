import 'package:flutter/material.dart';
import '../../home/widgets/add_to_playlist_dialog.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import 'queue_sheet.dart';
import 'track_artists_sheet.dart';

class PlayerSecondaryDeck extends StatelessWidget {
  final Track? track;
  final List<Track> queue;

  const PlayerSecondaryDeck({
    super.key,
    this.track,
    required this.queue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. ARTISTS
        Expanded(
          child: _DeckButton(
            icon: Icons.person_rounded,
            label: 'ARTISTS',
            onTap: () {
              if (track != null) {
                showTrackArtistsSheet(context, track!);
              }
            },
          ),
        ),
        const SizedBox(width: 8),

        // 2. ADD TO PLAYLIST
        Expanded(
          child: _DeckButton(
            icon: Icons.playlist_add_rounded,
            label: 'PLAYLIST',
            onTap: () {
              if (track != null) {
                showAddToPlaylistSheet(context, track!);
              }
            },
          ),
        ),
        const SizedBox(width: 8),

        // 3. UP NEXT (with badge count)
        Expanded(
          child: _DeckButton(
            icon: Icons.queue_music_rounded,
            label: 'UP NEXT',
            badgeCount: queue.length.toString(),
            onTap: () => showQueueBottomSheet(context),
          ),
        ),
      ],
    );
  }
}

class _DeckButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? badgeCount;
  final VoidCallback onTap;

  const _DeckButton({
    required this.icon,
    required this.label,
    this.badgeCount,
    required this.onTap,
  });

  @override
  State<_DeckButton> createState() => _DeckButtonState();
}

class _DeckButtonState extends State<_DeckButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: _pressed ? AppColors.surfaceContainer : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _pressed
                  ? AppColors.secondary.withValues(alpha: 0.3)
                  : AppColors.outlineVariant.withValues(alpha: 0.12),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                  if (widget.badgeCount != null)
                    Positioned(
                      top: -4,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.badgeCount!,
                          style: AppTypography.labelSm(color: AppColors.onSecondary).copyWith(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: AppTypography.labelSm(color: AppColors.onSurface).copyWith(
                  fontSize: 9.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
