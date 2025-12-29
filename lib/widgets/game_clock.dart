import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../theme/fortune_theme.dart';
import '../theme/steampunk_theme.dart';

class GameClock extends StatelessWidget {
  const GameClock({super.key});

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 0) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = duration.inHours > 0 ? '${duration.inHours}:' : '';
    return "$hours$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final colors = FortuneColors.of(context);
    final isCyberpunk = colors.themeId == 'cyberpunk';
    
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final duration = gameState.elapsedDuration;
        final timeString = _formatDuration(duration);
        final isPaused = gameState.isPaused;

        // --- THEME STYLES ---

        // Steampunk: Brass/Parchment feel
        final steampunkDecor = BoxDecoration(
          color: SteampunkTheme.leatherDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SteampunkTheme.brassDark, width: 2),
          boxShadow: [
            const BoxShadow(
              color: Colors.black54,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        );

        final steampunkTextStyle = GoogleFonts.rye(
          fontSize: 24,
          color: SteampunkTheme.brassBright,
          shadows: [
            const Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
          ],
        );

        // Cyberpunk: Digital/HUD feel
        final cyberpunkDecor = BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          // Cut corners handled by shape if we used ShapeDecoration, but simple box is fine for now
          // Or use a custom painter? Simple border for now.
          border: Border(
            top: BorderSide(color: colors.primary, width: 1),
            bottom: BorderSide(color: colors.primary, width: 1),
          ),
          boxShadow: [
             BoxShadow(
              color: colors.primary.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        );

        final cyberpunkTextStyle = GoogleFonts.orbitron(
          fontSize: 24,
          color: colors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
          shadows: [
             Shadow(blurRadius: 8, color: colors.primary, offset: const Offset(0, 0)),
          ],
        );

        return GestureDetector(
          onTap: gameState.togglePause,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: isCyberpunk ? cyberpunkDecor : steampunkDecor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Icon(
                  Icons.access_time, 
                  color: isCyberpunk ? colors.primary : colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                
                // Time
                Text(
                  timeString,
                  style: isCyberpunk ? cyberpunkTextStyle : steampunkTextStyle,
                ),
                
                const SizedBox(width: 12),
                
                // Pause/Play Indicator
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPaused ? (isCyberpunk ? colors.accent : Colors.orange) : Colors.transparent, 
                      width: 1
                    ),
                  ),
                  child: Icon(
                    isPaused ? Icons.play_arrow : Icons.pause,
                    color: isPaused ? (isCyberpunk ? colors.accent : Colors.orange) : (isCyberpunk ? colors.primaryDark : colors.primaryDark),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
