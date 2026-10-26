import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/track_artwork.dart';
import '../../library/screens/downloaded_songs_screen.dart';
import '../../library/screens/liked_songs_screen.dart';
import '../../models/models.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../repositories/download_repository.dart';
import '../../repositories/favorites_repository.dart';
import '../../repositories/history_repository.dart';
import '../../theme/theme.dart';

/// Grouped section providing quick shortcuts to user's Liked Songs,
/// Downloaded Songs, and Listening History.
class ProfileLibraryShortcuts extends StatelessWidget {
  const ProfileLibraryShortcuts({super.key});

  void _showHistorySheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ValueListenableBuilder<List<HistoryItem>>(
              valueListenable: HistoryRepository.instance.historyNotifier,
              builder: (context, historyItems, _) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Listening History',
                            style: AppTypography.titleLg(color: AppColors.primaryText),
                          ),
                          Text(
                            '${historyItems.length} songs',
                            style: AppTypography.labelSm(color: AppColors.outline),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: AppColors.outlineVariant, height: 1),
                    Expanded(
                      child: historyItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.history_rounded,
                                    size: 48,
                                    color: AppColors.outline,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No recently played tracks yet',
                                    style: AppTypography.bodyMd(color: AppColors.outline),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: historyItems.length,
                              separatorBuilder: (sepContext, sepIndex) => const Divider(
                                color: AppColors.outlineVariant,
                                height: 1,
                                indent: 72,
                              ),
                              itemBuilder: (itemContext, index) {
                                final item = historyItems[index];
                                final track = item.track;
                                final artUrl = track.albumArt;
                                return ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: TrackArtwork(
                                      albumArt: artUrl,
                                      trackId: track.id,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      fallback: Container(
                                        width: 48,
                                        height: 48,
                                        color: AppColors.surfaceContainerHigh,
                                        child: const Icon(
                                          Icons.music_note_rounded,
                                          color: AppColors.outline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    track.title,
                                    style: AppTypography.bodyMd(
                                      color: AppColors.primaryText,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${track.artist} · ${item.timeAgo}',
                                    style: AppTypography.bodySm(color: AppColors.outline),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: AppColors.secondaryAccent,
                                      size: 32,
                                    ),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      context.read<PlayerBloc>().add(
                                            PlayerPlayQueue(
                                              historyItems
                                                  .map((h) => h.track)
                                                  .toList(),
                                              initialIndex: index,
                                            ),
                                          );
                                      Navigator.of(bottomSheetContext).pop();
                                      PlayerScreen.open(context);
                                    },
                                  ),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context.read<PlayerBloc>().add(
                                          PlayerPlayQueue(
                                            historyItems
                                                .map((h) => h.track)
                                                .toList(),
                                            initialIndex: index,
                                          ),
                                        );
                                    Navigator.of(bottomSheetContext).pop();
                                    PlayerScreen.open(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'MY MUSIC & ACTIVITY',
            style: AppTypography.labelSm(color: AppColors.outline).copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.16),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Liked Songs
              ValueListenableBuilder<List<Track>>(
                valueListenable: FavoritesRepository.instance.likedSongsNotifier,
                builder: (context, likedSongs, _) {
                  return _ShortcutTile(
                    title: 'Liked Songs',
                    subtitle: '${likedSongs.length} tracks in favorites',
                    icon: Icons.favorite_rounded,
                    iconBgColor: const Color(0xFFE57373).withValues(alpha: 0.15),
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
              _buildDivider(),

              // Downloaded Songs
              ValueListenableBuilder<List<Track>>(
                valueListenable: DownloadRepository.instance.downloadedTracksNotifier,
                builder: (context, downloadedTracks, _) {
                  final storageText = DownloadRepository.instance.totalStorageFormatted;
                  return _ShortcutTile(
                    title: 'Downloaded Songs',
                    subtitle: '${downloadedTracks.length} offline tracks · $storageText',
                    icon: Icons.download_for_offline_rounded,
                    iconBgColor: const Color(0xFF81C784).withValues(alpha: 0.15),
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
              _buildDivider(),

              // Listening History
              ValueListenableBuilder<List<HistoryItem>>(
                valueListenable: HistoryRepository.instance.historyNotifier,
                builder: (context, history, _) {
                  return _ShortcutTile(
                    title: 'Listening History',
                    subtitle: history.isEmpty
                        ? 'No recently played tracks'
                        : '${history.length} recently played tracks',
                    icon: Icons.history_rounded,
                    iconBgColor: AppColors.secondaryAccent.withValues(alpha: 0.15),
                    iconColor: AppColors.secondaryAccent,
                    onTap: () => _showHistorySheet(context),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppColors.outlineVariant.withValues(alpha: 0.14),
      height: 1,
      indent: 56,
      endIndent: 16,
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ShortcutTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSm(color: AppColors.primaryText).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm(color: AppColors.outline),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
