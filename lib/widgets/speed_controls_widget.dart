import 'package:flutter/material.dart';

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

  static const _minSpeed = 0.25;
  static const _maxSpeed = 2.0;
  // M3 RoundSliderThumbShape default enabled radius
  static const _thumbRadius = 10.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: playbackSpeed,
                  min: _minSpeed,
                  max: _maxSpeed,
                  divisions: 35,
                  onChanged: isEnabled ? onSpeedChanged : null,
                  label: '${playbackSpeed.toStringAsFixed(2)}x',
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final trackWidth =
                        constraints.maxWidth - 2 * _thumbRadius;
                    return SizedBox(
                      height: 20,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final speed in _labeledSpeeds)
                            Positioned(
                              left: _thumbRadius +
                                  (speed - _minSpeed) /
                                      (_maxSpeed - _minSpeed) *
                                      trackWidth,
                              top: 0,
                              child: FractionalTranslation(
                                translation: const Offset(-0.5, 0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 1,
                                      height: 6,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withOpacity(0.5),
                                    ),
                                    Text(
                                      '${speed}x',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
