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
          // Header Row 1: Player Names
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    player1.name.toUpperCase(),
                    style: TextStyle(
                      color: player1.name == winnerName 
                          ? colors.primaryBright 
                          : colors.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox(), // Spacer for Inning column
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    player2.name.toUpperCase(),
                    style: TextStyle(
                      color: player2.name == winnerName 
                          ? colors.primaryBright 
                          : colors.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Header Row 2: Columns
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            color: colors.backgroundCard,
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildHeaderLabel(colors, 'POINTS')),
                Expanded(flex: 2, child: _buildHeaderLabel(colors, 'TOTAL')),
                Expanded(flex: 1, child: _buildHeaderLabel(colors, 'INN')),
                Expanded(flex: 2, child: _buildHeaderLabel(colors, 'TOTAL')),
                Expanded(flex: 2, child: _buildHeaderLabel(colors, 'POINTS')),
              ],
            ),
          ),
          // Innings rows
          ...List.generate(
            maxInnings,
            (index) => _buildInningRow(context, index + 1, inningScores),
          ),
          
          // Result row (Total Score)
          // Footer (Optional Total Row if needed, or remove as redundant if total acts as running total)
          // Removing the specific footer row to keep it clean as per user request for standard card style.
          // Or we can keep a summary row? Let's check user request: "name cols...".
          // The grid itself tracks totals.
        ],
      ),
    );
  }


  Widget _buildHeaderLabel(FortuneColors colors, String text) {
    return Text(
      text,
      style: TextStyle(
        color: colors.textMain.withOpacity(0.7),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInningRow(BuildContext context, int inning, Map<String, Map<int, InningStat>> inningScores) {
    final colors = FortuneColors.of(context);
    final isLegacy = matchLog.isNotEmpty && !matchLog.first.contains(':');

    // Data for single inning
    final p1Data = inningScores[player1.name]?[inning];
    final p2Data = inningScores[player2.name]?[inning]; // Expecting Map<String, dynamic> now? Or custom class..
    
    // We need to refactor _parseInningScores return type to hold (Notation, Total)
    
    String p1Notation = p1Data?.notation ?? '';
    String p1Total = p1Data?.total != null ? '${p1Data!.total}' : '';

    String p2Notation = p2Data?.notation ?? '';
    String p2Total = p2Data?.total != null ? '${p2Data!.total}' : '';
    
    if (isLegacy && inning == 1) {
       p1Notation = '-';
       p2Notation = '-';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.primaryDark, width: 0.5)),
      ),
      child: Row(
        children: [
          // P1 Points
          Expanded(
            flex: 2,
            child: Text(
              p1Notation,
              style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // P1 Total
          Expanded(
            flex: 2,
            child: Text(
              p1Total,
              style: TextStyle(color: colors.primary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          // Inning #
          Expanded(
            flex: 1,
            child: Text(
              inning.toString(),
              style: TextStyle(
                color: colors.accent,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // P2 Total
          Expanded(
            flex: 2,
             child: Text(
              p2Total,
              style: TextStyle(
                color: colors.primaryBright,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // P2 Notation
          Expanded(
            flex: 3,
            child: Text(
              p2Notation,
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

  // Refactor return type: Map<PlayerName, Map<Inning, InningStat>>
  Map<String, Map<int, InningStat>> _parseInningScores() {
    if (matchLog.isEmpty) {
        return { player1.name: {}, player2.name: {} };
    }
    
    bool hasInningPrefix(String logEntry) {
        return logEntry.startsWith(RegExp(r'I\d+ \| '));
    }

    if (!hasInningPrefix(matchLog.last)) {
      return { player1.name: {}, player2.name: {} };
    }
    
    Map<String, Map<int, InningStat>> result = {
      player1.name: {},
      player2.name: {},
    };
    
    // Running Totals
    Map<String, int> runningTotals = { player1.name: 0, player2.name: 0 };
    
    // Inning Accumulators
    Map<String, int> currentInningPoints = { player1.name: 0, player2.name: 0 };
    Map<String, int> reRackPoints = { player1.name: 0, player2.name: 0 };
    Map<String, bool> inReRackMode = { player1.name: false, player2.name: false };
    Map<String, bool> hasFoul = { player1.name: false, player2.name: false };
    Map<String, int> lastInning = { player1.name: 0, player2.name: 0 };
    
    // Reverse Log (Chronological)
    for (int i = matchLog.length - 1; i >= 0; i--) {
      String logEntry = matchLog[i];
      
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
      
      // If Inning Changed for this player -> Finalize Previous
      if (lastInning[playerName]! > 0 && lastInning[playerName]! != inning) {
         _finalizeInning(
            playerName, 
            lastInning[playerName]!, 
            currentInningPoints, 
            runningTotals, 
            reRackPoints, 
            inReRackMode, 
            hasFoul, 
            result
         );
      }
      
      lastInning[playerName] = inning;
      
      // Process Action Points
      int delta = 0;
      if (action.contains('Re-rack')) {
        inReRackMode[playerName] = true;
        reRackPoints[playerName] = currentInningPoints[playerName]!;
        currentInningPoints[playerName] = 0; 
      } else if (action.contains('Foul')) {
        hasFoul[playerName] = true;
        // Parse foul penalty if in log? Usually log has "Foul (-1)" or "Safe (0)"
        // But our log format for foul is usually "Player: -1 pts (Foul)"
      }
      
      if (action.contains('pts') || action.contains('Double-Sack')) {
         // Regex for signed int: (+15, -1, -2)
         RegExp pointsRegex = RegExp(r'([+-]?\d+)\s*pts|([+-]?\d+)');
         // We need to be careful not to match "I1" or ball count.
         // Action string: "Player: -1 pts (Foul) (Left: 14)"
         
         // Simple scan for points
         // If points are negative, they reduce total? 
         // Running Total tracks the player score. 
         // currentInningPoints tracks points IN THIS INNING for notation.
         // Wait, "5.F" means 5 points then foul.
         // So if I score 5 (valid), then I foul (-1).
         // Inning Total: 4. Notation: "5.F"??
         // Standard notation usually: Points scored in inning. 
         // If foul ended the inning, "F".
         // Does running total include the foul penalty? Yes.
         
         // We parse the exact delta from the log to update running total.
         RegExp scoreRegex = RegExp(r':\s*([+-]?\d+)\s*pts|Double-Sack!\s*\+?(\d+)');
         Match? match = scoreRegex.firstMatch(action);
         if (match != null) {
            String val = match.group(1) ?? match.group(2) ?? '0';
            delta = int.parse(val);
         }
      }
      
      currentInningPoints[playerName] = currentInningPoints[playerName]! + delta;
      // We do NOT update Running Total here yet? 
      // Or do we? The running total is end-of-inning state.
      // So we accumulate delta into 'currentInningPoints', and add to running total at end of inning processing?
      // YES.
    }
    
    // Finalize Last Inning
    for (var p in [player1.name, player2.name]) {
       if (lastInning[p]! > 0) {
          _finalizeInning(
            p, 
            lastInning[p]!, 
            currentInningPoints, 
            runningTotals, 
            reRackPoints, 
            inReRackMode, 
            hasFoul, 
            result
         );
       }
    }
    
    return result;
  }
  
  void _finalizeInning(
      String player,
      int inning,
      Map<String, int> currentPoints,
      Map<String, int> runningTotals,
      Map<String, int> reRackPoints,
      Map<String, bool> hasReRack,
      Map<String, bool> hasFoul,
      Map<String, Map<int, InningStat>> result
  ) {
      int inningScore = currentPoints[player]!;
      
      // Special logic: Re-rack points are separate but part of this inning's total?
      // Usually re-rack means "I scored X, then racked, then scored Y". 
      // Notation "X.Y".
      // Log logic accumulated Y into `currentPoints`. X is in `reRackPoints`.
      // Total Inning Score = X + Y.
      if (hasReRack[player]!) {
          inningScore += reRackPoints[player]!;
      }
      
      // Update Running Total
      runningTotals[player] = runningTotals[player]! + inningScore;
      
      // Build Notation
      String notation = '';
      if (hasReRack[player]!) {
          notation = '${reRackPoints[player]}.';
          // Only show second part if > 0 or if not foul?
          if (currentPoints[player]! > 0 || (!hasFoul[player]! && currentPoints[player]! != 0)) {
               notation += currentPoints[player].toString();
          } else if (currentPoints[player]! < 0) {
               // Negative points after rerack (foul immediate?)
               notation += currentPoints[player].toString(); 
          }
      } else {
          notation = inningScore.toString();
          // If 0, check if Safe or Foul or Miss?
          // If just 0 and no foul, it's a safe/miss.
          if (inningScore == 0 && !hasFoul[player]!) {
              notation = '-'; // or '0'
          }
      }
      
      if (hasFoul[player]!) {
          // If notation was just score, append F?
          // E.g. "5" -> "5F"? Or is F separate?
          // User said "5.F".
          // If I score 5 then foul (-1). Inning score is 4.
          // Notation usually is "Balls Potted".
          // Let's assume notation tracks "Positive Points" + F?
          // Or just raw score + F.
          // Let's stick to "F" suffix strictly.
          if (notation == '-') notation = '';
          notation += ' F'; 
      }
      
      result[player]![inning] = InningStat(notation, runningTotals[player]!);
      
      // Reset
      currentPoints[player] = 0;
      reRackPoints[player] = 0;
      hasReRack[player] = false;
      hasFoul[player] = false;
  }

}

class InningStat {
  final String notation;
  final int total;
  InningStat(this.notation, this.total);

}
