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

    String statusText() {
      if (!s.isRepeatActive) return 'Off';
      if (s.isSettingRepeatStart) return 'Set Point A';
      if (s.repeatStart != null && s.repeatEnd == null) return 'Set Point B';
      return 'Active';
    }

    String buttonLabel() {
      if (s.isSettingRepeatStart && s.isRepeatActive) return 'Set Start';
      if (s.isRepeatActive && !s.isSettingRepeatStart) return 'Set End';
      return 'A-B Repeat';
    }

    IconData buttonIcon() {
      return s.isSettingRepeatStart && s.isRepeatActive
          ? Icons.flag_rounded
          : Icons.repeat_rounded;
    }

    String fmt(Duration d) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      final ds = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
      return '$m:$s.$ds';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: s.isRepeatActive
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.repeat_rounded,
                      size: 16,
                      color: s.isRepeatActive
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: s.isRepeatActive
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Action button
              ElevatedButton.icon(
                onPressed: isEnabled ? notifier.toggleRepeatMode : null,
                icon: Icon(buttonIcon(), size: 16),
                label: Text(
                  buttonLabel(),
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: s.isRepeatActive
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  foregroundColor: s.isRepeatActive
                      ? Theme.of(context).colorScheme.onPrimary
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),

              // Clear button (only when repeat is active)
              if (s.isRepeatActive)
                IconButton(
                  onPressed: notifier.clearRepeat,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Clear Repeat',
                  color: Theme.of(context).colorScheme.error,
                  iconSize: 20,
                )
              else
                const SizedBox(width: 40),
            ],
          ),

          // A-B repeat markers
          if (s.isRepeatActive && s.repeatStart != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RepeatMarker(
                    label: 'A',
                    time: s.repeatStart!,
                    isActive: s.isSettingRepeatStart,
                    formatFn: fmt,
                  ),
                  if (s.repeatEnd != null) ...[
                    const SizedBox(width: 16),
                    _RepeatMarker(
                      label: 'B',
                      time: s.repeatEnd!,
                      isActive: false,
                      formatFn: fmt,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RepeatMarker extends StatelessWidget {
  final String label;
  final Duration time;
  final bool isActive;
  final String Function(Duration) formatFn;

  const _RepeatMarker({
    required this.label,
    required this.time,
    required this.isActive,
    required this.formatFn,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? Theme.of(context).colorScheme.tertiaryContainer
        : Theme.of(context).colorScheme.primaryContainer;
    final fg = isActive
        ? Theme.of(context).colorScheme.onTertiaryContainer
        : Theme.of(context).colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: isActive
            ? Border.all(
                color: Theme.of(context).colorScheme.tertiary,
                width: 2,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
          const SizedBox(width: 4),
          Text(formatFn(time), style: TextStyle(fontSize: 11, color: fg)),
        ],
      ),
    );
  }
}
