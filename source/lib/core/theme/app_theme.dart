import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // DirectNest-inspired high-end healthcare palette
  static const Color primary = Color(0xFF059669);        // Emerald green
  static const Color primaryDark = Color(0xFF047857);
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color primaryMuted = Color(0xFFECFDF5);
  static const Color accentGreen = Color(0xFF10B981);    // Vibrant mint emerald

  static const Color secondary = Color(0xFF0D9488);
  static const Color secondaryLight = Color(0xFFCCFBF1);

  static const Color accent = Color(0xFF34D399);
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFF3E8FF);

  static const Color background = Color(0xFFF8FAFC);     // Clean airy off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);

  static const Color textPrimary = Color(0xFF0F172A);    // Deep navy slate
  static const Color textSecondary = Color(0xFF475569);  // Slate 600
  static const Color textMuted = Color(0xFF94A3B8);      // Slate 400
  static const Color border = Color(0xFFE2E8F0);        // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9);

  // Garamond Light / Nova Typography (Cormorant Garamond)
  static TextStyle serifHero({double fontSize = 34, Color color = textPrimary}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: -0.3,
        height: 1.15,
      );

  static TextStyle serifTitle({double fontSize = 26, Color color = textPrimary}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
        height: 1.2,
      );

  static TextStyle serifSubtitle({double fontSize = 20, Color color = textPrimary}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // Ultra-clean Modern Sans Typography (Plus Jakarta Sans)
  static TextStyle sansBold({double fontSize = 14, Color color = textPrimary, double? letterSpacing}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle sansSemiBold({double fontSize = 14, Color color = textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle sansRegular({double fontSize = 14, Color color = textSecondary, double? height}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color,
        height: height ?? 1.45,
      );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glowGreenShadow => [
        BoxShadow(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData get lightTheme {
    final bodyFont = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: bodyFont.copyWith(
        displayLarge: serifHero(),
        headlineMedium: serifTitle(),
        titleLarge: serifSubtitle(),
        bodyLarge: sansRegular(fontSize: 15, color: textPrimary),
        bodyMedium: sansRegular(fontSize: 13.5, color: textSecondary),
        bodySmall: sansRegular(fontSize: 12, color: textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: textSecondary, fontSize: 13.5),
        hintStyle: GoogleFonts.plusJakartaSans(color: textMuted, fontSize: 13.5),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 11),
      ),
    );
  }
}
