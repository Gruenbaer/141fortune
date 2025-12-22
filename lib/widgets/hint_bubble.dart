import 'package:flutter/material.dart';

class HintBubble extends StatelessWidget {
  final String message;
  final Offset target;
  final double containerWidth;

  const HintBubble({
    super.key,
    required this.message,
    required this.target,
    required this.containerWidth,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HintBubblePainter(
        message: message,
        target: target,
        containerWidth: containerWidth,
      ),
      // Size: Height will be determined by painter? 
      // Actually CustomPaint size is usually constraints.
      // We want to fill the area?
      // No, we want to lay over the rack.
      // So width/height should be containerWidth / containerHeight (or infinite if stack).
      // But we passed containerWidth.
      size: Size(containerWidth, target.dy), // Draw up to target Y
    );
  }
}

class HintBubblePainter extends CustomPainter {
  final String message;
  final Offset target;
  final double containerWidth;

  HintBubblePainter({
    required this.message,
    required this.target,
    required this.containerWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 12.0;
    const pointerHeight = 12.0;
    const pointerBaseWidth = 20.0;
    const boxRadius = 12.0;

    final textSpan = TextSpan(
      text: message,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Max width for bubble: Container width - margins
    const margin = 16.0;
    textPainter.layout(
      minWidth: 0, 
      maxWidth: containerWidth - (margin * 2) - (padding * 2),
    );

    final bubbleWidth = textPainter.width + (padding * 2);
    final bubbleHeight = textPainter.height + (padding * 2);

    // Calculate Position
    // Ideal: Centered on target X
    double left = target.dx - (bubbleWidth / 2);
    
    // Clamp to container bounds
    if (left < margin) left = margin;
    if (left + bubbleWidth > containerWidth - margin) {
      left = containerWidth - margin - bubbleWidth;
    }

    // Top: Above target Y
    final top = target.dy - bubbleHeight - pointerHeight - 8; // Extra spacing

    final rect = Rect.fromLTWH(left, top, bubbleWidth, bubbleHeight);

    // Pointer Path (triangle pointing down to target)
    final pointerTipX = target.dx;
    final pointerPath = Path();
    pointerPath.moveTo(pointerTipX, target.dy); // Tip at target
    pointerPath.lineTo(pointerTipX - (pointerBaseWidth / 2), rect.bottom); 
    pointerPath.lineTo(pointerTipX + (pointerBaseWidth / 2), rect.bottom); 
    pointerPath.close();

    // RRect Path (bubble body)
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(boxRadius));
    final boxPath = Path()..addRRect(rrect);
    
    // Combine paths
    final combinedPath = Path.combine(PathOperation.union, boxPath, pointerPath);

    // Draw shadow
    canvas.drawShadow(combinedPath, Colors.black26, 3.0, true);
    
    // Fill bubble (white)
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(combinedPath, fillPaint);

    // Draw black border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawPath(combinedPath, borderPaint);
    
    // Paint text on top
    textPainter.paint(canvas, Offset(left + padding, top + padding));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Simplified
  }
}
