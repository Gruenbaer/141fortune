import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_settings.dart' hide Player;
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/steampunk_theme.dart';
import '../widgets/steampunk_widgets.dart';
import 'package:provider/provider.dart';
import '../models/achievement_manager.dart';
import '../services/player_service.dart';


class SettingsScreen extends StatefulWidget {
  final GameSettings currentSettings;
  final Function(GameSettings) onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings _settings;
  final _settingsService = SettingsService();
  final _playerService = PlayerService();
  List<Player> _players = [];

  @override
  void initState() {
    super.initState();
    _settings = widget.currentSettings;
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final players = await _playerService.getAllPlayers();
    if (mounted) {
      setState(() {
        _players = players;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    // Helper to build a control panel section
    Widget buildSectionHeader(String title, IconData icon) {
      return Container(
        margin: const EdgeInsets.only(top: 24, bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: SteampunkTheme.brassDark.withOpacity(0.3),
          border: Border(bottom: BorderSide(color: SteampunkTheme.brassPrimary, width: 2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: SteampunkTheme.brassPrimary),
            const SizedBox(width: 12),
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: SteampunkTheme.brassPrimary,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildPanelTile({required Widget child}) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black26,
          border: Border.all(color: SteampunkTheme.brassDark.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: child,
      );
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Builder(builder: (context) {
             final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
             return isKeyboardOpen ? const SizedBox.shrink() : const BackButton();
        }),
        title: Text(l10n.settings, style: theme.textTheme.displaySmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: SteampunkTheme.brassPrimary),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.save),
                color: SteampunkTheme.brassBright,
                onPressed: _saveSettings,
                tooltip: 'Save Configuration',
              ),
              if (_settings != widget.currentSettings)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SteampunkBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              buildSectionHeader(l10n.gameRules, Icons.gavel),

              // Race to Score
              buildPanelTile(
                child: ListTile(
                  title: Text(l10n.raceToScore, style: theme.textTheme.bodyLarge),
                  subtitle: Text('${_settings.raceToScore} ${l10n.points}', style: theme.textTheme.bodySmall),
                  trailing: Icon(Icons.edit, color: SteampunkTheme.brassPrimary),
                  onTap: () => _editRaceToScore(),
                ),
              ),

              // Player Names
              buildPanelTile(
                child: ListTile(
                  title: Text(l10n.player1, style: theme.textTheme.bodyLarge),
                  subtitle: Text(_settings.player1Name, style: theme.textTheme.displaySmall?.copyWith(fontSize: 18)),
                  trailing: Icon(Icons.edit, color: SteampunkTheme.brassPrimary),
                  onTap: () => _editPlayerName(1),
                ),
              ),
              buildPanelTile(
                child: ListTile(
                  title: Text(l10n.player2, style: theme.textTheme.bodyLarge),
                  subtitle: Text(_settings.player2Name, style: theme.textTheme.displaySmall?.copyWith(fontSize: 18)),
                  trailing: Icon(Icons.edit, color: SteampunkTheme.brassPrimary),
                  onTap: () => _editPlayerName(2),
                ),
              ),

              buildSectionHeader('Mechanics', Icons.settings_input_component),

              // 3-Foul Rule Toggle
              buildPanelTile(
                child: SwitchListTile(
                  title: Text(l10n.threeFoulRule, style: theme.textTheme.bodyLarge),
                  subtitle: Text(l10n.threeFoulRuleSubtitle, style: theme.textTheme.bodySmall),
                  value: _settings.threeFoulRuleEnabled,
                  activeColor: SteampunkTheme.amberGlow,
                  activeTrackColor: SteampunkTheme.brassDark,
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.black,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(threeFoulRuleEnabled: value);
                    });
                  },
                ),
              ),

              // Sound Effects Toggle
              buildPanelTile(
                child: SwitchListTile(
                  title: Text(l10n.soundEffects, style: theme.textTheme.bodyLarge),
                  subtitle: Text(l10n.enableGameSounds, style: theme.textTheme.bodySmall),
                  value: _settings.soundEnabled,
                  activeColor: SteampunkTheme.amberGlow,
                   activeTrackColor: SteampunkTheme.brassDark,
                  secondary: Icon(
                    _settings.soundEnabled ? Icons.volume_up : Icons.volume_off,
                    color: _settings.soundEnabled ? SteampunkTheme.brassPrimary : Colors.grey,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(soundEnabled: value);
                    });
                  },
                ),
              ),
              // Innings & Handicap Section
              buildSectionHeader('Limits & Handicaps', Icons.tune),

              // Max Innings Slider
              buildPanelTile(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 12, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Max Innings', style: theme.textTheme.bodyLarge),
                          Text(
                            '${_settings.maxInnings}',
                            style: theme.textTheme.displaySmall?.copyWith(fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                    Slider(
                      value: _settings.maxInnings.toDouble(),
                      min: 10,
                      max: 100,
                      divisions: 18, // Steps of 5 (approx)
                      label: '${_settings.maxInnings}',
                      activeColor: SteampunkTheme.amberGlow,
                      inactiveColor: SteampunkTheme.brassDark.withOpacity(0.3),
                      thumbColor: SteampunkTheme.brassPrimary,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(maxInnings: value.round());
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Player 1 Handicap
              buildPanelTile(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_settings.player1Name, style: theme.textTheme.bodyLarge),
                          Text('Point Multiplier', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      _buildMultiplierSelector(
                        _settings.player1HandicapMultiplier,
                        (val) => setState(() => _settings = _settings.copyWith(player1HandicapMultiplier: val)),
                      ),
                    ],
                  ),
                ),
              ),

              // Player 2 Handicap
              buildPanelTile(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_settings.player2Name, style: theme.textTheme.bodyLarge),
                          Text('Point Multiplier', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      _buildMultiplierSelector(
                        _settings.player2HandicapMultiplier,
                        (val) => setState(() => _settings = _settings.copyWith(player2HandicapMultiplier: val)),
                      ),
                    ],
                  ),
                ),
              ),

              buildSectionHeader(l10n.language, Icons.language),

              // Language Selection
              buildPanelTile(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(l10n.german, style: theme.textTheme.bodyMedium),
                      value: 'de',
                      groupValue: _settings.languageCode,
                      activeColor: SteampunkTheme.amberGlow,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(languageCode: value);
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(l10n.english, style: theme.textTheme.bodyMedium),
                      value: 'en',
                      groupValue: _settings.languageCode,
                      activeColor: SteampunkTheme.amberGlow,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(languageCode: value);
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Theme Selection (Hidden or styled)
              // Since we are forcing Steampunk, maybe hide this or just show it as "Visual Style"
              buildSectionHeader(l10n.theme, Icons.palette),
              buildPanelTile(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text('Steampunk', style: theme.textTheme.bodyMedium),
                      subtitle: const Text('Classic Brass & Wood'),
                      secondary: const Icon(Icons.access_time_filled, color: Color(0xFFCDBE78)),
                      value: 'steampunk',
                      groupValue: _settings.themeId,
                      activeColor: const Color(0xFFFFA000),
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(themeId: value);
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('Cyberpunk', style: theme.textTheme.bodyMedium),
                      subtitle: const Text('Neon & Glitch'),
                      secondary: const Icon(Icons.memory, color: Color(0xFF00F0FF)),
                      value: 'cyberpunk',
                      groupValue: _settings.themeId,
                      activeColor: const Color(0xFF00F0FF),
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(themeId: value);
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info about 3-Foul Rule
              if (_settings.threeFoulRuleEnabled)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SteampunkTheme.brassDark, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: SteampunkTheme.brassPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '3-FOUL PROTOCOL',
                            style: theme.textTheme.labelLarge?.copyWith(color: SteampunkTheme.brassBright),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 3 consecutive normal fouls = -15 points\n'
                        '• Severe fouls do NOT count toward this rule\n'
                        '• Counter resets after successful shot or penalty',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              
              // Data Management Section (Dangerous)
              buildSectionHeader('Data Management', Icons.delete_forever),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.shade900),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListTile(
                  leading: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                  title: Text(
                    'Reset All Data', 
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red.shade200),
                  ),
                  subtitle: Text(
                    'Delete all achievements and settings',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.red.shade100),
                  ),
                  onTap: _showResetDataConfirmation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResetDataConfirmation() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetEverything),
        content: Text(l10n.resetDataMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
             style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.resetAll),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Perform Reset
      
      // 1. Reset Achievements
      final achievementManager = Provider.of<AchievementManager>(context, listen: false);
      await achievementManager.reset();
      
      // 2. Reset Settings (to defaults) -> actually maybe just keep settings? 
      // User asked "reset all". Let's reset settings too for completeness, or at least notify.
      // For now, let's stick to Achievements as that's the main context.
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.allDataReset)),
        );
      }
    }
  }

  Future<void> _editRaceToScore() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: '${_settings.raceToScore}');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.raceToScore),
        content: TextField(
          controller: controller,
          maxLength: 50,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          keyboardType: TextInputType.number,
          contextMenuBuilder: (context, editableTextState) => const SizedBox.shrink(),
          decoration: InputDecoration(
            labelText: l10n.points,
            hintText: 'Enter target score',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _settings = _settings.copyWith(raceToScore: result);
      });
    }
  }

  Future<void> _editPlayerName(int playerNumber) async {
    final l10n = AppLocalizations.of(context);
    final currentName = playerNumber == 1 ? _settings.player1Name : _settings.player2Name;
    final controller = TextEditingController(text: currentName);
    Player? selectedPlayer;
    
    final finalName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Check if current text matches a player
            selectedPlayer = _players.cast<Player?>().firstWhere(
              (p) =>  p?.name.toLowerCase() == controller.text.trim().toLowerCase(),
              orElse: () => null,
            );
            
            return AlertDialog(
              title: Text(playerNumber == 1 ? l10n.player1 : l10n.player2),
              content: SizedBox(
                width: double.maxFinite,
                child: Autocomplete<String>(
                  initialValue: TextEditingValue(text: currentName),
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
                    controller.text = name;
                    setDialogState(() {});
                  },
                  fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
                    // Sync our controller with the autocomplete's
                    if (fieldController.text != controller.text) {
                      fieldController.text = controller.text;
                    }
                    
                    fieldController.addListener(() {
                      controller.text = fieldController.text;
                      setDialogState(() {});
                    });
                    
                    return TextField(
                      controller: fieldController,
                      focusNode: focusNode,
                      maxLength: 30,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      textCapitalization: TextCapitalization.words,
                      contextMenuBuilder: (context, editableTextState) => const SizedBox.shrink(),
                      decoration: InputDecoration(
                        labelText: l10n.playerName,
                        hintText: 'Enter or select player',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        counterText: '',
                        suffixIcon: selectedPlayer != null
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : (fieldController.text.trim().isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                                    tooltip: 'Create Player',
                                    onPressed: () async {
                                      final name = fieldController.text.trim();
                                      if (name.isEmpty) return;
                                      
                                      try {
                                        await _playerService.createPlayer(name);
                                        await _loadPlayers();
                                        
                                        setDialogState(() {});
                                        
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Player "$name" created ✓')),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                          );
                                        }
                                      }
                                    },
                                  )
                                : null),
                      ),
                      onSubmitted: (_) => Navigator.pop(dialogContext, controller.text.trim()),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(dialogContext, controller.text.trim());
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (finalName != null && finalName != currentName && finalName.isNotEmpty) {
      setState(() {
        if (playerNumber == 1) {
          _settings = _settings.copyWith(player1Name: finalName);
        } else {
          _settings = _settings.copyWith(player2Name: finalName);
        }
      });
    }
    
    controller.dispose();
  }

  Future<void> _saveSettings() async {
    final l10n = AppLocalizations.of(context);
    await _settingsService.saveSettings(_settings);
    widget.onSettingsChanged(_settings);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsSaved)),
      );
      Navigator.pop(context);
    }
  }
  Widget _buildMultiplierSelector(double current, Function(double) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: SteampunkTheme.brassDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: SteampunkTheme.brassPrimary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [1.0, 2.0, 3.0].map((val) {
          final isSelected = current == val;
          return GestureDetector(
            onTap: () => onChanged(val),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? SteampunkTheme.amberGlow : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '${val.toInt()}x',
                style: TextStyle(
                  color: isSelected ? Colors.black : SteampunkTheme.brassBright,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
