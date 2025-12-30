import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/player_service.dart';
import '../l10n/app_localizations.dart';

/// A simple player name input field with autocomplete dropdown
/// This replaces the problematic Flutter Autocomplete widget
class PlayerNameField extends StatefulWidget {
  final String label;
  final String initialValue;
  final List<Player> players;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCreatePlayer;

  const PlayerNameField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.players,
    required this.onChanged,
    this.onCreatePlayer,
  });

  @override
  State<PlayerNameField> createState() => _PlayerNameFieldState();
}

class _PlayerNameFieldState extends State<PlayerNameField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    widget.onChanged(text);

    setState(() {
      if (text.isEmpty) {
        _suggestions = [];
        _showSuggestions = false;
      } else {
        _suggestions = widget.players
            .map((p) => p.name)
            .where((name) => name.toLowerCase().contains(text.toLowerCase()))
            .toList();
        _showSuggestions = _suggestions.isNotEmpty && _focusNode.hasFocus;
      }
    });
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _showSuggestions = false;
      });
    } else if (_suggestions.isNotEmpty) {
      setState(() {
        _showSuggestions = true;
      });
    }
  }

  void _selectSuggestion(String name) {
    _controller.text = name;
    widget.onChanged(name);
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }

  bool get _isExistingPlayer {
    final text = _controller.text.trim();
    return widget.players.any((p) => p.name.toLowerCase() == text.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLength: 30,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: l10n.enterOrSelectPlayer,
            counterText: '',
            suffixIcon: _isExistingPlayer
                ? const Icon(Icons.check_circle, color: Colors.green)
                : (_controller.text.trim().isNotEmpty && widget.onCreatePlayer != null
                    ? IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        tooltip: l10n.createPlayer,
                        onPressed: widget.onCreatePlayer,
                      )
                    : null),
          ),
        ),
        if (_showSuggestions) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(context).cardColor,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(suggestion),
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
