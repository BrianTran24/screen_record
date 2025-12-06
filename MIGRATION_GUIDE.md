# Migration Guide: v0.x to v1.0.0

This guide helps you migrate from screen_record_plus v0.x (dual mode) to v1.0.0 (native-only).

## Overview of Changes

Version 1.0.0 is a **major breaking release** that removes widget-based recording and simplifies the API to focus exclusively on native screen recording.

## What Was Removed

### Dependencies
- ❌ `ffmpeg_kit_flutter: ^6.0.3` - No longer needed
- ❌ `bitmap: ^0.2.0` - Removed
- ❌ `image: ^4.2.0` - Removed
- ❌ `intl: ^0.19.0` - Removed

**Package size reduction: ~100MB**

### Classes & Enums
- ❌ `RecordingMode` enum - Only native mode exists now
- ❌ `Frame` class - No frame capture
- ❌ `ScreenRecorder` widget - No widget wrapping needed
- ❌ Widget-based recording functionality

### Parameters
- ❌ `recordingMode` - Always native now
- ❌ `pixelRatio` - Not applicable for native recording
- ❌ `skipFramesBetweenCaptures` - Not applicable
- ❌ `binding` - Not needed

## Migration Steps

### Step 1: Update Dependencies

**pubspec.yaml**

Before:
```yaml
dependencies:
  screen_record_plus: ^0.0.5
```

After:
```yaml
dependencies:
  screen_record_plus: ^1.0.0
```

Run: `flutter pub upgrade`

### Step 2: Update Controller Initialization

Before (v0.x):
```dart
final controller = ScreenRecorderController(
  recordingMode: RecordingMode.native,
  pixelRatio: 3.0,
  skipFramesBetweenCaptures: 0,
  recordingRect: Rect.fromLTWH(100, 100, 400, 400),
);
```

After (v1.0.0):
```dart
final controller = ScreenRecorderController(
  recordingRect: Rect.fromLTWH(100, 100, 400, 400),
);
```

### Step 3: Remove Widget Wrapper (if using widget mode)

Before (v0.x - widget mode):
```dart
ScreenRecorder(
  controller: controller,
  width: 300,
  height: 300,
  child: MyWidget(),
)
```

After (v1.0.0):
```dart
// No wrapper needed - native recording works system-wide
// Just use your widget directly
MyWidget()
```

### Step 4: Update Recording Logic

The basic recording API remains the same:

```dart
// Start
await controller.start();

// Stop
await controller.stop();

// Export
final file = await controller.exporter.exportVideo();
```

### Step 5: Check Platform Support

It's good practice to check if native recording is supported:

```dart
final isSupported = await NativeScreenRecorder.isSupported();
if (!isSupported) {
  // Show error: Native recording requires Android 21+ or iOS 11.0+
}
```

## Common Migration Scenarios

### Scenario 1: Full Screen Recording

**Before (v0.x):**
```dart
final controller = ScreenRecorderController(
  recordingMode: RecordingMode.native,
);

ScreenRecorder(
  controller: controller,
  width: MediaQuery.of(context).size.width,
  height: MediaQuery.of(context).size.height,
  child: MyApp(),
)
```

**After (v1.0.0):**
```dart
final controller = ScreenRecorderController();
// No widget wrapper needed
```

### Scenario 2: Region Recording

**Before (v0.x):**
```dart
final controller = ScreenRecorderController(
  recordingMode: RecordingMode.native,
  recordingRect: Rect.fromLTWH(0, 0, 400, 400),
);
```

**After (v1.0.0):**
```dart
final controller = ScreenRecorderController(
  recordingRect: Rect.fromLTWH(0, 0, 400, 400),
);
```

### Scenario 3: Export with Progress

**Before (v0.x):**
```dart
await controller.exporter.exportVideo(
  multiCache: true,
  cacheFolder: "recordings",
  onProgress: (result) {
    print('${result.percent}');
  },
);
```

**After (v1.0.0):**
```dart
// Same API!
await controller.exporter.exportVideo(
  multiCache: true,
  cacheFolder: "recordings",
  onProgress: (result) {
    print('${result.percent}');
  },
);
```

## If You Were Using Widget Mode

If you were using widget-based recording (`RecordingMode.widget`), you have two options:

### Option 1: Stay on v0.x
If widget-based recording is critical for your use case, stay on v0.0.5:

```yaml
dependencies:
  screen_record_plus: 0.0.5
```

### Option 2: Migrate to Native
Understand the differences:

| Feature | Widget Mode (v0.x) | Native Mode (v1.0.0) |
|---------|-------------------|---------------------|
| Platform Support | All platforms | Android 21+, iOS 11.0+ |
| Recording Scope | Specific widget | Full screen or region |
| Quality | Good | Better |
| Performance | Moderate | Better |
| Package Size | Large (~100MB FFmpeg) | Small |

## Breaking Changes Checklist

- [ ] Remove `recordingMode` parameter
- [ ] Remove `pixelRatio` parameter
- [ ] Remove `skipFramesBetweenCaptures` parameter
- [ ] Remove `ScreenRecorder` widget wrapper
- [ ] Update controller initialization
- [ ] Ensure Android 21+ and iOS 11.0+ minimum versions
- [ ] Test on both platforms

## Platform Requirements

### Android
- Minimum SDK: 21 (was compatible with lower in widget mode)
- Add permissions to AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### iOS
- Minimum version: 11.0 (was compatible with lower in widget mode)
- Add to Info.plist:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for screen recording</string>
```

## Troubleshooting

### Issue: "Native recording is not supported"
**Solution:** Check minimum platform versions (Android 21+, iOS 11.0+)

### Issue: Missing dependencies error
**Solution:** Run `flutter pub get` or `flutter clean && flutter pub get`

### Issue: Recording doesn't start
**Solution:** Ensure permissions are added to AndroidManifest.xml and Info.plist

### Issue: App crashes on start
**Solution:** Clean build: `flutter clean && flutter pub get && flutter run`

## Need Help?

- Check the [API Documentation](API_DOCUMENTATION.md)
- See [Examples](example/)
- Open an issue on [GitHub](https://github.com/BrianTran24/screen_record/issues)

## Benefits of v1.0.0

✅ **Smaller package** - ~100MB reduction  
✅ **Better performance** - Native encoding  
✅ **Simpler API** - Less configuration  
✅ **Higher quality** - Direct platform APIs  
✅ **Easier maintenance** - Focused codebase  
