import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _displayNameController = TextEditingController(text: user?.displayName);
    _bioController = TextEditingController(text: user?.bio);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    // TODO: Call API to update profile
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

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
                    icon: Icons.close,
                    onPressed: () => context.go('/profile'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  AppButton(
                    label: 'Save',
                    onPressed: _isLoading ? null : _handleSave,
                    isLoading: _isLoading,
                    size: AppButtonSize.sm,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Avatar Section
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    enableHover: false,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // TODO: Pick image
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    width: 3,
                                  ),
                                ),
                                child: user?.avatarUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          user!.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.person_rounded,
                                            size: 50,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.person_rounded,
                                        size: 50,
                                        color: AppTheme.primaryColor,
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? AppTheme.surfaceDark
                                          : AppTheme.surfaceLight,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to change photo',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                  const SizedBox(height: 20),

                  // Profile Info
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    enableHover: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),

                        AppInput(
                          controller: _displayNameController,
                          label: 'Display Name',
                          hint: 'How should we call you?',
                          prefixIcon: Icons.person_outlined,
                        ),
                        const SizedBox(height: 16),

                        AppInput(
                          controller: _bioController,
                          label: 'Bio',
                          hint: 'Tell us about yourself...',
                          prefixIcon: Icons.edit_note_outlined,
                          maxLines: 3,
                          maxLength: 150,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

                  const SizedBox(height: 20),

                  // Username (read-only)
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    enableHover: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Username',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppTheme.textPrimaryDark
                                    : AppTheme.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.borderDark
                                    : AppTheme.borderLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Cannot be changed',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? AppTheme.textMutedDark
                                      : AppTheme.textMutedLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.backgroundDark
                                : AppTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.borderDark
                                  : AppTheme.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.alternate_email,
                                size: 20,
                                color: isDark
                                    ? AppTheme.textMutedDark
                                    : AppTheme.textMutedLight,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                user?.username ?? 'username',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
