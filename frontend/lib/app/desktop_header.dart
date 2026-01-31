import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../shared/theme/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../core/utils/feature_flags.dart';

/// Desktop header navigation bar for screens >=900px
class DesktopHeader extends ConsumerWidget implements PreferredSizeWidget {
  const DesktopHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: preferredSize.height,
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.glassDark
                : AppTheme.glassLight,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Logo
                  _buildLogo(context, isDark),
                  const SizedBox(width: 48),

                  // Navigation Links
                  Expanded(
                    child: Row(
                      children: [
                        _NavLink(
                          label: 'Home',
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home_rounded,
                          isSelected: currentLocation.startsWith('/home'),
                          onTap: () => context.go('/home'),
                        ),
                        const SizedBox(width: 8),
                        _NavLink(
                          label: 'Search',
                          icon: Icons.search_outlined,
                          selectedIcon: Icons.search_rounded,
                          isSelected: currentLocation.startsWith('/search'),
                          onTap: () => context.go('/search'),
                        ),
                        const SizedBox(width: 8),
                        _NavLink(
                          label: 'Buddies',
                          icon: Icons.people_outline_rounded,
                          selectedIcon: Icons.people_rounded,
                          isSelected: currentLocation.startsWith('/buddies'),
                          onTap: () => context.go('/buddies'),
                        ),
                        const SizedBox(width: 8),
                        _NavLink(
                          label: 'Share',
                          icon: Icons.swap_horiz_outlined,
                          selectedIcon: Icons.swap_horiz_rounded,
                          isSelected: currentLocation.startsWith('/share'),
                          onTap: () => context.go('/share'),
                        ),
                        // Find tab hidden based on feature flag
                        if (FeatureFlags.enableFindTool) ...[
                          const SizedBox(width: 8),
                          _NavLink(
                            label: 'Find',
                            icon: Icons.location_on_outlined,
                            selectedIcon: Icons.location_on_rounded,
                            isSelected: currentLocation.startsWith('/find'),
                            onTap: () => context.go('/find'),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Right side: Notifications + Profile
                  Row(
                    children: [
                      // Notifications
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                        onPressed: () {
                          // TODO: Show notifications
                        },
                      ),
                      const SizedBox(width: 8),

                      // Profile dropdown
                      _ProfileDropdown(
                        user: user,
                        isDark: isDark,
                        isSelected: currentLocation.startsWith('/profile'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => context.go('/home'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SvgPicture.asset(
                'assets/images/toolkudu_logo.svg',
                height: 32,
                width: 32,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'ToolKUDU',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavLink({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.getPrimaryColor(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? primaryColor.withOpacity(isDark ? 0.15 : 0.1)
                : (_isHovered
                    ? (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03))
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isSelected ? widget.selectedIcon : widget.icon,
                size: 20,
                color: widget.isSelected
                    ? primaryColor
                    : (isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isSelected
                      ? primaryColor
                      : (isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDropdown extends StatefulWidget {
  final dynamic user;
  final bool isDark;
  final bool isSelected;

  const _ProfileDropdown({
    required this.user,
    required this.isDark,
    required this.isSelected,
  });

  @override
  State<_ProfileDropdown> createState() => _ProfileDropdownState();
}

class _ProfileDropdownState extends State<_ProfileDropdown> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.getPrimaryColor(context);

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      color: widget.isDark ? AppTheme.surfaceElevatedDark : AppTheme.surfaceLight,
      onSelected: (value) {
        switch (value) {
          case 'profile':
            context.go('/profile');
            break;
          case 'edit':
            context.go('/profile/edit');
            break;
          case 'settings':
            context.go('/profile/settings');
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: widget.isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
              const SizedBox(width: 12),
              const Text('View Profile'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 20,
                color: widget.isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
              const SizedBox(width: 12),
              const Text('Edit Profile'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 20,
                color: widget.isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
              const SizedBox(width: 12),
              const Text('Settings'),
            ],
          ),
        ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? primaryColor.withOpacity(widget.isDark ? 0.15 : 0.1)
                : (_isHovered
                    ? (widget.isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03))
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: widget.isSelected
                  ? primaryColor.withOpacity(0.3)
                  : (widget.isDark
                      ? AppTheme.borderDark
                      : AppTheme.borderLight),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: primaryColor.withOpacity(widget.isDark ? 0.2 : 0.1),
                backgroundImage: widget.user?.avatarUrl != null
                    ? NetworkImage(widget.user!.avatarUrl!)
                    : null,
                child: widget.user?.avatarUrl == null
                    ? Text(
                        (widget.user?.username ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                widget.user?.displayNameOrUsername ?? 'Profile',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: widget.isDark
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
