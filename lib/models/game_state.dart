import 'package:flutter/foundation.dart';
import 'dart:async';
import 'player.dart';
import 'foul_tracker.dart';
import 'achievement_manager.dart';
import '../data/messages.dart';
import 'game_settings.dart';

enum FoulMode { none, normal, severe }

// Event System for UI Animations
abstract class GameEvent {}

class FoulEvent extends GameEvent {
  final Player player;
  final int points;
  final String message;
  final int? positivePoints; // Optional: balls pocketed for breakdown display
  final int? penalty; // Optional: foul penalty for breakdown display
  
  FoulEvent(this.player, this.points, this.message, {this.positivePoints, this.penalty});
}

class WarningEvent extends GameEvent {
  final String title;
  final String message;
  WarningEvent(this.title, this.message);
}

class ReRackEvent extends GameEvent {
  final String type; // "14.1 Continuous", "After Foul", "Auto/Safe"
  ReRackEvent(this.type);
}


class DecisionEvent extends GameEvent {
  final String title;
  final String message;
  final List<String> options;
  final Function(int) onOptionSelected;

  DecisionEvent(this.title, this.message, this.options, this.onOptionSelected);
}

class SafeEvent extends GameEvent {}


class GameState extends ChangeNotifier {
  GameSettings settings;
  int raceToScore;
  late List<Player> players;
  late FoulTracker foulTracker;
  late AchievementManager? achievementManager;
  Set<int> activeBalls = {};
  int currentPlayerIndex = 0;
  bool gameStarted = false;
  bool gameOver = false;
  Player? winner;
  String? lastAction;
  bool showThreeFoulPopup = false;
  bool showTwoFoulWarning = false;
  
  // Foul Mode Flag
  FoulMode foulMode = FoulMode.none;
  // Safe Mode Toggle
  bool isSafeMode = false;
  
  // Break Sequence Flag (True at start, false after first valid shot)
  bool inBreakSequence = true;
  
  // UI Hint Flag
  bool showBreakFoulHint = false;
  int breakFoulErrorCount = 0;
  int ball13ErrorCount = 0; // Easter egg for Alex
  String breakFoulHintMessage = "Only Ball 15!";
  
  // Match History
  List<String> matchLog = [];
  
  // Undo/Redo Stacks
  final List<GameSnapshot> _undoStack = [];
  final List<GameSnapshot> _redoStack = [];

  // UI Event Queue (Consumed by UI)
  final List<GameEvent> eventQueue = [];


  bool get canUndo => _undoStack.isNotEmpty;
  
  // Robust check for Break Foul availability
  // Available if explicitly in sequence OR if game hasn't really started (log empty)
  bool get canBreakFoul => inBreakSequence || matchLog.isEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // Game Clock
  final Stopwatch _gameTimer = Stopwatch();
  Duration _savedDuration = Duration.zero; // For persistence
  
  Timer? _ticker;
  bool _isPaused = false;
  
  bool get isPaused => _isPaused;
  Duration get elapsedDuration => _savedDuration + _gameTimer.elapsed;

  void startGameTimer() {
    if (!gameStarted) return;
    if (!_gameTimer.isRunning && !_isPaused) {
      _gameTimer.start();
      _startTicker();
    }
  }

  void pauseGame() {
    if (_gameTimer.isRunning) {
      _gameTimer.stop();
      _isPaused = true;
      _stopTicker();
      notifyListeners();
    }
  }

  void resumeGame() {
    if (_isPaused) {
      _gameTimer.start();
      _isPaused = false;
      _startTicker();
      notifyListeners();
    }
  }

  void togglePause() {
    if (_isPaused) {
      resumeGame();
    } else {
      pauseGame();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners(); // Update UI every second
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
  
  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  GameState({
    required this.settings,
    this.achievementManager,
  }) : raceToScore = settings.raceToScore {
    // Initialize Players
    players = [
      Player(
        name: settings.player1Name, 
        isActive: true, // P1 starts active by default
        score: settings.player1Handicap,
        handicapMultiplier: settings.player1HandicapMultiplier
      ),
      Player(
        name: settings.player2Name, 
        isActive: false, 
        score: settings.player2Handicap,
        handicapMultiplier: settings.player2HandicapMultiplier
      )
    ];

    foulTracker = FoulTracker(threeFoulRuleEnabled: settings.threeFoulRuleEnabled);
    _resetRack();
  }

  // Update settings mid-game
  void updateSettings(dynamic settings) {
    bool somethingChanged = false;
    
    // Update Race to Score
    if (raceToScore != settings.raceToScore) {
      raceToScore = settings.raceToScore;
      somethingChanged = true;
      _logAction('Race to Score changed to $raceToScore');
    }

    // Update 3-Foul Rule
    if (foulTracker.threeFoulRuleEnabled != settings.threeFoulRuleEnabled) {
      foulTracker.threeFoulRuleEnabled = settings.threeFoulRuleEnabled;
      somethingChanged = true;
      _logAction('3-Foul Rule ${settings.threeFoulRuleEnabled ? "Enabled" : "Disabled"}');
    }

    // Update Player Names (if changed)
    if (players[0].name != settings.player1Name) {
       players[0] = players[0].copyWith(name: settings.player1Name);
       somethingChanged = true;
       _logAction('Player 1 renamed to ${settings.player1Name}');
    }

    if (players[1].name != settings.player2Name) {
       players[1] = players[1].copyWith(name: settings.player2Name);
       somethingChanged = true;
       _logAction('Player 2 renamed to ${settings.player2Name}');
    }

    // Update Handicap Multipliers
    if (players[0].handicapMultiplier != settings.player1HandicapMultiplier) {
      players[0] = players[0].copyWith(handicapMultiplier: settings.player1HandicapMultiplier);
      somethingChanged = true;
       _logAction('Player 1 Handicap changed to ${settings.player1HandicapMultiplier}x');
    }

    if (players[1].handicapMultiplier != settings.player2HandicapMultiplier) {
      players[1] = players[1].copyWith(handicapMultiplier: settings.player2HandicapMultiplier);
      somethingChanged = true;
       _logAction('Player 2 Handicap changed to ${settings.player2HandicapMultiplier}x');
    }
    
    // Check win condition if score limit was lowered
    if (somethingChanged) {
      _checkWinCondition();
      notifyListeners();
    }
  }

  void setShowBreakFoulHint(bool show) {
    showBreakFoulHint = show;
    notifyListeners();
  }

  void reportBreakFoulError({int? ballNumber}) {
    breakFoulErrorCount++;
    showBreakFoulHint = true;
    
    // Special Easter egg for Ball 13 (Alex)
    if (ballNumber == 13) {
      ball13ErrorCount++;
      
      // Update hint message based on count
      if (ball13ErrorCount == 1) {
         // Standard random message for first tap, or keep unique?
         // Let's keep it subtle at first
         breakFoulHintMessage = EasterEggs.getRandomBreakFoulMessage();
      } else if (ball13ErrorCount == 2) {
         breakFoulHintMessage = "Es ist Freitag der 15!";
      } else if (ball13ErrorCount == 5) {
         breakFoulHintMessage = "Alex...";
      } else if (ball13ErrorCount == 10) {
         breakFoulHintMessage = "ALEX...die 15!";
      } else {
         breakFoulHintMessage = EasterEggs.getRandomBreakFoulMessage();
       
       breakFoulHintMessage = EasterEggs.getRandomBreakFoulMessage();
      }
    } else {
      breakFoulHintMessage = EasterEggs.getRandomBreakFoulMessage();
    }
    
    notifyListeners();
  }
  
  void resetBreakFoulError() {
    breakFoulErrorCount = 0;
    ball13ErrorCount = 0;
    showBreakFoulHint = false;
    notifyListeners();
  }

  Player get currentPlayer => players[currentPlayerIndex];
  Player get otherPlayer => players[1 - currentPlayerIndex];

  void dismissThreeFoulPopup() {
    showThreeFoulPopup = false;
    notifyListeners();
  }

  void dismissTwoFoulWarning() {
    showTwoFoulWarning = false;
    notifyListeners();
  }

  void _resetRack() {
    activeBalls = Set.from(List.generate(15, (i) => i + 1));
    notifyListeners();
  }
  
  void _pushState() {
    _undoStack.add(GameSnapshot.fromState(this));
    _redoStack.clear(); // clear redo on new action
  }

  void undo() {
    if (!canUndo) return;
    final currentSnapshot = GameSnapshot.fromState(this);
    _redoStack.add(currentSnapshot);

    final snapshot = _undoStack.removeLast();
    snapshot.restore(this);
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    final currentSnapshot = GameSnapshot.fromState(this);
    _undoStack.add(currentSnapshot);

    final snapshot = _redoStack.removeLast();
    snapshot.restore(this);
    notifyListeners();
  }

  void setFoulMode(FoulMode mode) {
    foulMode = mode;
    resetBreakFoulError();
    notifyListeners();
  }

  
  // Toggle Safe Mode
  void onSafe() {
    if (!isSafeMode) {
      // ENTER Safe Mode
      isSafeMode = true;
      notifyListeners();
    } else {
      // CONFIRM Standard Safe (No points, Switch Player)
      _pushState();
      currentPlayer.incrementSaves();
      _logAction('${currentPlayer.name}: Safe (Standard)');
      
      foulMode = FoulMode.none; 
      isSafeMode = false; // Reset mode
      resetBreakFoulError();
      
      eventQueue.add(SafeEvent()); // Queue animation
      _switchPlayer();
      notifyListeners();
    }
  }

  void onBallTapped(int ballNumber) {
    _pushState();
    if (!gameStarted) {
      gameStarted = true;
      startGameTimer();
    }

    // Capture foul mode before reset
    final currentFoulMode = foulMode;
    foulMode = FoulMode.none; // Reset flag
    resetBreakFoulError();

    // SAFE MODE: Defensive Pocket (Special Case)
    // If we are in Safe Mode, tapping a ball usually means "I pocketed this ball defensively".
    // But with "Balls Remaining" logic, tapping a number means "This many are left".
    // So if I have 15, and I play defensivle and pocket 1, there are 14 left. I tap 14.
    // If Safe Mode is ON, we treat the DELTA as purely defensive points/stats? 
    // Or does the user explicitly "Tap Safe" button to confirm?
    // User Instructions: "Tapping a ball (while in Safe Mode) registers a 'Defensive Pocket' (1 point, end turn)."
    // If logic is "Balls Remaining", the user would tap the NEW count. 
    // Example: 15 on table. Safe Mode ON. I pocket 1 ball. I tap 14 (Balls Left).
    // Delta = 1. Score +1. Turn Ends.
    
    // Calculate Delta (Points Scored)
    int currentBallCount = activeBalls.length;
    int newBallCount = ballNumber;
    int points = currentBallCount - newBallCount;
    
    // Safety check: specific case for "Re-Rack" scenarios might act oddly, 
    // but assuming standard 15-ball to 0-ball flow.
    
    // Safe Mode Logic: Defensive Pocket
    if (isSafeMode) {
      isSafeMode = false; // Consume mode
      
      // If points > 0, we pocketed balls defensively
      if (points > 0) {
        // Apply Handicap Multiplier to positive points (Defensive Pocket counts as positive score)
        final scoredPoints = (points * currentPlayer.handicapMultiplier).round();
        currentPlayer.addScore(scoredPoints);
        currentPlayer.incrementSaves(); 
        _logAction('${currentPlayer.name}: Defensive Pocket (+$scoredPoints)');
        
        // Update rack to new count
        _updateRackCount(newBallCount);
      } else {
        // Did not reduce count? Maybe just tapped same number?
        // Treat as standard safe if 0?
        _logAction('${currentPlayer.name}: Safe (No balls pocketed)');
        currentPlayer.incrementSaves();
      }

      if (newBallCount == 1) {
        _updateRackCount(15);
        _logAction('${currentPlayer.name}: Re-rack (Auto/Safe)');
      }

      _checkWinCondition();
      eventQueue.add(SafeEvent()); // Queue animation for Defensive Pocket too
      _switchPlayer(); 
      notifyListeners();
      return;
    }

    // STANDARD PLAY
    String foulText = '';

    if (currentFoulMode == FoulMode.normal) {
      final penalty = foulTracker.applyNormalFoul(currentPlayer); // Use current Player
      // Calculate scored points once if needed
      int? scoredPoints;
      if (points > 0) {
        scoredPoints = (points * currentPlayer.handicapMultiplier).round();
        currentPlayer.addScore(scoredPoints);
      }
      currentPlayer.addScore(penalty);
      foulText = penalty == -15 ? ' (3-Foul!)' : ' (Foul)';
      
      // Queue Event for Animation
      if (penalty == -15) {
        // 3-Foul! Queue the big one.
        eventQueue.add(FoulEvent(currentPlayer, -15, "Triple Foul!"));
        showThreeFoulPopup = true; // State persistence only
        // Queue the Dialog as an Event for proper sequencing
        eventQueue.add(WarningEvent(
           "3 FOULS!", 
           "Three consecutive fouls.\nPenalty: -15 Points."
        ));
      } else if (scoredPoints != null) {
        // Show breakdown: positive points and foul penalty
        eventQueue.add(FoulEvent(currentPlayer, scoredPoints + penalty, "Foul!", positivePoints: scoredPoints, penalty: penalty));
      } else {
        // Just penalty, no positive points
        eventQueue.add(FoulEvent(currentPlayer, penalty, "Foul!"));
      }
    } else if (currentFoulMode == FoulMode.severe) {
      final penalty = foulTracker.applySevereFoul(currentPlayer); // Use current Player
      currentPlayer.addScore(penalty);
      // BREAK FOUL DIALOG REMOVED - User doesn't want any info/warnings
      // foulText = ' (Break Foul)';
      
      eventQueue.add(FoulEvent(currentPlayer, penalty, "Break Foul!")); // Usually -2
      
      // Break Foul Decision: Who breaks next?
      // Use local variable capture for safe closure
      final p1 = players[0];
      final p2 = players[1];
      
      eventQueue.add(DecisionEvent(
        "WHO BREAKS NEXT?", 
        "Break Foul Rule: Decide who takes the next break shot.",
        [p1.name, p2.name],
        (selectedIndex) {
             // 0 = P1, 1 = P2
             final selectedPlayer = selectedIndex == 0 ? p1 : p2;
             
             // Logic: Set Active Player to selected
             // If selected is currently active, DO NOT switch.
             // If selected is NOT active, DO switch.
             if (currentPlayer != selectedPlayer) {
                _switchPlayer(); 
             }
             
             // Ensure Rack is Reset for the Break
             _updateRackCount(15);
             notifyListeners();
        }
      ));
      
      // Prevent standard switchPlayer at end of 'onBallTapped' 
      // We handle turn switching in the callback above. 
      // But 'onBallTapped' is void and continues... 
      // The current logic calls `_switchPlayer()` at the END of onBallTapped typically?
      // Wait, let's check lines 460+
    } else {
      // Valid Shot
      currentPlayer.consecutiveFouls = 0; // Reset consecutive fouls on valid shot/safe
      
      // Normal Points
      if (points != 0) {
         if (points > 0) {
           final scoredPoints = (points * currentPlayer.handicapMultiplier).round();
           currentPlayer.addScore(scoredPoints);
           // Queue animation event for positive points
           eventQueue.add(FoulEvent(currentPlayer, scoredPoints, ""));
         } else {
           // Negative points? Logic usually prevents this unless input error.
           // If balls tapped < balls previous, points is positive.
           // If NEW count > OLD count? (Balls added?) -> points negative.
           // Usually we don't multiply negative.
           currentPlayer.addScore(points);
         }
      }
    }


    // Log calculation
    if (points != 0 || foulText.isNotEmpty) {
      // Calculate effective displayed points for log
      int displayPoints = points;
      if (currentFoulMode == FoulMode.none && points > 0) {
        displayPoints = (points * currentPlayer.handicapMultiplier).round();
      }
      
      String sign = displayPoints > 0 ? "+" : "";
      _logAction('${currentPlayer.name}: $sign$displayPoints pts$foulText (Left: $newBallCount)');
    }

    // Update Rack State
    _updateRackCount(newBallCount);

    // RE-RACK LOGIC (User Request: "If there is only one ball, a rerack is done.")
    // Whether we arrived here by Pot, Foul, or Safe -> If 1 ball remains, we rack the other 14.
    bool isReRack = false;
    
    if (newBallCount == 1) {
      _updateRackCount(15); // Reset to full rack (14 + 1)
      
      _logAction('${currentPlayer.name}: Re-rack');
      // Queue re-rack animation event
      eventQueue.add(ReRackEvent("Re-rack!"));
      isReRack = true;
    }

    bool turnEnded = false;

    // TURN SWITCHING LOGIC per rules:
    // "Automatischer Spielerwechsel: Nach jedem Ball (außer Ball 1 und Weiße)"
    // Turn switches after EVERY ball potted, EXCEPT:
    // - Re-rack scenarios (Ball 1) - player continues
    // - Double Sack (handled separately) - player continues
    // - Fouls always end turn
    if (currentFoulMode == FoulMode.none) {
      if (points > 0) {
        // Player potted ball(s) - turn ENDS (rule: switch after every ball)
        // Exception: Re-rack at Ball 1 - player continues
        if (isReRack) {
          turnEnded = false; // Player continues after re-rack
        } else {
          turnEnded = true; // Normal ball pot - switch turns
        }
      } else if (points <= 0) {
        // Miss/Safe (0 points or negative)
        turnEnded = true; 
        _logAction('${currentPlayer.name}: Miss/Safe (0 pts)');
        currentPlayer.incrementSaves(); 
      }
    } else {
      if (currentFoulMode == FoulMode.severe) {
        // Break Foul: Turn switch is handled by DecisionEvent callback
        turnEnded = false; 
      } else {
        turnEnded = true; // Normal Foul always ends turn
      }
    }

    // BREAK FOUL SEQUENCE LOGIC
    // If we just committed a Severe Foul, we stay in Break Sequence (allow another severe).
    // Otherwise, any other action ends the Break Sequence.
    if (currentFoulMode == FoulMode.severe) {
      inBreakSequence = true; 
    } else {
      inBreakSequence = false;
    }

    // If we cleared the rack (0? or 1?), user enters Re-rack manually or we detect logic.
    // If balls == 1, usually we ask for rerack.
    // Let's assume user manages rack flow via buttons.
    // If they input a count, we trust it.

    _checkWinCondition();
    
    if (turnEnded) {
      _switchPlayer();
    }
    
    notifyListeners();
  }

  void _updateRackCount(int count) {
    if (count < 0) count = 0;
    if (count > 15) count = 15;
    activeBalls = Set.from(List.generate(count, (i) => i + 1));
  }

  void onDoubleSack() {
    _pushState();
    if (!gameStarted) {
      gameStarted = true;
      startGameTimer();
    }

    final currentFoulMode = foulMode;
    foulMode = FoulMode.none;
    resetBreakFoulError();

    // Award points based on actual balls remaining on table
    int ballsRemaining = activeBalls.length;
    int points = ballsRemaining;
    String foulText = '';

    if (currentFoulMode == FoulMode.normal) {
      final penalty = foulTracker.applyNormalFoul(currentPlayer);
      points += penalty; 
      foulText = ' (Foul)'; 
      if (penalty == -15) showThreeFoulPopup = true;
    } else if (currentFoulMode == FoulMode.severe) {
       points += -2;
       foulText = ' (Break Foul)';
    } else {
      currentPlayer.consecutiveFouls = 0;
    }

    // Apply multiplier to the POSITIVE portion (ballsRemaining).
    // Penalties were added to points above.
    // Extract penalty, multiply the positive ball count, then add penalty back
    int penalty = points - ballsRemaining;
    int multipliedPoints = (ballsRemaining * currentPlayer.handicapMultiplier).round() + penalty;
    
    currentPlayer.addScore(multipliedPoints);
    _logAction('${currentPlayer.name}: Double-sack! +$multipliedPoints$foulText');
    
    // Queue animation events - show breakdown if there's a penalty
    if (penalty != 0) {
      // Show breakdown: positive points (green) and penalty (red)
      int multipliedBalls = (ballsRemaining * currentPlayer.handicapMultiplier).round();
      eventQueue.add(FoulEvent(
        currentPlayer, 
        multipliedPoints, 
        "",
        positivePoints: multipliedBalls,
        penalty: penalty,
      ));
    } else {
      // No penalty - just show total
      eventQueue.add(FoulEvent(currentPlayer, multipliedPoints, ""));
    }
    
    // Queue rerack animation
    eventQueue.add(ReRackEvent("Re-rack!"));
    
    _resetRack();

    // Check win BEFORE potentially switching player
    _checkWinCondition();

    // Double Sack: Player continues turn.
    // unless foul? Usually double sack is re-rack same player.
    // If foul, it's foul.
    if (currentFoulMode != FoulMode.none) {
       _switchPlayer();
    }

    notifyListeners();
  }

  // Helper to log actions with inning tracking
  void _logAction(String action) {
    // Get current player's inning number
    int currentInning = currentPlayer.currentInning;
    
    // Prefix with inning marker: "I{inning} | {action}"
    String logEntry = 'I$currentInning | $action';
    
    lastAction = logEntry;
    matchLog.insert(0, logEntry); // Newest first
    notifyListeners();
  }

  void _switchPlayer() {
    currentPlayer.isActive = false;
    currentPlayer.incrementInning();
    
    // Switch
    currentPlayerIndex = 1 - currentPlayerIndex;
    
    currentPlayer.isActive = true;

    // Check for 2-Foul Warning upon entering turn
    if (foulTracker.threeFoulRuleEnabled && currentPlayer.consecutiveFouls == 2) {
      // Replaced showTwoFoulWarning flag with Event
      eventQueue.add(WarningEvent(
         "2 FOULS!", 
         "You are on 2 consecutive fouls.\nOne more foul will result in a \n-15 points penalty!"
      ));
    }

    notifyListeners();
  }

  // Method to consume events (UI calls this)
  List<GameEvent> consumeEvents() {
    final events = List<GameEvent>.from(eventQueue);
    eventQueue.clear();
    return events;
  }

  // Allow swapping starting player before game starts
  void swapStartingPlayer() {
    if (gameStarted || matchLog.isNotEmpty) return; // Only allow at start

    _pushState();
    
    // Deactivate current
    players[currentPlayerIndex].isActive = false;
    
    // Swap index
    currentPlayerIndex = 1 - currentPlayerIndex;
    
    // Activate new
    players[currentPlayerIndex].isActive = true;
    
    _logAction('Starting Player Swapped to ${currentPlayer.name}');
    // Clear log because we just added an action but game hasn't "started" for scoring purposes?
    // Actually, swapping starting player shouldn't be in match log usually? 
    // Or maybe it is fine. But "gameStarted" flag triggers on first shot.
    // If we log it, matchLog is not empty, so next swap fails. 
    // Let's NOT log it, or clear log.
    matchLog.clear(); 
    notifyListeners();
  }

  void _checkWinCondition() {
    // Check ALL players for win (in case of edge cases)
    for (var player in players) {
      if (player.score >= raceToScore && !gameOver) {
        gameOver = true;
        winner = player;
        _logAction('${player.name} WINS! 🎉');
        // TODO: Trigger win achievements in future
        notifyListeners();
        return; // Exit after first winner found
      }
    }
  }

  void resetGame() {
    _pushState();
    for (var player in players) {
      player.score = 0;
      player.currentInning = 1;
      player.saves = 0;
      player.isActive = false;
    }
    players[0].isActive = true;
    currentPlayerIndex = 0;
    foulTracker.reset();
    _resetRack();
    gameStarted = false;
    gameOver = false;
    winner = null;
    lastAction = null;
    showThreeFoulPopup = false;
    showTwoFoulWarning = false;
    foulMode = FoulMode.none;
    matchLog.clear();
    // We do NOT clear undo stack, so reset can be undone!
    resetBreakFoulError();
    inBreakSequence = true; // Reset Break Sequence Logic
    notifyListeners();
  }
  Map<String, dynamic> toJson() => GameSnapshot.fromState(this).toJson();
  
  void loadFromJson(Map<String, dynamic> json) {
     final snapshot = GameSnapshot.fromJson(json);
     snapshot.restore(this);
     
     // Resume timer if game was in progress and we just loaded it
     // But wait! snapshot restores 'gameStarted'. 
     // Should we auto-resume timer? 
     // Probably yes, but let's pause it initially to be safe? 
     // Or effectively "resume" the stopwatch if it was running?
     // Since Stopwatch doesn't persist, we rely on 'elapsed' if we persisted it.
     // Current implementation doesn't persist 'elapsed' yet.
     // Let's add that to GameSnapshot first.
     notifyListeners();
  }
}

abstract class UndoState {
  void restore(GameState state);
}

class GameSnapshot implements UndoState {
  final List<Player> players;
  final Set<int> activeBalls;
  final int currentPlayerIndex;
  final bool gameStarted;
  final bool gameOver;
  final String? winnerName;
  final String? lastAction;
  final bool showThreeFoulPopup;
  final FoulMode foulMode;
  // final FoulTrackerSnapshot foulTrackerSnapshot; // REMOVED
  final List<String> matchLog;
  final String breakFoulHintMessage;
  final bool inBreakSequence; // Persistence
  final int elapsedDurationInSeconds; // Persistence

  GameSnapshot.fromState(GameState state)
      : players = state.players.map((p) => p.copyWith()).toList(),
        activeBalls = Set.from(state.activeBalls),
        currentPlayerIndex = state.currentPlayerIndex,
        gameStarted = state.gameStarted,
        gameOver = state.gameOver,
        winnerName = state.winner?.name,
        lastAction = state.lastAction,
        showThreeFoulPopup = state.showThreeFoulPopup,
        foulMode = state.foulMode,
        // foulTrackerSnapshot = FoulTrackerSnapshot(state.foulTracker.consecutiveNormalFouls), // REMOVED
        matchLog = List.from(state.matchLog),
        breakFoulHintMessage = state.breakFoulHintMessage,
        inBreakSequence = state.inBreakSequence,
        elapsedDurationInSeconds = state.elapsedDuration.inSeconds;
        
  GameSnapshot.fromJson(Map<String, dynamic> json)
      : players = (json['players'] as List).map((e) => Player.fromJson(e)).toList(),
        activeBalls = Set<int>.from(json['activeBalls'] as List),
        currentPlayerIndex = json['currentPlayerIndex'] as int,
        gameStarted = json['gameStarted'] as bool,
        gameOver = json['gameOver'] as bool? ?? false,
        winnerName = json['winnerName'] as String?,
        lastAction = json['lastAction'] as String?,
        showThreeFoulPopup = json['showThreeFoulPopup'] as bool,
        foulMode = (json['foulMode'] as int?) != null && 
                   (json['foulMode'] as int) < FoulMode.values.length 
            ? FoulMode.values[json['foulMode'] as int] 
            : FoulMode.none,
        // foulTrackerSnapshot = FoulTrackerSnapshot.fromJson(json['foulTrackerSnapshot']), // REMOVED
        matchLog = List<String>.from(json['matchLog'] as List),
        breakFoulHintMessage = json['breakFoulHintMessage'] as String,
        inBreakSequence = json['inBreakSequence'] as bool? ?? true,
        elapsedDurationInSeconds = json['elapsedDurationInSeconds'] as int? ?? 0;

  Map<String, dynamic> toJson() => {
    'players': players.map((p) => p.toJson()).toList(),
    'activeBalls': activeBalls.toList(),
    'currentPlayerIndex': currentPlayerIndex,
    'gameStarted': gameStarted,
    'gameOver': gameOver,
    'winnerName': winnerName,
    'lastAction': lastAction,
    'showThreeFoulPopup': showThreeFoulPopup,
    'foulMode': foulMode.index,
    // 'foulTrackerSnapshot': foulTrackerSnapshot.toJson(), // REMOVED
    'matchLog': matchLog,
    'breakFoulHintMessage': breakFoulHintMessage,
    'inBreakSequence': inBreakSequence,
    'elapsedDurationInSeconds': elapsedDurationInSeconds,
  };

  @override
  void restore(GameState state) {
    state.players = players.map((p) => p.copyWith()).toList();
    state.activeBalls = Set.from(activeBalls);
    state.currentPlayerIndex = currentPlayerIndex;
    // state.foulTracker.consecutiveNormalFouls = foulTrackerSnapshot.consecutiveNormalFouls; // REMOVED
    state.gameStarted = gameStarted;
    state.gameOver = gameOver;
    // Restore winner by finding player with matching name
    state.winner = winnerName != null 
        ? state.players.firstWhere((p) => p.name == winnerName, orElse: () => state.players[0])
        : null;
    state.lastAction = lastAction;
    state.showThreeFoulPopup = showThreeFoulPopup;
    state.inBreakSequence = inBreakSequence;
    state.foulMode = foulMode;
    state.matchLog = List.from(matchLog);
    state.breakFoulHintMessage = breakFoulHintMessage;
    
    // Restore Timer
    state._savedDuration = Duration(seconds: elapsedDurationInSeconds);
    state._gameTimer.reset(); // Reset active stopwatch
    // If game was running, should we auto-resume? 
    // Usually safe to default to paused or resume if we know it was running?
    // let's leave it paused for safety, user can resume.
    // actually, if we are loading from JSON (app restart), pausing is good.
    // if we are undoing, we probably want to keep current running state?
    // Undo logic might be tricky with timer. 
    // actually, if we are loading from JSON (app restart), pausing is good.
    // if we are undoing, we probably want to keep current running state?
    // Undo logic might be tricky with timer. 
    // Let's just restore the accumulated time.
  }
}
