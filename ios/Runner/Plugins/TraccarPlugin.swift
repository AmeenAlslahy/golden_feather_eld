import Foundation
import CoreLocation
import Flutter

/**
 * TraccarPlugin - تتبع GPS حقيقي للتواصل مع خادم Traccar
 *
 * Since the iOS location manager owns persistence and upload, this class is the
 * MethodChannel façade:
 *  - persists every setting Flutter sends (nested `location` block included),
 *  - remembers whether tracking was enabled across restarts,
 *  - forwards fixes produced outside CoreLocation (BLE ELD) to the same queue,
 *  - exposes real logs for the diagnostics screen.
 */
class TraccarPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {

    private var eventSink: FlutterEventSink?
    private var cachedLocation: [String: Any]?

    private static let trackingEnabledKey = "tracking_enabled"
    private static let maxLastKnownAge: TimeInterval = 5 * 60

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
            instance.forward(locations: locations)
        }

        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)

        // Restore tracking after a process restart, matching Android's
        // `tracking_enabled` behaviour.
        if UserDefaults.standard.bool(forKey: trackingEnabledKey) {
            LocationBackgroundManager.shared.startTracking(config: TrackingConfig.load())
            TrackingLogStore.shared.info("Restored tracking after launch", tag: "TRACCAR")
        }
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "setConfig":
                result(try setConfig(call: call))
            case "start":
                result(try startTracking())
            case "stop":
                result(stopTracking())
            case "isTracking":
                result(
                    UserDefaults.standard.bool(forKey: Self.trackingEnabledKey)
                        || LocationBackgroundManager.shared.tracking
                )
            case "requestPosition":
                result(try requestPosition(call: call))
            case "pushLocation":
                result(try pushLocation(call: call))
            case "getLastKnownPosition":
                result(lastKnownPosition())
            case "getLogs":
                result(TrackingLogStore.shared.snapshot())
            case "clearLogs":
                TrackingLogStore.shared.clear()
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        } catch let error as TraccarPluginError {
            TrackingLogStore.shared.error(error.message, tag: "TRACCAR")
            result(FlutterError(code: error.code, message: error.message, details: nil))
        } catch {
            TrackingLogStore.shared.error(error.localizedDescription, tag: "TRACCAR")
            result(
                FlutterError(
                    code: "TRACCAR_ERROR",
                    message: error.localizedDescription,
                    details: nil
                )
            )
        }
    }

    // MARK: - Configuration

    private func setConfig(call: FlutterMethodCall) throws -> Bool {
        let arguments = call.arguments as? [String: Any] ?? [:]
        let location = arguments["location"] as? [String: Any] ?? [:]

        func raw(_ key: String) -> Any? {
            location[key] ?? arguments[key]
        }

        var config = TrackingConfig.load()
        if let serverURL = arguments["serverUrl"] as? String {
            config.serverURL = serverURL
        }
        if let deviceID = arguments["deviceId"] as? String {
            config.deviceID = deviceID
        }
        config.intervalSeconds = number(raw("intervalSeconds")) ?? config.intervalSeconds
        config.distanceMeters = number(raw("distanceMeters")) ?? config.distanceMeters
        config.accuracy = raw("accuracy") as? String ?? config.accuracy
        config.angleDegrees = Int(number(raw("angleDegrees")) ?? Double(config.angleDegrees))
        config.heartbeatSeconds =
            number(raw("heartbeatIntervalSeconds")) ?? config.heartbeatSeconds
        config.stopDetection = boolean(raw("stopDetection")) ?? config.stopDetection
        config.buffer = boolean(raw("buffer")) ?? config.buffer
        config.wakeLock = boolean(arguments["wakeLock"] ?? raw("wakelock")) ?? config.wakeLock
        config.preferPlatformProviders =
            boolean(arguments["preferPlatformProviders"]) ?? config.preferPlatformProviders
        if let notification = arguments["notificationText"] as? String {
            config.notificationText = notification
        }
        config.sourceMode = arguments["sourceMode"] as? String ?? config.sourceMode
        config.save()

        LocationBackgroundManager.shared.updateConfig(config)
        TrackingLogStore.shared.info(
            "Config applied (server configured=\(!config.serverURL.isEmpty), " +
                "interval=\(Int(config.intervalSeconds))s, " +
                "distance=\(Int(config.distanceMeters))m, accuracy=\(config.accuracy))",
            tag: "TRACCAR"
        )
        return true
    }

    // MARK: - Tracking lifecycle

    private func startTracking() throws -> Bool {
        let config = TrackingConfig.load()
        LocationBackgroundManager.shared.startTracking(config: config)
        UserDefaults.standard.set(true, forKey: Self.trackingEnabledKey)
        return true
    }

    private func stopTracking() -> Bool {
        LocationBackgroundManager.shared.stopTracking()
        UserDefaults.standard.set(false, forKey: Self.trackingEnabledKey)
        return true
    }

    // MARK: - Positions

    private func requestPosition(call: FlutterMethodCall) throws -> [String: Any] {
        let arguments = call.arguments as? [String: Any] ?? [:]
        let alarm = arguments["alarm"] as? String
        let manager = LocationBackgroundManager.shared

        guard let location = manager.lastLocation else {
            manager.requestSingleUpdate()
            throw TraccarPluginError(code: "NO_LOCATION", message: "No location available")
        }

        manager.push(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            speed: max(0, location.speed),
            bearing: max(0, location.course),
            altitude: location.altitude,
            accuracy: max(0, location.horizontalAccuracy),
            timestamp: location.timestamp.timeIntervalSince1970,
            alarm: alarm,
            source: "phone"
        )

        let data = locationToMap(location, alarm: alarm)
        emit(data)
        return data
    }

    /// Accepts a fix produced outside CoreLocation (BLE ELD, NMEA parser).
    /// Speed must be metres per second; the uploader converts to knots.
    private func pushLocation(call: FlutterMethodCall) throws -> [String: Any] {
        let arguments = call.arguments as? [String: Any] ?? [:]
        guard
            let latitude = number(arguments["latitude"]),
            let longitude = number(arguments["longitude"]),
            (-90...90).contains(latitude),
            (-180...180).contains(longitude)
        else {
            throw TraccarPluginError(
                code: "INVALID_LOCATION", message: "Valid latitude/longitude required"
            )
        }

        let rawTimestamp = number(arguments["timestamp"]) ?? (Date().timeIntervalSince1970 * 1000)
        // Accept epoch seconds or milliseconds.
        let timestampSeconds = rawTimestamp > 100_000_000_000 ? rawTimestamp / 1000 : rawTimestamp
        let alarm = arguments["alarm"] as? String
        let source = arguments["source"] as? String ?? "ble"

        let speed = number(arguments["speed"]) ?? 0
        let bearing = number(arguments["bearing"]) ?? 0
        let altitude = number(arguments["altitude"]) ?? 0
        let accuracy = number(arguments["accuracy"]) ?? 0

        LocationBackgroundManager.shared.push(
            latitude: latitude,
            longitude: longitude,
            speed: speed,
            bearing: bearing,
            altitude: altitude,
            accuracy: accuracy,
            timestamp: timestampSeconds,
            alarm: alarm,
            source: source
        )

        var data: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "speed": speed,
            "bearing": bearing,
            "altitude": altitude,
            "accuracy": accuracy,
            "timestamp": Int(timestampSeconds * 1000),
            "source": source,
        ]
        if let alarm = alarm {
            data["alarm"] = alarm
        }
        emit(data)
        return data
    }

    /// Read-only access to the freshest cached fix.
    private func lastKnownPosition() -> [String: Any]? {
        // In BLE-only mode the ELD owns the position stream; a stale phone fix
        // must not be presented as the current vehicle location.
        if TrackingConfig.load().sourceMode == "bleDevice" {
            return nil
        }
        guard let location = LocationBackgroundManager.shared.lastLocation else { return nil }
        let age = Date().timeIntervalSince(location.timestamp)
        guard age <= Self.maxLastKnownAge else { return nil }
        return locationToMap(location, alarm: nil)
    }

    private func forward(locations: [CLLocation]) {
        guard let location = locations.last else { return }
        emit(locationToMap(location, alarm: nil))
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        forward(locations: locations)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        TrackingLogStore.shared.warn(
            "CoreLocation error: \(error.localizedDescription)", tag: "TRACCAR"
        )
    }

    // MARK: - Helpers

    private func emit(_ data: [String: Any]) {
        if let sink = eventSink {
            sink(data)
        } else {
            cachedLocation = data
        }
    }

    private func locationToMap(_ location: CLLocation, alarm: String?) -> [String: Any] {
        var map: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "speed": max(0, location.speed),
            "bearing": max(0, location.course),
            "altitude": location.altitude,
            "accuracy": max(0, location.horizontalAccuracy),
            "timestamp": Int(location.timestamp.timeIntervalSince1970 * 1000),
            "source": "phone",
        ]
        if let alarm = alarm, !alarm.isEmpty {
            map["alarm"] = alarm
        }
        return map
    }

    private func number(_ value: Any?) -> Double? {
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let double = value as? Double {
            return double
        }
        if let integer = value as? Int {
            return Double(integer)
        }
        if let string = value as? String {
            return Double(string)
        }
        return nil
    }

    private func boolean(_ value: Any?) -> Bool? {
        if let boolean = value as? Bool {
            return boolean
        }
        if let number = value as? NSNumber {
            return number.boolValue
        }
        if let string = value as? String {
            return (string as NSString).boolValue
        }
        return nil
    }
}

extension TraccarPlugin: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
        -> FlutterError?
    {
        self.eventSink = events
        if let cached = cachedLocation {
            events(cached)
            cachedLocation = nil
            TrackingLogStore.shared.info("Sent cached location on sink attach", tag: "TRACCAR")
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

private struct TraccarPluginError: Error {
    let code: String
    let message: String
}
