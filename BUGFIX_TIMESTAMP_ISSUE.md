# iOS Video Duration Bug Fix (v1.0.1)

## Problem Description

Users reported that screen recordings lasting only a few seconds were being exported as videos with durations of 35+ minutes on iOS devices.

### Vietnamese Issue Report
> "Mình record chỉ có vài giây, nhưng nó lại export ra hơn 35 phut là sao nhỉ"
> 
> Translation: "I only recorded for a few seconds, but it exported to over 35 minutes. What's going on?"

## Root Cause

The issue was in the iOS implementation (`ScreenRecordPlusPlugin.swift`) where the `AVAssetWriter` session was being started with a fixed timestamp of `.zero`:

```swift
// OLD CODE (BUGGY)
videoWriter?.startSession(atSourceTime: .zero)
```

### Why This Caused the Problem

1. **ReplayKit Sample Buffers**: When iOS's ReplayKit (`RPScreenRecorder`) captures video frames, each sample buffer includes a presentation timestamp (`CMTime`)
2. **System Uptime Timestamps**: These timestamps are based on system uptime, not starting from zero. For example, if the device has been running for 2000 seconds, the first sample buffer might have a timestamp of ~2000 seconds
3. **Incorrect Duration Calculation**: When `AVAssetWriter` starts at `.zero` but receives samples at timestamp ~2000 seconds:
   - First frame: 2000 seconds into the video
   - Last frame: 2003 seconds into the video (for a 3-second recording)
   - **Result**: Video duration calculated as 2003 seconds (~33 minutes) instead of 3 seconds

## Solution

The fix delays starting the `AVAssetWriter` session until the first video sample buffer arrives, then uses that buffer's timestamp as the starting point:

```swift
// NEW CODE (FIXED)
private func appendSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
    guard let input = videoWriterInput, input.isReadyForMoreMediaData else {
        return
    }
    
    // Start session with the first sample buffer's timestamp
    if !sessionStarted {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        videoWriter?.startSession(atSourceTime: timestamp)
        sessionStarted = true
    }
    
    input.append(sampleBuffer)
}
```

### How This Fixes the Issue

1. **Wait for First Sample**: Don't start the session in `setupVideoWriter()`
2. **Use Actual Timestamp**: When the first sample buffer arrives, extract its presentation timestamp
3. **Start at Correct Time**: Start the `AVAssetWriter` session at this timestamp
4. **Accurate Duration**: The video duration is now calculated correctly:
   - First frame: 0 seconds (relative to session start at timestamp 2000)
   - Last frame: 3 seconds (for a 3-second recording)
   - **Result**: Video duration is 3 seconds ✓

## Implementation Details

### Changes Made

1. **Added `sessionStarted` flag**: Tracks whether the session has been initialized
2. **Modified `setupVideoWriter()`**: Removed `startSession(atSourceTime: .zero)`, added `sessionStarted = false`
3. **Modified `appendSampleBuffer()`**: Added logic to start session with first buffer's timestamp
4. **Modified `stopRecording()`**: Reset `sessionStarted = false` for next recording

### Files Modified

- `ios/Classes/ScreenRecordPlusPlugin.swift`
- `CHANGELOG.md`
- `pubspec.yaml` (version bump to 1.0.1)

## Android Implementation

The Android implementation was **not affected** by this issue because:

1. Android uses `MediaRecorder` API, which handles timestamp management internally
2. `MediaRecorder` automatically manages frame timestamps and duration calculation
3. No manual timestamp configuration is required

## Testing Recommendations

To verify this fix works correctly:

1. **Short Recording Test**: Record for 3-5 seconds and verify exported video is 3-5 seconds long
2. **Medium Recording Test**: Record for 30 seconds and verify duration matches
3. **Multiple Sessions**: Record multiple times to ensure `sessionStarted` flag resets properly
4. **Device Uptime Test**: Test on devices with long uptime (hours/days) to ensure fix works with large timestamp values

## Technical References

- [AVAssetWriter Documentation](https://developer.apple.com/documentation/avfoundation/avassetwriter)
- [CMTime and Timestamps](https://developer.apple.com/documentation/coremedia/cmtime)
- [ReplayKit Sample Buffers](https://developer.apple.com/documentation/replaykit/rpscreenrecorder)
