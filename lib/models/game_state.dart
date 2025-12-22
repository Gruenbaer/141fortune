import 'package:flutter/foundation.dart';
import 'player.dart';
import 'foul_tracker.dart';
import 'achievement_manager.dart';
import '../data/messages.dart';

enum FoulMode { none, normal, severe }

class GameState extends ChangeNotifier {
  final int raceToScore;
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
  
  // Foul Mode Flag
  FoulMode foulMode = FoulMode.none;
  
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

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  GameState({
    required this.raceToScore,
    required List<String> playerNames,
    bool threeFoulRuleEnabled = true,
    this.achievementManager,
  }) {
    players = playerNames
        .map((name) => Player(name: name, isActive: false))
        .toList();
    players[0].isActive = true;
    foulTracker = FoulTracker(threeFoulRuleEnabled: threeFoulRuleEnabled);
    _resetRack();
  }

  void setShowBreakFoulHint(bool show) {
    showBreakFoulHint = show;
    notifyListeners();
  }

  void reportBreakFoulError({int? ballNumber}) {
    breakFoulErrorCount++;
    showBreakFoulHint = true;
    
    // Special Easter egg for Ball 13 (Alex)
    // Only track from 2nd error onwards (when bubbles appear, not info dialog)
    if (ballNumber == 13 && breakFoulErrorCount > 1) {
      ball13ErrorCount++;
      if (ball13ErrorCount == 1) {
        breakFoulHintMessage = "Es ist Freitag der 15!";
      } else if (ball13ErrorCount == 2) {
        breakFoulHintMessage = "Alex...";
      } else if (ball13ErrorCount == 3) {
        breakFoulHintMessage = "ALEX...die 15!";
      } else {
        breakFoulHintMessage = EasterEggs.getRandomBreakFoulMessage();
      }
      
      // Check for Vinzend achievement (13 clicks on 13)
      if (ball13ErrorCount == 13) {
        achievementManager?.unlock('vinzend');
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

  void onSafe() {
    _pushState();
    currentPlayer.incrementSaves();
    _logAction('${currentPlayer.name}: Safe');
    
    foulMode = FoulMode.none; 
    resetBreakFoulError();
    
    _switchPlayer();
    notifyListeners();
  }

  void onBallTapped(int ballNumber) {
    _pushState();
    if (!gameStarted) gameStarted = true;

    // Capture foul mode before reset
    final currentFoulMode = foulMode;
    foulMode = FoulMode.none; // Reset flag immediately
    resetBreakFoulError();

    int points = 15 - ballNumber;
    String foulText = '';

    if (currentFoulMode == FoulMode.normal) {
      final penalty = foulTracker.applyNormalFoul();
      points += penalty;
      foulText = penalty == -15 ? ' (3-Foul!)' : ' (Foul)';
      if (penalty == -15) showThreeFoulPopup = true;
    } else if (currentFoulMode == FoulMode.severe) {
      final penalty = foulTracker.applySevereFoul(); // -2
      points += penalty;
      foulText = ' (Break Foul)';
    } else {
      // Safe shot
      foulTracker.resetOnSuccessfulShot();
    }

    currentPlayer.addScore(points);
    _logAction('${currentPlayer.name}: +$points$foulText');

    // Update Rack
    activeBalls = Set.from(List.generate(ballNumber, (i) => i + 1));

    bool turnEnded = true;

    if (currentFoulMode != FoulMode.none) {
      turnEnded = true;
    } else {
      // Valid shot
      if (ballNumber == 1) {
        // Re-Rack, Continue
        _resetRack();
        turnEnded = false;
        _logAction('${currentPlayer.name}: Re-Rack! ($points pts)');
      } else {
        turnEnded = true;
      }
    }

    // Check win BEFORE switching player!
    _checkWinCondition();
    
    if (turnEnded) {
      _switchPlayer();
    }
    
    notifyListeners();
  }

  void onDoubleSack() {
    _pushState();
    if (!gameStarted) gameStarted = true;

    final currentFoulMode = foulMode;
    foulMode = FoulMode.none;
    resetBreakFoulError();

    int points = 15;
    String foulText = '';

    if (currentFoulMode == FoulMode.normal) {
      final penalty = foulTracker.applyNormalFoul();
      points += penalty; 
      foulText = ' (Foul)'; // Double sack + foul?
      if (penalty == -15) showThreeFoulPopup = true;
    } else if (currentFoulMode == FoulMode.severe) {
       points += -2;
       foulText = ' (Break Foul)';
    } else {
      foulTracker.resetOnSuccessfulShot();
    }

    currentPlayer.addScore(points);
    _logAction('${currentPlayer.name}: Double-Sack! +$points$foulText');
    
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

  // Helper to log actions
  void _logAction(String action) {
    lastAction = action;
    matchLog.insert(0, action); // Newest first
    notifyListeners();
  }

  void _switchPlayer() {
    currentPlayer.isActive = false;
    currentPlayer.incrementInning();
    
    // Switch
    currentPlayerIndex = 1 - currentPlayerIndex;
    
    currentPlayer.isActive = true;
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
    foulMode = FoulMode.none;
    matchLog.clear();
    // We do NOT clear undo stack, so reset can be undone!
    resetBreakFoulError();
    notifyListeners();
  }
  Map<String, dynamic> toJson() => GameSnapshot.fromState(this).toJson();
  
  void loadFromJson(Map<String, dynamic> json) {
     final snapshot = GameSnapshot.fromJson(json);
     snapshot.restore(this);
  }
}

abstract class UndoState {
  void restore(GameState state);
}

class FoulTrackerSnapshot {
  final int consecutiveNormalFouls;
  FoulTrackerSnapshot(this.consecutiveNormalFouls);

  Map<String, dynamic> toJson() => {'consecutiveNormalFouls': consecutiveNormalFouls};
  
  factory FoulTrackerSnapshot.fromJson(Map<String, dynamic> json) {
    return FoulTrackerSnapshot(json['consecutiveNormalFouls'] as int);
  }
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
  final FoulTrackerSnapshot foulTrackerSnapshot;
  final List<String> matchLog;
  final String breakFoulHintMessage;

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
        foulTrackerSnapshot = FoulTrackerSnapshot(state.foulTracker.consecutiveNormalFouls),
        matchLog = List.from(state.matchLog),
        breakFoulHintMessage = state.breakFoulHintMessage;
        
  GameSnapshot.fromJson(Map<String, dynamic> json)
      : players = (json['players'] as List).map((e) => Player.fromJson(e)).toList(),
        activeBalls = Set<int>.from(json['activeBalls'] as List),
        currentPlayerIndex = json['currentPlayerIndex'] as int,
        gameStarted = json['gameStarted'] as bool,
        gameOver = json['gameOver'] as bool? ?? false,
        winnerName = json['winnerName'] as String?,
        lastAction = json['lastAction'] as String?,
        showThreeFoulPopup = json['showThreeFoulPopup'] as bool,
        foulMode = FoulMode.values[json['foulMode'] as int],
        foulTrackerSnapshot = FoulTrackerSnapshot.fromJson(json['foulTrackerSnapshot']),
        matchLog = List<String>.from(json['matchLog'] as List),
        breakFoulHintMessage = json['breakFoulHintMessage'] as String;

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
    'foulTrackerSnapshot': foulTrackerSnapshot.toJson(),
    'matchLog': matchLog,
    'breakFoulHintMessage': breakFoulHintMessage,
  };

  @override
  void restore(GameState state) {
    state.players = players.map((p) => p.copyWith()).toList();
    state.activeBalls = Set.from(activeBalls);
    state.currentPlayerIndex = currentPlayerIndex;
    state.foulTracker.consecutiveNormalFouls = foulTrackerSnapshot.consecutiveNormalFouls;
    state.gameStarted = gameStarted;
    state.gameOver = gameOver;
    // Restore winner by finding player with matching name
    state.winner = winnerName != null 
        ? state.players.firstWhere((p) => p.name == winnerName, orElse: () => state.players[0])
        : null;
    state.lastAction = lastAction;
    state.showThreeFoulPopup = showThreeFoulPopup;
    state.foulMode = foulMode;
    state.matchLog = List.from(matchLog);
    state.breakFoulHintMessage = breakFoulHintMessage;
    state.notifyListeners();
  }
}
