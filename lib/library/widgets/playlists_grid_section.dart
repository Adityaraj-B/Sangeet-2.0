import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/playlist_skeleton.dart';
import '../../components/track_artwork.dart';
import '../../playlist/screens/playlist_detail_screen.dart';
import '../../models/models.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../repositories/playlist_repository.dart';
import '../../repositories/favorites_repository.dart';
import '../screens/liked_songs_screen.dart';
import '../../insights/screens/insights_tab_screen.dart';
import '../../insights/services/insight_service.dart';
import '../../theme/theme.dart';
import '../../playlist/services/importer.dart';
import '../bloc/library_bloc.dart';

class PlaylistsGridSection extends StatelessWidget {
  final LibraryState state;

  const PlaylistsGridSection({super.key, required this.state});

  void _showCreateDialog(BuildContext context) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'New Playlist',
            style: AppTypography.headlineMd(color: AppColors.primaryText).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            style: AppTypography.bodyMd(color: AppColors.primaryText),
            decoration: InputDecoration(
              hintText: 'e.g., Midnight Binaural Solitude',
              hintStyle: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  final newPl = PlaylistRepository.instance.createPlaylist(name: name);
                  HapticFeedback.mediumImpact();
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailScreen(playlistId: newPl.id),
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
    return AnimatedBuilder(
      animation: Listenable.merge([
        PlaylistRepository.instance.playlistsNotifier,
        PlaylistRepository.instance.isLoadingNotifier,
        PlaylistRepository.instance.errorNotifier,
        FavoritesRepository.instance.likedPlaylistsNotifier,
        FavoritesRepository.instance.likedSongsNotifier,
        FavoritesRepository.instance.likedPlaylistIdsNotifier,
      ]),
      builder: (context, _) {
        final isLoading = PlaylistRepository.instance.isLoading;
        final error = PlaylistRepository.instance.error;
        final allDynamicPlaylists = PlaylistRepository.instance.playlists;

        final isLikedPlaylistsFilter = state.selectedFilter == 'Liked Playlists';
        final dynamicPlaylists = isLikedPlaylistsFilter
            ? allDynamicPlaylists
                .where((p) => FavoritesRepository.instance.isPlaylistLiked(p.id))
                .toList()
            : allDynamicPlaylists;

        final totalCount = dynamicPlaylists.length;

        final headerTitle =
            isLikedPlaylistsFilter ? 'LIKED PLAYLISTS' : 'YOUR PLAYLISTS';

        final badgeText = isLoading
            ? 'SYNCING...'
            : error != null
                ? 'SYNC ERROR'
                : isLikedPlaylistsFilter
                    ? '$totalCount FAVORITED'
                    : '$totalCount ACTIVE LISTS';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pinned Liked Songs Card & Listening Insights Card (always shown when browsing all playlists)
            if (!isLikedPlaylistsFilter) ...[
              const _PinnedLikedSongsCard(),
              const SizedBox(height: 12),
              const _PinnedInsightsCard(),
              const SizedBox(height: 20),
            ],

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  headerTitle,
                  style: AppTypography.labelMd(color: AppColors.primary).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  badgeText,
                  style: AppTypography.labelSm(
                    color: error != null ? AppColors.error : AppColors.outline,
                  ).copyWith(
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // States: Loading, Error, Empty, Loaded
            if (isLoading && dynamicPlaylists.isEmpty)
              _buildSkeleton(context, state.isGridView)
            else if (error != null && dynamicPlaylists.isEmpty)
              LibraryPlaylistsErrorView(
                error: error,
                onRetry: () => PlaylistRepository.instance.retryFetch(),
              )
            else if (dynamicPlaylists.isEmpty && isLikedPlaylistsFilter)
              _buildEmptyLikedPlaylistsView(context)
            else if (dynamicPlaylists.isEmpty)
              LibraryPlaylistsEmptyView(
                onCreate: () => _showCreateDialog(context),
                onImport: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SpotifyImportScreen(),
                    ),
                  );
                },
              )
            else
              _buildFromDynamicPlaylists(
                context,
                dynamicPlaylists,
                state.isGridView,
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyLikedPlaylistsView(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.1),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.secondary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Liked Playlists Yet',
            style: AppTypography.headlineMd(color: AppColors.primaryText).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the heart icon on any playlist to save it here for fast offline access.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context, bool isGridView) {
    if (isGridView) {
      return GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) => const GridPlaylistCardSkeleton(),
      );
    } else {
      return ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => const ListPlaylistTileSkeleton(),
      );
    }
  }

  Widget _buildFromDynamicPlaylists(
    BuildContext context,
    List<Playlist> playlists,
    bool isGridView,
  ) {
    if (isGridView) {
      return GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: playlists.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return _DynamicPlaylistCard(playlist: playlist);
        },
      );
    } else {
      return ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: playlists.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return _DynamicPlaylistListTile(playlist: playlist);
        },
      );
    }
  }
}

// ── Pinned Liked Songs Hero Card ──────────────────────────────────────────────
class _PinnedLikedSongsCard extends StatelessWidget {
  const _PinnedLikedSongsCard();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        FavoritesRepository.instance.likedSongsNotifier,
        FavoritesRepository.instance.likedSongIdsNotifier,
      ]),
      builder: (context, _) {
        final count = FavoritesRepository.instance.likedSongsCount;
        final songs = FavoritesRepository.instance.likedSongs;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LikedSongsScreen(),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4A1054),
                  Color(0xFF280B38),
                  Color(0xFF140D1F),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Heart Icon Tile
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF7B1FA2),
                        Color(0xFF4A148C),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'COLLECTION',
                              style: AppTypography.labelSm(
                                color: AppColors.secondary,
                              ).copyWith(
                                fontSize: 8.5,
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'STORED ON DEVICE',
                            style: AppTypography.labelSm(
                              color: AppColors.onSurfaceVariant,
                            ).copyWith(fontSize: 8.5, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Liked Songs',
                        style: AppTypography.headlineMd(
                          color: Colors.white,
                        ).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count == 0
                            ? 'No songs saved yet • Tap to add'
                            : '$count ${count == 1 ? 'song' : 'songs'} preserved',
                        style: AppTypography.bodySm(
                          color: AppColors.onSurfaceVariant,
                        ).copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Play Action or Chevron
                if (count > 0)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.read<PlayerBloc>().add(
                            PlayerPlayQueue(songs, initialIndex: 0),
                          );
                      PlayerScreen.open(context);
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.onSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Pinned Listening Insights Hero Card ───────────────────────────────────────
class _PinnedInsightsCard extends StatelessWidget {
  const _PinnedInsightsCard();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ListeningInsightsService.instance,
      builder: (context, _) {
        final summary = ListeningInsightsService.instance.computeSummary();
        final streak = summary.currentStreakDays;
        final persona = summary.listenerPersona;
        final songsPlayed = summary.totalSongsPlayed;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const InsightsTabScreen(),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF381F14),
                  Color(0xFF221610),
                  Color(0xFF141210),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD4845A).withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4845A).withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Analytics Icon Tile
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE29267),
                        Color(0xFF9E542C),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.insights_rounded,
                      color: Color(0xFFFEFAE0),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4845A).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ANALYTICS',
                              style: AppTypography.labelSm(
                                color: const Color(0xFFD4845A),
                              ).copyWith(
                                fontSize: 8.5,
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            streak > 0 ? '$streak-DAY STREAK' : 'SONIC TELEMETRY',
                            style: AppTypography.labelSm(
                              color: AppColors.onSurfaceVariant,
                            ).copyWith(fontSize: 8.5, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Listening Insights',
                        style: AppTypography.headlineMd(
                          color: Colors.white,
                        ).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        persona.isNotEmpty
                            ? '$persona • $songsPlayed played'
                            : 'Personal taste DNA & dynamic autoplay stats',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm(
                          color: AppColors.onSurfaceVariant,
                        ).copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Chevron icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4845A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Color(0xFFD4845A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Dynamic Playlist Card (opens PlaylistDetailScreen) ───────────────────────
class _DynamicPlaylistCard extends StatefulWidget {
  final Playlist playlist;
  const _DynamicPlaylistCard({required this.playlist});

  @override
  State<_DynamicPlaylistCard> createState() => _DynamicPlaylistCardState();
}

class _DynamicPlaylistCardState extends State<_DynamicPlaylistCard> {
  bool _pressed = false;

  void _openDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(playlistId: widget.playlist.id),
      ),
    );
  }

  void _playPlaylist(BuildContext context) {
    if (widget.playlist.tracks.isEmpty) {
      _openDetail(context);
      return;
    }
    HapticFeedback.mediumImpact();
    context.read<PlayerBloc>().add(
          PlayerPlayQueue(widget.playlist.tracks, initialIndex: 0),
        );
    PlayerScreen.open(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Text(
          'Playing curation: ${widget.playlist.name}',
          style: AppTypography.bodySm(color: AppColors.primaryText),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cover = widget.playlist.coverUrl;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _openDetail(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Square Thumbnail Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _pressed
                        ? AppColors.secondary.withValues(alpha: 0.35)
                        : AppColors.outlineVariant.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeImage(
                      urlOrPath: cover,
                      fit: BoxFit.cover,
                      fallback: Container(
                        color: AppColors.surfaceContainerLow,
                        child: const Icon(
                          Icons.queue_music_rounded,
                          color: AppColors.outline,
                        ),
                      ),
                    ),
                    if (_pressed)
                      Container(color: Colors.black.withValues(alpha: 0.2)),

                    // Telemetry Pill (Top-Left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest.withValues(
                            alpha: 0.82,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.25),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          widget.playlist.telemetryBadge.toUpperCase(),
                          style: AppTypography.labelSm(
                            color: AppColors.secondary,
                          ).copyWith(
                            fontSize: 8.5,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Quick Play Button (Top-Right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _playPlaylist(context),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceContainerLowest.withValues(
                              alpha: 0.85,
                            ),
                            border: Border.all(
                              color: AppColors.secondaryAccent.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: AppColors.secondaryAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Title & Subtitle Info
            Text(
              widget.playlist.name,
              style: AppTypography.bodyMd(color: AppColors.primary).copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              '${widget.playlist.tracks.length} tracks · ${widget.playlist.formattedDuration}',
              style: AppTypography.labelSm(
                color: AppColors.onSurfaceVariant,
              ).copyWith(fontSize: 10.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dynamic Playlist List Tile (opens PlaylistDetailScreen) ──────────────────
class _DynamicPlaylistListTile extends StatefulWidget {
  final Playlist playlist;
  const _DynamicPlaylistListTile({required this.playlist});

  @override
  State<_DynamicPlaylistListTile> createState() =>
      _DynamicPlaylistListTileState();
}

class _DynamicPlaylistListTileState extends State<_DynamicPlaylistListTile> {
  bool _pressed = false;

  void _openDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(playlistId: widget.playlist.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cover = widget.playlist.coverUrl;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _openDetail(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.surfaceContainer
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _pressed
                  ? AppColors.secondary.withValues(alpha: 0.3)
                  : AppColors.outlineVariant.withValues(alpha: 0.12),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.surfaceContainerHigh,
                ),
                clipBehavior: Clip.antiAlias,
                child: SafeImage(
                  urlOrPath: cover,
                  fit: BoxFit.cover,
                  fallback: Container(
                    color: AppColors.surfaceContainerHigh,
                    child: const Icon(
                      Icons.queue_music_rounded,
                      color: AppColors.outline,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.playlist.name,
                      style: AppTypography.bodyMd(color: AppColors.primary)
                          .copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.playlist.tracks.length} tracks · ${widget.playlist.description}',
                      style: AppTypography.labelSm(
                        color: AppColors.onSurfaceVariant,
                      ).copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.playlist.telemetryBadge,
                  style: AppTypography.labelSm(color: AppColors.secondary)
                      .copyWith(fontSize: 9.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
