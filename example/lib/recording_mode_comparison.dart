import 'package:flutter/material.dart';
import 'package:screen_record_plus/screen_record_plus.dart';

/// Example comparing widget-based and native recording modes
class RecordingModeComparison extends StatefulWidget {
  const RecordingModeComparison({super.key});

  @override
  State<RecordingModeComparison> createState() => _RecordingModeComparisonState();
}

class _RecordingModeComparisonState extends State<RecordingModeComparison> {
  late ScreenRecorderController _widgetController;
  late ScreenRecorderController _nativeController;
  
  bool _isWidgetRecording = false;
  bool _isNativeRecording = false;
  bool _isNativeSupported = false;

  @override
  void initState() {
    super.initState();
    _checkNativeSupport();
    _initializeControllers();
  }

  Future<void> _checkNativeSupport() async {
    final supported = await NativeScreenRecorder.isSupported();
    setState(() {
      _isNativeSupported = supported;
    });
  }

  void _initializeControllers() {
    // Widget-based controller
    _widgetController = ScreenRecorderController(
      recordingMode: RecordingMode.widget,
      pixelRatio: 3.0,
      skipFramesBetweenCaptures: 0,
    );

    // Native controller with coordinates
    _nativeController = ScreenRecorderController(
      recordingMode: RecordingMode.native,
      pixelRatio: 3.0,
      skipFramesBetweenCaptures: 0,
      recordingRect: const Rect.fromLTWH(0, 0, 300, 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording Mode Comparison'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModeCard(
                title: 'Widget-Based Recording',
                description: 'Records using Flutter\'s RepaintBoundary.\n'
                    'Best for: Recording specific widgets, custom animations',
                mode: RecordingMode.widget,
                controller: _widgetController,
                isRecording: _isWidgetRecording,
                onStart: () async {
                  await _widgetController.start();
                  setState(() => _isWidgetRecording = true);
                },
                onStop: () {
                  _widgetController.stop();
                  setState(() => _isWidgetRecording = false);
                },
                onExport: () async {
                  await _widgetController.exporter.exportVideo(
                    multiCache: true,
                    cacheFolder: 'widget_recordings',
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildModeCard(
                title: 'Native Recording',
                description: 'Records using native platform APIs.\n'
                    'Best for: Full screen recording, coordinate-based capture',
                mode: RecordingMode.native,
                controller: _nativeController,
                isRecording: _isNativeRecording,
                isSupported: _isNativeSupported,
                onStart: () async {
                  await _nativeController.start();
                  setState(() => _isNativeRecording = true);
                },
                onStop: () {
                  _nativeController.stop();
                  setState(() => _isNativeRecording = false);
                },
                onExport: () async {
                  await _nativeController.exporter.exportVideo(
                    multiCache: true,
                    cacheFolder: 'native_recordings',
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildComparisonTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String description,
    required RecordingMode mode,
    required ScreenRecorderController controller,
    required bool isRecording,
    required VoidCallback onStart,
    required VoidCallback onStop,
    required VoidCallback onExport,
    bool isSupported = true,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 16),
            if (!isSupported)
              const Text(
                'Not supported on this platform',
                style: TextStyle(color: Colors.red),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: isRecording ? null : onStart,
                    child: const Text('Start'),
                  ),
                  ElevatedButton(
                    onPressed: !isRecording ? null : onStop,
                    child: const Text('Stop'),
                  ),
                  ElevatedButton(
                    onPressed: isRecording ? null : onExport,
                    child: const Text('Export'),
                  ),
                ],
              ),
            if (isRecording)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Comparison',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey),
              children: [
                _buildTableRow('Feature', 'Widget', 'Native', isHeader: true),
                _buildTableRow('Platform Support', 'All', 'iOS 11+, Android 21+'),
                _buildTableRow('Coordinate Recording', 'No', 'Yes'),
                _buildTableRow('Full Screen', 'No', 'Yes'),
                _buildTableRow('Widget Capture', 'Yes', 'No'),
                _buildTableRow('Performance', 'Good', 'Better'),
                _buildTableRow('Quality', 'Good', 'Better'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String feature, String widget, String native,
      {bool isHeader = false}) {
    final style = TextStyle(
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
    );
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(feature, style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(widget, style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(native, style: style),
        ),
      ],
    );
  }
}
