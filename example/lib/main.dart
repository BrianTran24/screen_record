import 'dart:io';

import 'package:flutter/material.dart';
import 'package:screen_record_plus/screen_record_plus.dart';

import 'video_playback_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen Record Plus Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Native Screen Recording Demo'),
    );
  }
}

enum RecordStatus { none, recording, stop, exporting }

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  RecordStatus status = RecordStatus.none;
  bool isNativeSupported = false;
  File? exportedFile;

  ScreenRecorderController controller = ScreenRecorderController(
    // Example: Record a specific region (400x400 starting at 100,100)
    recordingRect: const Rect.fromLTWH(100, 100, 400, 400),
  );

  @override
  void initState() {
    super.initState();
    _checkNativeSupport();
  }

  Future<void> _checkNativeSupport() async {
    final supported = await NativeScreenRecorder.isSupported();
    setState(() {
      isNativeSupported = supported;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (!isNativeSupported)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Native screen recording is not supported on this platform',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (isNativeSupported) ...[
                Builder(
                  builder: (context) {
                    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
                    final videoDimension = (400 * pixelRatio).toInt();
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Recording a 400x400 region starting at (100, 100)',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Device pixel ratio: ${pixelRatio.toStringAsFixed(1)}x',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Video will be: ${videoDimension}x$videoDimension pixels',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          status == RecordStatus.recording
                              ? Icons.fiber_manual_record
                              : Icons.videocam,
                          size: 80,
                          color: status == RecordStatus.recording
                              ? Colors.red
                              : Colors.grey,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          status == RecordStatus.recording
                              ? 'Recording...'
                              : 'Ready to record',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (status == RecordStatus.none)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await controller.start();
                      setState(() {
                        status = RecordStatus.recording;
                      });
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Recording'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                if (status == RecordStatus.recording)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await controller.stop();
                      setState(() {
                        status = RecordStatus.stop;
                      });
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                if (status == RecordStatus.stop)
                  ElevatedButton.icon(
                    onPressed: () async {
                      setState(() {
                        status = RecordStatus.exporting;
                      });
                      final file = await controller.exporter.exportVideo(
                        multiCache: true,
                        cacheFolder: "recordings",
                        onProgress: (result) {
                          debugPrint('Export: ${result.status} - ${result.percent}');
                        },
                      );
                      setState(() {
                        exportedFile = file;
                        status = RecordStatus.none;
                      });
                      if (file != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Video exported to: ${file.path}'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Export Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                if (status == RecordStatus.exporting)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Exporting video...'),
                    ],
                  ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: status == RecordStatus.none
                      ? () async {
                          await controller.clearCacheFolder("recordings");
                          setState(() {
                            exportedFile = null;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cache cleared'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.delete),
                  label: const Text('Clear Cache'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                if (exportedFile != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 48),
                        const SizedBox(height: 8),
                        const Text(
                          'Last export:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exportedFile!.path.split('/').last,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlaybackScreen(
                                  videoFile: exportedFile!,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Play Video'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
