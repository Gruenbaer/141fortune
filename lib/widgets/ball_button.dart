import 'package:flutter/material.dart';
import 'dart:math' as math;

class BallButton extends StatelessWidget {
  final int ballNumber;
  final bool isActive;
  final VoidCallback onTap;

  const BallButton({
    super.key,
    required this.ballNumber,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Map ball number to image file name
    String getImagePath() {
      if (ballNumber == 0) {
        return 'assets/images/balls/CueBallRedCircles.png';
      } else {
        // Ball numbers 1-15 map to 01.png - 15.png
        return 'assets/images/balls/${ballNumber.toString().padLeft(2, '0')}.png';
      }
    }

    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        opacity: isActive ? 1.0 : 0.4,
        child: ClipOval(
          child: Image.asset(
            getImagePath(),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to old custom paint if image fails to load
              return CustomPaint(
                size: const Size(60, 60),
                painter: BallPainter(ballNumber: ballNumber),
              );
            },
          ),
        ),
      ),
    );
  }
}

class BallPainter extends CustomPainter {
  final int ballNumber;

  BallPainter({required this.ballNumber});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Drop shadow
    final shadowPath = Path()
      ..addOval(Rect.fromCircle(center: center.translate(0, radius * 0.05), radius: radius));
    canvas.drawShadow(shadowPath, Colors.black.withValues(alpha: 0.4), 2.0, true);

    // Draw ball body
    if (ballNumber == 0) {
      _drawCueBall(canvas, center, radius);
    } else if (ballNumber <= 8) {
      _drawSolidBall(canvas, center, radius, ballNumber);
    } else {
      _drawStripedBall(canvas, center, radius, ballNumber);
    }

    // Draw number circle
    _drawNumberCircle(canvas, center, radius);
    
    // Draw glossy overlay (global reflection)
    _drawGlossyOverlay(canvas, center, radius);
  }

  void _drawCueBall(Canvas canvas, Offset center, double radius) {
    _drawSphereBase(canvas, center, radius, const Color(0xFFF0F0F0));

    // Red dots - 3 dots at 120 degrees
    final dotPaint = Paint()..color = const Color(0xFFD32F2F);
    final dotRadius = radius * 0.08;
    final dotDistance = radius * 0.60; // Slightly closer to center
    
    for (int i = 0; i < 3; i++) {
      // 0, 120, 240 degrees (in radians)
      final angle = (i * 120 - 90) * math.pi / 180; // Start from top (-90)
      final dotCenter = Offset(
        center.dx + dotDistance * math.cos(angle),
        center.dy + dotDistance * math.sin(angle),
      );
      canvas.drawCircle(dotCenter, dotRadius, dotPaint);
    }
  }

  void _drawSolidBall(Canvas canvas, Offset center, double radius, int number) {
    final color = _getBallColor(number);
    _drawSphereBase(canvas, center, radius, color);
  }

  void _drawStripedBall(Canvas canvas, Offset center, double radius, int number) {
    // 1. White base
    _drawSphereBase(canvas, center, radius, const Color(0xFFF9F9F9));

    // 2. Colored stripe (wide)
    final color = _getBallColor(number);
    final stripeHeight = radius * 1.2; // 60% of diameter approximately
    final stripeRect = Rect.fromCenter(
      center: center,
      width: radius * 2,
      height: stripeHeight,
    );

    canvas.save();
    // Clip to ball circle
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
    
    // Draw rect for stripe
    canvas.drawRect(stripeRect, Paint()..color = color);
    
    // Add gradient to stripe to match sphere volume
    final gradient = RadialGradient(
      colors: [color.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.4)],
      stops: const [0.6, 1.0],
      center: const Alignment(-0.2, -0.2),
      radius: 1.0,
    );
    canvas.drawRect(stripeRect, Paint()..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius)));

    canvas.restore();
  }

  // Base sphere rendering with 3D gradient
  void _drawSphereBase(Canvas canvas, Offset center, double radius, Color color) {
    final gradient = RadialGradient(
      colors: [
        _brighten(color, 20), // Highlight area
        color,
        _darken(color, 30),   // Shadow area
      ],
      stops: const [0.1, 0.5, 1.0],
      center: const Alignment(-0.4, -0.4), // Light from top-left
      radius: 1.2,
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  void _drawNumberCircle(Canvas canvas, Offset center, double radius) {
    if (ballNumber == 0) return;

    // White background circle
    final circleRadius = radius * 0.4;
    final circlePaint = Paint()..color = Colors.white;
    
    // Subtle shadow for the number circle
    canvas.drawCircle(
      center.translate(1, 1), 
      circleRadius, 
      Paint()..color = Colors.black.withValues(alpha: 0.2)
    );
    canvas.drawCircle(center, circleRadius, circlePaint);

    // Number text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$ballNumber',
        style: TextStyle(
          color: Colors.black,
          fontSize: radius * 0.45,
          fontWeight: FontWeight.w900,
          fontFamily: 'Arial',
          height: 1.0,
          letterSpacing: -1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textCenter = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textCenter);

    // Underline for 6 and 9
    if (ballNumber == 6 || ballNumber == 9) {
      final underlineWidth = textPainter.width * 0.6;
      final underlineY = textCenter.dy + textPainter.height * 0.85;
      final underlineX = center.dx - underlineWidth / 2;
      
      canvas.drawRect(
        Rect.fromLTWH(underlineX, underlineY, underlineWidth, radius * 0.04),
        Paint()..color = Colors.black,
      );
    }
  }

  void _drawGlossyOverlay(Canvas canvas, Offset center, double radius) {
    // 1. Strong specularity (Top Left)
    final highlightPath = Path()
      ..addOval(Rect.fromCircle(
        center: center.translate(-radius * 0.35, -radius * 0.35), 
        radius: radius * 0.25
      ));
    
    canvas.drawPath(
      highlightPath, 
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: center.translate(-radius*0.35, -radius*0.35), radius: radius*0.3))
    );

    // 2. Bottom reflection (Rim light) - subtle
    final rimPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius * 0.96));
    
    canvas.drawPath(
      rimPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.05
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
    );
  }

  Color _getBallColor(int number) {
    switch (number) {
      case 1: case 9: return const Color(0xFFFFD700); // Yellow
      case 2: case 10: return const Color(0xFF003399); // Deep Blue
      case 3: case 11: return const Color(0xFFCC0000); // Red
      case 4: case 12: return const Color(0xFF4B0082); // Purple
      case 5: case 13: return const Color(0xFFFF6600); // Orange
      case 6: case 14: return const Color(0xFF006400); // Dark Green
      case 7: case 15: return const Color(0xFF800000); // Maroon
      case 8: return const Color(0xFF000000); // Black
      default: return Colors.grey;
    }
  }
  
  Color _brighten(Color c, int percent) {
    var p = percent / 100;
    return Color.fromARGB(
        c.alpha,
        (c.red + ((255 - c.red) * p)).round(),
        (c.green + ((255 - c.green) * p)).round(),
        (c.blue + ((255 - c.blue) * p)).round()
    );
  }

  Color _darken(Color c, int percent) {
    var f = 1 - percent / 100;
    return Color.fromARGB(
        c.alpha,
        (c.red * f).round(),
        (c.green * f).round(),
        (c.blue * f).round()
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
