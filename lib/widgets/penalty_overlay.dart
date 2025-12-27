import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PenaltyOverlay extends StatefulWidget {
  final int points; // e.g. -2, -15
  final String? message; // Optional message (e.g. "Break Foul!")
  final Offset targetPosition; // Center of the target score
  final VoidCallback onImpact; // Trigger external effects (shake, score update)
  final VoidCallback onFinish; // Cleanup

  const PenaltyOverlay({
    super.key,
    required this.points,
    this.message,
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

    // 1. Zoom In (0.0 -> 3.0) - Fast entry (0-30%)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 4.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 30),
      TweenSequenceItem(tween: ConstantTween(4.0), weight: 10), // Short hold
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.5).chain(CurveTween(curve: Curves.easeInQuad)), weight: 60), // Shrink while flying
    ]).animate(_controller);

    // 2. Opacity - Stay visible!
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 90), // Stay full opacity until end/impact
    ]).animate(_controller);

    // 3. Position (Center -> Target)
    // We update this in build using LayoutBuilder to know screen center
  }
// ... (skip down to build)
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        
        // Setup Position Animation relative to screen size
        // 0-30%: Center (Intro)
        // 30-100%: Fly to Target
        
        Animation<Offset> flyAnimation = TweenSequence<Offset>([
          TweenSequenceItem(tween: ConstantTween(center), weight: 30),
          TweenSequenceItem(
            tween: Tween(begin: center, end: widget.targetPosition)
                .chain(CurveTween(curve: Curves.easeInOutCubic)), // Smooth flight
            weight: 70
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
              left: flyAnimation.value.dx - 200, // Center the 400-width widget
              top: flyAnimation.value.dy - 50,   // Center the 100-height widget
              width: 400,
              height: 120, // Increased height for message + score
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Center(
                    child: Material(
                      type: MaterialType.transparency,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.message != null)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.message!,
                                 textAlign: TextAlign.center,
                               style: GoogleFonts.nunito(
                                 fontSize: 24,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.redAccent,
                                 shadows: [
                                   const Shadow(blurRadius: 5, color: Colors.black, offset: Offset(1, 1)),
                                 ],
                               ),
                            ),),
                          Text(
                            '${widget.points}',
                            style: GoogleFonts.nunito(
                              fontSize: 48, // Slightly larger
                              fontWeight: FontWeight.w900,
                              color: Colors.redAccent, // Keep Red for penalty visuals
                              shadows: [
                                const Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2)),
                                BoxShadow(color: Colors.red.withOpacity(0.8), blurRadius: 20),
                              ],
                            ),
                          ),
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
