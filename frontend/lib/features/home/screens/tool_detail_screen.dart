import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../providers/toolbox_provider.dart';

class ToolDetailScreen extends ConsumerWidget {
  final String toolId;

  const ToolDetailScreen({super.key, required this.toolId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolAsync = ref.watch(toolProvider(toolId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: toolAsync.when(
        data: (tool) {
          if (tool == null) {
            return EmptyState(
              icon: Icons.build_outlined,
              title: 'Tool not found',
              description: 'This tool may have been deleted',
            );
          }

          return CustomScrollView(
            slivers: [
              // Hero Image with App Bar
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight)
                          .withOpacity(0.9),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight)
                            .withOpacity(0.9),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                        onPressed: () {
                          // TODO: Edit tool
                        },
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: tool.images.isNotEmpty
                      ? PageView.builder(
                          itemCount: tool.images.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              tool.images[index].url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: isDark
                                    ? AppTheme.surfaceDark
                                    : AppTheme.backgroundLight,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 64,
                                  color: isDark
                                      ? AppTheme.textMutedDark
                                      : AppTheme.textMutedLight,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: isDark
                              ? AppTheme.surfaceDark
                              : AppTheme.backgroundLight,
                          child: Center(
                            child: Icon(
                              Icons.handyman_rounded,
                              size: 80,
                              color: isDark
                                  ? AppTheme.textMutedDark
                                  : AppTheme.textMutedLight,
                            ),
                          ),
                        ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tool.name,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppTheme.textPrimaryDark
                                        : AppTheme.textPrimaryLight,
                                  ),
                                ),
                                if (tool.brand != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    tool.brand!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark
                                          ? AppTheme.textSecondaryDark
                                          : AppTheme.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms),

                      const SizedBox(height: 16),

                      // Status Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AvailabilityBadge(isAvailable: tool.isAvailable),
                          if (tool.hasTracker)
                            StatusBadge(
                              label: 'GPS Tracked',
                              variant: StatusBadgeVariant.success,
                              icon: Icons.location_on_outlined,
                            ),
                        ],
                      ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                      const SizedBox(height: 24),

                      // Details Card
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        enableHover: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.textPrimaryDark
                                    : AppTheme.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow('Model', tool.model, isDark),
                            _buildDetailRow('Category', tool.category, isDark),
                            _buildDetailRow('Serial Number', tool.serialNumber, isDark),
                            if (tool.purchasePrice != null)
                              _buildDetailRow(
                                'Purchase Price',
                                '\$${tool.purchasePrice!.toStringAsFixed(2)}',
                                isDark,
                              ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 150.ms, duration: 300.ms).slideY(
                            begin: 0.1,
                            end: 0,
                            delay: 150.ms,
                            duration: 300.ms,
                            curve: Curves.easeOutCubic,
                          ),

                      // Description
                      if (tool.description != null && tool.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        AppCard(
                          padding: const EdgeInsets.all(20),
                          enableHover: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.textPrimaryDark
                                      : AppTheme.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tool.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(
                              begin: 0.1,
                              end: 0,
                              delay: 200.ms,
                              duration: 300.ms,
                              curve: Curves.easeOutCubic,
                            ),
                      ],

                      // Notes
                      if (tool.notes != null && tool.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        AppCard(
                          padding: const EdgeInsets.all(20),
                          enableHover: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.note_outlined,
                                    size: 18,
                                    color: AppTheme.warningColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Notes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppTheme.textPrimaryDark
                                          : AppTheme.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tool.notes!,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 250.ms, duration: 300.ms).slideY(
                              begin: 0.1,
                              end: 0,
                              delay: 250.ms,
                              duration: 300.ms,
                              curve: Curves.easeOutCubic,
                            ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => _buildLoadingState(isDark),
        error: (_, __) => EmptyState.error(
          title: 'Failed to load tool',
          description: 'Check your connection and try again',
          actionLabel: 'Retry',
          onAction: () => ref.refresh(toolProvider(toolId)),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, bool isDark) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.textMutedDark
                    : AppTheme.textMutedLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          LoadingSkeleton(
            width: double.infinity,
            height: 280,
            borderRadius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton.text(width: 200, height: 24),
                const SizedBox(height: 8),
                LoadingSkeleton.text(width: 120, height: 16),
                const SizedBox(height: 16),
                Row(
                  children: [
                    LoadingSkeleton(
                      width: 80,
                      height: 28,
                      borderRadius: AppTheme.radius2xl,
                    ),
                    const SizedBox(width: 8),
                    LoadingSkeleton(
                      width: 60,
                      height: 28,
                      borderRadius: AppTheme.radius2xl,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                CardSkeleton(height: 150, showImage: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
