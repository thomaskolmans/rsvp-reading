// Standalone tests for the in-app language override (AppleLanguages).
// Build & run (macOS host):
//   swiftc ios/SpeedReader/Core/ReaderSettings.swift ios/SpeedReader/Core/LanguageOverride.swift \
//          ios/Tests/LanguageOverrideTests.swift -o /tmp/language_tests && /tmp/language_tests
import Foundation

@main
enum LanguageOverrideTestRunner {
    static func main() {
        var failures = 0
        var passed = 0

        func expect<T: Equatable>(_ name: String, _ actual: T, _ expected: T) {
            if actual == expected {
                passed += 1
            } else {
                failures += 1
                print("FAIL: \(name) — expected \(expected), got \(actual)")
            }
        }

        let suite = "speedreader.language.tests"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        LanguageOverride.store = defaults

        // AppleLanguages is special-cased by cfprefsd: reads fall through to
        // the host's effective language list, so assert on the raw domain
        // storage instead (what the app actually wrote).
        let appleLanguages: () -> [String] = {
            defaults.persistentDomain(forName: suite)?[LanguageOverride.appleLanguagesKey] as? [String] ?? []
        }

        LanguageOverride.set(.english)
        expect("set stores the raw choice", defaults.string(forKey: LanguageOverride.appLanguageKey), "english")
        expect("set applies English", appleLanguages(), ["en"])
        expect("current() reads the stored choice", LanguageOverride.current(), .english)

        LanguageOverride.set(.russian)
        expect("set applies Russian", appleLanguages(), ["ru"])

        LanguageOverride.set(.system)
        expect("system removes the override", appleLanguages(), [])
        expect("current() returns system", LanguageOverride.current(), .system)

        // A stored choice is re-applied on launch.
        defaults.set("english", forKey: LanguageOverride.appLanguageKey)
        defaults.set([], forKey: LanguageOverride.appleLanguagesKey)
        LanguageOverride.apply()
        expect("apply restores English from storage", appleLanguages(), ["en"])

        // No stored choice: AppleLanguages is left untouched.
        defaults.removePersistentDomain(forName: suite)
        defaults.set(["fr"], forKey: LanguageOverride.appleLanguagesKey)
        LanguageOverride.apply()
        expect("apply leaves AppleLanguages alone without a stored choice", appleLanguages(), ["fr"])

        // A stored "system" choice removes a previously applied override.
        defaults.set([], forKey: LanguageOverride.appleLanguagesKey)
        defaults.set("system", forKey: LanguageOverride.appLanguageKey)
        LanguageOverride.apply()
        expect("apply with system removes AppleLanguages", appleLanguages(), [])

        // An unknown stored value falls back to the system language.
        defaults.set("klingon", forKey: LanguageOverride.appLanguageKey)
        LanguageOverride.apply()
        expect("unknown stored value falls back to system", appleLanguages(), [])

        if failures == 0 {
            print("language_tests: all \(passed) assertions passed")
        } else {
            print("language_tests: \(failures) of \(passed + failures) assertions failed")
            exit(1)
        }
    }
}