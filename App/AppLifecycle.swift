import AppKit
import SwiftUI

/// Owns the menu bar item. It uses NSPopover rather than MenuBarExtra because the panel has to
/// stay up, or come back, while macOS shows its own location and password dialogs.
@MainActor
final class AppLifecycle: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let model = PasswordModel()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var clickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "qrcode", accessibilityDescription: "WiFi QR")
        item.button?.target = self
        item.button?.action = #selector(togglePopover)
        statusItem = item

        let host = NSHostingController(rootView: PasswordPanel(model: model))
        host.sizingOptions = .preferredContentSize
        popover.contentViewController = host
        popover.behavior = .applicationDefined
        popover.delegate = self
        model.onResult = { [weak self] in self?.showPopover() }
    }

    @objc private func togglePopover() {
        if popover.isShown { popover.performClose(nil) } else { showPopover() }
    }

    private func showPopover() {
        guard !popover.isShown, let button = statusItem?.button else { return }
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // Close on clicks in other apps, but not while the user is answering a system dialog.
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, !model.isLoading else { return }
            popover.performClose(nil)
        }
    }

    func popoverDidClose(_ notification: Notification) {
        if let clickMonitor { NSEvent.removeMonitor(clickMonitor) }
        clickMonitor = nil
        model.reset()
    }
}
