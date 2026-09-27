import SwiftUI

/// Recent documents with reading positions, plus reading statistics
/// (today / last 7 days / all time with a mini bar chart).
struct LibrarySheet: View {

    let onOpen: (LibraryEntry) -> Void
    let onClose: () -> Void

    @State private var entries: [LibraryEntry] = []
    @State private var stats = ReadingStatsSnapshot()

    private struct DayStats {
        let key: String
        let label: String
        let words: Int
    }

    var body: some View {
        NavigationStack {
            List {
                statsSection
                documentsSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onClose)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: reload)
    }

    private func reload() {
        StatsStore.flush()
        stats = StatsStore.snapshot()
        entries = LibraryStore.entries()
    }

    // MARK: - Statistics

    private var statsSection: some View {
        Section("Reading statistics") {
            VStack(alignment: .leading, spacing: 10) {
                statRow("Today", todayWords)
                statRow("Last 7 days", weekWords)
                statRow("All time", stats.totalWords)
                weekChart
            }
            .padding(.vertical, 6)
        }
    }

    private func statRow(_ title: String, _ words: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(String(format: String(localized: "words: %d"), words))
                .foregroundColor(WordStage.focusRed)
                .monospacedDigit()
        }
        .font(.system(size: 14))
    }

    private var todayWords: Int {
        stats.byDay[StatsStore.dayKey(for: Date())] ?? 0
    }

    private var weekWords: Int {
        lastSevenDays().reduce(0) { $0 + $1.words }
    }

    private var weekChart: some View {
        let days = lastSevenDays()
        let maxValue = max(days.map(\.words).max() ?? 0, 1)
        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(days, id: \.key) { day in
                VStack(spacing: 4) {
                    Capsule()
                        .fill(day.words > 0 ? WordStage.focusRed : Color(white: 0.18))
                        .frame(height: max(4, CGFloat(day.words) / CGFloat(maxValue) * 36))
                    Text(day.label)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.45))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func lastSevenDays() -> [DayStats] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return (0..<7).reversed().map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let key = StatsStore.dayKey(for: date)
            return DayStats(key: key, label: formatter.string(from: date), words: stats.byDay[key] ?? 0)
        }
    }

    // MARK: - Documents

    private var documentsSection: some View {
        Section("Documents") {
            if entries.isEmpty {
                Text("Documents you import or read appear here with their position.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
            } else {
                ForEach(entries) { entry in
                    Button {
                        onOpen(entry)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text("\(entry.currentIndex) / \(entry.totalWords) \(String(localized: "words")) · \(entry.savedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.45))
                        }
                    }
                }
                .onDelete(perform: deleteEntries)
            }
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        let removedIDs = offsets.map { entries[$0].id }
        removedIDs.forEach(LibraryStore.delete)
        entries = LibraryStore.entries()
    }
}
