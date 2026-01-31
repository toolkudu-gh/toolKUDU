import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  // Username editing state
  bool _isEditingUsername = false;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameError;
  Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _displayNameController = TextEditingController(text: user?.displayName);
    _usernameController = TextEditingController(text: user?.username);
    _bioController = TextEditingController(text: user?.bio);
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _displayNameController.dispose();
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    if (!_isEditingUsername) return;

    final username = _usernameController.text.trim();
    final user = ref.read(currentUserProvider);

    // If same as current username, reset state
    if (username == user?.username) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    // Cancel previous debounce
    _usernameDebounce?.cancel();

    // Validate length
    if (username.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameError = 'Username must be at least 3 characters';
        _isCheckingUsername = false;
      });
      return;
    }

    // Validate format
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameError = 'Only letters, numbers, and underscores allowed';
        _isCheckingUsername = false;
      });
      return;
    }

    // Show loading indicator
    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
      _usernameError = null;
    });

    // Debounce the API call (300ms)
    _usernameDebounce = Timer(const Duration(milliseconds: 300), () {
      _checkUsernameAvailability(username);
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    final authService = ref.read(authServiceProvider);
    final result = await authService.checkUsernameAvailability(username);

    if (!mounted) return;

    setState(() {
      _isCheckingUsername = false;
      _isUsernameAvailable = result['available'] == true;
      if (!_isUsernameAvailable!) {
        _usernameError = 'Username is already taken';
      } else {
        _usernameError = null;
      }
    });
  }

  void _startEditingUsername() {
    final user = ref.read(currentUserProvider);
    if (user?.canChangeUsername != true) return;
    setState(() {
      _isEditingUsername = true;
    });
  }

  void _cancelEditingUsername() {
    final user = ref.read(currentUserProvider);
    setState(() {
      _isEditingUsername = false;
      _usernameController.text = user?.username ?? '';
      _isUsernameAvailable = null;
      _usernameError = null;
    });
  }

  Widget? _buildUsernameSuffixIcon() {
    final username = _usernameController.text.trim();
    final user = ref.read(currentUserProvider);

    // If same as current username, no indicator needed
    if (username == user?.username) return null;

    // Don't show anything if username is too short
    if (username.length < 3) return null;

    // Show loading indicator while checking
    if (_isCheckingUsername) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.primaryColor,
        ),
      );
    }

    // Show availability status
    if (_isUsernameAvailable == true) {
      return Icon(
        Icons.check_circle,
        color: AppTheme.successColor,
        size: 20,
      );
    } else if (_isUsernameAvailable == false) {
      return Icon(
        Icons.cancel,
        color: AppTheme.errorColor,
        size: 20,
      );
    }

    return null;
  }

  String _getCooldownText(DateTime? availableDate) {
    if (availableDate == null) return 'Can change once per month';
    final formatter = DateFormat('MMM d, yyyy');
    return 'Can change again on ${formatter.format(availableDate)}';
  }

  Future<void> _handleSave() async {
    final user = ref.read(currentUserProvider);
    final newUsername = _usernameController.text.trim();
    final isUsernameChanged = _isEditingUsername && newUsername != user?.username;

    // Validate username if changed
    if (isUsernameChanged) {
      if (_isUsernameAvailable != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please choose an available username'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    // TODO: Call API to update profile
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUsernameChanged
              ? 'Profile updated with new username'
              : 'Profile updated'),
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

                  // Username (editable with 30-day cooldown)
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
                            if (user?.canChangeUsername != true) ...[
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
                                  _getCooldownText(user?.usernameChangeAvailableDate),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppTheme.textMutedDark
                                        : AppTheme.textMutedLight,
                                  ),
                                ),
                              ),
                            ] else if (!_isEditingUsername) ...[
                              GestureDetector(
                                onTap: _startEditingUsername,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Tap to edit',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isEditingUsername) ...[
                          AppInput(
                            controller: _usernameController,
                            prefixIcon: Icons.alternate_email,
                            errorText: _usernameError,
                            suffixIcon: _buildUsernameSuffixIcon(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _cancelEditingUsername,
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          GestureDetector(
                            onTap: user?.canChangeUsername == true ? _startEditingUsername : null,
                            child: Container(
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
                          ),
                        ],
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
