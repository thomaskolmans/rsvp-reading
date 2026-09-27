import CryptoKit
import Foundation

/// A document saved in the reading library with its last position.
struct LibraryEntry: Codable, Identifiable, Equatable {
    /// SHA-256 of the text — re-importing the same document updates, not duplicates.
    let id: String
    var title: String
    let text: String
    var currentIndex: Int
    var totalWords: Int
    var savedAt: Date
}

/// Recent-documents library backed by UserDefaults.
/// Entries are deduplicated by text hash, capped, and sorted newest-first.
enum LibraryStore {

    static let entryLimit = 20
    private static let storageKey = "speed-library"
    private static let titleLimit = 55
    private static let sentenceEnders: Set<Character> = [".", "!", "?", "…"]

    static func entries() -> [LibraryEntry] {
        load().sorted { $0.savedAt > $1.savedAt }
    }

    static func upsert(text: String, title: String?, currentIndex: Int, totalWords: Int) {
        var list = load()
        let id = identifier(for: text)
        let now = Date()

        if let index = list.firstIndex(where: { $0.id == id }) {
            var entry = list.remove(at: index)
            entry.currentIndex = currentIndex
            entry.totalWords = totalWords
            entry.savedAt = now
            if let title, !title.isEmpty { entry.title = title }
            list.insert(entry, at: 0)
        } else {
            let entry = LibraryEntry(
                id: id,
                title: title ?? makeTitle(from: text),
                text: text,
                currentIndex: currentIndex,
                totalWords: totalWords,
                savedAt: now
            )
            list.insert(entry, at: 0)
        }
        save(Array(list.prefix(entryLimit)))
    }

    static func delete(id: String) {
        save(load().filter { $0.id != id })
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    static func identifier(for text: String) -> String {
        SHA256.hash(data: Data(text.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    /// Human title: the first sentence when it is short enough, otherwise the
    /// longest whole-word prefix that fits.
    static func makeTitle(from text: String) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return "" }

        if let end = cleaned.firstIndex(where: { sentenceEnders.contains($0) }) {
            let sentence = String(cleaned[...end])
            if sentence.count <= titleLimit { return sentence }
        }

        var result = ""
        for word in cleaned.split(separator: " ", omittingEmptySubsequences: true) {
            let candidate = result.isEmpty ? String(word) : result + " " + word
            if candidate.count > titleLimit { break }
            result = candidate
        }
        return result
    }

    // MARK: - Persistence

    private static func load() -> [LibraryEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([LibraryEntry].self, from: data)) ?? []
    }

    private static func save(_ list: [LibraryEntry]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
