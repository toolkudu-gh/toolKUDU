import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/location_permission_dialog.dart';

class MagicLinkScreen extends ConsumerStatefulWidget {
  const MagicLinkScreen({super.key});

  @override
  ConsumerState<MagicLinkScreen> createState() => _MagicLinkScreenState();
}

class _MagicLinkScreenState extends ConsumerState<MagicLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  String? _emailError;
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Show location dialog if user hasn't set location, then navigate to home
  Future<void> _handleSuccessfulLogin() async {
    if (!mounted) return;

    // Check if we should prompt for location
    final shouldPrompt = ref.read(shouldPromptLocationProvider);

    if (shouldPrompt) {
      // Show the location permission dialog
      await LocationPermissionDialog.show(context);
    }

    if (mounted) {
      context.go('/home');
    }
  }

  bool _validateEmail() {
    setState(() => _emailError = null);

    if (_emailController.text.isEmpty) {
      setState(() => _emailError = 'Please enter your email');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      setState(() => _emailError = 'Please enter a valid email');
      return false;
    }
    return true;
  }

  Future<void> _handleSendMagicLink() async {
    if (!_validateEmail()) return;

    final email = _emailController.text.trim();

    try {
      final success = await ref.read(authStateProvider.notifier).requestMagicLink(email);

      if (mounted) {
        if (success) {
          setState(() => _codeSent = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Check your email for the verification code (Demo: use 123456)'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          final error = ref.read(authStateProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to send magic link'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleVerifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final success = await ref.read(authStateProvider.notifier).verifyMagicLinkCode(code);

    if (success && mounted) {
      await _handleSuccessfulLogin();
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
                    onPressed: () => context.go('/login'),
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
                    child: Form(
                      key: _formKey,
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
                              _codeSent ? Icons.pin_outlined : Icons.mail_outline,
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
                            _codeSent ? 'Enter Verification Code' : 'Magic Link Sign In',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                          const SizedBox(height: 8),

                          Text(
                            _codeSent
                                ? 'We sent a verification code to ${_emailController.text}'
                                : 'We\'ll send you a verification code to sign in',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                          ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

                          const SizedBox(height: 32),

                          // Form Card
                          AppCard(
                            padding: const EdgeInsets.all(24),
                            enableHover: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!_codeSent) ...[
                                  AppInput(
                                    controller: _emailController,
                                    label: 'Email',
                                    hint: 'Enter your email address',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.done,
                                    errorText: _emailError,
                                    onChanged: (_) {
                                      if (_emailError != null) {
                                        setState(() => _emailError = null);
                                      }
                                    },
                                    onSubmitted: (_) => _handleSendMagicLink(),
                                  ),
                                ] else ...[
                                  AppInput(
                                    controller: _codeController,
                                    label: 'Verification Code',
                                    hint: 'Enter the code from your email',
                                    prefixIcon: Icons.pin_outlined,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _handleVerifyCode(),
                                  ),
                                ],

                                const SizedBox(height: 16),

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

                                // Submit button
                                AppButton(
                                  label: _codeSent ? 'Verify Code' : 'Send Magic Link',
                                  icon: _codeSent ? Icons.check : Icons.send_rounded,
                                  onPressed: authState.isLoading
                                      ? null
                                      : (_codeSent ? _handleVerifyCode : _handleSendMagicLink),
                                  isLoading: authState.isLoading,
                                  fullWidth: true,
                                ),

                                if (_codeSent) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() => _codeSent = false);
                                          _codeController.clear();
                                        },
                                        child: Text(
                                          'Change Email',
                                          style: TextStyle(
                                            color: isDark
                                                ? AppTheme.textSecondaryDark
                                                : AppTheme.textSecondaryLight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: authState.isLoading ? null : _handleSendMagicLink,
                                        child: Text(
                                          'Resend Code',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
                                begin: 0.1,
                                end: 0,
                                delay: 200.ms,
                                duration: 400.ms,
                                curve: Curves.easeOutCubic,
                              ),

                          const SizedBox(height: 24),

                          // Back to login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Remember your password?',
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
                        ],
                      ),
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
