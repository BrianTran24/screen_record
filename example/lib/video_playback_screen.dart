import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Screen to playback a recorded video
class VideoPlaybackScreen extends StatefulWidget {
  final File videoFile;

  const VideoPlaybackScreen({
    super.key,
    required this.videoFile,
  });

  @override
  State<VideoPlaybackScreen> createState() => _VideoPlaybackScreenState();
}

class _VideoPlaybackScreenState extends State<VideoPlaybackScreen> {
  // Tolerance for matching aspect ratios to common ratios (e.g., 16:9, 4:3)
  static const double _aspectRatioTolerance = 0.01;
  
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(widget.videoFile);
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      // Auto play on load
      _controller.play();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatAspectRatio(double aspectRatio) {
    // Try to find common aspect ratios
    const commonRatios = {
      16 / 9: '16:9',
      4 / 3: '4:3',
      21 / 9: '21:9',
      1.0: '1:1',
      3 / 2: '3:2',
      2 / 1: '2:1',
    };
    
    // Check if it matches a common ratio (with small tolerance)
    for (final entry in commonRatios.entries) {
      if ((entry.key - aspectRatio).abs() < _aspectRatioTolerance) {
        return entry.value;
      }
    }
    
    // For non-standard ratios, show as decimal
    return '${aspectRatio.toStringAsFixed(2)}:1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Playback'),
        actions: [
          if (_isInitialized)
            IconButton(
              icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
            ),
        ],
      ),
      body: Center(
        child: _hasError
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading video',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage ?? 'Unknown error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : !_isInitialized
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading video...'),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                      _buildControls(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, VideoPlayerValue value, child) {
              return Column(
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDuration(value.position),
                        style: const TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: Slider(
                          value: value.position.inMilliseconds.toDouble(),
                          min: 0,
                          max: value.duration.inMilliseconds.toDouble(),
                          onChanged: (newValue) {
                            _controller.seekTo(Duration(milliseconds: newValue.toInt()));
                          },
                        ),
                      ),
                      Text(
                        _formatDuration(value.duration),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white),
                        onPressed: () {
                          final newPosition = _controller.value.position - const Duration(seconds: 10);
                          _controller.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
                        },
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          size: 48,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            value.isPlaying ? _controller.pause() : _controller.play();
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white),
                        onPressed: () {
                          final newPosition = _controller.value.position + const Duration(seconds: 10);
                          _controller.seekTo(
                            newPosition > value.duration ? value.duration : newPosition,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            widget.videoFile.path.split('/').last,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          if (_isInitialized)
            Text(
              '${_controller.value.size.width.toInt()}x${_controller.value.size.height.toInt()} • ${_formatAspectRatio(_controller.value.aspectRatio)}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
