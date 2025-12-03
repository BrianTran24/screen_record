# Intro:
Taking inspiration from the [screen_recorder](https://pub.dev/packages/screen_recorder) package, modify the mechanism and address the existing shortcomings

# Features:

- [x] Record screen and export mp4.
- [x] Native screen recording API support (Android & iOS)
- [x] Coordinate-based recording (record specific screen regions)
- [x] Widget-based recording (Flutter RepaintBoundary)
- [x] Video export with customizable settings

![Demo](https://github.com/BrianTran24/screen_record/blob/main/assets/ScreenRecording2024-11-22at17.06.33-ezgif.com-video-to-gif-converter.gif)

# Usage

## Widget-Based Recording (Default)

```dart
// Create a controller
final controller = ScreenRecorderController(
  pixelRatio: 3,
  skipFramesBetweenCaptures: 0,
  recordingMode: RecordingMode.widget, // Default mode
);

// Wrap your widget with ScreenRecorder
ScreenRecorder(
  height: 300,
  width: 300,
  controller: controller,
  child: YourWidget(),
)

// Start recording
await controller.start();

// Stop recording
controller.stop();

// Export video
final file = await controller.exporter.exportVideo(
  multiCache: false,
  cacheFolder: "my_recordings",
);
```

## Native Recording with Coordinates

```dart
// Create a controller with native mode and coordinates
final controller = ScreenRecorderController(
  recordingMode: RecordingMode.native,
  recordingRect: Rect.fromLTWH(100, 100, 200, 200), // x, y, width, height
);

// Start native recording (records the specified region)
await controller.start();

// Stop and export
controller.stop();
final file = await controller.exporter.exportVideo();
```

## Check Native Support

```dart
final isSupported = await NativeScreenRecorder.isSupported();
if (isSupported) {
  // Use native recording
}
```

## Platform-Specific Setup

### Android
Add to your `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### iOS
Add to your `Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for screen recording</string>
```

Minimum iOS version: 11.0

# App Demo:
 Store:
  + Android: https://play.google.com/store/apps/details?id=com.filterchallenge.tiiktock.funnyfilter
  + IOS: https://apps.apple.com/app/id6737876228
