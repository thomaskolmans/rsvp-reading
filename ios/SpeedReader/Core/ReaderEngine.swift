import Foundation
import SwiftUI

/// Playback engine replicating App.svelte's timer logic:
/// `currentIndex` is the *next word pointer*; the visible word is `words[currentIndex - 1]`.
@MainActor
final class ReaderEngine: ObservableObject {

    static let englishDefaultText = """
    Focused reading is a skill of attention, not just speed. When words appear one at a time at a fixed point on the screen, your eyes stop scanning and your mind settles into a steady rhythm. Start slower than feels comfortable. Let the red letter anchor your gaze. Trust the rhythm even when it feels fast. Speed is a habit, and habits are built one word at a time.
    """

    static let russianDefaultText = """
    Скорочтение — это навык внимания, а не просто скорость. Когда слова появляются по одному в одной точке экрана, глаза перестают бегать по строке, и ум входит в ровный ритм. Начинайте медленнее, чем кажется удобно. Пусть красная буква удерживает взгляд. Доверяйтесь ритму, даже когда он кажется быстрым. Скорость — это привычка, а привычки строятся по одному слову за раз.
    """

    /// Resolves `.system` to the language the UI is actually showing
    /// (AppleLanguages override, then the device language).
    static func effectiveLanguage(_ language: AppLanguage) -> AppLanguage {
        guard language == .system else { return language }
        // Probe the active UI language with a key whose Russian translation
        // differs from the English source string.
        return String(localized: "Play") == "Читать" ? .russian : .english
    }

    /// The base text shown for a fresh session, localized to the app language
    /// (`.system` follows the device language). Mirrors web `getDefaultText`.
    static func defaultText(forLanguage: AppLanguage = .system) -> String {
        return effectiveLanguage(forLanguage) == .russian ? russianDefaultText : englishDefaultText
    }

    // MARK: - State

    @Published private(set) var sourceText: String = ReaderEngine.defaultText()
    @Published private(set) var words: [String] = []
    /// Next-word pointer; 0 means "before the first word".
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var isPaused = false
    @Published var settings = ReaderSettings()
    /// Bumped every time playback reaches the end of the text (drives the finish haptic).
    @Published private(set) var completionCount = 0

    private var playbackTask: Task<Void, Never>?

    // MARK: - Derived state

    var isFocusMode: Bool { isPlaying || isPaused }

    var displayIndex: Int { max(0, currentIndex - 1) }

    var currentWord: String {
        guard words.indices.contains(displayIndex) else { return "" }
        return words[displayIndex]
    }

    var currentFrame: WordFrame {
        ReadingUtils.extractWordFrame(
            from: words,
            centerIndex: max(0, currentIndex - 1),
            frameSize: settings.frameWordCount
        )
    }

    var progressPercent: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentIndex) / Double(words.count) * 100
    }

    var timeRemaining: String {
        ReadingUtils.formatTimeRemaining(remainingWords: words.count - currentIndex, wpm: settings.wordsPerMinute)
    }

    var canPlay: Bool { !words.isEmpty }

    // MARK: - Loading

    init() {
        load(text: ReaderEngine.defaultText())
    }

    func load(text: String) {
        stopPlaybackTask()
        sourceText = text
        words = ReadingUtils.parseText(text)
        currentIndex = 0
        isPlaying = false
        isPaused = false
    }

    // MARK: - Transport (web parity)

    func start() {
        guard canPlay else { return }
        // Expected behavior when pressing Play at the end: start over.
        if currentIndex >= words.count {
            currentIndex = 0
        }
        isPlaying = true
        isPaused = false
        spawnLoop()
    }

    func pause() {
        stopPlaybackTask()
        isPlaying = false
        isPaused = true
    }

    func resume() {
        guard currentIndex < words.count else { return }
        isPlaying = true
        isPaused = false
        spawnLoop()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else if isPaused {
            resume()
        } else {
            start()
        }
    }

    func stop() {
        stopPlaybackTask()
        isPlaying = false
        isPaused = false
        currentIndex = 0
    }

    func restart() {
        stop()
        start()
    }

    // MARK: - Navigation

    func seek(toIndex index: Int) {
        guard !words.isEmpty else { return }
        currentIndex = min(max(0, index), words.count)
    }

    func seek(toPercent percentage: Double) {
        seek(toIndex: ReadingUtils.percentageToWordIndex(percentage, totalWords: words.count))
    }

    func skip(byWords wordsToSkip: Int) {
        seek(toIndex: currentIndex + wordsToSkip)
    }

    /// Rewind to the first word of the sentence currently on screen.
    /// Safe during playback: the pending word simply becomes the sentence start.
    func repeatSentence() {
        guard !words.isEmpty else { return }
        seek(toIndex: ReadingUtils.sentenceStartIndex(words: words, before: displayIndex))
    }

    /// Parses "150" (word number) or "50%" (percentage), mirroring `jumpToWord`.
    func jump(to rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !words.isEmpty else { return }

        if trimmed.hasSuffix("%") {
            let percent = Double(trimmed.dropLast())
            if let percent { seek(toPercent: percent) }
        } else if let number = Int(trimmed) {
            seek(toIndex: number)
        }
    }

    func adjustWpm(by delta: Int) {
        settings.wordsPerMinute = min(
            max(settings.wordsPerMinute + delta, ReaderSettings.wpmRange.lowerBound),
            ReaderSettings.wpmRange.upperBound
        )
    }

    // MARK: - Session persistence

    @discardableResult
    func saveSession() -> Bool {
        guard !words.isEmpty else { return false }
        let session = SavedSession(
            text: sourceText,
            currentWordIndex: currentIndex,
            totalWords: words.count,
            settings: settings,
            savedAt: Date()
        )
        return SessionStore.save(session)
    }

    func restore(session: SavedSession) {
        load(text: session.text)
        currentIndex = min(max(0, session.currentWordIndex), words.count)
        settings = session.settings
    }

    // MARK: - Playback loop

    private func spawnLoop() {
        stopPlaybackTask()
        playbackTask = Task { [weak self] in
            await self?.playbackLoop()
        }
    }

    private func playbackLoop() async {
        while isPlaying, currentIndex < words.count {
            if ReadingUtils.shouldPauseAtWord(currentIndex, every: settings.pauseAfterWords) {
                if await sleepMilliseconds(settings.pauseDurationMs) == .cancelled { return }
                guard isPlaying else { return }
            }

            currentIndex += 1
            StatsStore.addWordsRead(1) // only played-back words count as read
            let shownWord = words[currentIndex - 1]
            let delay = ReadingUtils.wordDelay(
                for: shownWord,
                wpm: settings.wordsPerMinute,
                pauseOnPunctuation: settings.pauseOnPunctuation,
                punctuationMultiplier: settings.punctuationPauseMultiplier,
                wordLengthExtraPercent: Double(settings.wordLengthWPMMultiplier)
            )

            if await sleepMilliseconds(Int(delay)) == .cancelled { return }
        }

        if isPlaying, currentIndex >= words.count {
            stopPlaybackTask()
            isPlaying = false
            isPaused = false
            currentIndex = 0
            completionCount += 1
        }
    }

    private enum SleepOutcome {
        case completed
        case cancelled
    }

    private func sleepMilliseconds(_ milliseconds: Int) async -> SleepOutcome {
        do {
            try await Task.sleep(nanoseconds: UInt64(max(0, milliseconds)) * 1_000_000)
            return .completed
        } catch {
            return .cancelled
        }
    }

    private func stopPlaybackTask() {
        playbackTask?.cancel()
        playbackTask = nil
    }
}
