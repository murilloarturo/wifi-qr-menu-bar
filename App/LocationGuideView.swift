import SwiftUI

struct LocationGuideView: View {
    let guide: LocationGuide

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(guide.step.title)
                    .font(.headline)
                Spacer()
                Button("Close", systemImage: "xmark", action: guide.close)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
            }
            Text(guide.step.instruction)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            SwitchDemo(step: guide.step)
                .padding(.top, 6)
        }
        .padding(16)
        .frame(width: 300)
        .padding(.horizontal, LocationGuide.arrowSize)
        .background(.regularMaterial, in: CalloutShape(arrowEdge: guide.arrowEdge))
    }
}

private extension LocationGuide.Step {
    var title: String {
        switch self {
        case .locationServices: "Turn on Location Services"
        case .app: "Turn on WiFi QR"
        }
    }

    var instruction: String {
        switch self {
        case .locationServices:
            "It's the switch at the top of this page. macOS only shares the Wi-Fi network's name with apps when it's on."
        case .app:
            "Find WiFi QR in the list on this page and switch it on."
        }
    }

    var switchLabel: String {
        switch self {
        case .locationServices: "Location Services"
        case .app: "WiFi QR"
        }
    }
}

/// A copy of the row in System Settings, with a hand switching it on, on a loop.
private struct SwitchDemo: View {
    let step: LocationGuide.Step

    var body: some View {
        PhaseAnimator(Phase.allCases) { phase in
            HStack(spacing: 8) {
                if step == .app {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                Text(step.switchLabel)
                Spacer()
                DemoSwitch(isOn: phase == .on)
                    .overlay {
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.title2)
                            .shadow(radius: 1)
                            .scaleEffect(phase == .press ? 0.85 : 1)
                            .offset(x: phase == .rest ? 22 : 12, y: phase == .rest ? 22 : 14)
                            .opacity(phase == .rest ? 0 : 1)
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.background, in: .rect(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.accentColor, lineWidth: 2))
        } animation: { phase in
            switch phase {
            case .rest: .easeOut(duration: 0.3).delay(1.2)
            case .point: .easeInOut(duration: 0.6).delay(0.4)
            case .press: .easeIn(duration: 0.15)
            case .on: .spring(duration: 0.3)
            }
        }
        .accessibilityHidden(true)
    }

    private enum Phase: CaseIterable {
        case rest, point, press, on
    }
}

private struct DemoSwitch: View {
    let isOn: Bool

    var body: some View {
        Capsule()
            .fill(isOn ? Color.accentColor : Color.secondary.opacity(0.3))
            .frame(width: 34, height: 20)
            .overlay {
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 0.5)
                    .padding(2)
                    .offset(x: isOn ? 7 : -7)
            }
    }
}

/// The card, with an arrow on the side that faces System Settings.
private struct CalloutShape: Shape {
    let arrowEdge: HorizontalEdge?

    func path(in rect: CGRect) -> Path {
        let size = LocationGuide.arrowSize
        let card = rect.insetBy(dx: size, dy: 0)
        var path = Path(roundedRect: card, cornerRadius: 16)
        let y = card.minY + 34
        switch arrowEdge {
        case .leading:
            path.addLines([CGPoint(x: card.minX, y: y - size), CGPoint(x: rect.minX, y: y), CGPoint(x: card.minX, y: y + size)])
        case .trailing:
            path.addLines([CGPoint(x: card.maxX, y: y - size), CGPoint(x: rect.maxX, y: y), CGPoint(x: card.maxX, y: y + size)])
        case nil:
            break
        }
        return path
    }
}
