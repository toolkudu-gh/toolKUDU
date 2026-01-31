import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';
import '../../core/utils/funny_messages.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customAction;
  final bool compact;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.customAction,
    this.compact = false,
  });

  factory EmptyState.noData({
    String title = 'No data found',
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyState(
      icon: Icons.inbox_outlined,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory EmptyState.noResults({
    String title = 'No results found',
    String? description,
    String? actionLabel = 'Clear filters',
    VoidCallback? onAction,
  }) {
    return EmptyState(
      icon: Icons.search_off_outlined,
      title: title,
      description: description ?? FunnyMessages.noSearchResults,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory EmptyState.error({
    String title = 'Something went wrong',
    String? description,
    String? actionLabel = 'Retry',
    VoidCallback? onAction,
  }) {
    return EmptyState(
      icon: Icons.error_outline,
      title: title,
      description: description ?? FunnyMessages.genericError,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory EmptyState.noConnection({
    String title = 'No internet connection',
    String? description,
    String? actionLabel = 'Retry',
    VoidCallback? onAction,
  }) {
    return EmptyState(
      icon: Icons.wifi_off_outlined,
      title: title,
      description: description ?? FunnyMessages.networkError,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  // Specific empty states with funny messages
  factory EmptyState.noTools({
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return EmptyState(
      icon: Icons.handyman_outlined,
      title: 'No Tools Yet',
      description: FunnyMessages.noTools,
      actionLabel: actionLabel ?? 'Add First Tool',
      onAction: onAction,
    );
  }

  factory EmptyState.noToolboxes({
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'No Toolboxes Yet',
      description: FunnyMessages.noToolboxes,
      actionLabel: actionLabel ?? 'Create Toolbox',
      onAction: onAction,
    );
  }

  factory EmptyState.noRequests({
    VoidCallback? onAction,
  }) {
    return EmptyState(
      icon: Icons.swap_horiz_outlined,
      title: 'No Requests',
      description: FunnyMessages.noRequests,
      onAction: onAction,
    );
  }

  factory EmptyState.noBuddies({
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return EmptyState(
      icon: Icons.people_outline,
      title: 'No Buddies Yet',
      description: FunnyMessages.noBuddies,
      actionLabel: actionLabel ?? 'Find Buddies',
      onAction: onAction,
    );
  }

  factory EmptyState.noHistory({
    VoidCallback? onAction,
  }) {
    return EmptyState(
      icon: Icons.history_outlined,
      title: 'No History',
      description: FunnyMessages.noHistory,
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 24 : 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 64 : 80,
              height: compact ? 64 : 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.borderDark
                    : AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: Icon(
                icon,
                size: compact ? 32 : 40,
                color: isDark
                    ? AppTheme.textMutedDark
                    : AppTheme.textMutedLight,
              ),
            ),
            SizedBox(height: compact ? 16 : 24),
            Text(
              title,
              style: TextStyle(
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 16 : 24),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.primary,
              ),
            ],
            if (customAction != null) ...[
              SizedBox(height: compact ? 16 : 24),
              customAction!,
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyListPlaceholder extends StatelessWidget {
  final String message;
  final IconData? icon;

  const EmptyListPlaceholder({
    super.key,
    required this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: isDark
                  ? AppTheme.textMutedDark
                  : AppTheme.textMutedLight,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppTheme.textMutedDark
                  : AppTheme.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
