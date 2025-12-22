// Add these methods to _GameScreenState class in game_screen.dart

// Save completed game to history
Future<void> _saveCompletedGame(GameState gameState) async {
  if (_gameStartTime == null) return;
  
  final winner = gameState.player1.score >= gameState.raceToScore 
      ? gameState.player1.name 
      : gameState.player2.name;
  
  final record = GameRecord(
    id: _gameId,
    player1Name: gameState.player1.name,
    player2Name: gameState.player2.name,
    player1Score: gameState.player1.score,
    player2Score: gameState.player2.score,
    startTime: _gameStartTime!,
    endTime: DateTime.now(),
    isCompleted: true,
    winner: winner,
    raceToScore: gameState.raceToScore,
    player1Innings: gameState.player1.currentInning,
    player2Innings: gameState.player2.currentInning,
    player1Fouls: gameState.player1.consecutiveFouls,
    player2Fouls: gameState.player2.consecutiveFouls,
  );
  
  await _historyService.saveGame(record);
}

// Save in-progress game to history  
Future<void> _saveInProgressGame(GameState gameState) async {
  if (_gameStartTime == null) return;
  
  final record = GameRecord(
    id: _gameId,
    player1Name: gameState.player1.name,
    player2Name: gameState.player2.name,
    player1Score: gameState.player1.score,
    player2Score: gameState.player2.score,
    startTime: _gameStartTime!,
    isCompleted: false,
    raceToScore: gameState.raceToScore,
    player1Innings: gameState.player1.currentInning,
    player2Innings: gameState.player2.currentInning,
    player1Fouls: gameState.player1.consecutiveFouls,
    player2Fouls: gameState.player2.consecutiveFouls,
    activeBalls: gameState.getActiveBalls(), // Need to add this method to GameState
    player1IsActive: gameState.player1.isActive,
  );
  
  await _historyService.saveGame(record);
}
