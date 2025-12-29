import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/player_service.dart';

/// Reusable player name input dialog with autocomplete, create button, and checkmark
class PlayerNameInputDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final String? labelText;
  final String? hintText;

  const PlayerNameInputDialog({
    super.key,
    required this.title,
    this.initialName = '',
    this.labelText,
    this.hintText,
  });

  /// Show the dialog and return the selected/created player name
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String initialName = '',
    String? labelText,
    String? hintText,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => PlayerNameInputDialog(
        title: title,
        initialName: initialName,
        labelText: labelText,
        hintText: hintText,
      ),
    );
  }

  @override
  State<PlayerNameInputDialog> createState() => _PlayerNameInputDialogState();
}

class _PlayerNameInputDialogState extends State<PlayerNameInputDialog> {
  final PlayerService _playerService = PlayerService();
  final TextEditingController _controller = TextEditingController();
  List<Player> _players = [];
  Player? _selectedPlayer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialName;
    _loadPlayers();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    final players = await _playerService.getAllPlayers();
    if (mounted) {
      setState(() {
        _players = players;
        _isLoading = false;
        _updateSelectedPlayer();
      });
    }
  }

  void _updateSelectedPlayer() {
    _selectedPlayer = _players.cast<Player?>().firstWhere(
      (p) => p?.name.toLowerCase() == _controller.text.trim().toLowerCase(),
      orElse: () => null,
    );
  }

  Future<void> _createPlayer() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    try {
      await _playerService.createPlayer(name);
      await _loadPlayers();

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: _isLoading
          ? const SizedBox(
              width: 200,
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: double.maxFinite,
              child: Autocomplete<String>(
                initialValue: TextEditingValue(text: widget.initialName),
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
                    _controller.text = name;
                    _updateSelectedPlayer();
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                  // Sync with our internal controller for state management
                  if (controller.text != _controller.text) {
                    controller.text = _controller.text;
                  }

                  controller.addListener(() {
                    if (_controller.text != controller.text) {
                      setState(() {
                        _controller.text = controller.text;
                        _updateSelectedPlayer();
                      });
                    }
                  });

                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    maxLength: 30,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    textCapitalization: TextCapitalization.words,
                    contextMenuBuilder: (context, editableTextState) =>
                        const SizedBox.shrink(),
                    decoration: InputDecoration(
                      labelText: widget.labelText ?? 'Player Name',
                      hintText: widget.hintText ?? 'Enter or select player',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      counterText: '',
                      suffixIcon: _selectedPlayer != null
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : (controller.text.trim().isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.add_circle,
                                      color: Colors.blue),
                                  tooltip: 'Create Player',
                                  onPressed: _createPlayer,
                                )
                              : null),
                    ),
                    onSubmitted: (_) {
                      if (_controller.text.trim().isNotEmpty) {
                        Navigator.pop(context, _controller.text.trim());
                      }
                    },
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
