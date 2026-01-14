import { describe, it, expect, vi, beforeEach } from 'vitest'

// Mock file with arrayBuffer support
function createMockFile(content: string, name: string, type: string) {
  return {
    name,
    type,
    arrayBuffer: () => Promise.resolve(new ArrayBuffer(content.length))
  } as unknown as File
}

// We need to mock the external libraries since they require browser APIs
vi.mock('pdfjs-dist', () => ({
  GlobalWorkerOptions: { workerSrc: '' },
  version: '4.0.0',
  getDocument: vi.fn()
}))

vi.mock('epubjs', () => ({
  default: vi.fn()
}))

// Import after mocks are set up
import { parseFile, getSupportedExtensions } from '../src/file-parsers'

describe('getSupportedExtensions', () => {
  it('should return supported file extensions', () => {
    const extensions = getSupportedExtensions()
    expect(extensions).toBe('.pdf,.epub')
  })

  it('should include pdf extension', () => {
    const extensions = getSupportedExtensions()
    expect(extensions).toContain('.pdf')
  })

  it('should include epub extension', () => {
    const extensions = getSupportedExtensions()
    expect(extensions).toContain('.epub')
  })
})

describe('parseFile', () => {
  it('should throw error for unsupported file types', async () => {
    const file = createMockFile('content', 'test.txt', 'text/plain')

    await expect(parseFile(file)).rejects.toThrow('Unsupported file type')
  })

  it('should throw error for doc files', async () => {
    const file = createMockFile('content', 'document.doc', 'application/msword')

    await expect(parseFile(file)).rejects.toThrow('Unsupported file type')
  })

  it('should throw error for docx files', async () => {
    const file = createMockFile('content', 'document.docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')

    await expect(parseFile(file)).rejects.toThrow('Unsupported file type')
  })

  it('should handle files with uppercase extensions', async () => {
    const file = createMockFile('content', 'test.TXT', 'text/plain')

    await expect(parseFile(file)).rejects.toThrow('Unsupported file type: test.txt')
  })
})

describe('parsePDF', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should attempt to parse PDF files', async () => {
    const pdfjsLib = await import('pdfjs-dist')

    // Mock the PDF document
    const mockPage = {
      getTextContent: vi.fn().mockResolvedValue({
        items: [
          { str: 'Hello' },
          { str: 'World' }
        ]
      })
    }

    const mockPdf = {
      numPages: 1,
      getPage: vi.fn().mockResolvedValue(mockPage)
    }

    ;(pdfjsLib.getDocument as ReturnType<typeof vi.fn>).mockReturnValue({
      promise: Promise.resolve(mockPdf)
    })

    const file = createMockFile('fake pdf content', 'test.pdf', 'application/pdf')

    const result = await parseFile(file)

    expect(pdfjsLib.getDocument).toHaveBeenCalled()
    expect(result).toBe('Hello World')
  })

  it('should handle multi-page PDFs', async () => {
    const pdfjsLib = await import('pdfjs-dist')

    const mockPage1 = {
      getTextContent: vi.fn().mockResolvedValue({
        items: [{ str: 'Page' }, { str: 'One' }]
      })
    }

    const mockPage2 = {
      getTextContent: vi.fn().mockResolvedValue({
        items: [{ str: 'Page' }, { str: 'Two' }]
      })
    }

    const mockPdf = {
      numPages: 2,
      getPage: vi.fn()
        .mockResolvedValueOnce(mockPage1)
        .mockResolvedValueOnce(mockPage2)
    }

    ;(pdfjsLib.getDocument as ReturnType<typeof vi.fn>).mockReturnValue({
      promise: Promise.resolve(mockPdf)
    })

    const file = createMockFile('fake pdf content', 'multipage.pdf', 'application/pdf')

    const result = await parseFile(file)

    expect(mockPdf.getPage).toHaveBeenCalledTimes(2)
    expect(result).toBe('Page One Page Two')
  })

  it('should filter out non-text items from PDF', async () => {
    const pdfjsLib = await import('pdfjs-dist')

    const mockPage = {
      getTextContent: vi.fn().mockResolvedValue({
        items: [
          { str: 'Text' },
          { type: 'marker' }, // No str property
          { str: 'Content' }
        ]
      })
    }

    const mockPdf = {
      numPages: 1,
      getPage: vi.fn().mockResolvedValue(mockPage)
    }

    ;(pdfjsLib.getDocument as ReturnType<typeof vi.fn>).mockReturnValue({
      promise: Promise.resolve(mockPdf)
    })

    const file = createMockFile('fake pdf content', 'test.pdf', 'application/pdf')

    const result = await parseFile(file)

    expect(result).toBe('Text Content')
  })
})

describe('parseEPUB', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should attempt to parse EPUB files', async () => {
    const epubjs = await import('epubjs')

    const mockSection = {
      href: 'chapter1.xhtml'
    }

    const mockBook = {
      ready: Promise.resolve(),
      loaded: { spine: Promise.resolve() },
      spine: {
        items: [mockSection],
        spineItems: [mockSection]
      },
      load: vi.fn().mockResolvedValue('<html><body>Chapter content here</body></html>')
    }

    ;(epubjs.default as ReturnType<typeof vi.fn>).mockReturnValue(mockBook)

    const file = createMockFile('fake epub content', 'test.epub', 'application/epub+zip')

    const result = await parseFile(file)

    expect(epubjs.default).toHaveBeenCalled()
    expect(result).toBe('Chapter content here')
  })

  it('should handle EPUB with multiple chapters', async () => {
    const epubjs = await import('epubjs')

    const mockSection1 = { href: 'chapter1.xhtml' }
    const mockSection2 = { href: 'chapter2.xhtml' }

    const mockBook = {
      ready: Promise.resolve(),
      loaded: { spine: Promise.resolve() },
      spine: {
        items: [mockSection1, mockSection2],
        spineItems: [mockSection1, mockSection2]
      },
      load: vi.fn().mockImplementation((href: string) => {
        if (href === 'chapter1.xhtml') return Promise.resolve('<html><body>Chapter One</body></html>')
        if (href === 'chapter2.xhtml') return Promise.resolve('<html><body>Chapter Two</body></html>')
        return Promise.resolve('')
      })
    }

    ;(epubjs.default as ReturnType<typeof vi.fn>).mockReturnValue(mockBook)

    const file = createMockFile('fake epub content', 'multiChapter.epub', 'application/epub+zip')

    const result = await parseFile(file)

    expect(result).toBe('Chapter One Chapter Two')
  })

  it('should handle failed section loads gracefully', async () => {
    const epubjs = await import('epubjs')

    const mockSection1 = { href: 'broken.xhtml' }
    const mockSection2 = { href: 'working.xhtml' }

    const mockBook = {
      ready: Promise.resolve(),
      loaded: { spine: Promise.resolve() },
      spine: {
        items: [mockSection1, mockSection2],
        spineItems: [mockSection1, mockSection2]
      },
      load: vi.fn().mockImplementation((href: string) => {
        if (href === 'broken.xhtml') return Promise.reject(new Error('Failed to load'))
        if (href === 'working.xhtml') return Promise.resolve('<html><body>Working chapter</body></html>')
        return Promise.resolve('')
      })
    }

    ;(epubjs.default as ReturnType<typeof vi.fn>).mockReturnValue(mockBook)

    const file = createMockFile('fake epub content', 'partial.epub', 'application/epub+zip')

    // Should not throw, should continue with other sections
    const result = await parseFile(file)

    expect(result).toBe('Working chapter')
  })
})

describe('text cleaning', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should clean multiple spaces', async () => {
    const pdfjsLib = await import('pdfjs-dist')

    const mockPage = {
      getTextContent: vi.fn().mockResolvedValue({
        items: [
          { str: 'Hello' },
          { str: '   ' },
          { str: 'World' }
        ]
      })
    }

    const mockPdf = {
      numPages: 1,
      getPage: vi.fn().mockResolvedValue(mockPage)
    }

    ;(pdfjsLib.getDocument as ReturnType<typeof vi.fn>).mockReturnValue({
      promise: Promise.resolve(mockPdf)
    })

    const file = createMockFile('fake pdf content', 'spaces.pdf', 'application/pdf')

    const result = await parseFile(file)

    // Multiple spaces should be collapsed
    expect(result).not.toContain('   ')
    expect(result).toBe('Hello World')
  })

  it('should clean repeated punctuation', async () => {
    const pdfjsLib = await import('pdfjs-dist')

    const mockPage = {
      getTextContent: vi.fn().mockResolvedValue({
        items: [
          { str: 'What???' },
          { str: 'Really!!!' }
        ]
      })
    }

    const mockPdf = {
      numPages: 1,
      getPage: vi.fn().mockResolvedValue(mockPage)
    }

    ;(pdfjsLib.getDocument as ReturnType<typeof vi.fn>).mockReturnValue({
      promise: Promise.resolve(mockPdf)
    })

    const file = createMockFile('fake pdf content', 'punctuation.pdf', 'application/pdf')

    const result = await parseFile(file)

    expect(result).toBe('What? Really!')
  })
})
