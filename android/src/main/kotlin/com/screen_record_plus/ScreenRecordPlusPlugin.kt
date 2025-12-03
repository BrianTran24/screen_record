package com.screen_record_plus

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.util.DisplayMetrics
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.IOException

class ScreenRecordPlusPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, 
    PluginRegistry.ActivityResultListener {
    
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null
    
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var mediaRecorder: MediaRecorder? = null
    private var mediaProjectionManager: MediaProjectionManager? = null
    
    private var isRecording = false
    private var videoOutputPath: String? = null
    
    private var recordingX: Int = 0
    private var recordingY: Int = 0
    private var recordingWidth: Int = 0
    private var recordingHeight: Int = 0
    
    private var pendingResult: Result? = null
    
    companion object {
        private const val TAG = "ScreenRecordPlus"
        private const val SCREEN_RECORD_REQUEST_CODE = 1001
    }
    
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "screen_record_plus")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }
    
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
    
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        mediaProjectionManager = activity?.getSystemService(Context.MEDIA_PROJECTION_SERVICE) 
            as? MediaProjectionManager
    }
    
    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }
    
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }
    
    override fun onDetachedFromActivity() {
        activity = null
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startRecording" -> {
                val x = call.argument<Double>("x")?.toInt() ?: 0
                val y = call.argument<Double>("y")?.toInt() ?: 0
                val width = call.argument<Double>("width")?.toInt()
                val height = call.argument<Double>("height")?.toInt()
                
                startRecording(x, y, width, height, result)
            }
            "stopRecording" -> {
                stopRecording(result)
            }
            "exportVideo" -> {
                val outputPath = call.argument<String>("outputPath")
                exportVideo(outputPath, result)
            }
            "isSupported" -> {
                result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP)
            }
            "isRecording" -> {
                result.success(isRecording)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun startRecording(x: Int, y: Int, width: Int?, height: Int?, result: Result) {
        if (isRecording) {
            result.success(false)
            return
        }
        
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity is null", null)
            return
        }
        
        val projectionManager = mediaProjectionManager
        if (projectionManager == null) {
            result.error("NO_PROJECTION_MANAGER", "MediaProjectionManager is null", null)
            return
        }
        
        // Store coordinates
        recordingX = x
        recordingY = y
        
        val metrics = DisplayMetrics()
        currentActivity.windowManager.defaultDisplay.getMetrics(metrics)
        recordingWidth = width ?: metrics.widthPixels
        recordingHeight = height ?: metrics.heightPixels
        
        pendingResult = result
        
        // Request screen capture permission
        val captureIntent = projectionManager.createScreenCaptureIntent()
        currentActivity.startActivityForResult(captureIntent, SCREEN_RECORD_REQUEST_CODE)
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == SCREEN_RECORD_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                setupMediaRecorder()
                
                mediaProjection = mediaProjectionManager?.getMediaProjection(resultCode, data)
                virtualDisplay = createVirtualDisplay()
                
                try {
                    mediaRecorder?.start()
                    isRecording = true
                    pendingResult?.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Error starting media recorder", e)
                    pendingResult?.error("START_FAILED", e.message, null)
                }
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
            return true
        }
        return false
    }
    
    private fun setupMediaRecorder() {
        val ctx = context ?: return
        
        // Create temporary output file
        val outputDir = ctx.cacheDir
        val outputFile = File.createTempFile("screen_record_", ".mp4", outputDir)
        videoOutputPath = outputFile.absolutePath
        
        mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(ctx)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }
        
        mediaRecorder?.apply {
            setVideoSource(MediaRecorder.VideoSource.SURFACE)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setOutputFile(videoOutputPath)
            setVideoSize(recordingWidth, recordingHeight)
            setVideoEncoder(MediaRecorder.VideoEncoder.H264)
            setVideoEncodingBitRate(5 * 1024 * 1024) // 5 Mbps
            setVideoFrameRate(30)
            
            try {
                prepare()
            } catch (e: IOException) {
                Log.e(TAG, "Error preparing MediaRecorder", e)
            }
        }
    }
    
    private fun createVirtualDisplay(): VirtualDisplay? {
        return mediaProjection?.createVirtualDisplay(
            "ScreenRecordDisplay",
            recordingWidth,
            recordingHeight,
            DisplayMetrics.DENSITY_DEFAULT,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            mediaRecorder?.surface,
            null,
            null
        )
    }
    
    private fun stopRecording(result: Result) {
        if (!isRecording) {
            result.success(false)
            return
        }
        
        try {
            mediaRecorder?.stop()
            mediaRecorder?.reset()
            isRecording = false
            
            virtualDisplay?.release()
            mediaProjection?.stop()
            
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping recording", e)
            result.error("STOP_FAILED", e.message, null)
        }
    }
    
    private fun exportVideo(outputPath: String?, result: Result) {
        if (outputPath == null) {
            result.error("INVALID_PATH", "Output path is null", null)
            return
        }
        
        val recordedFile = videoOutputPath
        if (recordedFile == null) {
            result.error("NO_RECORDING", "No recording to export", null)
            return
        }
        
        try {
            val sourceFile = File(recordedFile)
            val destFile = File(outputPath)
            
            if (sourceFile.exists()) {
                sourceFile.copyTo(destFile, overwrite = true)
                result.success(outputPath)
            } else {
                result.error("FILE_NOT_FOUND", "Recorded file not found", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error exporting video", e)
            result.error("EXPORT_FAILED", e.message, null)
        }
    }
}
