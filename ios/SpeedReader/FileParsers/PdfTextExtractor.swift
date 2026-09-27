import Foundation
import PDFKit

/// PDF text extraction via PDFKit — native replacement for pdfjs-dist.
enum PdfTextExtractor {

    static func extractText(from url: URL) throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw FileImportError.unreadable("PDF")
        }
        var parts: [String] = []
        parts.reserveCapacity(document.pageCount)
        for pageIndex in 0..<document.pageCount {
            if let pageText = document.page(at: pageIndex)?.string {
                parts.append(pageText)
            }
        }
        return TextCleaner.clean(parts.joined(separator: " "))
    }
}
