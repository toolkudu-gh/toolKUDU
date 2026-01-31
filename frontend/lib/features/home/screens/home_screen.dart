import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/funny_messages.dart';
import '../providers/toolbox_provider.dart';
import '../widgets/toolbox_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolboxesAsync = ref.watch(toolboxesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);

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
              color: AppTheme.getPrimaryColor(context),
              child: CustomScrollView(
                slivers: [
                  // Header with Add Button
                  SliverToBoxAdapter(
                    child: ResponsiveContainer(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 0 : 20,
                          isDesktop ? 24 : 16,
                          isDesktop ? 0 : 20,
                          0
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
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
                                          fontSize: isDesktop ? 32 : 28,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppTheme.textPrimaryDark
                                              : AppTheme.textPrimaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Desktop: Show Add button inline
                                if (isDesktop)
                                  AppButton(
                                    label: 'Add Toolbox',
                                    icon: Icons.add,
                                    onPressed: () => context.go('/home/add-toolbox'),
                                  )
                                else
                                  AppIconButton(
                                    icon: Icons.notifications_outlined,
                                    onPressed: () {
                                      // TODO: Navigate to notifications
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideY(
                          begin: -0.1,
                          end: 0,
                          duration: 300.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ),

                  // Stats Row
                  SliverToBoxAdapter(
                    child: ResponsiveContainer(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 0 : 20,
                          24,
                          isDesktop ? 0 : 20,
                          0
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                icon: Icons.inventory_2_outlined,
                                value: toolboxes.length.toString(),
                                label: 'Toolboxes',
                                iconColor: AppTheme.getPrimaryColor(context),
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
                                iconColor: AppTheme.getSuccessColor(context),
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
                  ),

                  // Section Header
                  SliverToBoxAdapter(
                    child: ResponsiveContainer(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 0 : 20,
                          24,
                          isDesktop ? 0 : 20,
                          12
                        ),
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
                  ),

                  // Toolbox Grid - Responsive columns (centered like other cards)
                  SliverToBoxAdapter(
                    child: ResponsiveContainer(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 0 : 20,
                          0,
                          isDesktop ? 0 : 20,
                          isDesktop ? 40 : 100,
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: isDesktop ? 220 : 180,
                            mainAxisSpacing: isDesktop ? 16 : 12,
                            crossAxisSpacing: isDesktop ? 16 : 12,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: toolboxes.length,
                          itemBuilder: (context, index) {
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
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => _buildLoadingState(context),
          error: (error, stack) => _buildErrorState(ref),
        ),
      ),
      // Mobile only: Show FAB with Add button
      floatingActionButton: !isDesktop
          ? Padding(
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
            )
          : null,
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32 : 20),
      child: ResponsiveContainer(
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
              columns: isDesktop ? 4 : 3,
              itemCount: isDesktop ? 8 : 6,
              childAspectRatio: 0.95,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'No Toolboxes Yet',
      description: FunnyMessages.noToolboxes,
      actionLabel: 'Create Toolbox',
      onAction: () => context.go('/home/add-toolbox'),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildErrorState(WidgetRef ref) {
    return EmptyState.error(
      title: 'Failed to load toolboxes',
      description: FunnyMessages.networkError,
      actionLabel: 'Retry',
      onAction: () => ref.refresh(toolboxesProvider),
    ).animate().fadeIn(duration: 400.ms);
  }
}
