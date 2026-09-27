import Foundation

/// Aggregated reading statistics: total words read and per-day counters.
struct ReadingStatsSnapshot: Codable, Equatable {
    var totalWords: Int = 0
    var byDay: [String: Int] = [:]

    init(totalWords: Int = 0, byDay: [String: Int] = [:]) {
        self.totalWords = totalWords
        self.byDay = byDay
    }
}

/// Reading-statistics store. Only words actually played back are counted
/// (scrubbing does not count). Writes are batched: `addWordsRead` buffers in
/// memory and flushes to UserDefaults every `flushThreshold` words, so a
/// 600 WPM session does not hit the disk ten times a second.
enum StatsStore {

    private static let storageKey = "speed-reading-stats"
    private static let flushThreshold = 25
    private static let keptDays = 30

    private static var bufferedWords = 0

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func dayKey(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    /// The persisted snapshot only (no in-flight buffer).
    static func load() -> ReadingStatsSnapshot {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(ReadingStatsSnapshot.self, from: data) else {
            return ReadingStatsSnapshot()
        }
        return snapshot
    }

    /// Persisted snapshot plus words counted since the last flush.
    static func snapshot() -> ReadingStatsSnapshot {
        var merged = load()
        guard bufferedWords > 0 else { return merged }
        merged.totalWords += bufferedWords
        merged.byDay[dayKey(for: Date()), default: 0] += bufferedWords
        return merged
    }

    static func addWordsRead(_ count: Int) {
        bufferedWords += count
        if bufferedWords >= flushThreshold {
            flush()
        }
    }

    static func flush() {
        guard bufferedWords > 0 else { return }
        var persisted = load()
        persisted.totalWords += bufferedWords
        persisted.byDay[dayKey(for: Date()), default: 0] += bufferedWords
        write(persisted)
        bufferedWords = 0
    }

    /// Replaces the stored snapshot (import/migration path; also used by tests).
    static func seed(_ snapshot: ReadingStatsSnapshot) {
        write(snapshot)
        bufferedWords = 0
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        bufferedWords = 0
    }

    // MARK: - Persistence

    private static func write(_ snapshot: ReadingStatsSnapshot) {
        if let data = try? JSONEncoder().encode(trim(snapshot)) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Drops daily buckets older than `keptDays`; totals are preserved.
    private static func trim(_ snapshot: ReadingStatsSnapshot) -> ReadingStatsSnapshot {
        let cutoff = dayKey(for: Date().addingTimeInterval(-Double(keptDays) * 86_400))
        var trimmed = snapshot
        trimmed.byDay = snapshot.byDay.filter { $0.key >= cutoff }
        return trimmed
    }
}
