import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../state.dart';

enum _DragTarget { none, playhead, repeatStart, repeatEnd, repeatRegion }

class GlobalTimelineWidget extends HookConsumerWidget {
  final void Function(Duration) onSeek;

  const GlobalTimelineWidget({super.key, required this.onSeek});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);

    if (s.totalDuration <= Duration.zero) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final widthRef = useRef(300.0);
    final dragTarget = useState(_DragTarget.none);
    final dragStartX = useRef(0.0);
    final dragStartRepeatStart = useRef<Duration?>(null);
    final dragStartRepeatEnd = useRef<Duration?>(null);
    final gripDragStartGlobalX = useRef(0.0);
    // Local position used while scrubbing so the stream doesn't fight the drag.
    final dragPosition = useState(s.position);

    double posToX(Duration pos) =>
        (pos.inMilliseconds / s.totalDuration.inMilliseconds) * widthRef.value;

    Duration xToPos(double x) => Duration(
      milliseconds: ((x / widthRef.value) * s.totalDuration.inMilliseconds)
          .round()
          .clamp(0, s.totalDuration.inMilliseconds),
    );

    _DragTarget hitTest(Offset pos) {
      final x = pos.dx;
      const handleR = 12.0;
      if (s.repeatStart != null && s.repeatEnd != null) {
        final sx = posToX(s.repeatStart!);
        final ex = posToX(s.repeatEnd!);
        if ((x - ex).abs() < handleR) return _DragTarget.repeatEnd;
        if ((x - sx).abs() < handleR) return _DragTarget.repeatStart;
        if (x > sx && x < ex) return _DragTarget.repeatRegion;
      } else if (s.repeatStart != null) {
        final sx = posToX(s.repeatStart!);
        if ((x - sx).abs() < handleR) return _DragTarget.repeatStart;
      }
      return _DragTarget.playhead;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          widthRef.value = constraints.maxWidth;
          final w = constraints.maxWidth;

          final hasRegion = s.repeatStart != null && s.repeatEnd != null;
          const gripW = 36.0;
          const gripH = 20.0;
          const trackH = 24.0;
          const totalH = trackH + gripH;

          double? gripLeft;
          if (hasRegion) {
            final sx = posToX(s.repeatStart!);
            final ex = posToX(s.repeatEnd!);
            gripLeft = ((sx + ex) / 2 - gripW / 2).clamp(0.0, w - gripW);
          }

          final isDraggingRegion = dragTarget.value == _DragTarget.repeatRegion;

          return SizedBox(
            height: totalH,
            child: Stack(
              children: [
                // ── Track + handles + seek (top 24px) ──────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: trackH,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) {
                      final target = hitTest(d.localPosition);
                      dragTarget.value = target;
                      dragStartX.value = d.localPosition.dx;
                      dragStartRepeatStart.value = s.repeatStart;
                      dragStartRepeatEnd.value = s.repeatEnd;
                      if (target == _DragTarget.playhead) {
                        final pos = xToPos(d.localPosition.dx.clamp(0.0, w));
                        dragPosition.value = pos;
                        onSeek(pos);
                      }
                    },
                    onPanUpdate: (d) {
                      final x = d.localPosition.dx.clamp(0.0, w);
                      switch (dragTarget.value) {
                        case _DragTarget.playhead:
                          final pos = xToPos(x);
                          dragPosition.value = pos;
                          onSeek(pos);
                        case _DragTarget.repeatStart:
                          final maxMs =
                              (s.repeatEnd?.inMilliseconds ??
                                  s.totalDuration.inMilliseconds) -
                              100;
                          notifier.setRepeatStart(
                            Duration(
                              milliseconds: xToPos(
                                x,
                              ).inMilliseconds.clamp(0, maxMs),
                            ),
                          );
                        case _DragTarget.repeatEnd:
                          final minMs =
                              (s.repeatStart?.inMilliseconds ?? 0) + 100;
                          notifier.setRepeatEnd(
                            Duration(
                              milliseconds: xToPos(x).inMilliseconds.clamp(
                                minMs,
                                s.totalDuration.inMilliseconds,
                              ),
                            ),
                          );
                        case _DragTarget.repeatRegion:
                          final totalMs = s.totalDuration.inMilliseconds;
                          final s0 = dragStartRepeatStart.value!.inMilliseconds;
                          final len =
                              dragStartRepeatEnd.value!.inMilliseconds - s0;
                          final dx = d.localPosition.dx - dragStartX.value;
                          final dMs = (dx / w) * totalMs;
                          final ns = (s0 + dMs).round().clamp(
                            0,
                            (totalMs - len).clamp(0, totalMs),
                          );
                          notifier.setRepeatRange(
                            Duration(milliseconds: ns),
                            Duration(milliseconds: ns + len),
                          );
                        case _DragTarget.none:
                          break;
                      }
                    },
                    onPanEnd: (_) => dragTarget.value = _DragTarget.none,
                    child: CustomPaint(
                      size: Size(w, trackH),
                      painter: _GlobalTimelinePainter(
                        position: dragTarget.value == _DragTarget.playhead
                            ? dragPosition.value
                            : s.position,
                        totalDuration: s.totalDuration,
                        repeatStart: s.repeatStart,
                        repeatEnd: s.repeatEnd,
                        colorScheme: colorScheme,
                        isDraggingRepeat:
                            dragTarget.value != _DragTarget.none &&
                            dragTarget.value != _DragTarget.playhead,
                      ),
                    ),
                  ),
                ),

                // ── Grip button (bottom 20px) ───────────────────────────────
                if (hasRegion && gripLeft != null)
                  Positioned(
                    bottom: 0,
                    left: gripLeft,
                    width: gripW,
                    height: gripH,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (d) {
                        dragTarget.value = _DragTarget.repeatRegion;
                        gripDragStartGlobalX.value = d.globalPosition.dx;
                        dragStartRepeatStart.value = s.repeatStart;
                        dragStartRepeatEnd.value = s.repeatEnd;
                      },
                      onPanUpdate: (d) {
                        final totalMs = s.totalDuration.inMilliseconds;
                        final s0 = dragStartRepeatStart.value!.inMilliseconds;
                        final len =
                            dragStartRepeatEnd.value!.inMilliseconds - s0;
                        final dx =
                            d.globalPosition.dx - gripDragStartGlobalX.value;
                        final dMs = (dx / widthRef.value) * totalMs;
                        final ns = (s0 + dMs).round().clamp(
                          0,
                          (totalMs - len).clamp(0, totalMs),
                        );
                        notifier.setRepeatRange(
                          Duration(milliseconds: ns),
                          Duration(milliseconds: ns + len),
                        );
                      },
                      onPanEnd: (_) {
                        dragTarget.value = _DragTarget.none;
                        if (s.repeatStart != null) onSeek(s.repeatStart!);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.tertiary.withOpacity(
                            isDraggingRegion ? 0.9 : 0.65,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.drag_handle,
                          size: 14,
                          color: colorScheme.onTertiary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Painter ─────────────────────────────────────────────────────────────────

class _GlobalTimelinePainter extends CustomPainter {
  final Duration position;
  final Duration totalDuration;
  final Duration? repeatStart;
  final Duration? repeatEnd;
  final ColorScheme colorScheme;
  final bool isDraggingRepeat;

  const _GlobalTimelinePainter({
    required this.position,
    required this.totalDuration,
    required this.repeatStart,
    required this.repeatEnd,
    required this.colorScheme,
    required this.isDraggingRepeat,
  });

  double _x(Duration pos, double w) =>
      (pos.inMilliseconds / totalDuration.inMilliseconds) * w;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const cy = 12.0;
    const trackH = 4.0;
    const handleR = 5.0;

    // Background track
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, cy - trackH / 2, w, trackH),
        const Radius.circular(2),
      ),
      Paint()..color = colorScheme.outline.withOpacity(0.25),
    );

    // Progress fill (0 → position)
    final px = _x(position, w).clamp(0.0, w);
    if (px > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, cy - trackH / 2, px, trackH),
          const Radius.circular(2),
        ),
        Paint()..color = colorScheme.primary.withOpacity(0.3),
      );
    }

    // A-B repeat region
    if (repeatStart != null && repeatEnd != null) {
      final sx = _x(repeatStart!, w);
      final ex = _x(repeatEnd!, w);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(sx, cy - 6, ex - sx, 12),
          const Radius.circular(3),
        ),
        Paint()
          ..color = colorScheme.tertiary.withOpacity(
            isDraggingRepeat ? 0.55 : 0.30,
          ),
      );
      canvas.drawCircle(
        Offset(sx, cy),
        handleR,
        Paint()..color = colorScheme.tertiary,
      );
      canvas.drawCircle(
        Offset(ex, cy),
        handleR,
        Paint()..color = colorScheme.tertiary,
      );
    } else if (repeatStart != null) {
      final sx = _x(repeatStart!, w);
      canvas.drawCircle(
        Offset(sx, cy),
        handleR,
        Paint()..color = colorScheme.tertiary.withOpacity(0.6),
      );
    }

    // Playhead
    canvas.drawLine(
      Offset(px, 3),
      Offset(px, cy + trackH / 2 + 1),
      Paint()
        ..color = colorScheme.primary
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(px, 3), 4.0, Paint()..color = colorScheme.primary);
  }

  @override
  bool shouldRepaint(_GlobalTimelinePainter old) =>
      position != old.position ||
      totalDuration != old.totalDuration ||
      repeatStart != old.repeatStart ||
      repeatEnd != old.repeatEnd ||
      isDraggingRepeat != old.isDraggingRepeat ||
      colorScheme != old.colorScheme;
}
