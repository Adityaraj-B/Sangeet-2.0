import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../main_layout/bloc/main_layout_bloc.dart';
import '../../theme/theme.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64 + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 20,
            right: 20,
          ),
          color: AppColors.neutralCanvas.withValues(alpha: 0.8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Brand (tappable to return to listen tab)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<NavigationBloc>().add(
                    const NavigationTabChanged(NavTab.listen),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SANGEET',
                      style: AppTypography.labelMd(color: AppColors.primaryText)
                          .copyWith(
                            letterSpacing: 0.28 * 12,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 12,
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: AppRadii.radiusSm,
                      ),
                      child: Text(
                        'Hi-Res',
                        style: AppTypography.labelSm(
                          color: AppColors.onSurfaceVariant,
                        ).copyWith(letterSpacing: 0.14 * 10, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Actions
              BlocSelector<NavigationBloc, NavigationState, NavTab>(
                selector: (s) => s.activeTab,
                builder: (context, activeTab) {
                  final isBrowse = activeTab == NavTab.browse;
                  return _iconBtn(
                    Icons.search_rounded,
                    'Search Archival Database',
                    color: isBrowse
                        ? AppColors.secondaryAccent
                        : AppColors.onSurfaceVariant,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.read<NavigationBloc>().add(
                        const NavigationTabChanged(NavTab.browse),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 4),
              BlocSelector<NavigationBloc, NavigationState, NavTab>(
                selector: (s) => s.activeTab,
                builder: (context, activeTab) {
                  final isProfile = activeTab == NavTab.profile;
                  return Tooltip(
                    message: 'Studio Profile & Settings',
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.read<NavigationBloc>().add(
                          const NavigationTabChanged(NavTab.profile),
                        );
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isProfile
                                ? AppColors.secondaryAccent
                                : AppColors.primaryText,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isProfile
                                  ? AppColors.secondaryAccent
                                  : AppColors.secondaryAccent.withValues(
                                      alpha: 0.5,
                                    ),
                              width: isProfile ? 2.0 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondaryAccent.withValues(
                                  alpha: isProfile ? 0.45 : 0.2,
                                ),
                                blurRadius: isProfile ? 10 : 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: isProfile
                                ? AppColors.onSecondary
                                : AppColors.neutralCanvas,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(
    IconData icon,
    String tooltip, {
    VoidCallback? onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 20,
              color: color ?? AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// Aliases for unified app bar usage
typedef MainLayoutAppBar = HomeAppBar;
typedef AuraAppBar = HomeAppBar;
