import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/achievement.dart';

class AchievementSplash extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const AchievementSplash({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<AchievementSplash> createState() => _AchievementSplashState();
}

class _AchievementSplashState extends State<AchievementSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;
  final _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    _controller.forward();
    
    // Start confetti and sound
    Future.delayed(const Duration(milliseconds: 400), () {
      _confettiController.play();
      _playHornSound();
    });
  }

  Future<void> _playHornSound() async {
    try {
      // Use AssetSource for local assets or UrlSource for web
      // For now, using a simple system beep sound
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      // Play a notification-like sound (you can replace with custom horn.mp3)
      await _audioPlayer.play(AssetSource('sounds/horn.mp3'));
    } catch (e) {
      // Fallback: no sound if asset not found
      debugPrint('Sound error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Stack(
          children: [
            // Confetti from top center
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.purple,
                  Colors.orange,
                ],
              ),
            ),
            
            // Achievement content
            Container(
              color: Colors.transparent,
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber.shade700,
                            Colors.orange.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.6),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '🏆 ACHIEVEMENT UNLOCKED! 🏆',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            widget.achievement.emoji,
                            style: const TextStyle(fontSize: 80),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.achievement.title,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.achievement.description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Tap to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white60,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
