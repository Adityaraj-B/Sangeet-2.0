import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Device screen classification based on DESIGN.md breakpoints.
/// - Desktop: width >= 1024px (12 columns)
/// - Tablet: 768px <= width < 1024px (8 columns)
/// - Mobile: width < 768px (4 columns)
enum DeviceType { mobile, tablet, desktop }

/// Screen information derived from MediaQuery.
class ScreenInfo {
  final double width;
  final double height;
  final Orientation orientation;
  final EdgeInsets padding;
  final DeviceType deviceType;

  const ScreenInfo({
    required this.width,
    required this.height,
    required this.orientation,
    required this.padding,
    required this.deviceType,
  });

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  int get columns {
    switch (deviceType) {
      case DeviceType.desktop:
        return 12;
      case DeviceType.tablet:
        return 8;
      case DeviceType.mobile:
        return 4;
    }
  }

  double get canvasMargin {
    switch (deviceType) {
      case DeviceType.desktop:
        return AppSpacing.marginDesktop;
      case DeviceType.tablet:
        return AppSpacing.marginTablet;
      case DeviceType.mobile:
        return AppSpacing.marginMobile;
    }
  }

  double get gutter {
    switch (deviceType) {
      case DeviceType.desktop:
        return AppSpacing.gutterDesktop;
      case DeviceType.tablet:
        return AppSpacing.gutterTablet;
      case DeviceType.mobile:
        return AppSpacing.gutterMobile;
    }
  }
}

/// Convenience BuildContext extensions for MediaQuery-based responsive design.
extension ResponsiveContextExtension on BuildContext {
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  Orientation get orientation => mediaQuery.orientation;
  EdgeInsets get screenPadding => mediaQuery.padding;

  DeviceType get deviceType {
    final w = screenWidth;
    if (w >= 1024) return DeviceType.desktop;
    if (w >= 768) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  int get columns {
    switch (deviceType) {
      case DeviceType.desktop:
        return 12;
      case DeviceType.tablet:
        return 8;
      case DeviceType.mobile:
        return 4;
    }
  }

  double get canvasMargin {
    switch (deviceType) {
      case DeviceType.desktop:
        return AppSpacing.marginDesktop;
      case DeviceType.tablet:
        return AppSpacing.marginTablet;
      case DeviceType.mobile:
        return AppSpacing.marginMobile;
    }
  }

  double get gutter {
    switch (deviceType) {
      case DeviceType.desktop:
        return AppSpacing.gutterDesktop;
      case DeviceType.tablet:
        return AppSpacing.gutterTablet;
      case DeviceType.mobile:
        return AppSpacing.gutterMobile;
    }
  }

  /// Select a value dynamically based on the current device category.
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  ScreenInfo get screenInfo => ScreenInfo(
        width: screenWidth,
        height: screenHeight,
        orientation: orientation,
        padding: screenPadding,
        deviceType: deviceType,
      );
}

/// Widget that switches layout based on MediaQuery breakpoints.
class ResponsiveLayout extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop && desktop != null) {
      return desktop!(context);
    }
    if (context.isTablet && tablet != null) {
      return tablet!(context);
    }
    if (context.isDesktop && tablet != null) {
      return tablet!(context);
    }
    return mobile(context);
  }
}

/// A responsive container that enforces max-width (1440px)
/// and applies device-specific outer margins using MediaQuery.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final bool applyHorizontalPadding;
  final bool applyVerticalPadding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.applyHorizontalPadding = true,
    this.applyVerticalPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final margin = context.canvasMargin;
    final padding = EdgeInsets.symmetric(
      horizontal: applyHorizontalPadding ? margin : 0,
      vertical: applyVerticalPadding ? AppSpacing.md : 0,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSpacing.maxViewportWidth,
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
