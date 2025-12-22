import 'package:flutter/material.dart';
import '../models/game_state.dart';

class FoulToggleButton extends StatelessWidget {
  final FoulMode currentMode;
  final VoidCallback onPressed;

  const FoulToggleButton({
    super.key,
    required this.currentMode,
    required this.onPressed,
  });

  Color _getButtonColor() {
    switch (currentMode) {
      case FoulMode.none:
        return Colors.grey[300]!;
      case FoulMode.normal:
        return Colors.orange;
      case FoulMode.severe:
        return Colors.red;
    }
  }

  String _getButtonText() {
    switch (currentMode) {
      case FoulMode.none:
        return 'No Foul';
      case FoulMode.normal:
        return 'Foul -1';
      case FoulMode.severe:
        return 'Break Foul -2';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56, // Fixed height for consistency
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getButtonColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          _getButtonText(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: currentMode == FoulMode.none ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }
}
