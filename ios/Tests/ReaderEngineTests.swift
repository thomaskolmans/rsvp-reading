// Standalone tests for ReaderEngine / SessionStore / ReaderSettings.
// Runs on any Apple host (no simulator needed):
//   swiftc ios/SpeedReader/Core/*.swift ios/Tests/ReaderEngineTests.swift -o /tmp/engine_tests && /tmp/engine_tests
import Foundation

@main
enum EngineTestRunner {

    @MainActor
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

        SessionStore.clear()

        // MARK: - Loading and derived state

        let engine = ReaderEngine()
        expect("default text has 69 words", engine.words.count, 69)
        expect("fresh engine can play", engine.canPlay, true)
        expect("fresh index is 0", engine.currentIndex, 0)
        expect("fresh progress is 0", engine.progressPercent, 0)

        engine.load(text: "alpha beta gamma delta")
        expect("load resets word count", engine.words.count, 4)
        expect("load resets index", engine.currentIndex, 0)

        // MARK: - Navigation

        engine.seek(toIndex: 2)
        expect("seek sets index", engine.currentIndex, 2)
        expect("display index trails by one", engine.displayIndex, 1)
        expect("current word follows index", engine.currentWord, "beta")
        expect("progress percent computed", engine.progressPercent, 50.0)
        expect("time remaining at half", engine.timeRemaining, "0:01") // 2 words left @300 = 0.4s -> 1s

        engine.seek(toIndex: 99)
        expect("seek clamps high", engine.currentIndex, 4)
        engine.seek(toIndex: -5)
        expect("seek clamps low", engine.currentIndex, 0)

        engine.skip(byWords: 3)
        expect("skip forward", engine.currentIndex, 3)
        engine.skip(byWords: -10)
        expect("skip backward clamps", engine.currentIndex, 0)

        // MARK: - Jump parsing ("150" or "50%")

        engine.jump(to: "50%")
        expect("jump percent", engine.currentIndex, 2)
        engine.jump(to: "1")
        expect("jump word number", engine.currentIndex, 1)
        engine.jump(to: "999")
        expect("jump clamps to total", engine.currentIndex, 4)
        engine.jump(to: "abc")
        expect("jump ignores garbage", engine.currentIndex, 4)
        engine.jump(to: "")
        expect("jump ignores empty", engine.currentIndex, 4)
        engine.jump(to: "25%")
        expect("jump percent rounds down", engine.currentIndex, 1)

        // MARK: - WPM adjustment

        engine.adjustWpm(by: 50)
        expect("wpm increases", engine.settings.wordsPerMinute, 350)
        engine.adjustWpm(by: -100)
        expect("wpm decreases", engine.settings.wordsPerMinute, 250)
        engine.settings.wordsPerMinute = 40
        expect("wpm clamped read", engine.settings.clampedWpm(), 50)
        engine.settings.wordsPerMinute = 300

        // MARK: - Frame extraction via engine

        engine.load(text: "one two three four five")
        engine.seek(toIndex: 3)
        engine.settings.frameWordCount = 3
        let frame = engine.currentFrame
        expect("frame subset", frame.subset, ["two", "three", "four"])
        expect("frame offset", frame.centerOffset, 1)
        engine.settings.frameWordCount = 1

        // MARK: - Session persistence roundtrip

        engine.load(text: "lorem ipsum dolor sit amet")
        engine.seek(toIndex: 3)
        engine.settings.wordsPerMinute = 450
        engine.settings.frameWordCount = 3
        expect("save session succeeds", engine.saveSession(), true)

        let loaded = SessionStore.load()
        expect("session text persisted", loaded?.text, "lorem ipsum dolor sit amet")
        expect("session index persisted", loaded?.currentWordIndex, 3)
        expect("session total persisted", loaded?.totalWords, 5)
        expect("session wpm persisted", loaded?.settings.wordsPerMinute, 450)
        expect("session frame count persisted", loaded?.settings.frameWordCount, 3)
        expect("hasSession true", SessionStore.hasSession(), true)

        let other = ReaderEngine()
        expect("other engine starts at default wpm", other.settings.wordsPerMinute, 300)
        if let session = loaded {
            other.restore(session: session)
        }
        expect("restore applies index", other.currentIndex, 3)
        expect("restore applies wpm", other.settings.wordsPerMinute, 450)
        expect("restore applies frame count", other.settings.frameWordCount, 3)
        expect("restore applies words", other.words.count, 5)

        // Out-of-range index is clamped on restore.
        if let session = loaded {
            let clamped = SavedSession(
                text: session.text,
                currentWordIndex: 42,
                totalWords: session.totalWords,
                settings: session.settings,
                savedAt: session.savedAt
            )
            other.restore(session: clamped)
        }
        expect("restore clamps index", other.currentIndex, 5)

        SessionStore.clear()
        expect("clear removes session", SessionStore.hasSession(), false)
        expect("load after clear is nil", SessionStore.load() == nil, true)

        // MARK: - Save refuses empty state

        let empty = ReaderEngine()
        empty.load(text: "   ")
        expect("save refuses empty text", empty.saveSession(), false)

        // MARK: - Settings decode robustness (missing keys -> defaults)

        let partialJSON = #"{"wordsPerMinute": 600}"#
        if let data = partialJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(ReaderSettings.self, from: data) {
            expect("partial decode keeps given key", decoded.wordsPerMinute, 600)
            expect("partial decode defaults fade", decoded.fadeEnabled, true)
            expect("partial decode defaults multiplier", decoded.punctuationPauseMultiplier, 2)
            expect("partial decode defaults frame count", decoded.frameWordCount, 1)
            expect("partial decode defaults font size", decoded.wordFontSizePt, 46)
            expect("partial decode defaults theme", decoded.theme, ReaderThemeKind.black)
            expect("partial decode defaults orientation", decoded.orientation, ReadingOrientation.auto)
            expect("partial decode defaults app language", decoded.appLanguage, AppLanguage.system)
        } else {
            failures += 1
            print("FAIL: partial settings JSON should decode")
        }

        let themedJSON = #"{"theme": "sepia", "wordFontSizePt": 60, "orientation": "landscape"}"#
        if let data = themedJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(ReaderSettings.self, from: data) {
            expect("themed decode reads theme", decoded.theme, ReaderThemeKind.sepia)
            expect("themed decode reads font size", decoded.wordFontSizePt, 60)
            expect("themed decode reads orientation", decoded.orientation, ReadingOrientation.landscape)
            expect("themed decode defaults app language", decoded.appLanguage, AppLanguage.system)
        } else {
            failures += 1
            print("FAIL: themed settings JSON should decode")
        }

        // Roundtrip: settings with new fields survive encode/decode.
        var customized = ReaderSettings()
        customized.theme = .navy
        customized.wordFontSizePt = 34
        customized.orientation = .portrait
        customized.appLanguage = .english
        if let data = try? JSONEncoder().encode(customized),
           let decoded = try? JSONDecoder().decode(ReaderSettings.self, from: data) {
            expect("settings roundtrip theme", decoded.theme, .navy)
            expect("settings roundtrip font size", decoded.wordFontSizePt, 34)
            expect("settings roundtrip orientation", decoded.orientation, .portrait)
            expect("settings roundtrip app language", decoded.appLanguage, .english)
        } else {
            failures += 1
            print("FAIL: settings roundtrip failed")
        }

        // MARK: - Transport behavior

        let transport = ReaderEngine()
        transport.load(text: "a b c")

        transport.togglePlayPause() // stopped -> playing
        expect("toggle starts playback", transport.isPlaying, true)
        transport.togglePlayPause() // playing -> paused
        expect("toggle pauses playback", transport.isPaused, true)
        transport.togglePlayPause() // paused -> resumed
        expect("toggle resumes playback", transport.isPlaying, true)
        expect("resume clears paused flag", transport.isPaused, false)
        transport.stop()
        expect("stop resets index", transport.currentIndex, 0)
        expect("stop clears flags", transport.isPlaying || transport.isPaused, false)

        transport.seek(toIndex: 3) // at the very end
        transport.start()
        expect("start at end restarts from zero", transport.currentIndex, 0)
        expect("start at end begins playback", transport.isPlaying, true)
        transport.stop()

        // MARK: - Repeat sentence

        let sentences = ReaderEngine()
        sentences.load(text: "Alpha beta gamma. Delta epsilon. Zeta eta theta.")
        // Words: 0 Alpha, 1 beta, 2 gamma., 3 Delta, 4 epsilon., 5 Zeta, 6 eta, 7 theta.
        sentences.seek(toIndex: 4) // displaying word 3 "Delta" (sentence start)
        sentences.repeatSentence()
        expect("repeat at sentence start stays", sentences.currentIndex, 3)
        sentences.seek(toIndex: 5) // displaying word 4 "epsilon."
        sentences.repeatSentence()
        expect("repeat rewinds to sentence start", sentences.currentIndex, 3)
        sentences.seek(toIndex: 2) // displaying word 1 "beta" (first sentence)
        sentences.repeatSentence()
        expect("repeat in first sentence goes to 0", sentences.currentIndex, 0)
        sentences.seek(toIndex: 1) // displaying word 0 "Alpha"
        sentences.repeatSentence()
        expect("repeat at text start stays", sentences.currentIndex, 0)

        let emptyEngine = ReaderEngine()
        emptyEngine.load(text: "")
        emptyEngine.repeatSentence()
        expect("repeat on empty text is safe", emptyEngine.currentIndex, 0)

        // MARK: - Result

        if failures == 0 {
            print("All \(passed) engine tests passed.")
            exit(0)
        } else {
            print("\(failures) of \(passed + failures) engine tests FAILED.")
            exit(1)
        }
    }
}
