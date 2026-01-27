import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
    this.iconBackgroundColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? AppTheme.primaryColor;
    final effectiveIconBg = iconBackgroundColor ??
        effectiveIconColor.withOpacity(isDark ? 0.2 : 0.1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: effectiveIconBg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: effectiveIconColor,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  final List<StatItem> stats;
  final bool dividers;
  final EdgeInsetsGeometry? padding;

  const StatRow({
    super.key,
    required this.stats,
    this.dividers = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          final isLast = index == stats.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        stat.value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stat.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (dividers && !isLast)
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark
                        ? AppTheme.borderDark
                        : AppTheme.borderLight,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class StatItem {
  final String value;
  final String label;
  final IconData? icon;
  final Color? color;

  const StatItem({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });
}

class MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? label;
  final Color? color;

  const MiniStat({
    super.key,
    required this.icon,
    required this.value,
    this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ??
        (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: effectiveColor,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.textPrimaryDark
                : AppTheme.textPrimaryLight,
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              color: effectiveColor,
            ),
          ),
        ],
      ],
    );
  }
}
