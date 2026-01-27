import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

class AppDialog extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? description;
  final Widget? content;
  final List<DialogAction>? actions;
  final bool showCloseButton;
  final double? maxWidth;

  const AppDialog({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.description,
    this.content,
    this.actions,
    this.showCloseButton = true,
    this.maxWidth,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    IconData? icon,
    Color? iconColor,
    String? description,
    Widget? content,
    List<DialogAction>? actions,
    bool showCloseButton = true,
    bool barrierDismissible = true,
    double? maxWidth,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        description: description,
        content: content,
        actions: actions,
        showCloseButton: showCloseButton,
        maxWidth: maxWidth,
      ),
    );
  }

  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    String? description,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return show<bool>(
      context: context,
      icon: isDestructive ? Icons.warning_amber_rounded : Icons.help_outline,
      iconColor: isDestructive ? AppTheme.warningColor : null,
      title: title,
      description: description,
      showCloseButton: false,
      actions: [
        DialogAction(
          label: cancelLabel,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
          variant: AppButtonVariant.outline,
        ),
        DialogAction(
          label: confirmLabel,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
          variant: isDestructive
              ? AppButtonVariant.destructive
              : AppButtonVariant.primary,
        ),
      ],
    );
  }

  static Future<void> success({
    required BuildContext context,
    required String title,
    String? description,
    String buttonLabel = 'Done',
  }) {
    return show(
      context: context,
      icon: Icons.check_circle_outline,
      iconColor: AppTheme.successColor,
      title: title,
      description: description,
      showCloseButton: false,
      actions: [
        DialogAction(
          label: buttonLabel,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ],
    );
  }

  static Future<void> error({
    required BuildContext context,
    required String title,
    String? description,
    String buttonLabel = 'OK',
  }) {
    return show(
      context: context,
      icon: Icons.error_outline,
      iconColor: AppTheme.errorColor,
      title: title,
      description: description,
      showCloseButton: false,
      actions: [
        DialogAction(
          label: buttonLabel,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? AppTheme.primaryColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 400,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.shadowXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null) ...[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: effectiveIconColor.withOpacity(
                                isDark ? 0.2 : 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLg),
                          ),
                          child: Icon(
                            icon,
                            size: 24,
                            color: effectiveIconColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.textPrimaryDark
                                    : AppTheme.textPrimaryLight,
                              ),
                            ),
                            if (description != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (showCloseButton)
                        GestureDetector(
                          onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: isDark
                                ? AppTheme.textMutedDark
                                : AppTheme.textMutedLight,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            if (content != null)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: content,
                ),
              ),

            // Actions
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: actions!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final action = entry.value;
                    final isLast = index == actions!.length - 1;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: isLast ? 0 : 12),
                        child: AppButton(
                          label: action.label,
                          onPressed: action.onPressed,
                          variant: action.variant,
                          isLoading: action.isLoading,
                          fullWidth: true,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DialogAction {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;

  const DialogAction({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
  });
}

class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<DialogAction>? actions;
  final bool showDragHandle;
  final double? maxHeight;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.showDragHandle = true,
    this.maxHeight,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    List<DialogAction>? actions,
    bool showDragHandle = true,
    bool isScrollControlled = true,
    double? maxHeight,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        title: title,
        actions: actions,
        showDragHandle: showDragHandle,
        maxHeight: maxHeight,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? mediaQuery.size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: isDark
                          ? AppTheme.textMutedDark
                          : AppTheme.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                title != null ? 16 : 24,
                24,
                actions != null ? 0 : 24,
              ),
              child: child,
            ),
          ),
          if (actions != null && actions!.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: actions!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final action = entry.value;
                    final isLast = index == actions!.length - 1;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: isLast ? 0 : 12),
                        child: AppButton(
                          label: action.label,
                          onPressed: action.onPressed,
                          variant: action.variant,
                          isLoading: action.isLoading,
                          fullWidth: true,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
