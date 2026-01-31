import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/toolbox.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/funny_snackbar.dart';

class AddToolboxScreen extends ConsumerStatefulWidget {
  const AddToolboxScreen({super.key});

  @override
  ConsumerState<AddToolboxScreen> createState() => _AddToolboxScreenState();
}

class _AddToolboxScreenState extends ConsumerState<AddToolboxScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  ToolboxVisibility _visibility = ToolboxVisibility.private;
  String _selectedIcon = 'inventory';
  String _selectedColor = '#6B8E7B';
  String? _nameError;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _icons = [
    {'name': 'inventory', 'icon': Icons.inventory_2_outlined},
    {'name': 'work', 'icon': Icons.work_outlined},
    {'name': 'home', 'icon': Icons.home_outlined},
    {'name': 'build', 'icon': Icons.build_outlined},
    {'name': 'electrical', 'icon': Icons.electrical_services_outlined},
    {'name': 'plumbing', 'icon': Icons.plumbing_outlined},
    {'name': 'paint', 'icon': Icons.format_paint_outlined},
    {'name': 'garden', 'icon': Icons.grass_outlined},
  ];

  final List<String> _colors = [
    '#6B8E7B', // Sage green (primary)
    '#3B82F6', // Blue
    '#8B5CF6', // Purple
    '#10B981', // Emerald
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#EC4899', // Pink
    '#78716C', // Stone
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    setState(() => _nameError = null);

    if (_nameController.text.isEmpty) {
      setState(() => _nameError = 'Please enter a name');
      return false;
    }
    return true;
  }

  Future<void> _handleSave() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    // TODO: Call API to create toolbox
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      FunnySnackBar.toolboxCreated(context);
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColorValue = Color(int.parse(_selectedColor.replaceFirst('#', 'FF'), radix: 16));

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
                    icon: Icons.close,
                    onPressed: () => context.go('/home'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'New Toolbox',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  AppButton(
                    label: 'Create',
                    onPressed: _isLoading ? null : _handleSave,
                    isLoading: _isLoading,
                    size: AppButtonSize.sm,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Preview Card
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      enableHover: false,
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: selectedColorValue.withOpacity(isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(
                                color: selectedColorValue.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _icons.firstWhere((i) => i['name'] == _selectedIcon)['icon'] as IconData,
                              size: 30,
                              color: selectedColorValue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isEmpty
                                      ? 'Toolbox Name'
                                      : _nameController.text,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _nameController.text.isEmpty
                                        ? (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight)
                                        : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      _getVisibilityIcon(),
                                      size: 14,
                                      color: isDark
                                          ? AppTheme.textSecondaryDark
                                          : AppTheme.textSecondaryLight,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getVisibilityLabel(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppTheme.textSecondaryDark
                                            : AppTheme.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                    const SizedBox(height: 24),

                    // Name & Description
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      enableHover: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppInput(
                            controller: _nameController,
                            label: 'Name',
                            hint: 'e.g., Work Tools, Home Workshop',
                            prefixIcon: Icons.inventory_2_outlined,
                            errorText: _nameError,
                            onChanged: (_) {
                              setState(() {
                                if (_nameError != null) _nameError = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          AppInput(
                            controller: _descriptionController,
                            label: 'Description (optional)',
                            hint: 'What kind of tools are in this toolbox?',
                            prefixIcon: Icons.notes_outlined,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

                    const SizedBox(height: 16),

                    // Visibility
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      enableHover: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Visibility',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildVisibilityOption(
                            ToolboxVisibility.private,
                            Icons.lock_outlined,
                            'Private',
                            'Only you can see this toolbox',
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildVisibilityOption(
                            ToolboxVisibility.buddies,
                            Icons.people_outlined,
                            'Buddies',
                            'Your buddies can view and borrow',
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildVisibilityOption(
                            ToolboxVisibility.public,
                            Icons.public,
                            'Public',
                            'Anyone can view and request to borrow',
                            isDark,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                    const SizedBox(height: 16),

                    // Icon Selection
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      enableHover: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Icon',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _icons.map((item) {
                              final isSelected = _selectedIcon == item['name'];
                              return GestureDetector(
                                onTap: () => setState(() => _selectedIcon = item['name']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? selectedColorValue.withOpacity(isDark ? 0.2 : 0.1)
                                        : (isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    border: Border.all(
                                      color: isSelected
                                          ? selectedColorValue
                                          : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    color: isSelected
                                        ? selectedColorValue
                                        : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 250.ms, duration: 300.ms),

                    const SizedBox(height: 16),

                    // Color Selection
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      enableHover: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Color',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _colors.map((color) {
                              final isSelected = _selectedColor == color;
                              final colorValue = Color(int.parse(color.replaceFirst('#', 'FF'), radix: 16));
                              return GestureDetector(
                                onTap: () => setState(() => _selectedColor = color),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: colorValue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? (isDark ? Colors.white : AppTheme.textPrimaryLight)
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: colorValue.withOpacity(0.4),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 22)
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityOption(
    ToolboxVisibility value,
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
  ) {
    final isSelected = _visibility == value;

    return GestureDetector(
      onTap: () => setState(() => _visibility = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(isDark ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppTheme.primaryColor
                  : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getVisibilityIcon() {
    switch (_visibility) {
      case ToolboxVisibility.private:
        return Icons.lock_outlined;
      case ToolboxVisibility.buddies:
        return Icons.people_outlined;
      case ToolboxVisibility.public:
        return Icons.public;
    }
  }

  String _getVisibilityLabel() {
    switch (_visibility) {
      case ToolboxVisibility.private:
        return 'Private';
      case ToolboxVisibility.buddies:
        return 'Buddies only';
      case ToolboxVisibility.public:
        return 'Public';
    }
  }
}
