

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
@immutable
class FortuneColors extends ThemeExtension<FortuneColors> {
  final String themeId; // 'steampunk' or 'cyberpunk'
  final Color backgroundMain;
  final Color backgroundCard;
  final Color primary;
  final Color primaryDark;
  final Color primaryBright;
  final Color secondary;
  final Color accent;
  final Color textMain;
  final Color textContrast;
  final String? backgroundImagePath; // Optional background image asset path

  const FortuneColors({
    required this.themeId,
    required this.backgroundMain,
    required this.backgroundCard,
    required this.primary,
    required this.primaryDark,
    required this.primaryBright,
    required this.secondary,
    required this.accent,
    required this.textMain,
    required this.textContrast,
    this.backgroundImagePath,
  });

  // Helper to access colors easily
  static FortuneColors of(BuildContext context) {
    return Theme.of(context).extension<FortuneColors>()!;
  }

  @override
  FortuneColors copyWith({
    String? themeId,
    Color? backgroundMain,
    Color? backgroundCard,
    Color? primary,
    Color? primaryDark,
    Color? primaryBright,
    Color? secondary,
    Color? accent,
    Color? textMain,
    Color? textContrast,
    String? backgroundImagePath,
  }) {
    return FortuneColors(
      themeId: themeId ?? this.themeId,
      backgroundMain: backgroundMain ?? this.backgroundMain,
      backgroundCard: backgroundCard ?? this.backgroundCard,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryBright: primaryBright ?? this.primaryBright,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      textMain: textMain ?? this.textMain,
      textContrast: textContrast ?? this.textContrast,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
    );
  }

  @override
  FortuneColors lerp(ThemeExtension<FortuneColors>? other, double t) {
    if (other is! FortuneColors) return this;
    // Don't lerp IDs, just switch at 50%
    return FortuneColors(
      themeId: t < 0.5 ? themeId : other.themeId,
      backgroundMain: Color.lerp(backgroundMain, other.backgroundMain, t)!,
      backgroundCard: Color.lerp(backgroundCard, other.backgroundCard, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryBright: Color.lerp(primaryBright, other.primaryBright, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textMain: Color.lerp(textMain, other.textMain, t)!,
      textContrast: Color.lerp(textContrast, other.textContrast, t)!,
      backgroundImagePath: t < 0.5 ? backgroundImagePath : other.backgroundImagePath,
    );
  }
}

class CyberpunkTheme {
  // Cyberpunk Palette
  static const Color blackVoid = Color(0xFF020408);
  static const Color darkMatrix = Color(0xFF0A1020);
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color darkCyan = Color(0xFF008088);
  static const Color brightCyan = Color(0xFFD0FFFF);
  static const Color neonMagenta = Color(0xFFFF00FF);
  static const Color neonGreen = Color(0xFF39FF14); // Acid Green
  static const Color textWhite = Color(0xFFE0E0E0);
  static const Color textBlack = Color(0xFF050505);

  static ThemeData get themeData {
    final colors = const FortuneColors(
      themeId: 'cyberpunk',
      backgroundMain: blackVoid,
      backgroundCard: darkMatrix,
      primary: neonCyan,
      primaryDark: darkCyan,
      primaryBright: brightCyan,
      secondary: neonMagenta,
      accent: neonGreen,
      textMain: textWhite,
      textContrast: textBlack,
      backgroundImagePath: null, // Cyberpunk uses code-drawn background or solid color
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: neonCyan,
      scaffoldBackgroundColor: blackVoid,
      
      extensions: [colors], // <--- Critical for access

      cardTheme: CardThemeData(
        color: darkMatrix,
        elevation: 8,
        shadowColor: neonCyan.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Sharper corners for Cyberpunk
          side: const BorderSide(color: darkCyan, width: 2),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: blackVoid,
        foregroundColor: neonCyan,
        centerTitle: true,
        titleTextStyle: GoogleFonts.crimsonPro(
          fontSize: 30,
          color: neonCyan,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5, // Reduced spacing
          shadows: [
            Shadow(blurRadius: 10, color: neonCyan.withOpacity(0.8), offset: Offset(0, 0)),
          ],
        ),
        iconTheme: const IconThemeData(color: neonCyan),
      ),

      textTheme: TextTheme(
        // Headlines: Serif instead of Orbitron, but kept bold/neon
        displayLarge: GoogleFonts.crimsonPro(color: neonCyan, fontSize: 36, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.crimsonPro(color: neonCyan, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.crimsonPro(color: neonCyan, fontSize: 24, fontWeight: FontWeight.bold),
        
        // Body: LibreBaskerville for consistency ("normal serif")
        bodyLarge: GoogleFonts.libreBaskerville(color: textWhite, fontSize: 18),
        bodyMedium: GoogleFonts.libreBaskerville(color: textWhite, fontSize: 16),
        bodySmall: GoogleFonts.libreBaskerville(color: neonCyan.withOpacity(0.8), fontSize: 14),
        
        // Buttons
        labelLarge: GoogleFonts.crimsonPro(
            color: textBlack, 
            fontSize: 20, 
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5
        ),
      ),
      
      iconTheme: const IconThemeData(
        color: neonCyan,
        size: 28,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: darkMatrix,
        titleTextStyle: GoogleFonts.crimsonPro(color: neonCyan, fontSize: 26, fontWeight: FontWeight.bold),
        contentTextStyle: GoogleFonts.libreBaskerville(color: textWhite, fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: neonCyan, width: 2),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: darkCyan,
        thickness: 1,
      ),
      
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonMagenta,
        surface: darkMatrix,
        error: Color(0xFFFF3333),
        onPrimary: textBlack,
        onSecondary: textBlack,
        onSurface: textWhite,
      ),
    );
  }
}
