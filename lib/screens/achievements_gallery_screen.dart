import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement_manager.dart';
import '../models/achievement.dart';
import '../widgets/achievement_badge.dart';
import '../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementsGalleryScreen extends StatelessWidget {
  const AchievementsGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.achievements),
        centerTitle: true,
      ),
      body: Consumer<AchievementManager>(
        builder: (context, achievementManager, child) {
          final achievements = achievementManager.allAchievements;
          final unlockedCount = achievements.where((a) => a.isUnlocked).length;

          return Column(
            children: [
              // Progress Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                        const SizedBox(width: 12),
                        Text(
                          '$unlockedCount / ${achievements.length}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.achievementsUnlocked,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: achievements.isEmpty ? 0 : unlockedCount / achievements.length,
                        minHeight: 8,
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                    ),
                  ],
                ),
              ),

              // Achievements Grid (Steampunk Gallery)
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75, // Taller for the plaque description
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 30, // Breathing room for the large shields
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    return _buildAchievementItem(context, achievement);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAchievementItem(BuildContext context, Achievement achievement) {
    // No Card wrapper! Just the floating shield with text below.
    return InkWell(
      onTap: () => _showAchievementDetail(context, achievement),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: AchievementBadge(
                id: achievement.id,
                emoji: achievement.emoji,
                isUnlocked: achievement.isUnlocked,
                isEasterEgg: achievement.isEasterEgg,
                size: 130, // Slightly smaller to fit text comfortably? Or distinct size.
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.rye(
                fontSize: 14,
                color: achievement.isUnlocked ? Colors.amber.shade300 : Colors.grey.shade500,
                fontWeight: FontWeight.bold,
                shadows: [
                  BoxShadow(color: Colors.black, blurRadius: 2, offset: Offset(1,1)),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.visible, // User said "entire name", so try to show it all.
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAchievementDetail(BuildContext context, Achievement achievement) {
    final l10n = AppLocalizations.of(context);
    
    // 1. Determine Title & Description based on state
    String title = achievement.title;
    String description = achievement.description;
    
    // Dynamic Logic for Easter Eggs (Lucky 7)
    if (achievement.id == 'lucky_7') {
      if (!achievement.isUnlocked) {
         title = l10n.lucky7Title;
         description = l10n.lucky7Locked;
      } else {
         title = l10n.lucky7Title;
         description = l10n.lucky7Desc;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true, // Allow clicking outside to close
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16), 
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Main Card Background (Brass Plate / Mahogany Wood)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24), // Top padding for badge overlap
              decoration: BoxDecoration(
                color: const Color(0xFF2D1B13), // Deep Mahogany
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFB8860B), // Dark Goldenrod / Brass
                  width: 4,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black87, blurRadius: 20, spreadRadius: 5),
                  BoxShadow(color: Color(0x66B8860B), blurRadius: 10, offset: Offset(0, 0), spreadRadius: 2), // Inner/Outer Glow
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title (Brass Text)
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.rye(
                      fontSize: 24,
                      color: const Color(0xFFFFE082), // Amber/Gold
                      shadows: [
                         const BoxShadow(color: Colors.black, offset: Offset(2,2), blurRadius: 2),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Divider (Ornamental)
                  Container(
                    height: 2,
                    width: 100,
                    color: const Color(0xFF8B4513),
                    margin: const EdgeInsets.only(bottom: 16),
                  ),

                  // Description Box (Parchment inset)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E6D3), // Parchment light
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF5D4037), width: 2),
                       boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)), // Standard shadow
                       ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          description,
                          style: GoogleFonts.crimsonText( // Book font
                            fontSize: 18,
                            color: const Color(0xFF3E2723),
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        // Extra Details (Unlocked Date/By)
                        if (achievement.isUnlocked) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFF8D6E63), thickness: 1),
                          const SizedBox(height: 8),
                          if (achievement.unlockedAt != null)
                             Text(
                              '${l10n.unlockedOn} ${_formatDate(achievement.unlockedAt!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.brown.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                             ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Close Button (Styled Text Button)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFFB74D),
                    ),
                    child: Text(
                      l10n.ok.toUpperCase(),
                      style: const TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            // Floating Badge Logic
            Positioned(
              top: -60, // Pull it out of the box
              child: AchievementBadge(
                id: achievement.id,
                emoji: achievement.emoji,
                isUnlocked: achievement.isUnlocked,
                isEasterEgg: achievement.isEasterEgg,
                size: 100,
              ),
            ),
            
            // X Close Button (Top right corner of the dialog content)
            Positioned(
              top: 10,
              right: 10,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF800000), // Dark Red
                      border: Border.all(color: const Color(0xFFB8860B), width: 2), // Brass border
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(2,2))],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            
            // Decorative Screws (Corners)
            Positioned(top: 10, left: 10, child: _buildScrewHead()),
            Positioned(bottom: 10, left: 10, child: _buildScrewHead()),
            Positioned(bottom: 10, right: 10, child: _buildScrewHead()),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScrewHead() {
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade300, Colors.grey.shade800],
        ),
        border: Border.all(color: Colors.black45, width: 0.5),
      ),
      child: Center(
        child: Container(height: 1, width: 6, color: Colors.black54), // Slot
      ),
    );
  }
  
  Widget _buildInfoSection(AppLocalizations l10n, String label, String content, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(icon, size: 16, color: Colors.brown.shade600),
             const SizedBox(width: 8),
             Text(
               label.toUpperCase(),
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 letterSpacing: 1.2,
                 color: Colors.brown.shade600,
               ),
             ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.rye(
            fontSize: 16,
            color: const Color(0xFF5D4037),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
