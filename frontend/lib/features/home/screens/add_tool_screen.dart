import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';

class AddToolScreen extends ConsumerStatefulWidget {
  final String toolboxId;

  const AddToolScreen({super.key, required this.toolboxId});

  @override
  ConsumerState<AddToolScreen> createState() => _AddToolScreenState();
}

class _AddToolScreenState extends ConsumerState<AddToolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _categoryController = TextEditingController();

  String? _nameError;
  bool _isLoading = false;
  final List<String> _selectedImages = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    setState(() => _nameError = null);

    if (_nameController.text.isEmpty) {
      setState(() => _nameError = 'Please enter a tool name');
      return false;
    }
    return true;
  }

  Future<void> _handleSave() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      context.go('/home/toolbox/${widget.toolboxId}');
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
                    onPressed: () => context.go('/home/toolbox/${widget.toolboxId}'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add Tool',
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
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Image upload area
                    AppCard(
                      padding: EdgeInsets.zero,
                      enableHover: false,
                      child: InkWell(
                        onTap: () {
                          // TODO: Add image picker
                        },
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                          child: _selectedImages.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                      ),
                                      child: Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 28,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Add Photos',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppTheme.textPrimaryDark
                                            : AppTheme.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to add images of your tool',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppTheme.textSecondaryDark
                                            : AppTheme.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _selectedImages.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == _selectedImages.length) {
                                      return Container(
                                        width: 120,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                                            width: 2,
                                            style: BorderStyle.solid,
                                          ),
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          color: isDark
                                              ? AppTheme.textMutedDark
                                              : AppTheme.textMutedLight,
                                        ),
                                      );
                                    }
                                    return Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                        image: DecorationImage(
                                          image: NetworkImage(_selectedImages[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                    const SizedBox(height: 24),

                    // Form fields
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      enableHover: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tool Details',
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
                            controller: _nameController,
                            label: 'Tool Name',
                            hint: 'e.g., Cordless Drill',
                            prefixIcon: Icons.handyman_outlined,
                            errorText: _nameError,
                            onChanged: (_) {
                              if (_nameError != null) {
                                setState(() => _nameError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          AppInput(
                            controller: _brandController,
                            label: 'Brand',
                            hint: 'e.g., DeWalt, Milwaukee',
                            prefixIcon: Icons.business_outlined,
                          ),
                          const SizedBox(height: 16),

                          AppInput(
                            controller: _modelController,
                            label: 'Model',
                            hint: 'e.g., DCD771C2',
                            prefixIcon: Icons.tag_outlined,
                          ),
                          const SizedBox(height: 16),

                          AppInput(
                            controller: _categoryController,
                            label: 'Category',
                            hint: 'e.g., Power Tools, Hand Tools',
                            prefixIcon: Icons.category_outlined,
                          ),
                          const SizedBox(height: 16),

                          AppInput(
                            controller: _descriptionController,
                            label: 'Description',
                            hint: 'Add any notes about this tool...',
                            prefixIcon: Icons.notes_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

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
}
