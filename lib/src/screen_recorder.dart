import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../screen_record_plus.dart';
import 'native_screen_recorder.dart';

class ScreenRecorderController {
  ScreenRecorderController({
    this.recordingRect,
  }){
    print('ScreenRecorderController initialized with recordingRect: $recordingRect');
  }

  /// Optional recording area coordinates
  /// If null, records the entire screen
  final Rect? recordingRect;

  /// Get the screen position and size of a widget using its GlobalKey
  /// 
  /// Returns null if the widget is not currently mounted in the widget tree
  /// 
  /// Example:
  /// ```dart
  /// final key = GlobalKey();
  /// // ... widget with key ...
  /// final rect = ScreenRecorderController.getWidgetRect(key);
  /// if (rect != null) {
  ///   final controller = ScreenRecorderController(recordingRect: rect);
  /// }
  /// ```
  // static Rect? getWidgetRect(GlobalKey key) {
  //   final renderObject = key.currentContext?.findRenderObject();
  //   if (renderObject is RenderBox && renderObject.hasSize) {
  //     final offset = renderObject.localToGlobal(Offset.zero);
  //     final size = renderObject.size;
  //     return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  //   }
  //   return null;
  // }

  // static Rect? getWidgetRect(GlobalKey key) {
  //   final renderObject = key.currentContext?.findRenderObject();
  //   if (renderObject is RenderBox && renderObject.hasSize) {
  //     final bounds = Offset.zero & renderObject.size;
  //     final p1 = renderObject.localToGlobal(bounds.topLeft);
  //     final p2 = renderObject.localToGlobal(bounds.topRight);
  //     final p3 = renderObject.localToGlobal(bounds.bottomLeft);
  //     final p4 = renderObject.localToGlobal(bounds.bottomRight);
  //
  //     final dxs = [p1.dx, p2.dx, p3.dx, p4.dx];
  //     final dys = [p1.dy, p2.dy, p3.dy, p4.dy];
  //
  //     final left = dxs.reduce((a, b) => a < b ? a : b);
  //     final top = dys.reduce((a, b) => a < b ? a : b);
  //     final right = dxs.reduce((a, b) => a > b ? a : b);
  //     final bottom = dys.reduce((a, b) => a > b ? a : b);
  //
  //     return Rect.fromLTRB(left, top, right, bottom);
  //   }
  //   return null;
  // }

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
