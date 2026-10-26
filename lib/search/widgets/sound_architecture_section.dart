import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/track_artwork.dart';
import '../../insights/services/insight_service.dart';
import '../../models/models.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../repositories/history_repository.dart';
import '../../repositories/music_repository.dart';
import '../../theme/theme.dart';

class SoundArchitectureSection extends StatefulWidget {
  const SoundArchitectureSection({super.key});

  @override
  State<SoundArchitectureSection> createState() =>
      _SoundArchitectureSectionState();
}

class _SoundArchitectureSectionState extends State<SoundArchitectureSection> {
  List<Song> _relatedSongs = [];
  String? _lastLoadedMood;
  String? _lastLoadedSongId;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
    ListeningInsightsService.instance.addListener(_onDataChanged);
    HistoryRepository.instance.historyNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    ListeningInsightsService.instance.removeListener(_onDataChanged);
    HistoryRepository.instance.historyNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
      _fetchRecommendations();
    }
  }

  Future<void> _fetchRecommendations() async {
    final insights = ListeningInsightsService.instance;
    final topSong = insights.getMostListenedSong();
    final topMood = insights.getPrimaryConsumedMood(defaultMood: 'Romantic');

    final songId = topSong?.id;
    if (songId == _lastLoadedSongId && topMood == _lastLoadedMood) {
      return;
    }
    _lastLoadedSongId = songId;
    _lastLoadedMood = topMood;

    try {
      List<Song> fetched = [];
      if (songId != null && songId.isNotEmpty) {
        fetched = await MusicRepository.instance.getSongSuggestions(songId);
      }
      if (fetched.isEmpty) {
        final query = topMood.toLowerCase() == 'romantic'
            ? 'romantic hits'
            : '$topMood songs';
        fetched = await MusicRepository.instance.searchSongs(query);
      }

      if (mounted && fetched.isNotEmpty) {
        setState(() {
          _relatedSongs =
              fetched.where((s) => s.id != songId).toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final insights = ListeningInsightsService.instance;
    final mostListenedSong = insights.getMostListenedSong();
    final topMood = insights.getPrimaryConsumedMood(defaultMood: 'Romantic');

    // Stats for most listened song
    final (playCount, totalSeconds) = mostListenedSong != null
        ? insights.getSongStats(mostListenedSong.id)
        : (0, 0);
    final totalMins = totalSeconds ~/ 60;

    // Pick related song (or fallback)
    final Song? relatedSong = _relatedSongs.isNotEmpty ? _relatedSongs.first : null;

    final moodUpper = topMood.toUpperCase();
    final counterLabel = mostListenedSong != null
        ? 'TAILORED • $moodUpper'
        : 'CURATED ARCHIVES';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        _SectionHeader(
          title: 'Sound Architecture',
          counter: counterLabel,
        ),
        const SizedBox(height: 12),

        // ─── Card 1: Most Listened Song (or Flagship Master) ─────────────
        if (mostListenedSong != null)
          _ArchitectureCard(
            key: ValueKey('most-listened-${mostListenedSong.id}'),
            imageUrl: mostListenedSong.coverUrl.isNotEmpty
                ? mostListenedSong.coverUrl
                : _defaultCoverForMood(topMood),
            telemetryPill: playCount > 1
                ? 'HEAVY ROTATION • $playCount PLAYS'
                : 'MOST LISTENED TRACK',
            category: mostListenedSong.mood.isNotEmpty
                ? '${mostListenedSong.mood.toUpperCase()} • PERSONAL ARCHIVE'
                : 'PERSONAL ARCHIVE',
            title: mostListenedSong.title,
            description:
                'by ${mostListenedSong.artist} • ${totalMins > 0 ? '$totalMins mins listened • ' : ''}Most consumed track in your library.',
            onTap: () {
              final track = mostListenedSong.toTrack();
              context.read<PlayerBloc>().add(PlayerPlayTrack(track));
              PlayerScreen.open(context);
              _showSnackBar(
                context,
                'Playing your most listened song: ${mostListenedSong.title}',
              );
            },
          )
        else
          // Default flagship romantic master for new users
          _ArchitectureCard(
            key: const ValueKey('default-most-listened'),
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBqS-KFs5hRD5rOrCiVN2UOXOmjoKjeDKI6njbn9vX-VWjOg3eYO3CEKdRtX9awm6BtrQNDs8eKWc8TfHN5kthgwCwYBLc3kH3BjZIyOMdVzqwdsE0eNhjLHGS1k6DYJKy2e3dzuI9dk7rG-kIw4lUHZ7sf3zfVjUPwEwIzVBGxhglKCFjjN-gQW0VNUwyyUwgpHhN8yMOBKpodtXpdHGRQ1WdabHkb0mgdFtMCHH_9zeb0tMrd1xyH-w',
            telemetryPill: 'STUDIO MASTER • 320 KBPS',
            category: 'ROMANTIC RESONANCE',
            title: 'Acoustic Spaces & Romantic Chambers',
            description:
                'Historic hall acoustics and resonant melodic strings captured in pristine uncompressed fidelity.',
            onTap: () async {
              try {
                final songs =
                    await MusicRepository.instance.searchSongs('romantic hits');
                if (songs.isNotEmpty && context.mounted) {
                  final tracks = songs.map((s) => s.toTrack()).toList();
                  context.read<PlayerBloc>().add(
                        PlayerPlayQueue(tracks, initialIndex: 0),
                      );
                  PlayerScreen.open(context);
                  return;
                }
              } catch (_) {}
              if (context.mounted) {
                PlayerScreen.open(context);
              }
            },
          ),

        const SizedBox(height: 12),

        // ─── Card 2: Related to Top Consumed Music (Romantic, etc.) ───────
        if (relatedSong != null)
          _ArchitectureCard(
            key: ValueKey('related-song-${relatedSong.id}'),
            imageUrl: relatedSong.coverUrl.isNotEmpty
                ? relatedSong.coverUrl
                : _defaultCoverForMood(topMood),
            telemetryPill: '$moodUpper RESONANCE • TOP TASTE',
            category: 'RELATED TO YOUR TASTE • $moodUpper',
            title: relatedSong.title,
            description:
                'by ${relatedSong.artist} • Curated master recording aligned with your high affinity for ${topMood.toLowerCase()} music.',
            onTap: () {
              if (_relatedSongs.length > 1) {
                final tracks = _relatedSongs.map((s) => s.toTrack()).toList();
                final idx = tracks.indexWhere((t) => t.id == relatedSong.id);
                context.read<PlayerBloc>().add(
                      PlayerPlayQueue(
                        tracks,
                        initialIndex: idx != -1 ? idx : 0,
                      ),
                    );
              } else {
                context.read<PlayerBloc>().add(
                      PlayerPlayTrack(relatedSong.toTrack()),
                    );
              }
              PlayerScreen.open(context);
              _showSnackBar(
                context,
                'Playing $topMood Architecture: ${relatedSong.title}',
              );
            },
          )
        else
          // Dynamic mood architecture card
          _ArchitectureCard(
            key: ValueKey('curated-mood-$topMood'),
            imageUrl: _defaultCoverForMood(topMood),
            telemetryPill: '$moodUpper VAULT • 24-BIT PCM',
            category: 'RELATED TO YOUR CONSUMPTION',
            title: '$topMood Sonic Architecture',
            description:
                'Deep harmonic warmth and stereo soundscapes tailored to your preference for $topMood music.',
            onTap: () async {
              try {
                final songs = await MusicRepository.instance.searchSongs(
                  topMood.toLowerCase() == 'romantic'
                      ? 'romantic melodies'
                      : '$topMood hits',
                );
                if (songs.isNotEmpty && context.mounted) {
                  final tracks = songs.map((s) => s.toTrack()).toList();
                  context.read<PlayerBloc>().add(
                        PlayerPlayQueue(tracks, initialIndex: 0),
                      );
                  PlayerScreen.open(context);
                  return;
                }
              } catch (_) {}
              if (context.mounted) {
                PlayerScreen.open(context);
              }
            },
          ),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message) {
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
                message,
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

  String _defaultCoverForMood(String mood) {
    final m = mood.toLowerCase();
    if (m.contains('romantic') || m.contains('love') || m.contains('heart')) {
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuBqS-KFs5hRD5rOrCiVN2UOXOmjoKjeDKI6njbn9vX-VWjOg3eYO3CEKdRtX9awm6BtrQNDs8eKWc8TfHN5kthgwCwYBLc3kH3BjZIyOMdVzqwdsE0eNhjLHGS1k6DYJKy2e3dzuI9dk7rG-kIw4lUHZ7sf3zfVjUPwEwIzVBGxhglKCFjjN-gQW0VNUwyyUwgpHhN8yMOBKpodtXpdHGRQ1WdabHkb0mgdFtMCHH_9zeb0tMrd1xyH-w';
    }
    if (m.contains('acoustic') || m.contains('folk') || m.contains('chill')) {
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuCvj6GPvfHLZZ9DEypg_tTiBMzkSAmKXvcyNyfxRAd6T9oT_xaBii0CTiSmoe7AVilxBRgEDAf18Gz2A5PBc_x5kM9xcp1QLIe_b0aydcfF-WUIvgigh6Xqy70t5hxW5WoT-ngqfVGZtn75XR8mTOAE9feDmoMMz9TJRzSId8dNRRnhTQaIYmU_EvCWYbfmUhGQ_TKAVJSknCiu2oivj0Hb2JdgDUEa_BCqEV4mINhtMRPbwZBHAftibg';
    }
    return 'https://lh3.googleusercontent.com/aida-public/AB6AXuBNzLZksSemNPgQpa3D2bdFpRhyV3j3JbEvUzxglln1HhDI4F0ShCJhmAKCSoVff_l0YVHkE7yl75DpK49tzUXBTpNX-C-mVZicNJfdqRA-a6T89THqIjgMXZ3e5NEsMNt1e4GEi3vgEehi-Yvi-gYws91_so_Paed_7cKg-mFLlxy36QOLS200l0dziTSnJ5F51lSEYeRksnXWiKMgCWND_iW4dXhEHEHeg1Q6ovqSHzQZRUjVY61Isw';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String counter;

  const _SectionHeader({required this.title, required this.counter});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.headlineMd(color: AppColors.primary).copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          counter,
          style: AppTypography.labelSm(color: AppColors.secondary)
              .copyWith(letterSpacing: 1.5, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ArchitectureCard extends StatefulWidget {
  final String imageUrl;
  final String telemetryPill;
  final String category;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ArchitectureCard({
    super.key,
    required this.imageUrl,
    required this.telemetryPill,
    required this.category,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  State<_ArchitectureCard> createState() => _ArchitectureCardState();
}

class _ArchitectureCardState extends State<_ArchitectureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 224,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressed
                  ? AppColors.secondary.withValues(alpha: 0.35)
                  : AppColors.outlineVariant.withValues(alpha: 0.14),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              SafeImage(
                urlOrPath: widget.imageUrl,
                fit: BoxFit.cover,
                fallback: Container(
                  color: AppColors.surfaceContainerLowest,
                  child: const Center(
                    child: Icon(
                      Icons.music_note_rounded,
                      color: AppColors.outline,
                      size: 48,
                    ),
                  ),
                ),
              ),

              // Gradient Overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xF20E0E0F),
                      Color(0x990E0E0F),
                      Color(0x000E0E0F),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),

              // Top Precision Telemetry Pill
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest.withValues(
                      alpha: 0.85,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                      width: 0.7,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.telemetryPill.toUpperCase(),
                        style: AppTypography.labelSm(color: AppColors.secondary)
                            .copyWith(
                          fontSize: 9.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Play Icon indicator (subtle glass circle at top right)
              Positioned(
                top: 12,
                right: 12,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.category,
                        style: AppTypography.labelSm(
                          color: AppColors.secondary.withValues(alpha: 0.9),
                        ).copyWith(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        style: AppTypography.bodyLg(color: AppColors.primary)
                            .copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.description,
                        style: AppTypography.bodySm(
                          color: AppColors.onSurfaceVariant,
                        ).copyWith(fontSize: 12, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
