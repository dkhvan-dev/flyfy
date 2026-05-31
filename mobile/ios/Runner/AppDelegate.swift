import AVFoundation
import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var documentInteractionController: UIDocumentInteractionController?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "inflap/clipboard_media",
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
      name: "inflap/video_tools",
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

    let fileOpenerChannel = FlutterMethodChannel(
      name: "inflap/file_opener",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    fileOpenerChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "openFile":
        self?.openFile(call.arguments, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func openFile(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any],
          let rawPath = args["path"] as? String else {
      result(Self.fileOpenResult(status: "file_not_found", message: "File path is empty"))
      return
    }

    let path = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !path.isEmpty else {
      result(Self.fileOpenResult(status: "file_not_found", message: "File path is empty"))
      return
    }

    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: url.path) else {
      result(Self.fileOpenResult(status: "file_not_found", message: "File does not exist"))
      return
    }

    guard let presenter = rootViewControllerForFileOpening(),
          let presenterView = presenter.view else {
      result(Self.fileOpenResult(status: "failed", message: "No active view controller"))
      return
    }

    let controller = UIDocumentInteractionController(url: url)
    if let rawContentType = args["contentType"] as? String {
      let contentType = rawContentType.trimmingCharacters(in: .whitespacesAndNewlines)
      if !contentType.isEmpty, let type = UTType(mimeType: contentType) {
        controller.uti = type.identifier
      }
    }

    documentInteractionController = controller
    let opened = controller.presentOptionsMenu(
      from: presenterView.bounds,
      in: presenterView,
      animated: true
    )
    result(Self.fileOpenResult(
      status: opened ? "done" : "no_app",
      message: opened ? nil : "No app can open this file"
    ))
  }

  private func rootViewControllerForFileOpening() -> UIViewController? {
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }

  private static func fileOpenResult(status: String, message: String? = nil) -> [String: Any] {
    var payload: [String: Any] = ["status": status]
    if let message {
      payload["message"] = message
    }
    return payload
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

    Task {
      do {
        let asset = AVURLAsset(url: inputURL)
        guard let sourceTimeRange = try await clampedTrimTimeRange(
          asset: asset,
          startMs: startMs,
          endMs: endMs
        ) else {
          await MainActor.run {
            result(FlutterError(
              code: "trim_failed",
              message: "Video trim range is outside the asset duration",
              details: nil
            ))
          }
          return
        }

        let compositionTimeRange = CMTimeRange(start: .zero, duration: sourceTimeRange.duration)
        let composition = try await trimmedComposition(
          asset: asset,
          sourceTimeRange: sourceTimeRange
        )
        let outputPath = try await exportTrimmedComposition(
          composition,
          compositionTimeRange: compositionTimeRange
        )
        await MainActor.run {
          result(outputPath)
        }
      } catch {
        await MainActor.run {
          result(FlutterError(
            code: "trim_failed",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    }
  }

  private static func exportTrimmedComposition(
    _ composition: AVMutableComposition,
    compositionTimeRange: CMTimeRange,
    presetNames: [String] = [
      AVAssetExportPresetPassthrough,
      AVAssetExportPresetHighestQuality
    ]
  ) async throws -> String {
    var lastError: Error?

    for presetName in presetNames {
      guard let exporter = AVAssetExportSession(
        asset: composition,
        presetName: presetName
      ) else {
        continue
      }

      let compatibleFileTypes = await compatibleFileTypes(for: exporter)
      guard let preferredOutputFileType = preferredVideoOutputFileType(compatibleFileTypes) else {
        throw NSError(
          domain: "InflapVideoTools",
          code: 2,
          userInfo: [NSLocalizedDescriptionKey: "Video export file type is unsupported"]
        )
      }

      let outputExtension = extensionForVideoOutputFileType(preferredOutputFileType)
      let outputURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("inflap_trimmed_\(Int(Date().timeIntervalSince1970 * 1000)).\(outputExtension)")
      try? FileManager.default.removeItem(at: outputURL)

      exporter.shouldOptimizeForNetworkUse = true
      exporter.timeRange = compositionTimeRange

      do {
        try await exporter.export(to: outputURL, as: preferredOutputFileType)
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
          throw NSError(
            domain: "InflapVideoTools",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Trimmed video file was not created"]
          )
        }
        return outputURL.path
      } catch {
        try? FileManager.default.removeItem(at: outputURL)
        lastError = error
      }
    }

    throw lastError ?? NSError(
      domain: "InflapVideoTools",
      code: 4,
      userInfo: [NSLocalizedDescriptionKey: "Video export session could not be created"]
    )
  }

  private static func clampedTrimTimeRange(
    asset: AVAsset,
    startMs: Int64,
    endMs: Int64
  ) async throws -> CMTimeRange? {
    let duration = try await asset.load(.duration)
    let assetDurationSeconds = CMTimeGetSeconds(duration)
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
  ) async throws -> AVMutableComposition {
    let composition = AVMutableComposition()
    var insertedTrack = false

    for mediaType in [AVMediaType.video, AVMediaType.audio] {
      for sourceTrack in try await asset.loadTracks(withMediaType: mediaType) {
        guard let compositionTrack = composition.addMutableTrack(
          withMediaType: mediaType,
          preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
          continue
        }

        try compositionTrack.insertTimeRange(sourceTimeRange, of: sourceTrack, at: .zero)
        if mediaType == .video {
          compositionTrack.preferredTransform = try await sourceTrack.load(.preferredTransform)
        }
        insertedTrack = true
      }
    }

    if !insertedTrack {
      throw NSError(
        domain: "InflapVideoTools",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "No audio or video tracks found"]
      )
    }

    return composition
  }

  private static func compatibleFileTypes(
    for exporter: AVAssetExportSession
  ) async -> [AVFileType] {
    await withCheckedContinuation { continuation in
      exporter.determineCompatibleFileTypes { fileTypes in
        continuation.resume(returning: fileTypes)
      }
    }
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
        if type == UTType.png.identifier {
          return [
            "bytes": FlutterStandardTypedData(bytes: data),
            "contentType": "image/png",
            "name": "clipboard_\(Int(Date().timeIntervalSince1970 * 1000)).png"
          ]
        }
        if type == UTType.jpeg.identifier {
          return [
            "bytes": FlutterStandardTypedData(bytes: data),
            "contentType": "image/jpeg",
            "name": "clipboard_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
          ]
        }
        if type == UTType.webP.identifier {
          return [
            "bytes": FlutterStandardTypedData(bytes: data),
            "contentType": "image/webp",
            "name": "clipboard_\(Int(Date().timeIntervalSince1970 * 1000)).webp"
          ]
        }
        if type == UTType.heic.identifier || type == UTType.heif.identifier {
          return [
            "bytes": FlutterStandardTypedData(bytes: data),
            "contentType": type == UTType.heif.identifier ? "image/heif" : "image/heic",
            "name": "clipboard_\(Int(Date().timeIntervalSince1970 * 1000)).heic"
          ]
        }
      }
    }
    return nil
  }
}
