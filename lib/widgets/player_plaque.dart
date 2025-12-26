import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/fortune_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerPlaque extends StatefulWidget {
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
  State<PlayerPlaque> createState() => PlayerPlaqueState();
}

class PlayerPlaqueState extends State<PlayerPlaque> with SingleTickerProviderStateMixin {
  late AnimationController _effectController;
  late Animation<Offset> _shakeAnimation;
  late Animation<Color?> _flashAnimation;

  @override
  void initState() {
    super.initState();
    _effectController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    // Shake: Sine wave to move left/right
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-5, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-5, 0), end: const Offset(5, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(5, 0), end: const Offset(-5, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(-5, 0), end: const Offset(5, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(5, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _effectController, curve: Curves.easeInOut));
    
    // Flash: Red tint
    _flashAnimation = ColorTween(
      begin: null, 
      end: Colors.redAccent
    ).animate(CurvedAnimation(
      parent: _effectController, 
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn) // Flash fast, fade slower
    ));
  }

  @override
  void dispose() {
    _effectController.dispose();
    super.dispose();
  }

  // Exposed method to trigger effect
  void triggerPenaltyImpact() {
    _effectController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = FortuneColors.of(context);
    final isActive = widget.player.isActive;

    // Check theme for shape
    final isCyberpunk = colors.themeId == 'cyberpunk';
    
    // Determine Text Color (Normal or Flash)
    // We animate a custom color override.
    return AnimatedBuilder(
      animation: _effectController,
      builder: (context, child) {
        final flashColor = _flashAnimation.value;
        // If flashing, use red. Else use normal theme logic.
        final nameColor = flashColor ?? (isActive ? colors.primaryBright : colors.primary);
        final scoreColor = flashColor ?? colors.accent;

        return Transform.translate(
          offset: _shakeAnimation.value,
          child: SizedBox(
            height: 115, // Fixed height to prevent resizing
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: ShapeDecoration(
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
                  // Penalty Glow!
                  if (flashColor != null)
                     BoxShadow(
                      color: Colors.red.withOpacity(0.8),
                      blurRadius: 20,
                      spreadRadius: 5,
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
                    widget.isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                children: [
                  // Player Name
                  Text(
                    widget.player.name.toUpperCase(),
                    style: GoogleFonts.nunito( // Rounded font
                      textStyle: theme.textTheme.labelLarge,
                      color: nameColor,
                      letterSpacing: 1.5,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Score Display (Nixie Tube / Neon)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: widget.isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${widget.player.score}',
                          style: GoogleFonts.nunito(
                            textStyle: theme.textTheme.displayMedium,
                            color: scoreColor,
                            fontSize: 42,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                color: scoreColor,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/ ${widget.raceToScore}',
                          style: GoogleFonts.nunito(
                            textStyle: theme.textTheme.bodyMedium,
                            color: colors.primaryDark,
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        // Foul Indicators (Red X) - Moved to right of score
                        if (widget.player.consecutiveFouls > 0) ...[
                          const SizedBox(width: 12),
                          ...List.generate(widget.player.consecutiveFouls, (index) => 
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Icon(
                                Icons.close, 
                                color: Colors.redAccent, 
                                size: 24,
                                shadows: [
                                  Shadow(color: Colors.red.withOpacity(0.5), blurRadius: 4),
                                ],
                              ),
                            )
                          ),
                        ],
                      ],
                    ),
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
                      'INNING ${widget.player.currentInning}',
                      style: GoogleFonts.nunito(
                        textStyle: theme.textTheme.bodySmall,
                        color: colors.textMain.withOpacity(0.7),
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
