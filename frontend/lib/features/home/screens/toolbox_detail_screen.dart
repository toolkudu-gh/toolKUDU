import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../core/models/tool.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/funny_messages.dart';
import '../providers/toolbox_provider.dart';

class ToolboxDetailScreen extends ConsumerWidget {
  final String toolboxId;

  const ToolboxDetailScreen({super.key, required this.toolboxId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolboxAsync = ref.watch(toolboxProvider(toolboxId));
    final toolsAsync = ref.watch(toolsInToolboxProvider(toolboxId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(context, ref, toolboxAsync, toolsAsync, isDark)
            : _buildMobileLayout(context, ref, toolboxAsync, toolsAsync, isDark),
      ),
      // Mobile only: Show FAB
      floatingActionButton: !isDesktop
          ? Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: FloatingActionButton.extended(
                onPressed: () => context.go('/home/toolbox/$toolboxId/add-tool'),
                icon: const Icon(Icons.add),
                label: const Text('Add Tool'),
              ).animate().scale(
                    delay: 400.ms,
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> toolboxAsync,
    AsyncValue<List<Tool>> toolsAsync,
    bool isDark,
  ) {
    return ResponsiveContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Toolbox info panel
          SizedBox(
            width: 320,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title
                  Row(
                    children: [
                      AppIconButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => context.go('/home'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: toolboxAsync.when(
                          data: (toolbox) => Text(
                            toolbox?.name ?? 'Toolbox',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                          loading: () => LoadingSkeleton.text(width: 150, height: 24),
                          error: (_, __) => const Text('Toolbox'),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 24),

                  // Toolbox info card
                  toolboxAsync.when(
                    data: (toolbox) {
                      if (toolbox == null) return const SizedBox.shrink();
                      return _buildToolboxInfoCard(context, toolbox, isDark);
                    },
                    loading: () => const CardSkeleton(height: 120, showImage: false),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  AppButton(
                    label: 'Add Tool',
                    icon: Icons.add,
                    fullWidth: true,
                    onPressed: () => context.go('/home/toolbox/$toolboxId/add-tool'),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Edit Toolbox',
                    icon: Icons.edit_outlined,
                    variant: AppButtonVariant.outline,
                    fullWidth: true,
                    onPressed: () {
                      // TODO: Edit toolbox
                    },
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Manage Permissions',
                    icon: Icons.lock_outlined,
                    variant: AppButtonVariant.outline,
                    fullWidth: true,
                    onPressed: () {
                      // TODO: Manage permissions
                    },
                  ),
                  const SizedBox(height: 24),
                  Divider(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Delete Toolbox',
                    icon: Icons.delete_outlined,
                    variant: AppButtonVariant.destructive,
                    fullWidth: true,
                    onPressed: () => _showDeleteConfirmation(context),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 32),

          // Divider
          Container(
            width: 1,
            height: double.infinity,
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),

          const SizedBox(width: 32),

          // Right side - Tools list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tools header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tools',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                      toolsAsync.whenData((tools) => Text(
                        '${tools.length} items',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textMutedLight,
                        ),
                      )).value ?? const SizedBox.shrink(),
                    ],
                  ),
                ),

                // Tools list
                Expanded(
                  child: toolsAsync.when(
                    data: (tools) {
                      if (tools.isEmpty) {
                        return _buildEmptyState(context);
                      }
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 100,
                        ),
                        itemCount: tools.length,
                        itemBuilder: (context, index) {
                          final tool = tools[index];
                          return _buildToolCard(context, tool, isDark, index);
                        },
                      );
                    },
                    loading: () => ListView.builder(
                      itemCount: 4,
                      itemBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: CardSkeleton(height: 80, showImage: false),
                      ),
                    ),
                    error: (_, __) => EmptyState.error(
                      title: 'Failed to load tools',
                      description: FunnyMessages.networkError,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> toolboxAsync,
    AsyncValue<List<Tool>> toolsAsync,
    bool isDark,
  ) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              AppIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: toolboxAsync.when(
                  data: (toolbox) => Text(
                    toolbox?.name ?? 'Toolbox',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                  loading: () => LoadingSkeleton.text(width: 120, height: 20),
                  error: (_, __) => Text(
                    'Toolbox',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                ),
              ),
              AppIconButton(
                icon: Icons.edit_outlined,
                onPressed: () {
                  // TODO: Edit toolbox
                },
              ),
              PopupMenuButton<String>(
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
                  if (value == 'permissions') {
                    // TODO: Manage permissions
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'permissions',
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outlined,
                          size: 20,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                        const SizedBox(width: 12),
                        const Text('Permissions'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outlined,
                          size: 20,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),

        // Toolbox info card
        toolboxAsync.when(
          data: (toolbox) {
            if (toolbox == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.all(20),
              child: _buildToolboxInfoCard(context, toolbox, isDark),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: CardSkeleton(height: 80, showImage: false),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Tools list
        Expanded(
          child: toolsAsync.when(
            data: (tools) {
              if (tools.isEmpty) {
                return _buildEmptyState(context);
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: tools.length,
                itemBuilder: (context, index) {
                  final tool = tools[index];
                  return _buildToolCard(context, tool, isDark, index);
                },
              );
            },
            loading: () => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: CardSkeleton(height: 80, showImage: false),
              ),
            ),
            error: (_, __) => EmptyState.error(
              title: 'Failed to load tools',
              description: FunnyMessages.networkError,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolboxInfoCard(BuildContext context, dynamic toolbox, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      enableHover: false,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(int.parse(
                toolbox.color?.replaceFirst('#', '0xFF') ?? '0xFF6B8E7B',
              )).withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(
              _getToolboxIcon(toolbox.icon),
              size: 24,
              color: Color(int.parse(
                toolbox.color?.replaceFirst('#', '0xFF') ?? '0xFF6B8E7B',
              )),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (toolbox.description != null) ...[
                  Text(
                    toolbox.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getToolboxIcon(String? iconName) {
    switch (iconName) {
      case 'build':
        return Icons.build_outlined;
      case 'hardware':
        return Icons.hardware_outlined;
      case 'electrical':
        return Icons.electrical_services_outlined;
      case 'plumbing':
        return Icons.plumbing_outlined;
      case 'garden':
        return Icons.grass_outlined;
      case 'paint':
        return Icons.format_paint_outlined;
      case 'measure':
        return Icons.straighten_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.handyman_outlined,
      title: 'No Tools Yet',
      description: FunnyMessages.noTools,
      actionLabel: 'Add First Tool',
      onAction: () => context.go('/home/toolbox/$toolboxId/add-tool'),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildToolCard(BuildContext context, Tool tool, bool isDark, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        onTap: () => context.go('/home/toolbox/$toolboxId/tool/${tool.id}'),
        child: Row(
          children: [
            // Tool image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.backgroundDark
                    : AppTheme.backgroundLight,
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
                          size: 28,
                          color: isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textMutedLight,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.handyman_rounded,
                      size: 28,
                      color: isDark
                          ? AppTheme.textMutedDark
                          : AppTheme.textMutedLight,
                    ),
            ),
            const SizedBox(width: 14),

            // Tool info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tool.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                        ),
                      ),
                      if (tool.hasTracker)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppTheme.getSuccessColor(context),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [tool.brand, tool.category].where((s) => s != null).join(' • '),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                  if (!tool.isAvailable) ...[
                    const SizedBox(height: 8),
                    StatusBadge(
                      label: 'Lent Out',
                      variant: StatusBadgeVariant.warning,
                      small: true,
                    ),
                  ],
                ],
              ),
            ),

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

  void _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Delete Toolbox?',
      description: FunnyMessages.deleteToolbox,
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      // TODO: Delete and navigate back
      context.go('/home');
    }
  }
}
