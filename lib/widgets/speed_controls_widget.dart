import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SpeedControlsWidget extends StatelessWidget {
  final double playbackSpeed;
  final bool isEnabled;
  final void Function(double) onSpeedChanged;

  const SpeedControlsWidget({
    super.key,
    required this.playbackSpeed,
    required this.isEnabled,
    required this.onSpeedChanged,
  });

  static const _labeledSpeeds = [0.25, 0.5, 1.0, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.speed_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '${playbackSpeed.toStringAsFixed(2)}x',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (playbackSpeed != 1.0)
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'Normal speed (1.0x)',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: isEnabled ? () => onSpeedChanged(1.0) : null,
            ),
          Expanded(
            child: _SpeedSlider(
              value: playbackSpeed,
              min: 0.25,
              max: 2.0,
              divisions: 35,
              enabled: isEnabled,
              onChanged: onSpeedChanged,
              tickValues: _labeledSpeeds,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedSlider extends HookWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final List<double> tickValues;

  const _SpeedSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.enabled,
    required this.onChanged,
    required this.tickValues,
  });

  static const _kThumbRadius = 10.0;
  static const _kTrackHeight = 4.0;
  static const _kInteractiveHeight = 44.0;
  static const _kTickHeight = 6.0;
  static const _kLabelFontSize = 10.0;
  static const _kTotalHeight = _kInteractiveHeight + _kTickHeight + 2 + 14;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDragging = useState(false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final trackStart = _kThumbRadius;
        final trackEnd = width - _kThumbRadius;
        final trackWidth = trackEnd - trackStart;
        const trackY = _kInteractiveHeight / 2;

        double valueToX(double v) =>
            trackStart + (v - min) / (max - min) * trackWidth;

        double xToValue(double x) {
          final fraction = (x - trackStart).clamp(0.0, trackWidth) / trackWidth;
          final raw = min + fraction * (max - min);
          final step = (max - min) / divisions;
          return (raw / step).round() * step;
        }

        void handlePosition(double x) {
          if (enabled) onChanged(xToValue(x));
        }

        final thumbX = valueToX(value);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: enabled
              ? (d) {
                  isDragging.value = true;
                  handlePosition(d.localPosition.dx);
                }
              : null,
          onHorizontalDragUpdate: enabled
              ? (d) => handlePosition(d.localPosition.dx)
              : null,
          onHorizontalDragEnd: enabled ? (_) => isDragging.value = false : null,
          onTapDown: enabled ? (d) => handlePosition(d.localPosition.dx) : null,
          child: SizedBox(
            width: width,
            height: _kTotalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Inactive track
                Positioned(
                  left: trackStart,
                  width: trackWidth,
                  top: trackY - _kTrackHeight / 2,
                  height: _kTrackHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(_kTrackHeight / 2),
                    ),
                  ),
                ),
                // Active track
                Positioned(
                  left: trackStart,
                  width: (thumbX - trackStart).clamp(0.0, trackWidth),
                  top: trackY - _kTrackHeight / 2,
                  height: _kTrackHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: enabled
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.38),
                      borderRadius: BorderRadius.circular(_kTrackHeight / 2),
                    ),
                  ),
                ),
                // Thumb
                Positioned(
                  left: thumbX - _kThumbRadius,
                  top: trackY - _kThumbRadius,
                  width: _kThumbRadius * 2,
                  height: _kThumbRadius * 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: enabled
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.38),
                      shape: BoxShape.circle,
                      boxShadow: isDragging.value
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.25),
                                blurRadius: 12,
                                spreadRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                // Drag tooltip
                if (isDragging.value)
                  Positioned(
                    left: thumbX,
                    top: trackY - _kThumbRadius - 8 - 28,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.inverseSurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${value.toStringAsFixed(2)}x',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onInverseSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Tick marks and labels
                for (final speed in tickValues)
                  Positioned(
                    left: valueToX(speed),
                    top: _kInteractiveHeight,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 1,
                            height: _kTickHeight,
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${speed}x',
                            style: TextStyle(
                              fontSize: _kLabelFontSize,
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
