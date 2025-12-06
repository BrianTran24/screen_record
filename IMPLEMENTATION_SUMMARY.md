# Native Screen Recording Implementation Summary

## Overview
This package provides native screen recording for Flutter using platform-specific APIs (Android MediaProjection and iOS ReplayKit) with coordinate-based region capture support.

## Key Features

### 1. Native Platform Integration
- **Android**: Uses MediaProjection API (Android API 21+)
  - Records screen content using native MediaRecorder
  - Supports H.264 encoding at 30fps
  - Configurable video quality (5 Mbps bitrate)
  
- **iOS**: Uses ReplayKit/RPScreenRecorder (iOS 11.0+)
  - Captures screen content using AVAssetWriter
  - Real-time video encoding
  - Supports standard video formats

### 2. Coordinate-Based Recording
Developers can specify exact screen regions to record:

```dart
final controller = ScreenRecorderController(
  recordingRect: Rect.fromLTWH(x, y, width, height),
);
```

### 3. Simplified API
Clean, straightforward API focused on native recording:
- No widget wrapping required
- No FFmpeg dependency
- Smaller package size (~100MB reduction)
- Better performance

## Architecture

### Flutter Layer
- `NativeScreenRecorder`: Platform channel interface for native operations
- `ScreenRecorderController`: Main controller for recording management
- `Exporter`: Handles video export operations

### Native Layer

#### Android (Kotlin)
- `ScreenRecordPlusPlugin.kt`: Main plugin implementation
- Uses MediaProjection API for screen capture
- Handles permission requests via Activity results
- MediaRecorder for video encoding

#### iOS (Swift)
- `ScreenRecordPlusPlugin.swift`: Main plugin implementation
- Uses RPScreenRecorder for screen capture
- Implements AVAssetWriter for video encoding
- Manages file operations and cleanup

## API Surface

### Main Classes
1. `ScreenRecorderController` - Main controller (simplified from v0.x)
2. `NativeScreenRecorder` - Static class for native recording operations
3. `Exporter` - Video export handler

### Public Methods
- `ScreenRecorderController.start()` - Start recording
- `ScreenRecorderController.stop()` - Stop recording
- `Exporter.exportVideo()` - Export recorded video
- `NativeScreenRecorder.isSupported()` - Check platform support
- `NativeScreenRecorder.isRecording()` - Check recording status

## Platform Requirements

### Android
- Minimum SDK: 21 (Lollipop)
- Required permissions:
  - `RECORD_AUDIO`
  - `WRITE_EXTERNAL_STORAGE` (API ≤ 28)
  - `FOREGROUND_SERVICE`

### iOS
- Minimum version: 11.0
- Required permissions:
  - `NSMicrophoneUsageDescription` (Info.plist)

## Changes from v0.x

### Removed
- Widget-based recording mode
- FFmpeg dependency (ffmpeg_kit_flutter)
- bitmap, image, intl dependencies
- ScreenRecorder widget
- Frame class
- RecordingMode enum
- pixelRatio parameter
- skipFramesBetweenCaptures parameter

### Simplified
- ScreenRecorderController now only takes `recordingRect` parameter
- Exporter only handles native recording export
- Cleaner, more focused API

## Performance Characteristics
- **Lower memory usage**: No frame buffering
- **Better CPU efficiency**: Native encoding
- **Higher quality**: Direct native encoding
- **Smaller package**: No FFmpeg (~100MB savings)

## Technical Details

### Video Output
- **Format**: MP4
- **Codec**: H.264
- **Android**: 30fps, 5 Mbps bitrate
- **iOS**: Adaptive quality based on device

### File Management
- Videos saved to application documents directory
- Configurable cache folders
- Automatic cleanup options

## Migration from v0.x

**Before:**
```dart
final controller = ScreenRecorderController(
  recordingMode: RecordingMode.native,
  pixelRatio: 3.0,
  skipFramesBetweenCaptures: 0,
  recordingRect: Rect.fromLTWH(100, 100, 400, 400),
);
```

**After:**
```dart
final controller = ScreenRecorderController(
  recordingRect: Rect.fromLTWH(100, 100, 400, 400),
);
```

## Security Considerations
1. All file operations use application-scoped directories
2. Temporary files are created in cache directories
3. No sensitive data exposed through the API
4. Proper cleanup of native resources
5. Permission handling follows platform best practices

## Future Enhancements
- Audio recording toggle
- Custom video quality settings
- Multiple region recording
- Real-time preview
- Pause/resume functionality
- Video trimming/editing

## Version History
- v1.0.0: Native-only implementation (breaking changes)
- v0.0.5: Added native recording alongside widget mode
- v0.0.4: Previous version (widget-based only with FFmpeg)
