import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/fortune_theme.dart';

class ScoreCard extends StatelessWidget {
  final Player player1;
  final Player player2;
  final List<String> matchLog;
  final String? winnerName;

  const ScoreCard({
    super.key,
    required this.player1,
    required this.player2,
    required this.matchLog,
    this.winnerName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = FortuneColors.of(context);
    
    // Parse the log to get inning-by-inning data
    final inningScores = _parseInningScores();
    
    // Determine max innings based on parsed data or current innings
    int maxInnings = player1.currentInning > player2.currentInning 
        ? player1.currentInning 
        : player2.currentInning;
        
    // Ensure we show at least 1 row
    if (maxInnings < 1) maxInnings = 1;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.primaryDark),
        borderRadius: BorderRadius.circular(8),
        color: colors.backgroundCard.withOpacity(0.5),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Inning',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    player1.name.toUpperCase(),
                    style: TextStyle(
                      color: player1.name == winnerName 
                          ? colors.primaryBright 
                          : colors.textMain,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    player2.name.toUpperCase(),
                    style: TextStyle(
                      color: player2.name == winnerName 
                          ? colors.primaryBright 
                          : colors.textMain,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Innings rows
          ...List.generate(
            maxInnings,
            (index) => _buildInningRow(context, index + 1, inningScores),
          ),
          
          // Result row (Total Score)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.primaryDark, width: 2)),
              color: colors.backgroundCard.withOpacity(0.3),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Total',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    player1.score.toString(),
                    style: TextStyle(
                      color: player1.name == winnerName ? colors.primaryBright : colors.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    player2.score.toString(),
                    style: TextStyle(
                      color: player2.name == winnerName ? colors.primaryBright : colors.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInningRow(BuildContext context, int inning, Map<String, Map<int, String>> inningScores) {
    final colors = FortuneColors.of(context);
    
    // Check if this is a legacy format game
    bool isLegacy = (inningScores[player1.name]?.isEmpty ?? true) && 
                     (inningScores[player2.name]?.isEmpty ?? true);
    
    String p1Score = '';
    String p2Score = '';
    
    if (!isLegacy) {
      // New format - access by inning number
      p1Score = inningScores[player1.name]?[inning] ?? '';
      p2Score = inningScores[player2.name]?[inning] ?? '';
    } else {
      // Legacy format - show placeholder only in first inning
      if (inning == 1) {
        p1Score = '-';
        p2Score = '-';
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.primaryDark, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              inning.toString(),
              style: TextStyle(
                color: colors.textMain,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              p1Score,
              style: TextStyle(
                color: colors.textMain,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              p2Score,
              style: TextStyle(
                color: colors.textMain,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Map<int, String>> _parseInningScores() {
    // Returns: { 
    //   "Player1": { 1: "14.3", 2: "5F", 3: "1", ... },
    //   "Player2": { 1: "2", 2: "8", ... }
    // }
    
    // Check if empty or legacy
    if (matchLog.isEmpty) {
        return { player1.name: {}, player2.name: {} };
    }
    
    // Legacy check
    bool hasInningPrefix(String logEntry) {
        return logEntry.startsWith(RegExp(r'I\d+ \| '));
    }

    if (!hasInningPrefix(matchLog.last)) {
      return {
        player1.name: {},
        player2.name: {},
      };
    }
    
    Map<String, Map<int, String>> result = {
      player1.name: {},
      player2.name: {},
    };
    
    // Track points accumulated in current inning (not as string, as number!)
    Map<String, int> currentInningPoints = {
      player1.name: 0,
      player2.name: 0,
    };
    
    Map<String, int> reRackPoints = {
      player1.name: 0,
      player2.name: 0,
    };
    
    Map<String, bool> inReRackMode = {
      player1.name: false,
      player2.name: false,
    };
    
    Map<String, bool> hasFoul = {
      player1.name: false,
      player2.name: false,
    };
    
    Map<String, int> lastInning = {
      player1.name: 0,
      player2.name: 0,
    };
    
    // Iterate chronologically
    for (int i = matchLog.length - 1; i >= 0; i--) {
      String logEntry = matchLog[i];
      
      // Extract inning and action
      RegExp inningRegex = RegExp(r'I(\d+) \| (.+)');
      Match? inningMatch = inningRegex.firstMatch(logEntry);
      if (inningMatch == null) continue;
      
      int inning = int.parse(inningMatch.group(1)!);
      String action = inningMatch.group(2)!;
      
      String? playerName;
      if (action.contains('${player1.name}:')) {
        playerName = player1.name;
      } else if (action.contains('${player2.name}:')) {
        playerName = player2.name;
      }
      if (playerName == null) continue;
      
      // Check if inning changed - finalize previous inning
      if (lastInning[playerName]! > 0 && lastInning[playerName]! != inning) {
        String notation = _buildInningNotation(
          currentInningPoints[playerName]!,
          reRackPoints[playerName]!,
          inReRackMode[playerName]!,
          hasFoul[playerName]!,
        );
        
        if (notation.isNotEmpty) {
          result[playerName]![lastInning[playerName]!] = notation;
        }
        
        // Reset for new inning
        currentInningPoints[playerName] = 0;
        reRackPoints[playerName] = 0;
        inReRackMode[playerName] = false;
        hasFoul[playerName] = false;
      }
      
      lastInning[playerName] = inning;
      
      // Parse action
      if (action.contains('Re-rack')) {
        inReRackMode[playerName] = true;
        reRackPoints[playerName] = currentInningPoints[playerName]!;
        currentInningPoints[playerName] = 0; // Reset for post-re-rack scoring
      } else if (action.contains('Foul')) {
        hasFoul[playerName] = true;
      } else if (action.contains('+')) {
        RegExp pointsRegex = RegExp(r'\+(\d+)');
        Match? match = pointsRegex.firstMatch(action);
        if (match != null) {
          int points = int.parse(match.group(1)!);
          currentInningPoints[playerName] = currentInningPoints[playerName]! + points;
        }
      }
    }
    
    // Finalize remaining innings
    for (var player in [player1.name, player2.name]) {
      if (lastInning[player]! > 0) {
        String notation = _buildInningNotation(
          currentInningPoints[player]!,
          reRackPoints[player]!,
          inReRackMode[player]!,
          hasFoul[player]!,
        );
        
        if (notation.isNotEmpty) {
          result[player]![lastInning[player]!] = notation;
        }
      }
    }
    
    return result;
  }
  
  String _buildInningNotation(int points, int reRackPoints, bool hasReRack, bool hasFoul) {
    String notation = '';
    
    if (hasReRack) {
      notation = '$reRackPoints.';
      if (points > 0) {
        notation += points.toString();
      }
    } else {
      if (points > 0) {
        notation = points.toString();
      }
    }
    
    if (hasFoul) {
      notation += 'F';
    }
    
    return notation;
  }
}
