import SwiftUI

@main
struct SpeedReaderApp: App {
    @UIApplicationDelegateAdaptor(OrientationLock.self) private var orientationLock

    init() {
        // Must run before the first localized string is resolved.
        LanguageOverride.apply()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
