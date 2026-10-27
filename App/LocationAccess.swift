import CoreLocation

/// macOS only tells apps the Wi-Fi network's name when they have Location Services access.
@MainActor
final class LocationAccess: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var pending: CheckedContinuation<Bool, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    var status: CLAuthorizationStatus { manager.authorizationStatus }

    /// The switch for the whole Mac. CoreLocation asks for this check to stay off the main thread.
    @concurrent
    nonisolated static func servicesEnabled() async -> Bool {
        CLLocationManager.locationServicesEnabled()
    }

    func requestAccess() async -> Bool {
        guard status == .notDetermined else {
            return status == .authorizedAlways
        }
        return await withCheckedContinuation { continuation in
            pending = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard status != .notDetermined else { return }
            pending?.resume(returning: status == .authorizedAlways)
            pending = nil
        }
    }
}
