import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/models.dart';
import '../../repositories/download_repository.dart';
import '../../theme/theme.dart';
import '../bloc/player_bloc.dart';
import 'track_artists_sheet.dart';

class PlayerMetaActions extends StatelessWidget {
  final Track track;
  final bool isLiked;

  const PlayerMetaActions({
    super.key,
    required this.track,
    required this.isLiked,
  });

  void _showAudioDetailsSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AUDIO METADATA',
                          style:
                              AppTypography.labelSm(
                                color: AppColors.secondary,
                              ).copyWith(
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _telemetryRow('Track Title', track.title),
                    _telemetryRow('Artist / Composer', track.artist),
                    _telemetryRow(
                      'Format & Bitrate',
                      '${track.formatBadge} · Uncompressed Bitstream',
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _telemetryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodySm(
                color: AppColors.primary,
              ).copyWith(fontWeight: FontWeight.w600, height: 1.2),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                track.title,
                style: AppTypography.headlineLgMobile(color: AppColors.primary)
                    .copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 26,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  showTrackArtistsSheet(context, track);
                },
                child: Text(
                  track.artist,
                  style: AppTypography.bodyMd(
                    color: AppColors.onSurfaceVariant,
                  ).copyWith(fontSize: 15, fontWeight: FontWeight.w400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            _ActionCircularButton(
              icon: isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              iconColor: isLiked
                  ? AppColors.secondary
                  : AppColors.onSurfaceVariant,
              tooltip: isLiked ? 'Favorited' : 'Favorite track',
              onTap: () {
                HapticFeedback.selectionClick();
                context.read<PlayerBloc>().add(const PlayerToggleLike());
              },
            ),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: Listenable.merge([
                DownloadRepository.instance.downloadedTrackIdsNotifier,
                DownloadRepository.instance.downloadProgressNotifier,
              ]),
              builder: (context, _) {
                final isDownloaded =
                    DownloadRepository.instance.isDownloaded(track.id);
                final isDownloading =
                    DownloadRepository.instance.isDownloading(track.id);
                final progress =
                    DownloadRepository.instance.getDownloadProgress(track.id);

                if (isDownloading) {
                  return SizedBox(
                    width: 38,
                    height: 38,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2.2,
                          color: const Color(0xFF26A69A),
                          backgroundColor:
                              AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                        ),
                        Text(
                          '${((progress ?? 0) * 100).toInt()}%',
                          style: const TextStyle(
                            color: Color(0xFF80CBC4),
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _ActionCircularButton(
                  icon: isDownloaded
                      ? Icons.download_done_rounded
                      : Icons.arrow_circle_down_rounded,
                  iconColor: isDownloaded
                      ? const Color(0xFF26A69A)
                      : AppColors.onSurfaceVariant,
                  tooltip: isDownloaded
                      ? 'Downloaded offline'
                      : 'Download for offline play',
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    if (isDownloaded) {
                      final playerBloc = context.read<PlayerBloc>();
                      await playerBloc.prepareForDownloadDeletion(track.id);
                      await DownloadRepository.instance.deleteDownload(track.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surfaceContainerHigh,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            content: Text(
                              'Removed "${track.title}" from offline downloads',
                              style: AppTypography.bodySm(
                                  color: AppColors.primaryText),
                            ),
                          ),
                        );
                      }
                    } else {
                      final playerState = context.read<PlayerBloc>().state;
                      final activeTrack =
                          (playerState.currentTrack?.id == track.id)
                              ? playerState.currentTrack!
                              : track;
                      DownloadRepository.instance.downloadTrack(activeTrack);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surfaceContainerHigh,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            content: Text(
                              'Downloading "${track.title}" for offline playback...',
                              style: AppTypography.bodySm(
                                  color: AppColors.primaryText),
                            ),
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
            const SizedBox(width: 10),
            _ActionCircularButton(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.onSurfaceVariant,
              tooltip: 'Master telemetry details',
              onTap: () => _showAudioDetailsSheet(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCircularButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionCircularButton({
    required this.icon,
    required this.iconColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ActionCircularButton> createState() => _ActionCircularButtonState();
}

class _ActionCircularButtonState extends State<_ActionCircularButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      verticalOffset: 32,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _pressed
                  ? AppColors.surfaceContainer
                  : AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
                width: 1.0,
              ),
              boxShadow: [
                if (!_pressed)
                  BoxShadow(
                    color: AppColors.outlineVariant.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Center(
              child: Icon(widget.icon, size: 20, color: widget.iconColor),
            ),
          ),
        ),
      ),
    );
  }
}
