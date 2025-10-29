
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00BFA6); // Teal
  static const Color secondaryColor = Color(0xFF1E88E5); // Deep Blue

  static final TextTheme _lightTextTheme = TextTheme(
    displayLarge: GoogleFonts.lato(fontSize: 57, fontWeight: FontWeight.bold, color: Colors.black),
    titleLarge: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
    bodyMedium: GoogleFonts.lato(fontSize: 14, color: Colors.black87),
  );

  static final TextTheme _darkTextTheme = TextTheme(
    displayLarge: GoogleFonts.lato(fontSize: 57, fontWeight: FontWeight.bold, color: Colors.white),
    titleLarge: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
    bodyMedium: GoogleFonts.lato(fontSize: 14, color: Colors.white70),
  );


  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      secondary: secondaryColor,
    ),
    textTheme: _lightTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      secondary: secondaryColor,
    ),
    textTheme: _darkTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
