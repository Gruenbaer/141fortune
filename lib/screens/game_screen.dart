import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
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
import '../widgets/steampunk_widgets.dart';
import '../widgets/victory_splash.dart';

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

  Future<void> _saveCompletedGame(GameState gameState) async {
    if (_isCompletedSaved || _gameStartTime == null) return;
    
    final p1 = gameState.players[0];
    final p2 = gameState.players[1];
    final winner = (p1.score >= gameState.raceToScore) ? p1 : (p2.score >= gameState.raceToScore ? p2 : null);
    
    // Only save if we actually have a winner
    if (winner == null) return;

    final record = GameRecord(
      id: _gameId,
      player1Name: p1.name,
      player2Name: p2.name,
      player1Score: p1.score,
      player2Score: p2.score,
      startTime: _gameStartTime!,
      endTime: DateTime.now(),
      isCompleted: true,
      winner: winner.name,
      raceToScore: gameState.raceToScore,
      player1Innings: p1.currentInning,
      player2Innings: p2.currentInning,
      player1Fouls: 0, // Not exposed in Player model yet
      player2Fouls: 0, // Not exposed in Player model yet, needs GameState method
    );
    
    await _historyService.saveGame(record);
    _isCompletedSaved = true;
  }

  @override
  void initState() {
    super.initState();
    
    if (widget.resumeGame != null) {
      _gameId = widget.resumeGame!.id;
      _gameStartTime = widget.resumeGame!.startTime;
      
      // Load state after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final gameState = Provider.of<GameState>(context, listen: false);
        if (widget.resumeGame!.snapshot != null) {
           gameState.loadFromJson(widget.resumeGame!.snapshot!);
        }
      });
    } else {
      _gameId = DateTime.now().millisecondsSinceEpoch.toString();
      _gameStartTime = DateTime.now();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final achievementManager = Provider.of<AchievementManager>(context, listen: false);
      achievementManager.onAchievementUnlocked = (achievement) {
        setState(() {
          _achievementToShow = achievement;
        });
      };
    });
  }

  @override
  void deactivate() {
    // Save game on exit
    final gameState = Provider.of<GameState>(context, listen: false);
    if (!gameState.gameStarted) {
       // Maybe delete empty game?
    } else {
       _saveInProgressGame(gameState);
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to provider for Undo/Redo button state
    final gameState = Provider.of<GameState>(context);

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
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  color: SteampunkTheme.brassPrimary,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Text(
                'Fortune 14/2',
                style: SteampunkTheme.themeData.textTheme.displaySmall,
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.analytics_outlined),
                  color: SteampunkTheme.brassPrimary,
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
                  color: SteampunkTheme.brassPrimary,
                  tooltip: 'Settings',
                  onPressed: () async {
                    final updateSettings = Provider.of<Function(GameSettings)>(context, listen: false);
                    final currentSettings = Provider.of<GameSettings>(context, listen: false);
                    
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                          currentSettings: currentSettings,
                          onSettingsChanged: updateSettings,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.undo),
                  color: SteampunkTheme.brassPrimary,
                  tooltip: 'Undo',
                  onPressed: gameState.canUndo ? gameState.undo : null,
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  color: SteampunkTheme.brassPrimary,
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
                        'Fortune 14/2',
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
                      });
                    }

                    return Column(
                      children: [
                        // Top: Scoreboard Area
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: SteampunkTheme.brassDark, width: 2)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'RACE TO ${gameState.raceToScore}',
                                style: SteampunkTheme.themeData.textTheme.labelLarge?.copyWith(
                                  color: SteampunkTheme.brassPrimary,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: PlayerPlaque(
                                      player: gameState.players[0],
                                      raceToScore: gameState.raceToScore,
                                      isLeft: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: PlayerPlaque(
                                      player: gameState.players[1],
                                      raceToScore: gameState.raceToScore,
                                      isLeft: false,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Notification / Action Log
                        if (gameState.lastAction != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            color: Colors.black38,
                            child: Text(
                              gameState.lastAction!.toUpperCase(),
                              style: SteampunkTheme.themeData.textTheme.bodySmall?.copyWith(
                                color: SteampunkTheme.brassBright,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Ball Rack
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Decorative Gears behind the rack
                              Opacity(
                                opacity: 0.1,
                                child: Image.asset('assets/images/ui/gears.png', fit: BoxFit.contain),
                              ),
                              // The Rack
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
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
                                      ? 'NO FOUL' 
                                      : (gameState.foulMode == FoulMode.normal ? 'FOUL -1' : 'BREAK FOUL -2'),
                                  icon: gameState.foulMode == FoulMode.none 
                                      ? Icons.flag_outlined 
                                      : (gameState.foulMode == FoulMode.normal ? Icons.flag : Icons.warning_amber_rounded),
                                  textColor: gameState.foulMode == FoulMode.none
                                      ? null // Default color
                                      : (gameState.foulMode == FoulMode.normal 
                                          ? const Color(0xFFCC6600) // Orange for -1
                                          : const Color(0xFFCC0000)), // Red for -2
                                  onPressed: gameState.gameOver ? () {} : () {
                                     FoulMode next;
                                     switch (gameState.foulMode) {
                                       case FoulMode.none: next = FoulMode.normal; break;
                                       case FoulMode.normal: next = FoulMode.severe; break;
                                       case FoulMode.severe: next = FoulMode.none; break;
                                     }
                                     gameState.setFoulMode(next);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Safe Button
                              Expanded(
                                child: SteampunkButton(
                                  label: 'SAFE',
                                  icon: Icons.shield,
                                  onPressed: gameState.gameOver ? () {} : gameState.onSafe,
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
          
        // Victory Splash Overlay
        if (gameState.gameOver && gameState.winner != null)
          VictorySplash(
            winner: gameState.winner!,
            loser: gameState.players.firstWhere((p) => p != gameState.winner),
            raceToScore: gameState.raceToScore,
            onNewGame: () {
              gameState.resetGame();
            },
            onExit: () {
              Navigator.of(context).pop();
            },
          ),
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

    // Helper to validate and handle taps
    void handleTap(int ballNumber) {
       // Disable all ball interactions if game is over
       if (gameState.gameOver) return;
       
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

    // A stack that contains ALL rack balls + Cue Ball

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
                    isActive: !gameState.gameOver && gameState.activeBalls.contains(rows[r][c]),
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
