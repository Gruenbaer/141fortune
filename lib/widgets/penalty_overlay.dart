import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PenaltyOverlay extends StatefulWidget {
  final int points; // e.g. -2, -15
  final Offset targetPosition; // Center of the target score
  final VoidCallback onImpact; // Trigger external effects (shake, score update)
  final VoidCallback onFinish; // Cleanup

  const PenaltyOverlay({
    super.key,
    required this.points,
    required this.targetPosition,
    required this.onImpact,
    required this.onFinish,
  });

  @override
  State<PenaltyOverlay> createState() => _PenaltyOverlayState();
}

class _PenaltyOverlayState extends State<PenaltyOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Sequence:
    // 0-30%: Zoom In (Center)
    // 30-60%: Hold
    // 60-100%: Fly to Target & Shrink

    // 1. Zoom In (0.0 -> 3.0)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 4.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 30),
      TweenSequenceItem(tween: ConstantTween(4.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.5).chain(CurveTween(curve: Curves.easeInQuad)), weight: 40),
    ]).animate(_controller);

    // 2. Opacity
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 10),
    ]).animate(_controller);

    // 3. Position (Center -> Target)
    // We update this in build using LayoutBuilder to know screen center
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Calculate layout dependent animations here if strictly needed,
    // but we can do it in build with LayoutBuilder for the start position (center).
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        
        // Setup Position Animation relative to screen size
        // 0-60%: Center
        // 60-100%: Fly to Target
        
        Animation<Offset> flyAnimation = TweenSequence<Offset>([
          TweenSequenceItem(tween: ConstantTween(center), weight: 60),
          TweenSequenceItem(
            tween: Tween(begin: center, end: widget.targetPosition)
                .chain(CurveTween(curve: Curves.easeInExpo)), 
            weight: 40
          ),
        ]).animate(_controller);

        // Start animation once we have layout
        if (!_controller.isAnimating && _controller.value == 0) {
          _controller.forward().then((_) {
             widget.onImpact();
             widget.onFinish();
          });
        }

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned(
              left: flyAnimation.value.dx - 100, // Center the 200-width widget
              top: flyAnimation.value.dy - 50,   // Center the 100-height widget
              width: 200,
              height: 100,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Center(
                    child: Text(
                      '${widget.points}',
                      style: GoogleFonts.nunito(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.redAccent,
                        shadows: [
                          const Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2)),
                          BoxShadow(color: Colors.red.withOpacity(0.8), blurRadius: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
