import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/models.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../repositories/playlist_repository.dart';
import '../../theme/theme.dart';
import '../../components/playlist_skeleton.dart';
import '../../components/track_artwork.dart';
import '../../playlist/screens/playlist_detail_screen.dart';
import '../../playlist/services/importer.dart';

class HomePlaylistsSection extends StatelessWidget {
  const HomePlaylistsSection({super.key});

  void _showCreateDialog(BuildContext context) {
    final textController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                      AppColors.surfaceContainerHigh.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'New Curation',
                      style:
                          AppTypography.headlineMd(
                            color: AppColors.primaryText,
                          ).copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 24),
                    _GlassTextField(
                      controller: textController,
                      label: 'Playlist Name',
                      hint: 'e.g., Midnight Binaural Solitude',
                      autoFocus: true,
                    ),
                    const SizedBox(height: 16),
                    _GlassTextField(
                      controller: descController,
                      label: 'Description (optional)',
                      hint: 'e.g., Analog tapes & tube harmonics',
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SpotifyImportScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryAccent.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.secondaryAccent.withValues(
                              alpha: 0.4,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_download_outlined,
                              size: 18,
                              color: AppColors.secondaryAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Import from Spotify / YouTube',
                              style: AppTypography.labelMd(
                                color: AppColors.secondaryAccent,
                              ).copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryText,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTypography.labelMd(
                              color: AppColors.primaryText.withValues(
                                alpha: 0.7,
                              ),
                            ).copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            final name = textController.text.trim();
                            if (name.isNotEmpty) {
                              final newPl = PlaylistRepository.instance
                                  .createPlaylist(
                                    name: name,
                                    description:
                                        descController.text.trim().isNotEmpty
                                        ? descController.text.trim()
                                        : 'Curated by you',
                                  );
                              HapticFeedback.mediumImpact();
                              Navigator.of(dialogContext).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PlaylistDetailScreen(
                                    playlistId: newPl.id,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.secondaryAccent.withValues(
                                    alpha: 0.8,
                                  ),
                                  AppColors.secondaryAccent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondaryAccent.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'Create',
                              style: AppTypography.labelMd(color: Colors.white)
                                  .copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
      ]),
      builder: (context, _) {
        final isLoading = PlaylistRepository.instance.isLoading;
        final error = PlaylistRepository.instance.error;
        final playlists = PlaylistRepository.instance.playlists;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Playlists',
                        style: AppTypography.bodyLg(
                          color: AppColors.primaryText,
                        ).copyWith(fontWeight: FontWeight.w500, fontSize: 18),
                      ),
                      Text(
                        isLoading
                            ? 'SYNCHRONIZING WITH CLOUD...'
                            : error != null
                                ? 'SYNC INTERRUPTED'
                                : 'STUDIO ARCHIVES & CURATIONS',
                        style:
                            AppTypography.labelSm(
                              color: error != null
                                  ? AppColors.error
                                  : AppColors.primaryText.withValues(
                                      alpha: 0.5,
                                    ),
                            ).copyWith(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SpotifyImportScreen(),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHighest.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.secondaryAccent.withValues(
                                alpha: 0.35,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_download_outlined,
                                size: 13,
                                color: AppColors.secondaryAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'IMPORT',
                                style: AppTypography.labelSm(
                                  color: AppColors.secondaryAccent,
                                ).copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showCreateDialog(context);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryAccent.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.secondaryAccent.withValues(
                                alpha: 0.4,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                size: 14,
                                color: AppColors.secondaryAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'NEW',
                                style:
                                    AppTypography.labelSm(
                                      color: AppColors.secondaryAccent,
                                    ).copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 260,
              child: _buildHorizontalList(
                context,
                isLoading: isLoading,
                error: error,
                playlists: playlists,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalList(
    BuildContext context, {
    required bool isLoading,
    required String? error,
    required List<Playlist> playlists,
  }) {
    // Case 1: Initial loading state
    if (isLoading && playlists.isEmpty) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        clipBehavior: Clip.none,
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CreatePlaylistTile(
              onTap: () => _showCreateDialog(context),
            );
          }
          return const HomePlaylistCardSkeleton();
        },
      );
    }

    // Case 2: Fetch error with no cached data
    if (error != null && playlists.isEmpty) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        clipBehavior: Clip.none,
        itemCount: 2,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CreatePlaylistTile(
              onTap: () => _showCreateDialog(context),
            );
          }
          return HomePlaylistErrorCard(
            error: error,
            onRetry: () => PlaylistRepository.instance.retryFetch(),
          );
        },
      );
    }

    // Case 3: Empty playlists
    if (playlists.isEmpty) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        clipBehavior: Clip.none,
        itemCount: 2,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CreatePlaylistTile(
              onTap: () => _showCreateDialog(context),
            );
          }
          return HomePlaylistEmptyCard(
            onTap: () => _showCreateDialog(context),
          );
        },
      );
    }

    // Case 4: Playlists loaded
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      clipBehavior: Clip.none,
      itemCount: playlists.length + 1,
      separatorBuilder: (_, _) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CreatePlaylistTile(
            onTap: () => _showCreateDialog(context),
          );
        }
        final playlist = playlists[index - 1];
        return _HomePlaylistCard(playlist: playlist);
      },
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool autoFocus;

  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.autoFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: AppTypography.labelSm(
              color: AppColors.primaryText.withValues(alpha: 0.8),
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black.withValues(alpha: 0.15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            autofocus: autoFocus,
            style: AppTypography.bodyMd(color: AppColors.primaryText),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.bodySm(
                color: AppColors.primaryText.withValues(alpha: 0.4),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _CreatePlaylistTile extends StatefulWidget {
  final VoidCallback onTap;
  const _CreatePlaylistTile({required this.onTap});

  @override
  State<_CreatePlaylistTile> createState() => _CreatePlaylistTileState();
}

class _CreatePlaylistTileState extends State<_CreatePlaylistTile> {
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
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 170,
          decoration: BoxDecoration(
            borderRadius: AppRadii.radiusXl,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadii.radiusXl,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surfaceContainerHigh.withValues(alpha: 0.35),
                      AppColors.surfaceContainerHigh.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: AppRadii.radiusXl,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.secondaryAccent.withValues(alpha: 0.25),
                            AppColors.secondaryAccent.withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.secondaryAccent.withValues(
                            alpha: 0.4,
                          ),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondaryAccent.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.secondaryAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create Playlist',
                      style: AppTypography.bodyMd(
                        color: AppColors.primaryText,
                      ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Custom Curation',
                      style: AppTypography.labelSm(
                        color: AppColors.primaryText.withValues(alpha: 0.6),
                      ).copyWith(fontSize: 11, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePlaylistCard extends StatefulWidget {
  final Playlist playlist;
  const _HomePlaylistCard({required this.playlist});

  @override
  State<_HomePlaylistCard> createState() => _HomePlaylistCardState();
}

class _HomePlaylistCardState extends State<_HomePlaylistCard> {
  bool _hovered = false;
  bool _pressed = false;

  void _openPlaylist(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(playlistId: widget.playlist.id),
      ),
    );
  }

  void _playDirectly(BuildContext context) {
    if (widget.playlist.tracks.isEmpty) {
      _openPlaylist(context);
      return;
    }
    HapticFeedback.mediumImpact();
    context.read<PlayerBloc>().add(
      PlayerPlayQueue(widget.playlist.tracks, initialIndex: 0),
    );
    PlayerScreen.open(context);
  }

  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlist;
    final cover = playlist.coverUrl;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          _openPlaylist(context);
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
          child: Container(
            width: 250,
            decoration: BoxDecoration(
              borderRadius: AppRadii.radiusXl,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _hovered ? 0.3 : 0.15),
                  blurRadius: _hovered ? 32 : 24,
                  offset: Offset(0, _hovered ? 16 : 12),
                  spreadRadius: _hovered ? 2 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadii.radiusXl,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedScale(
                    scale: _hovered ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        image: safeImageProvider(cover) != null
                            ? DecorationImage(
                                image: safeImageProvider(cover)!,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: safeImageProvider(cover) == null
                          ? const Center(
                              child: Icon(
                                Icons.queue_music_rounded,
                                size: 48,
                                color: AppColors.outline,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            playlist.telemetryBadge,
                            style:
                                AppTypography.labelSm(
                                  color: AppColors.secondaryAccent,
                                ).copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _playDirectly(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                playlist.name,
                                style:
                                    AppTypography.headlineMd(
                                      color: Colors.white,
                                    ).copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      letterSpacing: -0.2,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                playlist.description,
                                style:
                                    AppTypography.bodySm(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ).copyWith(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${playlist.tracks.length} TRACKS',
                                      style:
                                          AppTypography.labelSm(
                                            color: AppColors.secondaryAccent,
                                          ).copyWith(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    playlist.formattedDuration,
                                    style:
                                        AppTypography.labelSm(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                        ).copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
