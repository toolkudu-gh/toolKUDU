import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import 'app_dialog.dart';

/// Shows the account drawer sliding from the right
void showAccountDrawer(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Account Drawer',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const AccountDrawer();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      return SlideTransition(
        position: slideAnimation,
        child: child,
      );
    },
  );
}

class AccountDrawer extends ConsumerWidget {
  const AccountDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth > 400 ? 320.0 : screenWidth * 0.85;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: drawerWidth,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.surfaceDark.withOpacity(0.95)
                    : AppTheme.surfaceLight.withOpacity(0.95),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
                border: Border(
                  left: BorderSide(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header with close button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          Text(
                            'Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48), // Balance for close button
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // User info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
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
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          (user.username.isNotEmpty
                                                  ? user.username[0]
                                                  : 'U')
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      (user?.username.isNotEmpty == true
                                              ? user!.username[0]
                                              : 'U')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Name
                          Text(
                            user?.displayNameOrUsername ?? 'User',
                            style: TextStyle(
                              fontSize: 20,
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
                              fontSize: 14,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Menu items
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            _DrawerMenuItem(
                              icon: Icons.person_outline,
                              label: 'View Profile',
                              onTap: () {
                                Navigator.of(context).pop();
                                context.go('/profile');
                              },
                            ),
                            _DrawerMenuItem(
                              icon: Icons.edit_outlined,
                              label: 'Edit Profile',
                              onTap: () {
                                Navigator.of(context).pop();
                                context.go('/profile/edit');
                              },
                            ),
                            _DrawerMenuItem(
                              icon: Icons.settings_outlined,
                              label: 'Settings',
                              onTap: () {
                                Navigator.of(context).pop();
                                context.go('/profile/settings');
                              },
                            ),

                            const Spacer(),

                            Divider(
                              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                            ),
                            const SizedBox(height: 8),

                            _DrawerMenuItem(
                              icon: Icons.logout,
                              label: 'Sign Out',
                              isDestructive: true,
                              onTap: () => _handleSignOut(context, ref),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.confirmSignOut(context: context);

    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).signOut();
      if (context.mounted) {
        Navigator.of(context).pop(); // Close drawer
        context.go('/login');
      }
    }
  }
}

class _DrawerMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_DrawerMenuItem> createState() => _DrawerMenuItemState();
}

class _DrawerMenuItemState extends State<_DrawerMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.isDestructive
        ? AppTheme.errorColor
        : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isDestructive
                    ? AppTheme.errorColor.withOpacity(0.1)
                    : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03)))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 22,
                color: color,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              if (!widget.isDestructive)
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
    );
  }
}
