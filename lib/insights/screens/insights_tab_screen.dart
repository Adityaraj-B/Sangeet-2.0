import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/track_artwork.dart';
import '../../models/models.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/screens/player_screen.dart';
import '../../theme/theme.dart';
import '../models/listening_insights.dart';
import '../services/insight_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class InsightsTabScreen extends StatefulWidget {
  const InsightsTabScreen({super.key});

  @override
  State<InsightsTabScreen> createState() => _InsightsTabScreenState();
}

class _InsightsTabScreenState extends State<InsightsTabScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _stagger(int index, Widget child) {
    final start = (index * 0.09).clamp(0.0, 0.55);
    final end = (start + 0.46).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ListeningInsightsService.instance,
      builder: (context, _) {
        final summary = ListeningInsightsService.instance.computeSummary();
        final canPop = Navigator.canPop(context);

        return Scaffold(
          backgroundColor: AppColors.neutralCanvas,
          body: Stack(
            children: [
              // ── background atmosphere ──────────────────────────────────
              _GlowOrb(
                top: -200,
                right: -110,
                size: 460,
                color: AppColors.secondaryAccent,
                opacity: 0.09,
              ),
              _GlowOrb(
                top: 300,
                left: -160,
                size: 340,
                color: AppColors.secondaryAccent,
                opacity: 0.055,
              ),
              _GlowOrb(
                bottom: 100,
                right: -90,
                size: 300,
                color: AppColors.primary,
                opacity: 0.04,
              ),

              // ── scrollable content ────────────────────────────────────
              CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          canPop ? 12 : 68,
                          20,
                          0,
                        ),
                        child: _stagger(0, _TopStudioBar(canPop: canPop)),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _stagger(
                        1,
                        _HeroTelemetryConsole(summary: summary),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _stagger(
                        2,
                        _TemporalOscilloscopeDeck(summary: summary),
                      ),
                    ),
                  ),
                  if (summary.topArtists.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                      sliver: SliverToBoxAdapter(
                        child: _stagger(
                          3,
                          _ArtistPressingCarousel(artists: summary.topArtists),
                        ),
                      ),
                    ),
                  if (summary.topMoods.isNotEmpty ||
                      summary.topLanguages.isNotEmpty ||
                      summary.topGenres.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _stagger(
                          4,
                          _SonicHarmonicRose(summary: summary),
                        ),
                      ),
                    ),
                  if (summary.forgottenLikedSongs.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _stagger(
                          5,
                          _ArchiveCrateFlipDeck(
                            songs: summary.forgottenLikedSongs,
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared utility widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Soft radial gradient orb for atmospheric background depth.
class _GlowOrb extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;
  final double opacity;

  const _GlowOrb({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: opacity * 0.4),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated pulsing dot — premium live indicator.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return SizedBox(
          width: 18,
          height: 18,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 7 + (_pulse.value * 9),
                height: 7 + (_pulse.value * 9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryAccent.withValues(
                    alpha: 0.22 * (1 - _pulse.value),
                  ),
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryAccent,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryAccent.withValues(alpha: 0.7),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Premium frosted panel with glass-highlight top edge.
class _AcrylicPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _AcrylicPanel({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.radiusDefault,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.frostedGlass,
            borderRadius: AppRadii.radiusDefault,
            border: Border.all(color: AppColors.ghostBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 40,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            children: [
              // glass highlight stripe
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: AppRadii.radiusDefault,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Scale-and-haptic tap gesture with press spring.
class _TactileTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TactileTap({required this.child, required this.onTap});

  @override
  State<_TactileTap> createState() => _TactileTapState();
}

class _TactileTapState extends State<_TactileTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.955 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top studio bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopStudioBar extends StatelessWidget {
  final bool canPop;
  const _TopStudioBar({required this.canPop});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (canPop)
          _TactileTap(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: AppTheme.recessedBayDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primaryText,
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LIBRARY',
                    style: AppTypography.labelSm(color: AppColors.primaryText)
                        .copyWith(
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          Row(
            children: [
              const _PulsingDot(),
              const SizedBox(width: 9),
              Text(
                'ACOUSTIC TELEMETRY',
                style: AppTypography.labelSm(color: AppColors.primaryText)
                    .copyWith(
                      fontSize: 11,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),

        // SYS // LIVE badge with subtle glow
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.subSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.secondaryAccent.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryAccent.withValues(alpha: 0.18),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Text(
            'SYS // LIVE',
            style: AppTypography.labelSm(color: AppColors.secondaryAccent)
                .copyWith(
                  fontSize: 9.5,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero telemetry console
// ─────────────────────────────────────────────────────────────────────────────

class _HeroTelemetryConsole extends StatefulWidget {
  final UserInsightsSummary summary;
  const _HeroTelemetryConsole({required this.summary});

  @override
  State<_HeroTelemetryConsole> createState() => _HeroTelemetryConsoleState();
}

class _HeroTelemetryConsoleState extends State<_HeroTelemetryConsole> {
  int _focusedBay = 0;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final monthlyHours = summary.currentMonthListeningTime.inMinutes / 60.0;
    final allTimeHours = summary.totalListeningTime.inMinutes / 60.0;
    final growth = summary.monthlyGrowthPercent;

    final completionRatio = (summary.completionRate / 100.0).clamp(0.0, 1.0);
    final streakRatio = summary.longestStreakDays > 0
        ? (summary.currentStreakDays / summary.longestStreakDays).clamp(
            0.0,
            1.0,
          )
        : 0.0;
    final monthlyShareRatio = allTimeHours > 0
        ? (monthlyHours / allTimeHours).clamp(0.0, 1.0)
        : 0.0;

    final dialConfigs = [
      (
        ratio: completionRatio,
        value: '${summary.completionRate.toStringAsFixed(0)}%',
        label: 'COMPLETION',
      ),
      (
        ratio: streakRatio,
        value: '${summary.currentStreakDays}d',
        label: 'STREAK GOAL',
      ),
      (
        ratio: monthlyShareRatio,
        value: '${(monthlyShareRatio * 100).toStringAsFixed(0)}%',
        label: 'MO / TOTAL',
      ),
    ];

    final activeDial = dialConfigs[_focusedBay];
    final growthPositive = growth >= 0;

    return _AcrylicPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── left: metrics ──────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (summary.listenerPersona.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryAccent.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppColors.secondaryAccent.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondaryAccent.withValues(
                                      alpha: 0.8,
                                    ),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                summary.listenerPersona.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    AppTypography.labelSm(
                                      color: AppColors.secondaryAccent,
                                    ).copyWith(
                                      fontSize: 9.5,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      'MONTHLY SESSION TIME',
                      style:
                          AppTypography.labelSm(
                            color: AppColors.onSurfaceVariant,
                          ).copyWith(
                            fontSize: 9.5,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 5),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: monthlyHours),
                      duration: const Duration(milliseconds: 950),
                      curve: Curves.easeOutQuart,
                      builder: (_, val, _) {
                        return RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: val.toStringAsFixed(1),
                                style:
                                    AppTypography.headlineMd(
                                      color: AppColors.primaryText,
                                    ).copyWith(
                                      fontSize: 46,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -1.5,
                                      height: 1.0,
                                    ),
                              ),
                              TextSpan(
                                text: ' HRS',
                                style:
                                    AppTypography.labelMd(
                                      color: AppColors.secondaryAccent,
                                    ).copyWith(
                                      fontSize: 13,
                                      letterSpacing: 1.4,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // growth badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryAccent.withValues(
                          alpha: growthPositive ? 0.13 : 0.07,
                        ),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: AppColors.secondaryAccent.withValues(
                            alpha: growthPositive ? 0.35 : 0.2,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            growthPositive
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 9,
                            color: AppColors.secondaryAccent.withValues(
                              alpha: growthPositive ? 1.0 : 0.6,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${growth.abs().toStringAsFixed(0)}% VS LAST MONTH',
                            style:
                                AppTypography.labelSm(
                                  color: AppColors.secondaryAccent.withValues(
                                    alpha: growthPositive ? 1.0 : 0.7,
                                  ),
                                ).copyWith(
                                  fontSize: 9,
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // ── right: dial ────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _focusedBay = (_focusedBay + 1) % 3);
                },
                child: Container(
                  width: 116,
                  height: 116,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.subSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.ghostBorderActive,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryAccent.withValues(
                          alpha: 0.12,
                        ),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(_focusedBay),
                    tween: Tween(begin: 0, end: activeDial.ratio),
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.easeOutCubic,
                    builder: (_, val, _) {
                      return CustomPaint(
                        painter: _AcousticDialPainter(
                          progress: val,
                          accentColor: AppColors.secondaryAccent,
                          trackColor: AppColors.ghostBorder,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                activeDial.value,
                                style:
                                    AppTypography.titleSm(
                                      color: AppColors.primaryText,
                                    ).copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeDial.label,
                                style:
                                    AppTypography.labelSm(
                                      color: AppColors.onSurfaceVariant,
                                    ).copyWith(
                                      fontSize: 7,
                                      letterSpacing: 1.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── bay tiles ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _TelemetryBayTile(
                  label: 'COMPLETION',
                  value: '${summary.completionRate.toStringAsFixed(0)}%',
                  sub: '${summary.likedSongsCount} liked',
                  isSelected: _focusedBay == 0,
                  onTap: () => setState(() => _focusedBay = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TelemetryBayTile(
                  label: 'STREAK',
                  value: '${summary.currentStreakDays}d',
                  sub: 'Best ${summary.longestStreakDays}d',
                  isSelected: _focusedBay == 1,
                  onTap: () => setState(() => _focusedBay = 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TelemetryBayTile(
                  label: 'ALL-TIME',
                  value: '${allTimeHours.toStringAsFixed(1)}h',
                  sub: '${summary.totalSongsPlayed} plays',
                  isSelected: _focusedBay == 2,
                  onTap: () => setState(() => _focusedBay = 2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TelemetryBayTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool isSelected;
  final VoidCallback onTap;

  const _TelemetryBayTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainer : AppColors.subSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.ghostBorderActive
                : AppColors.ghostBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondaryAccent.withValues(alpha: 0.18),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTypography.labelSm(
                          color: isSelected
                              ? AppColors.secondaryAccent
                              : AppColors.onSurfaceVariant,
                        ).copyWith(
                          fontSize: 8.5,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondaryAccent,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondaryAccent.withValues(
                            alpha: 0.8,
                          ),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: AppTypography.titleSm(
                color: AppColors.primaryText,
              ).copyWith(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm(
                color: AppColors.outline,
              ).copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Acoustic dial painter — premium glowing arc
// ─────────────────────────────────────────────────────────────────────────────

class _AcousticDialPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final Color trackColor;

  _AcousticDialPainter({
    required this.progress,
    required this.accentColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) / 2) - 5;
    const startAngle = 135 * (pi / 180);
    const sweepTotal = 270 * (pi / 180);


    const dotCount = 36;
    for (var i = 0; i < dotCount; i++) {
      final angle = startAngle + (sweepTotal / dotCount) * i;
      final dx = center.dx + (radius + 7) * cos(angle);
      final dy = center.dy + (radius + 7) * sin(angle);
      canvas.drawCircle(
        Offset(dx, dy),
        0.9,
        Paint()..color = trackColor.withValues(alpha: 0.35),
      );
    }

    // track arc
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // tick marks — alternating major/minor
    for (var i = 0; i <= 20; i++) {
      final isMajor = i % 5 == 0;
      final angle = startAngle + (sweepTotal * (i / 20));
      final innerR = radius + (isMajor ? 1.5 : 2.5);
      final outerR = radius + (isMajor ? 5.5 : 4.0);
      canvas.drawLine(
        Offset(
          center.dx + innerR * cos(angle),
          center.dy + innerR * sin(angle),
        ),
        Offset(
          center.dx + outerR * cos(angle),
          center.dy + outerR * sin(angle),
        ),
        Paint()
          ..color = trackColor.withValues(alpha: isMajor ? 0.7 : 0.35)
          ..strokeWidth = isMajor ? 1.5 : 1.0,
      );
    }

    if (progress > 0) {
      final sweep = sweepTotal * progress.clamp(0.0, 1.0);

      // glow pass
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = accentColor.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // sharp arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5
          ..strokeCap = StrokeCap.round,
      );

      // tip dot
      final tipAngle = startAngle + sweep;
      final tipPt = Offset(
        center.dx + radius * cos(tipAngle),
        center.dy + radius * sin(tipAngle),
      );
      canvas.drawCircle(
        tipPt,
        4.5,
        Paint()
          ..color = accentColor.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(tipPt, 3, Paint()..color = accentColor);
    }
  }

  @override
  bool shouldRepaint(covariant _AcousticDialPainter old) =>
      old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Temporal oscilloscope deck
// ─────────────────────────────────────────────────────────────────────────────

class _TemporalOscilloscopeDeck extends StatefulWidget {
  final UserInsightsSummary summary;
  const _TemporalOscilloscopeDeck({required this.summary});

  @override
  State<_TemporalOscilloscopeDeck> createState() =>
      _TemporalOscilloscopeDeckState();
}

class _TemporalOscilloscopeDeckState extends State<_TemporalOscilloscopeDeck> {
  bool _showHourlyWaveform = false;
  late int _selectedWeekday;
  int? _scrubbedHour;

  static const _shortDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _fullDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _selectedWeekday = (DateTime.now().weekday - 1).clamp(0, 6);
  }

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:00 $period';
  }

  void _scrubWaveform(Offset pos, double width) {
    if (width <= 0) return;
    final idx = ((pos.dx / width) * 23).round().clamp(0, 23);
    if (_scrubbedHour != idx) {
      HapticFeedback.selectionClick();
      setState(() => _scrubbedHour = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekly = widget.summary.weeklyMinutesByWeekday;
    final hourly = widget.summary.hourlyActivityDistribution;
    final peakHour = hourly.isEmpty ? 0 : hourly.indexOf(hourly.reduce(max));
    final activeHour = _scrubbedHour ?? peakHour;

    return _AcrylicPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TEMPORAL RHYTHM',
                      style:
                          AppTypography.labelSm(
                            color: AppColors.secondaryAccent,
                          ).copyWith(
                            fontSize: 9.5,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _showHourlyWaveform
                          ? '24-Hour Signal Curve'
                          : 'Weekly Studio Faders',
                      style: AppTypography.titleSm(
                        color: AppColors.primaryText,
                      ).copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: AppTheme.recessedBayDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ModeChip(
                      label: '7D',
                      active: !_showHourlyWaveform,
                      onTap: () => setState(() => _showHourlyWaveform = false),
                    ),
                    _ModeChip(
                      label: '24H',
                      active: _showHourlyWaveform,
                      onTap: () => setState(() => _showHourlyWaveform = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.03, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                    ),
                child: child,
              ),
            ),
            child: _showHourlyWaveform
                ? _buildHourlyWaveform(hourly, activeHour)
                : _buildWeeklyFaders(weekly),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyFaders(List<double> weekly) {
    final maxVal = weekly.isEmpty ? 1.0 : max(1.0, weekly.reduce(max));
    final total = weekly.fold<double>(0, (a, b) => a + b);
    final selectedMin = weekly[_selectedWeekday].round();
    final share = total > 0
        ? ((weekly[_selectedWeekday] / total) * 100).round()
        : 0;

    return Column(
      key: const ValueKey('weekly_faders'),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: AppTheme.recessedBayDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fullDays[_selectedWeekday].toUpperCase(),
                style: AppTypography.labelSm(color: AppColors.primaryText)
                    .copyWith(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                '$selectedMin MIN  ·  $share% OF WEEK',
                style: AppTypography.labelSm(color: AppColors.secondaryAccent)
                    .copyWith(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 140,
          child: Row(
            children: List.generate(7, (i) {
              final ratio = (weekly[i] / maxVal).clamp(0.0, 1.0);
              final isSelected = _selectedWeekday == i;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedWeekday = i);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(3),
                            decoration: AppTheme.recessedBayDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final trackH = constraints.maxHeight;
                                final fillH = max(10.0, trackH * ratio);
                                return Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    // center guide line
                                    Positioned(
                                      top: 8,
                                      bottom: 8,
                                      child: Container(
                                        width: 1.5,
                                        color: AppColors.ghostBorder,
                                      ),
                                    ),
                                    // fill bar
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      height: fillH,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: isSelected
                                              ? [
                                                  AppColors.secondaryAccent,
                                                  AppColors.secondaryAccent
                                                      .withValues(alpha: 0.4),
                                                ]
                                              : [
                                                  AppColors.secondaryAccent
                                                      .withValues(alpha: 0.5),
                                                  AppColors.secondaryAccent
                                                      .withValues(alpha: 0.1),
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(7),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: AppColors
                                                      .secondaryAccent
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, -2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 3),
                                        width: 16,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primaryText
                                              : AppColors.secondaryAccent
                                                    .withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.4),
                                                    blurRadius: 4,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _shortDays[i],
                          style:
                              AppTypography.labelSm(
                                color: isSelected
                                    ? AppColors.secondaryAccent
                                    : AppColors.outline,
                              ).copyWith(
                                fontSize: 9,
                                letterSpacing: 0.8,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyWaveform(List<double> hourly, int activeHour) {
    final intensity = hourly.isEmpty
        ? 0
        : (hourly[activeHour].clamp(0.0, 1.0) * 100).round();

    return Column(
      key: const ValueKey('hourly_waveform'),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: AppTheme.recessedBayDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _scrubbedHour != null
                    ? 'INSPECTING ${_formatHour(activeHour)}'
                    : widget.summary.peakListeningWindow.isNotEmpty
                    ? widget.summary.peakListeningWindow.toUpperCase()
                    : 'PEAK AT ${_formatHour(activeHour)}',
                style: AppTypography.labelSm(color: AppColors.primaryText)
                    .copyWith(
                      fontSize: 10,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                '$intensity% LOAD',
                style: AppTypography.labelSm(color: AppColors.secondaryAccent)
                    .copyWith(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 140,
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
          decoration: AppTheme.recessedBayDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) =>
                          _scrubWaveform(d.localPosition, constraints.maxWidth),
                      onHorizontalDragUpdate: (d) =>
                          _scrubWaveform(d.localPosition, constraints.maxWidth),
                      onHorizontalDragEnd: (_) =>
                          setState(() => _scrubbedHour = null),
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _OscilloscopePainter(
                          values: hourly,
                          activeIndex: activeHour,
                          accentColor: AppColors.secondaryAccent,
                          gridColor: AppColors.ghostBorder,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['00:00', '06:00', '12:00', '18:00', '23:00']
                    .map(
                      (t) => Text(
                        t,
                        style: AppTypography.labelSm(
                          color: AppColors.outline,
                        ).copyWith(fontSize: 8.5, letterSpacing: 0.6),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: active
              ? Border.all(color: AppColors.ghostBorderActive)
              : null,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.secondaryAccent.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style:
              AppTypography.labelSm(
                color: active
                    ? AppColors.secondaryAccent
                    : AppColors.onSurfaceVariant,
              ).copyWith(
                fontSize: 9.5,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Oscilloscope painter — glowing signal curve
// ─────────────────────────────────────────────────────────────────────────────

class _OscilloscopePainter extends CustomPainter {
  final List<double> values;
  final int activeIndex;
  final Color accentColor;
  final Color gridColor;

  _OscilloscopePainter({
    required this.values,
    required this.activeIndex,
    required this.accentColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    // grid lines
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.6)
      ..strokeWidth = 0.7;
    for (var i = 1; i <= 3; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // build path
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalized = values[i].clamp(0.0, 1.0);
      final y = size.height - (normalized * (size.height - 10)) - 4;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // fill with gradient
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withValues(alpha: 0.36),
            accentColor.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    // glow stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = accentColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // sharp stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // active cursor
    if (activeIndex >= 0 && activeIndex < points.length) {
      final pt = points[activeIndex];

      // cursor line
      canvas.drawLine(
        Offset(pt.dx, 0),
        Offset(pt.dx, size.height),
        Paint()
          ..color = accentColor.withValues(alpha: 0.35)
          ..strokeWidth = 1.2,
      );

      // glow halo
      canvas.drawCircle(
        pt,
        11,
        Paint()
          ..color = accentColor.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // outer ring
      canvas.drawCircle(
        pt,
        6,
        Paint()
          ..color = accentColor.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      // solid dot
      canvas.drawCircle(pt, 3.5, Paint()..color = accentColor);
    }
  }

  @override
  bool shouldRepaint(covariant _OscilloscopePainter old) =>
      old.activeIndex != activeIndex || old.values != values;
}

// ─────────────────────────────────────────────────────────────────────────────
// Artist pressing carousel
// ─────────────────────────────────────────────────────────────────────────────

class _ArtistPressingCarousel extends StatefulWidget {
  final List<ArtistInsight> artists;
  const _ArtistPressingCarousel({required this.artists});

  @override
  State<_ArtistPressingCarousel> createState() =>
      _ArtistPressingCarouselState();
}

class _ArtistPressingCarouselState extends State<_ArtistPressingCarousel> {
  late final PageController _pageController;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.80);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.artists.fold<int>(
      1,
      (s, a) => s + a.totalSeconds,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HEAVY ROTATION',
                      style:
                          AppTypography.labelSm(
                            color: AppColors.secondaryAccent,
                          ).copyWith(
                            fontSize: 9.5,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Top Master Artists',
                      style: AppTypography.titleSm(
                        color: AppColors.primaryText,
                      ).copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: AppTheme.recessedBayDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(_activeIndex + 1).toString().padLeft(2, '0')} / ${widget.artists.length.toString().padLeft(2, '0')}',
                  style: AppTypography.labelSm(color: AppColors.secondaryAccent)
                      .copyWith(
                        fontSize: 9.5,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 182,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.artists.length,
            onPageChanged: (idx) {
              HapticFeedback.selectionClick();
              setState(() => _activeIndex = idx);
            },
            itemBuilder: (context, index) {
              final artist = widget.artists[index];
              final isFocused = index == _activeIndex;
              final minutes = (artist.totalSeconds / 60).round();
              final share = ((artist.totalSeconds / totalSeconds) * 100)
                  .round();

              return AnimatedScale(
                scale: isFocused ? 1.0 : 0.91,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: isFocused ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  child: _VinylSleeveCard(
                    artist: artist,
                    rank: index + 1,
                    minutes: minutes,
                    sharePercent: share,
                    isFocused: isFocused,
                    onTap: () => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VinylSleeveCard extends StatelessWidget {
  final ArtistInsight artist;
  final int rank;
  final int minutes;
  final int sharePercent;
  final bool isFocused;
  final VoidCallback onTap;

  const _VinylSleeveCard({
    required this.artist,
    required this.rank,
    required this.minutes,
    required this.sharePercent,
    required this.isFocused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = artist.artistName.isNotEmpty
        ? artist.artistName[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.frostedGlass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFocused
                ? AppColors.ghostBorderActive
                : AppColors.ghostBorder,
          ),
          boxShadow: isFocused
              ? [
                  const BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 32,
                    offset: Offset(0, 16),
                  ),
                  BoxShadow(
                    color: AppColors.secondaryAccent.withValues(alpha: 0.12),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          children: [
            // vinyl + artwork
            SizedBox(
              width: 124,
              height: 124,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // vinyl disc peeking out
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    left: isFocused ? 38 : 20,
                    child: CustomPaint(
                      size: const Size(90, 90),
                      painter: _VinylDiscGroovePainter(
                        accentColor: AppColors.secondaryAccent,
                      ),
                    ),
                  ),
                  // artwork sleeve
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: AppColors.subSurface,
                      border: Border.all(
                        color: isFocused
                            ? AppColors.ghostBorderActive
                            : AppColors.ghostBorder,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 16,
                          offset: Offset(4, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          SafeImage(
                            urlOrPath: artist.sampleCoverUrl,
                            fit: BoxFit.cover,
                            fallback: Container(
                              color: AppColors.surfaceContainer,
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: AppTypography.headlineMd(
                                  color: AppColors.secondaryAccent,
                                ),
                              ),
                            ),
                          ),
                          // subtle vignette
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.3),
                                ],
                                radius: 0.9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // rank badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutralCanvas.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: AppColors.secondaryAccent.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Text(
                        '#$rank',
                        style:
                            AppTypography.labelSm(
                              color: AppColors.secondaryAccent,
                            ).copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'MASTER PRESSING',
                    style:
                        AppTypography.labelSm(
                          color: AppColors.secondaryAccent,
                        ).copyWith(
                          fontSize: 8.5,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    artist.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTypography.headlineMd(
                          color: AppColors.primaryText,
                        ).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: AppTheme.recessedBayDecoration(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PressingStat(label: 'TIME', value: '${minutes}m'),
                        Container(
                          width: 1,
                          height: 16,
                          color: AppColors.ghostBorder,
                        ),
                        _PressingStat(
                          label: 'PLAYS',
                          value: '${artist.playCount}',
                        ),
                        Container(
                          width: 1,
                          height: 16,
                          color: AppColors.ghostBorder,
                        ),
                        _PressingStat(label: 'SHARE', value: '$sharePercent%'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PressingStat extends StatelessWidget {
  final String label;
  final String value;
  const _PressingStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSm(
            color: AppColors.outline,
          ).copyWith(fontSize: 7.5, letterSpacing: 0.8),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.labelSm(
            color: AppColors.primaryText,
          ).copyWith(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vinyl disc painter — premium grooves with sheen
// ─────────────────────────────────────────────────────────────────────────────

class _VinylDiscGroovePainter extends CustomPainter {
  final Color accentColor;
  _VinylDiscGroovePainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // disc body
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF0E0E0D));

    // grooves
    final groovePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;
    for (var r = radius * 0.40; r < radius * 0.90; r += 3.2) {
      final t = ((r - radius * 0.40) / (radius * 0.50)).clamp(0.0, 1.0);
      groovePaint.color = Colors.white.withValues(alpha: 0.04 + t * 0.04);
      canvas.drawCircle(center, r, groovePaint);
    }

    // outer rim
    canvas.drawCircle(
      center,
      radius - 1.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // label area
    canvas.drawCircle(
      center,
      radius * 0.30,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accentColor.withValues(alpha: 0.9),
            accentColor.withValues(alpha: 0.6),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.30)),
    );

    // label inner ring
    canvas.drawCircle(
      center,
      radius * 0.08,
      Paint()..color = const Color(0xFF0E0E0D),
    );

    // highlight sheen
    final highlightPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(
      highlightPath,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.6, -0.8),
          end: const Alignment(0.6, 0.8),
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.transparent,
            Colors.white.withValues(alpha: 0.03),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sonic harmonic rose
// ─────────────────────────────────────────────────────────────────────────────

class _SonicHarmonicRose extends StatefulWidget {
  final UserInsightsSummary summary;
  const _SonicHarmonicRose({required this.summary});

  @override
  State<_SonicHarmonicRose> createState() => _SonicHarmonicRoseState();
}

class _SonicHarmonicRoseState extends State<_SonicHarmonicRose> {
  int _activeDomain = 0;
  int _focusedRing = 0;

  @override
  Widget build(BuildContext context) {
    final domains = <(String, List<CategoryShare>)>[
      if (widget.summary.topMoods.isNotEmpty)
        ('MOODS', widget.summary.topMoods),
      if (widget.summary.topGenres.isNotEmpty)
        ('GENRES', widget.summary.topGenres),
      if (widget.summary.topLanguages.isNotEmpty)
        ('LANGUAGES', widget.summary.topLanguages),
    ];

    if (domains.isEmpty) return const SizedBox.shrink();

    final int safeDomain = _activeDomain.clamp(0, domains.length - 1);
    final items = domains[safeDomain].$2.take(4).toList();
    final int safeRing = items.isEmpty
        ? 0
        : _focusedRing.clamp(0, items.length - 1);

    final chipsWidget = Container(
      padding: const EdgeInsets.all(3),
      decoration: AppTheme.recessedBayDecoration(
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(domains.length, (i) {
          return _ModeChip(
            label: domains[i].$1,
            active: i == safeDomain,
            onTap: () => setState(() {
              _activeDomain = i;
              _focusedRing = 0;
            }),
          );
        }),
      ),
    );

    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HARMONIC SPECTRUM',
          style:
              AppTypography.labelSm(
                color: AppColors.secondaryAccent,
              ).copyWith(
                fontSize: 9.5,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          'Sonic DNA Soundstage',
          style: AppTypography.titleSm(
            color: AppColors.primaryText,
          ).copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );

    return _AcrylicPanel(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isStacked =
              constraints.maxWidth < (domains.length > 1 ? 420 : 280);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isStacked) ...[
                titleWidget,
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: chipsWidget,
                ),
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: titleWidget),
                    const SizedBox(width: 12),
                    chipsWidget,
                  ],
                ),
              const SizedBox(height: 18),
          Row(
            children: [
              // concentric rings
              GestureDetector(
                onTap: () {
                  if (items.isNotEmpty) {
                    HapticFeedback.selectionClick();
                    setState(
                      () => _focusedRing = (_focusedRing + 1) % items.length,
                    );
                  }
                },
                child: Container(
                  width: 148,
                  height: 148,
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.recessedBayDecoration(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('$safeDomain-$safeRing'),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, animVal, _) {
                      return CustomPaint(
                        painter: _HarmonicRingsPainter(
                          shares: items,
                          focusedIndex: safeRing,
                          animProgress: animVal,
                          accentColor: AppColors.secondaryAccent,
                          trackColor: AppColors.ghostBorder,
                        ),
                        child: Center(
                          child: items.isEmpty
                              ? const SizedBox.shrink()
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${items[safeRing].percentage.toStringAsFixed(0)}%',
                                      style:
                                          AppTypography.titleSm(
                                            color: AppColors.primaryText,
                                          ).copyWith(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      'CH 0${safeRing + 1}',
                                      style:
                                          AppTypography.labelSm(
                                            color: AppColors.secondaryAccent,
                                          ).copyWith(
                                            fontSize: 8,
                                            letterSpacing: 1.1,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // legend
              Expanded(
                child: Column(
                  children: List.generate(items.length, (i) {
                    final item = items[i];
                    final isFocused = i == safeRing;
                    final opacityFactor = (1.0 - (i * 0.2)).clamp(0.35, 1.0);

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i == items.length - 1 ? 0 : 8,
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _focusedRing = i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isFocused
                                ? AppColors.surfaceContainer
                                : AppColors.subSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isFocused
                                  ? AppColors.ghostBorderActive
                                  : AppColors.ghostBorder,
                            ),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: AppColors.secondaryAccent
                                          .withValues(alpha: 0.15),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.secondaryAccent.withValues(
                                    alpha: opacityFactor,
                                  ),
                                  boxShadow: isFocused
                                      ? [
                                          BoxShadow(
                                            color: AppColors.secondaryAccent
                                                .withValues(alpha: 0.7),
                                            blurRadius: 6,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      AppTypography.bodySm(
                                        color: isFocused
                                            ? AppColors.primaryText
                                            : AppColors.onSurfaceVariant,
                                      ).copyWith(
                                        fontSize: 12,
                                        fontWeight: isFocused
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${item.percentage.toStringAsFixed(0)}%',
                                style:
                                    AppTypography.labelSm(
                                      color: isFocused
                                          ? AppColors.secondaryAccent
                                          : AppColors.outline,
                                    ).copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      );
    },
  ),
);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Harmonic rings painter — concentric arcs with glow
// ─────────────────────────────────────────────────────────────────────────────

class _HarmonicRingsPainter extends CustomPainter {
  final List<CategoryShare> shares;
  final int focusedIndex;
  final double animProgress;
  final Color accentColor;
  final Color trackColor;

  _HarmonicRingsPainter({
    required this.shares,
    required this.focusedIndex,
    required this.animProgress,
    required this.accentColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (min(size.width, size.height) / 2) - 2;
    const ringSpacing = 10.0;
    const startAngle = -pi / 2;

    for (var i = 0; i < shares.length; i++) {
      final radius = maxRadius - (i * ringSpacing);
      if (radius <= 14) break;

      final isFocused = i == focusedIndex;

      // track
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor.withValues(alpha: isFocused ? 0.5 : 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isFocused ? 6.0 : 4.5,
      );

      final pct = (shares[i].percentage / 100.0).clamp(0.06, 1.0);
      final sweep = 2 * pi * pct * animProgress;
      final alpha = isFocused ? 1.0 : (0.7 - (i * 0.12)).clamp(0.28, 0.8);

      if (isFocused) {
        // glow pass
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweep,
          false,
          Paint()
            ..color = accentColor.withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 13
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      // arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = accentColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isFocused ? 6.0 : 4.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HarmonicRingsPainter old) =>
      old.focusedIndex != focusedIndex ||
      old.animProgress != animProgress ||
      old.shares != shares;
}

// ─────────────────────────────────────────────────────────────────────────────
// Archive crate flip deck
// ─────────────────────────────────────────────────────────────────────────────

class _ArchiveCrateFlipDeck extends StatefulWidget {
  final List<Song> songs;
  const _ArchiveCrateFlipDeck({required this.songs});

  @override
  State<_ArchiveCrateFlipDeck> createState() => _ArchiveCrateFlipDeckState();
}

class _ArchiveCrateFlipDeckState extends State<_ArchiveCrateFlipDeck> {
  int _frontIndex = 0;

  void _cycleNext() {
    if (widget.songs.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _frontIndex = (_frontIndex + 1) % widget.songs.length);
  }

  void _cyclePrev() {
    if (widget.songs.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(
      () => _frontIndex =
          (_frontIndex - 1 + widget.songs.length) % widget.songs.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.songs.length;
    final visibleLayers = min(3, total);

    return _AcrylicPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VINYL ARCHIVE CRATE',
                      style:
                          AppTypography.labelSm(
                            color: AppColors.secondaryAccent,
                          ).copyWith(
                            fontSize: 9.5,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Forgotten Gems',
                      style: AppTypography.titleSm(
                        color: AppColors.primaryText,
                      ).copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: AppTheme.recessedBayDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_frontIndex + 1} / $total',
                  style: AppTypography.labelSm(color: AppColors.secondaryAccent)
                      .copyWith(
                        fontSize: 9.5,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v < -150) {
                _cycleNext();
              } else if (v > 150) {
                _cyclePrev();
              }
            },
            child: SizedBox(
              height: 158,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: List.generate(visibleLayers, (layerIdx) {
                  final depth = (visibleLayers - 1) - layerIdx;
                  final songIdx = (_frontIndex + depth) % total;
                  final song = widget.songs[songIdx];
                  final scale = 1.0 - (depth * 0.05);
                  final translateY = -depth * 14.0;
                  final opacity = (1.0 - (depth * 0.3)).clamp(0.15, 1.0);

                  return AnimatedPositioned(
                    key: ValueKey('sleeve_$songIdx'),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    top: 16 + translateY,
                    left: depth * 6.0,
                    right: depth * 6.0,
                    bottom: -translateY,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.topCenter,
                      child: Opacity(
                        opacity: opacity,
                        child: _CrateSleeveFront(
                          song: song,
                          isFront: depth == 0,
                          onPlay: () {
                            context.read<PlayerBloc>().add(
                              PlayerPlayTrack(song.toTrack()),
                            );
                            PlayerScreen.open(context);
                          },
                          onFlipNext: _cycleNext,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrateSleeveFront extends StatelessWidget {
  final Song song;
  final bool isFront;
  final VoidCallback onPlay;
  final VoidCallback onFlipNext;

  const _CrateSleeveFront({
    required this.song,
    required this.isFront,
    required this.onPlay,
    required this.onFlipNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.subSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFront ? AppColors.ghostBorderActive : AppColors.ghostBorder,
        ),
        boxShadow: isFront
            ? [
                const BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 108,
              height: 108,
              color: AppColors.surfaceContainer,
              child: TrackArtwork(
                albumArt: song.coverUrl,
                trackId: song.id,
                fit: BoxFit.cover,
                fallback: const Icon(
                  Icons.album_rounded,
                  color: AppColors.outline,
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ARCHIVED FAVORITE',
                      style:
                          AppTypography.labelSm(
                            color: AppColors.secondaryAccent,
                          ).copyWith(
                            fontSize: 8.5,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      song.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSm(color: AppColors.primaryText)
                          .copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant,
                      ).copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
                if (isFront)
                  Row(
                    children: [
                      Expanded(
                        child: _TactileTap(
                          onTap: onPlay,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryAccent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondaryAccent.withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 15,
                                  color: AppColors.onSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'SPIN',
                                  style:
                                      AppTypography.labelSm(
                                        color: AppColors.onSecondary,
                                      ).copyWith(
                                        fontSize: 9.5,
                                        letterSpacing: 1.1,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TactileTap(
                        onTap: onFlipNext,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: AppColors.ghostBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.flip_to_front_rounded,
                                size: 13,
                                color: AppColors.primaryText,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'NEXT',
                                style:
                                    AppTypography.labelSm(
                                      color: AppColors.primaryText,
                                    ).copyWith(
                                      fontSize: 9.5,
                                      letterSpacing: 1.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
