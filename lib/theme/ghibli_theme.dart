import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'fortune_theme.dart';

class GhibliTheme {
  // Palette (Contrast Enhanced)
  static const Color creamBg = Color(0xFFFAF9F0); // Brighter/Cleaner Cream for contrast
  static const Color lushGreen = Color(0xFF4C7552); // Deeper, Richer Green
  static const Color darkGreen = Color(0xFF355239);
  static const Color skyBlue = Color(0xFF6B9AC4); // More vivid sky
  static const Color berryRed = Color(0xFFD16B6E); // More vibrant red
  static const Color sunYellow = Color(0xFFEBCA60); // Golden
  static const Color charcoal = Color(0xFF2E2C29); // Darker Ink (near black)
  static const Color cloudWhite = Color(0xFFFFFFFF);

  static ThemeData get themeData {
    final colors = const FortuneColors(
      themeId: 'ghibli',
      backgroundMain: creamBg,
      backgroundCard: cloudWhite,
      primary: lushGreen,
      primaryDark: darkGreen,
      primaryBright: skyBlue,
      secondary: berryRed,
      accent: sunYellow,
      textMain: charcoal,
      textContrast: cloudWhite,
      backgroundImagePath: null, // Could add a subtle paper texture eventually
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light, 
      primaryColor: lushGreen,
      scaffoldBackgroundColor: creamBg,
      
      extensions: [colors], 

      cardTheme: CardThemeData(
        color: cloudWhite,
        elevation: 0, // Flat with border or subtle shadow
        shadowColor: charcoal.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(color: lushGreen.withOpacity(0.2), width: 1), 
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: creamBg,
        foregroundColor: lushGreen,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.nunito( 
          fontSize: 28,
          color: lushGreen,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: lushGreen),
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.nunito(color: lushGreen, fontSize: 36, fontWeight: FontWeight.w900),
        displayMedium: GoogleFonts.nunito(color: lushGreen, fontSize: 28, fontWeight: FontWeight.w800),
        displaySmall: GoogleFonts.nunito(color: lushGreen, fontSize: 24, fontWeight: FontWeight.w800),
        
        bodyLarge: GoogleFonts.nunito(color: charcoal, fontSize: 18, fontWeight: FontWeight.w600),
        bodyMedium: GoogleFonts.nunito(color: charcoal, fontSize: 16, fontWeight: FontWeight.w500),
        bodySmall: GoogleFonts.nunito(color: charcoal.withOpacity(0.7), fontSize: 14),
        
        // Button text
        labelLarge: GoogleFonts.nunito(
            color: cloudWhite, 
            fontSize: 18, 
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0
        ),
      ),
      
      iconTheme: const IconThemeData(
        color: lushGreen,
        size: 28,
      ),
      
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: berryRed,
        foregroundColor: cloudWhite,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: creamBg,
        titleTextStyle: GoogleFonts.nunito(color: lushGreen, fontSize: 26, fontWeight: FontWeight.w900),
        contentTextStyle: GoogleFonts.nunito(color: charcoal, fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white, width: 4), // White border
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: skyBlue,
        thickness: 2,
        indent: 16,
        endIndent: 16,
      ),
      
      colorScheme: const ColorScheme.light(
        primary: lushGreen,
        secondary: berryRed,
        surface: creamBg,
        error: berryRed,
        onPrimary: cloudWhite,
        onSecondary: cloudWhite,
        onSurface: charcoal,
      ),
    );
  }
}
