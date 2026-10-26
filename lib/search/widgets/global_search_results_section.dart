import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../artist/screens/artist_detail_screen.dart';
import '../../components/track_artwork.dart';
import '../../home/screens/album_detail_screen.dart';
import '../../models/models.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../theme/theme.dart';
import '../bloc/search_bloc.dart';

class GlobalSearchResultsSection extends StatelessWidget {
  final SearchState state;

  const GlobalSearchResultsSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && !state.hasResults) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Searching global archives for "${state.query}"...',
                style: AppTypography.bodySm(
                  color: AppColors.onSurfaceVariant,
                ).copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (state.errorMessage != null && !state.hasResults) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 38,
                color: AppColors.outline,
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: AppTypography.bodySm(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.read<SearchBloc>().add(
                    SearchPerformSearch(state.query),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Search'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: BorderSide(
                    color: AppColors.secondary.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!state.isLoading && !state.hasResults) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.music_off_rounded,
                size: 38,
                color: AppColors.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'No results found matching "${state.query}"',
                style: AppTypography.bodyMd(
                  color: AppColors.primary,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Try searching for songs, artists, or album titles.',
                style: AppTypography.bodySm(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Pills (ALL, SONGS, ARTISTS, ALBUMS)
        _buildCategoryTabs(context),
        const SizedBox(height: 18),

        // Content based on selected category
        if (state.activeCategory == 'ALL') ...[
          _buildAllView(context),
        ] else if (state.activeCategory == 'SONGS') ...[
          _buildSongsOnlyView(context),
        ] else if (state.activeCategory == 'ARTISTS') ...[
          _buildArtistsOnlyView(context),
        ] else if (state.activeCategory == 'ALBUMS') ...[
          _buildAlbumsOnlyView(context),
        ],
      ],
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    final categories = [
      {'key': 'ALL', 'label': 'All'},
      {'key': 'SONGS', 'label': 'Songs (${state.searchResults.length})'},
      {'key': 'ARTISTS', 'label': 'Artists (${state.artistResults.length})'},
      {'key': 'ALBUMS', 'label': 'Albums (${state.albumResults.length})'},
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = state.activeCategory == cat['key'];

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.read<SearchBloc>().add(
                    SearchCategoryChanged(cat['key']!),
                  );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondary
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.secondary
                      : AppColors.outlineVariant.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  cat['label']!,
                  style: AppTypography.labelSm(
                    color: isSelected ? Colors.black : AppColors.onSurfaceVariant,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Artists Section (if any)
        if (state.artistResults.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            title: 'ARTISTS',
            count: state.artistResults.length,
            onSeeAll: () {
              context.read<SearchBloc>().add(
                    const SearchCategoryChanged('ARTISTS'),
                  );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 125,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: state.artistResults.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final artist = state.artistResults[index];
                return _ArtistCircleTile(artist: artist);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 2. Albums Section (if any)
        if (state.albumResults.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            title: 'ALBUMS',
            count: state.albumResults.length,
            onSeeAll: () {
              context.read<SearchBloc>().add(
                    const SearchCategoryChanged('ALBUMS'),
                  );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: state.albumResults.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final album = state.albumResults[index];
                return _AlbumCardTile(album: album);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 3. Songs Section (if any)
        if (state.searchResults.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            title: 'SONGS',
            count: state.searchResults.length,
            onSeeAll: () {
              context.read<SearchBloc>().add(
                    const SearchCategoryChanged('SONGS'),
                  );
            },
          ),
          const SizedBox(height: 12),
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.searchResults.length > 8 ? 8 : state.searchResults.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final song = state.searchResults[index];
              return _GlobalSongTile(
                song: song,
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSongsOnlyView(BuildContext context) {
    if (state.searchResults.isEmpty) {
      return _buildEmptyCategoryState('No songs found matching "${state.query}"');
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.searchResults.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final song = state.searchResults[index];
        return _GlobalSongTile(
          song: song,
        );
      },
    );
  }

  Widget _buildArtistsOnlyView(BuildContext context) {
    if (state.artistResults.isEmpty) {
      return _buildEmptyCategoryState('No artists found matching "${state.query}"');
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: state.artistResults.length,
      itemBuilder: (context, index) {
        final artist = state.artistResults[index];
        return _ArtistCircleTile(artist: artist);
      },
    );
  }

  Widget _buildAlbumsOnlyView(BuildContext context) {
    if (state.albumResults.isEmpty) {
      return _buildEmptyCategoryState('No albums found matching "${state.query}"');
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: state.albumResults.length,
      itemBuilder: (context, index) {
        final album = state.albumResults[index];
        return _AlbumGridCard(album: album);
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    required VoidCallback onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTypography.labelSm(
                color: AppColors.secondary,
              ).copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            if (state.isLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.secondary,
                  ),
                ),
              ),
            ],
          ],
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'SEE ALL ($count)',
            style: AppTypography.labelSm(
              color: AppColors.onSurfaceVariant,
            ).copyWith(
              letterSpacing: 1.0,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCategoryState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36.0),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 36, color: AppColors.outline),
            const SizedBox(height: 10),
            Text(
              message,
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Artist Circle Tile ──────────────────────────────────────────────────────

class _ArtistCircleTile extends StatelessWidget {
  final Artist artist;

  const _ArtistCircleTile({required this.artist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArtistDetailScreen(artist: artist),
          ),
        );
      },
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerHigh,
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeImage(
                    urlOrPath: artist.imageUrl,
                    fit: BoxFit.cover,
                    fallback: _defaultAvatar(),
                  ),
                ),
                if (artist.isVerified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: AppColors.secondary,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Name
            Text(
              artist.name,
              style: AppTypography.bodySm(
                color: AppColors.primaryText,
              ).copyWith(fontWeight: FontWeight.w600, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Role / Tag
            Text(
              artist.role.isNotEmpty ? artist.role : 'Artist',
              style: AppTypography.labelSm(
                color: AppColors.onSurfaceVariant,
              ).copyWith(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Center(
        child: Icon(Icons.person_rounded, color: AppColors.outline, size: 34),
      ),
    );
  }
}

// ─── Album Card Tile (Horizontal) ────────────────────────────────────────────

class _AlbumCardTile extends StatelessWidget {
  final Album album;

  const _AlbumCardTile({required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AlbumDetailScreen(album: album),
          ),
        );
      },
      child: SizedBox(
        width: 125,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.15),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: SafeImage(
                urlOrPath: album.coverUrl,
                fit: BoxFit.cover,
                fallback: _defaultAlbumArt(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              style: AppTypography.bodySm(
                color: AppColors.primaryText,
              ).copyWith(fontWeight: FontWeight.w600, fontSize: 12.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              album.artist.isNotEmpty ? album.artist : album.year,
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

  Widget _defaultAlbumArt() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Center(
        child: Icon(Icons.album_rounded, color: AppColors.outline, size: 32),
      ),
    );
  }
}

// ─── Album Grid Card ─────────────────────────────────────────────────────────

class _AlbumGridCard extends StatelessWidget {
  final Album album;

  const _AlbumGridCard({required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AlbumDetailScreen(album: album),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.15),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: SafeImage(
                urlOrPath: album.coverUrl,
                fit: BoxFit.cover,
                fallback: _defaultAlbumArt(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.name,
            style: AppTypography.bodySm(
              color: AppColors.primaryText,
            ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            [
              if (album.artist.isNotEmpty) album.artist,
              if (album.year.isNotEmpty) album.year,
            ].join(' • '),
            style: AppTypography.labelSm(
              color: AppColors.onSurfaceVariant,
            ).copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _defaultAlbumArt() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Center(
        child: Icon(Icons.album_rounded, color: AppColors.outline, size: 36),
      ),
    );
  }
}

// ─── Global Song Tile ────────────────────────────────────────────────────────

class _GlobalSongTile extends StatefulWidget {
  final Song song;

  const _GlobalSongTile({required this.song});

  @override
  State<_GlobalSongTile> createState() => _GlobalSongTileState();
}

class _GlobalSongTileState extends State<_GlobalSongTile> {
  bool _pressed = false;

  void _playSong(BuildContext context) {
    HapticFeedback.lightImpact();
    // Play the selected song as a fresh single-track queue so that Autoplay
    // discovers musical recommendations matching the song's language, mood & genre,
    // rather than dumping arbitrary search results into Up Next.
    context.read<PlayerBloc>().add(
          PlayerPlayQueue([widget.song.toTrack()], initialIndex: 0),
        );
    PlayerScreen.open(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.graphic_eq_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Playing ${widget.song.title} • ${widget.song.artist}',
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

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final mins = song.duration.inMinutes;
    final secs = song.duration.inSeconds % 60;
    final durationText =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _playSong(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.surfaceContainer
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _pressed
                  ? AppColors.secondary.withValues(alpha: 0.3)
                  : AppColors.outlineVariant.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 48x48 Album Art Thumbnail with play overlay
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TrackArtwork(
                      albumArt: song.coverUrl,
                      trackId: song.id,
                      fit: BoxFit.cover,
                      fallback: _defaultThumbnail(),
                    ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Title and Artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: AppTypography.bodyMd(
                        color: AppColors.primary,
                      ).copyWith(fontWeight: FontWeight.w500, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: AppTypography.labelSm(
                        color: AppColors.onSurfaceVariant,
                      ).copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Duration text
              Text(
                durationText,
                style: AppTypography.labelSm(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                ).copyWith(fontSize: 10.5),
              ),
              const SizedBox(width: 8),

              // 320k / Audio quality badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '320k',
                  style: AppTypography.labelSm(color: AppColors.secondary)
                      .copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              const SizedBox(width: 4),

              // Trailing action / play button
              IconButton(
                icon: const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 24,
                  color: AppColors.secondary,
                ),
                onPressed: () => _playSong(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultThumbnail() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Icon(
        Icons.music_note_rounded,
        color: AppColors.outline,
        size: 22,
      ),
    );
  }
}
