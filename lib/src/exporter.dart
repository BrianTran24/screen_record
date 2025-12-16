import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Rect;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

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
      onProgress?.call(ExportResult(status: ExportStatus.exporting, percent: 0.3));
      
      String cacheDir = (await getApplicationDocumentsDirectory()).path;
      String outputName = DateTime.now().millisecondsSinceEpoch.toString();
      
      if (!multiCache) {
        outputName = "ScreenRecord";
      }
      
      final Directory cacheFolderDir = Directory(join(cacheDir, cacheFolder));
      if (!cacheFolderDir.existsSync()) {
        cacheFolderDir.createSync();
      }
      
      // Export to temporary location first
      final tempOutputPath = join(cacheDir, 'temp_$outputName.mp4');
      
      final result = await NativeScreenRecorder.exportVideo(outputPath: tempOutputPath);
      
      if (result == null) {
        onProgress?.call(ExportResult(status: ExportStatus.failed, percent: 0));
        return null;
      }
      
      final tempFile = File(result);
      if (!tempFile.existsSync()) {
        onProgress?.call(ExportResult(status: ExportStatus.failed, percent: 0));
        return null;
      }
      
      // Check if we need to crop the video
      final recordingRect = controller.recordingRect;
      File finalFile;
      
      if (recordingRect != null) {
        // Crop the video using FFmpeg
        onProgress?.call(ExportResult(status: ExportStatus.encoding, percent: 0.6));
        
        final finalOutputPath = join(cacheFolderDir.path, '$outputName.mp4');
        final croppedFile = await _cropVideo(
          tempFile,
          finalOutputPath,
          recordingRect,
          onProgress,
        );
        
        if (croppedFile == null) {
          // Cleanup temp file
          if (tempFile.existsSync()) {
            await tempFile.delete();
          }
          onProgress?.call(ExportResult(status: ExportStatus.failed, percent: 0));
          return null;
        }
        
        // Delete temp file
        if (tempFile.existsSync()) {
          await tempFile.delete();
        }
        
        finalFile = croppedFile;
      } else {
        // No cropping needed, just move the file
        final finalOutputPath = join(cacheFolderDir.path, '$outputName.mp4');
        finalFile = await tempFile.copy(finalOutputPath);
        await tempFile.delete();
      }
      
      onProgress?.call(ExportResult(
        status: ExportStatus.exported,
        file: finalFile,
        percent: 1.0,
      ));
      return finalFile;
    } catch (e) {
      debugPrint('Error exporting native recording: $e');
      onProgress?.call(ExportResult(status: ExportStatus.failed, percent: 0));
      return null;
    }
  }
  
  /// Crop video using FFmpeg
  Future<File?> _cropVideo(
    File inputFile,
    String outputPath,
    Rect cropRect,
    ValueChanged<ExportResult>? onProgress,
  ) async {
    try {
      // FFmpeg crop filter: crop=width:height:x:y
      final command = '-i "${inputFile.path}" -filter:v "crop=${cropRect.width.toInt()}:${cropRect.height.toInt()}:${cropRect.left.toInt()}:${cropRect.top.toInt()}" -c:a copy "$outputPath"';
      
      debugPrint('FFmpeg command: $command');
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(outputPath);
        if (outputFile.existsSync()) {
          return outputFile;
        }
      } else {
        final output = await session.getOutput();
        debugPrint('FFmpeg failed with output: $output');
      }
      
      return null;
    } catch (e) {
      debugPrint('Error cropping video: $e');
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
