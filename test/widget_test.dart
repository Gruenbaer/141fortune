import 'package:flutter_test/flutter_test.dart';
import 'package:fortune141/models/game_state.dart';
import 'package:fortune141/models/game_settings.dart';
import 'package:fortune141/models/achievement_manager.dart';

void main() {
  testWidgets('App compiles without errors', (WidgetTester tester) async {
    // Simple compilation test
    expect(1, 1);
  });

  test('GameState can be created', () {
    final settings = GameSettings(
      raceToScore: 100,
      player1Name: 'Player 1',
      player2Name: 'Player 2',
      threeFoulRuleEnabled: true,
    );
    final gameState = GameState(
      settings: settings,
      achievementManager: AchievementManager(),
    );
    expect(gameState.settings.raceToScore, 100);
    expect(gameState.players.length, 2);
  });
}
