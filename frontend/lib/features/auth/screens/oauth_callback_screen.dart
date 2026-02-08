import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/location_permission_dialog.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/location_provider.dart';

/// OAuth Callback Screen
/// Handles the redirect from Clerk OAuth (Google sign-in)
/// Extracts session token from URL and completes authentication
class OAuthCallbackScreen extends ConsumerStatefulWidget {
  final String? sessionToken;
  final String? sessionId;
  final String? code;
  final String? error;

  const OAuthCallbackScreen({
    super.key,
    this.sessionToken,
    this.sessionId,
    this.code,
    this.error,
  });

  @override
  ConsumerState<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends ConsumerState<OAuthCallbackScreen> {
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    // Check for error from OAuth provider
    if (widget.error != null && widget.error!.isNotEmpty) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Authentication failed: ${widget.error}';
      });
      return;
    }

    // Process the OAuth callback
    final success = await ref.read(authStateProvider.notifier).handleOAuthCallback(
      sessionToken: widget.sessionToken,
      sessionId: widget.sessionId,
      code: widget.code,
    );

    if (!mounted) return;

    if (success) {
      // Check if we should prompt for location
      final shouldPrompt = ref.read(shouldPromptLocationProvider);

      if (shouldPrompt) {
        await LocationPermissionDialog.show(context);
      }

      if (mounted) {
        context.go('/home');
      }
    } else {
      final authState = ref.read(authStateProvider);
      setState(() {
        _isProcessing = false;
        _errorMessage = authState.error ?? 'Authentication failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing) ...[
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Completing sign in...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we set up your account',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                ),
              ] else if (_errorMessage != null) ...[
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Sign In Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: const Text('Back to Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
