import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../library/screens/downloaded_songs_screen.dart';
import '../../library/screens/liked_songs_screen.dart';
import '../../main_layout/bloc/main_layout_bloc.dart';
import '../../models/models.dart';
import '../../repositories/download_repository.dart';
import '../../repositories/favorites_repository.dart';
import '../../repositories/playlist_repository.dart';
import '../../theme/theme.dart';

/// Interactive 3-column stats card showing real-time Playlists, Liked Songs,
/// and Downloaded count with one-tap navigation to each.
class ProfileStatsCard extends StatelessWidget {
  const ProfileStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Playlists
            Expanded(
              child: ValueListenableBuilder<List<Playlist>>(
                valueListenable: PlaylistRepository.instance.playlistsNotifier,
                builder: (context, playlists, _) {
                  return _StatItem(
                    label: 'Playlists',
                    count: playlists.length.toString(),
                    icon: Icons.queue_music_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<MainLayoutBloc>().add(
                            const NavigationTabChanged(NavTab.library),
                          );
                    },
                  );
                },
              ),
            ),
            _buildDivider(),

            // Liked Songs
            Expanded(
              child: ValueListenableBuilder<List<Track>>(
                valueListenable: FavoritesRepository.instance.likedSongsNotifier,
                builder: (context, likedSongs, _) {
                  return _StatItem(
                    label: 'Liked Songs',
                    count: likedSongs.length.toString(),
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFE57373),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LikedSongsScreen()),
                      );
                    },
                  );
                },
              ),
            ),
            _buildDivider(),

            // Downloads
            Expanded(
              child: ValueListenableBuilder<List<Track>>(
                valueListenable: DownloadRepository.instance.downloadedTracksNotifier,
                builder: (context, downloadedTracks, _) {
                  return _StatItem(
                    label: 'Downloads',
                    count: downloadedTracks.length.toString(),
                    icon: Icons.download_done_rounded,
                    iconColor: const Color(0xFF81C784),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DownloadedSongsScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return VerticalDivider(
      color: AppColors.outlineVariant.withValues(alpha: 0.18),
      thickness: 1,
      indent: 14,
      endIndent: 14,
      width: 1,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _StatItem({
    required this.label,
    required this.count,
    required this.icon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? AppColors.secondaryAccent,
            ),
            const SizedBox(height: 6),
            Text(
              count,
              style: AppTypography.titleLg(color: AppColors.primaryText).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
