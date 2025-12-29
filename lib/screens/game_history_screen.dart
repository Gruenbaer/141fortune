import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/game_settings.dart';
import '../models/achievement_manager.dart';
import '../models/game_record.dart';
import '../services/game_history_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/steampunk_theme.dart';
import '../widgets/steampunk_widgets.dart';
import 'game_screen.dart';
import 'details_screen.dart';

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  final GameHistoryService _historyService = GameHistoryService();
  List<GameRecord> _games = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'active', 'completed'

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    
    List<GameRecord> games;
    switch (_filter) {
      case 'active':
        games = await _historyService.getActiveGames();
        break;
      case 'completed':
        games = await _historyService.getCompletedGames();
        break;
      default:
        games = await _historyService.getAllGames();
    }
    
    setState(() {
      _games = games;
      _isLoading = false;
    });
  }

  Future<void> _deleteGame(String id) async {
    await _historyService.deleteGame(id);
    _loadGames();
  }

  Future<void> _clearAllHistory() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('deleteAllGames')),
        content: Text(l10n.translate('confirmDeleteAll')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearAllHistory();
      _loadGames();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = SteampunkTheme.themeData;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.translate('gameHistory'), style: theme.textTheme.displayMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: SteampunkTheme.brassPrimary),
        actions: [
          if (_games.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep, color: SteampunkTheme.brassBright),
              onPressed: _clearAllHistory,
              tooltip: l10n.translate('deleteAllGames'),
            ),
        ],
      ),
      body: ThemedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Filter tabs
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: SteampunkTheme.brassDark, width: 2)),
                  color: Colors.black26,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterChip(
                        label: l10n.translate('allGames'),
                        value: 'all',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterChip(
                        label: l10n.translate('inProgress'),
                        value: 'active',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterChip(
                        label: l10n.translate('completed'),
                        value: 'completed',
                      ),
                    ),
                  ],
                ),
              ),
        
              // Game list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: SteampunkTheme.amberGlow))
                    : _games.isEmpty
                        ? _buildEmptyState(l10n)
                        : RefreshIndicator(
                            color: SteampunkTheme.amberGlow,
                            backgroundColor: SteampunkTheme.mahoganyLight,
                            onRefresh: _loadGames,
                            child: ListView.builder(
                              itemCount: _games.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                return _buildGameCard(_games[index], l10n, theme);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required String value}) {
    final isSelected = _filter == value;
    final theme = SteampunkTheme.themeData;
    return GestureDetector(
      onTap: () {
         setState(() => _filter = value);
         _loadGames();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? SteampunkTheme.brassPrimary : Colors.transparent,
          border: Border.all(color: SteampunkTheme.brassPrimary),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 12,
            color: isSelected ? SteampunkTheme.leatherDark : SteampunkTheme.brassPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    final theme = SteampunkTheme.themeData;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu, // Quill/History icon
            size: 64,
            color: SteampunkTheme.brassDark,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.translate('noGamesYet'),
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('playGameToSeeHistory'),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameRecord game, AppLocalizations l10n, ThemeData theme) {
    final stTheme = SteampunkTheme.themeData;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        image: DecorationImage(
           image: AssetImage('assets/images/ui/brass_plate_button.png'), // Reuse plate texture if available, or just colors
           fit: BoxFit.cover,
           colorFilter: ColorFilter.mode(SteampunkTheme.mahoganyLight.withOpacity(0.9), BlendMode.darken),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SteampunkTheme.brassDark),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), offset: Offset(2, 2), blurRadius: 4),
        ],
      ),
      child: Dismissible(
        key: Key(game.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
             color: Color(0xFF8B0000), // Dark Red
             borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.delete, color: SteampunkTheme.brassBright),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.translate('deleteGame')),
              content: Text(l10n.translate('confirmDeleteGame')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) => _deleteGame(game.id),
        child: ListTile(
          onTap: () {
            if (!game.isCompleted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (_) => GameState(
                      settings: GameSettings(
                        raceToScore: game.raceToScore,
                        player1Name: game.player1Name, 
                        player2Name: game.player2Name,
                      ),
                      achievementManager: Provider.of<AchievementManager>(context, listen: false),
                    ),
                    child: GameScreen(
                      settings: Provider.of<GameSettings>(context, listen: false), 
                      onSettingsChanged: (s) {}, 
                      resumeGame: game,
                    ),
                  ),
                ),
              ).then((_) => _loadGames());
            } else {
               // Reconstruct state for verification/details
               final tempState = GameState(
                 settings: GameSettings(
                    raceToScore: game.raceToScore,
                    player1Name: game.player1Name, 
                    player2Name: game.player2Name,
                 ),
                 achievementManager: Provider.of<AchievementManager>(context, listen: false),
               );
               
               if (game.snapshot != null) {
                  tempState.loadFromJson(game.snapshot!);
               } else {
                  // Fallback for old records
                  tempState.players[0].score = game.player1Score;
                  tempState.players[1].score = game.player2Score;
                  tempState.players[0].currentInning = game.player1Innings;
                  tempState.players[1].currentInning = game.player2Innings;
               }

               Navigator.push(
                 context, 
                 MaterialPageRoute(builder: (_) => DetailsScreen(gameState: tempState))
               );
            }
          },
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            '${game.player1Name} vs ${game.player2Name}',
            style: stTheme.textTheme.displaySmall?.copyWith(fontSize: 18),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                '${l10n.translate('score')}: ${game.player1Score} - ${game.player2Score}',
                style: stTheme.textTheme.bodyLarge?.copyWith(color: SteampunkTheme.amberGlow),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDate(game.startTime)} • ${game.getFormattedDuration()}',
                style: stTheme.textTheme.bodySmall,
              ),
              if (game.isCompleted && game.winner != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    border: Border.all(color: SteampunkTheme.verdigris),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${l10n.translate('winner')}: ${game.winner}',
                    style: stTheme.textTheme.labelLarge?.copyWith(color: SteampunkTheme.verdigris, fontSize: 14),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                     border: Border.all(color: SteampunkTheme.amberGlow),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.translate('inProgress'),
                    style: stTheme.textTheme.labelLarge?.copyWith(color: SteampunkTheme.amberGlow, fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
          trailing: game.isCompleted
              ? Icon(Icons.check_circle, color: SteampunkTheme.verdigris)
              : Icon(Icons.timelapse, color: SteampunkTheme.amberGlow),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
