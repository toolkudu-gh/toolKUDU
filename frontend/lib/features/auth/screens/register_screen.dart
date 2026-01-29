import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../core/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    setState(() {
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    bool isValid = true;

    // Username validation
    if (_usernameController.text.isEmpty) {
      setState(() => _usernameError = 'Please enter a username');
      isValid = false;
    } else if (_usernameController.text.length < 3) {
      setState(() => _usernameError = 'Username must be at least 3 characters');
      isValid = false;
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(_usernameController.text)) {
      setState(() => _usernameError = 'Only letters, numbers, and underscores allowed');
      isValid = false;
    }

    // Email validation
    if (_emailController.text.isEmpty) {
      setState(() => _emailError = 'Please enter your email');
      isValid = false;
    } else if (!_emailController.text.contains('@')) {
      setState(() => _emailError = 'Please enter a valid email');
      isValid = false;
    }

    // Password validation
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter a password');
      isValid = false;
    } else if (password.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters');
      isValid = false;
    } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
      setState(() => _passwordError = 'Must contain an uppercase letter');
      isValid = false;
    } else if (!RegExp(r'[a-z]').hasMatch(password)) {
      setState(() => _passwordError = 'Must contain a lowercase letter');
      isValid = false;
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      setState(() => _passwordError = 'Must contain a number');
      isValid = false;
    }

    // Confirm password validation
    if (_confirmPasswordController.text != password) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleRegister() async {
    if (!_validateForm()) return;

    final email = _emailController.text.trim();

    final success = await ref.read(authStateProvider.notifier).signUp(
          email: email,
          password: _passwordController.text,
          username: _usernameController.text.trim(),
        );

    if (success && mounted) {
      context.go('/verify-email', extra: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

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
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => context.go('/login'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 48 : 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SvgPicture.asset(
                                  'assets/images/toolkudu_logo.svg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 300.ms).scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1, 1),
                                duration: 300.ms,
                                curve: Curves.easeOutBack,
                              ),
                          const SizedBox(height: 16),
                          // Title
                          Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ).animate().fadeIn(duration: 300.ms),
                          const SizedBox(height: 8),
                          Text(
                            'Join ToolKUDU to organize and share your tools',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                          ).animate().fadeIn(delay: 50.ms, duration: 300.ms),

                          const SizedBox(height: 32),

                          // Form Card
                          AppCard(
                            padding: const EdgeInsets.all(24),
                            enableHover: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Username
                                AppInput(
                                  controller: _usernameController,
                                  label: 'Username',
                                  hint: 'Choose a unique username',
                                  prefixIcon: Icons.person_outlined,
                                  textInputAction: TextInputAction.next,
                                  errorText: _usernameError,
                                  onChanged: (_) {
                                    if (_usernameError != null) {
                                      setState(() => _usernameError = null);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Email
                                AppInput(
                                  controller: _emailController,
                                  label: 'Email',
                                  hint: 'Enter your email',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  errorText: _emailError,
                                  onChanged: (_) {
                                    if (_emailError != null) {
                                      setState(() => _emailError = null);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password
                                AppInput(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hint: 'Create a strong password',
                                  prefixIcon: Icons.lock_outlined,
                                  obscureText: true,
                                  textInputAction: TextInputAction.next,
                                  errorText: _passwordError,
                                  helperText: _passwordError == null
                                      ? 'Min 8 characters with uppercase, lowercase, and number'
                                      : null,
                                  onChanged: (_) {
                                    if (_passwordError != null) {
                                      setState(() => _passwordError = null);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Confirm Password
                                AppInput(
                                  controller: _confirmPasswordController,
                                  label: 'Confirm Password',
                                  hint: 'Re-enter your password',
                                  prefixIcon: Icons.lock_outlined,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  errorText: _confirmPasswordError,
                                  onChanged: (_) {
                                    if (_confirmPasswordError != null) {
                                      setState(() => _confirmPasswordError = null);
                                    }
                                  },
                                  onSubmitted: (_) => _handleRegister(),
                                ),

                                const SizedBox(height: 24),

                                // Error message
                                if (authState.error != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorLight,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                      border: Border.all(
                                        color: AppTheme.errorColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 18,
                                          color: AppTheme.errorColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            authState.error!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.errorColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Register button
                                AppButton(
                                  label: 'Create Account',
                                  onPressed: authState.isLoading ? null : _handleRegister,
                                  isLoading: authState.isLoading,
                                  fullWidth: true,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(
                                begin: 0.1,
                                end: 0,
                                delay: 100.ms,
                                duration: 400.ms,
                                curve: Curves.easeOutCubic,
                              ),

                          const SizedBox(height: 24),

                          // Login link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
