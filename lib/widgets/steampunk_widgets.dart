import 'package:flutter/material.dart';
import '../theme/steampunk_theme.dart';

class SteampunkBackground extends StatelessWidget {
  final Widget child;

  const SteampunkBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SteampunkTheme.mahoganyDark, // Fallback
        image: DecorationImage(
          image: AssetImage('assets/images/ui/background.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black38, // Darken slightly for readability
            BlendMode.darken,
          ),
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}

class SteampunkButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? textColor;
  final List<Color>? backgroundGradientColors;

  const SteampunkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.textColor,
    this.backgroundGradientColors,
  });

  @override
  State<SteampunkButton> createState() => _SteampunkButtonState();
}

class _SteampunkButtonState extends State<SteampunkButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       duration: const Duration(milliseconds: 100),
       vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          constraints: const BoxConstraints(maxWidth: 400, minHeight: 80, maxHeight: 80),
          child: CustomPaint(
            painter: BrassFramePainter(),
            child: Container(
              // Inner content area (inside the brass frame)
              margin: const EdgeInsets.all(12), // Space for the brass border
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                // Cream/beige background like reference, or custom
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.backgroundGradientColors ?? const [
                    Color(0xFFF5E6D3), // Light cream
                    Color(0xFFE8D4B8), // Darker cream/beige
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                // Inner shadow for depth
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon, 
                      color: widget.textColor ?? SteampunkTheme.leatherDark,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      widget.label.toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: widget.textColor ?? SteampunkTheme.leatherDark,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        shadows: [
                          // Embossed effect
                          Shadow(
                            color: Colors.white.withOpacity(0.5),
                            offset: const Offset(0, 1),
                            blurRadius: 1,
                          ),
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, -1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for ornate brass frame with rivets
class BrassFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    
    // Outer shadow
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    
    // Brass frame gradient (main border)
    final brassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          SteampunkTheme.brassBright,
          SteampunkTheme.brassPrimary,
          SteampunkTheme.brassDark,
          SteampunkTheme.brassPrimary,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(rect);
    
    canvas.drawRRect(rrect, brassPaint);
    
    // Dark inner border for depth
    final innerRect = rect.deflate(4);
    final innerRRect = RRect.fromRectAndRadius(innerRect, const Radius.circular(14));
    canvas.drawRRect(
      innerRRect,
      Paint()
        ..color = const Color(0xFF3D2817)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    
    // Highlight edge on top-left
    final highlightPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        rect.deflate(2),
        const Radius.circular(15),
      ));
    
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = SteampunkTheme.brassBright.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    
    // Corner rivets (decorative bolts)
    _drawRivet(canvas, const Offset(12, 12));
    _drawRivet(canvas, Offset(size.width - 12, 12));
    _drawRivet(canvas, Offset(12, size.height - 12));
    _drawRivet(canvas, Offset(size.width - 12, size.height - 12));
  }
  
  void _drawRivet(Canvas canvas, Offset center) {
    // Outer rivet circle
    canvas.drawCircle(
      center,
      4,
      Paint()
        ..color = SteampunkTheme.brassDark
        ..style = PaintingStyle.fill,
    );
    
    // Highlight
    canvas.drawCircle(
      center.translate(-0.5, -0.5),
      4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SteampunkTheme.brassBright.withOpacity(0.8),
            Colors.transparent,
          ],
          stops: const [0.3, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: 4)),
    );
    
    // Center screw slot
    canvas.drawLine(
      center.translate(-2, 0),
      center.translate(2, 0),
      Paint()
        ..color = Colors.black.withOpacity(0.7)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
