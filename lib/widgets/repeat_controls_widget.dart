import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../state.dart';

class RepeatControlsWidget extends HookConsumerWidget {
  const RepeatControlsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final isEnabled = s.filePath != null;

    String fmt(Duration d) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      final ds = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
      return '$m:$sec.$ds';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Set Point A button (shown when repeat is inactive)
          if (!s.isRepeatActive)
            ElevatedButton.icon(
              onPressed: isEnabled ? notifier.toggleRepeatMode : null,
              icon: const Icon(Icons.flag_rounded, size: 16),
              label: const Text('Set Point A', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),

          // Point A display (shown when A is set)
          if (s.isRepeatActive && s.repeatStart != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'A',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    fmt(s.repeatStart!),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(width: 8),

          // Set Point B button (shown when A is set but B is not)
          if (s.isRepeatActive && s.repeatStart != null && s.repeatEnd == null)
            ElevatedButton.icon(
              onPressed: isEnabled ? notifier.toggleRepeatMode : null,
              icon: const Icon(Icons.flag_rounded, size: 16),
              label: const Text('Set Point B', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),

          // Point B display with clear B button (shown when both A and B are set)
          if (s.isRepeatActive && s.repeatStart != null && s.repeatEnd != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'B',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    fmt(s.repeatEnd!),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: notifier.clearPointB,
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    iconSize: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    tooltip: 'Clear Point B',
                  ),
                ],
              ),
            ),

          // Clear all button (shown when either A or B is set)
          if (s.isRepeatActive &&
              (s.repeatStart != null || s.repeatEnd != null))
            IconButton(
              onPressed: notifier.clearRepeat,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Clear All',
              color: Theme.of(context).colorScheme.error,
              iconSize: 20,
            ),
        ],
      ),
    );
  }
}
