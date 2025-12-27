import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../models/achievement_manager.dart';
import '../models/game_record.dart';
import '../l10n/app_localizations.dart';
import '../screens/game_screen.dart';
import '../screens/new_game_settings_screen.dart';
import '../screens/players_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/achievements_gallery_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/game_history_screen.dart';
import '../widgets/steampunk_widgets.dart';
import '../theme/steampunk_theme.dart';
import '../services/game_history_service.dart';
import '../widgets/video_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameRecord? _activeGame;

  @override
  void initState() {
    super.initState();
    _checkActiveGame();
  }

  Future<void> _checkActiveGame() async {
     final games = await GameHistoryService().getActiveGames();
     if (mounted) {
       setState(() {
         _activeGame = games.isNotEmpty ? games.first : null;
       });
     }
  }

  void _resumeGame(GameRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => GameState(
            settings: GameSettings(
               raceToScore: record.raceToScore,
               player1Name: record.player1Name,
               player2Name: record.player2Name,
               // Reconstruct other settings from record or defaults if missing in record
               // Assuming GameRecord stores standard settings:
               // threeFoulRuleEnabled, etc. might need to be added to GameRecord or defaulted.
               // For now, assuming defaults or minimal reconstruction.
            ),
            achievementManager: Provider.of<AchievementManager>(context, listen: false),
          ),
          child: GameScreen(
            settings: Provider.of<GameSettings>(context, listen: false), 
            onSettingsChanged: (s) {}, 
            resumeGame: record,
          ),
        ),
      ),
    ).then((_) => _checkActiveGame());
  }

  void showNewGameSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NewGameSettingsScreen(
        onStartGame: (settings) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => GameState(
                  settings: settings,
                  achievementManager: Provider.of<AchievementManager>(context, listen: false),
                ),
                child: GameScreen(
                  settings: settings,
                  onSettingsChanged: (newSettings) {
                      Provider.of<Function(GameSettings)>(context, listen: false)(newSettings);
                  },
                ),
              ),
            ),
          ).then((_) => _checkActiveGame());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      // Background handled by specialized widget
      body:Stack(
        children: [
          // Main content
          SteampunkBackground(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    
                    // LOGO SECTION
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: const VideoLogo(),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // MENU BUTTONS (Constrained width)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_activeGame != null) ...[
                            SteampunkButton(
                              label: '${l10n.resume}: ${_activeGame!.player1Name} vs ${_activeGame!.player2Name}',
                              icon: Icons.play_circle_fill,
                              onPressed: () => _resumeGame(_activeGame!),
                            ),
                            const SizedBox(height: 16),
                          ],

                          SteampunkButton(
                            label: l10n.new141Game,
                            icon: Icons.play_arrow,
                            onPressed: () => showNewGameSettings(context),
                          ),
                          
                          SteampunkButton(
                            label: l10n.translate('gameHistory'),
                            icon: Icons.history,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const GameHistoryScreen()),
                              );
                            },
                          ),
                          
                          SteampunkButton(
                            label: l10n.players,
                            icon: Icons.people_outline,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PlayersScreen()),
                              );
                            },
                          ),
                          
                          SteampunkButton(
                            label: l10n.statistics,
                            icon: Icons.bar_chart,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                              );
                            },
                          ),
                          
                          // ACHIEVEMENTS BUTTON
                          SteampunkButton(
                            label: l10n.translate('achievements'),
                            icon: Icons.emoji_events,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AchievementsGalleryScreen()),
                              );
                            },
                          ),
                          
                          SteampunkButton(
                            label: l10n.settings,
                            icon: Icons.settings_suggest, 
                            onPressed: () async {
                              final currentSettings = Provider.of<GameSettings>(context, listen: false);
                              final updateSettings = Provider.of<Function(GameSettings)>(context, listen: false);
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 80), // Space for cogs
                    
                    // Version
                    Text(
                      'v3.3.0 - Steampunk Core',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: SteampunkTheme.steamWhite.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          

        ],
      ),
    );
  }
}
