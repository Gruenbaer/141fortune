import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/steampunk_theme.dart';

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
    final isActive = player.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SteampunkTheme.mahoganyLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? SteampunkTheme.brassBright : SteampunkTheme.brassDark,
          width: isActive ? 3 : 2,
        ),
        boxShadow: [
          // Outer shadow for depth
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
          // Inner Glow for active player (Amber lamp effect)
          if (isActive)
            BoxShadow(
              color: SteampunkTheme.amberGlow.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
        // Subtle gradient to resemble metal/wood curve
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SteampunkTheme.mahoganyLight,
            Color.lerp(SteampunkTheme.mahoganyLight, Colors.black, 0.4)!,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // Player Name (Engraved Brass style)
          Text(
            player.name.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: isActive ? SteampunkTheme.brassBright : SteampunkTheme.brassPrimary,
              letterSpacing: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          
          // Score Display (Nixie Tube / Illuminated)
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${player.score}',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: SteampunkTheme.amberGlow,
                  fontSize: 42,
                  shadows: [
                    Shadow(
                      color: SteampunkTheme.amberGlow,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ $raceToScore',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: SteampunkTheme.brassDark,
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
              border: Border.all(color: SteampunkTheme.brassDark.withOpacity(0.5)),
            ),
            child: Text(
              'INNING ${player.currentInning}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: SteampunkTheme.steamWhite.withOpacity(0.7),
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
