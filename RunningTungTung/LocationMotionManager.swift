import Foundation
import CoreLocation
import Combine

final class LocationMotionManager: NSObject, ObservableObject {
    @Published var isMoving: Bool = false

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var lastMovingAt: Date?

    // Tunables
    private let speedThreshold: CLLocationSpeed = 0.7      // m/s ~ 2.5 km/h
    private let distanceThreshold: CLLocationDistance = 3.0 // meters between updates
    private let movingDecayInterval: TimeInterval = 3.0     // seconds to keep moving after last motion

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 1 // meters
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = true
    }

    func requestAuthorization() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func start() {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
    }
}

extension LocationMotionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            start()
        default:
            stop()
            DispatchQueue.main.async { self.isMoving = false }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        evaluateMovement(with: loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // On failure, assume not moving
        DispatchQueue.main.async { self.isMoving = false }
    }
}

private extension LocationMotionManager {
    func evaluateMovement(with location: CLLocation) {
        var movementDetected = false

        // Use speed if valid (>= 0). Negative speed means invalid.
        if location.speed >= 0 {
            movementDetected = location.speed > speedThreshold
        }

        // Fallback to distance delta if speed is not reliable
        if !movementDetected, let last = lastLocation {
            let delta = location.distance(from: last)
            movementDetected = delta > distanceThreshold
        }

        lastLocation = location

        if movementDetected {
            lastMovingAt = Date()
            if !isMoving { DispatchQueue.main.async { self.isMoving = true } }
        } else {
            // Apply decay so we don't flicker when movement briefly pauses
            if let lastMovingAt = lastMovingAt, Date().timeIntervalSince(lastMovingAt) < movingDecayInterval {
                // keep isMoving = true for a short period
            } else if isMoving {
                DispatchQueue.main.async { self.isMoving = false }
            }
        }
    }
}
