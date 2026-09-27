// Standalone tests for LibraryStore and StatsStore.
// Build & run (macOS host):
//   swiftc ios/SpeedReader/Core/LibraryStore.swift ios/SpeedReader/Core/StatsStore.swift \
//          ios/Tests/LibraryStatsTests.swift -o /tmp/library_tests && /tmp/library_tests
import Foundation

@main
enum LibraryStatsTestRunner {

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

        LibraryStore.clear()
        StatsStore.clear()

        // MARK: - Library: titles

        expect("title from first sentence",
               LibraryStore.makeTitle(from: "First sentence here. Second sentence is much longer and should not be used."),
               "First sentence here.")
        expect("title falls back to trimmed prefix",
               LibraryStore.makeTitle(from: "one two three four five six seven eight nine ten eleven twelve thirteen"),
               "one two three four five six seven eight nine ten eleven")
        expect("title of empty text", LibraryStore.makeTitle(from: "   "), "")
        expect("title keeps short text", LibraryStore.makeTitle(from: "Short text."), "Short text.")

        // MARK: - Library: upsert and dedupe

        LibraryStore.upsert(text: "Alpha beta gamma.", title: nil, currentIndex: 2, totalWords: 3)
        var entries = LibraryStore.entries()
        expect("upsert inserts one entry", entries.count, 1)
        expect("entry title generated from text", entries.first?.title, "Alpha beta gamma.")
        expect("entry position stored", entries.first?.currentIndex, 2)

        LibraryStore.upsert(text: "Alpha beta gamma.", title: "Custom title", currentIndex: 3, totalWords: 3)
        entries = LibraryStore.entries()
        expect("same text deduplicates", entries.count, 1)
        expect("dedupe updates position", entries.first?.currentIndex, 3)
        expect("dedupe keeps custom title", entries.first?.title, "Custom title")

        LibraryStore.upsert(text: "Different document entirely.", title: nil, currentIndex: 0, totalWords: 3)
        entries = LibraryStore.entries()
        expect("distinct text adds entry", entries.count, 2)
        expect("entries sorted newest first", entries.first?.title, "Different document entirely.")

        // MARK: - Library: cap and delete

        for index in 0..<25 {
            LibraryStore.upsert(
                text: "Filler document number \(index) with unique content.",
                title: "Filler \(index)",
                currentIndex: 0,
                totalWords: 6
            )
        }
        entries = LibraryStore.entries()
        expect("library capped at 20 entries", entries.count, 20)
        expect("oldest entries evicted", entries.contains { $0.title == "Alpha beta gamma." }, false)
        expect("newest filler kept", entries.first?.title, "Filler 24")

        let victimID = entries.first!.id
        LibraryStore.delete(id: victimID)
        entries = LibraryStore.entries()
        expect("delete removes entry", entries.contains { $0.id == victimID }, false)
        expect("delete leaves others", entries.count, 19)

        LibraryStore.clear()
        expect("clear empties library", LibraryStore.entries().count, 0)

        // MARK: - Stats: buffering and flush threshold

        StatsStore.addWordsRead(24)
        expect("below threshold not persisted", StatsStore.load().totalWords, 0)
        StatsStore.addWordsRead(1)
        expect("threshold triggers flush", StatsStore.load().totalWords, 25)

        let snapshot = StatsStore.snapshot()
        expect("snapshot includes buffer", snapshot.totalWords >= 25, true)
        let todayKey = StatsStore.dayKey(for: Date())
        expect("words counted under today", snapshot.byDay[todayKey] ?? 0 >= 25, true)

        // MARK: - Stats: flush merges pending buffer

        StatsStore.addWordsRead(7)
        StatsStore.flush()
        expect("flush persists buffer", StatsStore.load().totalWords, 32)
        StatsStore.addWordsRead(5)
        expect("snapshot adds buffer on top", StatsStore.snapshot().totalWords, 37)
        StatsStore.flush()

        // MARK: - Stats: daily aggregation

        let before = StatsStore.load().byDay[todayKey] ?? 0
        StatsStore.addWordsRead(3)
        StatsStore.flush()
        let after = StatsStore.load().byDay[todayKey] ?? 0
        expect("same-day reads aggregate", after, before + 3)

        // MARK: - Stats: 30-day trim

        StatsStore.seed(
            ReadingStatsSnapshot(
                totalWords: 10,
                byDay: ["2000-01-01": 4, todayKey: 6]
            )
        )
        let trimmed = StatsStore.load()
        expect("old days trimmed", trimmed.byDay["2000-01-01"] == nil, true)
        expect("recent days kept", trimmed.byDay[todayKey], 6)
        expect("total preserved on trim", trimmed.totalWords, 10)

        StatsStore.clear()
        expect("stats cleared", StatsStore.load().totalWords, 0)

        // MARK: - Result

        if failures == 0 {
            print("All \(passed) library/stats tests passed.")
            exit(0)
        } else {
            print("\(failures) of \(passed + failures) library/stats tests FAILED.")
            exit(1)
        }
    }
}
