import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatusBadgeVariant { success, warning, error, neutral, primary }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeVariant variant;
  final IconData? icon;
  final bool small;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.neutral,
    this.icon,
    this.small = false,
  });

  factory StatusBadge.success({
    required String label,
    IconData? icon,
    bool small = false,
  }) {
    return StatusBadge(
      label: label,
      variant: StatusBadgeVariant.success,
      icon: icon ?? Icons.check_circle_outline,
      small: small,
    );
  }

  factory StatusBadge.warning({
    required String label,
    IconData? icon,
    bool small = false,
  }) {
    return StatusBadge(
      label: label,
      variant: StatusBadgeVariant.warning,
      icon: icon ?? Icons.warning_amber_outlined,
      small: small,
    );
  }

  factory StatusBadge.error({
    required String label,
    IconData? icon,
    bool small = false,
  }) {
    return StatusBadge(
      label: label,
      variant: StatusBadgeVariant.error,
      icon: icon ?? Icons.error_outline,
      small: small,
    );
  }

  factory StatusBadge.pending({
    required String label,
    IconData? icon,
    bool small = false,
  }) {
    return StatusBadge(
      label: label,
      variant: StatusBadgeVariant.warning,
      icon: icon ?? Icons.schedule_outlined,
      small: small,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    switch (variant) {
      case StatusBadgeVariant.success:
        backgroundColor = AppTheme.successLight;
        foregroundColor = AppTheme.successColor;
        borderColor = AppTheme.successColor.withOpacity(0.3);
        break;
      case StatusBadgeVariant.warning:
        backgroundColor = AppTheme.warningLight;
        foregroundColor = AppTheme.warningColor;
        borderColor = AppTheme.warningColor.withOpacity(0.3);
        break;
      case StatusBadgeVariant.error:
        backgroundColor = AppTheme.errorLight;
        foregroundColor = AppTheme.errorColor;
        borderColor = AppTheme.errorColor.withOpacity(0.3);
        break;
      case StatusBadgeVariant.primary:
        backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
        foregroundColor = AppTheme.primaryColor;
        borderColor = AppTheme.primaryColor.withOpacity(0.3);
        break;
      case StatusBadgeVariant.neutral:
        backgroundColor = isDark
            ? AppTheme.borderDark
            : AppTheme.backgroundLight;
        foregroundColor = isDark
            ? AppTheme.textSecondaryDark
            : AppTheme.textSecondaryLight;
        borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
        break;
    }

    if (isDark && variant != StatusBadgeVariant.neutral) {
      backgroundColor = foregroundColor.withOpacity(0.15);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: small ? 12 : 14,
              color: foregroundColor,
            ),
            SizedBox(width: small ? 4 : 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class ConditionBadge extends StatelessWidget {
  final String condition;

  const ConditionBadge({
    super.key,
    required this.condition,
  });

  StatusBadgeVariant get _variant {
    switch (condition.toLowerCase()) {
      case 'excellent':
      case 'new':
        return StatusBadgeVariant.success;
      case 'good':
        return StatusBadgeVariant.primary;
      case 'fair':
        return StatusBadgeVariant.warning;
      case 'poor':
      case 'broken':
        return StatusBadgeVariant.error;
      default:
        return StatusBadgeVariant.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: condition,
      variant: _variant,
    );
  }
}

class AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  final bool small;

  const AvailabilityBadge({
    super.key,
    required this.isAvailable,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: isAvailable ? 'Available' : 'Unavailable',
      variant: isAvailable
          ? StatusBadgeVariant.success
          : StatusBadgeVariant.neutral,
      icon: isAvailable ? Icons.check_circle_outline : Icons.block_outlined,
      small: small,
    );
  }
}
