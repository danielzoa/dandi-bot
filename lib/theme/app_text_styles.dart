import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const _sansFallback = ['Segoe UI', 'Arial'];
  static const _monoFallback = ['Consolas', 'Courier New'];

  static TextStyle get display => const TextStyle(
    color: AppColors.white,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    fontFamily: 'Inter',
    fontFamilyFallback: _sansFallback,
  );

  static TextStyle get title => const TextStyle(
    color: AppColors.white,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
    fontFamilyFallback: _sansFallback,
  );

  static TextStyle get subtitle => const TextStyle(
    color: AppColors.white,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
    fontFamilyFallback: _sansFallback,
  );

  static TextStyle get body => const TextStyle(
    color: AppColors.white,
    fontSize: 14,
    height: 1.45,
    fontFamily: 'Inter',
    fontFamilyFallback: _sansFallback,
  );

  static TextStyle get muted => const TextStyle(
    color: AppColors.muted,
    fontSize: 12,
    height: 1.4,
    fontFamily: 'Inter',
    fontFamilyFallback: _sansFallback,
  );

  static TextStyle get mono => const TextStyle(
    color: AppColors.white,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    fontFamily: 'Space Mono',
    fontFamilyFallback: _monoFallback,
  );
}
