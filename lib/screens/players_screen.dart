import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/player_service.dart';
import 'player_profile_screen.dart';
import '../l10n/app_localizations.dart';
import '../widgets/player_name_input_dialog.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final PlayerService _playerService = PlayerService();
  List<Player> _players = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    final players = await _playerService.getAllPlayers();
    setState(() {
      _players = players..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _isLoading = false;
    });
  }

  Future<void> _createPlayer() async {
    final name = await PlayerNameInputDialog.show(
      context,
      title: AppLocalizations.of(context).createPlayer,
      labelText: AppLocalizations.of(context).playerName,
      hintText: 'Enter name',
    );

    if (name != null) {
      try {
        await _playerService.createPlayer(name);
        await _loadPlayers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Player "$name" created')),
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

  Future<void> _deletePlayer(Player player) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deletePlayer),
        content: Text('${AppLocalizations.of(context).confirmDelete} "${player.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _playerService.deletePlayer(player.id);
      await _loadPlayers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Player "${player.name}" deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: Builder(builder: (context) {
             final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
             return isKeyboardOpen ? const SizedBox.shrink() : const BackButton();
        }),
        title: Text(l10n.players),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _players.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noPlayersYet,
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.tapToCreate,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _players.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        onTap: () async {
                          final deleted = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerProfileScreen(player: player),
                            ),
                          );
                          if (deleted == true) {
                            _loadPlayers(); // Reload if player was deleted
                          }
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[700],
                          child: Text(
                            player.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          player.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${l10n.games}: ${player.gamesPlayed} • ${l10n.gamesWon}: ${player.gamesWon}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlayer,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add),
      ),
    );
  }
}
