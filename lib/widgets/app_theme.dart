import 'package:flutter/material.dart';

class AppColors {
  static const magenta = Color(0xFF8E0A57);
  static const magentaDark = Color(0xFF61063B);
  static const magentaLight = Color(0xFFD4589A);
  static const bg = Color(0xFF0A0A0A);
  static const glass = Color(0x1AFFFFFF);
  static const glassBorder = Color(0x1AFFFFFF);
}

class AppTheme {
  static BoxDecoration glassDecoration({
    double radius = 24,
    Color? border,
  }) =>
      BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border ?? AppColors.glassBorder, width: 1),
      );

  static BoxDecoration magentaGlow({double radius = 24}) => BoxDecoration(
        color: AppColors.magenta,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.magenta.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      );
}
