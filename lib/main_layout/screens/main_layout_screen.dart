import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/main_layout_bloc.dart';
import '../../home/screens/home_screen.dart';
import '../../home/widgets/home_app_bar.dart';
import '../../library/screens/library_screen.dart';
import '../widgets/fade_indexed_stack.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/aura_bottom_nav.dart';
import '../widgets/offline_status_banner.dart';
import '../../profile/screens/profile_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../theme/theme.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    LibraryScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  static const List<Alignment> _ambientAlignments = [
    Alignment(-0.75, -0.85),
    Alignment(0.75, -0.75),
    Alignment(-0.65, -0.45),
    Alignment(0.80, -0.85),
  ];

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  bool _isChromeMinimized = false;

  bool _onScrollNotification(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification.direction == ScrollDirection.reverse &&
        notification.metrics.pixels > 72 &&
        !_isChromeMinimized) {
      setState(() => _isChromeMinimized = true);
    } else if ((notification.direction == ScrollDirection.forward ||
            notification.metrics.pixels <= 24) &&
        _isChromeMinimized) {
      setState(() => _isChromeMinimized = false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPad = mediaQuery.padding.bottom;
    final topPad = mediaQuery.padding.top;
    final bottomNavHeight = 64.0 + bottomPad;

    return BlocConsumer<NavigationBloc, NavigationState>(
      listenWhen: (prev, curr) => prev.activeTab != curr.activeTab,
      listener: (context, navState) {
        HapticFeedback.selectionClick();
        if (_isChromeMinimized) {
          setState(() => _isChromeMinimized = false);
        }
      },
      buildWhen: (prev, curr) => prev.activeTab != curr.activeTab,
      builder: (context, navState) {
        final tabIndex = navState.activeTab.index;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          ),
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (navState.activeTab != NavTab.listen) {
                HapticFeedback.lightImpact();
                context.read<NavigationBloc>().add(
                  const NavigationTabChanged(NavTab.listen),
                );
              } else {
                SystemNavigator.pop();
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.neutralCanvas,
              resizeToAvoidBottomInset: false,
              extendBody: true,
              extendBodyBehindAppBar: true,
              appBar: const HomeAppBar(),
              body: NotificationListener<UserScrollNotification>(
                onNotification: _onScrollNotification,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    IgnorePointer(
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 750),
                        curve: Curves.easeOutExpo,
                        alignment:
                            MainLayoutScreen._ambientAlignments[tabIndex],
                        child: Container(
                          width: 380,
                          height: 380,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.secondaryAccent.withValues(
                                  alpha: 0.08,
                                ),
                                AppColors.secondaryAccent.withValues(
                                  alpha: 0.02,
                                ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: FadeIndexedStack(
                        index: tabIndex,
                        children: MainLayoutScreen._screens,
                      ),
                    ),
                    Positioned(
                      top: 64.0 + topPad + 6,
                      left: 0,
                      right: 0,
                      child: const OfflineStatusBanner(),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      right: 0,
                      bottom: _isChromeMinimized
                          ? (bottomPad + 12)
                          : (bottomNavHeight + 6),
                      child: const RepaintBoundary(child: MiniPlayerBar()),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: AnimatedSlide(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                offset: _isChromeMinimized
                    ? const Offset(0, 1.15)
                    : Offset.zero,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  opacity: _isChromeMinimized ? 0.0 : 1.0,
                  child: const RepaintBoundary(child: AuraBottomNav()),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

typedef AppShell = MainLayoutScreen;
