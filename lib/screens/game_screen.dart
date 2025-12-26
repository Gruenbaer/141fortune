import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/player.dart'; // Explicit import needed after aliasing player_service
import '../models/game_settings.dart';
import '../models/achievement_manager.dart';
import '../models/achievement.dart';
import '../widgets/ball_button.dart';
import '../widgets/player_plaque.dart';
import '../widgets/foul_toggle_button.dart';
import '../widgets/hint_bubble.dart';
import '../widgets/achievement_splash.dart';
import '../l10n/app_localizations.dart';
import '../models/game_record.dart';
import '../services/game_history_service.dart';
import 'settings_screen.dart';
import 'details_screen.dart';
import '../theme/steampunk_theme.dart';
import '../theme/fortune_theme.dart';
import '../widgets/steampunk_widgets.dart';
import '../widgets/victory_splash.dart';
import '../widgets/game_clock.dart';
import '../widgets/pause_overlay.dart';
import 'new_game_settings_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // For Arial alternative (Lato/Roboto) if Arial not available, but user said Arial.
import '../services/player_service.dart' as stats; // For stats fetching

class GameScreen extends StatefulWidget {
  final GameSettings settings;
  final Function(GameSettings) onSettingsChanged;

  final GameRecord? resumeGame;

  const GameScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.resumeGame,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Achievement? _achievementToShow;
  final GameHistoryService _historyService = GameHistoryService();
  late String _gameId; // Unique ID for this game
  DateTime? _gameStartTime; // Track when game started
  bool _isCompletedSaved = false;
  
  // Historical stats for display
  stats.Player? _p1Stats;
  stats.Player? _p2Stats;

  Future<void> _loadPlayerStats() async {
    final gameState = Provider.of<GameState>(context, listen: false);
    final service = stats.PlayerService();
    // Fetch persistent data for P1 and P2
    // We match by Name since that's what we have
    final p1 = await service.getPlayerByName(gameState.players[0].name);
    final p2 = await service.getPlayerByName(gameState.players[1].name);
    
    if (mounted) {
      setState(() {
        _p1Stats = p1;
        _p2Stats = p2;
      });
    }
  }

  Future<void> _saveInProgressGame(GameState gameState) async {
    // Check if game is completed (score >= raceToScore)
    final p1 = gameState.players[0];
    final p2 = gameState.players[1];
    final winner = (p1.score >= gameState.raceToScore) ? p1 : (p2.score >= gameState.raceToScore ? p2 : null);

    // Don't save as in-progress if actually completed
    if (winner != null || _gameStartTime == null) return;
    
    final record = GameRecord(
      id: _gameId,
      player1Name: p1.name,
      player2Name: p2.name,
      player1Score: p1.score,
      player2Score: p2.score,
      startTime: _gameStartTime!,
      isCompleted: false,
      raceToScore: gameState.raceToScore,
      player1Innings: p1.currentInning,
      player2Innings: p2.currentInning,
      player1Fouls: 0, // Not exposed in Player model yet
      player2Fouls: 0, // Not exposed in Player model yet
      activeBalls: gameState.activeBalls.toList(),
      player1IsActive: p1.isActive,
      snapshot: gameState.toJson(),
    );
    
    await _historyService.saveGame(record);
  }
  
  // ... _saveCompletedGame restored:
  Future<void> _saveCompletedGame(GameState gameState) async {
    // 1. Mark as saved immediately to prevent double-save
    if (_isCompletedSaved) return;
    _isCompletedSaved = true;

    final p1 = gameState.players[0];
    final p2 = gameState.players[1];
    final winner = gameState.winner; 
    // If winner is null for some reason, determine by score
    final effectiveWinner = winner ?? ((p1.score >= gameState.raceToScore) ? p1 : (p2.score >= gameState.raceToScore ? p2 : null));

    if (effectiveWinner == null) return; // Should not happen if game is over

    final record = GameRecord(
      id: _gameId,
      player1Name: p1.name,
      player2Name: p2.name,
      player1Score: p1.score,
      player2Score: p2.score,
      startTime: _gameStartTime ?? DateTime.now(), // Fallback
      endTime: DateTime.now(),
      isCompleted: true,
      raceToScore: gameState.raceToScore,
      winner: effectiveWinner.name,
      player1Innings: p1.currentInning,
      player2Innings: p2.currentInning,
      player1Fouls: 0, 
      player2Fouls: 0, 
      activeBalls: [], // Cleared
      player1IsActive: false,
      snapshot: null, // Don't save snapshot for completed game
    );

    // Add matchLog if GameRecord supports it (it appeared missing in previous step view of GameRecord, let's omit if not there)
    // Looking at GameRecord file view, there is NO matchLog field. Removing it.

    await _historyService.saveGame(record);
    
    // 2. Update Persistent Player Stats
    try {
      final playerService = stats.PlayerService(); 
      
      // Helper to update a single player
      Future<void> updatePlayerStats(Player gamePlayer, bool isWinner) async {
        final existingPlayer = await playerService.getPlayerByName(gamePlayer.name);
        if (existingPlayer != null) {
          // Increment stats
          existingPlayer.gamesPlayed += 1;
          if (isWinner) existingPlayer.gamesWon += 1;
          existingPlayer.totalPoints += gamePlayer.score;
          existingPlayer.totalInnings += gamePlayer.currentInning;
          existingPlayer.totalSaves += gamePlayer.saves;
          
          await playerService.updatePlayer(existingPlayer);
        }
      }

      await updatePlayerStats(p1, p1 == effectiveWinner);
      await updatePlayerStats(p2, p2 == effectiveWinner);
      
    } catch (e) {
      print('Error updating player stats: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    
    if (widget.resumeGame != null) {
      _gameId = widget.resumeGame!.id;
      _gameStartTime = widget.resumeGame!.startTime;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final gameState = Provider.of<GameState>(context, listen: false);
        if (widget.resumeGame!.snapshot != null) {
           gameState.loadFromJson(widget.resumeGame!.snapshot!);
        }
        _loadPlayerStats();
      });
    } else {
      _gameId = DateTime.now().millisecondsSinceEpoch.toString();
      _gameStartTime = DateTime.now();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
         _loadPlayerStats();
      });
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final achievementManager = Provider.of<AchievementManager>(context, listen: false);
      achievementManager?.onAchievementUnlocked = (achievement) {
        setState(() {
          _achievementToShow = achievement;
        });
      };
    });
  }

  @override
  void deactivate() {
    if (!mounted) return; // Guard
    // Save game on exit
    // ... logic same ... 
    try {
      final gameState = Provider.of<GameState>(context, listen: false);
        if (!gameState.gameStarted) {
           // Maybe delete empty game?
        } else {
           _saveInProgressGame(gameState);
        }
    } catch (e) {
      // Ignore provider issues on dispose
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to provider for Undo/Redo button state
    final gameState = Provider.of<GameState>(context);
    final colors = FortuneColors.of(context);
    final theme = Theme.of(context);

    // Helper functions for Drawer actions
    void showRestartConfirmation() {
    final l10n = AppLocalizations.of(context);
    Navigator.pop(context); // Close drawer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restartGame),
        content: Text(l10n.restartGameMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              gameState.resetGame();
              Navigator.pop(context);
            },
            child: Text(l10n.undo), // Using 'undo' for 'restart'
          ),
        ],
      ),
    );
  }

    void showRulesPopup() {
    final l10n = AppLocalizations.of(context);
    Navigator.pop(context); // Close drawer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.gameRules),
        content: SingleChildScrollView(
          child: Text(
            l10n.translate('gameRulesContent'), // Will add full rules text
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.back),
          ),
        ],
      ),
    );
  }

    return Stack(
      children: [
        PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final l10n = AppLocalizations.of(context);
            final shouldExit = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.exitGameTitle),
                content: Text(l10n.exitGameMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.exit),
                  ),
                ],
              ),
            );
            if (shouldExit == true) {
              if (context.mounted) {
                // Save in-progress game before exiting
                final gameState = Provider.of<GameState>(context, listen: false);
                await _saveInProgressGame(gameState);
                
                if (context.mounted) {
                  Navigator.of(context).pop(); 
                }
              }
            }
          },
          child: Scaffold(
            extendBodyBehindAppBar: true, 
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              // Game type in top-left
              leading: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Center(
                  child: Text(
                    'Straight Pool',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(blurRadius: 3, color: Colors.black87, offset: const Offset(1, 1)),
                        Shadow(blurRadius: 6, color: colors.primary.withOpacity(0.5), offset: const Offset(0, 0)),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.analytics_outlined),
                  color: colors.primary,
                  tooltip: 'Details',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailsScreen(gameState: gameState),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  color: colors.primary,
                  tooltip: 'Settings',
                  onPressed: () async {
                    final updateSettings = Provider.of<Function(GameSettings)>(context, listen: false);
                    final currentSettings = Provider.of<GameSettings>(context, listen: false);
                    
                    // Create a Settings object that reflects the CURRENT game state
                    // This ensures the menu shows real names/scores, not defaults
                    final activeGameSettings = currentSettings.copyWith(
                      player1Name: gameState.players[0].name,
                      player2Name: gameState.players[1].name,
                      raceToScore: gameState.raceToScore,
                      threeFoulRuleEnabled: gameState.foulTracker.threeFoulRuleEnabled,
                    );

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                          currentSettings: activeGameSettings,
                          onSettingsChanged: (newSettings) {
                            // 1. Update Global Settings (Persistence)
                            updateSettings(newSettings);
                            
                            // 2. Update Active Game State (In-Game)
                            gameState.updateSettings(newSettings);
                          },
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.undo),
                  color: colors.primary,
                  tooltip: 'Undo',
                  onPressed: gameState.canUndo ? gameState.undo : null,
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  color: colors.primary,
                  tooltip: 'Redo',
                  onPressed: gameState.canRedo ? gameState.redo : null,
                ),
              ],
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                   DrawerHeader(
                    decoration: const BoxDecoration(
                      color: SteampunkTheme.mahoganyDark,
                    ),
                    child: Center(
                      child: Text(
                        '14.1 Fortune',
                        style: SteampunkTheme.themeData.textTheme.displayMedium,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.refresh, color: SteampunkTheme.brassPrimary),
                    title: Text('Restart Game', style: SteampunkTheme.themeData.textTheme.bodyLarge),
                    onTap: showRestartConfirmation,
                  ),
                  ListTile(
                    leading: const Icon(Icons.menu_book, color: SteampunkTheme.brassPrimary),
                    title: Text('Rules', style: SteampunkTheme.themeData.textTheme.bodyLarge),
                    onTap: showRulesPopup,
                  ),
                ],
              ),
            ),
            body: SteampunkBackground(
              child: SafeArea(
                child: Consumer<GameState>(
                  builder: (context, gameState, child) {
                    if (gameState.showThreeFoulPopup) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _show3FoulPopup(context, gameState);
                      });
                    }

                    final hasWinner = gameState.players.any((p) => p.score >= gameState.raceToScore);
                    if (hasWinner && !_isCompletedSaved) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _saveCompletedGame(gameState);
                        // Navigate to victory screen
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => VictorySplash(
                              winner: gameState.winner!,
                              loser: gameState.players.firstWhere((p) => p != gameState.winner),
                              raceToScore: gameState.raceToScore,
                              matchLog: gameState.matchLog,
                              elapsedDuration: gameState.elapsedDuration,
                              onNewGame: () {
                                // Pop all routes to return to home screen
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                              onExit: () {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                            ),
                          ),
                        );
                      });
                    }

                    return Column(
                      children: [
                        // Race to XX indicator
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Race to ${gameState.raceToScore}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                const Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
                              ],
                            ),
                          ),
                        ),
                        // 1. Players & Scores Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.backgroundCard,
                            border: Border(bottom: BorderSide(color: colors.primary, width: 2)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: PlayerPlaque(player: gameState.players[0], raceToScore: gameState.raceToScore, isLeft: true),
                              ),
                              // Switch Button or Spacer
                              if (!gameState.gameStarted && gameState.matchLog.isEmpty)
                                IconButton(
                                  icon: const Icon(Icons.swap_horiz, size: 28),
                                  color: colors.accent,
                                  onPressed: gameState.swapStartingPlayer,
                                  tooltip: 'Swap Sides',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              else
                                const SizedBox(width: 12),
                              Expanded(
                                child: PlayerPlaque(player: gameState.players[1], raceToScore: gameState.raceToScore, isLeft: false),
                              ),
                            ],
                          ),
                        ),

                        // 2. Historical Stats Row (Avg | Highest)
                        if (_p1Stats != null && _p2Stats != null)
                          Container(
                            color: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            child: Row(
                              children: [
                                // P1 Stats
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStatItem('GD', _p1Stats!.generalAverage.toStringAsFixed(2)),
                                      _buildStatItem('HR', '${_p1Stats!.highestRun}'),
                                    ],
                                  ),
                                ),
                                Container(width: 2, height: 24, color: SteampunkTheme.brassDark), // Divider
                                // P2 Stats
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStatItem('GD', _p2Stats!.generalAverage.toStringAsFixed(2)),
                                      _buildStatItem('HR', '${_p2Stats!.highestRun}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // CLOCK
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: GameClock(),
                        ),

                        // 3. Score Sheet (Match Log) - Removed per user request
                        // It is now available in "Details" (Stats Icon) and Victory Screen.

                        // 4. Notification / Last Action (Optional Overlay or smaller)
                        if (gameState.lastAction != null)
                           Container(
                              width: double.infinity,
                              color: colors.primary,
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                gameState.lastAction!.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                           ),

                        // 5. Ball Rack (Expanded to fill remaining space)
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Decorative Gears behind the rack
                              if (colors.backgroundMain == SteampunkTheme.mahoganyDark)
                                Opacity(
                                  opacity: 0.1,
                                  child: Image.asset('assets/images/ui/gears.png', fit: BoxFit.contain),
                                ),
                              // The Rack
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0), // Reduced padding
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: _buildRackFormation(context, gameState),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Controls
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Foul Toggle
                              Expanded(
                                child: SteampunkButton(
                                  label: gameState.foulMode == FoulMode.none 
                                      ? 'No Foul' 
                                      : (gameState.foulMode == FoulMode.normal ? 'Foul\n-1' : 'Break Foul\n-2'),
                                  textColor: gameState.foulMode == FoulMode.none
                                      ? null // Default color
                                      : (gameState.foulMode == FoulMode.normal 
                                          ? const Color(0xFFCC6600) // Orange for -1
                                          : const Color(0xFFCC0000)), // Red for -2
                                  onPressed: gameState.gameOver ? () {} : () {
                                     FoulMode next;
                                     switch (gameState.foulMode) {
                                       case FoulMode.none: 
                                         next = FoulMode.normal; 
                                         break;
                                       case FoulMode.normal: 
                                         // severe (Break Foul) only allowed in Break Sequence
                                         next = gameState.canBreakFoul ? FoulMode.severe : FoulMode.none; 
                                         break;
                                       case FoulMode.severe: 
                                         next = FoulMode.none; 
                                         break;
                                     }
                                     gameState.setFoulMode(next);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Safe Button (Toggle)
                              Expanded(
                                child: SteampunkButton(
                                  label: gameState.isSafeMode ? 'CONFIRM SAFE' : 'SAFE',
                                  icon: gameState.isSafeMode ? Icons.shield_moon : Icons.shield,
                                  onPressed: gameState.gameOver ? () {} : gameState.onSafe,
                                  // Green gradient when Active (Safe Mode ON)
                                  backgroundGradientColors: gameState.isSafeMode 
                                    ? const [Color(0xFF66BB6A), Color(0xFF2E7D32)] // Green/Dark Green
                                    : null,
                                  // Icon/Text color changes too? Maybe white on green?
                                  textColor: gameState.isSafeMode ? Colors.white : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        
        // Achievement Splash Overlay
        if (_achievementToShow != null)
          AchievementSplash(
            achievement: _achievementToShow!,
            onDismiss: () {
              setState(() {
                _achievementToShow = null;
              });
            },
          ),
          
        // Pause Overlay
        const PauseOverlay(),
      ],
    ); // close Stack - this is the return of build()
  }

  List<Widget> _buildRackFormation(BuildContext context, GameState gameState) {
    const ballSize = 60.0;
    const diameter = ballSize;
    // Tighter packing: Vertical distance = diameter * sin(60 degrees)
    const verticalOffset = diameter * 0.866025; 
    
    final rows = [
      [1],
      [2, 3],
      [4, 5, 6],
      [7, 8, 9, 10],
      [11, 12, 13, 14, 15],
    ];

    // Total rack dimensions
    final rackWidth = 5 * diameter;
    final rackHeight = 4 * verticalOffset + diameter;

    // Helper to check if ball can be tapped (rule enforcement)
    bool canTapBall(int ballNumber) {
      // Logic Simplified: We allow tapping even if it's the last ball.
      // This is necessary to register Fouls/Safes without pocketing the ball (Ball Count remains 1).
      // The GameState.onBallTapped logic handles the "0 points" calculation correctly.
      return true;
    }

    // Helper to validate and handle taps
    void handleTap(int ballNumber) {
       // Disable all ball interactions if game is over
       if (gameState.gameOver) return;
       
       // Enforce rule: cannot tap last ball during foul/safe
       if (!canTapBall(ballNumber)) return;
       
       if (gameState.foulMode == FoulMode.severe && ballNumber != 15) {
        // Trigger progressive hint
        gameState.reportBreakFoulError(ballNumber: ballNumber);
        if (gameState.breakFoulErrorCount == 1) {
             // 1st Error: Hide bubble, Show Dialog immediately
             gameState.setShowBreakFoulHint(false);
             showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Break Foul Rule'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       // Visual Ball 15
                       SizedBox(
                         width: 80, 
                         height: 80,
                         child: BallButton(
                           ballNumber: 15,
                           isActive: true,
                           onTap: () {},
                         ),
                       ),
                       const SizedBox(height: 16),
                       const Text(
                        'Invalid Selection!\n\n'
                        'When Break Foul is active (Severe):\n'
                        '- NO ball was potted.\n'
                        '- You MUST select Ball 15 (0 points).\n'
                        '- Result is -2 points to score.',
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
             );
         }
        return;
      }
      
      if (gameState.showBreakFoulHint) {
        gameState.setShowBreakFoulHint(false);
      }
      
      // Special handling for Ball 15 during Break Foul
      if (gameState.foulMode == FoulMode.severe && ballNumber == 15) {
        // Show info dialog BEFORE processing
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Important Break Foul Rules'),
            content: Text(
              '⚠️ Special Rules:\n\n'
              '• You CAN commit Break Foul again\n'
              '• The 3-Foul rule does NOT apply\n'
              '• Each Break Foul is -2 points\n'
              '• Only Ball 15 ends the turn',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // THEN process the ball tap
                  gameState.onBallTapped(ballNumber);
                },
                child: const Text('Got it!'),
              ),
            ],
          ),
        );
        return;
      }
      
      if (ballNumber == 0) {
        gameState.onDoubleSack();
      } else {
        gameState.onBallTapped(ballNumber);
      }
    }

    // A stack that contains ALL rack balls + Cue Ball + Hint Layer
    Widget rackStack = SizedBox(
      width: rackWidth,
      height: rackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Rack Balls
          for (int r = 0; r < rows.length; r++)
            for (int c = 0; c < rows[r].length; c++)
              Positioned(
                left: (rackWidth - (rows[r].length * diameter)) / 2 + (c * diameter),
                top: r * verticalOffset,
                child: SizedBox(
                  width: diameter,
                  height: diameter,
                  child: BallButton(
                    ballNumber: rows[r][c],
                    isActive: !gameState.gameOver && 
                              gameState.activeBalls.contains(rows[r][c]) &&
                              canTapBall(rows[r][c]),
                    onTap: () => handleTap(rows[r][c]),
                  ),
                ),
              ),

          // Cue Ball (Double Sack)
          Positioned(
            left: ((rackWidth - diameter) / 2) - (diameter * 2.5),
            top: 0, 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: diameter,
                  height: diameter,
                  child: BallButton(
                    ballNumber: 0,
                    isActive: !gameState.gameOver, 
                    onTap: () => handleTap(0),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Double Sack',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),

          // Progressive Error Hint (Bubble) - Show only after 1st error (2nd+)
          // No barrier - taps go through to balls
          if (gameState.breakFoulErrorCount > 1)
             Positioned.fill(
                child: IgnorePointer(
                  child: HintBubble(
                    key: ValueKey(gameState.breakFoulHintMessage),
                    message: gameState.breakFoulHintMessage,
                    // Target: Ball 15 top edge (pointer points DOWN to top of ball)
                    target: Offset(4.5 * diameter, 4 * verticalOffset),
                    containerWidth: rackWidth,
                  ),
                ),
             ),
        ],
      ),
    );

    return [
      // Add generous padding above rack for bubbles to prevent clipping
      const SizedBox(height: 120),
      rackStack,
    ];
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: SteampunkTheme.brassPrimary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier', // Monospace for stats looks cool/techy
          ),
        ),
      ],
    );
  }

  void _show3FoulPopup(BuildContext context, GameState gameState) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('threeFoulPenalty')),
        content: Text(l10n.translate('threeFoulMessage')),
        actions: [
          TextButton(
            onPressed: () {
              gameState.dismissThreeFoulPopup();
              Navigator.of(context).pop();
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('resetGame')),
        content: Text(l10n.translate('resetGameMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Provider.of<GameState>(context, listen: false).resetGame();
              Navigator.of(context).pop();
            },
            child: Text(l10n.translate('reset')),
          ),
        ],
      ),
    );
  }
}
