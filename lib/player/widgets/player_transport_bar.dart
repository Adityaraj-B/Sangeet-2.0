import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/theme.dart';
import '../bloc/player_bloc.dart';

class PlayerTransportBar extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final bool isShuffle;
  final bool isRepeat;

  const PlayerTransportBar({
    super.key,
    required this.isPlaying,
    this.isBuffering = false,
    required this.isShuffle,
    required this.isRepeat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.12),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Shuffle Toggle
          _TransportIconButton(
            icon: Icons.shuffle_rounded,
            iconSize: 20,
            color: isShuffle ? AppColors.secondary : AppColors.onSurfaceVariant,
            tooltip: isShuffle ? 'Shuffle active' : 'Shuffle off',
            onTap: () {
              HapticFeedback.selectionClick();
              context.read<PlayerBloc>().add(const PlayerToggleShuffle());
            },
          ),

          // Skip Previous Track
          _TransportIconButton(
            icon: Icons.skip_previous_rounded,
            iconSize: 28,
            color: AppColors.onSurface,
            tooltip: 'Previous track',
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<PlayerBloc>().add(const PlayerPreviousTrack());
            },
          ),

          // Master Play/Pause Precision Button (64x64)
          _MasterPlayButton(
            isPlaying: isPlaying,
            isBuffering: isBuffering,
            onTap: () {
              HapticFeedback.mediumImpact();
              context.read<PlayerBloc>().add(const PlayerTogglePlayPause());
            },
          ),

          // Skip Next Track
          _TransportIconButton(
            icon: Icons.skip_next_rounded,
            iconSize: 28,
            color: AppColors.onSurface,
            tooltip: 'Next track',
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<PlayerBloc>().add(const PlayerNextTrack());
            },
          ),

          // Loop / Repeat Mode
          _TransportIconButton(
            icon: Icons.repeat_rounded,
            iconSize: 20,
            color: isRepeat ? AppColors.secondary : AppColors.onSurfaceVariant,
            tooltip: isRepeat ? 'Repeat active' : 'Repeat off',
            onTap: () {
              HapticFeedback.selectionClick();
              context.read<PlayerBloc>().add(const PlayerToggleRepeat());
            },
          ),
        ],
      ),
    );
  }
}

class _MasterPlayButton extends StatefulWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;

  const _MasterPlayButton({
    required this.isPlaying,
    this.isBuffering = false,
    required this.onTap,
  });

  @override
  State<_MasterPlayButton> createState() => _MasterPlayButtonState();
}

class _MasterPlayButtonState extends State<_MasterPlayButton> {
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
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 14,
                spreadRadius: 1,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.isBuffering
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.onPrimary,
                      ),
                    ),
                  )
                : Icon(
                    widget.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 32,
                    color: AppColors.onPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}

class _TransportIconButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _TransportIconButton({
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_TransportIconButton> createState() => _TransportIconButtonState();
}

class _TransportIconButtonState extends State<_TransportIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
