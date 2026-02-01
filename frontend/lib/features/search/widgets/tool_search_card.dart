import 'package:flutter/material.dart';

import '../../../core/models/tool_search_result.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_badge.dart';

/// Card widget for displaying tool search results
/// Shows buddy highlight with accent border and "Buddy" chip
class ToolSearchCard extends StatelessWidget {
  final ToolSearchResult tool;
  final VoidCallback? onTap;

  const ToolSearchCard({
    super.key,
    required this.tool,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: tool.isBuddy
                ? Border(
                    left: BorderSide(
                      color: AppTheme.accentColor,
                      width: 4,
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tool image
                _buildToolImage(isDark),
                const SizedBox(width: 14),

                // Tool info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tool name
                      Text(
                        tool.toolName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Brand/Model
                      if (tool.brandAndModel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          tool.brandAndModel!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Owner info row
                      Row(
                        children: [
                          // Owner avatar
                          CircleAvatar(
                            radius: 10,
                            backgroundColor:
                                AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                            backgroundImage: tool.ownerAvatarUrl != null
                                ? NetworkImage(tool.ownerAvatarUrl!)
                                : null,
                            child: tool.ownerAvatarUrl == null
                                ? Text(
                                    tool.ownerUsername[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),

                          // Owner name
                          Expanded(
                            child: Text(
                              '@${tool.ownerUsername}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.textMutedDark
                                    : AppTheme.textMutedLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Badges row
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // Buddy badge
                          if (tool.isBuddy)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                                border: Border.all(
                                  color: AppTheme.accentColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_rounded,
                                    size: 12,
                                    color: AppTheme.accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Buddy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Availability badge
                          StatusBadge(
                            label: tool.isAvailable ? 'Available' : 'Unavailable',
                            variant: tool.isAvailable
                                ? StatusBadgeVariant.success
                                : StatusBadgeVariant.warning,
                            small: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Distance badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.surfaceElevatedDark
                        : AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: isDark
                            ? AppTheme.textMutedDark
                            : AppTheme.textMutedLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tool.formattedDistance,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }

  Widget _buildToolImage(bool isDark) {
    return Container(
      width: 60,
      height: 60,
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
                errorBuilder: (_, __, ___) => _buildPlaceholderIcon(isDark),
              ),
            )
          : _buildPlaceholderIcon(isDark),
    );
  }

  Widget _buildPlaceholderIcon(bool isDark) {
    return Center(
      child: Icon(
        Icons.handyman_rounded,
        size: 28,
        color: tool.isAvailable
            ? AppTheme.successColor
            : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
      ),
    );
  }
}

/// Location indicator widget showing search area
class LocationIndicator extends StatelessWidget {
  final String? zipcode;
  final String? locationName;
  final VoidCallback? onTap;

  const LocationIndicator({
    super.key,
    this.zipcode,
    this.locationName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayText = locationName ?? (zipcode != null ? 'zipcode $zipcode' : 'your location');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Searching within 100 mi of $displayText',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.edit_outlined,
                size: 14,
                color: AppTheme.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Category filter chip
class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight),
          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
