import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../artist/screens/artist_detail_screen.dart';
import '../../components/track_artwork.dart';
import '../../models/models.dart';
import '../../repositories/music_repository.dart';
import '../../theme/theme.dart';

/// Opens the Track Artists modal bottom sheet.
void showTrackArtistsSheet(BuildContext context, Track track) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => TrackArtistsSheet(track: track),
  );
}

class TrackArtistsSheet extends StatefulWidget {
  final Track track;

  const TrackArtistsSheet({super.key, required this.track});

  @override
  State<TrackArtistsSheet> createState() => _TrackArtistsSheetState();
}

class _TrackArtistsSheetState extends State<TrackArtistsSheet> {
  final Map<String, String> _artistPhotos = {};
  final Map<String, String> _artistIds = {};
  bool _isLoading = true;
  late final List<String> _artists;

  @override
  void initState() {
    super.initState();
    _artists = _parseArtists(widget.track.artist);
    _loadArtistTelemetry();
  }

  static List<String> _parseArtists(String raw) {
    if (raw.trim().isEmpty) return const ['Various Artists'];
    final normalized = raw
        .replaceAll(' feat. ', ', ')
        .replaceAll(' ft. ', ', ')
        .replaceAll(' Feat. ', ', ')
        .replaceAll(' Ft. ', ', ')
        .replaceAll(' & ', ', ')
        .replaceAll(' / ', ', ')
        .replaceAll(';', ',');

    final items = normalized
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    return items.isEmpty ? [raw.trim()] : items;
  }

  Future<void> _loadArtistTelemetry() async {
    for (int i = 0; i < _artists.length; i++) {
      final name = _artists[i];
      if (i == 0 && widget.track.artistId.isNotEmpty) {
        _artistIds[name] = widget.track.artistId;
      }

      try {
        final matches = await MusicRepository.instance.searchArtists(name);
        if (matches.isNotEmpty) {
          final first = matches.first;
          if (first.imageUrl.isNotEmpty) {
            _artistPhotos[name] = first.imageUrl;
          }
          if (first.id.isNotEmpty && (!_artistIds.containsKey(name) || _artistIds[name]!.isEmpty)) {
            _artistIds[name] = first.id;
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToArtist(BuildContext context, String name, int index) {
    HapticFeedback.lightImpact();
    final nav = Navigator.of(context);
    final resolvedId = _artistIds[name] ??
        (index == 0 && widget.track.artistId.isNotEmpty
            ? widget.track.artistId
            : name);
    final photo = _artistPhotos[name] ?? '';

    // Pop the bottom sheet first, then push the Artist detail screen onto the player navigation stack
    nav.pop();
    nav.push(
      MaterialPageRoute(
        builder: (_) => ArtistDetailScreen(
          artist: Artist(
            id: resolvedId,
            name: name,
            imageUrl: photo,
            role: index == 0 ? 'Primary Artist' : 'Featured Artist',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: _artists.length > 2 ? 0.60 : 0.48,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (sheetCtx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TRACK ARTISTS',
                      style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '${_artists.length}',
                        style: AppTypography.labelSm(color: AppColors.primary).copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isLoading) ...[
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
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // 3. Track Reference Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: widget.track.albumArt != null && widget.track.albumArt!.isNotEmpty
                            ? SafeImage(
                                urlOrPath: widget.track.albumArt!,
                                fit: BoxFit.cover,
                                fallback: const Icon(
                                  Icons.music_note_rounded,
                                  color: AppColors.outline,
                                  size: 20,
                                ),
                              )
                            : const Icon(
                                Icons.music_note_rounded,
                                color: AppColors.outline,
                                size: 20,
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.track.title,
                            style: AppTypography.bodySm(color: AppColors.primary).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select an artist below to explore their discography',
                            style: AppTypography.labelSm(color: AppColors.onSurfaceVariant).copyWith(
                              fontSize: 10.5,
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

              const SizedBox(height: 6),

              // 4. Scrollable Artists List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 6,
                    bottom: bottomInset + 20,
                  ),
                  itemCount: _artists.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final name = _artists[index];
                    final photo = _artistPhotos[name];
                    final isPrimary = index == 0;

                    return _ArtistTile(
                      name: name,
                      photoUrl: photo,
                      role: isPrimary ? 'Primary Artist' : 'Featured Artist',
                      onTap: () => _navigateToArtist(context, name, index),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArtistTile extends StatefulWidget {
  final String name;
  final String? photoUrl;
  final String role;
  final VoidCallback onTap;

  const _ArtistTile({
    required this.name,
    this.photoUrl,
    required this.role,
    required this.onTap,
  });

  @override
  State<_ArtistTile> createState() => _ArtistTileState();
}

class _ArtistTileState extends State<_ArtistTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _pressed ? AppColors.surfaceContainerHigh : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _pressed
                  ? AppColors.secondary.withValues(alpha: 0.3)
                  : AppColors.outlineVariant.withValues(alpha: 0.15),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              // Circular Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHighest,
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                      ? SafeImage(
                          urlOrPath: widget.photoUrl!,
                          fit: BoxFit.cover,
                          fallback: _buildInitialFallback(),
                        )
                      : _buildInitialFallback(),
                ),
              ),
              const SizedBox(width: 14),

              // Name & Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: AppTypography.bodyMd(color: AppColors.primary).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.role == 'Primary Artist'
                            ? AppColors.secondary.withValues(alpha: 0.15)
                            : AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.role.toUpperCase(),
                        style: AppTypography.labelSm(
                          color: widget.role == 'Primary Artist'
                              ? AppColors.secondary
                              : AppColors.onSurfaceVariant,
                        ).copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Trailing Action Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EXPLORE',
                      style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialFallback() {
    final initial = widget.name.trim().isNotEmpty
        ? widget.name.trim()[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        initial,
        style: AppTypography.headlineMd(color: AppColors.secondary).copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
