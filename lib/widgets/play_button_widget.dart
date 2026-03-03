import 'package:flutter/material.dart';

class PlayButtonWidget extends StatelessWidget {
  final bool isPlaying;
  final bool isEnabled;
  final VoidCallback onPressed;

  const PlayButtonWidget({
    super.key,
    required this.isPlaying,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
        iconSize: 60,
        color: isEnabled
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.4),
        tooltip: isPlaying ? 'Pause' : 'Play',
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
