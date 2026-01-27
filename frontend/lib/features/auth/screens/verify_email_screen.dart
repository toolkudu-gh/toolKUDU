import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isResending = false;

  @override
  void dispose() {
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _fullCode => _codeControllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    final code = _fullCode;
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the complete 6-digit code'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final success = await ref.read(authStateProvider.notifier).confirmSignUp(
          widget.email,
          code,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email verified successfully! Please sign in.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.go('/login');
    }
  }

  Future<void> _handleResendCode() async {
    setState(() => _isResending = true);

    final success = await ref.read(authStateProvider.notifier).resendVerificationCode(
          widget.email,
        );

    setState(() => _isResending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Verification code sent to ${widget.email}'
                : 'Failed to resend code. Please try again.',
          ),
          backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
    }
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_fullCode.length == 6) {
      _handleVerify();
    }
  }

  void _handlePaste(String pastedText) {
    final cleanText = pastedText.replaceAll(RegExp(r'\D'), '');
    if (cleanText.length == 6) {
      for (int i = 0; i < 6; i++) {
        _codeControllers[i].text = cleanText[i];
      }
      _handleVerify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  AppIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => context.go('/register'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 48 : 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mark_email_read_outlined,
                            size: 40,
                            color: AppTheme.primaryColor,
                          ),
                        ).animate().fadeIn(duration: 300.ms).scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1, 1),
                              duration: 300.ms,
                              curve: Curves.easeOutBack,
                            ),

                        const SizedBox(height: 24),

                        Text(
                          'Verify Your Email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                        const SizedBox(height: 12),

                        Text(
                          'We\'ve sent a 6-digit verification code to',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                        ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

                        const SizedBox(height: 4),

                        Text(
                          widget.email,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                        const SizedBox(height: 32),

                        // Code input
                        AppCard(
                          padding: const EdgeInsets.all(24),
                          enableHover: false,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(6, (index) {
                                  return Container(
                                    width: 45,
                                    height: 55,
                                    margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
                                    child: TextField(
                                      controller: _codeControllers[index],
                                      focusNode: _focusNodes[index],
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      maxLength: 1,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppTheme.textPrimaryDark
                                            : AppTheme.textPrimaryLight,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                        filled: true,
                                        fillColor: isDark
                                            ? AppTheme.backgroundDark
                                            : AppTheme.backgroundLight,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? AppTheme.borderDark
                                                : AppTheme.borderLight,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? AppTheme.borderDark
                                                : AppTheme.borderLight,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                          borderSide: BorderSide(
                                            color: AppTheme.primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) => _onCodeChanged(index, value),
                                      onTap: () {
                                        Clipboard.getData('text/plain').then((data) {
                                          if (data?.text != null && data!.text!.length == 6) {
                                            _handlePaste(data.text!);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                }),
                              ),

                              const SizedBox(height: 24),

                              // Error message
                              if (authState.error != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorLight,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    border: Border.all(
                                      color: AppTheme.errorColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 18,
                                        color: AppTheme.errorColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          authState.error!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Verify button
                              AppButton(
                                label: 'Verify Email',
                                onPressed: authState.isLoading ? null : _handleVerify,
                                isLoading: authState.isLoading,
                                fullWidth: true,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(
                              begin: 0.1,
                              end: 0,
                              delay: 250.ms,
                              duration: 400.ms,
                              curve: Curves.easeOutCubic,
                            ),

                        const SizedBox(height: 24),

                        // Resend code
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Didn't receive the code?",
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                              ),
                            ),
                            TextButton(
                              onPressed: _isResending ? null : _handleResendCode,
                              child: _isResending
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryColor,
                                      ),
                                    )
                                  : Text(
                                      'Resend',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 350.ms, duration: 300.ms),

                        const SizedBox(height: 16),

                        // Info card
                        AppCard(
                          padding: const EdgeInsets.all(14),
                          enableHover: false,
                          backgroundColor: AppTheme.primaryColor.withOpacity(isDark ? 0.1 : 0.05),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Check your spam folder if you don\'t see the email in your inbox.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
