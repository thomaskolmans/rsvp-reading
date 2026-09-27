// Standalone tests for the FB2 / DOCX parsers, text decoding and
// FileImportService routing. Needs fixture files (see Fixtures/README):
//   python3 ios/Tests/make_fixtures.py
// Build & run (macOS host, run from the repo root):
//   swiftc ios/SpeedReader/Core/TextCleaner.swift ios/SpeedReader/FileParsers/*.swift \
//          ios/Tests/FileParsersTests.swift -o /tmp/fileparsers_tests && /tmp/fileparsers_tests
import Foundation

private var failures: Int = 0
private var passed: Int = 0

private func expect<T: Equatable>(_ name: String, _ actual: T, _ expected: T) {
    if actual == expected {
        passed += 1
    } else {
        failures += 1
        print("FAIL: \(name) — expected \(String(describing: expected)), got \(String(describing: actual))")
    }
}

private func expectThrows(_ name: String, _ body: () throws -> Void) {
    do {
        try body()
        failures += 1
        print("FAIL: \(name) — expected an error, got none")
    } catch {
        passed += 1
    }
}

// MARK: - Fixture resolution

/// Fixtures live in `ios/Tests/Fixtures`; tests may be run from the repo root
/// or from `ios/`, so both relative roots are tried.
private func fixture(_ name: String) -> URL {
    let candidates = [
        "ios/Tests/Fixtures/\(name)",
        "Tests/Fixtures/\(name)",
    ]
    for candidate in candidates {
        let url = URL(fileURLWithPath: candidate)
        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }
    }
    fatalError("fixture not found: \(name)")
}

// MARK: - TextCleaner.decodeText

private func testDecodeText() {
    expect("decodeText: utf8 roundtrip",
           TextCleaner.decodeText(Data("Привет мир".utf8)), "Привет мир")

    // "Привет, мир!" in Windows-1251
    let cp1251: [UInt8] = [0xCF, 0xF0, 0xE8, 0xE2, 0xE5, 0xF2, 0x2C, 0x20,
                           0xEC, 0xE8, 0xF0, 0x21]
    expect("decodeText: cp1251 fallback",
           TextCleaner.decodeText(Data(cp1251)), "Привет, мир!")

    expect("decodeText: empty data",
           TextCleaner.decodeText(Data()), "")
}

// MARK: - Fb2Parser

private func testFb2Basic() {
    let xml = """
    <?xml version="1.0" encoding="utf-8"?>
    <FictionBook xmlns="http://www.gribuser.ru/xml/fictionbook/2.0">
      <description>
        <title-info><book-title>Test</book-title></title-info>
      </description>
      <body>
        <section>
          <title><p>Chapter One</p></title>
          <p>Hello world.</p>
          <p>Second line.</p>
        </section>
      </body>
      <binary id="cover" content-type="image/png">iVBORw0KGgo=</binary>
    </FictionBook>
    """
    expect("fb2: body paragraphs in order",
           Fb2Parser.extractDocumentText(from: xml), "Chapter One\nHello world.\nSecond line.")
}

private func testFb2SkipsDescriptionAndBinary() {
    let xml = """
    <FictionBook>
      <description>
        <title-info>
          <book-title>Hidden</book-title>
          <annotation><p>This annotation must not leak into the text.</p></annotation>
        </title-info>
      </description>
      <body>
        <section>
          <p>Only this line.</p>
        </section>
      </body>
    </FictionBook>
    """
    expect("fb2: description annotation excluded", Fb2Parser.extractDocumentText(from: xml), "Only this line.")
}

private func testFb2EmptyBody() {
    expect("fb2: empty body", Fb2Parser.extractDocumentText(from: "<FictionBook><body><section><p></p></section></body></FictionBook>"), "")
}

private func testFb2IncludesPoemVerses() {
    let xml = """
    <FictionBook>
      <body>
        <section>
          <poem><stanza><v><p>Rose is red</p></v><v><p>Violet is blue</p></v></stanza></poem>
        </section>
      </body>
    </FictionBook>
    """
    expect("fb2: poem verses kept", Fb2Parser.extractDocumentText(from: xml), "Rose is red\nViolet is blue")
}

// MARK: - DocxParser (XML layer)

private func testDocxParagraphs() {
    let xml = """
    <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
      <w:body>
        <w:p><w:r><w:t>Hel</w:t></w:r><w:r><w:t>lo</w:t></w:r></w:p>
        <w:p><w:r><w:t>World</w:t></w:r></w:p>
        <w:p><w:r><w:t xml:space="preserve">  </w:t></w:r></w:p>
        <w:p><w:r><w:t>Last.</w:t></w:r></w:p>
      </w:body>
    </w:document>
    """
    expect("docx: runs merged, paragraphs joined, blanks kept",
           DocxParser.extractDocumentText(from: xml), "Hello\nWorld\n\nLast.")
}

private func testDocxSkipsMarginalia() {
    let xml = """
    <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
      <w:body><w:p><w:r><w:t>Body first.</w:t></w:r></w:p></w:body>
    </w:document>
    """
    expect("docx: minimal body", DocxParser.extractDocumentText(from: xml), "Body first.")
}

private func testDocxBreaksAndTabs() {
    let xml = """
    <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
      <w:body>
        <w:p><w:r><w:t>A</w:t></w:r><w:br/><w:r><w:t>B</w:t></w:r><w:r><w:tab/></w:r><w:r><w:t>C</w:t></w:r></w:p>
      </w:body>
    </w:document>
    """
    expect("docx: line break and tab rendered",
           DocxParser.extractDocumentText(from: xml), "A\nB\tC")
}

// MARK: - DocxParser (ZIP container)

private func testDocxFromZipFixture() throws {
    let data = try Data(contentsOf: fixture("sample.docx"))
    let text = try DocxParser.extractText(from: data)
    expect("docx: real zip fixture", text, "First paragraph of the sample document.\nSecond one.\nThird, with a table cell value.")
}

// MARK: - FileImportService routing (end to end)

private func testRoutingFb2Cp1251() throws {
    let text = try FileImportService.importText(from: fixture("sample.fb2"))
    expect("routing: .fb2 in cp1251 decoded", text, "Глава первая.\nЭто книга в формате FictionBook.")
}

private func testRoutingDocx() throws {
    let text = try FileImportService.importText(from: fixture("sample.docx"))
    expect("routing: .docx extracted", text, "First paragraph of the sample document.\nSecond one.\nThird, with a table cell value.")
}

private func testRoutingTxtUtf8() throws {
    let text = try FileImportService.importText(from: fixture("sample_utf8.txt"))
    expect("routing: .txt utf8", text, "Обычный текстовый файл.")
}

private func testRoutingTxtCp1251() throws {
    let text = try FileImportService.importText(from: fixture("sample_cp1251.txt"))
    expect("routing: .txt cp1251 decoded", text, "Текстовый файл в кодировке 1251.")
}

private func testRoutingEpub() throws {
    let text = try FileImportService.importText(from: fixture("sample.epub"))
    expect("routing: .epub extracted", text, "Hello from EPUB.")
}

private func testRoutingUnsupported() {
    expectThrows("routing: unknown extension rejected") {
        _ = try FileImportService.importText(from: fixture("sample.rtf"))
    }
}

// MARK: - Runner

@main
enum FileParsersTestRunner {

    static func main() {
        testDecodeText()
        testFb2Basic()
        testFb2SkipsDescriptionAndBinary()
        testFb2EmptyBody()
        testFb2IncludesPoemVerses()
        testDocxParagraphs()
        testDocxSkipsMarginalia()
        testDocxBreaksAndTabs()
        do {
            try testDocxFromZipFixture()
            try testRoutingFb2Cp1251()
            try testRoutingDocx()
            try testRoutingTxtUtf8()
            try testRoutingTxtCp1251()
            try testRoutingEpub()
        } catch {
            failures += 1
            print("FAIL: fixture test error: \(error)")
        }
        testRoutingUnsupported()

        print("All \(passed) file-parser tests passed." + (failures > 0 ? " \(failures) failures." : ""))
        exit(failures > 0 ? 1 : 0)
    }
}