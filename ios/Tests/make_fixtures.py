#!/usr/bin/env python3
"""Generates the file-parser test fixtures into ios/Tests/Fixtures/.

Run from the repo root:  python3 ios/Tests/make_fixtures.py
"""
import os
import zipfile

FIXTURES = os.path.join(os.path.dirname(__file__), "Fixtures")
os.makedirs(FIXTURES, exist_ok=True)

# sample.fb2 — FictionBook 2.0, declared as Windows-1251 (the legacy case)
fb2 = """<?xml version="1.0" encoding="windows-1251"?>
<FictionBook xmlns="http://www.gribuser.ru/xml/fictionbook/2.0">
  <description>
    <title-info><book-title>Sample</book-title></title-info>
  </description>
  <body>
    <section>
      <title><p>Глава первая.</p></title>
      <p>Это книга в формате FictionBook.</p>
    </section>
  </body>
</FictionBook>
"""
with open(os.path.join(FIXTURES, "sample.fb2"), "wb") as f:
    f.write(fb2.encode("cp1251"))

# Plain text, both encodings
with open(os.path.join(FIXTURES, "sample_utf8.txt"), "w", encoding="utf-8") as f:
    f.write("Обычный текстовый файл.")
with open(os.path.join(FIXTURES, "sample_cp1251.txt"), "w", encoding="cp1251") as f:
    f.write("Текстовый файл в кодировке 1251.")

# sample.rtf — deliberately unsupported
with open(os.path.join(FIXTURES, "sample.rtf"), "w", encoding="ascii") as f:
    f.write(r"{\rtf1\ansi Bogus}")

# sample.epub — minimal EPUB3-style container
with zipfile.ZipFile(os.path.join(FIXTURES, "sample.epub"), "w") as z:
    z.writestr("mimetype", "application/epub+zip")
    z.writestr(
        "META-INF/container.xml",
        '<?xml version="1.0"?>'
        '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
        '<rootfiles><rootfile full-path="OEBPS/content.opf" '
        'media-type="application/oebps-package+xml"/></rootfiles></container>',
    )
    z.writestr(
        "OEBPS/content.opf",
        '<?xml version="1.0"?>'
        '<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="id">'
        '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">'
        "<dc:title>Sample</dc:title></metadata>"
        '<manifest><item id="c1" href="chapter1.xhtml" media-type="application/xhtml+xml"/></manifest>'
        '<spine><itemref idref="c1"/></spine></package>',
    )
    z.writestr(
        "OEBPS/chapter1.xhtml",
        '<?xml version="1.0"?>'
        '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>Chapter</title></head>'
        "<body><p>Hello from EPUB.</p></body></html>",
    )

# sample.docx — two paragraphs plus a one-cell table
doc_xml = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:r><w:t>First paragraph of the sample document.</w:t></w:r></w:p>
    <w:p><w:r><w:t>Second one.</w:t></w:r></w:p>
    <w:tbl>
      <w:tr><w:tc><w:p><w:r><w:t>Third, with a table cell value.</w:t></w:r></w:p></w:tc></w:tr>
    </w:tbl>
    <w:sectPr><w:pgSz w:w="11906" w:h="16838"/></w:sectPr>
  </w:body>
</w:document>
"""
content_types = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml"
    ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>
"""
rels = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"
    Target="word/document.xml"/>
</Relationships>
"""
with zipfile.ZipFile(os.path.join(FIXTURES, "sample.docx"), "w") as z:
    z.writestr("[Content_Types].xml", content_types)
    z.writestr("_rels/.rels", rels)
    z.writestr("word/document.xml", doc_xml)

print("fixtures written to", FIXTURES)