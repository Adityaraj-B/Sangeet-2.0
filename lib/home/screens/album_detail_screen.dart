import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/track_artwork.dart';
import '../../main_layout/widgets/mini_player_bar.dart';
import '../../models/models.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../repositories/music_repository.dart';
import '../../theme/theme.dart';

class AlbumDetailScreen extends StatefulWidget {
  final Album album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  late Album _currentAlbum;
  bool _isLoading = true;
  List<Song> _songs = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentAlbum = widget.album;
    _songs = widget.album.songs;
    if (_songs.isEmpty) {
      _loadAlbumDetails();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadAlbumDetails() async {
    try {
      final fetched = await MusicRepository.instance.getAlbumById(
        widget.album.id,
      );
      if (mounted) {
        if (fetched != null && fetched.songs.isNotEmpty) {
          setState(() {
            _currentAlbum = fetched;
            _songs = fetched.songs;
            _isLoading = false;
          });
        } else {
          final songs = await MusicRepository.instance.getSongsByAlbum(
            widget.album.id,
          );
          if (mounted) {
            setState(() {
              _songs = songs;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load album tracks';
        });
      }
    }
  }

  void _playAll({bool shuffle = false}) {
    if (_songs.isEmpty) return;
    HapticFeedback.mediumImpact();
    final tracks = _songs.map((s) => s.toTrack()).toList();
    if (shuffle) tracks.shuffle();
    context.read<PlayerBloc>().add(PlayerPlayQueue(tracks, initialIndex: 0));
    PlayerScreen.open(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        content: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Text(
            shuffle
                ? 'Shuffling ${_currentAlbum.name}...'
                : 'Playing ${_currentAlbum.name}...',
            style: AppTypography.bodySm(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _playSong(Song song) {
    HapticFeedback.lightImpact();
    final tracks = _songs.map((s) => s.toTrack()).toList();
    final idx = tracks.indexWhere((t) => t.id == song.id);
    if (idx != -1) {
      context.read<PlayerBloc>().add(
        PlayerPlayQueue(tracks, initialIndex: idx),
      );
    } else {
      context.read<PlayerBloc>().add(PlayerPlayTrack(song.toTrack()));
    }
    PlayerScreen.open(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom + 90.0;
    final cover = _currentAlbum.coverUrl;

    return Scaffold(
      backgroundColor: AppColors.neutralCanvas,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          if (cover.isNotEmpty)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Opacity(
                  opacity: 0.35,
                  child: SafeImage(
                    urlOrPath: cover,
                    fit: BoxFit.cover,
                    fallback: const SizedBox(),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.neutralCanvas.withValues(alpha: 0.1),
                    AppColors.neutralCanvas.withValues(alpha: 0.8),
                    AppColors.neutralCanvas,
                  ],
                  stops: const [0.0, 0.4, 0.8],
                ),
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                leadingWidth: 68,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.neutralCanvas.withValues(alpha: 0.6),
                            AppColors.neutralCanvas.withValues(alpha: 0.2),
                          ],
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.05),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                leading: Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).maybePop();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  'Album',
                  style: AppTypography.bodyLg(
                    color: AppColors.primaryText,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 32,
                              spreadRadius: 4,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              SafeImage(
                                urlOrPath: cover,
                                fit: BoxFit.cover,
                                fallback: Container(
                                  color: AppColors.surfaceContainerHigh,
                                  child: const Icon(
                                    Icons.album_rounded,
                                    size: 64,
                                    color: AppColors.outline,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.2),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.2),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryAccent.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.secondaryAccent.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          'STUDIO MASTER',
                          style:
                              AppTypography.labelSm(
                                color: AppColors.secondaryAccent,
                              ).copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentAlbum.name,
                        textAlign: TextAlign.center,
                        style:
                            AppTypography.headlineMd(
                              color: AppColors.primaryText,
                            ).copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentAlbum.artist,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLg(
                          color: AppColors.onSurfaceVariant,
                        ).copyWith(fontWeight: FontWeight.w400),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        [
                          if (_currentAlbum.year.isNotEmpty) _currentAlbum.year,
                          if (_currentAlbum.language.isNotEmpty)
                            _currentAlbum.language.toUpperCase(),
                          '${_songs.isNotEmpty ? _songs.length : _currentAlbum.songCount} TRACKS',
                        ].join('  •  '),
                        style: AppTypography.labelSm(
                          color: AppColors.outline,
                        ).copyWith(fontSize: 11, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GlassActionButton(
                            icon: Icons.play_arrow_rounded,
                            label: 'PLAY',
                            isPrimary: true,
                            onTap: _songs.isNotEmpty ? () => _playAll() : null,
                          ),
                          const SizedBox(width: 16),
                          _GlassActionButton(
                            icon: Icons.shuffle_rounded,
                            label: 'SHUFFLE',
                            isPrimary: false,
                            onTap: _songs.isNotEmpty
                                ? () => _playAll(shuffle: true)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryAccent,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.outline,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _loadAlbumDetails();
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final song = _songs[index];
                      return _AlbumSongTile(
                        song: song,
                        index: index + 1,
                        onTap: () => _playSong(song),
                      );
                    }, childCount: _songs.length),
                  ),
                ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            child: const MiniPlayerBar(),
          ),
        ],
      ),
    );
  }
}

class _GlassActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<_GlassActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!isDisabled) widget.onTap!();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: widget.isPrimary
                  ? LinearGradient(
                      colors: [
                        AppColors.secondaryAccent.withValues(alpha: 0.9),
                        AppColors.secondaryAccent,
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
              border: Border.all(
                color: widget.isPrimary
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: widget.isPrimary && !isDisabled
                  ? [
                      BoxShadow(
                        color: AppColors.secondaryAccent.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: widget.isPrimary
                      ? Colors.white
                      : AppColors.primaryText,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style:
                      AppTypography.labelMd(
                        color: widget.isPrimary
                            ? Colors.white
                            : AppColors.primaryText,
                      ).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlbumSongTile extends StatefulWidget {
  final Song song;
  final int index;
  final VoidCallback onTap;

  const _AlbumSongTile({
    required this.song,
    required this.index,
    required this.onTap,
  });

  @override
  State<_AlbumSongTile> createState() => _AlbumSongTileState();
}

class _AlbumSongTileState extends State<_AlbumSongTile> {
  bool _pressed = false;

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, pState) {
        final isCurrent = pState.currentTrack?.id == widget.song.id;
        final isPlaying = isCurrent && pState.isPlaying;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            if (isCurrent) {
              context.read<PlayerBloc>().add(const PlayerTogglePlayPause());
            } else {
              widget.onTap();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            transformAlignment: Alignment.center,
            transform: Matrix4.diagonal3Values(
              _pressed ? 0.97 : 1.0,
              _pressed ? 0.97 : 1.0,
              1.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isCurrent
                  ? LinearGradient(
                      colors: [
                        AppColors.secondaryAccent.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: isCurrent
                  ? null
                  : Colors.white.withValues(alpha: _pressed ? 0.05 : 0.02),
              border: Border.all(
                color: isCurrent
                    ? AppColors.secondaryAccent.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: isCurrent
                            ? _PlayingIndicator(isPlaying: isPlaying)
                            : Text(
                                widget.index.toString().padLeft(2, '0'),
                                style:
                                    AppTypography.labelSm(
                                      color: AppColors.outline.withValues(
                                        alpha: 0.6,
                                      ),
                                    ).copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.song.title,
                              style:
                                  AppTypography.bodyMd(
                                    color: isCurrent
                                        ? AppColors.secondaryAccent
                                        : AppColors.primaryText,
                                  ).copyWith(
                                    fontWeight: isCurrent
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 14.5,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.song.artist,
                              style:
                                  AppTypography.bodySm(
                                    color: AppColors.onSurfaceVariant
                                        .withValues(alpha: 0.8),
                                  ).copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDuration(widget.song.duration),
                        style: AppTypography.labelSm(
                          color: AppColors.outline.withValues(alpha: 0.6),
                        ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        size: 28,
                        color: isCurrent
                            ? AppColors.secondaryAccent
                            : Colors.white.withValues(alpha: 0.15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayingIndicator extends StatefulWidget {
  final bool isPlaying;
  const _PlayingIndicator({required this.isPlaying});

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
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
  void didUpdateWidget(covariant _PlayingIndicator old) {
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
            final offset = (index * 0.3);
            final value = widget.isPlaying
                ? ((_ctrl.value + offset) % 1.0)
                : 0.2;
            final height = 4.0 + (value * 12.0);
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.only(right: 2.5),
              decoration: BoxDecoration(
                color: AppColors.secondaryAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}
