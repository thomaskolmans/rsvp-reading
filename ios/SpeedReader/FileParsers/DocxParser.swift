import Foundation

enum DocxParserError: Error, LocalizedError {
    case missingDocumentXml

    var errorDescription: String? {
        String(localized: "word/document.xml not found in DOCX")
    }
}

/// Extracts plain text from a DOCX (Office Open XML). The document is a ZIP
/// container; the text lives in <w:p> paragraphs of word/document.xml, each
/// built from <w:t> runs. Paragraph order is preserved, tables included.
enum DocxParser {

    static func extractText(from docxData: Data) throws -> String {
        let entries = try ZipArchive.extractEntries(from: docxData)
        guard let document = entries.first(where: { $0.name.lowercased() == "word/document.xml" }) else {
            throw DocxParserError.missingDocumentXml
        }
        guard let xml = String(data: document.data, encoding: .utf8) else {
            throw DocxParserError.missingDocumentXml
        }
        return extractDocumentText(from: xml)
    }

    /// XML-only layer (unit-testable): <w:p> -> paragraphs, <w:t> -> runs,
    /// <w:br>/<w:tab> rendered as newline/tab. Whitespace-only paragraphs are
    /// kept as blank lines.
    static func extractDocumentText(from xml: String) -> String {
        let parser = XMLParser(data: Data(xml.utf8))
        let delegate = DocxTextDelegate()
        parser.delegate = delegate
        parser.parse()
        return delegate.paragraphs.joined(separator: "\n")
    }
}

private final class DocxTextDelegate: NSObject, XMLParserDelegate {
    private(set) var paragraphs: [String] = []
    private var inParagraph = false
    private var current = ""

    /// XMLParser reports namespaced elements with their prefix ("w:p").
    private func localName(_ elementName: String) -> String {
        elementName.split(separator: ":").last.map(String.init) ?? elementName
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        switch localName(elementName) {
        case "p":
            inParagraph = true
            current = ""
        case "br" where inParagraph:
            current += "\n"
        case "tab" where inParagraph:
            current += "\t"
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inParagraph { current += string }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if localName(elementName) == "p" {
            inParagraph = false
            paragraphs.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}