import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryPills extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onSelected;
  final bool showAll;
  final String allLabel;
  final ScrollController? scrollController;

  const CategoryPills({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.onSelected,
    this.showAll = true,
    this.allLabel = 'All',
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCategories = showAll ? [allLabel, ...categories] : categories;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isSelected = showAll
              ? (selectedCategory == null && category == allLabel) ||
                  selectedCategory == category
              : selectedCategory == category;

          return CategoryPill(
            label: category,
            isSelected: isSelected,
            onTap: () {
              if (showAll && category == allLabel) {
                onSelected?.call(null);
              } else {
                onSelected?.call(category);
              }
            },
          );
        },
      ),
    );
  }
}

class CategoryPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? selectedColor;

  const CategoryPill({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.selectedColor,
  });

  @override
  State<CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<CategoryPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = widget.selectedColor ?? AppTheme.primaryColor;

    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    if (widget.isSelected) {
      backgroundColor = selectedColor;
      foregroundColor = Colors.white;
      borderColor = selectedColor;
    } else if (_isHovered) {
      backgroundColor = isDark
          ? AppTheme.borderDark
          : AppTheme.backgroundLight;
      foregroundColor = isDark
          ? AppTheme.textPrimaryDark
          : AppTheme.textPrimaryLight;
      borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    } else {
      backgroundColor = Colors.transparent;
      foregroundColor = isDark
          ? AppTheme.textSecondaryDark
          : AppTheme.textSecondaryLight;
      borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: widget.icon != null ? 12 : 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radius2xl),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: foregroundColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterChips extends StatelessWidget {
  final List<FilterChipData> chips;
  final EdgeInsetsGeometry? padding;
  final WrapAlignment alignment;

  const FilterChips({
    super.key,
    required this.chips,
    this.padding,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: alignment,
        children: chips.map((chip) {
          return CategoryPill(
            label: chip.label,
            isSelected: chip.isSelected,
            onTap: chip.onTap,
            icon: chip.icon,
            selectedColor: chip.color,
          );
        }).toList(),
      ),
    );
  }
}

class FilterChipData {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  const FilterChipData({
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.color,
  });
}
