import 'package:flutter/material.dart';

/// Atmospheric Geometric Acoustic Seal / Monogram
/// Features concentric precision rings with a slow, breathing pulse
/// and an artisan champagne gold core.
class AcousticMonogram extends StatefulWidget {
  final double size;

  const AcousticMonogram({super.key, this.size = 64.0});

  @override
  State<AcousticMonogram> createState() => _AcousticMonogramState();
}

class _AcousticMonogramState extends State<AcousticMonogram>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsating hairline ring
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5C378).withValues(alpha: 0.22),
                      width: 1.0,
                    ),
                  ),
                ),
              );
            },
          ),

          // Middle subtle hairline ring
          Container(
            width: s * 0.84,
            height: s * 0.84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
          ),

          // Inner gold ring
          Container(
            width: s * 0.68,
            height: s * 0.68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE5C378).withValues(alpha: 0.42),
                width: 1.0,
              ),
            ),
          ),

          // Core radiant seal with graphic_eq
          Container(
            width: s * 0.40,
            height: s * 0.40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE09D),
                  Color(0xFFE5C378),
                  Color(0xFF9E7D32),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE5C378).withValues(alpha: 0.38),
                  blurRadius: 18,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.graphic_eq_rounded,
                size: 13,
                color: Color(0xFF1B1C19),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
