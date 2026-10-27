import AppKit
import SwiftUI

/// A floating panel beside System Settings that shows which switch to turn on.
@MainActor @Observable
final class LocationGuide {
    enum Step {
        case locationServices
        case app
    }

    /// Room on each side of the card for the arrow that points at System Settings.
    nonisolated static let arrowSize: CGFloat = 10

    private(set) var step = Step.app
    private(set) var arrowEdge: HorizontalEdge?
    @ObservationIgnored private var panel: NSPanel?
    @ObservationIgnored private var followTask: Task<Void, Never>?

    var isShown: Bool { panel != nil }

    func show(_ step: Step) {
        if self.step != step { self.step = step }
        guard panel == nil else { return }
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = FirstClickHostingView(rootView: LocationGuideView(guide: self))
        self.panel = panel
        followTask = Task { await follow() }
    }

    func close() {
        followTask?.cancel()
        followTask = nil
        panel?.orderOut(nil)
        panel = nil
    }

    /// Keeps the panel beside the System Settings window, and closes it once that window goes away.
    private func follow() async {
        var settingsFrame: CGRect?
        var ticks = 0
        while !Task.isCancelled, let panel {
            ticks += 1
            let size = panel.contentView?.fittingSize ?? .zero
            if let frame = Self.settingsWindowFrame() {
                if frame != settingsFrame || panel.frame.size != size {
                    place(panel, size: size, nextTo: frame)
                }
                settingsFrame = frame
                ticks = 0
            } else if settingsFrame != nil, ticks > 8 {
                close()
                return
            } else if settingsFrame == nil, ticks == 12 {
                // System Settings is slow to open, so show the guide on its own meanwhile.
                panel.setContentSize(size)
                panel.center()
                panel.orderFrontRegardless()
            }
            try? await Task.sleep(for: .milliseconds(250))
        }
    }

    /// To the right of the window, else to the left, else over its bottom-right corner.
    private func place(_ panel: NSPanel, size: CGSize, nextTo settings: CGRect) {
        guard let screen = NSScreen.screens.first(where: { $0.frame.intersects(settings) }) ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        var origin = CGPoint(x: settings.maxX, y: settings.maxY - 56 - size.height)
        var edge: HorizontalEdge? = .leading
        if origin.x + size.width > visible.maxX {
            origin.x = settings.minX - size.width
            edge = .trailing
        }
        if origin.x < visible.minX {
            origin = CGPoint(x: settings.maxX - size.width - 16, y: settings.minY + 16)
            edge = nil
        }
        origin.y = min(max(origin.y, visible.minY), visible.maxY - size.height)
        if arrowEdge != edge { arrowEdge = edge }
        panel.setFrame(CGRect(origin: origin, size: size), display: true)
        panel.orderFrontRegardless()
    }

    /// The System Settings window in AppKit screen coordinates. Reading window bounds needs no permission.
    private static func settingsWindowFrame() -> CGRect? {
        guard let settings = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systempreferences").first,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]],
              let mainScreenHeight = NSScreen.screens.first?.frame.height
        else { return nil }
        return windows
            .filter { $0[kCGWindowOwnerPID as String] as? pid_t == settings.processIdentifier && $0[kCGWindowLayer as String] as? Int == 0 }
            .compactMap { window -> CGRect? in
                guard let bounds = window[kCGWindowBounds as String] as? NSDictionary,
                      let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary)
                else { return nil }
                // Window bounds start at the top-left of the main screen; AppKit frames start at its bottom-left.
                return CGRect(x: frame.minX, y: mainScreenHeight - frame.maxY, width: frame.width, height: frame.height)
            }
            .max { $0.width * $0.height < $1.width * $1.height }
    }
}

/// Lets clicks reach the close button, since the panel never becomes key.
private final class FirstClickHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
