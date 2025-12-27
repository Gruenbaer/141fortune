import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReRackOverlay extends StatefulWidget {
  final String type; // e.g. "14.1 Re-Rack"
  final VoidCallback onFinish;

  const ReRackOverlay({
    super.key,
    required this.type,
    required this.onFinish,
  });

  @override
  State<ReRackOverlay> createState() => _ReRackOverlayState();
}

class _ReRackOverlayState extends State<ReRackOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       duration: const Duration(milliseconds: 2000), // 2 seconds total
       vsync: this,
    );

    // Zoom in, Pause, Zoom out
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.elasticOut)), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 2.0), weight: 30), // Zoom out huge at end
    ]).animate(_controller);

    // Fade In, Hold, Fade Out
    _opacityAnimation = TweenSequence([
       TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
       TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
       TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade700, width: 2),
                  boxShadow: [
                     const BoxShadow(color: Colors.black87, blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.grid_on, color: Colors.amber, size: 48), // Triangle/Rack Icon proxy
                    const SizedBox(height: 12),
                    Text(
                      widget.type,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rye(
                        fontSize: 32,
                        color: Colors.amber.shade100,
                        shadows: [
                          const Shadow(blurRadius: 10, color: Colors.orange, offset: Offset(0, 0)),
                        ],
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
