import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import '../../core/providers/location_provider.dart';
import 'app_button.dart';
import 'app_input.dart';

/// Dialog to request location permission after login/registration
/// Shows after Google Sign-In, Magic Link, or regular registration
class LocationPermissionDialog extends ConsumerStatefulWidget {
  const LocationPermissionDialog({super.key});

  /// Show the location permission dialog
  /// Returns true if location was obtained, false if skipped
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocationPermissionDialog(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<LocationPermissionDialog> createState() =>
      _LocationPermissionDialogState();
}

class _LocationPermissionDialogState
    extends ConsumerState<LocationPermissionDialog> {
  bool _showZipcodeInput = false;
  final _zipcodeController = TextEditingController();
  String? _zipcodeError;

  @override
  void dispose() {
    _zipcodeController.dispose();
    super.dispose();
  }

  Future<void> _handleUseMyLocation() async {
    final success =
        await ref.read(locationStateProvider.notifier).requestLocationPermission();

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleZipcodeSubmit() async {
    final zipcode = _zipcodeController.text.trim();

    // Validate zipcode (US format: 5 digits)
    if (zipcode.isEmpty) {
      setState(() => _zipcodeError = 'Please enter a zipcode');
      return;
    }
    if (zipcode.length != 5 || int.tryParse(zipcode) == null) {
      setState(() => _zipcodeError = 'Please enter a valid 5-digit zipcode');
      return;
    }

    setState(() => _zipcodeError = null);

    final success = await ref
        .read(locationStateProvider.notifier)
        .setLocationFromZipcode(zipcode);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _handleSkip() {
    ref.read(locationStateProvider.notifier).markAsPrompted();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationState = ref.watch(locationStateProvider);
    final isLoading = locationState.isLoading || locationState.isRequestingPermission;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 36,
                  color: AppTheme.primaryColor,
                ),
              ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: 20),

              // Title
              Text(
                'Find Tools Near You',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

              const SizedBox(height: 12),

              // Description
              Text(
                'Share your location to discover tools available for borrowing in your area.',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

              const SizedBox(height: 24),

              // Error message
              if (locationState.error != null) ...[
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
                          locationState.error!,
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

              // Content based on mode
              if (_showZipcodeInput) ...[
                // Zipcode input mode
                AppInput(
                  controller: _zipcodeController,
                  label: 'Zipcode',
                  hint: 'Enter your 5-digit zipcode',
                  prefixIcon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                  errorText: _zipcodeError,
                  maxLength: 5,
                  onChanged: (_) {
                    if (_zipcodeError != null) {
                      setState(() => _zipcodeError = null);
                    }
                  },
                  onSubmitted: (_) => _handleZipcodeSubmit(),
                ),

                const SizedBox(height: 16),

                // Submit zipcode button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Continue',
                    onPressed: isLoading ? null : _handleZipcodeSubmit,
                    isLoading: isLoading,
                    fullWidth: true,
                  ),
                ),

                const SizedBox(height: 12),

                // Back to GPS option
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => setState(() => _showZipcodeInput = false),
                  child: Text(
                    'Use GPS Instead',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ] else ...[
                // GPS mode (default)
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Use My Location',
                    icon: Icons.my_location,
                    onPressed: isLoading ? null : _handleUseMyLocation,
                    isLoading: isLoading,
                    fullWidth: true,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                const SizedBox(height: 12),

                // Zipcode fallback
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => setState(() => _showZipcodeInput = true),
                  child: Text(
                    'Enter Zipcode Instead',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
              ],

              const SizedBox(height: 8),

              // Skip option
              TextButton(
                onPressed: isLoading ? null : _handleSkip,
                child: Text(
                  'Skip for Now',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textMutedDark
                        : AppTheme.textMutedLight,
                    fontSize: 13,
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

              // Privacy note
              const SizedBox(height: 8),
              Text(
                'Your location is only used to show nearby tools and is never shared publicly.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppTheme.textMutedDark
                      : AppTheme.textMutedLight,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 350.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
