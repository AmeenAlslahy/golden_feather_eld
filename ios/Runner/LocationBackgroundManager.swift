import Foundation
import CoreLocation

class LocationBackgroundManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationBackgroundManager()
    
    var onLocationUpdated: (([String: Any]) -> Void)?
    
    private let locationManager = CLLocationManager()
    private var isTracking = false
    private let queueKey = "traccar_offline_queue"
    private var isUploading = false
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
    }
    
    func setConfig(_ config: [String: Any]) {
        let defaults = UserDefaults.standard
        if let serverUrl = config["serverUrl"] as? String {
            defaults.set(serverUrl, forKey: "traccar_serverUrl")
        }
        if let deviceId = config["deviceId"] as? String {
            defaults.set(deviceId, forKey: "traccar_deviceId")
        }
        if let interval = config["interval"] as? Double {
            defaults.set(interval, forKey: "traccar_interval")
        }
        if let distance = config["distance"] as? Double {
            defaults.set(distance, forKey: "traccar_distance")
            locationManager.distanceFilter = distance
        }
    }
    
    func startTracking() {
        if isTracking { return }
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        isTracking = true
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        isTracking = false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let locData: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "speed": max(location.speed, 0) * 2.23694, // m/s to mph
            "bearing": max(location.course, 0),
            "altitude": location.altitude,
            "accuracy": location.horizontalAccuracy,
            "timestamp": Int64(location.timestamp.timeIntervalSince1970 * 1000)
        ]
        
        // 1. Broadcast to Flutter
        onLocationUpdated?(locData)
        
        // 2. Save to Queue
        var queue = UserDefaults.standard.array(forKey: queueKey) as? [[String: Any]] ?? []
        queue.append(locData)
        UserDefaults.standard.set(queue, forKey: queueKey)
        
        // 3. Trigger Upload
        triggerUpload()
    }
    
    private func triggerUpload() {
        if isUploading { return }
        let defaults = UserDefaults.standard
        guard let serverUrl = defaults.string(forKey: "traccar_serverUrl"), !serverUrl.isEmpty,
              let deviceId = defaults.string(forKey: "traccar_deviceId"), !deviceId.isEmpty else {
            return
        }
        
        var queue = defaults.array(forKey: queueKey) as? [[String: Any]] ?? []
        if queue.isEmpty { return }
        
        isUploading = true
        uploadNext(serverUrl: serverUrl, deviceId: deviceId, queue: queue)
    }
    
    private func uploadNext(serverUrl: String, deviceId: String, queue: [[String: Any]]) {
        guard let loc = queue.first else {
            isUploading = false
            return
        }
        
        let lat = loc["latitude"] as? Double ?? 0
        let lon = loc["longitude"] as? Double ?? 0
        let speed = loc["speed"] as? Double ?? 0
        let bearing = loc["bearing"] as? Double ?? 0
        let altitude = loc["altitude"] as? Double ?? 0
        let accuracy = loc["accuracy"] as? Double ?? 0
        let timestamp = loc["timestamp"] as? Int64 ?? 0
        
        let urlString = "\(serverUrl)/?id=\(deviceId)&lat=\(lat)&lon=\(lon)&timestamp=\(timestamp)&speed=\(speed)&bearing=\(bearing)&altitude=\(altitude)&accuracy=\(accuracy)"
        
        guard let url = URL(string: urlString) else {
            isUploading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Success, remove from queue
                var currentQueue = UserDefaults.standard.array(forKey: self.queueKey) as? [[String: Any]] ?? []
                if !currentQueue.isEmpty {
                    currentQueue.removeFirst()
                    UserDefaults.standard.set(currentQueue, forKey: self.queueKey)
                    
                    // Proceed to next
                    self.uploadNext(serverUrl: serverUrl, deviceId: deviceId, queue: currentQueue)
                } else {
                    self.isUploading = false
                }
            } else {
                // Network error, stop uploading
                self.isUploading = false
            }
        }
        task.resume()
    }
}
