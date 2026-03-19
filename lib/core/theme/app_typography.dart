import 'package:flutter/material.dart';

/// App text styles based on provided design system.
///
/// Note: assumes fonts "DM Sans" và "Be Vietnam Pro" đã được add vào project.
class AppTypography {
  AppTypography._();

  // Font families
  static const _dmSans = 'DM Sans';
  static const _beVietnamPro = 'Be Vietnam Pro';

  // Headers
  static const header1 = TextStyle(
    fontFamily: _dmSans,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.72,
    color: Colors.black,
  );

  static const header2 = TextStyle(
    fontFamily: _dmSans,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.48,
    color: Colors.black,
  );

  static const header3 = TextStyle(
    fontFamily: _beVietnamPro,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Colors.black,
  );

  static const subHeader = TextStyle(
    fontFamily: _beVietnamPro,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.16,
    height: 1.5,
    color: Colors.black,
  );

  static const highlighter = subHeader;

  static const bodyRegular1 = TextStyle(
    fontFamily: _beVietnamPro,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Colors.black,
  );

  // Map to Flutter TextTheme slots for convenience
  static TextTheme toTextTheme() {
    return const TextTheme(
      displayLarge: header1,
      titleLarge: header2,
      titleMedium: subHeader,
      bodyLarge: bodyRegular1,
      bodyMedium: header3,
    );
  }
}

