import 'package:flutter/material.dart';

/// Responsive breakpoints and utilities
class Responsive {
  Responsive._();

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double wideBreakpoint = 1440;

  /// Check if current screen is mobile (<600px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < mobileBreakpoint;
  }

  /// Check if current screen is tablet (600-899px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if current screen is desktop (>=900px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= tabletBreakpoint;
  }

  /// Check if current screen is wide desktop (>=1200px)
  static bool isWideDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }

  /// Check if current screen is extra wide (>=1440px)
  static bool isExtraWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= wideBreakpoint;
  }

  /// Get the current screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return ScreenSize.mobile;
    if (width < tabletBreakpoint) return ScreenSize.tablet;
    if (width < desktopBreakpoint) return ScreenSize.desktop;
    return ScreenSize.wide;
  }

  /// Get responsive value based on screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? wide,
  }) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.wide:
        return wide ?? desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive padding based on screen size
  static EdgeInsets padding(BuildContext context) {
    return value<EdgeInsets>(
      context,
      mobile: const EdgeInsets.symmetric(horizontal: 16),
      tablet: const EdgeInsets.symmetric(horizontal: 24),
      desktop: const EdgeInsets.symmetric(horizontal: 32),
      wide: const EdgeInsets.symmetric(horizontal: 48),
    );
  }

  /// Get responsive content max width
  static double maxContentWidth(BuildContext context) {
    return value<double>(
      context,
      mobile: double.infinity,
      tablet: 720,
      desktop: 960,
      wide: 1200,
    );
  }

  /// Get number of grid columns based on screen size
  static int gridColumns(BuildContext context, {int baseColumns = 2}) {
    return value<int>(
      context,
      mobile: baseColumns,
      tablet: baseColumns + 1,
      desktop: baseColumns + 2,
      wide: baseColumns + 3,
    );
  }
}

/// Screen size categories
enum ScreenSize {
  mobile,
  tablet,
  desktop,
  wide,
}

/// Widget that builds different layouts based on screen size
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize screenSize) builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? wide;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
    this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
  });

  /// Convenience constructor for specific layouts
  const ResponsiveBuilder.specific({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
  }) : builder = _defaultBuilder;

  static Widget _defaultBuilder(BuildContext context, ScreenSize screenSize) {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = Responsive.getScreenSize(context);

    // If specific layouts provided, use them
    if (mobile != null || tablet != null || desktop != null || wide != null) {
      switch (screenSize) {
        case ScreenSize.mobile:
          return mobile ?? tablet ?? desktop ?? wide ?? const SizedBox.shrink();
        case ScreenSize.tablet:
          return tablet ?? desktop ?? mobile ?? wide ?? const SizedBox.shrink();
        case ScreenSize.desktop:
          return desktop ?? tablet ?? mobile ?? wide ?? const SizedBox.shrink();
        case ScreenSize.wide:
          return wide ?? desktop ?? tablet ?? mobile ?? const SizedBox.shrink();
      }
    }

    return builder(context, screenSize);
  }
}

/// Wrapper that constrains content to max width and centers it
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final bool centerContent;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? Responsive.maxContentWidth(context);
    final effectivePadding = padding ?? Responsive.padding(context);

    Widget content = child;

    if (effectiveMaxWidth != double.infinity) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: content,
      );
    }

    if (centerContent && effectiveMaxWidth != double.infinity) {
      content = Center(child: content);
    }

    return Padding(
      padding: effectivePadding,
      child: content,
    );
  }
}
