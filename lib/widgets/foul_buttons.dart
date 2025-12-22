import 'package:flutter/material.dart';

class FoulButtons extends StatelessWidget {
  final VoidCallback onNormalFoul;
  final VoidCallback onSevereFoul;

  const FoulButtons({
    super.key,
    required this.onNormalFoul,
    required this.onSevereFoul,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: onNormalFoul,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            'Normal Foul\n-1',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
        ElevatedButton(
          onPressed: onSevereFoul,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            'Severe Foul\n-2',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
