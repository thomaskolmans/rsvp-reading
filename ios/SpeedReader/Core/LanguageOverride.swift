import Foundation

/// In-app language choice (System / English / Русский) that overrides the
/// device language. Writes the AppleLanguages user default before any
/// localized string is resolved, so the choice applies from the next launch.
enum LanguageOverride {
    static let appLanguageKey = "appLanguage"
    static let appleLanguagesKey = "AppleLanguages"

    /// Injectable store for tests; the app always uses .standard.
    static var store: UserDefaults = .standard

    /// Persists the user's choice and applies the override immediately.
    static func set(_ language: AppLanguage) {
        store.set(language.rawValue, forKey: appLanguageKey)
        applyOverride(language)
    }

    /// The choice currently applied for the next launch (.system when none).
    static func current() -> AppLanguage {
        guard let raw = store.string(forKey: appLanguageKey) else { return .system }
        return AppLanguage(rawValue: raw) ?? .system
    }

    /// Reads the stored choice (if any) and rewrites AppleLanguages.
    /// Call before the first localized string is resolved (App.init).
    static func apply() {
        guard let raw = store.string(forKey: appLanguageKey) else { return }
        applyOverride(AppLanguage(rawValue: raw) ?? .system)
    }

    private static func applyOverride(_ language: AppLanguage) {
        switch language {
        case .english: store.set(["en"], forKey: appleLanguagesKey)
        case .russian: store.set(["ru"], forKey: appleLanguagesKey)
        // An absent AppleLanguages key means "follow the device language";
        // an empty array can fall back to the development language instead.
        case .system: store.removeObject(forKey: appleLanguagesKey)
        }
    }
}