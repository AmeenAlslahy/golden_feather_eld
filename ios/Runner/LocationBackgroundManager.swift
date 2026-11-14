import Foundation
import CoreLocation
import UIKit

/// Persisted tracking settings coming from Flutter.
///
/// Mirrors the shape the Android plugin writes into SharedPreferences, so the
/// same Dart config drives both platforms.
struct TrackingConfig {
    var serverURL: String = ""
    var deviceID: String = ""
    var intervalSeconds: Double = 5
    var distanceMeters: Double = 50
    var accuracy: String = "medium"
    var angleDegrees: Int = 0
    var heartbeatSeconds: Double = 0
    var stopDetection: Bool = true
    var buffer: Bool = true
    var wakeLock: Bool = false
    var preferPlatformProviders: Bool = false
    var notificationText: String = "Tracking in progress..."
    /// `phoneGps` | `bleDevice` | `hybrid`.
    var sourceMode: String = "hybrid"

    static let defaultsKey = "traccar_config"

    static func load() -> TrackingConfig {
        var config = TrackingConfig()
        guard let stored = UserDefaults.standard.dictionary(forKey: defaultsKey) else {
            return config
        }
        config.serverURL = stored["serverUrl"] as? String ?? config.serverURL
        config.deviceID = stored["deviceId"] as? String ?? config.deviceID
        config.intervalSeconds =
            (stored["interval"] as? NSNumber)?.doubleValue ?? config.intervalSeconds
        config.distanceMeters =
            (stored["distance"] as? NSNumber)?.doubleValue ?? config.distanceMeters
        config.accuracy = stored["accuracy"] as? String ?? config.accuracy
        config.angleDegrees =
            (stored["angle"] as? NSNumber)?.intValue ?? config.angleDegrees
        config.heartbeatSeconds =
            (stored["heartbeat"] as? NSNumber)?.doubleValue ?? config.heartbeatSeconds
        config.stopDetection = stored["stop_detection"] as? Bool ?? config.stopDetection
        config.buffer = stored["buffer"] as? Bool ?? config.buffer
        config.wakeLock = stored["wakelock"] as? Bool ?? config.wakeLock
        config.preferPlatformProviders =
            stored["prefer_platform_providers"] as? Bool ?? config.preferPlatformProviders
        config.notificationText =
            stored["notification_text"] as? String ?? config.notificationText
        config.sourceMode = stored["source_mode"] as? String ?? config.sourceMode
        return config
    }

    func save() {
        let stored: [String: Any] = [
            "serverUrl": serverURL,
            "deviceId": deviceID,
            "interval": intervalSeconds,
            "distance": distanceMeters,
            "accuracy": accuracy,
            "angle": angleDegrees,
            "heartbeat": heartbeatSeconds,
            "stop_detection": stopDetection,
            "buffer": buffer,
            "wakelock": wakeLock,
            "prefer_platform_providers": preferPlatformProviders,
            "notification_text": notificationText,
            "source_mode": sourceMode,
        ]
        UserDefaults.standard.set(stored, forKey: TrackingConfig.defaultsKey)
    }
}

/// One position waiting to be uploaded (offline-safe queue).
struct QueuedLocation: Codable {
    let id: String
    let latitude: Double
    let longitude: Double
    /// Metres per second, exactly as reported by CoreLocation/BLE.
    let speed: Double
    let bearing: Double
    let altitude: Double
    let accuracy: Double
    /// Unix epoch seconds.
    let timestamp: Double
    let alarm: String?
    let source: String
}

/// CoreLocation wrapper that now owns the offline queue and the OsmAnd uploader.
///
/// Before this change iOS only forwarded positions to Flutter while the app was
/// alive: nothing was persisted and nothing was uploaded. It now:
///  - applies the same accuracy/angle/heartbeat/stop filters as Android,
///  - writes every accepted fix to a JSON queue in Application Support,
///  - uploads with the OsmAnd protocol (knots, any 2xx, alarm, battery),
///  - retries with 5s -> 5min backoff.
final class LocationBackgroundManager: NSObject, CLLocationManagerDelegate {

    static let shared = LocationBackgroundManager()

    /// Called for every fix (accepted or filtered) so Flutter can render it.
    var onLocationUpdated: (([CLLocation]) -> Void)?

    private let locationManager = CLLocationManager()
    private let queue = DispatchQueue(label: "com.goldenfeather.eld.location-queue")

    private var config = TrackingConfig.load()
    private var isTracking = false

    private var pending: [QueuedLocation] = []
    private var lastAccepted: CLLocation?
    private var lastAcceptedAt: Date?
    private var failures = 0
    private var uploaderBusy = false
    private var retryScheduled = false

    private(set) var lastLocation: CLLocation?

    private static let mpsToKnots = 1.9438444924406
    private static let baseBackoffSeconds: Double = 5
    private static let maxBackoffSeconds: Double = 300

    override private init() {
        super.init()
        UIDevice.current.isBatteryMonitoringEnabled = true
        pending = Self.readQueue()
        TrackingLogStore.shared.info(
            "Location manager initialised with \(pending.count) queued fix(es)", tag: "LOCATION"
        )
    }

    // MARK: - Lifecycle

    func startTracking(config: TrackingConfig) {
        self.config = config
        config.save()

        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = desiredAccuracy(for: config.accuracy)
        locationManager.distanceFilter = max(1, config.distanceMeters)
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.startUpdatingLocation()

        isTracking = true
        UserDefaults.standard.set(true, forKey: "tracking_enabled")
        TrackingLogStore.shared.info(
            "Tracking started (interval=\(config.intervalSeconds)s, " +
                "distance=\(config.distanceMeters)m, accuracy=\(config.accuracy))",
            tag: "LOCATION"
        )
        flush()
    }

    func updateConfig(_ config: TrackingConfig) {
        self.config = config
        config.save()
        if isTracking {
            locationManager.desiredAccuracy = desiredAccuracy(for: config.accuracy)
            locationManager.distanceFilter = max(1, config.distanceMeters)
        }
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        isTracking = false
        UserDefaults.standard.set(false, forKey: "tracking_enabled")
        retryScheduled = false
        TrackingLogStore.shared.info("Tracking stopped", tag: "LOCATION")
    }

    var tracking: Bool { isTracking }

    /// One-shot request used by `requestPosition` when the cache is empty.
    func requestSingleUpdate() {
        locationManager.delegate = self
        locationManager.requestLocation()
    }

    // MARK: - Location intake

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location

        // In `bleDevice` mode the ELD owns the position stream; phone fixes must
        // not be queued or shown twice.
        if config.sourceMode == "bleDevice" {
            return
        }

        onLocationUpdated?(locations)

        guard shouldAccept(location) else { return }

        enqueue(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            speed: max(0, location.speed),
            bearing: max(0, location.course),
            altitude: location.altitude,
            accuracy: max(0, location.horizontalAccuracy),
            timestamp: location.timestamp.timeIntervalSince1970,
            alarm: nil,
            source: "phone"
        )
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        TrackingLogStore.shared.warn(
            "CoreLocation error: \(error.localizedDescription)", tag: "LOCATION"
        )
    }

    /// Accepts a fix produced outside CoreLocation (BLE ELD).
    func push(
        latitude: Double,
        longitude: Double,
        speed: Double,
        bearing: Double,
        altitude: Double,
        accuracy: Double,
        timestamp: Double,
        alarm: String?,
        source: String
    ) {
        enqueue(
            latitude: latitude,
            longitude: longitude,
            speed: speed,
            bearing: bearing,
            altitude: altitude,
            accuracy: accuracy,
            timestamp: timestamp,
            alarm: alarm,
            source: source
        )
    }

    private func enqueue(
        latitude: Double,
        longitude: Double,
        speed: Double,
        bearing: Double,
        altitude: Double,
        accuracy: Double,
        timestamp: Double,
        alarm: String?,
        source: String
    ) {
        let entry = QueuedLocation(
            id: UUID().uuidString,
            latitude: latitude,
            longitude: longitude,
            speed: speed,
            bearing: bearing,
            altitude: altitude,
            accuracy: accuracy,
            timestamp: timestamp,
            alarm: alarm,
            source: source
        )
        queue.async {
            self.pending.append(entry)
            self.saveQueue()
            self.flushLocked()
        }
    }

    // MARK: - Filters (same semantics as Android TrackingLocationFilter)

    private func shouldAccept(_ location: CLLocation) -> Bool {
        let threshold = accuracyThresholdMeters(config.accuracy)
        if threshold > 0 && location.horizontalAccuracy > threshold {
            return false
        }

        guard let previous = lastAccepted else {
            markAccepted(location)
            return true
        }

        let elapsed = Date().timeIntervalSince(lastAcceptedAt ?? Date())
        if config.heartbeatSeconds > 0 && elapsed >= config.heartbeatSeconds {
            markAccepted(location)
            return true
        }

        let distance = location.distance(from: previous)
        if distance >= config.distanceMeters {
            if config.angleDegrees <= 0 {
                markAccepted(location)
                return true
            }
            let delta = angleDifference(previous.course, location.course)
            if delta >= Double(config.angleDegrees) || distance >= config.distanceMeters * 3 {
                markAccepted(location)
                return true
            }
            return false
        }

        if config.stopDetection && max(0, location.speed) < 0.5 {
            return false
        }
        return false
    }

    private func markAccepted(_ location: CLLocation) {
        lastAccepted = location
        lastAcceptedAt = Date()
    }

    private func angleDifference(_ a: Double, _ b: Double) -> Double {
        let raw = abs(a - b).truncatingRemainder(dividingBy: 360)
        return raw > 180 ? 360 - raw : raw
    }

    private func accuracyThresholdMeters(_ accuracy: String) -> Double {
        switch accuracy.lowercased() {
        case "highest": return 20
        case "high": return 50
        case "low": return 500
        default: return 150
        }
    }

    private func desiredAccuracy(for accuracy: String) -> CLLocationAccuracy {
        switch accuracy.lowercased() {
        case "highest": return kCLLocationAccuracyBest
        case "high": return kCLLocationAccuracyNearestTenMeters
        case "low": return kCLLocationAccuracyHundredMeters
        default: return kCLLocationAccuracyBest
        }
    }

    // MARK: - Queue persistence

    private static func queueFileURL() -> URL? {
        let manager = FileManager.default
        guard let directory = manager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        if !manager.fileExists(atPath: directory.path) {
            try? manager.createDirectory(
                at: directory, withIntermediateDirectories: true, attributes: nil
            )
        }
        return directory.appendingPathComponent("traccar_queue.json")
    }

    private static func readQueue() -> [QueuedLocation] {
        guard let url = queueFileURL(), let data = try? Data(contentsOf: url) else {
            return []
        }
        return (try? JSONDecoder().decode([QueuedLocation].self, from: data)) ?? []
    }

    private func saveQueue() {
        guard let url = Self.queueFileURL() else { return }
        if let data = try? JSONEncoder().encode(pending) {
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: - Upload

    /// Flushes the queue. Safe to call from any thread.
    func flush() {
        queue.async { self.flushLocked() }
    }

    private func flushLocked() {
        guard !uploaderBusy, !retryScheduled else { return }
        guard !pending.isEmpty else { return }
        guard !config.serverURL.isEmpty, !config.deviceID.isEmpty else { return }

        uploaderBusy = true
        let entry = pending[0]

        upload(entry) { [weak self] success, statusCode in
            guard let self = self else { return }
            self.queue.async {
                self.uploaderBusy = false
                if success {
                    self.failures = 0
                    if !self.pending.isEmpty {
                        self.pending.removeFirst()
                    }
                    self.saveQueue()
                    self.flushLocked()
                } else {
                    self.failures += 1
                    TrackingLogStore.shared.warn(
                        "Upload failed (attempt \(self.failures), HTTP \(statusCode)). " +
                            "Retrying in \(Int(self.backoffSeconds()))s. " +
                            "Queue: \(self.pending.count)",
                        tag: "UPLOAD"
                    )
                    self.scheduleRetry()
                }
            }
        }
    }

    private func scheduleRetry() {
        guard !retryScheduled else { return }
        retryScheduled = true
        let delay = backoffSeconds()
        queue.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.retryScheduled = false
            self.flushLocked()
        }
    }

    private func backoffSeconds() -> Double {
        guard failures > 0 else { return 0 }
        let exponent = min(failures - 1, 10)
        return min(Self.baseBackoffSeconds * pow(2, Double(exponent)), Self.maxBackoffSeconds)
    }

    private func upload(
        _ entry: QueuedLocation,
        completion: @escaping (Bool, Int) -> Void
    ) {
        var base = config.serverURL
        if base.hasSuffix("/") {
            base.removeLast()
        }
        let speedKnots = entry.speed * Self.mpsToKnots

        var components = URLComponents(string: base + "/")
        var items: [URLQueryItem] = [
            URLQueryItem(name: "id", value: config.deviceID),
            URLQueryItem(name: "lat", value: String(format: "%.7f", entry.latitude)),
            URLQueryItem(name: "lon", value: String(format: "%.7f", entry.longitude)),
            URLQueryItem(name: "timestamp", value: String(Int64(entry.timestamp))),
            URLQueryItem(name: "speed", value: String(format: "%.2f", speedKnots)),
            URLQueryItem(name: "bearing", value: String(format: "%.1f", entry.bearing)),
            URLQueryItem(name: "altitude", value: String(format: "%.1f", entry.altitude)),
            URLQueryItem(name: "accuracy", value: String(format: "%.1f", entry.accuracy)),
        ]
        if let alarm = entry.alarm, !alarm.isEmpty {
            items.append(URLQueryItem(name: "alarm", value: alarm))
        }
        if let battery = batteryQueryItems() {
            items.append(contentsOf: battery)
        }
        components?.queryItems = items

        guard let url = components?.url else {
            completion(false, 0)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("GoldenFeather-ELD/1.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                TrackingLogStore.shared.warn(
                    "Upload error for \(entry.id): \(error.localizedDescription)", tag: "UPLOAD"
                )
                completion(false, 0)
                return
            }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let success = (200...299).contains(status)
            if success {
                TrackingLogStore.shared.info(
                    "Uploaded location \(entry.id) (source=\(entry.source))", tag: "UPLOAD"
                )
            }
            completion(success, status)
        }.resume()
    }

    private func batteryQueryItems() -> [URLQueryItem]? {
        let level = Int(UIDevice.current.batteryLevel * 100)
        guard level >= 0 && level <= 100 else { return nil }
        let charging = UIDevice.current.batteryState == .charging
            || UIDevice.current.batteryState == .full
        return [
            URLQueryItem(name: "batt", value: String(level)),
            URLQueryItem(name: "charge", value: charging ? "true" : "false"),
        ]
    }
}

/// Small ring buffer shared with the Flutter diagnostics screen.
///
/// `getLogs` used to return an empty array on iOS, which made field debugging
/// impossible.
final class TrackingLogStore {
    static let shared = TrackingLogStore()

    private let maxEntries = 500
    private var entries: [[String: Any]] = []
    private let lock = NSLock()

    private init() {}

    func info(_ message: String, tag: String = "TRACCAR_PLUGIN") {
        add(level: "I", message: message, tag: tag)
    }

    func warn(_ message: String, tag: String = "TRACCAR_PLUGIN") {
        add(level: "W", message: message, tag: tag)
    }

    func error(_ message: String, tag: String = "TRACCAR_PLUGIN") {
        add(level: "E", message: message, tag: tag)
    }

    func snapshot() -> [[String: Any]] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll()
    }

    private func add(level: String, message: String, tag: String) {
        let entry: [String: Any] = [
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "level": level,
            "tag": tag,
            "message": message,
        ]
        lock.lock()
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
        lock.unlock()
        NSLog("[%@] %@", tag, message)
    }
}
