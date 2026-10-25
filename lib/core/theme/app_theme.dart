import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Soft Pastel DRC Theme Specification
/// Derived from the calm, soft tones of the Democratic Republic of Congo flag and globe:
/// - Background: Pure White (#FFFFFF) & Soft Ice-Blue/Gray containers (#F4F7FA)
/// - Typography: Deep Slate Navy (#1B365D) headers & Cool Muted Gray (#5C6F84) copy
/// - Primary Action: Soft Sky-Cerulean Blue (#5BA4E5) pill buttons with white text
/// - Secondary Action: Gentle Powder-Blue (#E3F0FC)
/// - Pastel Accents:
///     * Apricot/Peach (#FFE5CC) with Terracotta icons (#D97736)
///     * Buttercream Yellow (#FFF4CC) with Warm Ochre (#D4A017)
///     * Soft Rose-Coral (#FADBD8) with Muted Ruby (#C0392B)
class AppTheme {
  // Surface & Canvas
  static const Color surfacePureWhite = Color(0xFFFFFFFF);
  static const Color backgroundIceBlue = Color(0xFFF4F7FA);
  static const Color cardOutline = Color(0xFFE6EEF6);

  // Typography Colors
  static const Color textSlateNavy = Color(0xFF1B365D);
  static const Color textMutedGray = Color(0xFF5C6F84);
  static const Color textLightPlaceholder = Color(0xFF9AA8B7);

  // Brand CTAs
  static const Color ceruleanBlue = Color(0xFF5BA4E5);
  static const Color powderBlue = Color(0xFFE3F0FC);
  static const Color deepCerulean = Color(0xFF3B86C8);

  // Soft Pastel Category & Accent Palettes
  static const Color pastelApricot = Color(0xFFFFE5CC);
  static const Color terracottaIcon = Color(0xFFD97736);

  static const Color pastelButtercream = Color(0xFFFFF4CC);
  static const Color warmOchre = Color(0xFFD4A017);

  static const Color pastelRose = Color(0xFFFADBD8);
  static const Color roseText = Color(0xFFC0392B);

  static const Color pastelMint = Color(0xFFD5F5E3);
  static const Color mintGreen = Color(0xFF27AE60);

  // Geometry
  static const double cardRadius = 24.0;
  static const double pillRadius = 999.0;
  static const double minTouchTarget = 48.0;

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surfacePureWhite,
      colorScheme: const ColorScheme.light(
        primary: ceruleanBlue,
        onPrimary: Colors.white,
        secondary: powderBlue,
        onSecondary: textSlateNavy,
        surface: surfacePureWhite,
        onSurface: textSlateNavy,
        surfaceContainerHighest: backgroundIceBlue,
        outline: cardOutline,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          color: textSlateNavy,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: textSlateNavy,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: textSlateNavy,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: textSlateNavy,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: textSlateNavy,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: textSlateNavy,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: textMutedGray,
          fontSize: 14,
          height: 1.5,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          color: textSlateNavy,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: backgroundIceBlue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: cardOutline, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ceruleanBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textSlateNavy,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: cardOutline, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundIceBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cardOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cardOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ceruleanBlue, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textLightPlaceholder,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfacePureWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textSlateNavy),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textSlateNavy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
