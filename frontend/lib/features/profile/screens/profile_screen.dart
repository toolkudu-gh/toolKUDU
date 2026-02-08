import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/funny_snackbar.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/responsive.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.settings_outlined,
                    onPressed: () => context.go('/profile/settings'),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 24),

              // Profile Card
              AppCard(
                padding: const EdgeInsets.all(24),
                enableHover: false,
                child: Column(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: () => context.go('/profile/edit'),
                      child: Stack(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
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
                                        size: 44,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.person_rounded,
                                    size: 44,
                                    color: AppTheme.primaryColor,
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.surfaceDark
                                      : AppTheme.surfaceLight,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      user?.displayNameOrUsername ?? 'User',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user?.username ?? 'username'}',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),

                    // Bio
                    if (user?.bio != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        user!.bio!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Stats - Tool Buddies terminology
                    StatRow(
                      stats: [
                        StatItem(
                          value: '${user?.followersCount ?? 0}',
                          label: 'Tool Buddies',
                        ),
                        StatItem(
                          value: '${user?.followingCount ?? 0}',
                          label: 'Following',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Edit and Share buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Edit Profile',
                            variant: AppButtonVariant.outline,
                            icon: Icons.edit_outlined,
                            onPressed: () => context.go('/profile/edit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        AppIconButton(
                          icon: Icons.share_outlined,
                          tooltip: 'Share Profile',
                          onPressed: () => _shareProfile(context, user?.username ?? 'user'),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(
                    begin: 0.1,
                    end: 0,
                    delay: 100.ms,
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: 24),

              // Menu Section
              _buildMenuSection(
                context,
                isDark,
                title: 'Activity',
                items: [
                  _MenuItem(
                    icon: Icons.people_outline,
                    title: 'Buddies',
                    onTap: () => context.go('/buddies'),
                  ),
                  _MenuItem(
                    icon: Icons.inventory_2_outlined,
                    title: 'My Toolboxes',
                    onTap: () => context.go('/home'),
                  ),
                  _MenuItem(
                    icon: Icons.history_outlined,
                    title: 'Lending History',
                    onTap: () {},
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(
                    begin: 0.1,
                    end: 0,
                    delay: 200.ms,
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: 16),

              _buildMenuSection(
                context,
                isDark,
                title: 'Account',
                items: [
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () => context.go('/profile/settings'),
                  ),
                  _MenuItem(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    isDestructive: true,
                    onTap: () => _showSignOutConfirmation(context, ref),
                  ),
                ],
              ).animate().fadeIn(delay: 250.ms, duration: 300.ms).slideY(
                    begin: 0.1,
                    end: 0,
                    delay: 250.ms,
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    bool isDark, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.textMutedDark
                  : AppTheme.textMutedLight,
            ),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          enableHover: false,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: item.onTap,
                      borderRadius: BorderRadius.vertical(
                        top: index == 0 ? const Radius.circular(12) : Radius.zero,
                        bottom: isLast ? const Radius.circular(12) : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 22,
                              color: item.isDestructive
                                  ? AppTheme.errorColor
                                  : (isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: item.isDestructive
                                      ? AppTheme.errorColor
                                      : (isDark
                                          ? AppTheme.textPrimaryDark
                                          : AppTheme.textPrimaryLight),
                                ),
                              ),
                            ),
                            if (!item.isDestructive)
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: isDark
                                    ? AppTheme.textMutedDark
                                    : AppTheme.textMutedLight,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showSignOutConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.confirmSignOut(context: context);

    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _shareProfile(BuildContext context, String username) async {
    final profileUrl = 'https://toolkudu.app/u/$username';

    // On desktop or web, copy to clipboard
    if (Responsive.isDesktop(context)) {
      await Clipboard.setData(ClipboardData(text: profileUrl));
      if (context.mounted) {
        FunnySnackBar.showSuccess(
          context,
          customMessage: "Profile link copied! Share it like a prized power tool!",
        );
      }
    } else {
      // On mobile, use system share sheet
      await Share.share(
        'Check out my profile on ToolKUDU: $profileUrl',
        subject: 'ToolKUDU Profile',
      );
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });
}
