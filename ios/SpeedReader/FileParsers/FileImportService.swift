import Foundation
import UniformTypeIdentifiers

enum FileImportError: Error, LocalizedError {
    case unsupportedType(String)
    case unreadable(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedType(let name):
            return String(localized: "Unsupported file type: \(name). Use PDF, EPUB, TXT, FB2 or DOCX.")
        case .unreadable(let kind):
            return String(localized: "Could not read the \(kind) file.")
        }
    }
}

/// Detects file type and extracts text (PDF / EPUB / TXT / FB2 / DOCX),
/// the native counterpart of the web app's parseFile().
enum FileImportService {

    static var supportedTypes: [UTType] {
        [
            .pdf,
            .plainText,
            UTType(filenameExtension: "epub") ?? UTType(exportedAs: "org.idpf.epub-container"),
            UTType(filenameExtension: "fb2") ?? UTType(exportedAs: "org.fictionbook.fb2"),
            UTType(filenameExtension: "docx") ?? UTType(exportedAs: "org.openxmlformats.wordprocessingml.document"),
        ]
    }

    /// Extracts text from a user-picked file URL (handles security-scoped access).
    static func importText(from url: URL) throws -> String {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let text: String
        switch url.pathExtension.lowercased() {
        case "pdf":
            text = try PdfTextExtractor.extractText(from: url)
        case "epub":
            text = try EpubParser.extractText(from: try Data(contentsOf: url))
        case "fb2":
            guard let parsed = Fb2Parser.extractText(from: try Data(contentsOf: url)),
                  !parsed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw FileImportError.unreadable("FB2")
            }
            text = parsed
        case "docx":
            text = try DocxParser.extractText(from: try Data(contentsOf: url))
        case "txt", "text":
            guard let decoded = TextCleaner.decodeText(try Data(contentsOf: url)) else {
                throw FileImportError.unreadable("TXT")
            }
            text = decoded
        default:
            throw FileImportError.unsupportedType(url.lastPathComponent)
        }

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FileImportError.unreadable(url.lastPathComponent)
        }
        return text
    }
}
