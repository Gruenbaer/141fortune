import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/game_settings.dart';
import '../models/player.dart';
import '../theme/fortune_theme.dart';
import '../widgets/score_card.dart';

class DetailsScreen extends StatelessWidget {
  final GameState gameState;

  const DetailsScreen({
    super.key,
    required this.gameState,
  });

  String _calculateAverage(Player player) {
    if (player.currentInning == 0) return '0.00';
    return (player.score / player.currentInning).toStringAsFixed(2);
  }

  String _calculateHighestRun(Player player) {
    // This logic duplicates logic in VictorySplash. Ideally should be in GameState or Player logic.
    // For now, simple implementation or we can rely on parsing if complex.
    // But wait, the user asked for High Run.
    // Let's implement a simple parser for HR here? Or move logic to GameState?
    // Moving logic to GameState is safer to avoid duplication.
    // But for now, let's just parse it simply as we did in VictorySplash.
    
    // Copy-paste logic from VictorySplash (condensed for brevity)
    // Actually, let's just use what we have. If it's too complex, maybe just skip or use a simple heuristic.
    // User asked for "High Run". 
    // Let's iterate match log quickly.
    
    int highest = 0;
    int currentRun = 0;
    String lastPlayer = '';
    
    for (var entry in gameState.matchLog) {
      if (entry.contains(player.name)) {
        if (!entry.contains(lastPlayer)) {
          currentRun = 0;
          lastPlayer = player.name;
        }
        
        final regex = RegExp(r'\+(\d+)');
        final match = regex.firstMatch(entry);
        if (match != null) {
          int pts = int.parse(match.group(1)!);
          currentRun += pts;
          if (currentRun > highest) highest = currentRun;
        } else if (entry.contains('Miss') || entry.contains('Safe') || entry.contains('Foul')) {
           currentRun = 0;
        }
      } else {
        if (lastPlayer == player.name) {
          currentRun = 0;
          lastPlayer = '';
        }
      }
    }
    return highest.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FortuneColors.of(context);
    final settings = Provider.of<GameSettings>(context, listen: false);

    // Identify current leader/winner for highlighting
    String? leaderName;
    if (gameState.players[0].score > gameState.players[1].score) {
      leaderName = gameState.players[0].name;
    } else if (gameState.players[1].score > gameState.players[0].score) {
      leaderName = gameState.players[1].name;
    }

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: AppBar(
        title: Text(
          'Match Details',
          style: TextStyle(color: colors.primaryBright),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Game Metadata Badge
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.backgroundCard.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      settings.isLeagueGame ? Icons.emoji_events : Icons.handshake, 
                      size: 16, 
                      color: settings.isLeagueGame ? Colors.amber : Colors.greenAccent
                    ),
                    const SizedBox(width: 8),
                    Text(
                      settings.isLeagueGame ? 'LEAGUE GAME' : 'FRIENDSHIP GAME',
                      style: TextStyle(
                        color: settings.isLeagueGame ? Colors.amber : Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 12, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      'Race to ${gameState.raceToScore}',
                      style: TextStyle(
                        color: colors.textMain,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Player Comparison (Left vs Right)
            Container(
              decoration: BoxDecoration(
                color: colors.backgroundCard.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.primaryDark),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Names & Totals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // P1
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              gameState.players[0].name.toUpperCase(),
                              style: TextStyle(
                                color: gameState.players[0].name == leaderName 
                                    ? colors.primaryBright 
                                    : colors.textMain,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              gameState.players[0].score.toString(),
                              style: TextStyle(
                                color: colors.accent,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // VS
                      Text(
                        'VS', 
                        style: TextStyle(
                          color: colors.primaryDark, 
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        )
                      ),
                      // P2
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              gameState.players[1].name.toUpperCase(),
                              style: TextStyle(
                                color: gameState.players[1].name == leaderName 
                                    ? colors.primaryBright 
                                    : colors.textMain,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              gameState.players[1].score.toString(),
                              style: TextStyle(
                                color: colors.accent,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  
                  // Detailed Stats Table
                   Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1), // Label centered
                      2: FlexColumnWidth(1),
                    },
                    children: [
                      _buildStatRow(
                        colors, 
                        'Avg', 
                        _calculateAverage(gameState.players[0]), 
                        _calculateAverage(gameState.players[1])
                      ),
                      _buildStatRow(
                        colors, 
                        'High Run', 
                        _calculateHighestRun(gameState.players[0]), 
                        _calculateHighestRun(gameState.players[1])
                      ),
                       _buildStatRow(
                        colors, 
                        'Innings', 
                        gameState.players[0].currentInning.toString(), 
                        gameState.players[1].currentInning.toString()
                      ),
                       _buildStatRow(
                        colors, 
                        'Saves', 
                        gameState.players[0].saves.toString(), 
                        gameState.players[1].saves.toString()
                      ),
                       _buildStatRow(
                        colors, 
                        'Fouls', 
                        gameState.players[0].consecutiveFouls.toString(), 
                        gameState.players[1].consecutiveFouls.toString()
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Score Sheet Section
            Center(
              child: Text(
                'SCORE SHEET',
                style: TextStyle(
                  color: colors.primary,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            ScoreCard(
              player1: gameState.players[0],
              player2: gameState.players[1],
              matchLog: gameState.matchLog,
              winnerName: leaderName,
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  TableRow _buildStatRow(FortuneColors colors, String label, String p1Val, String p2Val) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            p1Val,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textMain, fontSize: 16, fontFamily: 'Courier'),
          ),
        ),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.primaryDark, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            p2Val,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textMain, fontSize: 16, fontFamily: 'Courier'),
          ),
        ),
      ],
    );
  }
}

