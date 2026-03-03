import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../state.dart';

class WaveformTimelineWidget extends HookConsumerWidget {
  final void Function(Duration) onSeek;

  const WaveformTimelineWidget({super.key, required this.onSeek});

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ds = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '$m:$s.$ds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);

    const historySize = 600;
    final history = useState(List<double>.filled(historySize, 1.0));
    final lastPitch = useRef(1.0);
    final tick = useRef(0);

    final isDragging = useState(false);
    final dragOffsetMs = useState(0.0);
    final isReturning = useState(false);
    final widthRef = useRef(300.0);
    final wasPlayingOnDragStart = useRef(false);

    // Subscribe to the pitch stream — updates lastPitch whenever pitch changes.
    useEffect(() {
      final sub = notifier.pitchStream.listen((p) => lastPitch.value = p);
      return sub.cancel;
    }, const []);

    // 30fps tick while playing: push a new sample (pitch + harmonics) into history.
    useEffect(() {
      if (!s.isPlaying) return null;
      final timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        tick.value++;
        final t = tick.value.toDouble();
        final harmonic =
            sin(t * 0.4) * 0.04 + cos(t * 0.15) * 0.02 + sin(t * 0.8) * 0.015;
        final sample = lastPitch.value + harmonic;
        final next = List<double>.of(history.value)
          ..removeAt(0)
          ..add(sample);
        history.value = next;
      });
      return timer.cancel;
    }, [s.isPlaying]);

    // Exponential spring-back toward 0 after drag is released.
    useEffect(() {
      if (!isReturning.value) return null;
      Timer? t;
      void step() {
        t = Timer(const Duration(milliseconds: 16), () {
          if (dragOffsetMs.value.abs() < 0.5) {
            dragOffsetMs.value = 0.0;
            isReturning.value = false;
          } else {
            dragOffsetMs.value *= 0.82;
            step();
          }
        });
      }

      step();
      return () => t?.cancel();
    }, [isReturning.value]);

    // Window duration mirrors the old zoomed-timeline logic: 10s × playbackSpeed.
    final windowDurationMs = 10000.0 * s.playbackSpeed;
    final hasFile = s.totalDuration > Duration.zero;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          if (!hasFile)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Load an audio file to begin',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            // ── Time row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(s.position),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  // Seek-offset badge — shown while scrubbing.
                  if (dragOffsetMs.value.abs() > 0.5)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${dragOffsetMs.value >= 0 ? '+' : ''}${dragOffsetMs.value.round()}ms',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSecondaryContainer,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  Text(
                    _fmt(s.totalDuration),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            // ── Waveform canvas ───────────────────────────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) {
                isDragging.value = true;
                isReturning.value = false;
                wasPlayingOnDragStart.value = s.isPlaying;
                if (s.isPlaying) notifier.togglePlayPause();
              },
              onHorizontalDragUpdate: (details) {
                // ms per pixel: full widget width ≙ windowDurationMs.
                // Smaller playbackSpeed → smaller window → finer precision.
                // Negated: drag right = seek backward, drag left = seek forward.
                final sensitivity = windowDurationMs / widthRef.value;
                final next =
                    dragOffsetMs.value - details.delta.dx * sensitivity;
                dragOffsetMs.value = next.clamp(
                  -windowDurationMs / 2,
                  windowDurationMs / 2,
                );
              },
              onHorizontalDragEnd: (_) {
                isDragging.value = false;
                final newPos =
                    s.position +
                    Duration(milliseconds: dragOffsetMs.value.round());
                final clamped = newPos < Duration.zero
                    ? Duration.zero
                    : newPos > s.totalDuration
                    ? s.totalDuration
                    : newPos;
                onSeek(clamped);
                if (wasPlayingOnDragStart.value) notifier.togglePlayPause();
                Future.delayed(
                  const Duration(milliseconds: 500),
                  () => isReturning.value = true,
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  widthRef.value = constraints.maxWidth;
                  return CustomPaint(
                    size: Size(constraints.maxWidth, 80),
                    painter: _WaveformPainter(
                      history: history.value,
                      // Negative dragOffset (drag right) → waveform shifts right (older data).
                      shiftFraction: dragOffsetMs.value / windowDurationMs,
                      primaryColor: colorScheme.primary,
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Painter ────────────────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  final List<double> history;

  /// Fraction of widget width to shift the waveform.
  /// Positive = seeking forward = waveform moves left.
  final double shiftFraction;

  final Color primaryColor;

  const _WaveformPainter({
    required this.history,
    required this.shiftFraction,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final n = history.length;
    if (n < 2) return;

    canvas.clipRect(Offset.zero & size);

    final shiftPx = -shiftFraction * w;

    final path = Path();
    for (int i = 0; i < n; i++) {
      final x = (i / (n - 1)) * w + shiftPx;
      // Normalise: pitch 1.0 ± 0.2 → ±1.0, clamped.
      final norm = ((history[i] - 1.0) / 0.2).clamp(-1.0, 1.0);
      final y = h / 2 - norm * h * 0.38;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final rect = Offset.zero & size;

    // Glow pass.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            primaryColor.withOpacity(0),
            primaryColor.withOpacity(0.12),
            primaryColor.withOpacity(0.22),
            primaryColor.withOpacity(0.12),
            primaryColor.withOpacity(0),
          ],
          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        ).createShader(rect),
    );

    // Main line pass.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            primaryColor.withOpacity(0),
            primaryColor.withOpacity(0.7),
            primaryColor.withOpacity(1.0),
            primaryColor.withOpacity(0.7),
            primaryColor.withOpacity(0),
          ],
          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        ).createShader(rect),
    );

    // Playhead cursor — subtle vertical tick at the right edge of history
    // (newest sample position when not dragging).
    canvas.drawLine(
      Offset(w + shiftPx, h * 0.15),
      Offset(w + shiftPx, h * 0.85),
      Paint()
        ..color = primaryColor.withOpacity(0.5)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      history != old.history ||
      shiftFraction != old.shiftFraction ||
      primaryColor != old.primaryColor;
}
