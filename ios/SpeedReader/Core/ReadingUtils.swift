import Foundation

/// Pure speed-reading logic, a 1:1 port of the web app's `src/lib/reading-utils.js`.
/// Only depends on Foundation so it can be unit-tested on any Apple host.
enum ReadingUtils {

    // MARK: - Text parsing

    /// Split raw text into words (any Unicode whitespace, no empty tokens).
    static func parseText(_ text: String?) -> [String] {
        guard let text, !text.isEmpty else { return [] }
        return text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }

    // MARK: - Optimal Recognition Point (ORP)

    /// Letter-count ORP position for a word (punctuation ignored when counting).
    /// The middle letter is chosen so the highlight stays centered on screen.
    static func orpIndex(_ word: String?) -> Int {
        guard let word, !word.isEmpty else { return 0 }
        let letterCount = word.filter(\.isLetter).count
        guard letterCount > 1 else { return 0 }
        return (letterCount - 1) / 2
    }

    /// Actual character index of the ORP, skipping leading punctuation.
    static func actualOrpIndex(_ word: String?) -> Int {
        guard let word, !word.isEmpty else { return 0 }
        let target = orpIndex(word)
        let chars = Array(word)
        var letterCount = 0
        for (index, char) in chars.enumerated() where char.isLetter {
            if letterCount == target { return index }
            letterCount += 1
        }
        return min(target, chars.count - 1)
    }

    /// The three display parts of a word: before / ORP letter / after.
    static func splitWordForDisplay(_ word: String?) -> WordParts {
        guard let word, !word.isEmpty else { return WordParts(before: "", orp: "", after: "") }
        let chars = Array(word)
        guard chars.indices.contains(actualOrpIndex(word)) else {
            return WordParts(before: "", orp: "", after: "")
        }
        let orpIndex = actualOrpIndex(word)
        return WordParts(
            before: String(chars[0..<orpIndex]),
            orp: String(chars[orpIndex]),
            after: String(chars[(orpIndex + 1)...])
        )
    }

    /// Detect Hebrew/Arabic and other RTL scripts (same ranges as the web app).
    static func isRightToLeft(_ word: String) -> Bool {
        word.unicodeScalars.contains { scalar in
            let v = scalar.value
            return (0x0591...0x07FF).contains(v)
                || (0xFB1D...0xFDFD).contains(v)
                || (0xFE70...0xFEFC).contains(v)
        }
    }

    // MARK: - Timing

    /// Display delay (ms) for a word, mirroring `getWordDelay` from the web app.
    static func wordDelay(
        for word: String?,
        wpm: Int,
        pauseOnPunctuation: Bool = true,
        punctuationMultiplier: Double = 2,
        wordLengthExtraPercent: Double = 0
    ) -> Double {
        guard wpm > 0 else { return 200 }
        let baseDelay = 60_000.0 / Double(wpm)
        guard let word, !word.isEmpty else { return baseDelay }

        var delay = baseDelay
        if wordLengthExtraPercent > 0, word.count >= 12 {
            let extraPoints = (wordLengthExtraPercent / 100) * Double(word.count - 12)
            delay *= 1 + extraPoints
        }

        if pauseOnPunctuation {
            let last = word.last.map(String.init) ?? ""
            if ".!?;:".contains(last) { return delay * punctuationMultiplier }
            if last == "," { return delay * 1.5 }
        }
        return delay
    }

    /// Remaining reading time formatted as M:SS.
    static func formatTimeRemaining(remainingWords: Int, wpm: Int) -> String {
        guard remainingWords > 0, wpm > 0 else { return "0:00" }
        let seconds = Int(ceil(Double(remainingWords) / Double(wpm) * 60))
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }

    /// Whether the reader should take a comprehension pause at `wordIndex`.
    static func shouldPauseAtWord(_ wordIndex: Int, every pauseAfterWords: Int) -> Bool {
        guard pauseAfterWords > 0, wordIndex > 0 else { return false }
        return wordIndex % pauseAfterWords == 0
    }

    // MARK: - Multi-word frames

    /// Words around `centerIndex`, mirroring `extractWordFrame` from the web app.
    static func extractWordFrame(from allWords: [String], centerIndex: Int, frameSize: Int) -> WordFrame {
        let fallback = WordFrame(
            subset: [allWords.indices.contains(centerIndex) ? allWords[centerIndex] : ""],
            centerOffset: 0
        )
        guard !allWords.isEmpty, frameSize > 1, centerIndex < allWords.count else { return fallback }

        let radius = frameSize / 2
        let leftBound = max(0, centerIndex - radius)
        let rightBound = min(allWords.count, centerIndex + radius + 1)
        let subset = Array(allWords[leftBound..<rightBound])
        return WordFrame(subset: subset, centerOffset: centerIndex - leftBound)
    }

    // MARK: - Sentences

    static let sentenceEnders: Set<Character> = [".", "!", "?", "…"]

    /// Index of the first word of the sentence containing the word at `displayIndex`
    /// (used by "repeat sentence"). If the shown word itself ends a sentence,
    /// the start of that sentence is returned.
    static func sentenceStartIndex(words: [String], before displayIndex: Int) -> Int {
        guard !words.isEmpty else { return 0 }
        let clamped = min(max(0, displayIndex), words.count - 1)
        var index = clamped - 1
        while index >= 0 {
            if let last = words[index].last, sentenceEnders.contains(last) {
                return index + 1
            }
            index -= 1
        }
        return 0
    }

    // MARK: - Percentage mapping (progress-storage.js parity)

    static func percentageToWordIndex(_ percentage: Double, totalWords: Int) -> Int {
        guard totalWords > 0 else { return 0 }
        let clamped = min(100, max(0, percentage))
        return Int(floor((clamped / 100) * Double(totalWords)))
    }

    static func wordIndexToPercentage(_ wordIndex: Int, totalWords: Int) -> Int {
        guard totalWords > 0 else { return 0 }
        return Int((Double(wordIndex) / Double(totalWords)) * 100)
    }
}

/// before / ORP letter / after decomposition used by the display view.
struct WordParts: Equatable {
    let before: String
    let orp: String
    let after: String
}

/// A window of words with the highlighted word's offset inside it.
struct WordFrame: Equatable {
    let subset: [String]
    let centerOffset: Int
}
