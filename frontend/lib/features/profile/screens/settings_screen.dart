import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../core/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    onPressed: () => context.go('/profile'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Account Section
                  _buildSectionHeader('Account', isDark),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: EdgeInsets.zero,
                    enableHover: false,
                    child: Column(
                      children: [
                        _buildSettingItem(
                          context,
                          isDark,
                          icon: Icons.email_outlined,
                          title: 'Email',
                          subtitle: 'user@example.com',
                          onTap: () {},
                          isFirst: true,
                        ),
                        _buildDivider(isDark),
                        _buildSettingItem(
                          context,
                          isDark,
                          icon: Icons.lock_outlined,
                          title: 'Change Password',
                          onTap: () {},
                          isLast: true,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                  const SizedBox(height: 24),

                  // Notifications Section
                  _buildSectionHeader('Notifications', isDark),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: EdgeInsets.zero,
                    enableHover: false,
                    child: Column(
                      children: [
                        _buildSwitchItem(
                          context,
                          isDark,
                          icon: Icons.notifications_outlined,
                          title: 'Push Notifications',
                          subtitle: 'Receive notifications about activity',
                          value: true,
                          onChanged: (value) {},
                          isFirst: true,
                        ),
                        _buildDivider(isDark),
                        _buildSwitchItem(
                          context,
                          isDark,
                          icon: Icons.email_outlined,
                          title: 'Email Notifications',
                          value: false,
                          onChanged: (value) {},
                          isLast: true,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

                  const SizedBox(height: 24),

                  // Privacy Section
                  _buildSectionHeader('Privacy', isDark),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: EdgeInsets.zero,
                    enableHover: false,
                    child: Column(
                      children: [
                        _buildSettingItem(
                          context,
                          isDark,
                          icon: Icons.visibility_outlined,
                          title: 'Default Toolbox Visibility',
                          subtitle: 'Private',
                          onTap: () {},
                          isFirst: true,
                        ),
                        _buildDivider(isDark),
                        _buildSettingItem(
                          context,
                          isDark,
                          icon: Icons.block_outlined,
                          title: 'Blocked Users',
                          onTap: () {},
                          isLast: true,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                  const SizedBox(height: 24),

                  // App Section
                  _buildSectionHeader('App', isDark),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: EdgeInsets.zero,
                    enableHover: false,
                    child: Column(
                      children: [
                        _buildSettingItem(
                          context,
                          isDark,
                          icon: Icons.palette_outlined,
                          title: 'Theme',
                          subtitle: _getThemeLabel(ref.watch(themeProvider)),
                          onTap: () => _showThemeDialog(context, isDark, ref),
                          isFirst: true,
                        ),
                        _buildDivider(isDark),
                        _buildSettingItem(
                          context,
                          isDark,
                          icon: Icons.info_outlined,
                          title: 'About',
                          subtitle: 'Version 1.0.0',
                          showChevron: false,
                          onTap: () {},
                          isLast: true,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 250.ms, duration: 300.ms),

                  const SizedBox(height: 24),

                  // Danger Zone Section
                  _buildSectionHeader('Danger Zone', isDark, isDestructive: true),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: EdgeInsets.zero,
                    enableHover: false,
                    border: Border.all(
                      color: AppTheme.errorColor.withOpacity(0.3),
                    ),
                    child: _buildSettingItem(
                      context,
                      isDark,
                      icon: Icons.delete_forever,
                      title: 'Delete Account',
                      isDestructive: true,
                      onTap: () => _showDeleteAccountDialog(context, isDark),
                      isFirst: true,
                      isLast: true,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isDestructive
              ? AppTheme.errorColor
              : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 56,
      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showChevron = true,
    bool isDestructive = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isDestructive
                    ? AppTheme.errorColor
                    : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDestructive
                            ? AppTheme.errorColor
                            : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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
              if (showChevron && !isDestructive)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeDialog(BuildContext context, bool isDark, WidgetRef ref) {
    final currentTheme = ref.read(themeProvider);

    AppBottomSheet.show(
      context: context,
      title: 'Choose Theme',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeOption(context, isDark, 'System', Icons.settings_outlined, ThemeMode.system, currentTheme, ref),
          const SizedBox(height: 8),
          _buildThemeOption(context, isDark, 'Light', Icons.light_mode_outlined, ThemeMode.light, currentTheme, ref),
          const SizedBox(height: 8),
          _buildThemeOption(context, isDark, 'Dark', Icons.dark_mode_outlined, ThemeMode.dark, currentTheme, ref),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    bool isDark,
    String title,
    IconData icon,
    ThemeMode mode,
    ThemeMode currentTheme,
    WidgetRef ref,
  ) {
    final isSelected = mode == currentTheme;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(mode);
        Navigator.of(context, rootNavigator: true).pop();
      },
      backgroundColor: isSelected
          ? AppTheme.primaryColor.withOpacity(isDark ? 0.15 : 0.08)
          : null,
      border: isSelected
          ? Border.all(color: AppTheme.primaryColor)
          : null,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppTheme.primaryColor
                    : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: AppTheme.primaryColor,
            ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, bool isDark) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Delete Account',
      description:
          'This action cannot be undone. All your toolboxes, tools, and data will be permanently deleted.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      // TODO: Delete account
    }
  }
}
