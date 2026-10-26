import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../models/models.dart';
import '../../components/track_artwork.dart';
import '../../theme/theme.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  void _openPlayer(BuildContext context) {
    PlayerScreen.open(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PlayerBloc, PlayerState, Track?>(
      selector: (state) => state.currentTrack,
      builder: (context, currentTrack) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.35),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: currentTrack == null
              ? const SizedBox.shrink()
              : Padding(
                  key: const ValueKey('mini_player_visible'),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _MiniPlayerSurface(onTap: () => _openPlayer(context)),
                ),
        );
      },
    );
  }
}

class _MiniPlayerSurface extends StatelessWidget {
  final VoidCallback onTap;

  const _MiniPlayerSurface({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.radiusFull,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppColors.secondaryAccent.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadii.radiusFull,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceContainerHigh.withValues(alpha: 0.35),
                  AppColors.surfaceContainerHigh.withValues(alpha: 0.15),
                  AppColors.surfaceContainerHigh.withValues(alpha: 0.05),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: AppRadii.radiusFull,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.2,
              ),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 15,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(999),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Row(
                      children: [
                        BlocBuilder<PlayerBloc, PlayerState>(
                          buildWhen: (prev, curr) =>
                              prev.currentTrack != curr.currentTrack ||
                              prev.isPlaying != curr.isPlaying,
                          builder: (context, state) {
                            return _AlbumThumb(
                              track: state.currentTrack!,
                              isPlaying: state.isPlaying,
                            );
                          },
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: BlocSelector<PlayerBloc, PlayerState, Track>(
                            selector: (state) => state.currentTrack!,
                            builder: (context, track) {
                              return _TrackDetails(track: track);
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        BlocSelector<PlayerBloc, PlayerState, bool>(
                          selector: (state) => state.isLiked,
                          builder: (context, isLiked) {
                            return _LikeButton(
                              isLiked: isLiked,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.read<PlayerBloc>().add(
                                  const PlayerToggleLike(),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        BlocSelector<PlayerBloc, PlayerState, bool>(
                          selector: (state) => state.isPlaying,
                          builder: (context, isPlaying) {
                            return _PlayPauseButton(
                              isPlaying: isPlaying,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                context.read<PlayerBloc>().add(
                                  const PlayerTogglePlayPause(),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 28,
                  right: 28,
                  bottom: 0,
                  child: BlocSelector<PlayerBloc, PlayerState, double>(
                    selector: (state) => state.progress,
                    builder: (context, progress) {
                      return _ProgressScrubber(
                        progress: progress,
                        onSeek: (p) =>
                            context.read<PlayerBloc>().add(PlayerSeek(p)),
                      );
                    },
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

class _TrackDetails extends StatelessWidget {
  final Track track;

  const _TrackDetails({required this.track});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.centerLeft,
          children: [...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey('${track.title}_${track.artist}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            track.title,
            style: AppTypography.bodyMd(
              color: AppColors.primaryText,
            ).copyWith(fontWeight: FontWeight.w600, fontSize: 15),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            track.artist,
            style: AppTypography.bodySm(
              color: AppColors.primaryText.withValues(alpha: 0.7),
            ).copyWith(fontWeight: FontWeight.w400),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _AlbumThumb extends StatefulWidget {
  final Track track;
  final bool isPlaying;

  const _AlbumThumb({required this.track, required this.isPlaying});

  @override
  State<_AlbumThumb> createState() => _AlbumThumbState();
}

class _AlbumThumbState extends State<_AlbumThumb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.isPlaying) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AlbumThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.isPlaying ? 1.0 : 0.92,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 0.4,
            ).animate(_pulseController),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryAccent.withValues(alpha: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryAccent.withValues(alpha: 0.6),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              width: 46,
              height: 46,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: TrackArtwork(
                  key: ValueKey(widget.track.albumArt ?? widget.track.id),
                  albumArt: widget.track.albumArt,
                  trackId: widget.track.id,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                  fallback: Container(
                    key: const ValueKey('placeholder_art'),
                    color: AppColors.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.5),
                radius: 0.8,
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  final bool isLiked;
  final VoidCallback onTap;

  const _LikeButton({required this.isLiked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.elasticOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey<bool>(isLiked),
              size: 22,
              color: isLiked
                  ? AppColors.secondaryAccent
                  : AppColors.primaryText.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayPauseButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey<bool>(isPlaying),
                  size: 24,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressScrubber extends StatefulWidget {
  final double progress;
  final ValueChanged<double> onSeek;

  const _ProgressScrubber({required this.progress, required this.onSeek});

  @override
  State<_ProgressScrubber> createState() => _ProgressScrubberState();
}

class _ProgressScrubberState extends State<_ProgressScrubber> {
  double? _dragValue;

  void _handleUpdate(double dx, double maxWidth) {
    if (maxWidth <= 0) return;
    final fraction = (dx / maxWidth).clamp(0.0, 1.0);
    setState(() => _dragValue = fraction);
    widget.onSeek(fraction);
  }

  @override
  Widget build(BuildContext context) {
    final isScrubbing = _dragValue != null;
    final effectiveProgress = (_dragValue ?? widget.progress).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final barHeight = isScrubbing ? 6.0 : 3.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            HapticFeedback.selectionClick();
            _handleUpdate(d.localPosition.dx, maxWidth);
          },
          onHorizontalDragUpdate: (d) =>
              _handleUpdate(d.localPosition.dx, maxWidth),
          onHorizontalDragEnd: (_) => setState(() => _dragValue = null),
          onHorizontalDragCancel: () => setState(() => _dragValue = null),
          onTapDown: (d) {
            HapticFeedback.selectionClick();
            _handleUpdate(d.localPosition.dx, maxWidth);
          },
          onTapUp: (_) => setState(() => _dragValue = null),
          child: SizedBox(
            height: 20,
            width: double.infinity,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutQuint,
                    height: barHeight,
                    width: maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.black.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: isScrubbing
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    curve: Curves.easeOutQuint,
                    height: barHeight,
                    width: maxWidth * effectiveProgress,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondaryAccent.withValues(alpha: 0.7),
                          AppColors.secondaryAccent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondaryAccent.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
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

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
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
        scale: _pressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        child: widget.child,
      ),
    );
  }
}
