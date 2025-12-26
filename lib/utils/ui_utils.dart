import 'package:flutter/material.dart';

/// Shows a dialog with a fast Zoom/Fade transition.
Future<T?> showZoomDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Curve the animation for a nice "pop" effect
      final curvedValue = Curves.easeOutBack.transform(animation.value);
      
      return Transform.scale(
        scale: 0.8 + (0.2 * curvedValue), // Scale from 0.8 to 1.0 (subtle zoom)
        // Alternate: 0.0 to 1.0 for full zoom? User said "fade in zooming". 
        // 0.5 -> 1.0 is usually safer for UI.
        child: Opacity(
          opacity: animation.value,
          child: child,
        ),
      );
    },
  );
}
