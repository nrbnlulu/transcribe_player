import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../state.dart';
import 'play_button_widget.dart';
import 'seek_button_widget.dart';

class PlaybackControlsWidget extends HookConsumerWidget {
  const PlaybackControlsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final isEnabled = s.filePath != null;

    /// Inner level (1): 2s × speed  → 1s at 0.5x, 0.5s at 0.25x
    /// Outer level (2): 4s × speed  → 2s at 0.5x, 1s at 0.25x
    Duration skipInterval(int level) {
      final multiplier = level == 1 ? 2.0 : 4.0;
      return Duration(
        milliseconds: (multiplier * s.playbackSpeed * 1000).round(),
      );
    }

    void seekBack(Duration interval) {
      final pos = s.position - interval;
      notifier.seekToPosition(pos < Duration.zero ? Duration.zero : pos);
    }

    void seekForward(Duration interval) {
      final pos = s.position + interval;
      notifier.seekToPosition(pos > s.totalDuration ? s.totalDuration : pos);
    }

    final skip1 = skipInterval(1);
    final skip2 = skipInterval(2);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 12,
      children: [
        // Outer back (level 2)
        SeekButtonWidget(
          direction: SeekDirection.back,
          level: 2,
          skipDuration: skip2,
          isEnabled: isEnabled,
          onPressed: () => seekBack(skip2),
        ),
        // Inner back (level 1)
        SeekButtonWidget(
          direction: SeekDirection.back,
          level: 1,
          skipDuration: skip1,
          isEnabled: isEnabled,
          onPressed: () => seekBack(skip1),
        ),

        // Main widget: play/pause
        PlayButtonWidget(
          isPlaying: s.isPlaying,
          isEnabled: isEnabled,
          onPressed: notifier.togglePlayPause,
        ),

        // Inner forward (level 1)
        SeekButtonWidget(
          direction: SeekDirection.forward,
          level: 1,
          skipDuration: skip1,
          isEnabled: isEnabled,
          onPressed: () => seekForward(skip1),
        ),
        // Outer forward (level 2)
        SeekButtonWidget(
          direction: SeekDirection.forward,
          level: 2,
          skipDuration: skip2,
          isEnabled: isEnabled,
          onPressed: () => seekForward(skip2),
        ),
      ],
    );
  }
}
