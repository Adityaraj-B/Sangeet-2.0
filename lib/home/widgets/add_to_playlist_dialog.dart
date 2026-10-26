import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../components/playlist_skeleton.dart';
import '../../components/track_artwork.dart';
import '../../models/models.dart';
import '../../repositories/playlist_repository.dart';
import '../../repositories/favorites_repository.dart';
import '../../theme/theme.dart';

void showAddToPlaylistSheet(BuildContext context, Track track) {
  HapticFeedback.selectionClick();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.neutralCanvas,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              PlaylistRepository.instance.playlistsNotifier,
              PlaylistRepository.instance.isLoadingNotifier,
            ]),
            builder: (context, _) {
              final playlists = PlaylistRepository.instance.playlists;
              final isLoading = PlaylistRepository.instance.isLoading;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add to Playlist',
                                style: AppTypography.headlineMd(
                                  color: AppColors.primaryText,
                                ).copyWith(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${track.title} • ${track.artist}',
                                style: AppTypography.bodySm(
                                  color: AppColors.onSurfaceVariant,
                                ).copyWith(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.outline,
                          ),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Colors.white10),

                  // Liked Songs tile
                  AnimatedBuilder(
                    animation: FavoritesRepository.instance.likedSongIdsNotifier,
                    builder: (context, _) {
                      final isLiked = FavoritesRepository.instance.isSongLiked(track.id);
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isLiked
                                ? AppColors.secondary.withValues(alpha: 0.2)
                                : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isLiked
                                ? AppColors.secondary
                                : AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          isLiked ? 'Remove from Liked Songs' : 'Save to Liked Songs',
                          style: AppTypography.bodyMd(
                            color: isLiked ? AppColors.secondary : Colors.white,
                          ).copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        subtitle: Text(
                          'Stored permanently on device',
                          style: AppTypography.labelSm(
                            color: AppColors.onSurfaceVariant,
                          ).copyWith(fontSize: 11),
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          FavoritesRepository.instance.toggleLikeSong(track);
                          Navigator.of(sheetCtx).pop();
                        },
                      );
                    },
                  ),

                  const Divider(height: 1, color: Colors.white10),

                  // Create new playlist tile
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.secondaryAccent,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Create New Playlist',
                      style: AppTypography.bodyMd(
                        color: AppColors.secondaryAccent,
                      ).copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      _showCreateAndAddDialog(context, track);
                    },
                  ),

                  const Divider(height: 1, color: Colors.white10),                  // Playlists List
                  Flexible(
                    child: isLoading && playlists.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                ListPlaylistTileSkeleton(),
                                SizedBox(height: 8),
                                ListPlaylistTileSkeleton(),
                              ],
                            ),
                          )
                        : playlists.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 24,
                                ),
                                child: Text(
                                  'No playlists found. Tap "Create New Playlist" above to start.',
                                  style: AppTypography.bodySm(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: playlists.length,
                                itemBuilder: (context, index) {
                                  final pl = playlists[index];
                                  final isAlreadyAdded =
                                      pl.tracks.any((t) => t.id == track.id);

                                  return ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(8),
                                        image: safeImageProvider(pl.coverUrl) != null
                                            ? DecorationImage(
                                                image: safeImageProvider(pl.coverUrl)!,
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: safeImageProvider(pl.coverUrl) == null
                                          ? const Icon(
                                              Icons.queue_music_rounded,
                                              color: AppColors.outline,
                                              size: 18,
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      pl.name,
                                      style: AppTypography.bodyMd(
                                        color: AppColors.primaryText,
                                      ).copyWith(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${pl.tracks.length} tracks',
                                      style: AppTypography.labelSm(
                                        color: AppColors.onSurfaceVariant,
                                      ).copyWith(fontSize: 11),
                                    ),
                                    trailing: isAlreadyAdded
                                        ? const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.secondaryAccent,
                                            size: 18,
                                          )
                                        : null,
                                    onTap: isAlreadyAdded
                                        ? null
                                        : () {
                                            PlaylistRepository.instance
                                                .addTrackToPlaylist(pl.id, track);
                                            HapticFeedback.mediumImpact();
                                            Navigator.of(sheetCtx).pop();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                backgroundColor:
                                                    AppColors.surfaceContainerHigh,
                                                behavior: SnackBarBehavior.floating,
                                                margin: const EdgeInsets.fromLTRB(
                                                  16,
                                                  0,
                                                  16,
                                                  12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                content: Text(
                                                  'Added "${track.title}" to ${pl.name}',
                                                  style: AppTypography.bodySm(
                                                    color: AppColors.primaryText,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

void _showCreateAndAddDialog(BuildContext context, Track track) {
  final nameCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        title: Text(
          'New Playlist',
          style: AppTypography.headlineMd(
            color: AppColors.primaryText,
          ).copyWith(fontSize: 18),
        ),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: AppTypography.bodyMd(color: AppColors.primaryText),
          decoration: InputDecoration(
            hintText: 'Playlist Name',
            hintStyle: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.secondaryAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelMd(color: AppColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryAccent,
              foregroundColor: AppColors.neutralCanvas,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final newPl = PlaylistRepository.instance.createPlaylist(
                  name: name,
                  initialTracks: [track],
                );
                HapticFeedback.mediumImpact();
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
                      'Created "${newPl.name}" and added "${track.title}"',
                      style: AppTypography.bodySm(color: AppColors.primaryText),
                    ),
                  ),
                );
              } else {
                Navigator.of(dialogCtx).pop();
              }
            },
            child: const Text('Create & Add'),
          ),
        ],
      );
    },
  );
}
