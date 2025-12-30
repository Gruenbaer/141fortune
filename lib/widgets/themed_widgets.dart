import 'package:flutter/material.dart';
import 'dart:math' as math;
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
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? textColor;
  final List<Color>? backgroundGradientColors;

  const ThemedButton({
    super.key,
    this.label,
    this.child,
    this.onPressed,
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
  late int _seed; // Stable seed for randomizing decorations

  @override
  void initState() {
    super.initState();
    _seed = math.Random().nextInt(100000); 
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
    final isEnabled = widget.onPressed != null;
    
    return GestureDetector(
      onTapDown: isEnabled ? (_) => _controller.forward() : null,
      onTapUp: isEnabled ? (_) {
        _controller.reverse();
        widget.onPressed?.call();
      } : null,
      onTapCancel: isEnabled ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          constraints: const BoxConstraints(maxWidth: 400, minHeight: 60), // Reduced minHeight, removed maxHeight
          child: CustomPaint(
            painter: colors.themeId == 'cyberpunk' 
                ? CyberpunkFramePainter(colors) 
                : (colors.themeId == 'ghibli' 
                    ? GhibliFramePainter(colors, seed: _seed) 
                    : BrassFramePainter(colors)),
            child: Container(
              // Inner content area
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              alignment: Alignment.center, // Strictly center the child content
              decoration: colors.themeId == 'ghibli' 
                  ? null // Hand-painted by GhibliFramePainter!
                  : BoxDecoration(
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



class GhibliFramePainter extends CustomPainter {
  final FortuneColors colors;
  final int seed;
  
  GhibliFramePainter(this.colors, {required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    // SEEDED RANDOM: Ensure consistent look for this specific button instance
    final random = math.Random(seed);
    
    final charcoal = const Color(0xFF4A4844);
    
    // 1. Organic Shape (Slightly irregular Pill)
    // To look hand-drawn, we use a Path rather than perfect RRect
    final path = Path();
    final h = size.height;
    final w = size.width;
    
    // Add subtle wobble to the shape based on seed
    final wobble1 = (random.nextDouble() - 0.5) * h * 0.1;
    final wobble2 = (random.nextDouble() - 0.5) * h * 0.1;

    // Start Left Center
    path.moveTo(0, h / 2);
    
    // Top Left Corner (Slightly bulging)
    path.cubicTo(0, h * 0.1, h * 0.1, 0, h/2, 0);
    
    // Top Line (Slightly dip)
    path.cubicTo(w * 0.3, h * 0.05, w * 0.7, -h * 0.02, w - h/2, 0);
    
    // Top Right Corner
    path.cubicTo(w - h * 0.1, 0, w, h * 0.1, w, h/2);
    
    // Bottom Line (Slightly curve up)
    path.cubicTo(w, h * 0.9, w - h * 0.1, h, w - h/2, h);
    path.cubicTo(w * 0.7, h * 0.98, w * 0.3, h * 1.02, h/2, h);
    
    // Bottom Left Corner
    path.cubicTo(h * 0.1, h, 0, h * 0.9, 0, h/2);
    path.close();

    // 2. Fill (Watercolor style)
    final fillPaint = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.fill;
    
    // Drop shadow (Sketchy - Offset)
    canvas.drawPath(path.shift(const Offset(3, 4)), Paint()..color = charcoal.withOpacity(0.15)); // Soft shadow
    
    // Main Body
    canvas.drawPath(path, fillPaint);
    
    // Watercolor Highlight (Soft Blobs)
    canvas.save();
    canvas.clipPath(path);
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(w * 0.2, h * 0.3), h * 0.8, highlightPaint);
    canvas.drawCircle(Offset(w * 0.8, h * 0.6), h * 0.6, highlightPaint);
    canvas.restore();


    // 3. Sketchy Border (Charcoal)
    final borderPaint = Paint()
      ..color = charcoal.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    canvas.drawPath(path, borderPaint);
    
    // 4. Leaves (Hand drawn accent)
    _drawLeaves(canvas, size, borderPaint, fillPaint);
  }
  
  void _drawLeaves(Canvas canvas, Size size, Paint borderPaint, Paint baseFillPaint) {
    // Leaf Paint (Vibrant Natural Green)
    final leafFillPaint = Paint()
      ..color = const Color(0xFF8CD47E) // Lighter/Brighter than the button base
      ..style = PaintingStyle.fill;
      
    // 1. LEFT SPROUT (Double Leaf) -- Growing from the left vertical edge
    canvas.save();
    // Move to roughly where the visual "start" of the left curve is 
    // The path starts at (0, h/2) and curves up. 
    // We want to sprout around (0, h*0.3).
    canvas.translate(-2, size.height * 0.35); 
    canvas.rotate(-0.5); // Tilt outwards
    
    // Scale up significantly
    const double scale = 1.8;
    canvas.scale(scale);

    // Stem (merging with border)
    final stemPath = Path();
    stemPath.moveTo(0, 0); 
    stemPath.quadraticBezierTo(-5, -5, -8, -15); // Main stem up
    
    // Leaf A (Top)
    final leafA = Path();
    leafA.moveTo(-8, -15);
    leafA.quadraticBezierTo(-15, -25, -5, -35); // Left curve
    leafA.quadraticBezierTo(5, -20, -8, -15);   // Right curve
    
    // Leaf B (Side)
    final leafB = Path();
    leafB.moveTo(-6, -10); // Branch off stem
    leafB.quadraticBezierTo(-15, -5, -20, 5); 
    leafB.quadraticBezierTo(-10, 8, -6, -10);
    
    // Draw Leaf Fills
    canvas.drawPath(leafA, leafFillPaint);
    canvas.drawPath(leafB, leafFillPaint);
    
    // Draw Leaf Borders (Sketchy)
    canvas.drawPath(leafA, borderPaint);
    canvas.drawPath(leafB, borderPaint);
    
    // Draw Stem (Thicker connection)
    canvas.drawPath(stemPath, borderPaint..strokeWidth = 2);
    
    // Little vein details
    canvas.drawPath(Path()..moveTo(-8, -15)..lineTo(-6, -25), borderPaint..strokeWidth = 1);
    canvas.drawPath(Path()..moveTo(-6, -10)..lineTo(-15, 0), borderPaint..strokeWidth = 1);

    canvas.restore();
    
    
    // 2. RIGHT ACCENT (Single Leaf) -- Wrapping onto the bottom right
    canvas.save();
    canvas.translate(size.width - 5, size.height * 0.7); // Bottom right edge
    canvas.rotate(1.0); // Pointing down/out
    canvas.scale(1.5);
    
    final leafC = Path();
    leafC.moveTo(0, 0); // Sprout point
    leafC.quadraticBezierTo(10, 0, 15, 10);
    leafC.quadraticBezierTo(0, 15, 0, 0);
    
    canvas.drawPath(leafC, leafFillPaint);
    canvas.drawPath(leafC, borderPaint..strokeWidth = 1.5);
    
    // Stem connection
    canvas.drawPath(Path()..moveTo(0, 0)..lineTo(-5, 0), borderPaint..strokeWidth = 2);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
