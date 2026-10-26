import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/theme.dart';
import '../bloc/player_bloc.dart';

class PlayerWaveformScrubber extends StatefulWidget {
  final double progress;
  final String currentTime;
  final String totalTime;
  final bool isPlaying;

  const PlayerWaveformScrubber({
    super.key,
    required this.progress,
    required this.currentTime,
    required this.totalTime,
    this.isPlaying = true,
  });

  @override
  State<PlayerWaveformScrubber> createState() => _PlayerWaveformScrubberState();
}

class _PlayerWaveformScrubberState extends State<PlayerWaveformScrubber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  double? _dragProgress;
  int? _lastHapticBarIndex;

  static const List<double> _barHeights = [
    0.32,
    0.52,
    0.38,
    0.72,
    0.88,
    0.58,
    0.78,
    0.98,
    0.68,
    0.44,
    0.82,
    0.94,
    0.64,
    0.48,
    0.78,
    0.90,
    0.42,
    0.70,
    0.96,
    0.60,
    0.86,
    0.74,
    0.50,
    0.66,
    0.92,
    0.72,
    0.42,
    0.32,
    0.56,
    0.82,
    0.62,
    0.46,
    0.28,
    0.42,
    0.64,
    0.50,
  ];

  bool get _isDragging => _dragProgress != null;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onDragStart(double fraction) {
    final clamped = fraction.clamp(0.0, 1.0);
    HapticFeedback.lightImpact();
    setState(() {
      _dragProgress = clamped;
      _lastHapticBarIndex = (clamped * _barHeights.length).floor();
    });
  }

  void _onDragUpdate(double fraction) {
    final clamped = fraction.clamp(0.0, 1.0);
    final currentBarIndex = (clamped * _barHeights.length).floor().clamp(
      0,
      _barHeights.length - 1,
    );

    if (currentBarIndex != _lastHapticBarIndex) {
      HapticFeedback.selectionClick();
      _lastHapticBarIndex = currentBarIndex;
    }

    setState(() => _dragProgress = clamped);
  }

  void _onDragEnd() {
    if (_dragProgress != null) {
      final finalSeek = _dragProgress!;
      HapticFeedback.lightImpact();
      context.read<PlayerBloc>().add(PlayerSeek(finalSeek));
      setState(() {
        _dragProgress = null;
        _lastHapticBarIndex = null;
      });
    }
  }

  void _handleTapSeek(double fraction) {
    final clamped = fraction.clamp(0.0, 1.0);
    HapticFeedback.mediumImpact();
    context.read<PlayerBloc>().add(PlayerSeek(clamped));
  }

  @override
  Widget build(BuildContext context) {
    final activeProgress = (_dragProgress ?? widget.progress).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Studio Acoustic Deck (Custom-Painted Stereo Waveform + Laser Playhead)
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  _handleTapSeek(details.localPosition.dx / maxWidth),
              onHorizontalDragStart: (details) =>
                  _onDragStart(details.localPosition.dx / maxWidth),
              onHorizontalDragUpdate: (details) =>
                  _onDragUpdate(details.localPosition.dx / maxWidth),
              onHorizontalDragEnd: (_) => _onDragEnd(),
              onHorizontalDragCancel: _onDragEnd,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.surfaceContainerLowest,
                      AppColors.surfaceContainerLowest.withValues(alpha: 0.88),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDragging
                        ? AppColors.secondary.withValues(alpha: 0.55)
                        : AppColors.outlineVariant.withValues(alpha: 0.16),
                    width: _isDragging ? 1.1 : 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(
                        alpha: _isDragging ? 0.16 : 0.0,
                      ),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                    const BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size(maxWidth - 20, 40),
                      painter: _StudioWaveformPainter(
                        barHeights: _barHeights,
                        progress: activeProgress,
                        phase: _pulseController.value * 2 * math.pi,
                        isPlaying: widget.isPlaying,
                        isDragging: _isDragging,
                        primaryColor: AppColors.primary,
                        secondaryColor: AppColors.secondary,
                        unplayedColor: AppColors.outlineVariant.withValues(
                          alpha: 0.34,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // 2. Precision Milled Dual-Line Scrubber
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final thumbPosition = (activeProgress * barWidth).clamp(
              0.0,
              barWidth,
            );
            final trackHeight = _isDragging ? 5.0 : 3.2;
            final thumbSize = _isDragging ? 20.0 : 16.0;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  _handleTapSeek(details.localPosition.dx / barWidth),
              onHorizontalDragStart: (details) =>
                  _onDragStart(details.localPosition.dx / barWidth),
              onHorizontalDragUpdate: (details) =>
                  _onDragUpdate(details.localPosition.dx / barWidth),
              onHorizontalDragEnd: (_) => _onDragEnd(),
              onHorizontalDragCancel: _onDragEnd,
              child: SizedBox(
                height: 24,
                width: barWidth,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  children: [
                    // Unplayed Recessed Track
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      height: trackHeight,
                      width: barWidth,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),

                    // Active Illuminated Gradient Track
                    AnimatedContainer(
                      duration: _isDragging
                          ? Duration.zero
                          : const Duration(milliseconds: 110),
                      curve: Curves.easeOutCubic,
                      height: trackHeight,
                      width: thumbPosition,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondary.withValues(alpha: 0.7),
                            AppColors.secondary,
                            AppColors.primary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(
                              alpha: _isDragging ? 0.55 : 0.25,
                            ),
                            blurRadius: _isDragging ? 8.0 : 4.0,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),

                    // Milled Hardware Scrubber Thumb (Fixed BoxShadow Lerp)
                    Positioned(
                      left: (thumbPosition - (thumbSize / 2)).clamp(
                        0.0,
                        barWidth - thumbSize,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        width: thumbSize,
                        height: thumbSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          border: Border.all(
                            color: AppColors.secondary.withValues(
                              alpha: _isDragging ? 1.0 : 0.0,
                            ),
                            width: _isDragging ? 1.6 : 0.0,
                          ),
                          // Keeping identical shadow count prevents negative blurRadius lerp bugs
                          boxShadow: [
                            const BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 6.0,
                              offset: Offset(0, 2),
                            ),
                            BoxShadow(
                              color: AppColors.secondary.withValues(
                                alpha: _isDragging ? 0.5 : 0.0,
                              ),
                              blurRadius: 12.0,
                              spreadRadius: _isDragging ? 2.0 : 0.0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            width: _isDragging ? 7.5 : 5.5,
                            height: _isDragging ? 7.5 : 5.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isDragging
                                  ? AppColors.secondary
                                  : AppColors.surfaceContainerLowest,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 3),

        // 3. Telemetry Timestamp Readout
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: _isDragging ? 6 : 0,
                vertical: 1.5,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(
                  alpha: _isDragging ? 0.14 : 0.0,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style:
                    AppTypography.labelSm(
                      color: _isDragging
                          ? AppColors.primary
                          : AppColors.secondary,
                    ).copyWith(
                      fontWeight: _isDragging
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                child: Text(widget.currentTime),
              ),
            ),
            Text(
              widget.totalTime,
              style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)
                  .copyWith(
                    fontSize: 11,
                    letterSpacing: 0.3,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Custom Painter for a high-craft stereo acoustic waveform with reflection
/// and a glowing playhead needle.
class _StudioWaveformPainter extends CustomPainter {
  final List<double> barHeights;
  final double progress;
  final double phase;
  final bool isPlaying;
  final bool isDragging;
  final Color primaryColor;
  final Color secondaryColor;
  final Color unplayedColor;

  const _StudioWaveformPainter({
    required this.barHeights,
    required this.progress,
    required this.phase,
    required this.isPlaying,
    required this.isDragging,
    required this.primaryColor,
    required this.secondaryColor,
    required this.unplayedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = barHeights.length;
    if (count == 0) return;

    final baselineY = size.height * 0.72; // 72% top wave, 28% stereo reflection
    final maxUpperHeight = baselineY - 2.0;
    final maxLowerHeight = (size.height - baselineY) - 2.0;
    final playheadX = (progress * size.width).clamp(0.0, size.width);

    // 1. Subtle studio horizon line
    final horizonPaint = Paint()
      ..color = unplayedColor.withValues(alpha: 0.18)
      ..strokeWidth = 0.7;
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      horizonPaint,
    );

    // 2. Ambient radial glow behind the active playhead
    if (isPlaying || isDragging) {
      final glowRadius = isDragging ? 38.0 : 26.0;
      final glowPaint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                secondaryColor.withValues(alpha: isDragging ? 0.28 : 0.16),
                secondaryColor.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(playheadX, baselineY * 0.6),
                radius: glowRadius,
              ),
            );
      canvas.drawCircle(
        Offset(playheadX, baselineY * 0.6),
        glowRadius,
        glowPaint,
      );
    }

    // 3. Draw Upper Acoustic Bars + Lower Mirrored Reflection Bars
    final slotWidth = size.width / count;
    final baseBarWidth = (slotWidth * 0.56).clamp(2.4, 4.2);

    for (int i = 0; i < count; i++) {
      final barStart = i / count;
      final barEnd = (i + 1) / count;
      final barCenter = (i + 0.5) / count;
      final centerX = barCenter * size.width;

      final fillAmount = ((progress - barStart) / (barEnd - barStart)).clamp(
        0.0,
        1.0,
      );

      final distFromPlayhead = (barCenter - progress).abs();
      final proximity = (1.0 - (distFromPlayhead * 6.5)).clamp(0.0, 1.0);

      // Organic harmonic oscillation
      final harmonic =
          math.sin(phase + (i * 0.48)) * 0.07 +
          math.cos((phase * 0.5) - (i * 0.25)) * 0.04;

      final dynamicBoost = isDragging
          ? (proximity * 0.26)
          : (isPlaying
                ? (fillAmount > 0 ? harmonic : 0.0) + (proximity * 0.14)
                : 0.0);

      final amplitude = (barHeights[i] + dynamicBoost).clamp(0.16, 1.0);
      final upperH = (maxUpperHeight * amplitude).clamp(3.0, maxUpperHeight);
      final lowerH = (maxLowerHeight * amplitude * 0.65).clamp(
        1.5,
        maxLowerHeight,
      );

      final barWidth = isDragging && proximity > 0.5
          ? baseBarWidth * 1.18
          : baseBarWidth;

      final activeColor = Color.lerp(
        secondaryColor,
        primaryColor,
        proximity * 0.5,
      )!;
      final mainBarColor = Color.lerp(unplayedColor, activeColor, fillAmount)!;

      // Soft neon bloom on bars near the playhead
      if (proximity > 0.55 && (isPlaying || isDragging)) {
        final bloomPaint = Paint()
          ..color = secondaryColor.withValues(alpha: proximity * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(centerX, baselineY - (upperH / 2) - 1.5),
              width: barWidth,
              height: upperH,
            ),
            const Radius.circular(99),
          ),
          bloomPaint,
        );
      }

      // Upper Main Bar
      final upperPaint = Paint()..color = mainBarColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, baselineY - (upperH / 2) - 1.5),
            width: barWidth,
            height: upperH,
          ),
          const Radius.circular(99),
        ),
        upperPaint,
      );

      // Lower Mirrored Stereo Reflection Bar
      final reflectionPaint = Paint()
        ..color = mainBarColor.withValues(alpha: fillAmount > 0 ? 0.28 : 0.12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, baselineY + (lowerH / 2) + 1.5),
            width: barWidth * 0.88,
            height: lowerH,
          ),
          const Radius.circular(99),
        ),
        reflectionPaint,
      );
    }

    // 4. Precision Laser Playhead Needle when Scrubbing
    if (isDragging) {
      final laserGlowPaint = Paint()
        ..color = secondaryColor.withValues(alpha: 0.65)
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawLine(
        Offset(playheadX, 1),
        Offset(playheadX, size.height - 1),
        laserGlowPaint,
      );

      final laserCorePaint = Paint()
        ..color = primaryColor
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(playheadX, 1),
        Offset(playheadX, size.height - 1),
        laserCorePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StudioWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.isDragging != isDragging;
  }
}
