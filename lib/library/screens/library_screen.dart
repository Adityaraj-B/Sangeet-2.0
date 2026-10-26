import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/theme.dart';
import '../bloc/library_bloc.dart';
import '../widgets/library_header.dart';
import '../widgets/library_filter_pills.dart';
import '../widgets/playlists_grid_section.dart';
import '../widgets/recent_playback_section.dart';
import '../widgets/followed_masters_section.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LibraryBloc>(
      create: (_) => LibraryBloc(),
      child: const _LibraryScreenView(),
    );
  }
}

class _LibraryScreenView extends StatelessWidget {
  const _LibraryScreenView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        return _LibraryBody(state: state);
      },
    );
  }
}

class _LibraryBody extends StatelessWidget {
  final LibraryState state;

  const _LibraryBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top + 12;
    // Space for floating mini-player + bottom navigation bar
    const bottomPadding = 24.0 + 80.0 + 64.0;

    return Stack(
      children: [
        // Subtle Ambient Glow at the top
        Positioned(
          top: -120,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),
        ),

        // Scrollable Content
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: topPadding,
            bottom: bottomPadding,
            left: 20,
            right: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header & Meta Statistics + Controls
              LibraryHeader(state: state),
              const SizedBox(height: 16),

              // 2. Horizontal Filter Pills
              LibraryFilterPills(state: state),
              const SizedBox(height: 18),

              // 4. Playlists Section (Curated Collections)
              PlaylistsGridSection(state: state),
              const SizedBox(height: 24),

              // 5. Recent Songs Quick History
              RecentPlaybackSection(tracks: state.recentTracks),
              const SizedBox(height: 24),

              // 6. Followed Masters & Composers Carousel
              FollowedMastersSection(artists: state.followedArtists),
            ],
          ),
        ),
      ],
    );
  }
}
