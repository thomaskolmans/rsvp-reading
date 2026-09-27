// Standalone test runner for ReadingUtils / TextCleaner / SessionStore helpers.
// Mirrors src/tests/reading-utils.test.js from the web app.
// Build & run (macOS host):
//   swiftc ios/SpeedReader/Core/ReadingUtils.swift ios/SpeedReader/Core/TextCleaner.swift \
//          ios/Tests/ReadingUtilsTests.swift -o /tmp/reading_tests && /tmp/reading_tests
import Foundation

private var failures: Int = 0
private var passed: Int = 0

private func expect<T: Equatable>(_ name: String, _ actual: T, _ expected: T) {
    if actual == expected {
        passed += 1
    } else {
        failures += 1
        print("FAIL: \(name) — expected \(expected), got \(actual)")
    }
}

private func expect(_ name: String, _ actual: Double, _ expected: Double, accuracy: Double) {
    if abs(actual - expected) <= accuracy {
        passed += 1
    } else {
        failures += 1
        print("FAIL: \(name) — expected \(expected), got \(actual)")
    }
}

@main
enum ReadingUtilsTestRunner {
    static func main() {
    // MARK: - parseText

    expect("parseText splits words", ReadingUtils.parseText("Hello world test"), ["Hello", "world", "test"])
    expect("parseText multiple spaces", ReadingUtils.parseText("Hello   world    test"), ["Hello", "world", "test"])
    expect("parseText trims", ReadingUtils.parseText("  Hello world  "), ["Hello", "world"])
    expect("parseText empty", ReadingUtils.parseText(""), [])
    expect("parseText whitespace only", ReadingUtils.parseText("   "), [])
    expect("parseText nil", ReadingUtils.parseText(nil), [])
    expect("parseText newlines and tabs", ReadingUtils.parseText("Hello\nworld\ttest"), ["Hello", "world", "test"])

    // MARK: - getORPIndex

    expect("orp single letter", ReadingUtils.orpIndex("a"), 0)
    expect("orp 'I'", ReadingUtils.orpIndex("I"), 0)
    expect("orp 'to'", ReadingUtils.orpIndex("to"), 0)
    expect("orp 'the' (mid letter)", ReadingUtils.orpIndex("the"), 1)
    expect("orp 'cat'", ReadingUtils.orpIndex("cat"), 1)
    expect("orp 'word' (4 letters)", ReadingUtils.orpIndex("word"), 1)
    expect("orp 'hello' (5 letters)", ReadingUtils.orpIndex("hello"), 2)
    expect("orp 'reading' (7 letters)", ReadingUtils.orpIndex("reading"), 3)
    expect("orp 'beautiful' (9 letters)", ReadingUtils.orpIndex("beautiful"), 4)
    expect("orp 'interesting' (11 letters)", ReadingUtils.orpIndex("interesting"), 5)
    expect("orp 'presentation' (12 letters)", ReadingUtils.orpIndex("presentation"), 5)
    expect("orp 'extraordinarily' (15 letters)", ReadingUtils.orpIndex("extraordinarily"), 7)
    expect("orp ignores apostrophe", ReadingUtils.orpIndex("don't"), 1)
    expect("orp ignores hyphen", ReadingUtils.orpIndex("e-mail"), 2)
    expect("orp empty", ReadingUtils.orpIndex(""), 0)
    expect("orp nil", ReadingUtils.orpIndex(nil), 0)
    // Unicode
    expect("orp 'café'", ReadingUtils.orpIndex("café"), 1)
    expect("orp 'résumé'", ReadingUtils.orpIndex("résumé"), 2)
    expect("orp 'français'", ReadingUtils.orpIndex("français"), 3)
    expect("orp 'niño'", ReadingUtils.orpIndex("niño"), 1)
    expect("orp 'über'", ReadingUtils.orpIndex("über"), 1)
    expect("orp 'мир'", ReadingUtils.orpIndex("мир"), 1)
    expect("orp 'слово'", ReadingUtils.orpIndex("слово"), 2)
    expect("orp 'привет'", ReadingUtils.orpIndex("привет"), 2)
    expect("orp 'λόγος'", ReadingUtils.orpIndex("λόγος"), 2)
    expect("orp 'ελληνικά'", ReadingUtils.orpIndex("ελληνικά"), 3)
    expect("orp '中'", ReadingUtils.orpIndex("中"), 0)
    expect("orp '中国'", ReadingUtils.orpIndex("中国"), 0)
    expect("orp '你好世界'", ReadingUtils.orpIndex("你好世界"), 1)

    // MARK: - getActualORPIndex

    expect("actual orp skips leading quote", ReadingUtils.actualOrpIndex("\"hello"), 3)
    expect("actual orp plain", ReadingUtils.actualOrpIndex("hello"), 2)
    expect("actual orp empty", ReadingUtils.actualOrpIndex(""), 0)

    // MARK: - splitWordForDisplay

    let parts = ReadingUtils.splitWordForDisplay("hello")
    expect("split before", parts.before, "he")
    expect("split orp", parts.orp, "l")
    expect("split after", parts.after, "lo")
    let emptyParts = ReadingUtils.splitWordForDisplay("")
    expect("split empty word", emptyParts.before + emptyParts.orp + emptyParts.after, "")

    // MARK: - getWordDelay

    expect("delay base 300wpm", ReadingUtils.wordDelay(for: "hello", wpm: 300), 200.0)
    expect("delay disabled wpm fallback", ReadingUtils.wordDelay(for: "hello", wpm: 0), 200.0)
    expect("delay sentence punctuation", ReadingUtils.wordDelay(for: "end.", wpm: 300, pauseOnPunctuation: true, punctuationMultiplier: 2), 400.0)
    expect("delay semicolon punctuation", ReadingUtils.wordDelay(for: "end;", wpm: 300, pauseOnPunctuation: true, punctuationMultiplier: 2), 400.0)
    expect("delay comma", ReadingUtils.wordDelay(for: "however,", wpm: 300, pauseOnPunctuation: true, punctuationMultiplier: 2), 300.0)
    expect("delay no punctuation pause", ReadingUtils.wordDelay(for: "end.", wpm: 300, pauseOnPunctuation: false, punctuationMultiplier: 2), 200.0)
    expect("delay long word extra", ReadingUtils.wordDelay(for: "extraordinarily", wpm: 300, wordLengthExtraPercent: 10), 200.0 * 1.3, accuracy: 0.001)
    expect("delay nil word", ReadingUtils.wordDelay(for: nil, wpm: 300), 200.0)

    // MARK: - formatTimeRemaining

    expect("time remaining 300@300", ReadingUtils.formatTimeRemaining(remainingWords: 300, wpm: 300), "1:00")
    expect("time remaining 30@300", ReadingUtils.formatTimeRemaining(remainingWords: 30, wpm: 300), "0:06")
    expect("time remaining zero", ReadingUtils.formatTimeRemaining(remainingWords: 0, wpm: 300), "0:00")
    expect("time remaining bad wpm", ReadingUtils.formatTimeRemaining(remainingWords: 100, wpm: 0), "0:00")
    expect("time remaining rounds up", ReadingUtils.formatTimeRemaining(remainingWords: 1, wpm: 60), "0:01")

    // MARK: - shouldPauseAtWord

    expect("pause at 10 every 10", ReadingUtils.shouldPauseAtWord(10, every: 10), true)
    expect("no pause at 5 every 10", ReadingUtils.shouldPauseAtWord(5, every: 10), false)
    expect("pause disabled when 0", ReadingUtils.shouldPauseAtWord(10, every: 0), false)
    expect("no pause at 0", ReadingUtils.shouldPauseAtWord(0, every: 10), false)

    // MARK: - extractWordFrame

    let frame = ReadingUtils.extractWordFrame(from: ["a", "b", "c", "d", "e"], centerIndex: 2, frameSize: 3)
    expect("frame subset", frame.subset, ["b", "c", "d"])
    expect("frame offset", frame.centerOffset, 1)
    let edgeFrame = ReadingUtils.extractWordFrame(from: ["a", "b"], centerIndex: 0, frameSize: 3)
    expect("frame edge subset", edgeFrame.subset, ["a", "b"])
    expect("frame edge offset", edgeFrame.centerOffset, 0)
    let singleFrame = ReadingUtils.extractWordFrame(from: ["a", "b"], centerIndex: 1, frameSize: 1)
    expect("frame size 1 subset", singleFrame.subset, ["b"])
    expect("frame size 1 offset", singleFrame.centerOffset, 0)

    // MARK: - percentage helpers

    expect("pct→index 50 of 100", ReadingUtils.percentageToWordIndex(50, totalWords: 100), 50)
    expect("pct→index 25 of 200", ReadingUtils.percentageToWordIndex(25, totalWords: 200), 50)
    expect("pct→index clamps high", ReadingUtils.percentageToWordIndex(150, totalWords: 100), 100)
    expect("pct→index clamps low", ReadingUtils.percentageToWordIndex(-10, totalWords: 100), 0)
    expect("pct→index zero total", ReadingUtils.percentageToWordIndex(50, totalWords: 0), 0)
    expect("index→pct 50 of 100", ReadingUtils.wordIndexToPercentage(50, totalWords: 100), 50)
    expect("index→pct 25 of 50", ReadingUtils.wordIndexToPercentage(25, totalWords: 50), 50)
    expect("index→pct zero total", ReadingUtils.wordIndexToPercentage(10, totalWords: 0), 0)

    // MARK: - RTL detection

    expect("rtl hebrew", ReadingUtils.isRightToLeft("שלום"), true)
    expect("rtl arabic", ReadingUtils.isRightToLeft("مرحبا"), true)
    expect("ltr english", ReadingUtils.isRightToLeft("hello"), false)
    expect("ltr cyrillic", ReadingUtils.isRightToLeft("привет"), false)

    // MARK: - Sentence repeat

let sentenceWords = ["One", "two", "three.", "Four", "five", "six.", "Seven", "eight."]
expect("sentence start mid-sentence", ReadingUtils.sentenceStartIndex(words: sentenceWords, before: 4), 3)
expect("sentence start second sentence", ReadingUtils.sentenceStartIndex(words: sentenceWords, before: 5), 3)
expect("sentence start on sentence-ending word", ReadingUtils.sentenceStartIndex(words: sentenceWords, before: 2), 0)
expect("sentence start at text beginning", ReadingUtils.sentenceStartIndex(words: sentenceWords, before: 0), 0)
expect("sentence start of last sentence", ReadingUtils.sentenceStartIndex(words: sentenceWords, before: 7), 6)
expect("sentence start ellipsis", ReadingUtils.sentenceStartIndex(words: ["Wait", "for", "it…", "Now", "go"], before: 4), 3)
expect("sentence start question mark", ReadingUtils.sentenceStartIndex(words: ["Really?", "Yes", "indeed"], before: 2), 1)
expect("sentence start no punctuation", ReadingUtils.sentenceStartIndex(words: ["a", "b", "c"], before: 2), 0)
expect("sentence start empty words", ReadingUtils.sentenceStartIndex(words: [], before: 0), 0)
expect("sentence start clamps beyond end", ReadingUtils.sentenceStartIndex(words: ["Hi", "there."], before: 99), 0)

// MARK: - TextCleaner

    expect("clean collapses whitespace", TextCleaner.clean("a  b\n\nc\t d"), "a b c d")
    expect("clean collapses repeated punctuation", TextCleaner.clean("Wow!!! Really??"), "Wow! Really?")
    expect("clean trims", TextCleaner.clean("  hi  "), "hi")

    // MARK: - Result

    if failures == 0 {
        print("All \(passed) tests passed.")
        exit(0)
    } else {
        print("\(failures) of \(passed + failures) tests FAILED.")
        exit(1)
    }
    }
}
