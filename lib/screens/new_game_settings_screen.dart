import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/player_service.dart';
import '../models/game_settings.dart';
import '../l10n/app_localizations.dart';

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
  final _player1Controller = TextEditingController();
  final _player2Controller = TextEditingController();
  final PlayerService _playerService = PlayerService();
  List<Player> _players = [];
  double _raceSliderValue = 100;
  Player? _player1;
  Player? _player2;

  @override
  void initState() {
    super.initState();
    _settings = GameSettings();
    // Start with empty fields - "Player 1" and "Player 2" are just defaults for settings
    _player1Controller.text = '';
    _player2Controller.text = '';
    _raceSliderValue = _settings.raceToScore.toDouble();
    _loadPlayers();
    
    _player1Controller.addListener(_onPlayer1Changed);
    _player2Controller.addListener(_onPlayer2Changed);
  }

  Future<void> _loadPlayers() async {
    final players = await _playerService.getAllPlayers();
    setState(() {
      _players = players;
    });
  }

  void _onPlayer1Changed() {
    setState(() {
      _player1 = _players.cast<Player?>().firstWhere(
        (p) => p?.name.toLowerCase() == _player1Controller.text.trim().toLowerCase(),
        orElse: () => null,
      );
      _settings = _settings.copyWith(player1Name: _player1Controller.text);
    });
  }

  void _onPlayer2Changed() {
    setState(() {
      _player2 = _players.cast<Player?>().firstWhere(
        (p) => p?.name.toLowerCase() == _player2Controller.text.trim().toLowerCase(),
        orElse: () => null,
      );
      _settings = _settings.copyWith(player2Name: _player2Controller.text);
    });
  }

  Future<void> _createPlayer1() async {
    final name = _player1Controller.text.trim();
    if (name.isEmpty) return;
    
    try {
      await _playerService.createPlayer(name);
      await _loadPlayers();
      
      // Trigger state update to show checkmark
      setState(() {
        _player1 = _players.cast<Player?>().firstWhere(
          (p) => p?.name.toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Player "$name" created ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _createPlayer2() async {
    final name = _player2Controller.text.trim();
    if (name.isEmpty) return;
    
    try {
      await _playerService.createPlayer(name);
      await _loadPlayers();
      
      // Trigger state update to show checkmark
      setState(() {
        _player2 = _players.cast<Player?>().firstWhere(
          (p) => p?.name.toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).playerCreated}: "$name"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  void dispose() {
    _player1Controller.removeListener(_onPlayer1Changed);
    _player2Controller.removeListener(_onPlayer2Changed);
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  Autocomplete<String>(
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _players
                          .map((p) => p.name)
                          .where((name) => name.toLowerCase().contains(
                              textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (name) {
                      setState(() {
                        _player1Controller.text = name;
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      // Sync logic removed to prevent cursor jumping bug

                      
                      return TextField(
                        controller: controller,
                        maxLength: 30,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        focusNode: focusNode,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Player 1',
                          hintText: 'Enter or select player',
                          border: const OutlineInputBorder(),
                          counterText: '',  // Hide character counter
                          suffixIcon: _player1 != null
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : (controller.text.trim().isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                                      tooltip: 'Create Player',
                                      onPressed: _createPlayer1,
                                    )
                                  : null),
                        ),
                        onChanged: (value) {
                          _player1Controller.text = value;
                        },
                        onSubmitted: (_) => onSubmitted(),
                      );
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
                  Autocomplete<String>(
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _players
                          .map((p) => p.name)
                          .where((name) => name.toLowerCase().contains(
                              textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (name) {
                      setState(() {
                        _player2Controller.text = name;
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      // Sync logic removed to prevent cursor jumping bug

                      
                      return TextField(
                        controller: controller,
                        maxLength: 30,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        focusNode: focusNode,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Player 2',
                          hintText: 'Enter or select player',
                          border: const OutlineInputBorder(),
                          counterText: '',  // Hide character counter
                          suffixIcon: _player2 != null
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : (controller.text.trim().isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                                      tooltip: 'Create Player',
                                      onPressed: _createPlayer2,
                                    )
                                  : null),
                        ),
                        onChanged: (value) {
                          _player2Controller.text = value;
                        },
                        onSubmitted: (_) => onSubmitted(),
                      );
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
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              child: const Text(
                'Start Game',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
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

  Widget _buildInningsButton(int value, {String? label}) {
    final isSelected = _settings.maxInnings == value;
    final displayText = label ?? value.toString();
    
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
          displayText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _editMaxInnings() async {
    final controller = TextEditingController(
      text: _settings.maxInnings == 0 ? '' : '${_settings.maxInnings}',
    );
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Max Innings'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Innings (0 = unlimited)',
            hintText: '0',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _settings = _settings.copyWith(maxInnings: result);
      });
    }
  }

  void _startGame() {
    // Use entered names or defaults if empty
    final player1Name = _player1Controller.text.trim().isEmpty 
        ? 'Player 1' 
        : _player1Controller.text.trim();
    final player2Name = _player2Controller.text.trim().isEmpty 
        ? 'Player 2' 
        : _player2Controller.text.trim();
    
    final finalSettings = _settings.copyWith(
      player1Name: player1Name,
      player2Name: player2Name,
    );
    
    widget.onStartGame(finalSettings);
  }
}
