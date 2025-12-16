## 1.1.0

### Features
* **Video Cropping**: Implemented FFmpeg-based video cropping for region-specific recording
  * Re-added `ffmpeg_kit_flutter` dependency for post-processing
  * Videos are now automatically cropped to `recordingRect` after recording
  * Full screen is recorded, then cropped to specified region during export
* **Widget-based Recording**: Added `ScreenRecorderController.getWidgetRect()` helper method to easily record specific widgets
  * Use `GlobalKey` to get widget position and size on screen
  * Automatically converts widget boundaries to recording coordinates
  * See new `WidgetRecordingExample` in example app
* **Documentation**: Updated README and API documentation with widget recording examples
* **Example**: Added new widget recording example demonstrating how to capture specific UI components

### Technical Details
* Recording workflow: Record full screen → Export → Crop to region (if specified) → Return cropped video
* FFmpeg is used only for post-processing (cropping), not for recording
* Package size will increase due to FFmpeg dependency (~100MB)

## 1.0.2

### Features
* **Widget-based Recording**: Added `ScreenRecorderController.getWidgetRect()` helper method to easily record specific widgets
  * Use `GlobalKey` to get widget position and size on screen
  * Automatically converts widget boundaries to recording coordinates
  * See new `WidgetRecordingExample` in example app
* **Documentation**: Updated README and API documentation with widget recording examples
* **Example**: Added new widget recording example demonstrating how to capture specific UI components

## 1.0.1

### Bug Fixes
* **iOS**: Fixed video duration issue where recordings of a few seconds were exported as 35+ minute videos
  * Root cause: AVAssetWriter was starting session at `.zero` timestamp, but ReplayKit sample buffers use system uptime timestamps
  * Solution: Now starts the session using the timestamp from the first sample buffer for accurate duration calculation
  * This fix only affects iOS; Android implementation was not affected

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
