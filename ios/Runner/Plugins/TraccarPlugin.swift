import Foundation
import CoreLocation
import Flutter

/**
 * TraccarPlugin - تتبع GPS حقيقي للتواصل مع خادم Traccar
 */
class TraccarPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    private var isTracking = false
    private var eventSink: FlutterEventSink?
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.goldenfeather.eld/traccar",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.goldenfeather.eld/traccar/events",
            binaryMessenger: registrar.messenger()
        )
        
        let instance = TraccarPlugin()
        
        LocationBackgroundManager.shared.onLocationUpdated = { locations in
            instance.locationManager(CLLocationManager(), didUpdateLocations: locations)
        }
        
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setConfig":
            setConfig(call: call, result: result)
        case "start":
            startTracking(result: result)
        case "stop":
            stopTracking(result: result)
        case "isTracking":
            result(isTracking)
        case "requestPosition":
            requestPosition(call: call, result: result)
        case "getLogs":
            result([])
        case "clearLogs":
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func setConfig(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let interval = (call.arguments as? [String: Any])?["intervalSeconds"] as? Double ?? 5.0
        let distance = (call.arguments as? [String: Any])?["distanceMeters"] as? Double ?? 50.0
        
        locationManager.distanceFilter = distance
        // Note: iOS doesn't support custom interval directly
        // CoreLocation determines the update frequency
        
        result(true)
    }
    
    private func startTracking(result: @escaping FlutterResult) {
        guard !isTracking else {
            result(true)
            return
        }
        
        LocationBackgroundManager.shared.startTracking()
        
        isTracking = true
        result(true)
    }
    
    private func stopTracking(result: @escaping FlutterResult) {
        LocationBackgroundManager.shared.stopTracking()
        isTracking = false
        result(true)
    }
    
    private func requestPosition(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let location = locationManager.location else {
            result(FlutterError(code: "NO_LOCATION", message: "No location available", details: nil))
            return
        }
        
        let data = locationToMap(location)
        eventSink?(data)
        result(data)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let data = locationToMap(location)
        eventSink?(data)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        eventSink?(FlutterError(code: "LOCATION_ERROR", message: error.localizedDescription, details: nil))
    }
    
    private func locationToMap(_ location: CLLocation) -> [String: Any] {
        return [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "speed": location.speed < 0 ? 0 : location.speed,
            "bearing": location.course < 0 ? 0 : location.course,
            "altitude": location.altitude,
            "accuracy": location.horizontalAccuracy,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
    }
}

extension TraccarPlugin: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
