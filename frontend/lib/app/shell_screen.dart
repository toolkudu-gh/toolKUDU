import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shared/theme/app_theme.dart';
import '../shared/widgets/account_drawer.dart';
import '../core/utils/responsive.dart';
import '../core/providers/auth_provider.dart';
import 'desktop_header.dart';

class ShellScreen extends ConsumerStatefulWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);
    final user = ref.watch(currentUserProvider);

    // Desktop layout with top header
    if (isDesktop) {
      return Scaffold(
        body: Column(
          children: [
            const DesktopHeader(),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    // Mobile/tablet layout with bottom navigation
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: Column(
        children: [
          // Mobile app bar with account icon
          _buildMobileAppBar(context, isDark, user),
          Expanded(child: widget.child),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight)
              .withOpacity(0.9),
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: selectedIndex == 0,
                      onTap: () => _onItemTapped(0, context),
                    ),
                    _NavItem(
                      icon: Icons.search_outlined,
                      selectedIcon: Icons.search_rounded,
                      label: 'Search',
                      isSelected: selectedIndex == 1,
                      onTap: () => _onItemTapped(1, context),
                    ),
                    _NavItem(
                      icon: Icons.people_outline_rounded,
                      selectedIcon: Icons.people_rounded,
                      label: 'Buddies',
                      isSelected: selectedIndex == 2,
                      onTap: () => _onItemTapped(2, context),
                    ),
                    _NavItem(
                      icon: Icons.swap_horiz_outlined,
                      selectedIcon: Icons.swap_horiz_rounded,
                      label: 'Share',
                      isSelected: selectedIndex == 3,
                      onTap: () => _onItemTapped(3, context),
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

  Widget _buildMobileAppBar(BuildContext context, bool isDark, dynamic user) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.glassDark : AppTheme.glassLight,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Logo/Title area - empty for now, screens have their own headers
                  const Spacer(),
                  // Account button
                  GestureDetector(
                    onTap: () => showAccountDrawer(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: user?.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user!.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    (user.username ?? 'U')[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                (user?.username ?? 'U')[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/buddies')) return 2;
    if (location.startsWith('/share')) return 3;
    // Profile is now accessible via account drawer, not main nav
    if (location.startsWith('/profile')) return -1;

    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/buddies');
        break;
      case 3:
        context.go('/share');
        break;
    }
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.getPrimaryColor(context);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSelected ? 16 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? primaryColor.withOpacity(isDark ? 0.2 : 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isSelected ? widget.selectedIcon : widget.icon,
                size: 22,
                color: widget.isSelected
                    ? primaryColor
                    : (isDark
                        ? AppTheme.textMutedDark
                        : AppTheme.textMutedLight),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: widget.isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassmorphicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const GlassmorphicAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  if (leading != null)
                    leading!
                  else if (showBackButton)
                    IconButton(
                      onPressed: onBackPressed ?? () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  if (titleWidget != null)
                    Expanded(child: titleWidget!)
                  else if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
