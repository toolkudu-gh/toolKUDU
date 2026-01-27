import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/tool.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';

class BorrowRequestDialog extends StatefulWidget {
  final Tool tool;

  const BorrowRequestDialog({super.key, required this.tool});

  static Future<String?> show({
    required BuildContext context,
    required Tool tool,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => BorrowRequestDialog(tool: tool),
    );
  }

  @override
  State<BorrowRequestDialog> createState() => _BorrowRequestDialogState();
}

class _BorrowRequestDialogState extends State<BorrowRequestDialog> {
  final _messageController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    setState(() => _isSubmitting = true);
    Navigator.pop(context, _messageController.text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: Icon(
                      Icons.handshake_outlined,
                      size: 24,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request to Borrow',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Send a request to the owner',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
            ).animate().fadeIn(duration: 200.ms),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tool info card
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    enableHover: false,
                    backgroundColor: AppTheme.primaryColor.withOpacity(isDark ? 0.1 : 0.05),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.surfaceDark
                                : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: widget.tool.primaryImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  child: Image.network(
                                    widget.tool.primaryImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.handyman_rounded,
                                      size: 22,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.handyman_rounded,
                                  size: 22,
                                  color: AppTheme.primaryColor,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.tool.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.textPrimaryDark
                                      : AppTheme.textPrimaryLight,
                                ),
                              ),
                              if (widget.tool.brand != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.tool.brand!,
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
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 200.ms),

                  const SizedBox(height: 20),

                  // Message label
                  Text(
                    'Add a message (optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Message input
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: _isFocused
                            ? AppTheme.primaryColor
                            : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                        width: _isFocused ? 2 : 1,
                      ),
                      boxShadow: _isFocused
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      maxLines: 3,
                      maxLength: 500,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g., "I need this for a weekend project..."',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textMutedLight,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                        counterStyle: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textMutedLight,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 200.ms),

                  const SizedBox(height: 8),

                  // Info text
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: isDark
                            ? AppTheme.textMutedDark
                            : AppTheme.textMutedLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'The owner will be notified of your request.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textMutedLight,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 200.ms),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.outline,
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Send Request',
                      icon: Icons.send_rounded,
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      isLoading: _isSubmitting,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 200.ms),
          ],
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 200.ms,
          curve: Curves.easeOutCubic,
        ).fadeIn(duration: 200.ms);
  }
}
