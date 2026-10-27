import SwiftUI

struct PasswordPanel: View {
    let model: PasswordModel

    var body: some View {
        VStack(spacing: 12) {
            content
            Divider()
            Button("Quit WiFi QR") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.borderless)
        }
        .padding(16)
        .frame(width: 260)
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle:
            Button("Show Password", action: model.showPassword)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
        case .loading:
            ProgressView()
                .controlSize(.small)
        case .needsLocation:
            Image(systemName: "location.slash")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("macOS only shares the Wi-Fi network's name with apps that have location access.")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open Location Settings", action: model.openLocationSettings)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        case .shown(let network, let qrCode):
            Image(qrCode, scale: 1, label: Text("QR code to join \(network.ssid)"))
                .resizable()
                .frame(width: 200, height: 200)
                .padding(8)
                .background(.white, in: .rect(cornerRadius: 8))
            Text(network.ssid)
                .font(.headline)
            Text(network.password ?? "No password")
                .font(.body.monospaced())
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
        case .failed(let message):
            Text(message)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Try Again", action: model.showPassword)
        }
    }
}
