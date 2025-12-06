import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../screen_record_plus.dart';
import 'native_screen_recorder.dart';

class Exporter {
  Exporter(this.controller);

  final ScreenRecorderController controller;

  Duration? get duration => controller.duration;

  /// Export the recorded video
  /// 
  /// [multiCache] is used to determine whether to create a new Video file for each recording or not.
  /// [cacheFolder] is the folder where the cache is stored. Default ScreenRecordVideos
  Future<File?> exportVideo({
    ValueChanged<ExportResult>? onProgress,
    bool multiCache = false,
    String cacheFolder = "ScreenRecordVideos",
  }) async {
    if (duration == null) {
      throw Exception('Duration is null');
    }

    try {
      onProgress?.call(ExportResult(status: ExportStatus.exporting, percent: 0.5));
      
      String cacheDir = (await getApplicationDocumentsDirectory()).path;
      String outputName = DateTime.now().millisecondsSinceEpoch.toString();
      
      if (!multiCache) {
        outputName = "ScreenRecord";
      }
      
      final Directory cacheFolderDir = Directory(join(cacheDir, cacheFolder));
      if (!cacheFolderDir.existsSync()) {
        cacheFolderDir.createSync();
      }
      
      final outputPath = join(cacheFolderDir.path, '$outputName.mp4');
      
      final result = await NativeScreenRecorder.exportVideo(outputPath: outputPath);
      
      if (result != null) {
        final file = File(result);
        onProgress?.call(ExportResult(
          status: ExportStatus.exported,
          file: file,
          percent: 1.0,
        ));
        return file;
      }
      
      onProgress?.call(ExportResult(status: ExportStatus.failed, percent: 0));
      return null;
    } catch (e) {
      debugPrint('Error exporting native recording: $e');
      onProgress?.call(ExportResult(status: ExportStatus.failed, percent: 0));
      return null;
    }
  }
}

enum ExportStatus {
  exporting,
  encoding,
  encoded,
  exported,
  failed,
}

class ExportResult {
  final ExportStatus status;
  final File? file;
  final double? percent;

  ExportResult({required this.status, this.file, this.percent});

  @override
  String toString() {
    return 'ExportResult(status: $status, percent: $percent)';
  }
}
