import Foundation

/// Extracts plain text from a FictionBook (FB2) file. FB2 is XML: the reader
/// text lives in <p> paragraphs inside the <body>; <description> metadata and
/// <binary> attachments (base64 images) must be skipped.
enum Fb2Parser {

    /// Full pipeline over raw file bytes. XMLParser honors the encoding
    /// declared in the prolog (utf-8, windows-1251, …), so legacy-encoded
    /// books decode correctly without pre-processing.
    static func extractText(from data: Data) -> String? {
        let parser = XMLParser(data: data)
        let delegate = Fb2TextDelegate()
        parser.delegate = delegate
        guard parser.parse() else { return nil }
        return delegate.paragraphs.joined(separator: "\n")
    }

    /// XML-only layer (unit-testable). The input is already decoded text, so
    /// the declaration is stripped to keep XMLParser from re-decoding it.
    static func extractDocumentText(from xml: String) -> String {
        let declarationFree = xml.replacingOccurrences(
            of: #"(?is)^\s*<\?xml[^>]*\?>"#,
            with: "",
            options: .regularExpression
        )
        return extractText(from: Data(declarationFree.utf8)) ?? ""
    }
}

private final class Fb2TextDelegate: NSObject, XMLParserDelegate {
    private(set) var paragraphs: [String] = []
    private var inBody = false
    private var inParagraph = false
    private var current = ""

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
        case "body":
            inBody = true
        case "p" where inBody:
            inParagraph = true
            current = ""
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
        switch localName(elementName) {
        case "body":
            inBody = false
        case "p" where inBody:
            inParagraph = false
            paragraphs.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        default:
            break
        }
    }
}