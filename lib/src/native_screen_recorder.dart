import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native screen recorder that uses platform-specific APIs
/// for screen recording with coordinate support
class NativeScreenRecorder {
  static const MethodChannel _channel = MethodChannel('screen_record_plus');

  /// Start recording with optional coordinates
  /// 
  /// [x] - X coordinate of the recording area (optional)
  /// [y] - Y coordinate of the recording area (optional)
  /// [width] - Width of the recording area (optional)
  /// [height] - Height of the recording area (optional)
  /// 
  /// If coordinates are not provided, records the entire screen
  static Future<bool> startRecording({
    double? x,
    double? y,
    double? width,
    double? height,
  }) async {
    try {
      final Map<String, dynamic> args = {};
      if (x != null) args['x'] = x;
      if (y != null) args['y'] = y;
      if (width != null) args['width'] = width;
      if (height != null) args['height'] = height;

      final result = await _channel.invokeMethod('startRecording', args);
      return result == true;
    } catch (e) {
      debugPrint('Error starting native recording: $e');
      return false;
    }
  }

  /// Stop the current recording
  static Future<bool> stopRecording() async {
    try {
      final result = await _channel.invokeMethod('stopRecording');
      return result == true;
    } catch (e) {
      debugPrint('Error stopping native recording: $e');
      return false;
    }
  }

  /// Export the recorded video to a file
  /// 
  /// [outputPath] - The path where the video should be saved
  /// Returns the path to the exported video file or null if export failed
  static Future<String?> exportVideo({required String outputPath}) async {
    try {
      final result = await _channel.invokeMethod('exportVideo', {
        'outputPath': outputPath,
      });
      return result as String?;
    } catch (e) {
      debugPrint('Error exporting native recording: $e');
      return null;
    }
  }

  /// Check if native screen recording is supported on this platform
  static Future<bool> isSupported() async {
    try {
      final result = await _channel.invokeMethod('isSupported');
      return result == true;
    } catch (e) {
      debugPrint('Error checking native recording support: $e');
      return false;
    }
  }

  /// Get the current recording status
  static Future<bool> isRecording() async {
    try {
      final result = await _channel.invokeMethod('isRecording');
      return result == true;
    } catch (e) {
      debugPrint('Error checking recording status: $e');
      return false;
    }
  }
}
