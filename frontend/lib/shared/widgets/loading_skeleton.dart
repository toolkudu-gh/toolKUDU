import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class LoadingSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const LoadingSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
  });

  factory LoadingSkeleton.text({
    double? width,
    double height = 16,
    EdgeInsetsGeometry? margin,
  }) {
    return LoadingSkeleton(
      width: width,
      height: height,
      borderRadius: 4,
      margin: margin,
    );
  }

  factory LoadingSkeleton.circle({
    required double size,
    EdgeInsetsGeometry? margin,
  }) {
    return LoadingSkeleton(
      width: size,
      height: size,
      borderRadius: size / 2,
      margin: margin,
    );
  }

  factory LoadingSkeleton.avatar({
    double size = 48,
    EdgeInsetsGeometry? margin,
  }) {
    return LoadingSkeleton(
      width: size,
      height: size,
      borderRadius: size / 2,
      margin: margin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? AppTheme.borderDark
          : const Color(0xFFE7E5E4),
      highlightColor: isDark
          ? AppTheme.surfaceDark
          : const Color(0xFFF5F5F4),
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class CardSkeleton extends StatelessWidget {
  final double? height;
  final bool showImage;
  final EdgeInsetsGeometry? margin;

  const CardSkeleton({
    super.key,
    this.height,
    this.showImage = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showImage) ...[
            LoadingSkeleton(
              width: double.infinity,
              height: height ?? 120,
              borderRadius: AppTheme.radiusMd,
            ),
            const SizedBox(height: 12),
          ],
          LoadingSkeleton.text(width: 150),
          const SizedBox(height: 8),
          LoadingSkeleton.text(width: 100, height: 14),
        ],
      ),
    );
  }
}

class ListTileSkeleton extends StatelessWidget {
  final bool showAvatar;
  final bool showTrailing;
  final EdgeInsetsGeometry? margin;

  const ListTileSkeleton({
    super.key,
    this.showAvatar = true,
    this.showTrailing = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (showAvatar) ...[
            LoadingSkeleton.avatar(size: 48),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton.text(width: 160),
                const SizedBox(height: 6),
                LoadingSkeleton.text(width: 100, height: 14),
              ],
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: 12),
            LoadingSkeleton(
              width: 60,
              height: 28,
              borderRadius: AppTheme.radius2xl,
            ),
          ],
        ],
      ),
    );
  }
}

class GridSkeleton extends StatelessWidget {
  final int columns;
  final int itemCount;
  final double childAspectRatio;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const GridSkeleton({
    super.key,
    this.columns = 2,
    this.itemCount = 4,
    this.childAspectRatio = 1.0,
    this.spacing = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const CardSkeleton(),
    );
  }
}

class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton.circle(size: 40),
          const SizedBox(height: 12),
          LoadingSkeleton.text(width: 60, height: 24),
          const SizedBox(height: 6),
          LoadingSkeleton.text(width: 80, height: 14),
        ],
      ),
    );
  }
}
