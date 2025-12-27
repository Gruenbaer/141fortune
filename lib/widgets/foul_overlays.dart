import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

/// Message Overlay: Fades in/out at screen center
class FoulMessageOverlay extends StatefulWidget {
  final String message; // "Foul!", "Break Foul!", "Triple Foul!"
  final VoidCallback onFinish;

  const FoulMessageOverlay({
    super.key,
    required this.message,
    required this.onFinish,
  });

  @override
  State<FoulMessageOverlay> createState() => _FoulMessageOverlayState();
}

class _FoulMessageOverlayState extends State<FoulMessageOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Scale: Zoom in (reduced for readability)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.5).chain(CurveTween(curve: Curves.elasticOut)), weight: 40),
      TweenSequenceItem(tween: ConstantTween(1.5), weight: 60),
    ]).animate(_controller);

    // Opacity: Fade in, hold, fade out
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onFinish());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Center(
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    widget.message.replaceAll('Triple Foul', 'Triple\nFoul'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      shadows: [
                        const Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Points Overlay: Fades in above score, fades out, triggers score update
class FoulPointsOverlay extends StatefulWidget {
  final int points; // -1, -2, -15
  final Offset targetPosition; // Position above player score
  final VoidCallback onImpact; // Trigger score update when animation completes
  final VoidCallback onFinish;

  const FoulPointsOverlay({
    super.key,
    required this.points,
    required this.targetPosition,
    required this.onImpact,
    required this.onFinish,
  });

  @override
  State<FoulPointsOverlay> createState() => _FoulPointsOverlayState();
}

class _FoulPointsOverlayState extends State<FoulPointsOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  final _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Opacity: Fade in, hold, fade out quickly
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20), // Faster fade out
    ]).animate(_controller);

    // Scale: Expand and shrink animation (simplified to avoid assertion errors)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.5), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward().then((_) {
      widget.onImpact(); // Trigger score update and shake
      widget.onFinish();
    });
    
    // Play sound for negative points
    if (widget.points < 0) {
      _audioPlayer.play(AssetSource('sounds/beeboo.wav'));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.targetPosition.dx - 40, // Centered
          top: widget.targetPosition.dy - 16, // Align with score
          child: IgnorePointer(
            child: ClipRect(
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 200, maxHeight: 100),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                          '${widget.points >= 0 ? "+" : ""}${widget.points}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 84, // Double size (was 42)
                            fontWeight: FontWeight.w900,
                            color: widget.points >= 0 ? Colors.greenAccent : Colors.redAccent,
                            shadows: [
                              const Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
