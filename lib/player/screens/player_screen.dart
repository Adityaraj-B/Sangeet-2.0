import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../bloc/player_bloc.dart';
import '../widgets/player_artwork_hero.dart';
import '../widgets/player_meta_actions.dart';
import '../widgets/player_waveform_scrubber.dart';
import '../widgets/player_transport_bar.dart';
// import '../widgets/player_output_volume_card.dart';
import '../widgets/player_secondary_deck.dart';
import '../widgets/queue_sheet.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  static bool _isOpen = false;

  /// Opens the full-screen [PlayerScreen] route with a smooth slide & fade animation.
  /// If the player is already opened, prevents pushing a duplicate route.
  static Future<void> open(BuildContext context) async {
    if (_isOpen) return;
    _isOpen = true;
    try {
      await Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder(
          settings: const RouteSettings(name: '/player'),
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, animation, secondaryAnimation) =>
              const PlayerScreen(),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        ),
      );
    } finally {
      _isOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        final track = state.currentTrack;
        if (track == null) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(
              child: Text(
                'No track playing',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          );
        }
        final topPad = MediaQuery.paddingOf(context).top;
        final bottomPad = MediaQuery.paddingOf(context).bottom;

        return Scaffold(
          backgroundColor: AppColors.surface,
          extendBodyBehindAppBar: true,
          appBar: _PlayerTopHeader(queue: state.queue),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              top: topPad + 64 + 10,
              bottom: bottomPad + 24,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Vinyl/Square Artwork Display
                PlayerArtworkHero(track: track),
                const SizedBox(height: 16),

                // 2. Track Title, Meta & Direct Actions (Favorite & Info)
                PlayerMetaActions(track: track, isLiked: state.isLiked),
                const SizedBox(height: 16),

                // 3. Interactive Acoustic Scrubber & Waveform Timeline
                PlayerWaveformScrubber(
                  progress: state.progress,
                  currentTime: state.currentTime,
                  totalTime: state.totalTime,
                ),
                const SizedBox(height: 16),

                // 4. Tactile Master Transport Controls
                PlayerTransportBar(
                  isPlaying: state.isPlaying,
                  isBuffering: state.isBuffering,
                  isShuffle: state.isShuffle,
                  isRepeat: state.isRepeat,
                ),
                const SizedBox(height: 16),

                // // 5. Output Device Selector & Master Volume Attenuator
                // const PlayerOutputVolumeCard(),
                // const SizedBox(height: 16),

                // 6. Editorial Secondary Navigation Deck (Notes, Playlist, Up Next)
                PlayerSecondaryDeck(track: track, queue: state.queue),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Alias for backwards compatibility
typedef MusicPlayerScreen = PlayerScreen;

class _PlayerTopHeader extends StatelessWidget implements PreferredSizeWidget {
  final List<Track> queue;

  const _PlayerTopHeader({required this.queue});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64 + topPad,
          padding: EdgeInsets.only(top: topPad, left: 16, right: 16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: AppColors.ghostBorderSubtle.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Minimize player button (keyboard_arrow_down)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(22),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 26,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),

              // Center Editorial Title
              Text(
                'NOW PLAYING',
                style:
                    AppTypography.labelSm(
                      color: AppColors.secondary.withValues(alpha: 0.9),
                    ).copyWith(
                      letterSpacing: 2.0,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
              ),

              // Right Actions: Queue & Profile Avatar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => showQueueBottomSheet(context),
                      borderRadius: BorderRadius.circular(22),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: Icon(
                            Icons.queue_music_rounded,
                            size: 20,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
