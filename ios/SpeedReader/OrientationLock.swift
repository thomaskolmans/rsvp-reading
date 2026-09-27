import UIKit

/// Application delegate that enforces the reading-orientation preference.
/// SwiftUI has no supported orientation lock, so the classic
/// `supportedInterfaceOrientationsFor` route is used.
final class OrientationLock: NSObject, UIApplicationDelegate {

    private(set) static var mask: UIInterfaceOrientationMask = .allButUpsideDown

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        Self.mask
    }

    /// Applies the preference immediately (rotates the current scene when needed).
    static func apply(_ orientation: ReadingOrientation) {
        switch orientation {
        case .auto:
            mask = .allButUpsideDown
        case .portrait:
            mask = .portrait
        case .landscape:
            mask = [.landscapeLeft, .landscapeRight]
        }

        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            scene.windows.forEach { $0.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations() }
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
        }
    }
}
