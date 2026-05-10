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
