import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/main_layout_bloc.dart';
import '../../theme/theme.dart';

class AuraBottomNav extends StatelessWidget {
  const AuraBottomNav({super.key});

  static const List<_NavDestination> _destinations = [
    _NavDestination(
      tab: NavTab.listen,
      icon: Icons.graphic_eq_rounded,
      label: 'Listen',
    ),
    _NavDestination(
      tab: NavTab.library,
      icon: Icons.folder_open_rounded,
      label: 'Library',
    ),
    _NavDestination(
      tab: NavTab.browse,
      icon: Icons.search_rounded,
      label: 'Search',
    ),
    _NavDestination(
      tab: NavTab.profile,
      icon: Icons.person_outline_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64 + bottomPad,
          padding: EdgeInsets.only(bottom: bottomPad, left: 16, right: 16),
          decoration: BoxDecoration(
            color: AppColors.neutralCanvas.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: AppColors.ghostBorderSubtle.withValues(alpha: 0.14),
                width: 1,
              ),
            ),
          ),
          child: BlocSelector<NavigationBloc, NavigationState, NavTab>(
            selector: (state) => state.activeTab,
            builder: (context, activeTab) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _destinations.map((dest) {
                  final isActive = activeTab == dest.tab;
                  return _NavItem(
                    destination: dest,
                    isActive: isActive,
                    onTap: () {
                      if (!isActive) {
                        HapticFeedback.selectionClick();
                        context.read<NavigationBloc>().add(
                          NavigationTabChanged(dest.tab),
                        );
                      }
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  final NavTab tab;
  final IconData icon;
  final String label;

  const _NavDestination({
    required this.tab,
    required this.icon,
    required this.label,
  });
}

class _NavItem extends StatefulWidget {
  final _NavDestination destination;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
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
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: 76,
          height: 52,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: widget.isActive ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, rawT, _) {
              final t = rawT.clamp(0.0, 1.0);
              final itemColor = Color.lerp(
                AppColors.onSurfaceVariant,
                AppColors.primaryText,
                t,
              )!;

              return Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 4,
                    child: Opacity(
                      opacity: (t * 0.14).clamp(0.0, 1.0),
                      child: Container(
                        width: 36,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryAccent,
                          borderRadius: AppRadii.radiusFull,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondaryAccent.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, -1.5 * t),
                        child: Transform.scale(
                          scale: 1.0 + (0.08 * t),
                          child: Icon(
                            widget.destination.icon,
                            size: 22,
                            color: itemColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        style: AppTypography.labelSm(color: itemColor).copyWith(
                          fontSize: 10,
                          letterSpacing: 1.5 + (0.2 * t),
                          fontWeight: widget.isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        child: Text(widget.destination.label.toUpperCase()),
                      ),
                    ],
                  ),
                  if (t > 0.0)
                    Positioned(
                      bottom: 2,
                      child: Opacity(
                        opacity: t,
                        child: Container(
                          width: 12 * t,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryAccent,
                            borderRadius: AppRadii.radiusFull,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondaryAccent.withValues(
                                  alpha: 0.65 * t,
                                ),
                                blurRadius: 6,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
