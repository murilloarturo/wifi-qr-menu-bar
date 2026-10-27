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

    func requestAccess() async -> Bool {
        guard manager.authorizationStatus == .notDetermined else {
            return manager.authorizationStatus == .authorizedAlways
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
