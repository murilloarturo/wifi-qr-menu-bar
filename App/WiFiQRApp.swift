import SwiftUI

@main @MainActor
struct WiFiQRApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycle.self) private var lifecycle

    var body: some Scene {
        // The menu bar item and its panel live in AppLifecycle.
        Settings { EmptyView() }
    }
}
