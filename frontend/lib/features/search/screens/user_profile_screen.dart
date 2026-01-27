import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/toolbox.dart';
import '../../../core/models/tool.dart';
import '../../../core/providers/lending_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../share/widgets/borrow_request_dialog.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;
  final bool borrowMode;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.borrowMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));
    final toolboxesAsync = ref.watch(userToolboxesProvider(userId));
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
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      borrowMode ? 'Select a Tool' : 'Profile',
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
              child: userAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => EmptyState.error(
                  title: 'Failed to load profile',
                  description: error.toString(),
                ),
                data: (user) => SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Card
                      AppCard(
                        padding: const EdgeInsets.all(24),
                        enableHover: false,
                        child: Column(
                          children: [
                            // Avatar
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
                              child: user.avatarUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        user.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Text(
                                          user.username[0].toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        user.username[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              user.displayNameOrUsername,
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
                              '@${user.username}',
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                              ),
                            ),

                            if (user.bio != null && user.bio!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                user.bio!,
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

                            // Stats
                            StatRow(
                              stats: [
                                StatItem(
                                  value: '${user.followersCount}',
                                  label: 'Followers',
                                ),
                                StatItem(
                                  value: '${user.followingCount}',
                                  label: 'Following',
                                ),
                              ],
                            ),

                            if (!borrowMode) ...[
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton(
                                      label: user.isFollowing == true ? 'Following' : 'Follow',
                                      icon: user.isFollowing == true
                                          ? Icons.check
                                          : Icons.person_add_outlined,
                                      variant: user.isFollowing == true
                                          ? AppButtonVariant.outline
                                          : AppButtonVariant.primary,
                                      onPressed: () {
                                        // TODO: Follow/Unfollow
                                      },
                                      fullWidth: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppButton(
                                      label: user.isBuddy == true ? 'Buddies' : 'Add Buddy',
                                      icon: Icons.people_outlined,
                                      variant: AppButtonVariant.outline,
                                      onPressed: () {
                                        // TODO: Add buddy
                                      },
                                      fullWidth: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

                      // Toolboxes Section Header
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 20,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            borrowMode ? 'Available Toolboxes' : 'Public Toolboxes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                      const SizedBox(height: 12),

                      // Toolboxes List
                      toolboxesAsync.when(
                        loading: () => Column(
                          children: List.generate(
                            2,
                            (index) => const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: CardSkeleton(height: 80, showImage: false),
                            ),
                          ),
                        ),
                        error: (error, _) => EmptyState.error(
                          title: 'Failed to load toolboxes',
                          description: error.toString(),
                        ),
                        data: (toolboxes) {
                          if (toolboxes.isEmpty) {
                            return EmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: 'No public toolboxes',
                              description: 'This user hasn\'t shared any toolboxes yet',
                              compact: true,
                            );
                          }
                          return Column(
                            children: toolboxes.asMap().entries.map((entry) {
                              return _buildToolboxTile(
                                context,
                                ref,
                                entry.value,
                                isDark,
                                entry.key,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolboxTile(
    BuildContext context,
    WidgetRef ref,
    Toolbox toolbox,
    bool isDark,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        enableHover: false,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: EdgeInsets.zero,
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            title: Text(
              toolbox.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
            subtitle: Text(
              '${toolbox.toolCount} tools',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryColor,
              ),
            ),
            children: [
              Divider(
                height: 1,
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              ),
              _buildToolsList(context, ref, toolbox.id, isDark),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 250 + index * 50),
          duration: 300.ms,
        );
  }

  Widget _buildToolsList(
    BuildContext context,
    WidgetRef ref,
    String toolboxId,
    bool isDark,
  ) {
    final toolsAsync = ref.watch(toolboxToolsProvider(toolboxId));

    return toolsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error: $error',
          style: TextStyle(color: AppTheme.errorColor),
        ),
      ),
      data: (tools) {
        if (tools.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No tools in this toolbox',
              style: TextStyle(
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
          );
        }
        return Column(
          children: tools.map((tool) => _buildToolTile(context, ref, tool, isDark)).toList(),
        );
      },
    );
  }

  Widget _buildToolTile(
    BuildContext context,
    WidgetRef ref,
    Tool tool,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tool.isAvailable
                  ? AppTheme.successLight
                  : (isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: tool.primaryImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Image.network(
                      tool.primaryImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.handyman_rounded,
                        size: 22,
                        color: tool.isAvailable
                            ? AppTheme.successColor
                            : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                      ),
                    ),
                  )
                : Icon(
                    Icons.handyman_rounded,
                    size: 22,
                    color: tool.isAvailable
                        ? AppTheme.successColor
                        : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
                ),
                if (tool.brand != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    tool.brand!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                StatusBadge(
                  label: tool.isAvailable ? 'Available' : 'Not Available',
                  variant: tool.isAvailable
                      ? StatusBadgeVariant.success
                      : StatusBadgeVariant.warning,
                  small: true,
                ),
              ],
            ),
          ),
          if (tool.isAvailable && borrowMode)
            AppButton(
              label: 'Borrow',
              size: AppButtonSize.sm,
              onPressed: () => _showBorrowDialog(context, ref, tool),
            ),
        ],
      ),
    );
  }

  Future<void> _showBorrowDialog(BuildContext context, WidgetRef ref, Tool tool) async {
    final result = await BorrowRequestDialog.show(
      context: context,
      tool: tool,
    );

    if (result != null) {
      final success = await ref.read(lendingStateProvider.notifier).createBorrowRequest(
            tool.id,
            message: result.isNotEmpty ? result : null,
          );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Borrow request sent!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          context.go('/share');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to send request. Please try again.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}
