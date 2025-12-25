import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/player.dart';
import '../theme/steampunk_theme.dart';
import 'steampunk_widgets.dart';

class VictorySplash extends StatefulWidget {
  final Player winner;
  final Player loser;
  final int raceToScore;
  final List<String> matchLog;
  final VoidCallback onNewGame;
  final VoidCallback onExit;

  const VictorySplash({
    super.key,
    required this.winner,
    required this.loser,
    required this.raceToScore,
    required this.matchLog,
    required this.onNewGame,
    required this.onExit,
  });

  @override
  State<VictorySplash> createState() => _VictorySplashState();
}

class _VictorySplashState extends State<VictorySplash> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SteampunkTheme.mahoganyDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(), // No back button
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            color: SteampunkTheme.brassPrimary,
            tooltip: 'Undo',
            onPressed: () {
              // Undo last action before victory
              Navigator.of(context).pop();
              // The game state's undo will be called after popping
            },
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            color: SteampunkTheme.brassDark,
            tooltip: 'Redo (disabled)',
            onPressed: null, // Greyed out
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          SteampunkBackground(
            child: Container(),
          ),
          
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Trophy Icon and Victory Text - Compact
                  const Icon(
                    Icons.emoji_events,
                    size: 48,
                    color: SteampunkTheme.amberGlow,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'VICTORY!',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: SteampunkTheme.brassBright,
                      fontSize: 32,
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
                  
                  // Scoresheet - No border, more space
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Column(
                      children: [
                        // Player names and scores at top
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    widget.winner.score.toString(),
                                    style: const TextStyle(
                                      color: SteampunkTheme.amberGlow,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.winner.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: SteampunkTheme.brassBright,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    widget.loser.score.toString(),
                                    style: const TextStyle(
                                      color: SteampunkTheme.steamWhite,
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.loser.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: SteampunkTheme.steamWhite,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Stats table
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: SteampunkTheme.brassDark),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              // Header row
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: const BoxDecoration(
                                  color: SteampunkTheme.mahoganyLight,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.winner.name.toUpperCase(),
                                        style: const TextStyle(
                                          color: SteampunkTheme.brassBright,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(width: 80, child: Text('')),
                                    Expanded(
                                      child: Text(
                                        widget.loser.name.toUpperCase(),
                                        style: const TextStyle(
                                          color: SteampunkTheme.steamWhite,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Stats rows
                              _buildStatsRow('Innings', widget.winner.currentInning.toString(), widget.loser.currentInning.toString()),
                              _buildStatsRow('Saves', widget.winner.saves.toString(), widget.loser.saves.toString()),
                              _buildStatsRow('Average', _calculateAverage(widget.winner), _calculateAverage(widget.loser)),
                              _buildStatsRow('Highest Run', _calculateHighestRun(widget.winner), _calculateHighestRun(widget.loser)),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Score Card
                        Text(
                          'SCORE CARD',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: SteampunkTheme.brassPrimary,
                            letterSpacing: 2,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildScoreCard(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Buttons - Using SteampunkButton
                  Row(
                    children: [
                      Expanded(
                        child: SteampunkButton(
                          label: 'New',
                          onPressed: widget.onNewGame,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SteampunkButton(
                          label: 'Exit',
                          onPressed: widget.onExit,
                        ),
                      ),
                    ],
                  ),
                ],
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

  Widget _buildStatsRow(String label, String winnerStat, String loserStat) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: SteampunkTheme.brassDark, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              winnerStat,
              style: const TextStyle(
                color: SteampunkTheme.brassBright,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: SteampunkTheme.steamWhite,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              loserStat,
              style: const TextStyle(
                color: SteampunkTheme.steamWhite,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateAverage(Player player) {
    if (player.currentInning == 0) return '0.0';
    return (player.score / player.currentInning).toStringAsFixed(1);
  }

  String _calculateHighestRun(Player player) {
    // Parse match log to find highest consecutive run for this player
    int currentRun = 0;
    int highestRun = 0;
    String lastPlayerName = '';
    
    // Iterate through match log chronologically (matchLog[0]=newest, iterate backwards for chronological order)
    for (int i = widget.matchLog.length - 1; i >= 0; i--) {
      String logEntry = widget.matchLog[i];
      
      // Check if this entry is for the current player
      if (logEntry.contains('${player.name}:')) {
        // Parse points from various formats:
        // - "Player: +14 pts" (normal scoring)
        // - "Player: Double-Sack! +15" (white ball)
        // - "Player: Re-rack (14.1 Continuous)" (ball 1 re-rack)
        RegExp pointsRegex = RegExp(r'\+(\d+)');
        Match? match = pointsRegex.firstMatch(logEntry);
        
        if (match != null) {
          int points = int.parse(match.group(1)!);
          
          // If same player as last scoring action, add to current run
          if (lastPlayerName == player.name) {
            currentRun += points;
          } else {
            // New player started scoring, reset current run
            currentRun = points;
            lastPlayerName = player.name;
          }
          
          // Update highest run if current exceeds it
          if (currentRun > highestRun) {
            highestRun = currentRun;
          }
        } else if (logEntry.contains('Miss') || logEntry.contains('Safe')) {
          // Entry exists but no points (safe, miss) - break the run
          if (lastPlayerName == player.name) {
            currentRun = 0;
            lastPlayerName = '';
          }
        } else if (logEntry.contains('Foul')) {
          // Foul - break the run
          if (lastPlayerName == player.name) {
            currentRun = 0;
            lastPlayerName = '';
          }
        }
        // Note: Re-rack and Double-Sack don't break the run - player continues
      } else {
        // Entry for other player - break the run if we were tracking this player
        if (lastPlayerName == player.name) {
          currentRun = 0;
          lastPlayerName = '';
        }
      }
    }
    
    return highestRun.toString();
  }

  Widget _buildScoreCard() {
    // Create a simple innings breakdown
    int maxInnings = widget.winner.currentInning > widget.loser.currentInning 
        ? widget.winner.currentInning 
        : widget.loser.currentInning;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: SteampunkTheme.brassDark),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: SteampunkTheme.mahoganyLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: const Text(
                    'Inning',
                    style: TextStyle(
                      color: SteampunkTheme.brassPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    widget.winner.name,
                    style: const TextStyle(
                      color: SteampunkTheme.brassBright,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    widget.loser.name,
                    style: const TextStyle(
                      color: SteampunkTheme.steamWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Innings rows (show first 9)
          ...List.generate(
            maxInnings > 9 ? 9 : maxInnings,
            (index) => _buildInningRow(index + 1),
          ),
          // Result row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: SteampunkTheme.brassDark, width: 2)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: const Text(
                    'Result',
                    style: TextStyle(
                      color: SteampunkTheme.brassPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    widget.winner.score.toString(),
                    style: const TextStyle(
                      color: SteampunkTheme.brassBright,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    widget.loser.score.toString(),
                    style: const TextStyle(
                      color: SteampunkTheme.steamWhite,
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

  Widget _buildInningRow(int inning) {
    // Parse match log to find score notation for this inning
    Map<String, Map<int, String>> inningScores = _parseInningScores();
    
    // Check if this is a legacy format game
    bool isLegacy = inningScores[widget.winner.name]!.isEmpty && 
                     inningScores[widget.loser.name]!.isEmpty;
    
    String winnerScore = '';
    String loserScore = '';
    
    if (!isLegacy) {
      // New format - access by inning number
      winnerScore = inningScores[widget.winner.name]?[inning] ?? '';
      loserScore = inningScores[widget.loser.name]?[inning] ?? '';
    } else {
      // Legacy format - show placeholder only in first inning
      if (inning == 1) {
        winnerScore = '-';
        loserScore = '-';
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: SteampunkTheme.brassDark, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              inning.toString(),
              style: const TextStyle(
                color: SteampunkTheme.steamWhite,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              winnerScore,
              style: const TextStyle(
                color: SteampunkTheme.steamWhite,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              loserScore,
              style: const TextStyle(
                color: SteampunkTheme.steamWhite,
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
    
    // Check for legacy format (no inning prefixes)
    if (widget.matchLog.isNotEmpty && !_hasInningPrefix(widget.matchLog.last)) {
      return {
        widget.winner.name: {},
        widget.loser.name: {},
      };
    }
    
    Map<String, Map<int, String>> result = {
      widget.winner.name: {},
      widget.loser.name: {},
    };
    
    // Track points accumulated in current inning (not as string, as number!)
    Map<String, int> currentInningPoints = {
      widget.winner.name: 0,
      widget.loser.name: 0,
    };
    
    Map<String, int> reRackPoints = {
      widget.winner.name: 0,
      widget.loser.name: 0,
    };
    
    Map<String, bool> inReRackMode = {
      widget.winner.name: false,
      widget.loser.name: false,
    };
    
    Map<String, bool> hasFoul = {
      widget.winner.name: false,
      widget.loser.name: false,
    };
    
    Map<String, int> lastInning = {
      widget.winner.name: 0,
      widget.loser.name: 0,
    };
    
    // Iterate chronologically
    for (int i = widget.matchLog.length - 1; i >= 0; i--) {
      String logEntry = widget.matchLog[i];
      
      // Extract inning and action
      RegExp inningRegex = RegExp(r'I(\d+) \| (.+)');
      Match? inningMatch = inningRegex.firstMatch(logEntry);
      if (inningMatch == null) continue;
      
      int inning = int.parse(inningMatch.group(1)!);
      String action = inningMatch.group(2)!;
      
      String? playerName;
      if (action.contains('${widget.winner.name}:')) {
        playerName = widget.winner.name;
      } else if (action.contains('${widget.loser.name}:')) {
        playerName = widget.loser.name;
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
    for (var player in [widget.winner.name, widget.loser.name]) {
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
    // Build notation: "14.3" or "5F" or "8" etc.
    String notation = '';
    
    if (hasReRack) {
      // Re-rack format: "{reRackPoints}.{additionalPoints}"
      notation = '$reRackPoints.';
      if (points > 0) {
        notation += points.toString();
      }
    } else {
      // Normal format: just the points
      if (points > 0) {
        notation = points.toString();
      }
    }
    
    if (hasFoul) {
      notation += 'F';
    }
    
    
    return notation;
  }
  
  bool _hasInningPrefix(String logEntry) {
    return logEntry.startsWith(RegExp(r'I\d+ \| '));
  }
}
