import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SteampunkTheme {
  // Palette
  static const Color mahoganyDark = Color(0xFF2D160E);   // Deep wood for background
  static const Color mahoganyLight = Color(0xFF4A2817);  // Lighter wood for cards
  static const Color brassPrimary = Color(0xFFCDBE78);   // Main brass/gold color
  static const Color brassDark = Color(0xFF8B7E40);      // Shadow/Border brass
  static const Color brassBright = Color(0xFFFFF5C3);    // Highlight
  static const Color verdigris = Color(0xFF43B3AE);      // Oxidized copper accent
  static const Color leatherDark = Color(0xFF1A1110);    // Deepest shadow
  static const Color steamWhite = Color(0xFFE0E0E0);     // Text color (off-white)
  static const Color amberGlow = Color(0xFFFFA000);      // Active/Highlight glow

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: brassPrimary,
      scaffoldBackgroundColor: mahoganyDark,
      
      // Card Theme (Leather/Wood look)
      cardTheme: CardThemeData(
        color: mahoganyLight,
        elevation: 8,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: brassDark, width: 2),
        ),
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: mahoganyDark,
        foregroundColor: brassPrimary,
        centerTitle: true,
        titleTextStyle: GoogleFonts.rye(
          fontSize: 28,
          color: brassPrimary,
          shadows: [
            const Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
          ],
        ),
        iconTheme: const IconThemeData(color: brassPrimary),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        // Headlines (Victorian style)
        displayLarge: GoogleFonts.rye(color: brassPrimary, fontSize: 32),
        displayMedium: GoogleFonts.rye(color: brassPrimary, fontSize: 24),
        displaySmall: GoogleFonts.rye(color: brassPrimary, fontSize: 20),
        
        // Body text (Readable Serif or Slab Serif)
        bodyLarge: GoogleFonts.libreBaskerville(color: steamWhite, fontSize: 18),
        bodyMedium: GoogleFonts.libreBaskerville(color: steamWhite, fontSize: 16),
        bodySmall: GoogleFonts.libreBaskerville(color: brassPrimary.withOpacity(0.8), fontSize: 14),
        
        // Button text
        labelLarge: GoogleFonts.rye(color: leatherDark, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: brassPrimary,
        size: 28,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: mahoganyLight,
        titleTextStyle: GoogleFonts.rye(color: brassPrimary, fontSize: 24),
        contentTextStyle: GoogleFonts.libreBaskerville(color: steamWhite, fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: brassPrimary, width: 3),
        ),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: brassDark,
        thickness: 1,
      ), colorScheme: const ColorScheme.dark(
        primary: brassPrimary,
        secondary: verdigris,
        surface: mahoganyLight,
        // background: mahoganyDark, // Deprecated in recent Flutter but safe to omit if surface covers it
        error: Color(0xFFCF6679),
        onPrimary: leatherDark,
        onSecondary: leatherDark,
        onSurface: steamWhite,
      ),
    );
  }
}
