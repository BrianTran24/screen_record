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
        onProgress?.call(ExportResult(status: ExportStatus.cropping, percent: 0.6));
        
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
      onProgress?.call(ExportResult(status: ExportStatus.cropping, percent: 0.7));
      
      // Validate and build FFmpeg crop filter parameters
      // Ensure dimensions are positive and reasonable
      final cropWidth = cropRect.width.toInt().clamp(1, 7680); // Max 8K width
      final cropHeight = cropRect.height.toInt().clamp(1, 4320); // Max 8K height
      final cropX = cropRect.left.toInt().clamp(0, 7680);
      final cropY = cropRect.top.toInt().clamp(0, 4320);
      
      if (cropWidth <= 0 || cropHeight <= 0) {
        debugPrint('Invalid crop dimensions: ${cropWidth}x$cropHeight');
        return null;
      }
      
      // FFmpeg crop filter: crop=width:height:x:y
      final cropFilter = 'crop=$cropWidth:$cropHeight:$cropX:$cropY';
      
      // Use executeWithArguments for better security (prevents command injection)
      // -y flag overwrites output file if it exists
      final arguments = [
        '-i', inputFile.path,
        '-filter:v', cropFilter,
        '-c:a', 'copy',
        '-y', // Overwrite output file without asking
        outputPath,
      ];
      
      debugPrint('FFmpeg crop filter: $cropFilter');
      
      final session = await FFmpegKit.executeWithArguments(arguments);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        onProgress?.call(ExportResult(status: ExportStatus.encoded, percent: 0.9));
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
  cropping,
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
