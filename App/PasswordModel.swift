import AppKit
import Observation

@MainActor @Observable
final class PasswordModel {
    enum State {
        case idle
        case loading
        case needsLocation
        case shown(WiFiNetwork, qrCode: CGImage)
        case failed(String)
    }

    private(set) var state = State.idle
    /// Let AppLifecycle show or hide the panel when the flow moves on by itself.
    @ObservationIgnored var onShowPanel: () -> Void = {}
    @ObservationIgnored var onHidePanel: () -> Void = {}
    @ObservationIgnored private let location = LocationAccess()
    @ObservationIgnored private let guide = LocationGuide()
    @ObservationIgnored private var guideTask: Task<Void, Never>?

    var isLoading: Bool {
        if case .loading = state { true } else { false }
    }

    func showPassword() {
        guard !isLoading else { return }
        state = .loading
        Task {
            state = await nextState()
            if case .idle = state { return }
            onShowPanel()
        }
    }

    /// Opens Location Services in System Settings with a guide beside it, and carries on once access is on.
    func openLocationSettings() {
        onHidePanel()
        NSWorkspace.shared.open(Self.locationSettings)
        guideTask?.cancel()
        guideTask = Task {
            repeat {
                let servicesEnabled = await LocationAccess.servicesEnabled()
                let status = location.status
                if status == .authorizedAlways || (servicesEnabled && status == .notDetermined) {
                    guide.close()
                    // Asks for access first when macOS hasn't asked yet.
                    showPassword()
                    return
                }
                guide.show(servicesEnabled ? .app : .locationServices)
                try? await Task.sleep(for: .milliseconds(500))
            } while guide.isShown && !Task.isCancelled
        }
    }

    /// Forgets the password when the panel closes. A request still waiting on a dialog keeps going.
    func reset() {
        if !isLoading { state = .idle }
    }

    private func nextState() async -> State {
        guard await location.requestAccess() else { return .needsLocation }
        do {
            let network = try await WiFiNetwork.current()
            guard let qrCode = QRCode.image(for: network.qrPayload) else { throw WiFiError.qrCode }
            return .shown(network, qrCode: qrCode)
        } catch WiFiError.cancelled {
            return .idle
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    private static let locationSettings = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_LocationServices")!
}
