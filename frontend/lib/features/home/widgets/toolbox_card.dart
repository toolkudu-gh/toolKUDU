import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/toolbox.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';

class ToolboxCard extends StatefulWidget {
  final Toolbox toolbox;
  final VoidCallback? onTap;
  final int? animationIndex;

  const ToolboxCard({
    super.key,
    required this.toolbox,
    this.onTap,
    this.animationIndex,
  });

  @override
  State<ToolboxCard> createState() => _ToolboxCardState();
}

class _ToolboxCardState extends State<ToolboxCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toolboxColor = _parseColor(widget.toolbox.color);

    Widget card = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
        transformAlignment: Alignment.center,
        child: AppCard(
          onTap: widget.onTap,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Icon + Visibility badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: toolboxColor.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: toolboxColor.withOpacity(_isHovered ? 0.4 : 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _getIcon(widget.toolbox.icon),
                      color: toolboxColor,
                      size: 18,
                    ),
                  ),
                  _buildVisibilityChip(isDark),
                ],
              ),

              const SizedBox(height: 10),

              // Name
              Text(
                widget.toolbox.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Description (if exists)
              if (widget.toolbox.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.toolbox.description!,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const Spacer(),

              // Tool count
              Row(
                children: [
                  Icon(
                    Icons.handyman_rounded,
                    size: 12,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${widget.toolbox.toolCount} tools',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Apply staggered animation if index is provided
    if (widget.animationIndex != null) {
      final delay = Duration(milliseconds: 100 + widget.animationIndex! * 50);
      card = card
          .animate()
          .fadeIn(delay: delay, duration: 300.ms)
          .slideY(
            begin: 0.1,
            end: 0,
            delay: delay,
            duration: 300.ms,
            curve: Curves.easeOutCubic,
          );
    }

    return card;
  }

  Widget _buildVisibilityChip(bool isDark) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (widget.toolbox.visibility) {
      case ToolboxVisibility.private:
        icon = Icons.lock_outlined;
        color = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
        bgColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
        break;
      case ToolboxVisibility.buddies:
        icon = Icons.people_outlined;
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFF3B82F6).withOpacity(isDark ? 0.2 : 0.1);
        break;
      case ToolboxVisibility.public:
        icon = Icons.public;
        color = AppTheme.successColor;
        bgColor = AppTheme.successLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return AppTheme.primaryColor;
    }
    try {
      return Color(int.parse(colorHex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'nature':
        return Icons.nature_outlined;
      case 'car':
        return Icons.directions_car_outlined;
      case 'build':
        return Icons.build_outlined;
      case 'electrical':
        return Icons.electrical_services_outlined;
      case 'plumbing':
        return Icons.plumbing_outlined;
      case 'paint':
        return Icons.format_paint_outlined;
      case 'hardware':
        return Icons.hardware_outlined;
      case 'garden':
        return Icons.grass_outlined;
      case 'measure':
        return Icons.straighten_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}
