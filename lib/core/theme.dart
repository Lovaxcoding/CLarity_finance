import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Couleurs Violettes Aesthétiques
  static const Color primaryColor = Color(
    0xFF6A0DAD,
  ); // Violet foncé (Améthyste)
  static const Color secondaryColor = Color(0xFFC71585); // Rose-Violet vif

  // Définition des polices
  static final String _titleFontFamily = GoogleFonts.josefinSans().fontFamily!;
  static final String _bodyFontFamily = GoogleFonts.montserrat().fontFamily!;

  // --- Thème de Texte Clair (Montserrat pour le corps, Josefin Sans pour les titres) ---
  static final TextTheme _lightTextTheme = TextTheme(
    // TITRES : Josefin Sans
    displayLarge: GoogleFonts.josefinSans(
      fontSize: 57,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    displayMedium: GoogleFonts.josefinSans(
      fontSize: 45,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ), // Utilisé pour 'Bonjour [Nom]'
    titleLarge: GoogleFonts.josefinSans(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    titleMedium: GoogleFonts.josefinSans(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ), // Utilisé pour les titres de sections
    // CORPS DU TEXTE : Montserrat
    bodyMedium: GoogleFonts.montserrat(fontSize: 14, color: Colors.black87),
    labelLarge: GoogleFonts.montserrat(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
  );

  // --- Thème de Texte Sombre ---
  static final TextTheme _darkTextTheme = TextTheme(
    // TITRES : Josefin Sans
    displayLarge: GoogleFonts.josefinSans(
      fontSize: 57,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    displayMedium: GoogleFonts.josefinSans(
      fontSize: 45,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleLarge: GoogleFonts.josefinSans(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleMedium: GoogleFonts.josefinSans(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),

    // CORPS DU TEXTE : Montserrat
    bodyMedium: GoogleFonts.montserrat(fontSize: 14, color: Colors.white70),
    labelLarge: GoogleFonts.montserrat(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  );

  // --- Thème Clair (LIGHT THEME) ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    // Définir Montserrat comme police de base (fallback)
    fontFamily: _bodyFontFamily,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      background: const Color(0xFFF0F0F5), // Un fond très clair
    ),
    textTheme: _lightTextTheme,

    // Thème de l'AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.josefinSans(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Thème des Boutons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  // --- Thème Sombre (DARK THEME) ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    // Définir Montserrat comme police de base
    fontFamily: _bodyFontFamily,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      background: Colors.black,
      surface: const Color(
        0xFF1A0A3A,
      ), // Un fond sombre avec une touche de violet
    ),
    textTheme: _darkTextTheme,

    // Thème de l'AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.josefinSans(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Thème des Boutons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor:
            secondaryColor, // Utiliser la couleur secondaire pour un contraste dans le dark mode
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
