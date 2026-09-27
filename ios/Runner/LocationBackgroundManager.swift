import Foundation
import CoreLocation

class LocationBackgroundManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationBackgroundManager()
    
    var onLocationUpdated: (([CLLocation]) -> Void)?
    
    private let locationManager = CLLocationManager()
    private var isTracking = false
    
    func startTracking() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
        isTracking = true
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        isTracking = false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // إرسال المواقع إلى Flutter عبر EventChannel
        onLocationUpdated?(locations)
    }
}
