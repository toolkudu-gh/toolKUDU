import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../core/utils/funny_messages.dart';

/// A snackbar widget that displays funny industry-themed messages
class FunnySnackBar {
  FunnySnackBar._();

  /// Show a success snackbar with a funny message
  static void showSuccess(
    BuildContext context, {
    String? message,
    String? customMessage,
    Duration duration = const Duration(seconds: 3),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successColor = AppTheme.getSuccessColor(context);

    _showSnackBar(
      context,
      message: customMessage ?? message ?? FunnyMessages.actionComplete,
      icon: Icons.check_circle_rounded,
      backgroundColor: isDark
          ? successColor.withOpacity(0.15)
          : successColor.withOpacity(0.1),
      iconColor: successColor,
      borderColor: successColor.withOpacity(0.3),
      duration: duration,
    );
  }

  /// Show an error snackbar with a funny message
  static void showError(
    BuildContext context, {
    String? message,
    String? customMessage,
    Duration duration = const Duration(seconds: 4),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _showSnackBar(
      context,
      message: customMessage ?? message ?? FunnyMessages.genericError,
      icon: Icons.error_rounded,
      backgroundColor: isDark
          ? AppTheme.errorColor.withOpacity(0.15)
          : AppTheme.errorColor.withOpacity(0.1),
      iconColor: AppTheme.errorColor,
      borderColor: AppTheme.errorColor.withOpacity(0.3),
      duration: duration,
    );
  }

  /// Show a warning snackbar with a funny message
  static void showWarning(
    BuildContext context, {
    String? message,
    String? customMessage,
    Duration duration = const Duration(seconds: 3),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warningColor = AppTheme.getWarningColor(context);

    _showSnackBar(
      context,
      message: customMessage ?? message ?? "Heads up! Something needs your attention.",
      icon: Icons.warning_rounded,
      backgroundColor: isDark
          ? warningColor.withOpacity(0.15)
          : warningColor.withOpacity(0.1),
      iconColor: warningColor,
      borderColor: warningColor.withOpacity(0.3),
      duration: duration,
    );
  }

  /// Show an info snackbar
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.getPrimaryColor(context);

    _showSnackBar(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: isDark
          ? primaryColor.withOpacity(0.15)
          : primaryColor.withOpacity(0.1),
      iconColor: primaryColor,
      borderColor: primaryColor.withOpacity(0.3),
      duration: duration,
    );
  }

  /// Show a loading snackbar with a funny message
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading(
    BuildContext context, {
    String? message,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.getPrimaryColor(context);

    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message ?? FunnyMessages.loading,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isDark
            ? AppTheme.surfaceElevatedDark
            : AppTheme.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
        ),
        duration: const Duration(days: 1), // Stays until dismissed
        dismissDirection: DismissDirection.none,
      ),
    );
  }

  /// Hide the current snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Color borderColor,
    required Duration duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isDark
            ? AppTheme.surfaceElevatedDark
            : AppTheme.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: borderColor),
        ),
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: iconColor,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  // ============== Specific action snackbars ==============

  /// Show success message for tool added
  static void toolAdded(BuildContext context) {
    showSuccess(context, customMessage: FunnyMessages.toolAdded);
  }

  /// Show success message for toolbox created
  static void toolboxCreated(BuildContext context) {
    showSuccess(context, customMessage: FunnyMessages.toolboxCreated);
  }

  /// Show success message for sharing approved
  static void sharingApproved(BuildContext context) {
    showSuccess(context, customMessage: FunnyMessages.sharingApproved);
  }

  /// Show success message for profile updated
  static void profileUpdated(BuildContext context) {
    showSuccess(context, customMessage: FunnyMessages.profileUpdated);
  }

  /// Show success message for tool returned
  static void toolReturned(BuildContext context) {
    showSuccess(context, customMessage: FunnyMessages.toolReturned);
  }

  /// Show success message for buddy added
  static void buddyAdded(BuildContext context) {
    showSuccess(context, customMessage: FunnyMessages.buddyAdded);
  }

  /// Show error for network issues
  static void networkError(BuildContext context) {
    showError(context, customMessage: FunnyMessages.networkError);
  }

  /// Show error for save failure
  static void saveFailed(BuildContext context) {
    showError(context, customMessage: FunnyMessages.saveFailed);
  }

  /// Show error for invalid input
  static void invalidInput(BuildContext context) {
    showError(context, customMessage: FunnyMessages.invalidInput);
  }
}
