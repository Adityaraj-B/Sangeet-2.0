import 'package:flutter/material.dart';
import '../../components/track_artwork.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';

class PlayerArtworkHero extends StatelessWidget {
  final Track track;

  const PlayerArtworkHero({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x8C000000),
              blurRadius: 32,
              spreadRadius: 2,
              offset: Offset(0, 14),
            ),
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.surfaceContainerLow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Universal Offline-Ready Cover Image
              TrackArtwork(
                albumArt: track.albumArt,
                trackId: track.id,
                fit: BoxFit.cover,
                fallback: Container(
                  color: AppColors.surfaceContainerLowest,
                  child: const Center(
                    child: Icon(
                      Icons.album_rounded,
                      size: 64,
                      color: AppColors.outline,
                    ),
                  ),
                ),
              ),

              // Ambient Vignette Scrim Overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xE60E0E0F),
                      Color(0x330E0E0F),
                      Color(0x000E0E0F),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // Bottom Artwork Badges / Telemetry Stamp
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.25),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        track.formatBadge.isNotEmpty
                            ? track.formatBadge.toUpperCase()
                            : '96K / 24-BIT PCM MASTER',
                        style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                          fontSize: 9,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                      ),
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
}
