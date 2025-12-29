import 'package:flutter/material.dart';
import '../theme/fortune_theme.dart';

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
      duration: const Duration(milliseconds: 1500), // Simpler, faster animation
       vsync: this,
    );

    // Zoom in, Pause, Zoom out
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.elasticOut)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.2), weight: 60), // Longer hold
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 2.0), weight: 20), // Zoom out huge at end
    ]).animate(_controller);

    // Fade In, Hold, Fade Out
    _opacityAnimation = TweenSequence([
       TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
       TweenSequenceItem(tween: ConstantTween(1.0), weight: 70), // Longer hold
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3), // Transparent per user request
                  borderRadius: BorderRadius.circular(20),
                  // border: Border.all(color: Colors.amber.shade700, width: 2), // Removed per user request
                  boxShadow: [
                     const BoxShadow(color: Colors.black87, blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: Builder(
                  builder: (context) {
                    final colors = FortuneColors.of(context);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon removed per user request
                        const SizedBox(height: 12),
                        Text(
                          widget.type,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 32,
                            color: colors.primaryBright,
                            shadows: [
                              Shadow(blurRadius: 10, color: colors.accent, offset: const Offset(0, 0)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
