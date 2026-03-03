import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'state.dart';
import 'widgets/file_info_widget.dart';
import 'widgets/repeat_controls_widget.dart';
import 'widgets/speed_controls_widget.dart';
import 'widgets/playback_controls_widget.dart';
import 'widgets/global_timeline_widget.dart';
import 'widgets/waveform_timeline_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const ProviderScope(child: TranscribePlayerApp()));
}

class TranscribePlayerApp extends StatelessWidget {
  const TranscribePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transcribe Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TranscribePlayerScreen(),
    );
  }
}

class TranscribePlayerScreen extends HookConsumerWidget {
  const TranscribePlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final isEnabled = s.filePath != null;
    final isLoading = useState(false);

    return Scaffold(
      appBar: AppBar(title: const Text('Transcribe Player'), centerTitle: true),
      body: SafeArea(
        child: Column(
          spacing: 10,
          children: [
            FileInfoWidget(
              fileName: s.fileName,
              totalDuration: s.totalDuration,
              isLoading: isLoading.value,
              onLoadFile: () async {
                isLoading.value = true;
                try {
                  final error = await notifier.loadAudioFile();
                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  isLoading.value = false;
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: RepeatControlsWidget(),
            ),
            SpeedControlsWidget(
              playbackSpeed: s.playbackSpeed,
              isEnabled: isEnabled,
              onSpeedChanged: notifier.setSpeed,
            ),
            Flexible(
              flex: 6,
              child: Center(child: const PlaybackControlsWidget()),
            ),
            GlobalTimelineWidget(onSeek: notifier.seekToPosition),
            WaveformTimelineWidget(onSeek: notifier.seekToPosition),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
