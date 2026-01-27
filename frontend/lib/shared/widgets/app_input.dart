import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AppInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const AppInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscureText = widget.obscureText;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null;

    Color borderColor;
    if (hasError) {
      borderColor = AppTheme.errorColor;
    } else if (_isFocused) {
      borderColor = AppTheme.primaryColor;
    } else {
      borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscureText,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: isDark
                    ? AppTheme.textMutedDark
                    : AppTheme.textMutedLight,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _isFocused
                          ? AppTheme.primaryColor
                          : (isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textMutedLight),
                    )
                  : null,
              suffixIcon: widget.obscureText
                  ? GestureDetector(
                      onTap: () => setState(() => _obscureText = !_obscureText),
                      child: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: isDark
                            ? AppTheme.textMutedDark
                            : AppTheme.textMutedLight,
                      ),
                    )
                  : widget.suffix,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.prefixIcon != null ? 0 : 16,
                vertical: 14,
              ),
              counterText: '',
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 14,
                color: AppTheme.errorColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helperText!,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppTheme.textMutedDark
                  : AppTheme.textMutedLight,
            ),
          ),
        ],
      ],
    );
  }
}

class AppSearchInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  const AppSearchInput({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  @override
  State<AppSearchInput> createState() => _AppSearchInputState();
}

class _AppSearchInputState extends State<AppSearchInput> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: _controller,
      hint: widget.hint,
      prefixIcon: Icons.search,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffix: _hasText
          ? GestureDetector(
              onTap: _onClear,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.textMutedDark
                      : AppTheme.textMutedLight,
                ),
              ),
            )
          : null,
    );
  }
}
