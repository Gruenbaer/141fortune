import 'package:flutter/material.dart';
import '../services/player_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/steampunk_theme.dart';
import '../widgets/steampunk_widgets.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final PlayerService _playerService = PlayerService();
  List<Player> _players = [];
  bool _isLoading = true;
  String _sortBy = 'gamesPlayed'; // Default sort

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    final players = await _playerService.getAllPlayers();
    setState(() {
      _players = players;
      _sortPlayers();
      _isLoading = false;
    });
  }

  void _sortPlayers() {
    switch (_sortBy) {
      case 'gamesPlayed':
        _players.sort((a, b) => b.gamesPlayed.compareTo(a.gamesPlayed));
        break;
      case 'winRate':
        _players.sort((a, b) => b.winRate.compareTo(a.winRate));
        break;
      case 'avgPoints':
        _players.sort((a, b) => b.averagePointsPerGame.compareTo(a.averagePointsPerGame));
        break;
      case 'highestRun':
        _players.sort((a, b) => b.highestRun.compareTo(a.highestRun));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = SteampunkTheme.themeData;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.statistics, style: theme.textTheme.displayMedium),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: SteampunkTheme.brassPrimary),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: SteampunkTheme.brassPrimary),
            color: SteampunkTheme.mahoganyLight,
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortPlayers();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'gamesPlayed', child: Text(l10n.gamesPlayed, style: theme.textTheme.bodyMedium)),
              PopupMenuItem(value: 'winRate', child: Text(l10n.winRate, style: theme.textTheme.bodyMedium)),
              PopupMenuItem(value: 'avgPoints', child: Text(l10n.avgPoints, style: theme.textTheme.bodyMedium)),
              PopupMenuItem(value: 'highestRun', child: Text(l10n.highestRun, style: theme.textTheme.bodyMedium)),
            ],
          ),
        ],
      ),
      body: ThemedBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: SteampunkTheme.amberGlow))
              : _players.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart, size: 64, color: SteampunkTheme.brassDark),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noStatistics,
                            style: theme.textTheme.displaySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.playGamesToSee,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: SteampunkTheme.amberGlow,
                      backgroundColor: SteampunkTheme.mahoganyLight,
                      onRefresh: _loadPlayers,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Overall Stats Card
                          _buildOverallStatsCard(l10n),
                          
                          const SizedBox(height: 24),
                          
                          // Player Rankings Header
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: SteampunkTheme.brassPrimary, width: 2)),
                              gradient: LinearGradient(
                                colors: [SteampunkTheme.brassDark.withOpacity(0.5), Colors.transparent],
                              ),
                            ),
                            child: Text(
                              l10n.playerRankings.toUpperCase(),
                              style: theme.textTheme.labelLarge?.copyWith(
                                letterSpacing: 1.5,
                                color: SteampunkTheme.brassBright,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          ..._players.asMap().entries.map((entry) {
                            final index = entry.key;
                            final player = entry.value;
                            return _buildPlayerCard(player, index + 1);
                          }).toList(),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildOverallStatsCard(AppLocalizations l10n) {
    final totalGames = _players.fold<int>(0, (sum, p) => sum + p.gamesPlayed);
    final totalPoints = _players.fold<int>(0, (sum, p) => sum + p.totalPoints);
    final totalFouls = _players.fold<int>(0, (sum, p) => sum + p.totalFouls);
    final highestRun = _players.fold<int>(0, (max, p) => p.highestRun > max ? p.highestRun : max);

    return Container(
      decoration: BoxDecoration(
        color: SteampunkTheme.mahoganyLight,
        border: Border.all(color: SteampunkTheme.brassDark, width: 2),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(2, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: SteampunkTheme.brassPrimary),
              const SizedBox(width: 8),
              Text(
                l10n.overallStatistics,
                style: SteampunkTheme.themeData.textTheme.displaySmall?.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(l10n.games, totalGames.toString(), Icons.sports_esports),
              _buildStatColumn(l10n.points, totalPoints.toString(), Icons.stars),
              _buildStatColumn(l10n.fouls, totalFouls.toString(), Icons.warning),
              _buildStatColumn(l10n.bestRun, highestRun.toString(), Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    final theme = SteampunkTheme.themeData;
    return Column(
      children: [
        Icon(icon, color: SteampunkTheme.brassBright, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: SteampunkTheme.amberGlow),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPlayerCard(Player player, int rank) {
    final theme = SteampunkTheme.themeData;
    return Container( // Replaced Card with Container for custom border
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        border: Border.all(color: SteampunkTheme.brassDark, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ExpansionTile(
        iconColor: SteampunkTheme.amberGlow,
        leading: CircleAvatar(
          backgroundColor: rank <= 3 ? SteampunkTheme.amberGlow : SteampunkTheme.brassDark,
          foregroundColor: Colors.black,
          child: Text(
            '#$rank',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(player.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${player.gamesPlayed} games | ${player.winRate.toStringAsFixed(1)}% Win',
          style: theme.textTheme.bodySmall,
        ),

        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatRow('Games Played', player.gamesPlayed.toString()),
                _buildStatRow('Games Won', '${player.gamesWon} (${player.winRate.toStringAsFixed(1)}%)'),
                const Divider(),
                _buildStatRow('Total Points', player.totalPoints.toString()),
                _buildStatRow('Avg Points/Game', player.averagePointsPerGame.toStringAsFixed(1)),
                _buildStatRow('Highest Run', player.highestRun.toString()),
                const Divider(),
                _buildStatRow('Total Innings', player.totalInnings.toString()),
                _buildStatRow('Avg Innings/Game', player.averageInningsPerGame.toStringAsFixed(1)),
                const Divider(),
                _buildStatRow('Total Fouls', player.totalFouls.toString()),
                _buildStatRow('Avg Fouls/Game', player.averageFoulsPerGame.toStringAsFixed(1)),
                _buildStatRow('Total Saves', player.totalSaves.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
