import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

class AchievementBadge extends StatelessWidget {
  final String id;
  final String emoji;
  final bool isUnlocked;
  final bool isEasterEgg;
  final double size;

  const AchievementBadge({
    super.key,
    required this.id, // Now required to find asset
    required this.emoji,
    required this.isUnlocked,
    this.isEasterEgg = false,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size, // Images are square/circular
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. The Asset Image (with ColorFilter if locked)
          ColorFiltered(
            colorFilter: isUnlocked 
                ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply) // No-op
                : const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0,      0,      0,      1, 0,
                  ]), // Standard Greyscale
            child: ColorFiltered(
               // Add Sepia tone on top of greyscale for "Rusty" look if locked
               colorFilter: isUnlocked
                   ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                   : const ColorFilter.mode(Color(0xFF704214), BlendMode.overlay), 
               child: Image.asset(
                 _getAssetPath(id),
                 width: size,
                 height: size,
                 fit: BoxFit.contain,
                 errorBuilder: (context, error, stackTrace) {
                   // Fallback if image missing: Show generic shield (or just handle gracefully)
                   return Icon(Icons.broken_image, size: size * 0.5, color: Colors.grey);
                 },
               ),
            ),
          ),
          
          // 2. Lock Icon Overlay (if locked)
          if (!isUnlocked)
            Container(
              padding: EdgeInsets.all(size * 0.05),
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade600, width: 2),
              ),
              child: Icon(
                Icons.lock_outline,
                color: Colors.grey.shade300,
                size: size * 0.25,
              ),
            ),
        ],
      ),
    );
  }

  String _getAssetPath(String id) {
    const basePath = 'assets/images/achievements/';
    
    // Direct Mappings
    if (id == 'first_game') return '${basePath}first_game.png';
    if (id == 'first_win') return '${basePath}first_win.png';
    if (id == 'lucky_7') return '${basePath}lucky_7.png';
    
    // Category Mappings
    if (id.startsWith('streak_')) return '${basePath}streak_10.png'; // Reuse streak fire for all streaks currently
    
    // Fallback for others (use first_game or a generic one if I had it)
    // For now, let's re-use 'first_game' as a generic "Pool" badge base
    return '${basePath}first_game.png';
  }
}
