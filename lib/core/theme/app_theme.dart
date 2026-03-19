import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Central ThemeData for the app following the provided design system.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surfaceWhite,
      onSurface: AppColors.neutralDark,
    );

    final textTheme = AppTypography.toTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Be Vietnam Pro',
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.neutralDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.header2.copyWith(
          color: AppColors.neutralDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size.fromHeight(50)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          elevation: WidgetStateProperty.all(8),
          shadowColor: WidgetStateProperty.all(
            const Color(0x1AC94210), // #C94210 @10% opacity
          ),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          textStyle: WidgetStateProperty.all(
            AppTypography.header3.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.14,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => null, // we will usually use gradients in custom button
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size.fromHeight(50)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.primary),
          ),
          foregroundColor: WidgetStateProperty.all(AppColors.primary),
          textStyle: WidgetStateProperty.all(
            AppTypography.subHeader,
          ),
          elevation: WidgetStateProperty.all(8),
          shadowColor: WidgetStateProperty.all(
            const Color(0x1AC94210),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: AppTypography.bodyRegular1.copyWith(
          fontSize: 12,
          color: const Color(0xFF3C3C3C),
          height: 1.37,
        ),
        hintStyle: AppTypography.bodyRegular1.copyWith(
          fontSize: 14,
          color: const Color(0xFFA9ABAE),
          height: 1.37,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.neutralLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.neutralLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.error,
          letterSpacing: -0.24,
        ),
      ),
    );
  }
}

