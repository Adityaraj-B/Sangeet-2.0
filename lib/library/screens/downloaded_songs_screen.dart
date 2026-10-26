import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/widgets/add_to_playlist_dialog.dart';
import '../../main_layout/widgets/mini_player_bar.dart';
import '../../models/models.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../repositories/download_repository.dart';
import '../../theme/theme.dart';

/// Screen displaying all tracks downloaded into the app's private sandbox storage.
///
/// Tracks shown here play 100% offline with zero internet access required.
class DownloadedSongsScreen extends StatefulWidget {
  const DownloadedSongsScreen({super.key});

  @override
  State<DownloadedSongsScreen> createState() => _DownloadedSongsScreenState();
}

class _DownloadedSongsScreenState extends State<DownloadedSongsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _playAll(List<Track> tracks, {bool shuffle = false}) {
    if (tracks.isEmpty) return;
    HapticFeedback.mediumImpact();
    final queue = List<Track>.from(tracks);
    if (shuffle) queue.shuffle();
    context.read<PlayerBloc>().add(PlayerPlayQueue(queue, initialIndex: 0));
    PlayerScreen.open(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(
          shuffle ? 'Shuffling offline tracks...' : 'Playing offline tracks...',
          style: AppTypography.bodySm(color: AppColors.primaryText),
        ),
      ),
    );
  }

  void _playTrackAt(List<Track> tracks, int index) {
    HapticFeedback.lightImpact();
    context.read<PlayerBloc>().add(
          PlayerPlayQueue(tracks, initialIndex: index),
        );
    PlayerScreen.open(context);
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        title: Text(
          'Delete All Downloads?',
          style: AppTypography.headlineMd(color: Colors.white).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will remove all downloaded audio files from your device storage to free up space. You can re-download them anytime.',
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
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
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              DownloadRepository.instance.clearAllDownloads();
              Navigator.of(dialogCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  content: Text(
                    'All downloaded songs deleted from device',
                    style: AppTypography.bodySm(color: AppColors.primaryText),
                  ),
                ),
              );
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  List<Track> _filterTracks(List<Track> raw) {
    if (_searchQuery.trim().isEmpty) return raw;
    final q = _searchQuery.trim().toLowerCase();
    return raw
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          AnimatedBuilder(
            animation: DownloadRepository.instance.downloadedTrackIdsNotifier,
            builder: (context, _) {
              if (DownloadRepository.instance.downloadedCount == 0) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Clear all downloads',
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Color(0xFFE57373),
                  size: 24,
                ),
                onPressed: () => _confirmClearAll(context),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00897B).withValues(alpha: 0.1),
                ),
              ),
            ),
          ),

          // Main Content
          AnimatedBuilder(
            animation: Listenable.merge([
              DownloadRepository.instance.downloadedTracksNotifier,
              DownloadRepository.instance.downloadedTrackIdsNotifier,
              DownloadRepository.instance.totalStorageBytesNotifier,
            ]),
            builder: (context, _) {
              final rawTracks = DownloadRepository.instance.downloadedTracks;
              final tracks = _filterTracks(rawTracks);
              final totalStorage =
                  DownloadRepository.instance.totalStorageFormatted;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Header Banner
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      context,
                      count: rawTracks.length,
                      storageText: totalStorage,
                      tracks: rawTracks,
                    ),
                  ),

                  // 2. Search Bar
                  if (rawTracks.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                            style: AppTypography.bodySm(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search downloaded songs...',
                              hintStyle: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.onSurfaceVariant,
                                size: 18,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded,
                                          size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.surfaceContainerHigh
                                  .withValues(alpha: 0.4),
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 3. Track List or Empty State
                  if (rawTracks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyView(context),
                    )
                  else if (tracks.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No matching downloaded songs',
                            style: AppTypography.bodyMd(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final track = tracks[index];
                            return _DownloadedTrackTile(
                              index: index + 1,
                              track: track,
                              onTap: () => _playTrackAt(tracks, index),
                            );
                          },
                          childCount: tracks.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Floating Mini Player Overlay
          const Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: MiniPlayerBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required int count,
    required String storageText,
    required List<Track> tracks,
  }) {
    final topPadding = MediaQuery.of(context).padding.top + 50;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 20),
      child: Column(
        children: [
          // Offline Vault Artwork Container
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00695C),
                    Color(0xFF004D40),
                    Color(0xFF0E1A17),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00897B).withValues(alpha: 0.3),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF26A69A).withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.offline_pin_rounded,
                    size: 64,
                    color: Color(0xFF80CBC4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00897B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF26A69A).withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: const Text(
              'OFFLINE VAULT • ACCESSIBLE ONLY IN AURA',
              style: TextStyle(
                color: Color(0xFF80CBC4),
                fontSize: 9.5,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            'Downloaded Music',
            style: AppTypography.headlineLg(color: Colors.white).copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            '$count ${count == 1 ? 'song' : 'songs'} • $storageText on device • 100% Offline Play',
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 18),

          // Play Controls
          if (tracks.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text(
                    'PLAY ALL',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  onPressed: () => _playAll(tracks, shuffle: false),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                  label: const Text(
                    'SHUFFLE',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  onPressed: () => _playAll(tracks, shuffle: true),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00897B).withValues(alpha: 0.12),
                border: Border.all(
                  color: const Color(0xFF26A69A).withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.download_rounded,
                size: 44,
                color: Color(0xFF80CBC4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Downloaded Music',
              style: AppTypography.headlineMd(color: Colors.white).copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Download songs to listen anywhere without internet. Downloaded files are encrypted in the app vault and can only be played in Aura.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                  .copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Downloaded Track Tile ───────────────────────────────────────────────────

class _DownloadedTrackTile extends StatelessWidget {
  final int index;
  final Track track;
  final VoidCallback onTap;

  const _DownloadedTrackTile({
    required this.index,
    required this.track,
    required this.onTap,
  });

  void _showMoreMenu(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: _buildArtwork(track.albumArt),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style: AppTypography.bodyMd(color: Colors.white)
                                  .copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              track.artist,
                              style: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.outlineVariant, height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.playlist_play_rounded,
                    color: Colors.white,
                  ),
                  title:
                      const Text('Play Next', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    context.read<PlayerBloc>().add(
                          PlayerAddToQueue(track, playNext: true),
                        );
                    Navigator.of(sheetCtx).pop();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.queue_music_rounded, color: Colors.white),
                  title: const Text('Add to Queue',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    context.read<PlayerBloc>().add(
                          PlayerAddToQueue(track, playNext: false),
                        );
                    Navigator.of(sheetCtx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.playlist_add_rounded,
                      color: Colors.white),
                  title: const Text('Add to Playlist',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    showAddToPlaylistSheet(context, track);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFE57373),
                  ),
                  title: const Text(
                    'Delete from Device',
                    style: TextStyle(color: Color(0xFFE57373)),
                  ),
                  onTap: () {
                    DownloadRepository.instance.deleteDownload(track.id);
                    Navigator.of(sheetCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        content: Text(
                          'Deleted "${track.title}" from device storage',
                          style: AppTypography.bodySm(
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtwork(String? artPath) {
    if (artPath == null || artPath.isEmpty) {
      return Container(
        color: AppColors.surfaceContainerHigh,
        child: const Icon(Icons.music_note, color: Colors.white38),
      );
    }
    if (artPath.startsWith('http')) {
      return Image.network(
        artPath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: AppColors.surfaceContainerHigh,
          child: const Icon(Icons.music_note, color: Colors.white38),
        ),
      );
    }
    final file = File(artPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: AppColors.surfaceContainerHigh,
          child: const Icon(Icons.music_note, color: Colors.white38),
        ),
      );
    }
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Icon(Icons.music_note, color: Colors.white38),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) =>
          (prev.currentTrack?.id == track.id) !=
              (curr.currentTrack?.id == track.id) ||
          prev.isPlaying != curr.isPlaying,
      builder: (context, playerState) {
        final isCurrentTrack = playerState.currentTrack?.id == track.id;
        final isPlaying = isCurrentTrack && playerState.isPlaying;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: isCurrentTrack
                ? const Color(0xFF00897B).withValues(alpha: 0.15)
                : AppColors.surfaceContainerLow.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentTrack
                  ? const Color(0xFF26A69A).withValues(alpha: 0.4)
                  : AppColors.outlineVariant.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: ListTile(
            onTap: onTap,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: _buildArtwork(track.albumArt),
                  ),
                ),
                if (isCurrentTrack)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: const Color(0xFF80CBC4),
                      size: 24,
                    ),
                  ),
              ],
            ),
            title: Text(
              track.title,
              style: AppTypography.bodyMd(
                color: isCurrentTrack ? const Color(0xFF80CBC4) : Colors.white,
              ).copyWith(
                fontWeight: isCurrentTrack ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004D40),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'OFFLINE',
                    style: TextStyle(
                      color: Color(0xFF80CBC4),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${track.artist} • ${track.duration}',
                    style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                        .copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF26A69A),
                  size: 20,
                ),
                IconButton(
                  tooltip: 'Options',
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 18,
                  ),
                  onPressed: () => _showMoreMenu(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
