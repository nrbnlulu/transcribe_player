import 'package:flutter/material.dart';

enum SeekDirection { back, forward }

class SeekButtonWidget extends StatelessWidget {
  final SeekDirection direction;

  /// Level 1 = inner (closer to play button), Level 2 = outer
  final int level;
  final Duration skipDuration;
  final bool isEnabled;
  final VoidCallback onPressed;

  const SeekButtonWidget({
    super.key,
    required this.direction,
    required this.level,
    required this.skipDuration,
    required this.isEnabled,
    required this.onPressed,
  });

  IconData get _icon {
    if (direction == SeekDirection.back) {
      return level == 1
          ? Icons.keyboard_arrow_left_rounded
          : Icons.keyboard_double_arrow_left_rounded;
    } else {
      return level == 1
          ? Icons.keyboard_arrow_right_rounded
          : Icons.keyboard_double_arrow_right_rounded;
    }
  }

  String get _label {
    final ms = skipDuration.inMilliseconds;
    if (ms == 0) return '0s';
    if (ms < 1000) return '${ms}ms';
    if (ms % 1000 == 0) return '${ms ~/ 1000}s';
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }

  @override
  Widget build(BuildContext context) {
    final color = isEnabled
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3);
    final labelColor = isEnabled
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3);

    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: level == 2 ? 30 : 26, color: color),
            const SizedBox(height: 3),
            Text(
              _label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: labelColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
