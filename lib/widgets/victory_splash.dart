import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/player.dart';
import '../theme/steampunk_theme.dart';

class VictorySplash extends StatefulWidget {
  final Player winner;
  final Player loser;
  final int raceToScore;
  final VoidCallback onNewGame;
  final VoidCallback onExit;

  const VictorySplash({
    super.key,
    required this.winner,
    required this.loser,
    required this.raceToScore,
    required this.onNewGame,
    required this.onExit,
  });

  @override
  State<VictorySplash> createState() => _VictorySplashState();
}

class _VictorySplashState extends State<VictorySplash> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    // Start animations
    _confettiController.play();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                SteampunkTheme.brassPrimary,
                SteampunkTheme.brassBright,
                SteampunkTheme.verdigris,
                SteampunkTheme.amberGlow,
              ],
              numberOfParticles: 50,
              gravity: 0.3,
            ),
          ),
          
          // Content
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(32),
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      SteampunkTheme.mahoganyLight,
                      SteampunkTheme.mahoganyDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: SteampunkTheme.brassPrimary,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trophy Icon
                    const Icon(
                      Icons.emoji_events,
                      size: 80,
                      color: SteampunkTheme.amberGlow,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Victory Text
                    Text(
                      'VICTORY!',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: SteampunkTheme.brassBright,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(
                            blurRadius: 10,
                            color: SteampunkTheme.amberGlow,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Winner Name
                    Text(
                      widget.winner.name.toUpperCase(),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: SteampunkTheme.brassPrimary,
                        fontSize: 32,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Scoresheet
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: SteampunkTheme.brassDark,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'FINAL SCORE',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: SteampunkTheme.brassPrimary,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildScoreLine(widget.winner.name, widget.winner.score, isWinner: true),
                          const SizedBox(height: 8),
                          _buildScoreLine(widget.loser.name, widget.loser.score, isWinner: false),
                          const SizedBox(height: 16),
                          Divider(color: SteampunkTheme.brassDark),
                          const SizedBox(height: 8),
                          _buildStatLine('Innings', widget.winner.currentInning.toString(), widget.loser.currentInning.toString()),
                          _buildStatLine('Saves', widget.winner.saves.toString(), widget.loser.saves.toString()),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onNewGame,
                            icon: const Icon(Icons.replay),
                            label: const Text('NEW GAME'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SteampunkTheme.verdigris,
                              foregroundColor: SteampunkTheme.leatherDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onExit,
                            icon: const Icon(Icons.exit_to_app),
                            label: const Text('EXIT'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SteampunkTheme.brassPrimary,
                              foregroundColor: SteampunkTheme.leatherDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreLine(String name, int score, {required bool isWinner}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              color: isWinner ? SteampunkTheme.brassBright : SteampunkTheme.steamWhite,
              fontSize: isWinner ? 24 : 18,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          score.toString(),
          style: TextStyle(
            color: isWinner ? SteampunkTheme.amberGlow : SteampunkTheme.steamWhite,
            fontSize: isWinner ? 32 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatLine(String label, String winnerStat, String loserStat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              winnerStat,
              style: const TextStyle(color: SteampunkTheme.steamWhite),
              textAlign: TextAlign.left,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: SteampunkTheme.brassDark,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              loserStat,
              style: const TextStyle(color: SteampunkTheme.steamWhite),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
