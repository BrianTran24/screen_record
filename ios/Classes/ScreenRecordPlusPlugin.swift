import Flutter
import UIKit
import ReplayKit
import AVFoundation

public class ScreenRecordPlusPlugin: NSObject, FlutterPlugin, RPPreviewViewControllerDelegate {
    
    private var isRecording = false
    private var videoOutputURL: URL?
    private var videoWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var screenRecorder = RPScreenRecorder.shared()
    
    private var recordingX: CGFloat = 0
    private var recordingY: CGFloat = 0
    private var recordingWidth: CGFloat = 0
    private var recordingHeight: CGFloat = 0
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "screen_record_plus", binaryMessenger: registrar.messenger())
        let instance = ScreenRecordPlusPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRecording":
            let args = call.arguments as? [String: Any]
            let x = args?["x"] as? Double ?? 0
            let y = args?["y"] as? Double ?? 0
            let width = args?["width"] as? Double
            let height = args?["height"] as? Double
            
            startRecording(x: x, y: y, width: width, height: height, result: result)
            
        case "stopRecording":
            stopRecording(result: result)
            
        case "exportVideo":
            let args = call.arguments as? [String: Any]
            let outputPath = args?["outputPath"] as? String
            exportVideo(outputPath: outputPath, result: result)
            
        case "isSupported":
            if #available(iOS 11.0, *) {
                result(true)
            } else {
                result(false)
            }
            
        case "isRecording":
            result(isRecording)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startRecording(x: Double, y: Double, width: Double?, height: Double?, result: @escaping FlutterResult) {
        if isRecording {
            result(false)
            return
        }
        
        guard #available(iOS 11.0, *) else {
            result(FlutterError(code: "UNSUPPORTED", message: "iOS 11.0 or later required", details: nil))
            return
        }
        
        guard screenRecorder.isAvailable else {
            result(FlutterError(code: "UNAVAILABLE", message: "Screen recording is not available", details: nil))
            return
        }
        
        // Store coordinates
        recordingX = CGFloat(x)
        recordingY = CGFloat(y)
        
        let screenSize = UIScreen.main.bounds.size
        recordingWidth = width != nil ? CGFloat(width!) : screenSize.width
        recordingHeight = height != nil ? CGFloat(height!) : screenSize.height
        
        // Setup video writer
        setupVideoWriter()
        
        screenRecorder.startCapture(handler: { [weak self] (sampleBuffer, bufferType, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error during capture: \(error.localizedDescription)")
                return
            }
            
            if CMSampleBufferDataIsReady(sampleBuffer) {
                if bufferType == .video {
                    self.appendSampleBuffer(sampleBuffer)
                }
            }
        }) { [weak self] error in
            if let error = error {
                result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
            } else {
                self?.isRecording = true
                result(true)
            }
        }
    }
    
    private func setupVideoWriter() {
        let outputFileName = "screen_record_\(Date().timeIntervalSince1970).mp4"
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let outputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent(outputFileName)
        
        videoOutputURL = outputURL
        
        do {
            videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(recordingWidth),
                AVVideoHeightKey: Int(recordingHeight)
            ]
            
            videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoWriterInput?.expectsMediaDataInRealTime = true
            
            if let input = videoWriterInput, videoWriter?.canAdd(input) == true {
                videoWriter?.add(input)
            }
            
            videoWriter?.startWriting()
            videoWriter?.startSession(atSourceTime: .zero)
        } catch {
            print("Error setting up video writer: \(error.localizedDescription)")
        }
    }
    
    private func appendSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let input = videoWriterInput, input.isReadyForMoreMediaData else {
            return
        }
        
        input.append(sampleBuffer)
    }
    
    private func stopRecording(result: @escaping FlutterResult) {
        if !isRecording {
            result(false)
            return
        }
        
        guard #available(iOS 11.0, *) else {
            result(FlutterError(code: "UNSUPPORTED", message: "iOS 11.0 or later required", details: nil))
            return
        }
        
        screenRecorder.stopCapture { [weak self] error in
            guard let self = self else { return }
            
            self.videoWriterInput?.markAsFinished()
            self.videoWriter?.finishWriting {
                self.isRecording = false
                
                if let error = error {
                    result(FlutterError(code: "STOP_FAILED", message: error.localizedDescription, details: nil))
                } else {
                    result(true)
                }
            }
        }
    }
    
    private func exportVideo(outputPath: String?, result: @escaping FlutterResult) {
        guard let outputPath = outputPath else {
            result(FlutterError(code: "INVALID_PATH", message: "Output path is null", details: nil))
            return
        }
        
        guard let sourceURL = videoOutputURL else {
            result(FlutterError(code: "NO_RECORDING", message: "No recording to export", details: nil))
            return
        }
        
        let destURL = URL(fileURLWithPath: outputPath)
        
        do {
            let fileManager = FileManager.default
            
            // Remove existing file if it exists
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            
            // Copy the file
            try fileManager.copyItem(at: sourceURL, to: destURL)
            result(outputPath)
        } catch {
            result(FlutterError(code: "EXPORT_FAILED", message: error.localizedDescription, details: nil))
        }
    }
}
