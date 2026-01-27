import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';

class AddTrackerScreen extends ConsumerStatefulWidget {
  final String toolId;

  const AddTrackerScreen({super.key, required this.toolId});

  @override
  ConsumerState<AddTrackerScreen> createState() => _AddTrackerScreenState();
}

class _AddTrackerScreenState extends ConsumerState<AddTrackerScreen> {
  String _selectedType = 'airtag';
  final _identifierController = TextEditingController();
  final _nameController = TextEditingController();
  String? _identifierError;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _trackerTypes = [
    {
      'value': 'airtag',
      'title': 'Apple AirTag',
      'subtitle': 'Find My network',
      'icon': Icons.apple,
    },
    {
      'value': 'tile',
      'title': 'Tile Tracker',
      'subtitle': 'Bluetooth tracker',
      'icon': Icons.bluetooth,
    },
    {
      'value': 'gps_cellular',
      'title': 'GPS Cellular',
      'subtitle': 'Cellular network',
      'icon': Icons.cell_tower,
    },
    {
      'value': 'gps_satellite',
      'title': 'GPS Satellite',
      'subtitle': 'Satellite tracking',
      'icon': Icons.satellite_alt,
    },
  ];

  @override
  void dispose() {
    _identifierController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    setState(() => _identifierError = null);

    if (_identifierController.text.isEmpty) {
      setState(() => _identifierError = 'Please enter tracker identifier');
      return false;
    }
    return true;
  }

  Future<void> _handleSave() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    // TODO: Call API to add tracker
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tracker added successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.go('/find');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    icon: Icons.close,
                    onPressed: () => context.go('/find'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add Tracker',
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
                    label: 'Save',
                    onPressed: _isLoading ? null : _handleSave,
                    isLoading: _isLoading,
                    size: AppButtonSize.sm,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Tracker Type Selection
                  Text(
                    'Tracker Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.textMutedDark
                          : AppTheme.textMutedLight,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                  const SizedBox(height: 12),

                  ...List.generate(_trackerTypes.length, (index) {
                    final type = _trackerTypes[index];
                    final isSelected = _selectedType == type['value'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildTrackerTypeOption(
                        context,
                        isDark,
                        value: type['value'] as String,
                        title: type['title'] as String,
                        subtitle: type['subtitle'] as String,
                        icon: type['icon'] as IconData,
                        isSelected: isSelected,
                      ),
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: 150 + index * 50),
                          duration: 300.ms,
                        );
                  }),

                  const SizedBox(height: 24),

                  // Tracker Details
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    enableHover: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tracker Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),

                        AppInput(
                          controller: _identifierController,
                          label: 'Tracker Identifier',
                          hint: 'Serial number or device ID',
                          prefixIcon: Icons.qr_code_outlined,
                          errorText: _identifierError,
                          onChanged: (_) {
                            if (_identifierError != null) {
                              setState(() => _identifierError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        AppInput(
                          controller: _nameController,
                          label: 'Nickname (optional)',
                          hint: 'e.g., Blue AirTag',
                          prefixIcon: Icons.label_outlined,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 350.ms, duration: 300.ms),

                  const SizedBox(height: 16),

                  // Info Card
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    enableHover: false,
                    backgroundColor: AppTheme.primaryColor.withOpacity(isDark ? 0.1 : 0.05),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How to find your tracker ID',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.textPrimaryDark
                                      : AppTheme.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'The identifier is usually printed on your tracker or can be found in your tracker\'s companion app.',
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
                  ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerTypeOption(
    BuildContext context,
    bool isDark, {
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(isDark ? 0.15 : 0.08)
              : (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.15)
                    : (isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppTheme.primaryColor
                    : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
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
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
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
}
