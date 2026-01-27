import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Shadcn/ui-inspired color palette - Sage green theme
  static const Color primaryColor = Color(0xFF6B8E7B); // Sage green
  static const Color primaryHover = Color(0xFF5A7A69); // Darker sage
  static const Color secondaryColor = Color(0xFF8BA898); // Lighter sage

  // Status colors
  static const Color successColor = Color(0xFF10B981); // Emerald
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color errorLight = Color(0xFFFEE2E2);

  // Light theme - Warm stone palette
  static const Color backgroundLight = Color(0xFFFAFAF9); // Stone-50
  static const Color surfaceLight = Color(0xFFFFFFFF); // White
  static const Color textPrimaryLight = Color(0xFF292524); // Stone-800
  static const Color textSecondaryLight = Color(0xFF57534E); // Stone-600
  static const Color textMutedLight = Color(0xFF78716C); // Stone-500
  static const Color borderLight = Color(0xFFE7E5E4); // Stone-200

  // Dark theme - Deep stone
  static const Color backgroundDark = Color(0xFF1C1917); // Stone-900
  static const Color surfaceDark = Color(0xFF292524); // Stone-800
  static const Color textPrimaryDark = Color(0xFFFAFAF9); // Stone-50
  static const Color textSecondaryDark = Color(0xFFA8A29E); // Stone-400
  static const Color textMutedDark = Color(0xFF78716C); // Stone-500
  static const Color borderDark = Color(0xFF44403C); // Stone-700

  // Border radii
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radius2xl = 24.0;

  // Shadows for light theme
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowXl => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 25,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: successColor,
        error: errorColor,
        surface: surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
        outline: borderLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textPrimaryLight,
        displayColor: textPrimaryLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLight.withOpacity(0.8),
        foregroundColor: textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryColor.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMutedLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: 24);
          }
          return IconThemeData(color: textMutedLight, size: 24);
        }),
        elevation: 0,
        height: 70,
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: borderLight),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          color: textMutedLight,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: textSecondaryLight,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: BorderSide(color: borderLight),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: backgroundLight,
        selectedColor: primaryColor.withOpacity(0.15),
        disabledColor: borderLight,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondaryLight,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: primaryColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius2xl),
          side: BorderSide(color: borderLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondaryLight,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceLight,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryLight,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: surfaceLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: textMutedLight,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimaryLight,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: textSecondaryLight,
        ),
      ),
      iconTheme: IconThemeData(
        color: textSecondaryLight,
        size: 24,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return textMutedLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return borderLight;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: successColor,
        error: errorColor,
        surface: surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
        outline: borderDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textPrimaryDark,
        displayColor: textPrimaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark.withOpacity(0.8),
        foregroundColor: textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryColor.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMutedDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: 24);
          }
          return IconThemeData(color: textMutedDark, size: 24);
        }),
        elevation: 0,
        height: 70,
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: borderDark),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          color: textMutedDark,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: textSecondaryDark,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: BorderSide(color: borderDark),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        selectedColor: primaryColor.withOpacity(0.2),
        disabledColor: borderDark,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondaryDark,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: primaryColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius2xl),
          side: BorderSide(color: borderDark),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: borderDark,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondaryDark,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryDark,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: surfaceDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: textMutedDark,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimaryDark,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: textSecondaryDark,
        ),
      ),
      iconTheme: IconThemeData(
        color: textSecondaryDark,
        size: 24,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return textMutedDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return borderDark;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
