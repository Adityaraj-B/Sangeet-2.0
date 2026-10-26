import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../playlist/screens/playlist_detail_screen.dart';
import '../../playlist/services/importer.dart';
import '../../repositories/playlist_repository.dart';
import '../../repositories/favorites_repository.dart';
import '../../repositories/download_repository.dart';
import '../../theme/theme.dart';
import '../bloc/library_bloc.dart';

class LibraryHeader extends StatelessWidget {
  final LibraryState state;

  const LibraryHeader({super.key, required this.state});

  void _showSortSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SORT LIBRARY BY',
                  style: AppTypography.labelSm(
                    color: AppColors.secondary,
                  ).copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...state.availableSorts.map((sortOpt) {
                  final isSelected = sortOpt == state.currentSort;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      sortOpt,
                      style:
                          AppTypography.bodyMd(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.primary,
                          ).copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.secondary,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.read<LibraryBloc>().add(
                        LibrarySortChanged(sortOpt),
                      );
                      Navigator.of(bottomSheetContext).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          title: Text(
            'New Curation Playlist',
            style: AppTypography.headlineMd(
              color: AppColors.primary,
            ).copyWith(fontSize: 20),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            style: AppTypography.bodyMd(color: AppColors.primary),
            decoration: InputDecoration(
              hintText: 'e.g., Midnight Binaural Solitude',
              hintStyle: AppTypography.bodySm(
                color: AppColors.onSurfaceVariant,
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.secondary),
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SpotifyImportScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.cloud_download_outlined,
                size: 16,
                color: AppColors.secondary,
              ),
              label: Text(
                'Import',
                style: AppTypography.labelMd(color: AppColors.secondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.labelMd(color: AppColors.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  context.read<LibraryBloc>().add(LibraryPlaylistCreated(name));
                  final newPl = PlaylistRepository.instance.createPlaylist(
                    name: name,
                  );
                  HapticFeedback.mediumImpact();
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PlaylistDetailScreen(playlistId: newPl.id),
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Meta Statistics
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARCHIVE INDEX',
                  style: AppTypography.labelSm(color: AppColors.secondary)
                      .copyWith(
                        letterSpacing: 2.0,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Library',
                  style: AppTypography.headlineLgMobile(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w300, letterSpacing: -0.5),
                ),
              ],
            ),
            AnimatedBuilder(
              animation: Listenable.merge([
                FavoritesRepository.instance.likedSongsNotifier,
                DownloadRepository.instance.totalStorageBytesNotifier,
              ]),
              builder: (context, _) {
                final count = FavoritesRepository.instance.likedSongsCount;
                final dlCount = DownloadRepository.instance.downloadedCount;
                final offlineSize =
                    DownloadRepository.instance.totalStorageFormatted;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      count > 0 ? '$count LIKED • ARCHIVE' : state.masterCount,
                      style: AppTypography.labelSm(
                        color: AppColors.secondary,
                      ).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dlCount > 0
                          ? '$offlineSize Offline ($dlCount)'
                          : 'Stored on device',
                      style: AppTypography.labelSm(
                        color: AppColors.outline,
                      ).copyWith(fontSize: 10.5, letterSpacing: 0.4),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Action & View Controls Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Sort Dropdown Button
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showSortSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.currentSort.toUpperCase(),
                      style: AppTypography.labelSm(color: AppColors.onSurface)
                          .copyWith(
                            fontSize: 9.5,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.expand_more_rounded,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),

            // Controls on the right: View Mode Switcher + Add Button
            Row(
              children: [
                // Grid / List View Toggle
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      _ViewToggleButton(
                        icon: Icons.grid_view_rounded,
                        isActive: state.isGridView,
                        onTap: () {
                          if (!state.isGridView) {
                            HapticFeedback.selectionClick();
                            context.read<LibraryBloc>().add(
                              const LibraryViewModeToggled(true),
                            );
                          }
                        },
                      ),
                      _ViewToggleButton(
                        icon: Icons.view_agenda_rounded,
                        isActive: !state.isGridView,
                        onTap: () {
                          if (state.isGridView) {
                            HapticFeedback.selectionClick();
                            context.read<LibraryBloc>().add(
                              const LibraryViewModeToggled(false),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Import Playlist Button (Spotify / YouTube)
                Tooltip(
                  message: 'Import from Spotify / YouTube',
                  child: Material(
                    color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SpotifyImportScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(alpha: 0.15),
                            width: 0.8,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.cloud_download_outlined,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // New Playlist Button (+)
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showCreatePlaylistDialog(context);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.surfaceContainerHighest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: isActive ? AppColors.primary : AppColors.outline,
          ),
        ),
      ),
    );
  }
}
