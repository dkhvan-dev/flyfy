import AVFoundation
import Flutter
import MobileCoreServices
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "flyfy/clipboard_media",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "readImage":
        result(Self.readImageFromPasteboard())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let videoToolsChannel = FlutterMethodChannel(
      name: "flyfy/video_tools",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    videoToolsChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "trimVideo":
        Self.trimVideo(call.arguments, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func trimVideo(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any],
          let inputPath = args["inputPath"] as? String,
          let startMs = int64Value(args["startMs"]),
          let endMs = int64Value(args["endMs"]),
          !inputPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          endMs > startMs else {
      result(FlutterError(
        code: "invalid_arguments",
        message: "Invalid video trim arguments",
        details: nil
      ))
      return
    }

    let inputURL = URL(fileURLWithPath: inputPath)
    guard FileManager.default.fileExists(atPath: inputURL.path) else {
      result(FlutterError(
        code: "invalid_arguments",
        message: "Input video does not exist",
        details: nil
      ))
      return
    }

    let asset = AVURLAsset(url: inputURL)
    guard let sourceTimeRange = clampedTrimTimeRange(
      asset: asset,
      startMs: startMs,
      endMs: endMs
    ) else {
      result(FlutterError(
        code: "trim_failed",
        message: "Video trim range is outside the asset duration",
        details: nil
      ))
      return
    }

    let compositionTimeRange = CMTimeRange(start: .zero, duration: sourceTimeRange.duration)
    let composition: AVMutableComposition
    do {
      composition = try trimmedComposition(asset: asset, sourceTimeRange: sourceTimeRange)
    } catch {
      result(FlutterError(
        code: "trim_failed",
        message: error.localizedDescription,
        details: nil
      ))
      return
    }

    exportTrimmedComposition(
      composition,
      compositionTimeRange: compositionTimeRange,
      result: result
    )
  }

  private static func exportTrimmedComposition(
    _ composition: AVMutableComposition,
    compositionTimeRange: CMTimeRange,
    presetNames: [String] = [
      AVAssetExportPresetPassthrough,
      AVAssetExportPresetHighestQuality
    ],
    presetIndex: Int = 0,
    result: @escaping FlutterResult
  ) {
    guard presetIndex < presetNames.count else {
      result(FlutterError(
        code: "trim_failed",
        message: "Video export session could not be created",
        details: nil
      ))
      return
    }

    guard let exporter = AVAssetExportSession(
      asset: composition,
      presetName: presetNames[presetIndex]
    ) else {
      exportTrimmedComposition(
        composition,
        compositionTimeRange: compositionTimeRange,
        presetNames: presetNames,
        presetIndex: presetIndex + 1,
        result: result
      )
      return
    }

    guard let preferredOutputFileType = preferredVideoOutputFileType(exporter.supportedFileTypes) else {
      result(FlutterError(
        code: "trim_failed",
        message: "Video export file type is unsupported",
        details: nil
      ))
      return
    }

    let outputExtension = extensionForVideoOutputFileType(preferredOutputFileType)
    let outputURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("flyfy_trimmed_\(Int(Date().timeIntervalSince1970 * 1000)).\(outputExtension)")
    try? FileManager.default.removeItem(at: outputURL)

    exporter.outputURL = outputURL
    exporter.outputFileType = preferredOutputFileType
    exporter.shouldOptimizeForNetworkUse = true
    exporter.timeRange = compositionTimeRange

    exporter.exportAsynchronously {
      DispatchQueue.main.async {
        switch exporter.status {
        case .completed:
          if FileManager.default.fileExists(atPath: outputURL.path) {
            result(outputURL.path)
          } else {
            result(FlutterError(
              code: "trim_failed",
              message: "Trimmed video file was not created",
              details: nil
            ))
          }
        case .failed:
          try? FileManager.default.removeItem(at: outputURL)
          if presetIndex + 1 < presetNames.count {
            exportTrimmedComposition(
              composition,
              compositionTimeRange: compositionTimeRange,
              presetNames: presetNames,
              presetIndex: presetIndex + 1,
              result: result
            )
            return
          }
          result(FlutterError(
            code: "trim_failed",
            message: exporter.error?.localizedDescription ?? "Video trim failed",
            details: nil
          ))
        case .cancelled:
          try? FileManager.default.removeItem(at: outputURL)
          result(FlutterError(
            code: "trim_cancelled",
            message: "Video trim was cancelled",
            details: nil
          ))
        default:
          try? FileManager.default.removeItem(at: outputURL)
          result(FlutterError(
            code: "trim_failed",
            message: "Video trim ended in an unexpected state",
            details: nil
          ))
        }
      }
    }
  }

  private static func clampedTrimTimeRange(
    asset: AVAsset,
    startMs: Int64,
    endMs: Int64
  ) -> CMTimeRange? {
    let assetDurationSeconds = CMTimeGetSeconds(asset.duration)
    guard assetDurationSeconds.isFinite, assetDurationSeconds > 0 else {
      return nil
    }

    let assetDurationMs = max(Int64((assetDurationSeconds * 1000).rounded()), 1)
    let safeStartMs = min(max(startMs, 0), max(assetDurationMs - 1, 0))
    let safeEndMs = min(max(endMs, safeStartMs + 1), assetDurationMs)
    guard safeEndMs > safeStartMs else {
      return nil
    }

    return CMTimeRange(
      start: CMTime(value: CMTimeValue(safeStartMs), timescale: 1000),
      duration: CMTime(value: CMTimeValue(safeEndMs - safeStartMs), timescale: 1000)
    )
  }

  private static func trimmedComposition(
    asset: AVAsset,
    sourceTimeRange: CMTimeRange
  ) throws -> AVMutableComposition {
    let composition = AVMutableComposition()
    var insertedTrack = false

    for mediaType in [AVMediaType.video, AVMediaType.audio] {
      for sourceTrack in asset.tracks(withMediaType: mediaType) {
        guard let compositionTrack = composition.addMutableTrack(
          withMediaType: mediaType,
          preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
          continue
        }

        try compositionTrack.insertTimeRange(sourceTimeRange, of: sourceTrack, at: .zero)
        if mediaType == .video {
          compositionTrack.preferredTransform = sourceTrack.preferredTransform
        }
        insertedTrack = true
      }
    }

    if !insertedTrack {
      throw NSError(
        domain: "FlyfyVideoTools",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "No audio or video tracks found"]
      )
    }

    return composition
  }

  private static func preferredVideoOutputFileType(_ supportedTypes: [AVFileType]) -> AVFileType? {
    if supportedTypes.contains(AVFileType.mp4) {
      return AVFileType.mp4
    }
    if supportedTypes.contains(AVFileType.mov) {
      return AVFileType.mov
    }
    return supportedTypes.first
  }

  private static func extensionForVideoOutputFileType(_ fileType: AVFileType) -> String {
    if fileType == AVFileType.mp4 {
      return "mp4"
    }
    if fileType == AVFileType.mov {
      return "mov"
    }
    return "mov"
  }

  private static func int64Value(_ value: Any?) -> Int64? {
    if let value = value as? Int64 { return value }
    if let value = value as? Int { return Int64(value) }
    if let value = value as? NSNumber { return value.int64Value }
    return nil
  }

  private static func readImageFromPasteboard() -> [String: Any]? {
    let pasteboard = UIPasteboard.general
    if let image = pasteboard.image,
       let bytes = image.pngData(),
       !bytes.isEmpty {
      return [
        "bytes": FlutterStandardTypedData(bytes: bytes),
        "contentType": "image/png",
        "name": "clipboard_\(Int(Date().timeIntervalSince1970 * 1000)).png"
      ]
    }

    for item in pasteboard.items {
      for (type, value) in item {
        guard let data = value as? Data, !data.isEmpty else { continue }
        if type == kUTTypePNG as String {
          return [
            "bytes": FlutterStandardTypedData(bytes: data),
            "contentType": "image/png",
            "name": "clipboard_\(Int(Date().timeIntervalSince1970 * 1000)).png"
          ]
        }
        if type == kUTTypeJPEG as String {
          return [
            "bytes": FlutterStandardTypedData(bytes: data),
            "contentType": "image/jpeg",
            "name": "clipboard_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
          ]
        }
        if type == "org.webmproject.webp" {
          return [
            "bytes": FlutterStandardTypedData(bytes: data),
            "contentType": "image/webp",
            "name": "clipboard_\(Int(Date().timeIntervalSince1970 * 1000)).webp"
          ]
        }
        if type == "public.heic" || type == "public.heif" {
          return [
            "bytes": FlutterStandardTypedData(bytes: data),
            "contentType": type == "public.heif" ? "image/heif" : "image/heic",
            "name": "clipboard_\(Int(Date().timeIntervalSince1970 * 1000)).heic"
          ]
        }
      }
    }
    return nil
  }
}
