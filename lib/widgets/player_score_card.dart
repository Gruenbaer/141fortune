import 'package:flutter/material.dart';
import '../models/player.dart';

class PlayerScoreCard extends StatelessWidget {
  final Player player;
  final int raceToScore;

  const PlayerScoreCard({
    super.key,
    required this.player,
    required this.raceToScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: player.isActive ? Colors.green[100] : Colors.grey[200],
        border: Border.all(
          color: player.isActive ? Colors.green : Colors.grey,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            player.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${player.score} / $raceToScore',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Inning ${player.currentInning}',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
