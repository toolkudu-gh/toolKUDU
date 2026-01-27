import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/app_dialog.dart';

class FindToolScreen extends ConsumerWidget {
  const FindToolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // TODO: Fetch tracked tools from API
    final trackedTools = [
      {'id': 't1', 'name': 'Cordless Drill', 'lastSeen': '2 minutes ago', 'hasLocation': true, 'battery': 85},
      {'id': 't2', 'name': 'Circular Saw', 'lastSeen': '1 hour ago', 'hasLocation': true, 'battery': 62},
      {'id': 't3', 'name': 'Impact Driver', 'lastSeen': 'Never', 'hasLocation': false, 'battery': null},
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Find My Tools',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.map_outlined,
                    onPressed: () {
                      // TODO: Show map view
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 8),

            // Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                enableHover: false,
                backgroundColor: AppTheme.primaryColor.withOpacity(isDark ? 0.15 : 0.08),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${trackedTools.where((t) => t['hasLocation'] == true).length} of ${trackedTools.length} tools tracked',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'All tracked tools are within range',
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
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 20),

            // Content
            Expanded(
              child: trackedTools.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: trackedTools.length,
                      itemBuilder: (context, index) {
                        final tool = trackedTools[index];
                        return _buildTrackerCard(context, tool, isDark, index);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddTrackerDialog(context, isDark),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Add Tracker'),
        ).animate().scale(
              delay: 400.ms,
              duration: 300.ms,
              curve: Curves.easeOutBack,
            ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.location_off_outlined,
      title: 'No Tracked Tools',
      description: 'Add a GPS tracker to your tools to find them anytime',
      actionLabel: 'Add Tracker',
      onAction: () => _showAddTrackerDialog(context, Theme.of(context).brightness == Brightness.dark),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTrackerCard(
    BuildContext context,
    Map<String, dynamic> tool,
    bool isDark,
    int index,
  ) {
    final hasLocation = tool['hasLocation'] as bool;
    final battery = tool['battery'] as int?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        onTap: hasLocation
            ? () {
                // Show tool location details
              }
            : null,
        child: Row(
          children: [
            // Location icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: hasLocation
                    ? AppTheme.successLight
                    : (isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: hasLocation
                      ? AppTheme.successColor.withOpacity(0.3)
                      : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
              ),
              child: Icon(
                hasLocation ? Icons.location_on : Icons.location_off,
                color: hasLocation
                    ? AppTheme.successColor
                    : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Tool info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool['name'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDark
                            ? AppTheme.textMutedDark
                            : AppTheme.textMutedLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Last seen: ${tool['lastSeen']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  if (battery != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          battery > 20 ? Icons.battery_std : Icons.battery_alert,
                          size: 14,
                          color: battery > 20
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$battery%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: battery > 20
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Navigate button
            if (hasLocation)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.navigation_outlined,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  onPressed: () {
                    // TODO: Navigate to tool
                  },
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 200 + index * 50),
          duration: 300.ms,
        ).slideX(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: 200 + index * 50),
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }

  void _showAddTrackerDialog(BuildContext context, bool isDark) {
    AppBottomSheet.show(
      context: context,
      title: 'Add GPS Tracker',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTrackerTypeOption(
            context,
            icon: Icons.apple,
            title: 'Apple AirTag',
            subtitle: 'Find My network',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              context.go('/find/add-tracker/airtag');
            },
          ),
          const SizedBox(height: 8),
          _buildTrackerTypeOption(
            context,
            icon: Icons.bluetooth,
            title: 'Tile Tracker',
            subtitle: 'Bluetooth tracker',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              context.go('/find/add-tracker/tile');
            },
          ),
          const SizedBox(height: 8),
          _buildTrackerTypeOption(
            context,
            icon: Icons.cell_tower,
            title: 'GPS Cellular',
            subtitle: 'Cellular network',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              context.go('/find/add-tracker/gps_cellular');
            },
          ),
          const SizedBox(height: 8),
          _buildTrackerTypeOption(
            context,
            icon: Icons.satellite_alt,
            title: 'GPS Satellite',
            subtitle: 'Satellite tracking',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              context.go('/find/add-tracker/gps_satellite');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerTypeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  subtitle,
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
          Icon(
            Icons.chevron_right_rounded,
            color: isDark
                ? AppTheme.textMutedDark
                : AppTheme.textMutedLight,
          ),
        ],
      ),
    );
  }
}
