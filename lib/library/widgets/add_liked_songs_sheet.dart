import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../components/track_artwork.dart';
import '../../models/models.dart';
import '../../repositories/favorites_repository.dart';
import '../../repositories/history_repository.dart';
import '../../repositories/music_repository.dart';
import '../../theme/theme.dart';

/// Sheet that allows users to search, browse trending, or pick from recent history
/// to add songs directly to their Liked Songs collection.
class AddLikedSongsSheet extends StatefulWidget {
  const AddLikedSongsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddLikedSongsSheet(),
    );
  }

  @override
  State<AddLikedSongsSheet> createState() => _AddLikedSongsSheetState();
}

class _AddLikedSongsSheetState extends State<AddLikedSongsSheet> {
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

    _debounce = Timer(const Duration(milliseconds: 350), () async {
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

  void _toggleTrack(Track track) {
    HapticFeedback.mediumImpact();
    final wasLiked = FavoritesRepository.instance.isSongLiked(track.id);
    if (wasLiked) {
      FavoritesRepository.instance.unlikeSong(track.id);
    } else {
      FavoritesRepository.instance.likeSong(track);
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
                Icons.favorite_rounded,
                color: AppColors.secondary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Added "${track.title}" to Liked Songs',
                  style: AppTypography.bodySm(color: AppColors.primaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
      height: screenHeight * 0.86,
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to Liked Songs',
                        style: AppTypography.headlineMd(
                          color: AppColors.primaryText,
                        ).copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Browse catalog or search any track to save',
                        style: AppTypography.bodySm(
                          color: AppColors.onSurfaceVariant,
                        ).copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: AppTypography.bodyMd(color: AppColors.primaryText),
              decoration: InputDecoration(
                hintText: 'Search songs, artists, or soundtracks...',
                hintStyle: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.secondary,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Quick Filter Tabs (Trending / History)
          if (_searchController.text.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTabPill('trending', 'TRENDING HITS', Icons.trending_up_rounded),
                  const SizedBox(width: 8),
                  _buildTabPill('history', 'RECENT HISTORY', Icons.history_rounded),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Divider
          Divider(
            color: AppColors.outlineVariant.withValues(alpha: 0.12),
            height: 1,
          ),

          // Results / Content
          Expanded(
            child: AnimatedBuilder(
              animation: FavoritesRepository.instance.likedSongIdsNotifier,
              builder: (context, _) {
                if (_isSearching) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.secondary,
                    ),
                  );
                }

                if (displayedList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _activeTab == 'history'
                              ? Icons.history_rounded
                              : Icons.music_off_rounded,
                          size: 48,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _activeTab == 'history'
                              ? 'No recent listening history yet'
                              : 'No matching songs found',
                          style: AppTypography.bodyMd(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: displayedList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final track = displayedList[index];
                    final isLiked =
                        FavoritesRepository.instance.isSongLiked(track.id);

                    return _TrackAddTile(
                      track: track,
                      isLiked: isLiked,
                      onToggle: () => _toggleTrack(track),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(String tabKey, String label, IconData icon) {
    final isSelected = _activeTab == tabKey;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeTab = tabKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.2)
              : AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.secondary
                : AppColors.outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.secondary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSm(
                color: isSelected ? AppColors.secondary : AppColors.onSurfaceVariant,
              ).copyWith(fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackAddTile extends StatelessWidget {
  final Track track;
  final bool isLiked;
  final VoidCallback onToggle;

  const _TrackAddTile({
    required this.track,
    required this.isLiked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLiked
              ? AppColors.secondary.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: ClipRRect(
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
        title: Text(
          track.title,
          style: AppTypography.bodyMd(color: AppColors.primaryText).copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${track.artist} • ${track.duration}',
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isLiked
                  ? AppColors.secondary.withValues(alpha: 0.2)
                  : AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: isLiked
                    ? AppColors.secondary
                    : AppColors.outlineVariant.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isLiked ? AppColors.secondary : AppColors.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
