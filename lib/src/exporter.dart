import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui show ImageByteFormat, Image;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../screen_record_plus.dart';
import 'create_video.dart';
import 'native_screen_recorder.dart';

class Exporter {
  Exporter(this.skipFramesBetweenCaptures, this.controller);

  final int skipFramesBetweenCaptures;
  final ScreenRecorderController controller;
  static final List<Frame> _frames = [];

  static List<Frame> get frames => _frames;

  void onNewFrame(Frame frame) {
    _frames.add(frame);
  }

  void clear() {
    _frames.clear();
  }

  bool get hasFrames => _frames.isNotEmpty;

  Duration? get duration => controller.duration;

  static Future<image.Image> convertUiImageToImage(ui.Image uiImage) async {
    // Convert ui.Image to ByteData
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to convert ui.Image to ByteData');
    }

    // Convert ByteData to Uint8List
    final uint8List = byteData.buffer.asUint8List();

    // Decode Uint8List to image.Image
    final imageTMP = image.decodeImage(uint8List);
    if (imageTMP == null) {
      throw Exception('Failed to decode Uint8List to image.Image');
    }

    return imageTMP;
  }

  /// [multiCache] is used to determine whether to create a new Video file for each recording or not.
  ///
  /// [cacheFolder] is the folder where the cache is stored. Default ScreenRecordVideos
  Future<File?> exportVideo({ValueChanged<ExportResult>? onProgress, double speed = 1, bool multiCache = false, String cacheFolder = "ScreenRecordVideos"}) async {
    if (duration == null) {
      throw Exception('Duration is null');
    }
    
    // Handle native recording export
    if (controller.recordingMode == RecordingMode.native) {
      return await _exportNativeRecording(
        onProgress: onProgress,
        multiCache: multiCache,
        cacheFolder: cacheFolder,
      );
    }
    
    // Handle widget-based recording export
    File? result = await createVideoFromImages(
      duration: duration!,
      onProgress: onProgress,
      speed: speed,
      multiCache: multiCache,
      cacheFolder: cacheFolder,
    );
    clearRenderingDirectory();
    return result;
  }

  /// Export native recording to video file
  Future<File?> _exportNativeRecording({
    ValueChanged<ExportResult>? onProgress,
    bool multiCache = false,
    String cacheFolder = "ScreenRecordVideos",
  }) async {
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

  static image.PaletteUint8 _convertPalette(image.Palette palette) {
    final newPalette = image.PaletteUint8(palette.numColors, 4);
    for (var i = 0; i < palette.numColors; i++) {
      newPalette.setRgba(i, palette.getRed(i), palette.getGreen(i), palette.getBlue(i), 255);
    }
    return newPalette;
  }

  static image.Image encodeGifWIthTransparency(
    image.Image srcImage, {
    int transparencyThreshold = 1,
  }) {
    var format = srcImage.format;
    image.Image image32;
    if (format != image.Format.int8) {
      image32 = srcImage.convert(format: image.Format.uint8);
    } else {
      image32 = srcImage;
    }
    final newImage = image.quantize(image32);

    // GifEncoder will use palette colors with a 0 alpha as transparent. Look at the pixels
    // of the original image and set the alpha of the palette color to 0 if the pixel is below
    // a transparency threshold.
    final numFrames = srcImage.frames.length;
    for (var frameIndex = 0; frameIndex < numFrames; frameIndex++) {
      final srcFrame = srcImage.frames[frameIndex];
      final newFrame = newImage.frames[frameIndex];

      final palette = _convertPalette(newImage.palette!);

      for (final srcPixel in srcFrame) {
        if (srcPixel.a < transparencyThreshold) {
          final newPixel = newFrame.getPixel(srcPixel.x, srcPixel.y);
          palette.setAlpha(newPixel.index.toInt(), 0); // Set the palette color alpha to 0
        }
      }

      newFrame.data!.palette = palette;
    }

    return newImage;
  }
}

class DataFrame {
  final RawFrame frame;
  final image.Image mainImage;
  final int width;
  final int height;

  DataFrame({required this.frame, required this.mainImage, required this.width, required this.height});
}

class RawFrame {
  RawFrame(this.durationInMillis, this.image);

  final int durationInMillis;
  final ByteData image;
}

class DataHolder {
  DataHolder(this.frames, this.width, this.height);

  List<RawFrame> frames;

  int width;
  int height;
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

  //to String
  @override
  String toString() {
    return 'ExportResult(status: $status,  percent: $percent)';
  }
}
