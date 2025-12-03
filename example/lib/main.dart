import 'dart:io';

import 'package:flutter/material.dart';
import 'package:screen_record_plus/screen_record_plus.dart';

import 'sample_animation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // FFmpegKitConfig.enableLogCallback((log) {
  //   final message = log.getMessage();
  //   print(message);
  // });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Screen Record Plus Demo'),
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
  bool useNativeRecording = false;
  bool isNativeSupported = false;

  ScreenRecorderController controller = ScreenRecorderController(
    binding: WidgetsFlutterBinding.ensureInitialized(),
    skipFramesBetweenCaptures: 0,
    pixelRatio: 3,
    recordingMode: RecordingMode.widget,
  );

  bool get canExport => controller.exporter.hasFrames;
  double percentExport = 0;

  Duration duration = const Duration(seconds: 3);

  File? testFile;

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

  void _updateRecordingMode() {
    controller = ScreenRecorderController(
      binding: WidgetsFlutterBinding.ensureInitialized(),
      skipFramesBetweenCaptures: 0,
      pixelRatio: 3,
      recordingMode: useNativeRecording ? RecordingMode.native : RecordingMode.widget,
      // Example: Record a specific region (200x200 starting at 100,100)
      recordingRect: useNativeRecording ? const Rect.fromLTWH(100, 100, 200, 200) : null,
    );
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
              if (isNativeSupported)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Native Recording:'),
                      Switch(
                        value: useNativeRecording,
                        onChanged: status == RecordStatus.none
                            ? (value) {
                                setState(() {
                                  useNativeRecording = value;
                                  _updateRecordingMode();
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              if (useNativeRecording && status == RecordStatus.none)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Native mode will record a 200x200 region\nstarting at position (100, 100)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ScreenRecorder(
                height: MediaQuery.of(context).size.height - 400,
                width: MediaQuery.of(context).size.width,
                controller: controller,
                child: const UnconstrainedBox(
                  child: SizedBox(
                    height: 300,
                    width: 300,
                    child: SampleAnimation(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (status == RecordStatus.none)
                ElevatedButton(
                  onPressed: () async {
                    await controller.start();
                    setState(() {
                      status = RecordStatus.recording;
                    });
                  },
                  child: Text(
                    useNativeRecording ? 'Start Native Recording' : 'Start Widget Recording',
                  ),
                ),
              if (status == RecordStatus.recording)
                ElevatedButton(
                  onPressed: () async {
                    controller.stop();
                    setState(() {
                      status = RecordStatus.stop;
                    });
                  },
                  child: const Text('Stop Recording'),
                ),
              if (status == RecordStatus.stop)
                ElevatedButton(
                  onPressed: () async {
                    await controller.exporter.exportVideo(multiCache: false, cacheFolder: "test2").then((val) {
                      debugPrint('File Exported: $val');
                    });

                    setState(() {
                      status = RecordStatus.none;
                    });
                  },
                  child: const Text('Export'),
                ),
              ElevatedButton(
                onPressed: () async {
                  controller.clearCacheFolder("test2");
                },
                child: const Text('Clear Cache Folder'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
