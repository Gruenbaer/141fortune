import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/steampunk_theme.dart';
import '../theme/fortune_theme.dart';

class PlayerPlaque extends StatelessWidget {
  final Player player;
  final int raceToScore;
  final bool isLeft;

  const PlayerPlaque({
    super.key,
    required this.player,
    required this.raceToScore,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = FortuneColors.of(context);
    final isActive = player.isActive;

    // Check theme for shape
    final isCyberpunk = colors.themeId == 'cyberpunk';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: colors.backgroundCard,
        shape: isCyberpunk 
            ? BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isActive ? colors.primaryBright : colors.primaryDark,
                  width: isActive ? 3 : 2,
                ),
              )
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isActive ? colors.primaryBright : colors.primaryDark,
                  width: isActive ? 3 : 2,
                ),
              ),
        shadows: [
          // Outer shadow for depth
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
          // Inner Glow for active player
          if (isActive)
            BoxShadow(
              color: colors.accent.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
        // Subtle gradient
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.backgroundCard,
            Color.lerp(colors.backgroundCard, Colors.black, 0.4)!,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // Player Name
          Text(
            player.name.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: isActive ? colors.primaryBright : colors.primary,
              letterSpacing: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          
          // Score Display (Nixie Tube / Neon)
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${player.score}',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: colors.accent,
                  fontSize: 42,
                  shadows: [
                    Shadow(
                      color: colors.accent,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ $raceToScore',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.primaryDark,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Inning Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colors.primaryDark.withOpacity(0.5)),
            ),
            child: Text(
              'INNING ${player.currentInning}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textMain.withOpacity(0.7),
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
