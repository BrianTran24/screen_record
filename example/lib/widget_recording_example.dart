import 'dart:io';

import 'package:flutter/material.dart';
import 'package:screen_record_plus/screen_record_plus.dart';

import 'video_playback_screen.dart';

/// Example demonstrating widget-based recording using GlobalKey
class WidgetRecordingExample extends StatefulWidget {
  const WidgetRecordingExample({super.key});

  @override
  State<WidgetRecordingExample> createState() => _WidgetRecordingExampleState();
}

class _WidgetRecordingExampleState extends State<WidgetRecordingExample> {
  final GlobalKey _widgetKey = GlobalKey();
  ScreenRecorderController? _controller;
  bool _isRecording = false;
  bool _isNativeSupported = false;
  File? _lastExportedFile;
  Rect? _widgetRect;

  @override
  void initState() {
    super.initState();
    _checkNativeSupport();
  }

  Future<void> _checkNativeSupport() async {
    final supported = await NativeScreenRecorder.isSupported();
    setState(() {
      _isNativeSupported = supported;
    });
  }

  void _setupRecording() {
    // Get the widget's position and size on screen
    final rect = ScreenRecorderController.getWidgetRect(_widgetKey);
    
    if (rect == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get widget position. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _widgetRect = rect;
      _controller = ScreenRecorderController(recordingRect: rect);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Recording area set: ${rect.width.toInt()}x${rect.height.toInt()} at (${rect.left.toInt()}, ${rect.top.toInt()})',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _startRecording() async {
    if (_controller == null) {
      _setupRecording();
      if (_controller == null) return;
    }

    await _controller!.start();
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    if (_controller == null) return;

    await _controller!.stop();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _exportVideo() async {
    if (_controller == null) return;

    final file = await _controller!.exporter.exportVideo(
      multiCache: true,
      cacheFolder: 'widget_recordings',
      onProgress: (result) {
        debugPrint('Export progress: ${result.status} - ${result.percent}');
      },
    );

    if (file != null) {
      setState(() {
        _lastExportedFile = file;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video exported to: ${file.path}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isNativeSupported) {
      return const Scaffold(
        body: Center(
          child: Text('Native screen recording is not supported on this device'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Recording Example'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'This example shows how to record a specific widget area using GlobalKey',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            // This is the widget we want to record
            Container(
              key: _widgetKey,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isRecording ? Icons.fiber_manual_record : Icons.videocam,
                    size: 80,
                    color: _isRecording ? Colors.red : Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isRecording ? 'Recording This Widget!' : 'Widget to Record',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Only this widget area will be recorded',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_widgetRect != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Size: ${_widgetRect!.width.toInt()}×${_widgetRect!.height.toInt()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isRecording ? null : _startRecording,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: !_isRecording ? null : _stopRecording,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isRecording ? null : _exportVideo,
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_lastExportedFile != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 40),
                          const SizedBox(height: 8),
                          const Text(
                            'Video exported successfully!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoPlaybackScreen(
                                    videoFile: _lastExportedFile!,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('Play Video'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'How it works',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            '1. Attach a GlobalKey to the widget you want to record\n'
                            '2. Use ScreenRecorderController.getWidgetRect(key) to get the widget\'s position\n'
                            '3. Create a controller with the recordingRect parameter\n'
                            '4. Start recording - only the widget area will be captured',
                            style: TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
