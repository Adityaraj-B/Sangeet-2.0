import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats_card.dart';
import '../widgets/profile_library_shortcuts.dart';
import '../widgets/profile_playback_section.dart';
import '../widgets/profile_storage_section.dart';
import '../widgets/profile_account_section.dart';

/// Clean, modern profile screen designed with intuitive navigation, real-time
/// library statistics, and comprehensive music app settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        return _ProfileBody(state: state);
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final ProfileState state;

  const _ProfileBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top + 16;
    // Space for floating mini player + bottom nav bar
    const bottomPadding = 24.0 + 80.0 + 64.0;

    return SingleChildScrollView(
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
          ProfileHeader(state: state),
          const SizedBox(height: 16),
          const ProfileStatsCard(),
          const SizedBox(height: 20),
          const ProfileLibraryShortcuts(),
          const SizedBox(height: 20),
          ProfilePlaybackSection(state: state),
          const SizedBox(height: 20),
          ProfileStorageSection(state: state),
          const SizedBox(height: 20),
          ProfileAccountSection(state: state),
        ],
      ),
    );
  }
}
