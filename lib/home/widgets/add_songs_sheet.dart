import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../components/track_artwork.dart';
import '../../models/models.dart';
import '../../repositories/history_repository.dart';
import '../../repositories/music_repository.dart';
import '../../repositories/playlist_repository.dart';
import '../../theme/theme.dart';

class AddSongsSheet extends StatefulWidget {
  final String playlistId;
  final String playlistName;

  const AddSongsSheet({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  static Future<void> show(
    BuildContext context, {
    required String playlistId,
    required String playlistName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSongsSheet(
        playlistId: playlistId,
        playlistName: playlistName,
      ),
    );
  }

  @override
  State<AddSongsSheet> createState() => _AddSongsSheetState();
}

class _AddSongsSheetState extends State<AddSongsSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  List<Track> _searchResults = [];
  List<Track> _trendingTracks = [];
  List<Track> _historyTracks = [];
  String _activeTab = 'trending'; // 'trending', 'history', 'search'

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // 1. History tracks
    final historyItems = HistoryRepository.instance.history;
    _historyTracks = historyItems.map((item) => item.track).toList();

    // 2. Trending tracks
    try {
      final songs = await MusicRepository.instance.getTrending();
      if (mounted) {
        setState(() {
          _trendingTracks = songs.map((s) => s.toTrack()).toList();
        });
      }
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _activeTab = 'trending';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _activeTab = 'search';
    });

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final songs = await MusicRepository.instance.searchSongs(q);
        if (mounted) {
          setState(() {
            _searchResults = songs.map((s) => s.toTrack()).toList();
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  void _addTrack(Track track) {
    HapticFeedback.mediumImpact();
    final added = PlaylistRepository.instance.addTrackToPlaylist(
      widget.playlistId,
      track,
    );
    if (added) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.secondaryAccent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Added "${track.title}" to ${widget.playlistName}',
                  style: AppTypography.bodySm(color: AppColors.primaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlist = PlaylistRepository.instance.getPlaylist(widget.playlistId);
    final existingTrackIds =
        playlist?.tracks.map((t) => t.id).toSet() ?? <String>{};

    List<Track> displayedList;
    if (_activeTab == 'search') {
      displayedList = _searchResults;
    } else if (_activeTab == 'history') {
      displayedList = _historyTracks;
    } else {
      displayedList = _trendingTracks;
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: AppColors.neutralCanvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
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
                        ).copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.playlistName,
                        style: AppTypography.bodySm(
                          color: AppColors.secondaryAccent,
                        ).copyWith(fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withValues(
                        alpha: 0.6,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.18),
                  width: 0.8,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: AppTypography.bodyMd(color: AppColors.primaryText),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, or soundtracks...',
                  hintStyle: AppTypography.bodySm(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.secondaryAccent,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.outline,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Segment Tab Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _TabPill(
                  label: 'Trending',
                  isSelected: _activeTab == 'trending',
                  onTap: () => setState(() => _activeTab = 'trending'),
                ),
                const SizedBox(width: 8),
                _TabPill(
                  label: 'Recent History',
                  isSelected: _activeTab == 'history',
                  onTap: () => setState(() => _activeTab = 'history'),
                ),
                if (_searchResults.isNotEmpty || _isSearching) ...[
                  const SizedBox(width: 8),
                  _TabPill(
                    label: 'Search Results',
                    isSelected: _activeTab == 'search',
                    onTap: () => setState(() => _activeTab = 'search'),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),
          Divider(
            color: AppColors.outlineVariant.withValues(alpha: 0.12),
            height: 1,
          ),

          // Content List / Loading / Empty
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryAccent,
                      strokeWidth: 2,
                    ),
                  )
                : displayedList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.music_off_rounded,
                              size: 40,
                              color: AppColors.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _activeTab == 'search'
                                  ? 'No matching songs found'
                                  : 'No tracks available',
                              style: AppTypography.bodyMd(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        physics: const BouncingScrollPhysics(),
                        itemCount: displayedList.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final track = displayedList[index];
                          final isAlreadyAdded =
                              existingTrackIds.contains(track.id);

                          return _AddTrackTile(
                            track: track,
                            isAdded: isAlreadyAdded,
                            onAdd: () => _addTrack(track),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondaryAccent
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryAccent
                : AppColors.outlineVariant.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSm(
            color: isSelected
                ? AppColors.neutralCanvas
                : AppColors.onSurfaceVariant,
          ).copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

class _AddTrackTile extends StatelessWidget {
  final Track track;
  final bool isAdded;
  final VoidCallback onAdd;

  const _AddTrackTile({
    required this.track,
    required this.isAdded,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final coverArt = track.albumArt ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.1),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: TrackArtwork(
              albumArt: coverArt,
              trackId: track.id,
              fit: BoxFit.cover,
              fallback: const Icon(
                Icons.music_note_rounded,
                size: 20,
                color: AppColors.outline,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Artist
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: AppTypography.bodyMd(color: AppColors.primaryText)
                      .copyWith(fontWeight: FontWeight.w500, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  track.artist,
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 11.5, fontWeight: FontWeight.w300),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Add / Added Button
          GestureDetector(
            onTap: isAdded ? null : onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isAdded
                    ? AppColors.secondaryAccent.withValues(alpha: 0.15)
                    : AppColors.secondaryAccent,
                borderRadius: BorderRadius.circular(8),
                border: isAdded
                    ? Border.all(
                        color: AppColors.secondaryAccent.withValues(alpha: 0.3),
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAdded ? Icons.check_rounded : Icons.add_rounded,
                    size: 15,
                    color: isAdded
                        ? AppColors.secondaryAccent
                        : AppColors.neutralCanvas,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAdded ? 'Added' : 'Add',
                    style: AppTypography.labelSm(
                      color: isAdded
                          ? AppColors.secondaryAccent
                          : AppColors.neutralCanvas,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
