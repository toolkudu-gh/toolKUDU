import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool enableHover;
  final double? borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final bool enableGlass;
  final double glassBlur;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.enableHover = true,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.enableGlass = false,
    this.glassBlur = 10.0,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = widget.borderRadius ?? AppTheme.radiusLg;

    Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      margin: widget.margin,
      padding: widget.padding ?? const EdgeInsets.all(16),
      transform: _isHovered && widget.onTap != null
          ? (Matrix4.identity()..scale(1.02))
          : Matrix4.identity(),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.enableGlass
            ? (isDark ? AppTheme.glassDark : AppTheme.glassLight)
            : (widget.backgroundColor ??
                (isDark ? AppTheme.surfaceElevatedDark : AppTheme.surfaceLight)),
        borderRadius: BorderRadius.circular(radius),
        border: widget.border ??
            Border.all(
              color: widget.enableGlass
                  ? (isDark ? AppTheme.glassBorderDark : AppTheme.glassBorderLight)
                  : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
            ),
        boxShadow: _isHovered && widget.onTap != null
            ? AppTheme.shadowLg
            : AppTheme.shadowSm,
      ),
      child: widget.child,
    );

    // Wrap with blur effect if glassmorphism is enabled
    if (widget.enableGlass) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.glassBlur,
            sigmaY: widget.glassBlur,
          ),
          child: cardContent,
        ),
      );
    }

    return MouseRegion(
      onEnter: widget.enableHover ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.enableHover ? (_) => setState(() => _isHovered = false) : null,
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: cardContent,
      ),
    );
  }
}

/// A glassmorphic card with blur effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? borderRadius;
  final double blurAmount;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.blurAmount = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      margin: margin,
      onTap: onTap,
      borderRadius: borderRadius,
      enableGlass: true,
      glassBlur: blurAmount,
      child: child,
    );
  }
}

class AppCardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  const AppCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
