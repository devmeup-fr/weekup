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

  /// Thème principal de l'app : nuit violette, accent pêche.
  static ThemeData night() {
    const scheme = ColorScheme.dark(
      primary: ThemeColors.secondary,
      onPrimary: ThemeColors.night,
      secondary: ThemeColors.secondary,
      onSecondary: ThemeColors.night,
      primaryContainer: ThemeColors.dusk,
      onPrimaryContainer: Colors.white,
      tertiary: ThemeColors.tertiary,
      error: ThemeColors.errorSoft,
      onError: ThemeColors.night,
      surface: ThemeColors.night,
      onSurface: Colors.white,
      onSurfaceVariant: ThemeColors.textMuted,
      surfaceContainerLowest: ThemeColors.night,
      surfaceContainerLow: ThemeColors.nightSurface,
      surfaceContainer: ThemeColors.nightSurface,
      surfaceContainerHigh: ThemeColors.nightSurfaceHigh,
      surfaceContainerHighest: ThemeColors.nightSurfaceHigh,
      outline: ThemeColors.textFaint,
      outlineVariant: ThemeColors.nightOutline,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: GoogleFonts.roboto().fontFamily,
    );

    return base.copyWith(
      scaffoldBackgroundColor: ThemeColors.night,
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontFamily: GoogleFonts.roboto().fontFamily),
          ),
        ),
      ),
      textTheme: ThemeStyles.textTheme.apply(
        fontFamily: GoogleFonts.roboto().fontFamily,
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ThemeColors.night,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: ThemeColors.nightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ThemeColors.nightOutline),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ThemeColors.nightSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: ThemeColors.textFaint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: ThemeColors.nightSurfaceHigh,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ThemeColors.nightSurfaceHigh,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 15),
        actionTextColor: ThemeColors.secondary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? ThemeColors.night
              : ThemeColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? ThemeColors.secondary
              : ThemeColors.nightSurfaceHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.transparent
              : ThemeColors.textFaint,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: ThemeColors.secondary,
        inactiveTrackColor: ThemeColors.nightSurfaceHigh,
        thumbColor: ThemeColors.secondary,
        overlayColor: Color(0x29FEA071),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ThemeColors.secondary,
        foregroundColor: ThemeColors.night,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ThemeColors.secondary,
          foregroundColor: ThemeColors.night,
          textStyle: TextStyle(
            fontFamily: GoogleFonts.roboto().fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ThemeColors.nightSurfaceHigh,
        hintStyle: const TextStyle(color: ThemeColors.textFaint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: ThemeColors.textMuted,
        textColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: ThemeColors.nightOutline,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ThemeColors.nightSurfaceHigh,
        selectedColor: ThemeColors.secondary,
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: Colors.white,
          fontFamily: GoogleFonts.roboto().fontFamily,
        ),
        secondaryLabelStyle: const TextStyle(color: ThemeColors.night),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: ThemeColors.nightSurfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: ThemeColors.nightSurfaceHigh,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
