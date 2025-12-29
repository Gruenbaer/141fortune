import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../theme/fortune_theme.dart';
import '../theme/steampunk_theme.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        if (!gameState.isPaused) return const SizedBox.shrink();

        final colors = FortuneColors.of(context);
        final isCyberpunk = colors.themeId == 'cyberpunk';

        return GestureDetector(
          onTap: gameState.resumeGame,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withOpacity(0.7), // Dim background
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {}, // Trap taps on the box itself? No, tap anywhere resumes per instructions "Close it by tapping anywhere"
              // Wait, instructions: "Close it by tapping anywhere, bit also add a small x."
              // So tapping box should ALSO close it? Or just background?
              // "Close it by tapping anywhere" implies anywhere on screen.
              // So I don't need to trap taps. 
              // But maybe the user wants to read the text? 
              // Usually tapping the "Paused" sign also resumes.
              
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                decoration: isCyberpunk 
                  ? BoxDecoration(
                      color: colors.backgroundCard.withOpacity(0.9),
                      border: Border.all(color: colors.primary, width: 2),
                      boxShadow: [
                        BoxShadow(color: colors.primary.withOpacity(0.5), blurRadius: 20),
                      ],
                      // Cut corners?
                    )
                  : BoxDecoration(
                      color: SteampunkTheme.mahoganyLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SteampunkTheme.brassPrimary, width: 3),
                      boxShadow: [
                        const BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'GAME PAUSED',
                      style: isCyberpunk
                          ? GoogleFonts.orbitron(
                              fontSize: 32,
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              shadows: [Shadow(color: colors.primary, blurRadius: 10)],
                            )
                          : GoogleFonts.rye(
                              fontSize: 32,
                              color: SteampunkTheme.brassPrimary,
                              letterSpacing: 2,
                              shadows: [const Shadow(color: Colors.black, blurRadius: 2, offset: Offset(2, 2))],
                            ),
                    ),
                    const SizedBox(height: 24),
                    // Close Button (X)
                    GestureDetector(
                      onTap: gameState.resumeGame,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCyberpunk ? colors.secondary : SteampunkTheme.brassDark,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.close,
                          color: isCyberpunk ? colors.secondary : SteampunkTheme.brassPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
