import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/track_artwork.dart';
import '../../home/widgets/add_to_playlist_dialog.dart';
import '../../main_layout/widgets/mini_player_bar.dart';
import '../../models/models.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../repositories/favorites_repository.dart';
import '../../repositories/download_repository.dart';
import '../../theme/theme.dart';
import '../widgets/add_liked_songs_sheet.dart';

/// Dedicated screen for user's Liked Songs collection.
/// Stored persistently on device and synced with cloud.
class LikedSongsScreen extends StatefulWidget {
  const LikedSongsScreen({super.key});

  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortMode = 'RECENT'; // 'RECENT', 'TITLE', 'ARTIST', 'DURATION'

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
          shuffle ? 'Shuffling Liked Songs...' : 'Playing Liked Songs...',
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

  void _openAddSongs() {
    HapticFeedback.selectionClick();
    AddLikedSongsSheet.show(context);
  }

  void _toggleSort() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_sortMode == 'RECENT') {
        _sortMode = 'TITLE';
      } else if (_sortMode == 'TITLE') {
        _sortMode = 'ARTIST';
      } else if (_sortMode == 'ARTIST') {
        _sortMode = 'DURATION';
      } else {
        _sortMode = 'RECENT';
      }
    });
  }

  String _formatTotalDuration(List<Track> tracks) {
    var totalSeconds = 0;
    for (final track in tracks) {
      final parts = track.duration.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        totalSeconds += (m * 60) + s;
      }
    }
    final dur = Duration(seconds: totalSeconds);
    if (dur.inMinutes == 0 && dur.inSeconds == 0) return '0 min';
    if (dur.inHours > 0) {
      final rem = dur.inMinutes % 60;
      return '${dur.inHours} hr ${rem > 0 ? '$rem min' : ''}';
    }
    return '${dur.inMinutes} min';
  }

  List<Track> _filterAndSort(List<Track> rawTracks) {
    var filtered = List<Track>.from(rawTracks);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.artist.toLowerCase().contains(q))
          .toList();
    }

    if (_sortMode == 'TITLE') {
      filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortMode == 'ARTIST') {
      filtered.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
    } else if (_sortMode == 'DURATION') {
      filtered.sort((a, b) => a.duration.compareTo(b.duration));
    }
    // 'RECENT' is the default insertion order (most recently liked at index 0)
    return filtered;
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
          IconButton(
            tooltip: 'Add songs',
            icon: const Icon(Icons.add_rounded, color: AppColors.secondary, size: 26),
            onPressed: _openAddSongs,
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
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.12),
                ),
              ),
            ),
          ),

          // Main Content
          AnimatedBuilder(
            animation: Listenable.merge([
              FavoritesRepository.instance.likedSongsNotifier,
              FavoritesRepository.instance.likedSongIdsNotifier,
            ]),
            builder: (context, _) {
              final rawTracks = FavoritesRepository.instance.likedSongs;
              final tracks = _filterAndSort(rawTracks);
              final totalDurationText = _formatTotalDuration(rawTracks);

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Header Banner
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      context,
                      totalCount: rawTracks.length,
                      durationText: totalDurationText,
                      tracks: rawTracks,
                    ),
                  ),

                  // 2. Search & Controls Bar
                  if (rawTracks.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildControlsBar(context, rawTracks, tracks),
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
                            'No matches for "$_searchQuery"',
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
                            return _LikedTrackTile(
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
    required int totalCount,
    required String durationText,
    required List<Track> tracks,
  }) {
    final topPadding = MediaQuery.of(context).padding.top + 50;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 20),
      child: Column(
        children: [
          // Artwork Container with Glowing Heart Emblem
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5B1066),
                    Color(0xFF2E0854),
                    Color(0xFF160D2A),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A1B9A).withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle Radial Glow
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary.withValues(alpha: 0.15),
                    ),
                  ),
                  const Icon(
                    Icons.favorite_rounded,
                    size: 64,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Text(
              'AUTO-CURATED COLLECTION',
              style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                fontSize: 9.5,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            'Liked Songs',
            style: AppTypography.headlineLg(color: Colors.white).copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle / Metrics
          Text(
            '$totalCount ${totalCount == 1 ? 'song' : 'songs'} • $durationText • Stored on Device',
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),

          // Action Buttons: Play All & Shuffle
          if (tracks.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.onSecondary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  Widget _buildControlsBar(
    BuildContext context,
    List<Track> allTracks,
    List<Track> displayedTracks,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              // Search Input
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: AppTypography.bodySm(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search liked songs...',
                      hintStyle:
                          AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 18,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Sort Mode Button
              InkWell(
                onTap: _toggleSort,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sort_rounded,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _sortMode,
                        style: AppTypography.labelSm(color: AppColors.secondary)
                            .copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SHOWING ${displayedTracks.length} OF ${allTracks.length}',
                style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)
                    .copyWith(fontSize: 10, letterSpacing: 1.0),
              ),
              GestureDetector(
                onTap: _openAddSongs,
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ADD MORE',
                      style: AppTypography.labelSm(color: AppColors.secondary)
                          .copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
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
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 42,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Liked Songs Yet',
              style: AppTypography.headlineMd(color: Colors.white).copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Songs you favorite while listening or browsing will be stored permanently on your device so they never disappear.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Browse & Add Songs',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: _openAddSongs,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Liked Track Tile ──────────────────────────────────────────────────────────

class _LikedTrackTile extends StatelessWidget {
  final int index;
  final Track track;
  final VoidCallback onTap;

  const _LikedTrackTile({
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: TrackArtwork(
                            albumArt: track.albumArt,
                            trackId: track.id,
                            fit: BoxFit.cover,
                            fallback: Container(color: AppColors.surfaceContainerHigh),
                          ),
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
                  title: const Text('Play Next', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    context.read<PlayerBloc>().add(
                          PlayerAddToQueue(track, playNext: true),
                        );
                    Navigator.of(sheetCtx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.queue_music_rounded, color: Colors.white),
                  title:
                      const Text('Add to Queue', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    context.read<PlayerBloc>().add(
                          PlayerAddToQueue(track, playNext: false),
                        );
                    Navigator.of(sheetCtx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.playlist_add_rounded, color: Colors.white),
                  title: const Text('Add to Playlist',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    showAddToPlaylistSheet(context, track);
                  },
                ),
                ListTile(
                  leading: Icon(
                    DownloadRepository.instance.isDownloaded(track.id)
                        ? Icons.download_done_rounded
                        : Icons.download_rounded,
                    color: DownloadRepository.instance.isDownloaded(track.id)
                        ? const Color(0xFF26A69A)
                        : Colors.white,
                  ),
                  title: Text(
                    DownloadRepository.instance.isDownloaded(track.id)
                        ? 'Remove Download from Device'
                        : 'Download for Offline Play',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    if (DownloadRepository.instance.isDownloaded(track.id)) {
                      DownloadRepository.instance.deleteDownload(track.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.surfaceContainerHigh,
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'Removed "${track.title}" from offline downloads',
                            style: AppTypography.bodySm(color: AppColors.primaryText),
                          ),
                        ),
                      );
                    } else {
                      DownloadRepository.instance.downloadTrack(track);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.surfaceContainerHigh,
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'Downloading "${track.title}" for offline play...',
                            style: AppTypography.bodySm(color: AppColors.primaryText),
                          ),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFE57373),
                  ),
                  title: const Text(
                    'Remove from Liked Songs',
                    style: TextStyle(color: Color(0xFFE57373)),
                  ),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _confirmRemove(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmRemove(BuildContext context) {
    FavoritesRepository.instance.unlikeSong(track.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(
          'Removed "${track.title}" from Liked Songs',
          style: AppTypography.bodySm(color: AppColors.primaryText),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.secondary,
          onPressed: () {
            FavoritesRepository.instance.likeSong(track);
          },
        ),
      ),
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
                ? AppColors.secondary.withValues(alpha: 0.1)
                : AppColors.surfaceContainerLow.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentTrack
                  ? AppColors.secondary.withValues(alpha: 0.4)
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
                    child: TrackArtwork(
                      albumArt: track.albumArt,
                      trackId: track.id,
                      fit: BoxFit.cover,
                      fallback: Container(
                        color: AppColors.surfaceContainerHigh,
                        child: const Icon(Icons.music_note, color: Colors.white38),
                      ),
                    ),
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
                      color: AppColors.secondary,
                      size: 24,
                    ),
                  ),
              ],
            ),
            title: Text(
              track.title,
              style: AppTypography.bodyMd(
                color: isCurrentTrack ? AppColors.secondary : Colors.white,
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
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    track.formatBadge,
                    style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)
                        .copyWith(fontSize: 8.5, letterSpacing: 0.5),
                  ),
                ),
                if (DownloadRepository.instance.isDownloaded(track.id)) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.offline_pin_rounded,
                    color: Color(0xFF26A69A),
                    size: 13,
                  ),
                ],
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
                // Quick Unlike Button
                IconButton(
                  tooltip: 'Unlike',
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  onPressed: () => _confirmRemove(context),
                ),
                // 3-dots Menu
                IconButton(
                  tooltip: 'More',
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
