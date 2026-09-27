import Foundation

enum EpubParserError: Error, LocalizedError {
    case missingContainer
    case missingRootFile
    case invalidPackage

    var errorDescription: String? {
        switch self {
        case .missingContainer: return String(localized: "META-INF/container.xml not found in EPUB")
        case .missingRootFile: return String(localized: "No rootfile declared in EPUB container")
        case .invalidPackage: return String(localized: "EPUB package (OPF) could not be parsed")
        }
    }
}

/// Extracts plain text from an EPUB: container.xml → OPF → spine order → XHTML text.
/// Mirrors the web app's parseEPUB (spine order preserved, text cleaned at the end).
enum EpubParser {

    static func extractText(from epubData: Data) throws -> String {
        let entries = try ZipArchive.extractEntries(from: epubData)
        let byName = Dictionary(uniqueKeysWithValues: entries.map { ($0.name, $0.data) })

        let container = entry(named: "META-INF/container.xml", in: byName)
            ?? entry(named: "meta-inf/container.xml", in: byName)
        guard let containerData = container else { throw EpubParserError.missingContainer }

        guard let opfPath = RootFileFinder().path(in: containerData) else {
            throw EpubParserError.missingRootFile
        }
        guard let opfData = entry(named: opfPath, in: byName, caseInsensitive: true) else {
            throw EpubParserError.invalidPackage
        }

        let package = try SpineManifestParser().parse(opfData)
        let opfDirectory = (opfPath as NSString).deletingLastPathComponent

        var chunks: [String] = []
        for href in package.spineHrefs {
            let fullPath = resolve(path: href, against: opfDirectory)
            guard let content = entry(named: fullPath, in: byName, caseInsensitive: true) else { continue }
            let extractor = XhtmlTextExtractor()
            chunks.append(extractor.text(from: content) ?? extractor.fallbackText(from: content))
        }
        return TextCleaner.clean(chunks.joined(separator: " "))
    }

    // MARK: - Path helpers

    private static func entry(named name: String, in entries: [String: Data], caseInsensitive: Bool = false) -> Data? {
        if let data = entries[name] { return data }
        guard caseInsensitive else { return nil }
        let lowered = name.lowercased()
        return entries.first { $0.key.lowercased() == lowered }?.value
    }

    private static func resolve(path href: String, against directory: String) -> String {
        href.hasPrefix("/")
            ? String(href.dropFirst())
            : directory.isEmpty ? href : "\(directory)/\(href)"
    }
}

// MARK: - container.xml

/// Finds the <rootfile full-path="..."> declared in META-INF/container.xml.
private final class RootFileFinder: NSObject, XMLParserDelegate {
    private var fullPath: String?

    func path(in data: Data) -> String? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return fullPath
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes: [String: String]
    ) {
        if elementName == "rootfile", let declared = attributes["full-path"] {
            fullPath = declared
        }
    }
}

// MARK: - OPF manifest / spine

private struct EpubPackage {
    var spineHrefs: [String] = []
}

/// Parses the OPF: manifest id→href plus the spine's ordered idrefs.
private final class SpineManifestParser: NSObject, XMLParserDelegate {
    private var manifest: [String: String] = [:]
    private var spineIdRefs: [String] = []
    private var currentElement = ""

    func parse(_ data: Data) throws -> EpubPackage {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else { throw EpubParserError.invalidPackage }

        var package = EpubPackage()
        package.spineHrefs = spineIdRefs.compactMap { manifest[$0] }
        if package.spineHrefs.isEmpty {
            // Fallback: read documents in manifest order.
            package.spineHrefs = manifest.values.sorted()
        }
        return package
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes: [String: String]
    ) {
        currentElement = elementName
        if elementName == "item", let id = attributes["id"], let href = attributes["href"] {
            manifest[id] = href
        }
        if elementName == "itemref", let idref = attributes["idref"] {
            spineIdRefs.append(idref)
        }
    }

    func parser(_: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentElement = ""
    }
}

// MARK: - XHTML text

/// Extracts readable character data from one XHTML document,
/// skipping <style>/<script>/<title>/<head> (body text only, like epub.js).
private final class XhtmlTextExtractor: NSObject, XMLParserDelegate {
    private var text = ""
    private var skipDepth = 0

    private static let blockElements: Set<String> = [
        "p", "div", "br", "h1", "h2", "h3", "h4", "h5", "h6",
        "li", "tr", "blockquote", "section", "article",
    ]
    private static let skippedElements: Set<String> = ["style", "script", "title", "head"]

    func text(from data: Data) -> String? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else { return nil }
        return text
    }

    /// Regex tag-stripping fallback for XHTML that is not well-formed XML.
    func fallbackText(from data: Data) -> String {
        guard var source = String(data: data, encoding: .utf8) else { return "" }
        for tag in ["style", "script", "head"] {
            source = source.replacingOccurrences(
                of: #"(?is)<\#(tag)\b.*?</\#(tag)>"#,
                with: " ",
                options: .regularExpression
            )
        }
        source = source.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
        return source
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes: [String: String]
    ) {
        if Self.skippedElements.contains(elementName) {
            skipDepth += 1
        } else if Self.blockElements.contains(elementName) {
            text += " "
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if Self.skippedElements.contains(elementName), skipDepth > 0 {
            skipDepth -= 1
        } else if Self.blockElements.contains(elementName) {
            text += " "
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if skipDepth == 0 { text += string }
    }
}
