import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
    
    private var eventSink: FlutterEventSink?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        
        let methodChannel = FlutterMethodChannel(name: "com.goldenfeather.eld/traccar", binaryMessenger: controller.binaryMessenger)
        let eventChannel = FlutterEventChannel(name: "com.goldenfeather.eld/traccar/events", binaryMessenger: controller.binaryMessenger)
        
        eventChannel.setStreamHandler(self)
        
        methodChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "setConfig":
                if let args = call.arguments as? [String: Any] {
                    LocationBackgroundManager.shared.setConfig(args)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Arguments must be a Map", details: nil))
                }
            case "startTracking":
                LocationBackgroundManager.shared.startTracking()
                result(nil)
            case "stopTracking":
                LocationBackgroundManager.shared.stopTracking()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - FlutterStreamHandler
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        LocationBackgroundManager.shared.onLocationUpdated = { locData in
            // Send back to Flutter on the main thread
            DispatchQueue.main.async {
                self.eventSink?(locData)
            }
        }
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        LocationBackgroundManager.shared.onLocationUpdated = nil
        return nil
    }
}
