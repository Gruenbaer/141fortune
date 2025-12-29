import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../models/achievement_manager.dart';
import '../models/achievement.dart';
import '../widgets/achievement_badge.dart';
import '../l10n/app_localizations.dart';
import '../services/game_history_service.dart';
import '../models/game_record.dart';
import '../widgets/player_name_input_dialog.dart';

class PlayerProfileScreen extends StatefulWidget {
  final Player player;

  const PlayerProfileScreen({
    super.key,
    required this.player,
  });

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  late Player _player;
  final PlayerService _playerService = PlayerService();
  final GameHistoryService _historyService = GameHistoryService();
  
  // Rivalry Data: Opponent Name -> {games, wins, losses}
  Map<String, Map<String, int>> _rivalryStats = {};
  bool _isLoadingRivalry = true;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _loadRivalryStats();
  }

  Future<void> _loadRivalryStats() async {
    final allGames = await _historyService.getCompletedGames();
    final playerGames = allGames.where((g) => 
      g.player1Name == _player.name || g.player2Name == _player.name
    ).toList();

    final stats = <String, Map<String, int>>{};

    for (var game in playerGames) {
      final isP1 = game.player1Name == _player.name;
      final opponent = isP1 ? game.player2Name : game.player1Name;
      final isWinner = game.winner == _player.name;

      if (!stats.containsKey(opponent)) {
        stats[opponent] = {'games': 0, 'wins': 0};
      }
      
      stats[opponent]!['games'] = (stats[opponent]!['games'] ?? 0) + 1;
      if (isWinner) {
        stats[opponent]!['wins'] = (stats[opponent]!['wins'] ?? 0) + 1;
      }
    }
    
    if (mounted) {
      setState(() {
        _rivalryStats = stats;
        _isLoadingRivalry = false;
      });
    }
  }

  Future<void> _editPlayerName() async {
    final l10n = AppLocalizations.of(context);
    
    final newName = await PlayerNameInputDialog.show(
      context,
      title: l10n.editPlayer,
      initialName: _player.name,
      labelText: l10n.playerName,
    );

    if (newName != null && newName != _player.name) {
      try {
        await _playerService.updatePlayerName(_player.id, newName);
        setState(() {
          _player = Player(
            id: _player.id,
            name: newName,
            gamesPlayed: _player.gamesPlayed,
            gamesWon: _player.gamesWon,
            createdAt: _player.createdAt,
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.playerUpdated)),
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
  }

  Future<void> _deletePlayer() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePlayer),
        content: Text('${l10n.confirmDelete} "${_player.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _playerService.deletePlayer(_player.id);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final achievementManager = Provider.of<AchievementManager>(context);
    final playerAchievements = achievementManager.allAchievements
        .where((a) => a.unlockedBy.contains(_player.name))
        .toList();
    
    final winRate = _player.gamesPlayed > 0
        ? (_player.gamesWon / _player.gamesPlayed * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: Text(_player.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editPlayerName,
            tooltip: l10n.editPlayer,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deletePlayer,
            tooltip: l10n.deletePlayer,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Player Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green[700],
                    child: Text(
                      _player.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _player.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Statistics Section
          Text(
            l10n.statistics,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n.games,
                  _player.gamesPlayed.toString(),
                  Icons.sports,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  l10n.gamesWon,
                  _player.gamesWon.toString(),
                  Icons.emoji_events,
                  Colors.amber,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n.winRate,
                  '$winRate%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  l10n.gamesLost,
                  (_player.gamesPlayed - _player.gamesWon).toString(),
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // NEW STATS: Highest Run & General Average
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n.translate('highestRun') ?? 'Highest Run (HR)',
                  _player.highestRun.toString(),
                  Icons.star,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  l10n.translate('generalAverage') ?? 'Avg Pots (GD)',
                  _player.generalAverage.toStringAsFixed(2),
                  Icons.show_chart,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // RIVALRY SECTION (Head-to-Head)
          if (_rivalryStats.isNotEmpty) ...[
            Text(
              l10n.translate('rivalryHistory') ?? 'Head-to-Head',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rivalryStats.length,
              itemBuilder: (context, index) {
                final opponentName = _rivalryStats.keys.elementAt(index);
                final stats = _rivalryStats[opponentName]!;
                final games = stats['games'] ?? 0;
                final wins = stats['wins'] ?? 0;
                final winRate = games > 0 ? (wins / games * 100).toStringAsFixed(1) : '0.0';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      child: Text(opponentName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text('vs $opponentName'),
                    subtitle: Text('${l10n.games}: $games  •  ${l10n.gamesWon}: $wins'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$winRate%', 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: (double.tryParse(winRate) ?? 0) > 50 ? Colors.green : Colors.red,
                            fontSize: 16
                          ),
                        ),
                        Text(l10n.winRate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],

          // Achievements Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.achievements,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${playerAchievements.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (playerAchievements.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noAchievementsYet,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: playerAchievements.length,
              itemBuilder: (context, index) {
                final achievement = playerAchievements[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      _showAchievementDetail(achievement);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AchievementBadge(
                          id: achievement.id,
                          emoji: achievement.emoji,
                          isUnlocked: true,
                          isEasterEgg: achievement.isEasterEgg,
                          size: 50,
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            achievement.title,
                            style: const TextStyle(fontSize: 11),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetail(Achievement achievement) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AchievementBadge(
              id: achievement.id,
              emoji: achievement.emoji,
              isUnlocked: true,
              isEasterEgg: achievement.isEasterEgg,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}
