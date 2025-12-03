# API Documentation - Screen Record Plus

## Table of Contents
- [ScreenRecorderController](#screenrecordercontroller)
- [NativeScreenRecorder](#nativescreenrecorder)
- [ScreenRecorder Widget](#screenrecorder-widget)
- [Exporter](#exporter)
- [Enums](#enums)
- [Data Classes](#data-classes)

---

## ScreenRecorderController

Main controller for managing screen recording operations.

### Constructor

```dart
ScreenRecorderController({
  double pixelRatio = 0.5,
  int skipFramesBetweenCaptures = 2,
  RecordingMode recordingMode = RecordingMode.widget,
  Rect? recordingRect,
  SchedulerBinding? binding,
})
```

#### Parameters
- `pixelRatio` (double): Scale between logical pixels and output image size. Default: 0.5
- `skipFramesBetweenCaptures` (int): Number of frames to skip between captures. Default: 2
- `recordingMode` (RecordingMode): Recording mode (widget or native). Default: RecordingMode.widget
- `recordingRect` (Rect?): Recording area for native mode. If null, records entire screen
- `binding` (SchedulerBinding?): Custom scheduler binding. Default: SchedulerBinding.instance

### Properties

- `exporter` (Exporter): Get the exporter instance for this controller
- `duration` (Duration?): Get the duration of the recording
- `pixelRatio` (double): The pixel ratio for recording
- `skipFramesBetweenCaptures` (int): Frame skip count
- `recordingMode` (RecordingMode): Current recording mode
- `recordingRect` (Rect?): Recording region (native mode only)

### Methods

#### start()
```dart
Future<void> start()
```
Starts the recording. Initializes appropriate recording mechanism based on mode.

**Returns:** Future<void>

**Example:**
```dart
await controller.start();
```

#### stop()
```dart
Future<void> stop()
```
Stops the current recording.

**Returns:** Future<void>

**Example:**
```dart
await controller.stop();
```

#### clearCacheFolder()
```dart
Future<void> clearCacheFolder(String cacheFolder)
```
Clears all files in the specified cache folder.

**Parameters:**
- `cacheFolder` (String): Name of the cache folder to clear

**Returns:** Future<void>

**Example:**
```dart
await controller.clearCacheFolder("my_recordings");
```

---

## NativeScreenRecorder

Static class for native screen recording operations.

### Methods

#### startRecording()
```dart
static Future<bool> startRecording({
  double? x,
  double? y,
  double? width,
  double? height,
})
```
Starts native screen recording with optional coordinates.

**Parameters:**
- `x` (double?): X coordinate of recording area
- `y` (double?): Y coordinate of recording area
- `width` (double?): Width of recording area
- `height` (double?): Height of recording area

**Returns:** Future<bool> - true if recording started successfully

**Example:**
```dart
// Record entire screen
final success = await NativeScreenRecorder.startRecording();

// Record specific region
final success = await NativeScreenRecorder.startRecording(
  x: 100,
  y: 100,
  width: 200,
  height: 200,
);
```

#### stopRecording()
```dart
static Future<bool> stopRecording()
```
Stops the current native recording.

**Returns:** Future<bool> - true if stopped successfully

**Example:**
```dart
final success = await NativeScreenRecorder.stopRecording();
```

#### exportVideo()
```dart
static Future<String?> exportVideo({
  required String outputPath,
})
```
Exports the recorded video to a file.

**Parameters:**
- `outputPath` (String): Path where video should be saved

**Returns:** Future<String?> - Path to exported video or null if failed

**Example:**
```dart
final videoPath = await NativeScreenRecorder.exportVideo(
  outputPath: '/path/to/output.mp4',
);
```

#### isSupported()
```dart
static Future<bool> isSupported()
```
Checks if native screen recording is supported on this platform.

**Returns:** Future<bool> - true if supported

**Example:**
```dart
final supported = await NativeScreenRecorder.isSupported();
if (supported) {
  // Use native recording
}
```

#### isRecording()
```dart
static Future<bool> isRecording()
```
Checks if recording is currently active.

**Returns:** Future<bool> - true if recording

**Example:**
```dart
final recording = await NativeScreenRecorder.isRecording();
```

---

## ScreenRecorder Widget

Widget that wraps content for recording.

### Constructor

```dart
const ScreenRecorder({
  Key? key,
  required Widget child,
  required ScreenRecorderController controller,
  required double width,
  required double height,
  Color background = Colors.transparent,
})
```

#### Parameters
- `child` (Widget): The widget to record
- `controller` (ScreenRecorderController): Controller for recording operations
- `width` (double): Width of the recording area
- `height` (double): Height of the recording area
- `background` (Color): Background color. Default: Colors.transparent

### Example

```dart
ScreenRecorder(
  controller: controller,
  width: 300,
  height: 300,
  background: Colors.white,
  child: MyAnimatedWidget(),
)
```

---

## Exporter

Handles video export operations.

### Methods

#### exportVideo()
```dart
Future<File?> exportVideo({
  ValueChanged<ExportResult>? onProgress,
  double speed = 1,
  bool multiCache = false,
  String cacheFolder = "ScreenRecordVideos",
})
```
Exports the recorded content as a video file.

**Parameters:**
- `onProgress` (ValueChanged<ExportResult>?): Progress callback
- `speed` (double): Video playback speed. Default: 1.0
- `multiCache` (bool): Create unique filename for each export. Default: false
- `cacheFolder` (String): Folder for cached videos. Default: "ScreenRecordVideos"

**Returns:** Future<File?> - Exported video file or null if failed

**Example:**
```dart
final file = await controller.exporter.exportVideo(
  multiCache: true,
  cacheFolder: "my_videos",
  onProgress: (result) {
    print('Progress: ${result.percent}');
  },
);
```

---

## Enums

### RecordingMode

Defines the recording mode.

```dart
enum RecordingMode {
  widget,  // Use Flutter's RepaintBoundary
  native,  // Use native platform APIs
}
```

**Example:**
```dart
final controller = ScreenRecorderController(
  recordingMode: RecordingMode.native,
);
```

### ExportStatus

Status of export operation.

```dart
enum ExportStatus {
  exporting,  // Export in progress
  encoding,   // Encoding video
  encoded,    // Encoding complete
  exported,   // Export complete
  failed,     // Export failed
}
```

---

## Data Classes

### ExportResult

Result of export operation.

#### Properties
- `status` (ExportStatus): Current export status
- `file` (File?): Exported file (when status is exported)
- `percent` (double?): Progress percentage (0.0 to 1.0)

#### Constructor
```dart
ExportResult({
  required ExportStatus status,
  File? file,
  double? percent,
})
```

**Example:**
```dart
ExportResult(
  status: ExportStatus.exported,
  file: myVideoFile,
  percent: 1.0,
)
```

### Frame

Represents a captured frame.

#### Properties
- `timeStamp` (Duration): Time when frame was captured
- `image` (ui.Image): The captured image

#### Constructor
```dart
Frame(Duration timeStamp, ui.Image image)
```

---

## Complete Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:screen_record_plus/screen_record_plus.dart';

class RecordingExample extends StatefulWidget {
  @override
  State<RecordingExample> createState() => _RecordingExampleState();
}

class _RecordingExampleState extends State<RecordingExample> {
  late ScreenRecorderController controller;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    
    // Check native support
    NativeScreenRecorder.isSupported().then((supported) {
      // Initialize controller
      controller = ScreenRecorderController(
        recordingMode: supported ? RecordingMode.native : RecordingMode.widget,
        recordingRect: supported ? Rect.fromLTWH(0, 0, 400, 400) : null,
        pixelRatio: 3.0,
      );
    });
  }

  Future<void> startRecording() async {
    await controller.start();
    setState(() => isRecording = true);
  }

  Future<void> stopAndExport() async {
    await controller.stop();
    setState(() => isRecording = false);
    
    final file = await controller.exporter.exportVideo(
      multiCache: true,
      onProgress: (result) {
        print('Export: ${result.status} - ${result.percent}');
      },
    );
    
    if (file != null) {
      print('Video saved to: ${file.path}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenRecorder(
        controller: controller,
        width: 400,
        height: 400,
        child: MyContent(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isRecording ? stopAndExport : startRecording,
        child: Icon(isRecording ? Icons.stop : Icons.play_arrow),
      ),
    );
  }
}
```

## Platform-Specific Notes

### Android
- Requires user permission for screen recording
- Permission dialog appears on first recording attempt
- Minimum API level: 21 (Android 5.0)

### iOS
- Requires `NSMicrophoneUsageDescription` in Info.plist
- Works on iOS 11.0 and later
- User must grant recording permission

## Best Practices

1. **Always check native support** before using native recording:
   ```dart
   final supported = await NativeScreenRecorder.isSupported();
   ```

2. **Handle errors gracefully**:
   ```dart
   try {
     await controller.start();
   } catch (e) {
     print('Recording failed: $e');
   }
   ```

3. **Clean up resources**:
   ```dart
   await controller.clearCacheFolder("recordings");
   ```

4. **Monitor export progress**:
   ```dart
   await exporter.exportVideo(
     onProgress: (result) {
       // Update UI with progress
     },
   );
   ```
