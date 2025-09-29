import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';
import 'styles.dart';

class Themes {
  static ThemeData light() => ThemeData(
        /// Colors
        brightness: Brightness.light,
        textTheme: ThemeStyles.textTheme.apply(
          fontFamily: GoogleFonts.roboto().fontFamily,
          bodyColor: ThemeColors.primary,
          displayColor: ThemeColors.primary,
        ),
        fontFamily: GoogleFonts.roboto().fontFamily,

        primaryColor: Colors.white,

        canvasColor: ThemeColors.primary,
        hoverColor: Colors.grey[200],
        focusColor: ThemeColors.secondary,

        // Appbar
        appBarTheme: const AppBarTheme(
          backgroundColor: ThemeColors.primary,
        ),

        /// input
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: ThemeColors.primary),
        ),

        /// Button
        buttonTheme: const ButtonThemeData(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(),
        ),
        iconTheme: const IconThemeData(),

        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 4,
        ),

        /// Dropdown theme
        dropdownMenuTheme: const DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
          ),
        ),

        colorScheme: const ColorScheme.light(
          primary: ThemeColors.primary,
          secondary: ThemeColors.secondary,
          tertiary: ThemeColors.tertiary,
          error: ThemeColors.error,
          surface: Color.fromRGBO(250, 248, 247, 1),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: ThemeColors.primary,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        menuTheme: const MenuThemeData(),
      );

  static ThemeData dark() => ThemeData.dark();
}
