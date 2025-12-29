import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_settings.dart';
import '../l10n/app_localizations.dart';
import '../widgets/steampunk_widgets.dart';
import '../widgets/player_name_input_dialog.dart';

class NewGameSettingsScreen extends StatefulWidget {
  final Function(GameSettings) onStartGame;

  const NewGameSettingsScreen({
    super.key,
    required this.onStartGame,
  });

  @override
  State<NewGameSettingsScreen> createState() => _NewGameSettingsScreenState();
}

class _NewGameSettingsScreenState extends State<NewGameSettingsScreen> {
  late GameSettings _settings;
  double _raceSliderValue = 100;

  @override
  void initState() {
    super.initState();
    _settings = GameSettings();
    _raceSliderValue = _settings.raceToScore.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newGameSetup),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Game Type
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.gameType,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(l10n.leagueGame),
                    subtitle: Text(l10n.leagueGameSubtitle),
                    value: _settings.isLeagueGame,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(isLeagueGame: value);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Race to Score
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.raceTo,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Quick buttons
                  Row(
                    children: [
                      _buildRaceButton(25),
                      const SizedBox(width: 8),
                      _buildRaceButton(50),
                      const SizedBox(width: 8),
                      _buildRaceButton(100),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Slider
                  Row(
                    children: [
                      const Text('Custom: '),
                      Expanded(
                        child: Slider(
                          value: _raceSliderValue,
                          min: 25,
                          max: 200,
                          divisions: 35,
                          label: _raceSliderValue.round().toString(),
                          onChanged: (value) {
                            setState(() {
                              _raceSliderValue = value;
                              _settings = _settings.copyWith(raceToScore: value.round());
                            });
                          },
                        ),
                      ),
                      Text(
                        '${_raceSliderValue.round()}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Max Innings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Max Innings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Quick buttons
                  Row(
                    children: [
                      _buildInningsButton(25),
                      const SizedBox(width: 8),
                      _buildInningsButton(50),
                      const SizedBox(width: 8),
                      _buildInningsButton(100),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Slider (always visible)
                  Row(
                    children: [
                      const Text('Custom: '),
                      Expanded(
                        child: Slider(
                          value: _settings.maxInnings.toDouble().clamp(0, 200),
                          min: 0,
                          max: 200,
                          divisions: 40,
                          label: _settings.maxInnings == 0 
                              ? 'Unlimited' 
                              : _settings.maxInnings.toString(),
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings.copyWith(maxInnings: value.round());
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          _settings.maxInnings == 0 ? 'Unlimited' : '${_settings.maxInnings}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Players
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Players',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Player 1
                  ListTile(
                    title: const Text('Player 1'),
                    subtitle: Text(
                      _settings.player1Name.isEmpty ? 'Tap to select' : _settings.player1Name,
                      style: TextStyle(
                        color: _settings.player1Name.isEmpty ? Colors.grey : null,
                      ),
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final name = await PlayerNameInputDialog.show(
                        context,
                        title: 'Player 1',
                        initialName: _settings.player1Name,
                        labelText: 'Player 1',
                        hintText: 'Enter or select player',
                      );
                      if (name != null) {
                        setState(() {
                          _settings = _settings.copyWith(player1Name: name);
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      const Text('Handicap: '),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _settings.player1Handicap > 0
                            ? () => setState(() {
                                  _settings = _settings.copyWith(
                                      player1Handicap: _settings.player1Handicap - 5);
                                })
                            : null,
                      ),
                      Text('+${_settings.player1Handicap}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() {
                          _settings = _settings.copyWith(
                              player1Handicap: _settings.player1Handicap + 5);
                        }),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Player 2
                  ListTile(
                    title: const Text('Player 2'),
                    subtitle: Text(
                      _settings.player2Name.isEmpty ? 'Tap to select' : _settings.player2Name,
                      style: TextStyle(
                        color: _settings.player2Name.isEmpty ? Colors.grey : null,
                      ),
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final name = await PlayerNameInputDialog.show(
                        context,
                        title: 'Player 2',
                        initialName: _settings.player2Name,
                        labelText: 'Player 2',
                        hintText: 'Enter or select player',
                      );
                      if (name != null) {
                        setState(() {
                          _settings = _settings.copyWith(player2Name: name);
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      const Text('Handicap: '),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _settings.player2Handicap > 0
                            ? () => setState(() {
                                  _settings = _settings.copyWith(
                                      player2Handicap: _settings.player2Handicap - 5);
                                })
                            : null,
                      ),
                      Text('+${_settings.player2Handicap}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() {
                          _settings = _settings.copyWith(
                              player2Handicap: _settings.player2Handicap + 5);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Additional Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Additional Rules',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: const Text('3-Foul Rule'),
                    subtitle: const Text('3 consecutive fouls = -15 points'),
                    value: _settings.threeFoulRuleEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(threeFoulRuleEnabled: value);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Start Game Button
          SteampunkButton(
            label: 'START GAME',
            icon: Icons.play_circle_fill,
            onPressed: _startGame,
            backgroundGradientColors: [
              Colors.green.shade900,
              Colors.green.shade700,
            ],
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildRaceButton(int value) {
    final isSelected = _settings.raceToScore == value;
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _raceSliderValue = value.toDouble();
            _settings = _settings.copyWith(raceToScore: value);
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : Colors.green,
          side: BorderSide(color: Colors.green.shade700, width: 2),
        ),
        child: Text(
          value.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInningsButton(int value) {
    final isSelected = _settings.maxInnings == value;
    
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _settings = _settings.copyWith(maxInnings: value);
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : Colors.blue,
          side: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        child: Text(
          value.toString(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _startGame() {
    // Use entered names or defaults if empty
    final player1Name = _settings.player1Name.isEmpty 
        ? 'Player 1' 
        : _settings.player1Name;
    final player2Name = _settings.player2Name.isEmpty 
        ? 'Player 2' 
        : _settings.player2Name;
    
    final finalSettings = _settings.copyWith(
      player1Name: player1Name,
      player2Name: player2Name,
    );
    
    widget.onStartGame(finalSettings);
  }
}
