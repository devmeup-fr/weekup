import 'package:flutter/material.dart';

class ThemeStyles {
  static const fontLight = FontWeight.w300;
  static const fontRegular = FontWeight.w400;
  static const fontMedium = FontWeight.w500;

  static const displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: fontLight,
  );

  static const display = TextStyle(
    fontSize: 45,
    fontWeight: fontLight,
  );

  static const displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: fontRegular,
  );

  static const headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: fontRegular,
  );

  static const headline = TextStyle(
    fontSize: 28,
    fontWeight: fontRegular,
  );

  static const headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: fontRegular,
  );

  static const titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: fontRegular,
  );

  static const title = TextStyle(
    fontSize: 18,
    fontWeight: fontMedium,
  );

  static const titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: fontMedium,
  );

  static const bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: fontRegular,
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: fontRegular,
  );

  static const bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: fontRegular,
  );

  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: fontMedium,
  );

  static const label = TextStyle(
    fontSize: 12,
    fontWeight: fontMedium,
  );

  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: fontMedium,
  );

// https://api.flutter.dev/flutter/material/TextTheme-class.html
  static TextTheme get textTheme {
    final textTheme = const TextTheme()
        .copyWith(
          displayLarge: displayLarge,
          displayMedium: display,
          displaySmall: displaySmall,
          headlineLarge: headlineLarge,
          headlineMedium: headline,
          headlineSmall: headlineSmall,
          titleLarge: titleLarge,
          titleMedium: title,
          titleSmall: titleSmall,
          bodyLarge: bodyLarge,
          bodyMedium: body,
          bodySmall: bodySmall,
          labelLarge: labelLarge,
          labelMedium: label,
          labelSmall: labelSmall,
        )
        .apply();
    return textTheme;
  }
}
