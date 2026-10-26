import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/track_artwork.dart';
import '../../main_layout/widgets/mini_player_bar.dart';
import '../../models/models.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../repositories/playlist_repository.dart';
import '../../repositories/favorites_repository.dart';
import '../../repositories/download_repository.dart';
import '../../theme/theme.dart';
import '../../home/widgets/add_songs_sheet.dart';
import '../../home/widgets/add_to_playlist_dialog.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortMode = 'DEFAULT'; // 'DEFAULT', 'TITLE', 'DURATION'

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

    final playlist = PlaylistRepository.instance.getPlaylist(widget.playlistId);
    final name = playlist?.name ?? 'Playlist';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(
          shuffle ? 'Shuffling $name...' : 'Playing $name...',
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

  void _showAddSongs(Playlist playlist) {
    HapticFeedback.selectionClick();
    AddSongsSheet.show(
      context,
      playlistId: playlist.id,
      playlistName: playlist.name,
    );
  }

  void _toggleSort() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_sortMode == 'DEFAULT') {
        _sortMode = 'TITLE';
      } else if (_sortMode == 'TITLE') {
        _sortMode = 'DURATION';
      } else {
        _sortMode = 'DEFAULT';
      }
    });
  }

  void _showRenameDialog(Playlist playlist) {
    final nameCtrl = TextEditingController(text: playlist.name);
    final descCtrl = TextEditingController(text: playlist.description);

    showDialog(
      context: context,
      builder: (dialogCtx) {
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
            'Edit Playlist',
            style: AppTypography.headlineMd(
              color: AppColors.primaryText,
            ).copyWith(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: AppTypography.bodyMd(color: AppColors.primaryText),
                decoration: InputDecoration(
                  labelText: 'Playlist Name',
                  labelStyle: AppTypography.labelSm(
                    color: AppColors.secondaryAccent,
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.outlineVariant),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.secondaryAccent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: AppTypography.bodyMd(color: AppColors.primaryText),
                decoration: InputDecoration(
                  labelText: 'Curator / Subtitle',
                  labelStyle: AppTypography.labelSm(
                    color: AppColors.onSurfaceVariant,
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.outlineVariant),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.secondaryAccent),
                  ),
                ),
              ),
            ],
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
                final newName = nameCtrl.text.trim();
                if (newName.isNotEmpty) {
                  PlaylistRepository.instance.renamePlaylist(
                    playlist.id,
                    newName,
                    newDescription: descCtrl.text.trim(),
                  );
                }
                Navigator.of(dialogCtx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeletePlaylist(Playlist playlist) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
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
            'Delete Playlist?',
            style: AppTypography.headlineMd(
              color: AppColors.primaryText,
            ).copyWith(fontSize: 18),
          ),
          content: Text(
            'Are you sure you want to delete "${playlist.name}"? This cannot be undone.',
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
                backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                PlaylistRepository.instance.deletePlaylist(playlist.id);
                Navigator.of(dialogCtx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
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
      ]),
      builder: (context, child) {
        final playlist = PlaylistRepository.instance.getPlaylist(
          widget.playlistId,
        );

        if (playlist == null) {
          if (PlaylistRepository.instance.isLoading) {
            return Scaffold(
              backgroundColor: const Color(0xFF131315),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondaryAccent,
                ),
              ),
            );
          }
          return Scaffold(
            backgroundColor: const Color(0xFF131315),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(
              child: Text(
                'Playlist not found',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        final cover =
            (playlist.tracks.isNotEmpty &&
                playlist.tracks.first.albumArt != null &&
                playlist.tracks.first.albumArt!.isNotEmpty)
            ? playlist.tracks.first.albumArt!
            : playlist.coverUrl;
        var tracks = List<Track>.from(playlist.tracks);

        // Apply filter
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          tracks = tracks
              .where(
                (t) =>
                    t.title.toLowerCase().contains(q) ||
                    t.artist.toLowerCase().contains(q),
              )
              .toList();
        }

        // Apply sort
        if (_sortMode == 'TITLE') {
          tracks.sort((a, b) => a.title.compareTo(b.title));
        } else if (_sortMode == 'DURATION') {
          tracks.sort((a, b) => b.duration.compareTo(a.duration));
        }

        final bottomPad = MediaQuery.of(context).padding.bottom + 90.0;

        return Scaffold(
          backgroundColor: const Color(0xFF131315),
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Top Custom App Bar
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: const Color(0xFF131315),
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    leadingWidth: 52,
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PLAYLIST ARCHIVE',
                          style:
                              AppTypography.labelSm(
                                color: const Color(0xFFC5A059),
                              ).copyWith(
                                fontSize: 10,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Playlist Detail',
                          style: AppTypography.bodyLg(color: Colors.white)
                              .copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.3,
                              ),
                        ),
                      ],
                    ),
                    actions: [
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        color: const Color(0xFF1E1E22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 'add') {
                            _showAddSongs(playlist);
                          } else if (value == 'rename') {
                            _showRenameDialog(playlist);
                          } else if (value == 'delete') {
                            _confirmDeletePlaylist(playlist);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'add',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 18,
                                  color: Color(0xFFC5A059),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Add Songs',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Edit Info',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  // 2. Main Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Hero Poster Card ───────────────────────────────
                          Container(
                            width: double.infinity,
                            height: 380,
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Background Artwork
                                SafeImage(
                                  urlOrPath: cover,
                                  fit: BoxFit.cover,
                                  fallback: _fallbackPoster(),
                                ),

                                // Scrim overlay at bottom
                                const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Color(0x30000000),
                                        Color(0xCC0E0E10),
                                        Color(0xF50B0B0D),
                                      ],
                                      stops: [0.25, 0.55, 0.8, 1.0],
                                    ),
                                  ),
                                ),

                                // Top Header Bar inside the card
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 36,
                                    color: const Color(
                                      0xFF191A1D,
                                    ).withValues(alpha: 0.92),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFC5A059),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Playlist - ${playlist.name}',
                                            style: const TextStyle(
                                              color: Color(0xFFA5A7AE),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.3,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          width: 13,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.white38,
                                              width: 1.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Bottom Typography inside card
                                Positioned(
                                  bottom: 20,
                                  left: 20,
                                  right: 20,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        playlist.telemetryBadge.isNotEmpty
                                            ? playlist.telemetryBadge
                                                  .toUpperCase()
                                            : 'STUDIO PURE CURATION',
                                        style:
                                            AppTypography.labelSm(
                                              color: const Color(0xFFC5A059),
                                            ).copyWith(
                                              fontSize: 10,
                                              letterSpacing: 1.8,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        playlist.name,
                                        style:
                                            AppTypography.headlineLgMobile(
                                              color: Colors.white,
                                            ).copyWith(
                                              fontSize: 27,
                                              fontWeight: FontWeight.w400,
                                              letterSpacing: -0.4,
                                              height: 1.15,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Curator & Stats Subtitle ───────────────────────
                          Text(
                            [
                              playlist.description.isNotEmpty
                                  ? playlist.description
                                  : 'Studio Pure & Julian Vance',
                              '${playlist.tracks.length} Tracks',
                              playlist.formattedDuration,
                            ].join('  ·  '),
                            style:
                                AppTypography.bodySm(
                                  color: const Color(0xFF9E9EA6),
                                ).copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.1,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 18),

                          // ── Action Bar Row ─────────────────────────────────
                          Row(
                            children: [
                              // Play All Button (Solid White)
                              GestureDetector(
                                onTap: playlist.tracks.isNotEmpty
                                    ? () => _playAll(playlist.tracks)
                                    : null,
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'PLAY ALL',
                                        style:
                                            AppTypography.labelSm(
                                              color: Colors.black,
                                            ).copyWith(
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.2,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Shuffle Button (Dark Square Box)
                              GestureDetector(
                                onTap: playlist.tracks.isNotEmpty
                                    ? () => _playAll(
                                        playlist.tracks,
                                        shuffle: true,
                                      )
                                    : null,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1F23),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.shuffle_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Add Songs '+' Icon Button
                              _TonearmMixIcon(
                                onTap: () => _showAddSongs(playlist),
                              ),

                              const SizedBox(width: 10),

                              // Solid White/Gold Heart Favorite Icon
                              AnimatedBuilder(
                                animation: FavoritesRepository
                                    .instance.likedPlaylistIdsNotifier,
                                builder: (context, _) {
                                  final isLiked = FavoritesRepository.instance
                                      .isPlaylistLiked(playlist.id);
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      FavoritesRepository.instance
                                          .toggleLikePlaylist(playlist)
                                          .then((nowLiked) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                                AppColors.surfaceContainerHigh,
                                            behavior: SnackBarBehavior.floating,
                                            duration:
                                                const Duration(seconds: 2),
                                            margin: const EdgeInsets.fromLTRB(
                                                16, 0, 16, 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            content: Text(
                                              nowLiked
                                                  ? 'Added to Liked Playlists'
                                                  : 'Removed from Liked Playlists',
                                              style: AppTypography.bodySm(
                                                  color: AppColors.primaryText),
                                            ),
                                          ),
                                        );
                                      });
                                    },
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: Center(
                                        child: Icon(
                                          isLiked
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          color: isLiked
                                              ? const Color(0xFFC5A059)
                                              : Colors.white,
                                          size: 21,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(width: 10),

                              // Share Icon
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor:
                                          AppColors.surfaceContainerHigh,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      content: Text(
                                        'Playlist link copied to clipboard',
                                        style: AppTypography.bodySm(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Center(
                                    child: Icon(
                                      Icons.share_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Download Playlist Icon
                              ValueListenableBuilder<Set<String>>(
                                valueListenable: DownloadRepository
                                    .instance.downloadedTrackIdsNotifier,
                                builder: (context, downloadedIds, _) {
                                  final tracks = playlist.tracks;
                                  final allDownloaded = tracks.isNotEmpty &&
                                      tracks.every((t) =>
                                          downloadedIds.contains(t.id));
                                  final someDownloaded = tracks.any((t) =>
                                      downloadedIds.contains(t.id));

                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () async {
                                      HapticFeedback.lightImpact();
                                      if (tracks.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                                AppColors.surfaceContainerHigh,
                                            behavior:
                                                SnackBarBehavior.floating,
                                            content: Text(
                                              'No tracks in playlist to download',
                                              style: AppTypography.bodySm(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      if (allDownloaded) {
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (dialogCtx) => AlertDialog(
                                            backgroundColor:
                                                AppColors.surfaceContainerLow,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            title: const Text(
                                              'Remove Downloads?',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            content: Text(
                                              'Remove all ${tracks.length} downloaded songs in "${playlist.name}" from your device storage?',
                                              style: const TextStyle(
                                                color: Color(0xFFD6D6DC),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        dialogCtx, false),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    color: Color(0xFF8E9097),
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        dialogCtx, true),
                                                child: const Text(
                                                  'Remove',
                                                  style: TextStyle(
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          for (final t in tracks) {
                                            await DownloadRepository.instance
                                                .deleteDownloadedSong(t.id);
                                          }
                                          messenger.showSnackBar(
                                            SnackBar(
                                              backgroundColor:
                                                  AppColors.surfaceContainerHigh,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              content: Text(
                                                'Removed downloaded tracks from device',
                                                style: AppTypography.bodySm(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                                AppColors.surfaceContainerHigh,
                                            behavior:
                                                SnackBarBehavior.floating,
                                            content: Text(
                                              'Downloading ${tracks.length} tracks to offline vault...',
                                              style: AppTypography.bodySm(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        );
                                        for (final t in tracks) {
                                          if (!DownloadRepository.instance
                                              .isDownloaded(t.id)) {
                                            DownloadRepository.instance
                                                .downloadSong(t);
                                          }
                                        }
                                      }
                                    },
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: Center(
                                        child: Icon(
                                          allDownloaded
                                              ? Icons.offline_pin_rounded
                                              : (someDownloaded
                                                  ? Icons.downloading_rounded
                                                  : Icons
                                                      .arrow_circle_down_rounded),
                                          color: allDownloaded
                                              ? const Color(0xFF26A69A)
                                              : Colors.white,
                                          size: 21,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // ── Search & Filter Controls ───────────────────────
                          Row(
                            children: [
                              // Search input
                              Expanded(
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF191A1D),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.search_rounded,
                                        color: Color(0xFF70737B),
                                        size: 19,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          onChanged: (val) => setState(
                                            () => _searchQuery = val,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Find within archive...',
                                            hintStyle: TextStyle(
                                              color: Color(0xFF63656C),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                      if (_searchQuery.isNotEmpty)
                                        GestureDetector(
                                          onTap: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Color(0xFF70737B),
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Sort Mode Button (DEFAULT / TITLE / DURATION)
                              GestureDetector(
                                onTap: _toggleSort,
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF191A1D),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _sortMode,
                                        style: const TextStyle(
                                          color: Color(0xFFE2E2E6),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.tune_rounded,
                                        size: 16,
                                        color: Color(0xFFE2E2E6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── Column Headers (COVER | COMPOSITION | SPECS / DURATION) ──
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 44,
                                  child: Center(
                                    child: Icon(
                                      Icons.album_outlined,
                                      size: 14,
                                      color: Color(0xFF6B6E76),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'COMPOSITION',
                                  style: TextStyle(
                                    color: Color(0xFF6B6E76),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  'SPECS  /  DURATION',
                                  style: TextStyle(
                                    color: Color(0xFF6B6E76),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 36),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),

                  // 3. Track List
                  if (tracks.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 40,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.queue_music_rounded,
                                size: 36,
                                color: Color(0xFF5A5A60),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No matches in archive'
                                    : 'Archive is empty',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => _showAddSongs(playlist),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC5A059),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '+ Add Songs',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad),
                      sliver: SliverReorderableList(
                        itemCount: tracks.length,
                        onReorder: (oldIndex, newIndex) {
                          HapticFeedback.mediumImpact();
                          if (_sortMode != 'DEFAULT') {
                            setState(() => _sortMode = 'DEFAULT');
                          }
                          if (_searchQuery.isEmpty) {
                            PlaylistRepository.instance.reorderTrack(
                              playlist.id,
                              oldIndex,
                              newIndex,
                            );
                          } else {
                            final trackBeingMoved = tracks[oldIndex];
                            final originalOldIndex = playlist.tracks.indexWhere(
                              (t) => t.id == trackBeingMoved.id,
                            );
                            int originalNewIndex;
                            if (newIndex >= tracks.length) {
                              final lastFiltered = tracks.last;
                              originalNewIndex =
                                  playlist.tracks.indexWhere(
                                    (t) => t.id == lastFiltered.id,
                                  ) +
                                  1;
                            } else {
                              final targetTrack = tracks[newIndex];
                              originalNewIndex = playlist.tracks.indexWhere(
                                (t) => t.id == targetTrack.id,
                              );
                            }
                            if (originalOldIndex != -1 &&
                                originalNewIndex != -1) {
                              PlaylistRepository.instance.reorderTrack(
                                playlist.id,
                                originalOldIndex,
                                originalNewIndex,
                              );
                            }
                          }
                        },
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, animChild) {
                              return Material(
                                color: Colors.transparent,
                                elevation: 8,
                                shadowColor: Colors.black.withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF26272C),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFC5A059,
                                      ).withValues(alpha: 0.6),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: animChild,
                                ),
                              );
                            },
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(track.id),
                            index: index,
                            child: _ArchiveTrackTile(
                              key: ValueKey(track.id),
                              track: track,
                              index: index + 1,
                              onTap: () => _playTrackAt(tracks, index),
                              onRemove: () {
                                PlaylistRepository.instance
                                    .removeTrackFromPlaylist(
                                      playlist.id,
                                      track.id,
                                    );
                                HapticFeedback.mediumImpact();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),

              // Mini Player
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom + 8,
                child: const MiniPlayerBar(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fallbackPoster() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF382E26), Color(0xFF221D1A), Color(0xFF131316)],
        ),
      ),
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFC5A059).withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 42,
              color: Color(0xFFC5A059),
            ),
          ),
        ),
      ),
    );
  }
}

/// Add songs '+' icon button in playlist header
class _TonearmMixIcon extends StatelessWidget {
  final VoidCallback onTap;

  const _TonearmMixIcon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _ArchiveTrackTile extends StatefulWidget {
  final Track track;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ArchiveTrackTile({
    super.key,
    required this.track,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<_ArchiveTrackTile> createState() => _ArchiveTrackTileState();
}

class _ArchiveTrackTileState extends State<_ArchiveTrackTile> {
  void _showTrackMenu(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.8,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.playlist_play_rounded,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Play Next',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    context.read<PlayerBloc>().add(
                      PlayerAddToQueue(widget.track, playNext: true),
                    );
                    Navigator.of(sheetCtx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.queue_music_rounded,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Add to Queue',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    context.read<PlayerBloc>().add(
                      PlayerAddToQueue(widget.track, playNext: false),
                    );
                    Navigator.of(sheetCtx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.playlist_add_rounded,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Add to Playlist',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    showAddToPlaylistSheet(context, widget.track);
                  },
                ),
                ListTile(
                  leading: Icon(
                    FavoritesRepository.instance.isSongLiked(widget.track.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: FavoritesRepository.instance
                            .isSongLiked(widget.track.id)
                        ? AppColors.secondaryAccent
                        : Colors.white,
                  ),
                  title: Text(
                    FavoritesRepository.instance.isSongLiked(widget.track.id)
                        ? 'Remove from Liked Songs'
                        : 'Save to Liked Songs',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    FavoritesRepository.instance.toggleLikeSong(widget.track);
                  },
                ),
                ValueListenableBuilder<Set<String>>(
                  valueListenable: DownloadRepository
                      .instance.downloadedTrackIdsNotifier,
                  builder: (ctx, downloadedIds, _) {
                    final isDownloaded =
                        downloadedIds.contains(widget.track.id);
                    return ListTile(
                      leading: Icon(
                        isDownloaded
                            ? Icons.offline_pin_rounded
                            : Icons.arrow_circle_down_rounded,
                        color: isDownloaded
                            ? const Color(0xFF26A69A)
                            : Colors.white,
                      ),
                      title: Text(
                        isDownloaded
                            ? 'Remove Download from Device'
                            : 'Download for Offline Play',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: isDownloaded
                          ? const Text(
                              'Stored in private offline vault',
                              style: TextStyle(
                                color: Color(0xFF8E9097),
                                fontSize: 11,
                              ),
                            )
                          : null,
                      onTap: () async {
                        Navigator.of(sheetCtx).pop();
                        final messenger = ScaffoldMessenger.of(context);
                        if (isDownloaded) {
                          await DownloadRepository.instance
                              .deleteDownloadedSong(widget.track.id);
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.surfaceContainerHigh,
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                'Download removed from device',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        } else {
                          DownloadRepository.instance.downloadSong(widget.track);
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.surfaceContainerHigh,
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                'Downloading track for offline playback...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Remove from Playlist',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    widget.onRemove();
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _trackFallbackArtwork() {
    return Container(
      color: const Color(0xFF222327),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 18,
          color: Color(0xFF8E9097),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, pState) {
        final isCurrent = pState.currentTrack?.id == widget.track.id;
        final isPlaying = isCurrent && pState.isPlaying;

        final isDsd = widget.track.formatBadge.toUpperCase().contains('DSD');
        final badgeText = widget.track.formatBadge.toUpperCase();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (isCurrent) {
              context.read<PlayerBloc>().add(const PlayerTogglePlayPause());
            } else {
              widget.onTap();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrent ? const Color(0xFF1F2024) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isCurrent
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 0.8,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Song Cover Artwork (with playing equalizer overlay if active)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF242428),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFFC5A059).withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TrackArtwork(
                        albumArt: widget.track.albumArt,
                        trackId: widget.track.id,
                        fit: BoxFit.cover,
                        fallback: _trackFallbackArtwork(),
                      ),
                      if (isCurrent)
                        Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          child: Center(
                            child: _PlayingEqualizerBars(isPlaying: isPlaying),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Composition (Title & Artist)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.track.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.5,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.track.artist.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.track.artist,
                          style: const TextStyle(
                            color: Color(0xFF8E9097),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Offline Downloaded Indicator
                ValueListenableBuilder<Set<String>>(
                  valueListenable: DownloadRepository
                      .instance.downloadedTrackIdsNotifier,
                  builder: (context, downloadedIds, _) {
                    if (downloadedIds.contains(widget.track.id)) {
                      return const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.offline_pin_rounded,
                          size: 15,
                          color: Color(0xFF26A69A),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Specs Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222327),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: isDsd
                          ? const Color(0xFFC5A059).withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.08),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: isDsd
                          ? const Color(0xFFC5A059)
                          : const Color(0xFF9E9EA6),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Duration
                SizedBox(
                  width: 36,
                  child: Text(
                    widget.track.duration,
                    style: TextStyle(
                      color: isCurrent
                          ? const Color(0xFFC5A059)
                          : const Color(0xFFD6D6DC),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),

                const SizedBox(width: 8),

                // Three Dots menu
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showTrackMenu(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      color: Color(0xFF70737B),
                      size: 20,
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

class _PlayingEqualizerBars extends StatefulWidget {
  final bool isPlaying;
  const _PlayingEqualizerBars({required this.isPlaying});

  @override
  State<_PlayingEqualizerBars> createState() => _PlayingEqualizerBarsState();
}

class _PlayingEqualizerBarsState extends State<_PlayingEqualizerBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.isPlaying) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PlayingEqualizerBars old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      if (widget.isPlaying) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.animateTo(0.2, duration: const Duration(milliseconds: 200));
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final value = widget.isPlaying
                ? ((_ctrl.value + (index * 0.3)) % 1.0)
                : 0.2;
            return Container(
              width: 2.5,
              height: 4.0 + (value * 11.0),
              margin: const EdgeInsets.only(right: 2.0),
              decoration: BoxDecoration(
                color: const Color(0xFFC5A059),
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          },
        );
      }),
    );
  }
}
