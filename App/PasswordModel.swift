import CoreGraphics
import Observation

@MainActor @Observable
final class PasswordModel {
    enum State {
        case idle
        case loading
        case shown(WiFiNetwork, qrCode: CGImage)
        case failed(String)
    }

    private(set) var state = State.idle
    /// Called when a request finishes, so the panel can reopen if a system dialog closed it.
    @ObservationIgnored var onResult: () -> Void = {}
    @ObservationIgnored private let location = LocationAccess()

    var isLoading: Bool {
        if case .loading = state { true } else { false }
    }

    func showPassword() {
        guard !isLoading else { return }
        state = .loading
        Task {
            do {
                guard await location.requestAccess() else { throw WiFiError.locationDenied }
                let network = try await WiFiNetwork.current()
                guard let qrCode = QRCode.image(for: network.qrPayload) else { throw WiFiError.qrCode }
                state = .shown(network, qrCode: qrCode)
            } catch WiFiError.cancelled {
                state = .idle
                return
            } catch {
                state = .failed(error.localizedDescription)
            }
            onResult()
        }
    }

    /// Forgets the password when the panel closes. A request still waiting on a dialog keeps going.
    func reset() {
        if !isLoading { state = .idle }
    }
}
