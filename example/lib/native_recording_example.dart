import 'dart:io';

import 'package:flutter/material.dart';
import 'package:screen_record_plus/screen_record_plus.dart';

import 'video_playback_screen.dart';

/// Example demonstrating native screen recording with coordinate-based capture
class NativeRecordingExample extends StatefulWidget {
  const NativeRecordingExample({super.key});

  @override
  State<NativeRecordingExample> createState() => _NativeRecordingExampleState();
}

class _NativeRecordingExampleState extends State<NativeRecordingExample> {
  late ScreenRecorderController _controller;
  bool _isRecording = false;
  bool _isNativeSupported = false;
  File? _lastExportedFile;

  @override
  void initState() {
    super.initState();
    _checkNativeSupport();
    _initializeController();
  }

  Future<void> _checkNativeSupport() async {
    final supported = await NativeScreenRecorder.isSupported();
    setState(() {
      _isNativeSupported = supported;
    });
  }

  void _initializeController() {
    _controller = ScreenRecorderController(
      // Record a 400x400 region starting at position (50, 100)
      recordingRect: const Rect.fromLTWH(50, 100, 400, 400),
    );
  }

  Future<void> _startRecording() async {
    await _controller.start();
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _controller.stop();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _exportVideo() async {
    final file = await _controller.exporter.exportVideo(
      multiCache: true,
      cacheFolder: 'native_recordings',
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
        title: const Text('Native Recording Example'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Recording Region\n400x400 logical pixels\nStarting at (50, 100)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Device pixel ratio: ${MediaQuery.of(context).devicePixelRatio.toStringAsFixed(1)}x',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          'Actual video: ${(400 * MediaQuery.of(context).devicePixelRatio).toInt()}x${(400 * MediaQuery.of(context).devicePixelRatio).toInt()} px',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isRecording)
                    const CircularProgressIndicator()
                  else
                    const Icon(Icons.videocam, size: 100, color: Colors.grey),
                  const SizedBox(height: 20),
                  Text(
                    _isRecording ? 'Recording...' : 'Ready to record',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_lastExportedFile != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Last export: ${_lastExportedFile!.path.split('/').last}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: !_isRecording ? null : _stopRecording,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isRecording ? null : _exportVideo,
                      icon: const Icon(Icons.download),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
                if (_lastExportedFile != null) ...[
                  const SizedBox(height: 16),
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
                      backgroundColor: Colors.purple,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
