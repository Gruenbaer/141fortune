import 'package:flutter_test/flutter_test.dart';
import 'package:fortune141/models/game_state.dart';

void main() {
  group('GameState Tests', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState(
        raceToScore: 100,
        playerNames: ['Player 1', 'Player 2'],
        threeFoulRuleEnabled: true,
      );
    });

    test('Initial state is correct', () {
      expect(gameState.players[0].score, 0);
      expect(gameState.players[1].score, 0);
      expect(gameState.players[0].isActive, true);
      expect(gameState.players[1].isActive, false);
      expect(gameState.activeBalls.length, 15);
    });

    test('Ball tap awards correct points', () {
      // Tap ball 5 (5 balls left) → 10 points (15-5)
      gameState.onBallTapped(5);
      expect(gameState.players[0].score, 10);
      expect(gameState.activeBalls.length, 5);
      expect(gameState.players[1].isActive, true); // Switched
    });

    test('Ball 1 re-racks and player stays', () {
      gameState.onBallTapped(1);
      expect(gameState.players[0].score, 14); // 15-1
      expect(gameState.activeBalls.length, 15); // Re-racked
      expect(gameState.players[0].isActive, true); // Stayed
    });

    test('Double-Sack gives 15 points and re-racks', () {
      gameState.onDoubleSack();
      expect(gameState.players[0].score, 15);
      expect(gameState.activeBalls.length, 15);
      expect(gameState.players[0].isActive, true); // Stayed
    });

    test('Normal foul deducts 1 point and switches', () {
      gameState.applyNormalFoul();
      expect(gameState.players[0].score, -1);
      expect(gameState.players[1].isActive, true);
    });

    test('3-Foul penalty deducts 15 points (global tracking)', () {
      // Current implementation: 3-foul counter is global, not per-player
      // P1 fouls → -1 foul counter=1, switch to P2
      // P2 fouls → -1, foul counter=2, switch to P1  
      // P1 fouls → -15 (3rd foul triggers penalty), foul counter=0, switch to P2
      
      gameState.applyNormalFoul(); // P1: -1
      gameState.applyNormalFoul(); // P2: -1  
      gameState.applyNormalFoul(); // P1: -1 initially then -15 more = -16 total
      
      // P1 has -16 total (-1 from first + -15 from 3-foul penalty)
      // P2 has -1
      expect(gameState.players[0].score, -16);
      expect(gameState.players[1].score, -1);
      expect(gameState.foulTracker.consecutiveNormalFouls, 0); // Reset
    });

    test('Severe foul does not count toward 3-foul', () {
      gameState.applySevereFoul(); // -2
      expect(gameState.foulTracker.consecutiveNormalFouls, 0);
      expect(gameState.players[0].score, -2);
    });

    test('Successful shot resets foul counter', () {
      gameState.applyNormalFoul();
      gameState.applyNormalFoul();
      expect(gameState.foulTracker.consecutiveNormalFouls, 2);
      
      gameState.onBallTapped(10); // Successful shot
      expect(gameState.foulTracker.consecutiveNormalFouls, 0);
    });
  });
}
