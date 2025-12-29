import 'package:flutter/material.dart';

/// Shield overlay that fades in/out when Safe Mode is activated
class SafeShieldOverlay extends StatefulWidget {
  final VoidCallback onFinish;

  const SafeShieldOverlay({
    super.key,
    required this.onFinish,
  });

  @override
  State<SafeShieldOverlay> createState() => _SafeShieldOverlayState();
}

class _SafeShieldOverlayState extends State<SafeShieldOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Opacity: Fade in, hold, fade out
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 30),
      TweenSequenceItem(tween: ConstantTween(0.7), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 30),
    ]).animate(_controller);

    // Scale: Gentle pulse
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 30),
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Icon(
                    Icons.shield,
                    size: 220,
                    color: Colors.green.withOpacity(0.3),
                  ),
                  // Main shield
                  Icon(
                    Icons.shield,
                    size: 200,
                    color: Colors.green.shade400,
                  ),
                  // Inner highlight
                  Icon(
                    Icons.shield,
                    size: 160,
                    color: Colors.green.shade200,
                  ),
                  // Center emblem
                  Icon(
                    Icons.verified_user,
                    size: 80,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
