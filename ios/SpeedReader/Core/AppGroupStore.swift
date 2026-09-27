import Foundation

/// Hand-off channel between the Share Extension and the containing app,
/// backed by the shared App Group defaults (`group.app.speedreader`).
/// The extension writes the shared text; the app consumes it on activation.
enum AppGroupStore {

    static let suiteName = "group.app.speedreader"

    private static let textKey = "pending-shared-text"
    private static let titleKey = "pending-shared-title"
    private static let dateKey = "pending-shared-at"

    struct PendingShare: Equatable {
        let text: String
        let title: String?
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    /// Called by the Share Extension with the extracted text.
    static func savePending(text: String, title: String?) {
        guard let store = defaults else { return }
        store.set(text, forKey: textKey)
        if let title, !title.isEmpty {
            store.set(title, forKey: titleKey)
        } else {
            store.removeObject(forKey: titleKey)
        }
        store.set(Date().timeIntervalSince1970, forKey: dateKey)
    }

    /// Returns and clears the pending share (nil when nothing is waiting
    /// or the payload is whitespace-only).
    static func takePendingText() -> PendingShare? {
        guard let store = defaults,
              let text = store.string(forKey: textKey),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let share = PendingShare(text: text, title: store.string(forKey: titleKey))
        store.removeObject(forKey: textKey)
        store.removeObject(forKey: titleKey)
        store.removeObject(forKey: dateKey)
        return share
    }
}
