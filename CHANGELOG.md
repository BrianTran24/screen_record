## 1.0.0 - BREAKING CHANGES

**Major refactoring to native-only implementation**

### Breaking Changes
* **REMOVED**: Widget-based recording mode (RecordingMode.widget)
* **REMOVED**: ScreenRecorder widget (RepaintBoundary-based recording)
* **REMOVED**: FFmpeg dependency (ffmpeg_kit_flutter)
* **REMOVED**: Dependencies: bitmap, image, intl
* **REMOVED**: `pixelRatio` parameter from ScreenRecorderController
* **REMOVED**: `skipFramesBetweenCaptures` parameter from ScreenRecorderController
* **REMOVED**: `recordingMode` parameter from ScreenRecorderController
* **REMOVED**: RecordingMode enum
* **REMOVED**: Frame class
* **REMOVED**: Widget-based frame capture functionality

### What's Changed
* Simplified API - only native screen recording is now supported
* Reduced package size by removing FFmpeg (~100MB reduction)
* Better performance using native platform APIs
* Cleaner, more maintainable codebase

### Migration Guide
Before (v0.x):
```dart
final controller = ScreenRecorderController(
  recordingMode: RecordingMode.native,  // No longer needed
  pixelRatio: 3.0,                       // Removed
  skipFramesBetweenCaptures: 0,          // Removed
  recordingRect: Rect.fromLTWH(100, 100, 400, 400),
);
```

After (v1.0.0):
```dart
final controller = ScreenRecorderController(
  recordingRect: Rect.fromLTWH(100, 100, 400, 400),  // Only parameter
);
```

### Requirements
* Android: Minimum API 21 (Lollipop)
* iOS: Minimum iOS 11.0

---

## 0.0.5
* Add native screen recording API support for Android and iOS
* Add coordinate-based recording to capture specific screen regions
* Add RecordingMode enum (widget vs native)
* Add NativeScreenRecorder class for platform-specific recording
* Update ScreenRecorderController with recordingRect parameter
* Enhanced video export functionality for native recordings
* Update example app to demonstrate native recording with coordinates
* Update README with comprehensive usage documentation

## 0.0.4
* Update repository

## 0.0.3
* Update repository

## 0.0.2
* Update example and README.md

## 0.0.1
* Init project with basic structure
* Basic widget-based screen recording with FFmpeg
