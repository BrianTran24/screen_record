import 'dart:io';
import 'dart:ui' as ui;

import 'package:bitmap/bitmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../screen_record_plus.dart';
import 'native_screen_recorder.dart';

Size globalSize = const Size(0, 0);

/// Recording mode for the screen recorder
enum RecordingMode {
  /// Use Flutter's RepaintBoundary to capture frames
  widget,
  
  /// Use native platform APIs for screen recording
  native,
}

class ScreenRecorderController {
  ScreenRecorderController({
    Exporter? exporter,
    this.pixelRatio = 0.5,
    this.skipFramesBetweenCaptures = 2,
    this.recordingMode = RecordingMode.widget,
    this.recordingRect,
    SchedulerBinding? binding,
  })  : _containerKey = GlobalKey(),
        _binding = binding ?? SchedulerBinding.instance;

  final GlobalKey _containerKey;
  final SchedulerBinding _binding;

  Exporter get exporter => Exporter(skipFramesBetweenCaptures, this);

  /// The recording mode (widget-based or native)
  final RecordingMode recordingMode;

  /// Optional recording area coordinates (for native recording)
  /// If null, records the entire screen/widget
  final Rect? recordingRect;

  /// The pixelRatio describes the scale between the logical pixels and the size
  /// of the output image. Specifying 1.0 will give you a 1:1 mapping between
  /// logical pixels and the output pixels in the image. The default is a pixel
  /// ration of 3 and a value below 1 is not recommended.
  ///
  /// See [RenderRepaintBoundary](https://api.flutter.dev/flutter/rendering/RenderRepaintBoundary/toImage.html)
  /// for the underlying implementation.
  final double pixelRatio;

  /// Describes how many frames are skipped between caputerd frames.
  /// For example if it's `skipFramesBetweenCaptures = 2` screen_recorder
  /// captures a frame, skips the next two frames and then captures the next
  /// frame again.
  final int skipFramesBetweenCaptures;

  int skipped = 0;

  bool _record = false;

  DateTime? startTime;
  DateTime? endTime;

  /// Clear all folder rendering in cache
  /// Reset biến startTime và biến engTime
  /// Gán biến startTime

  Duration? get duration {
    if (startTime == null) {
      throw Exception('Recording has not started yet');
    }
    if (endTime == null) {
      throw Exception('Recording has not stopped yet');
    }

    return endTime!.difference(startTime!);
  }

  int fileIndex = 0;

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
    fileIndex = 1;
    if (_record == true) {
      return;
    }
    _record = true;

    // Use native recording if mode is native
    if (recordingMode == RecordingMode.native) {
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
      return;
    }

    // Widget-based recording
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path;
    Directory renderingDir = Directory(join(path, 'rendering'));
    if (!await renderingDir.exists()) {
      await renderingDir.create();
    }
    await clearRenderingDirectory();

    startTime = DateTime.now();
    _binding.addPostFrameCallback(postFrameCallback);
  }

  void stop() async {
    _record = false;
    endTime = DateTime.now();
    
    // Stop native recording if in native mode
    if (recordingMode == RecordingMode.native) {
      await NativeScreenRecorder.stopRecording();
    }
  }

  void postFrameCallback(Duration timestamp) {
    if (_record == false) {
      return;
    }
    if (skipped > 0) {
      // count down frames which should be skipped
      skipped = skipped - 1;
      // add a new PostFrameCallback to know about the next frame
      _binding.addPostFrameCallback(postFrameCallback);
      // but we do nothing, because we skip this frame
      return;
    }
    if (skipped == 0) {
      // reset skipped frame counter
      skipped = skipped + skipFramesBetweenCaptures;
    }
    try {
      final image = capture();
      if (image == null) {
        debugPrint('capture returned null');
        return;
      }
      _handleSaveImage(image);
    } catch (e) {
      debugPrint('Error while capturing frame: $e $runtimeType');
    }
    _binding.addPostFrameCallback(postFrameCallback);
  }

  ui.Image? capture() {
    final renderObject = _containerKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    return renderObject.toImageSync(pixelRatio: pixelRatio);
  }

  int indexTest = 0;

  Future<bool> _handleSaveImage(ui.Image image) async {
    try {
      globalSize = Size(image.width.toDouble(), image.height.toDouble());
      Bitmap bitmap = await uiImageToBitmap(image);

      File file = await saveBitmapToCache(bitmap, 'rendering', fileIndex++);
      if (file.existsSync()) {
        return true;
      }
    } catch (e) {
      debugPrint('Error while saving image: $e');
    }
    return false;
  }

  Future<File> saveBitmapToCache(Bitmap bitmap, String folderName, int index) async {
    String cacheDir = (await getApplicationDocumentsDirectory()).path;
    String ext = '.bmp';
    String nameWithExtension = 'frame_${generateFormattedString(index)}$ext';
    String fullPath = join(cacheDir, folderName, nameWithExtension);
    File file = File(fullPath);
    file = await file.writeAsBytes(bitmap.buildHeaded());
    return file;
  }

  String generateFormattedString(int number) {
    final formatter = NumberFormat('0000');
    return formatter.format(number);
  }
}

class ScreenRecorder extends StatelessWidget {
  const ScreenRecorder({
    super.key,
    required this.child,
    required this.controller,
    required this.width,
    required this.height,
    this.background = Colors.transparent,
  });

  /// The child which should be recorded.
  final Widget child;

  /// This controller starts and stops the recording.
  final ScreenRecorderController controller;

  /// Width of the recording.
  /// This should not change during recording as it could lead to
  /// undefined behavior.
  final double width;

  /// Height of the recording
  /// This should not change during recording as it could lead to
  /// undefined behavior.
  final double height;

  /// The background color of the recording.
  /// Transparency is currently not supported.
  final Color background;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: controller._containerKey,
      child: Container(
        width: width,
        height: height,
        color: background,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

Future<void> clearRenderingDirectory() async {
  String documentPath = (await getApplicationDocumentsDirectory()).path;
  String path = join(documentPath, 'rendering');
  final directory = Directory(path);
  if (await directory.exists()) {
    final files = directory.listSync();
    for (var file in files) {
      if (file is File) {
        await file.delete();
      }
    }
  }
}

class AppUtil {
  static Future<String> createFolderInAppDocDir(String folderName) async {
    //Get this App Document Directory
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    //App Document Directory + folder name
    final Directory appDocDirFolder = Directory('${appDocDir.path}/$folderName/');

    if (await appDocDirFolder.exists()) {
      //if folder already exists return path
      return appDocDirFolder.path;
    } else {
      //if folder not exists create folder and then return its path
      final Directory appDocDirNewFolder = await appDocDirFolder.create(recursive: true);
      return appDocDirNewFolder.path;
    }
  }
}

/// Chuyển đổi ui.Image thành Bitmap
Future<Bitmap> uiImageToBitmap(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final buffer = byteData!.buffer.asUint8List();
  return Bitmap.fromHeadless(image.width, image.height, buffer);
}
