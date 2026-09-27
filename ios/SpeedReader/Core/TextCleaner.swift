import Foundation

/// Text normalization shared by the PDF/EPUB extractors,
/// a port of `cleanText` from the web app's file-parsers.js.
enum TextCleaner {

    static func clean(_ text: String) -> String {
        let collapsed = text.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        let deduped = collapsed.replacingOccurrences(
            of: #"([.!?])\1+"#,
            with: "$1",
            options: .regularExpression
        )
        return deduped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Decodes raw document bytes: strict UTF-8 first, then Windows-1251
    /// (the common legacy encoding for Russian TXT and FB2 files).
    static func decodeText(_ data: Data) -> String? {
        if let utf8 = String(data: data, encoding: .utf8) { return utf8 }
        return String(data: data, encoding: .windowsCP1251)
    }
}
