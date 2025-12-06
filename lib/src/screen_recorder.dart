import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../screen_record_plus.dart';
import 'native_screen_recorder.dart';

class ScreenRecorderController {
  ScreenRecorderController({
    this.recordingRect,
  });

  /// Optional recording area coordinates
  /// If null, records the entire screen
  final Rect? recordingRect;

  bool _record = false;

  DateTime? startTime;
  DateTime? endTime;

  Exporter get exporter => Exporter(this);

  Duration? get duration {
    if (startTime == null) {
      throw Exception('Recording has not started yet');
    }
    if (endTime == null) {
      throw Exception('Recording has not stopped yet');
    }

    return endTime!.difference(startTime!);
  }

  Future<void> clearCacheFolder(String cacheFolder) async {
    String cacheDir = (await getApplicationDocumentsDirectory()).path;
    String fullPath = join(cacheDir, cacheFolder);
    Directory directory = Directory(fullPath);
    if (await directory.exists()) {
      final files = directory.listSync();
      for (var file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    }
  }

  Future<void> start() async {
    endTime = null;
    if (_record == true) {
      return;
    }
    _record = true;

    final success = await NativeScreenRecorder.startRecording(
      x: recordingRect?.left,
      y: recordingRect?.top,
      width: recordingRect?.width,
      height: recordingRect?.height,
    );
    if (!success) {
      debugPrint('Failed to start native recording');
      _record = false;
      return;
    }
    startTime = DateTime.now();
  }

  Future<void> stop() async {
    _record = false;
    endTime = DateTime.now();
    await NativeScreenRecorder.stopRecording();
  }
}
