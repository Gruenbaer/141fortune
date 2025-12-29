import 'package:flutter/material.dart';
import '../theme/steampunk_theme.dart'; // Keep for legacy constants if needed, or remove?
import '../theme/fortune_theme.dart';

class ThemedBackground extends StatelessWidget {
  final Widget child;

  const ThemedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = FortuneColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundMain, 
        image: colors.backgroundImagePath != null ? DecorationImage(
          image: AssetImage(colors.backgroundImagePath!),
          fit: BoxFit.cover,
          colorFilter: const ColorFilter.mode(
            Colors.black38,
            BlendMode.darken,
          ),
        ) : null,
      ),
      child: SafeArea(child: child),
    );
  }
}

class ThemedButton extends StatefulWidget {
  final String? label;
  final Widget? child;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? textColor;
  final List<Color>? backgroundGradientColors;

  const ThemedButton({
    super.key,
    this.label,
    this.child,
    required this.onPressed,
    this.icon,
    this.textColor,
    this.backgroundGradientColors,
  }) : assert(label != null || child != null, 'Label or Child must be provided');

  @override
  State<ThemedButton> createState() => _ThemedButtonState();
}

class _ThemedButtonState extends State<ThemedButton> with SingleTickerProviderStateMixin {
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
    final colors = FortuneColors.of(context);
    
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
          constraints: const BoxConstraints(maxWidth: 400, minHeight: 60), // Reduced minHeight, removed maxHeight
          child: CustomPaint(
            painter: colors.themeId == 'cyberpunk' 
                ? CyberpunkFramePainter(colors) 
                : BrassFramePainter(colors),
            child: Container(
              // Inner content area
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              alignment: Alignment.center, // Strictly center the child content
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.backgroundGradientColors ?? [
                    colors.backgroundCard.withOpacity(0.8),
                    colors.backgroundCard,
                  ],
                ),
                // Cyberpunk uses cut corners (Beveled), Steampunk uses Rounded
                borderRadius: colors.themeId == 'cyberpunk' 
                    ? BorderRadius.zero 
                    : BorderRadius.circular(12),
                
                // For Cyberpunk, we might want a clipPath for cut corners, but for now simple box
                border: colors.themeId == 'cyberpunk' 
                    ? Border.all(color: colors.primary.withOpacity(0.3)) 
                    : null,
                
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: widget.child ?? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center, // Ensure vertical centering
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon, 
                      color: widget.textColor ?? colors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      widget.label?.toUpperCase() ?? '',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: widget.textColor ?? const Color(0xFFF0F0F0), // Near white for contrast
                        letterSpacing: 0.5, // Reduced from 1.0 for space saving
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8), // Stronger shadow
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                        fontWeight: FontWeight.w900, // Black weight
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

// Custom painter (Brass for Steampunk)
class BrassFramePainter extends CustomPainter {
  final FortuneColors colors;
  
  BrassFramePainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    // ... existing brass paint logic ...
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    
    // Outer shadow
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    
    // Frame Gradient
    final framePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colors.primaryBright,
          colors.primary,
          colors.primaryDark,
          colors.primary,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(rect);
    
    canvas.drawRRect(rrect, framePaint);
    
    // Dark inner border for depth
    final innerRect = rect.deflate(4);
    final innerRRect = RRect.fromRectAndRadius(innerRect, const Radius.circular(14));
    canvas.drawRRect(
      innerRRect,
      Paint()
        ..color = colors.backgroundMain
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    
    // Highlight edge
    final highlightPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        rect.deflate(2),
        const Radius.circular(15),
      ));
    
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = colors.primaryBright.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
      );
      
      // Rivets
      _drawRivet(canvas, const Offset(12, 12));
      _drawRivet(canvas, Offset(size.width - 12, 12));
      _drawRivet(canvas, Offset(12, size.height - 12));
      _drawRivet(canvas, Offset(size.width - 12, size.height - 12));
    }
    
    void _drawRivet(Canvas canvas, Offset center) {
      canvas.drawCircle(center, 4, Paint()..color = colors.primaryDark..style = PaintingStyle.fill);
      canvas.drawCircle(center.translate(-0.5, -0.5), 4, Paint()..shader = RadialGradient(colors: [colors.primaryBright.withOpacity(0.8), Colors.transparent], stops: const [0.3, 1.0]).createShader(Rect.fromCircle(center: center, radius: 4)));
      canvas.drawLine(center.translate(-2, 0), center.translate(2, 0), Paint()..color = Colors.black.withOpacity(0.7)..strokeWidth = 1..strokeCap = StrokeCap.round);
    }
  
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Tech/HUD Painter for Cyberpunk
class CyberpunkFramePainter extends CustomPainter {
  final FortuneColors colors;
  
  CyberpunkFramePainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Cut corners (Chamfered)
    const double cut = 12.0;
    
    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width - cut, 0)
      ..lineTo(size.width, cut)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(cut, size.height)
      ..lineTo(0, size.height - cut)
      ..lineTo(0, cut)
      ..close();
      
    // 1. Fill Background (Dark Matrix mostly handled by container, but frame needs body)
    // Actually we strictly paint the border frame here.
    
    // 2. Neon Border Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4), // Glow
    );
    
    // 3. Sharp Neon Border
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    
    // 4. Accent Corners (Thicker lines at corners)
    final cornerPaint = Paint()
      ..color = colors.secondary // Magenta accents
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
      
    // Top Left
    canvas.drawPath(Path()..moveTo(0, cut + 10)..lineTo(0, cut)..lineTo(cut, 0)..lineTo(cut + 10, 0), cornerPaint);
    // Bottom Right
    canvas.drawPath(Path()..moveTo(size.width, size.height - cut - 10)..lineTo(size.width, size.height - cut)..lineTo(size.width - cut, size.height)..lineTo(size.width - cut - 10, size.height), cornerPaint);
    
    // 5. Tech Bits (Decorations)
    final decorPaint = Paint()..color = colors.primary.withOpacity(0.5)..style = PaintingStyle.fill;
    // Small rects
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 20, size.height - 4, 40, 2), decorPaint);
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 20, 2, 40, 2), decorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
