import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/funny_snackbar.dart';
import '../../search/widgets/user_search_dialog.dart';

class BuddiesScreen extends ConsumerWidget {
  const BuddiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header - now main tab style
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tool Buddies',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                    AppIconButton(
                      icon: Icons.person_add_outlined,
                      tooltip: 'Find Buddies',
                      onPressed: () => UserSearchDialog.show(context),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 16),

              // Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    ),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd - 2),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(4),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'My Buddies'),
                      Tab(text: 'Requests'),
                      Tab(text: 'Sent'),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

              const SizedBox(height: 16),

              // Tab Content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildBuddiesTab(context, isDark),
                    _buildFollowersTab(context, isDark),
                    _buildFollowingTab(context, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuddiesTab(BuildContext context, bool isDark) {
    // TODO: Fetch actual buddies
    final buddies = List.generate(3, (index) => {
      'id': 'b$index',
      'name': 'Buddy ${index + 1}',
      'username': 'buddy${index + 1}',
    });

    if (buddies.isEmpty) {
      return EmptyState.noBuddies(
        actionLabel: 'Find Tool Buddies',
        onAction: () => UserSearchDialog.show(context),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: buddies.length,
      itemBuilder: (context, index) {
        final buddy = buddies[index];
        return _buildUserCard(
          context,
          isDark,
          name: buddy['name']!,
          username: buddy['username']!,
          index: index,
          trailing: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            onSelected: (value) {
              if (value == 'view') {
                context.go('/search/user/${buddy['id']}');
              } else if (value == 'borrow') {
                context.go('/search/user/${buddy['id']}?mode=borrow');
              } else if (value == 'remove') {
                // TODO: Remove buddy
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outlined,
                      size: 20,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                    const SizedBox(width: 12),
                    const Text('View Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'borrow',
                child: Row(
                  children: [
                    Icon(
                      Icons.handshake_outlined,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Request Tool',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_remove_outlined,
                      size: 20,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Remove Buddy',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFollowersTab(BuildContext context, bool isDark) {
    final followers = List.generate(5, (index) => {
      'id': 'f$index',
      'name': 'User ${index + 1}',
      'username': 'user${index + 1}',
      'isFollowing': index % 2 == 0,
    });

    if (followers.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No buddy requests',
        description: 'When someone wants to be your Tool Buddy, they\'ll appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: followers.length,
      itemBuilder: (context, index) {
        final follower = followers[index];
        final isFollowing = follower['isFollowing'] as bool;

        return _buildUserCard(
          context,
          isDark,
          name: follower['name']! as String,
          username: follower['username']! as String,
          index: index,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: 'Accept',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.sm,
                onPressed: () {
                  // TODO: Accept buddy request
                  FunnySnackBar.buddyAdded(context);
                },
              ),
              const SizedBox(width: 8),
              AppButton(
                label: 'Decline',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                onPressed: () {
                  // TODO: Decline buddy request
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFollowingTab(BuildContext context, bool isDark) {
    final following = List.generate(4, (index) => {
      'id': 'u$index',
      'name': 'User ${index + 1}',
      'username': 'user${index + 1}',
    });

    if (following.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'No sent requests',
        description: 'Your pending buddy requests will appear here',
        actionLabel: 'Find Tool Buddies',
        onAction: () => UserSearchDialog.show(context),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: following.length,
      itemBuilder: (context, index) {
        final user = following[index];
        return _buildUserCard(
          context,
          isDark,
          name: user['name']! as String,
          username: user['username']! as String,
          index: index,
          trailing: AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outline,
            size: AppButtonSize.sm,
            onPressed: () {
              // TODO: Cancel buddy request
            },
          ),
        );
      },
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    bool isDark, {
    required String name,
    required String username,
    required int index,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () => context.go('/search/user/$username'),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                  Text(
                    '@$username',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 150 + index * 50),
          duration: 300.ms,
        ).slideX(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: 150 + index * 50),
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
