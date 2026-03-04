import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

class PlayerState {
  final bool isPlaying;
  final Duration position;
  final Duration totalDuration;
  final double playbackSpeed;
  final Duration? repeatStart;
  final Duration? repeatEnd;
  final bool isRepeatActive;
  final String? fileName;
  final String? filePath;

  const PlayerState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.totalDuration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.repeatStart,
    this.repeatEnd,
    this.isRepeatActive = false,
    this.fileName,
    this.filePath,
  });

  // Sentinel used to distinguish "not provided" from explicit null in copyWith.
  static const _keep = Object();

  PlayerState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? totalDuration,
    double? playbackSpeed,
    Object? repeatStart = _keep,
    Object? repeatEnd = _keep,
    bool? isRepeatActive,
    Object? fileName = _keep,
    Object? filePath = _keep,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      totalDuration: totalDuration ?? this.totalDuration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      repeatStart: identical(repeatStart, _keep)
          ? this.repeatStart
          : repeatStart as Duration?,
      repeatEnd: identical(repeatEnd, _keep)
          ? this.repeatEnd
          : repeatEnd as Duration?,
      isRepeatActive: isRepeatActive ?? this.isRepeatActive,
      fileName: identical(fileName, _keep)
          ? this.fileName
          : fileName as String?,
      filePath: identical(filePath, _keep)
          ? this.filePath
          : filePath as String?,
    );
  }
}

class PlayerNotifier extends Notifier<PlayerState> {
  late final Player _player;

  @override
  PlayerState build() {
    _player = Player(
      configuration: const PlayerConfiguration(bufferSize: 10 * 1024 * 1024),
    );

    final playingSub = _player.stream.playing.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    final durationSub = _player.stream.duration.listen((duration) {
      state = state.copyWith(totalDuration: duration);
    });

    final completedSub = _player.stream.completed.listen((completed) {
      if (completed) {
        state = state.copyWith(isPlaying: false, position: Duration.zero);
      }
    });

    final positionSub = _player.stream.position.listen((pos) {
      state = state.copyWith(position: pos);
      if (state.isRepeatActive &&
          state.repeatEnd != null &&
          pos >= state.repeatEnd!) {
        _player.seek(state.repeatStart!);
      }
    });

    ref.onDispose(() {
      playingSub.cancel();
      durationSub.cancel();
      completedSub.cancel();
      positionSub.cancel();
      _player.dispose();
    });

    return const PlayerState();
  }

  /// Returns an error message on failure, null on success.
  Future<String?> loadAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        state = state.copyWith(
          fileName: result.files.single.name,
          filePath: path,
          repeatStart: null,
          repeatEnd: null,
          isRepeatActive: false,
          position: Duration.zero,
        );
        await _player.open(Media(path));
      }
      return null;
    } catch (e) {
      return 'Error loading audio: $e';
    }
  }

  Future<void> togglePlayPause() async {
    if (state.filePath == null) return;
    if (state.isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(playbackSpeed: speed);
    await _player.setRate(speed);
  }

  void toggleRepeatMode() {
    if (!state.isRepeatActive) {
      state = state.copyWith(
        isRepeatActive: true,
        repeatStart: state.position,
        repeatEnd: null,
      );
    } else if (state.repeatStart == null) {
      state = state.copyWith(repeatStart: state.position);
    } else {
      var start = state.repeatStart;
      var end = state.position;
      if (end <= start!) {
        final tmp = start;
        start = end;
        end = tmp;
      }
      state = state.copyWith(repeatStart: start, repeatEnd: end);
    }
  }

  void clearRepeat() {
    state = state.copyWith(
      repeatStart: null,
      repeatEnd: null,
      isRepeatActive: false,
    );
  }

  void clearPointB() {
    state = state.copyWith(repeatEnd: null);
  }

  Future<void> seekToPosition(Duration position) async {
    // If in repeat mode and seeking outside the A-B range,
    // shift the A-B range to center around the new position.
    if (state.isRepeatActive &&
        state.repeatStart != null &&
        state.repeatEnd != null) {
      final rangeStart = state.repeatStart!;
      final rangeEnd = state.repeatEnd!;
      final rangeDuration = rangeEnd - rangeStart;

      // Check if the new position is outside the current A-B range
      if (position < rangeStart || position > rangeEnd) {
        // Calculate new A-B range centered on the seeked position
        final halfRange = Duration(
          milliseconds: rangeDuration.inMilliseconds ~/ 2,
        );
        var newStart = position - halfRange;
        var newEnd = position + halfRange;

        // Clamp to total duration bounds
        if (newStart < Duration.zero) {
          newStart = Duration.zero;
          newEnd = newStart + rangeDuration;
        }
        if (newEnd > state.totalDuration) {
          newEnd = state.totalDuration;
          newStart = newEnd - rangeDuration;
        }

        // Ensure newStart doesn't go negative after clamping
        if (newStart < Duration.zero) {
          newStart = Duration.zero;
        }

        state = state.copyWith(repeatStart: newStart, repeatEnd: newEnd);
      }
    }

    await _player.seek(position);
    state = state.copyWith(position: position);
  }

  void setRepeatStart(Duration pos) {
    state = state.copyWith(repeatStart: pos);
  }

  void setRepeatEnd(Duration pos) {
    state = state.copyWith(repeatEnd: pos);
  }

  void setRepeatRange(Duration start, Duration end) {
    state = state.copyWith(repeatStart: start, repeatEnd: end);
  }

  Stream<double> get pitchStream => _player.stream.pitch;
}

final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(
  PlayerNotifier.new,
);
