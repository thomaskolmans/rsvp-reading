import Foundation

/// Persists reading sessions in UserDefaults (localStorage parity from the web app).
enum SessionStore {

    private static let storageKey = "speed-reading-session"

    @discardableResult
    static func save(_ session: SavedSession) -> Bool {
        guard let data = try? JSONEncoder().encode(session) else { return false }
        UserDefaults.standard.set(data, forKey: storageKey)
        return true
    }

    static func load() -> SavedSession? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(SavedSession.self, from: data)
    }

    static func hasSession() -> Bool {
        UserDefaults.standard.data(forKey: storageKey) != nil
    }

    @discardableResult
    static func clear() -> Bool {
        UserDefaults.standard.removeObject(forKey: storageKey)
        return true
    }
}
