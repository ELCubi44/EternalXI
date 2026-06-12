import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    super.key,
    this.hintText,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      style: TextStyle(
        fontFamily: 'Lumiare',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: context.xiTextPrimary,
      ),
      cursorColor: XiColors.royalBlue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: context.xiSurfaceInset.withValues(alpha: 0.65),
        labelStyle: TextStyle(
          fontFamily: 'Lumiare',
          fontSize: 13,
          color: context.xiTextPrimary.withValues(alpha: 0.72),
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Lumiare',
          fontSize: 11,
          color: XiColors.royalBlue,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Lumiare',
          fontSize: 13,
          color: context.xiTextPrimary.withValues(alpha: 0.45),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Lumiare',
          fontSize: 11,
          color: XiColors.heroRed,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.xiBorderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: XiColors.royalBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: XiColors.heroRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: XiColors.heroRed, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: context.xiBorderSubtle.withValues(alpha: 0.5),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
