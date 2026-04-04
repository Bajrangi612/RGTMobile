import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';

class GoldTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;
  final int maxLines;

  GoldTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
  }) ;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      enabled: enabled,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      style: TextStyle(
        color: AppColors.pureWhite,
        fontSize: 16,
      ),
      cursorColor: AppColors.royalGold,
      decoration: AppDecorations.inputDecoration(
        label: label,
        hint: hint,
        prefix: prefixIcon,
        suffix: suffixIcon,
      ),
    );
  }
}
