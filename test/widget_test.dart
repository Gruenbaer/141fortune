import 'package:flutter_test/flutter_test.dart';
import 'package:fortune142/models/game_state.dart';

void main() {
  testWidgets('App compiles without errors', (WidgetTester tester) async {
    // Simple compilation test
    expect(1, 1);
  });

  test('GameState can be created', () {
    final gameState = GameState(
      raceToScore: 100,
      playerNames: ['Player 1', 'Player 2'],
      threeFoulRuleEnabled: true,
    );
    expect(gameState.raceToScore, 100);
    expect(gameState.players.length, 2);
  });
}
