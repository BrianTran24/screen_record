# Screen Record Plus

Native screen recording library for Flutter using platform-specific APIs (Android MediaProjection and iOS ReplayKit) with FFmpeg-powered region cropping.

## Features

- ✅ Native screen recording (Android & iOS)
- ✅ Region-specific recording with automatic video cropping
- ✅ Widget-based recording using GlobalKey
- ✅ Video export with customizable settings
- ✅ High-quality MP4 output with H.264 encoding

![Demo](https://github.com/BrianTran24/screen_record/blob/main/assets/ScreenRecording2024-11-22at17.06.33-ezgif.com-video-to-gif-converter.gif)

## Platform Support

| Platform | Minimum Version | API Used |
|----------|----------------|----------|
| Android | API 21 (Lollipop) | MediaProjection + MediaRecorder |
| iOS | 11.0 | ReplayKit (RPScreenRecorder) |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  screen_record_plus: ^1.0.0
```

## Usage

### Basic Recording

```dart
import 'package:screen_record_plus/screen_record_plus.dart';

// Create controller
final controller = ScreenRecorderController();

// Start recording (full screen)
await controller.start();

// Stop recording
await controller.stop();

// Export video
final file = await controller.exporter.exportVideo(
  multiCache: true,
  cacheFolder: "my_recordings",
);

print('Video saved to: ${file?.path}');
```

### Recording with Coordinates

Capture a specific region of the screen. The full screen is recorded, then the video is automatically cropped to the specified region during export:

```dart
// Record a 400x400 region starting at position (100, 100)
final controller = ScreenRecorderController(
  recordingRect: Rect.fromLTWH(100, 100, 400, 400),
);

await controller.start();
// ... recording ...
await controller.stop();
final file = await controller.exporter.exportVideo(); // Automatically cropped
```

**How it works**: The native APIs record the full screen, then FFmpeg crops the video to your specified region during export. This ensures you only get the part of the screen you want.

### Recording a Specific Widget

Easily record a specific widget using GlobalKey:

```dart
// Create a GlobalKey and attach it to your widget
final key = GlobalKey();

Widget build(BuildContext context) {
  return Container(
    key: key,
    child: YourWidget(),
  );
}

// Get the widget's position and size
final rect = ScreenRecorderController.getWidgetRect(key);
if (rect != null) {
  final controller = ScreenRecorderController(recordingRect: rect);
  await controller.start();
  // ... recording ...
  await controller.stop();
  final file = await controller.exporter.exportVideo();
}
```

### Check Platform Support

```dart
final isSupported = await NativeScreenRecorder.isSupported();
if (isSupported) {
  // Start recording
}
```

### Export with Progress Callback

```dart
await controller.exporter.exportVideo(
  multiCache: false,
  cacheFolder: "recordings",
  onProgress: (result) {
    print('Status: ${result.status}, Progress: ${result.percent}');
  },
);
```

## Platform-Specific Setup

### Android

Add permissions to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

**Note:** User will be prompted for screen recording permission on first use.

### iOS

Add to your `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for screen recording</string>
```

**Minimum iOS version:** 11.0

## API Reference

### ScreenRecorderController

Main controller for screen recording.

```dart
ScreenRecorderController({
  Rect? recordingRect,  // Optional: specify recording region
})
```

**Methods:**
- `Future<void> start()` - Start recording
- `Future<void> stop()` - Stop recording
- `Future<void> clearCacheFolder(String cacheFolder)` - Clear cached files
- `Exporter get exporter` - Get exporter instance
- `Duration? get duration` - Get recording duration

### Exporter

Handles video export operations.

**Methods:**
- `Future<File?> exportVideo({...})` - Export recorded video

Parameters:
- `ValueChanged<ExportResult>? onProgress` - Progress callback
- `bool multiCache` - Create unique filename for each export (default: false)
- `String cacheFolder` - Cache folder name (default: "ScreenRecordVideos")

### NativeScreenRecorder

Static class for native platform operations.

**Methods:**
- `static Future<bool> startRecording({double? x, y, width, height})` - Start native recording
- `static Future<bool> stopRecording()` - Stop recording
- `static Future<String?> exportVideo({required String outputPath})` - Export video
- `static Future<bool> isSupported()` - Check if native recording is supported
- `static Future<bool> isRecording()` - Check if currently recording

## Example

See the [example](example) folder for a complete working example.

## Technical Details

### Recording Process
1. **Capture**: Native APIs (MediaProjection/ReplayKit) record the full screen
2. **Export**: Video is exported to temporary location
3. **Crop**: If `recordingRect` is specified, FFmpeg crops the video to that region
4. **Output**: Final cropped video is saved to cache folder

### Android Implementation
- Uses **MediaProjection API** for screen capture
- **MediaRecorder** for video encoding
- H.264 codec at 30fps, 5 Mbps bitrate
- Outputs MP4 format

### iOS Implementation
- Uses **ReplayKit** (RPScreenRecorder) for screen capture
- **AVAssetWriter** for video encoding
- H.264 codec with configurable quality
- Outputs MP4 format

### Video Cropping
- Uses **FFmpeg** for post-recording video cropping
- Cropping happens automatically during export when `recordingRect` is specified
- No quality loss during cropping (uses stream copy for audio)
- Note: Package size increases by ~100MB due to FFmpeg inclusion

## Migration from v0.x

Version 1.0.0 removed widget-based recording mode. Version 1.1.0 re-adds FFmpeg for video cropping functionality. If you were using:

**Before (v0.x):**
```dart
ScreenRecorderController(
  recordingMode: RecordingMode.widget,  // Removed
  pixelRatio: 3.0,                      // Removed
  skipFramesBetweenCaptures: 2,         // Removed
)
```

**After (v1.0.0):**
```dart
ScreenRecorderController(
  recordingRect: Rect.fromLTWH(0, 0, 400, 400),  // Optional
)
```

The ScreenRecorder widget is no longer needed. All recording is now done using native platform APIs.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

See [LICENSE](LICENSE) file for details.

## App Demo

 Store:
  + Android: https://play.google.com/store/apps/details?id=com.filterchallenge.tiiktock.funnyfilter
  + iOS: https://apps.apple.com/app/id6737876228
