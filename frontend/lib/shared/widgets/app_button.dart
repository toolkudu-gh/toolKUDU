import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, outline, ghost, destructive }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool iconRight;
  final bool isLoading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.iconRight = false,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;

  EdgeInsets get _padding {
    switch (widget.size) {
      case AppButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case AppButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case AppButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 13;
      case AppButtonSize.md:
        return 14;
      case AppButtonSize.lg:
        return 16;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 16;
      case AppButtonSize.md:
        return 18;
      case AppButtonSize.lg:
        return 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Color backgroundColor;
    Color foregroundColor;
    Border? border;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        backgroundColor = _isHovered && !isDisabled
            ? AppTheme.primaryHover
            : AppTheme.primaryColor;
        foregroundColor = Colors.white;
        border = null;
        break;
      case AppButtonVariant.outline:
        backgroundColor = _isHovered && !isDisabled
            ? (isDark
                ? AppTheme.primaryColor.withOpacity(0.1)
                : AppTheme.primaryColor.withOpacity(0.05))
            : Colors.transparent;
        foregroundColor = isDark
            ? AppTheme.textPrimaryDark
            : AppTheme.textPrimaryLight;
        border = Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        );
        break;
      case AppButtonVariant.ghost:
        backgroundColor = _isHovered && !isDisabled
            ? (isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05))
            : Colors.transparent;
        foregroundColor = isDark
            ? AppTheme.textPrimaryDark
            : AppTheme.textPrimaryLight;
        border = null;
        break;
      case AppButtonVariant.destructive:
        backgroundColor = _isHovered && !isDisabled
            ? AppTheme.errorColor.withOpacity(0.9)
            : AppTheme.errorColor;
        foregroundColor = Colors.white;
        border = null;
        break;
    }

    if (isDisabled) {
      backgroundColor = backgroundColor.withOpacity(0.5);
      foregroundColor = foregroundColor.withOpacity(0.5);
    }

    final iconWidget = widget.icon != null
        ? Icon(widget.icon, size: _iconSize, color: foregroundColor)
        : null;

    final loadingWidget = SizedBox(
      width: _iconSize,
      height: _iconSize,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: foregroundColor,
      ),
    );

    final content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          loadingWidget,
          const SizedBox(width: 8),
        ] else if (iconWidget != null && !widget.iconRight) ...[
          iconWidget,
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
          ),
        ),
        if (iconWidget != null && widget.iconRight && !widget.isLoading) ...[
          const SizedBox(width: 8),
          iconWidget,
        ],
      ],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: _padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: border,
          ),
          child: content,
        ),
      ),
    );
  }
}

class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final Color? color;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.color,
    this.tooltip,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isHovered = false;

  double get _size {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 32;
      case AppButtonSize.md:
        return 40;
      case AppButtonSize.lg:
        return 48;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 16;
      case AppButtonSize.md:
        return 20;
      case AppButtonSize.lg:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.color ??
        (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight);

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: _iconSize,
              color: _isHovered ? AppTheme.primaryColor : color,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}
