import Foundation

/// Reading-screen background themes (color mapping lives in ThemeColors.swift).
enum ReaderThemeKind: String, Codable, CaseIterable {
    case black
    case charcoal
    case navy
    case sepia
    case white
}

/// Interface-orientation preference for reading.
enum ReadingOrientation: String, Codable, CaseIterable {
    case auto
    case portrait
    case landscape
}

/// In-app UI language choice; .system follows the device language.
enum AppLanguage: String, Codable, CaseIterable {
    case system
    case english
    case russian
}

/// Reader settings, persisted as part of a saved session.
/// Defaults mirror the web app's App.svelte initial values.
struct ReaderSettings: Codable, Equatable {
    var wordsPerMinute: Int = 300
    var fadeEnabled: Bool = true
    var fadeDurationMs: Int = 150
    var pauseOnPunctuation: Bool = true
    var punctuationPauseMultiplier: Double = 2
    var wordLengthWPMMultiplier: Int = 5
    var pauseAfterWords: Int = 0
    var pauseDurationMs: Int = 500
    var frameWordCount: Int = 1
    var wordFontSizePt: Int = 46
    var theme: ReaderThemeKind = .black
    var orientation: ReadingOrientation = .auto
    var appLanguage: AppLanguage = .system

    enum CodingKeys: String, CodingKey {
        case wordsPerMinute
        case fadeEnabled
        case fadeDurationMs
        case pauseOnPunctuation
        case punctuationPauseMultiplier
        case wordLengthWPMMultiplier
        case pauseAfterWords
        case pauseDurationMs
        case frameWordCount
        case wordFontSizePt
        case theme
        case orientation
        case appLanguage
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        wordsPerMinute = try container.decodeIfPresent(Int.self, forKey: .wordsPerMinute) ?? wordsPerMinute
        fadeEnabled = try container.decodeIfPresent(Bool.self, forKey: .fadeEnabled) ?? fadeEnabled
        fadeDurationMs = try container.decodeIfPresent(Int.self, forKey: .fadeDurationMs) ?? fadeDurationMs
        pauseOnPunctuation = try container.decodeIfPresent(Bool.self, forKey: .pauseOnPunctuation) ?? pauseOnPunctuation
        punctuationPauseMultiplier = try container.decodeIfPresent(Double.self, forKey: .punctuationPauseMultiplier) ?? punctuationPauseMultiplier
        wordLengthWPMMultiplier = try container.decodeIfPresent(Int.self, forKey: .wordLengthWPMMultiplier) ?? wordLengthWPMMultiplier
        pauseAfterWords = try container.decodeIfPresent(Int.self, forKey: .pauseAfterWords) ?? pauseAfterWords
        pauseDurationMs = try container.decodeIfPresent(Int.self, forKey: .pauseDurationMs) ?? pauseDurationMs
        frameWordCount = try container.decodeIfPresent(Int.self, forKey: .frameWordCount) ?? frameWordCount
        wordFontSizePt = try container.decodeIfPresent(Int.self, forKey: .wordFontSizePt) ?? wordFontSizePt
        theme = try container.decodeIfPresent(ReaderThemeKind.self, forKey: .theme) ?? theme
        orientation = try container.decodeIfPresent(ReadingOrientation.self, forKey: .orientation) ?? orientation
        appLanguage = try container.decodeIfPresent(AppLanguage.self, forKey: .appLanguage) ?? appLanguage
    }

    static let wpmRange = 50...1000
    static let wpmStep = 25
    static let wpmPresets = [200, 300, 400, 500]
    static let fontSizeRange = 28...64

    func clampedWpm() -> Int {
        min(max(wordsPerMinute, Self.wpmRange.lowerBound), Self.wpmRange.upperBound)
    }
}

/// A persisted reading session (progress-storage.js parity).
struct SavedSession: Codable, Equatable {
    let text: String
    let currentWordIndex: Int
    let totalWords: Int
    let settings: ReaderSettings
    let savedAt: Date

    init(text: String, currentWordIndex: Int, totalWords: Int, settings: ReaderSettings, savedAt: Date) {
        self.text = text
        self.currentWordIndex = currentWordIndex
        self.totalWords = totalWords
        self.settings = settings
        self.savedAt = savedAt
    }
}
