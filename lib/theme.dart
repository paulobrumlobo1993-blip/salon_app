import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color rosePrimary = Color(0xFFD4708A);
  static const Color roseLight = Color(0xFFF9E8EE);
  static const Color roseDark = Color(0xFFA84F68);
  static const Color gold = Color(0xFFB8860B);
  static const Color goldLight = Color(0xFFFFF8E7);
  static const Color surface = Color(0xFFFDF6F8);
  static const Color textDark = Color(0xFF2D1B24);
  static const Color textMedium = Color(0xFF7A5565);
  static const Color textLight = Color(0xFFB89AA5);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE57373);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: rosePrimary,
          primary: rosePrimary,
          secondary: gold,
          surface: surface,
          background: surface,
        ),
        scaffoldBackgroundColor: surface,
        textTheme: GoogleFonts.playfairDisplayTextTheme().copyWith(
          bodyLarge: GoogleFonts.lato(color: textDark, fontSize: 16),
          bodyMedium: GoogleFonts.lato(color: textMedium, fontSize: 14),
          bodySmall: GoogleFonts.lato(color: textLight, fontSize: 12),
          labelLarge: GoogleFonts.lato(
            color: textDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: rosePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: rosePrimary.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: rosePrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: rosePrimary.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: rosePrimary.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: rosePrimary, width: 2),
          ),
          labelStyle: GoogleFonts.lato(color: textMedium),
          hintStyle: GoogleFonts.lato(color: textLight),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: rosePrimary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: rosePrimary,
          unselectedItemColor: Color(0xFFB89AA5),
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
      );
}
