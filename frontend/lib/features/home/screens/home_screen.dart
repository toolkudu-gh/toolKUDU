import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../providers/toolbox_provider.dart';
import '../widgets/toolbox_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolboxesAsync = ref.watch(toolboxesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: toolboxesAsync.when(
          data: (toolboxes) {
            if (toolboxes.isEmpty) {
              return _buildEmptyState(context);
            }

            // Calculate stats using toolCount from Toolbox model
            final totalTools = toolboxes.fold<int>(
                0, (sum, box) => sum + box.toolCount);

            return RefreshIndicator(
              onRefresh: () => ref.refresh(toolboxesProvider.future),
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? AppTheme.textSecondaryDark
                                          : AppTheme.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'My Toolboxes',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppTheme.textPrimaryDark
                                          : AppTheme.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              AppIconButton(
                                icon: Icons.notifications_outlined,
                                onPressed: () {
                                  // TODO: Navigate to notifications
                                },
                              ),
                            ],
                          ).animate().fadeIn(duration: 300.ms).slideY(
                                begin: -0.1,
                                end: 0,
                                duration: 300.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ],
                      ),
                    ),
                  ),

                  // Stats Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Icons.inventory_2_outlined,
                              value: toolboxes.length.toString(),
                              label: 'Toolboxes',
                              iconColor: AppTheme.primaryColor,
                            ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(
                                  begin: 0.2,
                                  end: 0,
                                  delay: 100.ms,
                                  duration: 300.ms,
                                  curve: Curves.easeOutCubic,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              icon: Icons.build_outlined,
                              value: totalTools.toString(),
                              label: 'Total Tools',
                              iconColor: AppTheme.successColor,
                            ).animate().fadeIn(delay: 150.ms, duration: 300.ms).slideY(
                                  begin: 0.2,
                                  end: 0,
                                  delay: 150.ms,
                                  duration: 300.ms,
                                  curve: Curves.easeOutCubic,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Section Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Toolboxes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                          Text(
                            '${toolboxes.length} items',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppTheme.textMutedDark
                                  : AppTheme.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Toolbox Grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final toolbox = toolboxes[index];
                          return ToolboxCard(
                            toolbox: toolbox,
                            onTap: () => context.go('/home/toolbox/${toolbox.id}'),
                          ).animate().fadeIn(
                                delay: Duration(milliseconds: 200 + (index * 50)),
                                duration: 300.ms,
                              ).slideY(
                                begin: 0.2,
                                end: 0,
                                delay: Duration(milliseconds: 200 + (index * 50)),
                                duration: 300.ms,
                                curve: Curves.easeOutCubic,
                              );
                        },
                        childCount: toolboxes.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(ref),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          onPressed: () => context.go('/home/add-toolbox'),
          icon: const Icon(Icons.add),
          label: const Text('Add Toolbox'),
        ).animate().scale(
              delay: 500.ms,
              duration: 300.ms,
              curve: Curves.easeOutBack,
            ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton.text(width: 100, height: 14),
          const SizedBox(height: 8),
          LoadingSkeleton.text(width: 180, height: 28),
          const SizedBox(height: 24),
          Row(
            children: List.generate(
              2,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 1 ? 12 : 0),
                  child: const StatCardSkeleton(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GridSkeleton(
            columns: 3,
            itemCount: 6,
            childAspectRatio: 0.95,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'No Toolboxes Yet',
      description: 'Create your first toolbox to start organizing your tools',
      actionLabel: 'Create Toolbox',
      onAction: () => context.go('/home/add-toolbox'),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildErrorState(WidgetRef ref) {
    return EmptyState.error(
      title: 'Failed to load toolboxes',
      description: 'Check your connection and try again',
      actionLabel: 'Retry',
      onAction: () => ref.refresh(toolboxesProvider),
    ).animate().fadeIn(duration: 400.ms);
  }
}
