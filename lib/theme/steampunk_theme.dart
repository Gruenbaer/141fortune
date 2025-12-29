import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'fortune_theme.dart';

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
    final colors = const FortuneColors(
      themeId: 'steampunk',
      backgroundMain: mahoganyDark,
      backgroundCard: mahoganyLight,
      primary: brassPrimary,
      primaryDark: brassDark,
      primaryBright: brassBright,
      secondary: verdigris,
      accent: amberGlow,
      textMain: steamWhite,
      textContrast: leatherDark,
      backgroundImagePath: 'assets/images/ui/background.png',
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: brassPrimary,
      scaffoldBackgroundColor: mahoganyDark,
      
      extensions: [colors],

      
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
        titleTextStyle: GoogleFonts.crimsonPro(
          fontSize: 30, // Slightly larger to match presence
          fontWeight: FontWeight.w800, // Extra Bold for Title
          color: brassPrimary,
          shadows: [
            const Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
          ],
        ),
        iconTheme: const IconThemeData(color: brassPrimary),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        // Headlines (Victorian style -> Classic Serif)
        displayLarge: GoogleFonts.crimsonPro(color: brassPrimary, fontSize: 36, fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.crimsonPro(color: brassPrimary, fontSize: 28, fontWeight: FontWeight.w700),
        displaySmall: GoogleFonts.crimsonPro(color: brassPrimary, fontSize: 24, fontWeight: FontWeight.w700),
        
        // Body text (Readable Serif or Slab Serif)
        bodyLarge: GoogleFonts.libreBaskerville(color: steamWhite, fontSize: 18),
        bodyMedium: GoogleFonts.libreBaskerville(color: steamWhite, fontSize: 16),
        bodySmall: GoogleFonts.libreBaskerville(color: brassPrimary.withOpacity(0.8), fontSize: 14),
        
        // Button text (Condensed, Bold Serif)
        labelLarge: GoogleFonts.crimsonPro(
            color: leatherDark, 
            fontSize: 20, // Slightly larger than Rye's 18 as it's more compact
            fontWeight: FontWeight.w900, 
            letterSpacing: 0.5 // Reduce spacing slightly
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: brassPrimary,
        size: 28,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: mahoganyLight,
        titleTextStyle: GoogleFonts.crimsonPro(color: brassPrimary, fontSize: 26, fontWeight: FontWeight.bold),
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
