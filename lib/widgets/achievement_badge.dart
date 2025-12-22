import 'package:flutter/material.dart';
import 'dart:math' as math;

class AchievementBadge extends StatelessWidget {
  final String emoji;
  final bool isUnlocked;
  final bool isEasterEgg;
  final double size;

  const AchievementBadge({
    super.key,
    required this.emoji,
    required this.isUnlocked,
    this.isEasterEgg = false,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shield background
          CustomPaint(
            size: Size(size, size * 1.1),
            painter: _ShieldPainter(
              isUnlocked: isUnlocked,
              isEasterEgg: isEasterEgg,
            ),
          ),
          
          // Emoji
          Positioned(
            top: size * 0.25,
            child: Text(
              emoji,
              style: TextStyle(
                fontSize: size * 0.45,
                color: isUnlocked ? Colors.white : Colors.grey.shade400,
              ),
            ),
          ),
          
          // Lock icon for locked achievements
          if (!isUnlocked)
            Positioned(
              bottom: size * 0.15,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: size * 0.15,
                ),
              ),
            ),
          
          // Easter egg star for unlocked easter eggs
          if (isEasterEgg && isUnlocked)
            Positioned(
              top: size * 0.05,
              right: size * 0.05,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade700,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.shade700.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: size * 0.15,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final bool isUnlocked;
  final bool isEasterEgg;

  _ShieldPainter({
    required this.isUnlocked,
    required this.isEasterEgg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _createShieldPath(size);
    
    // Shadow
    if (isUnlocked) {
      canvas.drawShadow(
        path,
        Colors.black.withValues(alpha: 0.3),
        8.0,
        true,
      );
    }
    
    // Background gradient
    final gradient = isUnlocked
        ? (isEasterEgg
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade600,
                  Colors.purple.shade800,
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber.shade400,
                  Colors.amber.shade700,
                ],
              ))
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade400,
              Colors.grey.shade600,
            ],
          );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Border/outline
    final borderPaint = Paint()
      ..color = isUnlocked ? Colors.white.withValues(alpha: 0.3) : Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(path, borderPaint);

    // Inner highlight
    if (isUnlocked) {
      final highlightPath = _createShieldPath(Size(size.width * 0.9, size.height * 0.9));
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.save();
      canvas.translate(size.width * 0.05, size.height * 0.05);
      canvas.drawPath(highlightPath, highlightPaint);
      canvas.restore();
    }
  }

  Path _createShieldPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Start at top center
    path.moveTo(w * 0.5, 0);
    
    // Top right curve
    path.quadraticBezierTo(w * 0.75, 0, w, h * 0.15);
    
    // Right side
    path.lineTo(w, h * 0.6);
    
    // Bottom right curve to point
    path.quadraticBezierTo(w * 0.85, h * 0.8, w * 0.5, h);
    
    // Bottom left curve from point
    path.quadraticBezierTo(w * 0.15, h * 0.8, 0, h * 0.6);
    
    // Left side
    path.lineTo(0, h * 0.15);
    
    // Top left curve
    path.quadraticBezierTo(w * 0.25, 0, w * 0.5, 0);
    
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_ShieldPainter oldDelegate) {
    return oldDelegate.isUnlocked != isUnlocked ||
        oldDelegate.isEasterEgg != isEasterEgg;
  }
}
