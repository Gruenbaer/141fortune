import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/fortune_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

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
  // late Animation<Offset> _shakeAnimation; // REMOVED - causing overflow flashing
  late Animation<double> _scaleAnimation;
  
  // UI Logic: Visual Score (delayed update)
  late int _visualScore;
  Timer? _safetyTimer;
  
  // Key for Animation Targeting
  final GlobalKey scoreKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _effectController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    // Shake: REMOVED - causing overflow flashing
    // _shakeAnimation = TweenSequence<Offset>([
    //   TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-5, 0)), weight: 1),
    //   TweenSequenceItem(tween: Tween(begin: const Offset(-5, 0), end: const Offset(5, 0)), weight: 2),
    //   TweenSequenceItem(tween: Tween(begin: const Offset(5, 0), end: const Offset(-5, 0)), weight: 2),
    //   TweenSequenceItem(tween: Tween(begin: const Offset(-5, 0), end: const Offset(5, 0)), weight: 2),
    //   TweenSequenceItem(tween: Tween(begin: const Offset(5, 0), end: Offset.zero), weight: 1),
    // ]).animate(CurvedAnimation(parent: _effectController, curve: Curves.easeInOut));
    
    // Scale: Bump up
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1), // Grow
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 2), // Shrink back
    ]).animate(CurvedAnimation(
      parent: _effectController,
      curve: Curves.elasticOut,
    ));
    
    _visualScore = widget.player.score; // Init with current
  }

  @override
  void didUpdateWidget(PlayerPlaque oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.player.score != oldWidget.player.score) {
      if (widget.player.score < oldWidget.player.score) {
        // Score Dropped (Penalty?) -> DEFER UPDATE
        // We wait for triggerPenaltyImpact() to call sync.
        
        // Safety: If animation never comes, sync after 3s
        _safetyTimer?.cancel();
        _safetyTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && _visualScore != widget.player.score) {
            setState(() {
              _visualScore = widget.player.score;
            });
          }
        });
      } else {
        // Score Increased (Pot/Points) -> Update Immediately (or animate differently later)
        if (_visualScore != widget.player.score) {
          setState(() {
            _visualScore = widget.player.score;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _effectController.dispose();
    super.dispose();
  }

  // Exposed method to trigger effect AND update score
  void triggerPenaltyImpact() {
    _effectController.forward(from: 0.0);
    
    // Award the score (Sync visual to actual)
    if (_visualScore != widget.player.score) {
      setState(() {
        _visualScore = widget.player.score;
      });
    }
    _safetyTimer?.cancel();
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
        // Score Color: Always Golden (no flash)
        final nameColor = isActive ? colors.primaryBright : colors.primary;
        const scoreColor = Color(0xFFFFD700); // Standard Gold always

        return Container(
            // No fixed height constraints - controlled by Parent IntrinsicHeight
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
                    // Penalty Glow removed (no flash)
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
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Text(
                            key: scoreKey,
                            '$_visualScore',
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
                          ),),
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
          );
      }
    );
  }
}
