/**
 * File parsing utilities for PDF and EPUB files
 */

/**
 * Parse a PDF file and extract its text content
 * @param {File} file - The PDF file to parse
 * @returns {Promise<string>} The extracted text
 */
export async function parsePDF(file) {
  const pdfjsLib = await import('pdfjs-dist')

  // Set up the worker - use unpkg which mirrors npm directly
  pdfjsLib.GlobalWorkerOptions.workerSrc = `https://unpkg.com/pdfjs-dist@${pdfjsLib.version}/build/pdf.worker.min.mjs`

  const arrayBuffer = await file.arrayBuffer()
  const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise

  let fullText = ''

  for (let i = 1; i <= pdf.numPages; i++) {
    const page = await pdf.getPage(i)
    const textContent = await page.getTextContent()
    const pageText = textContent.items
      .filter(item => 'str' in item)
      .map(item => /** @type {{ str: string }} */ (item).str)
      .join(' ')
    fullText += pageText + ' '
  }

  // Clean up the text
  return cleanText(fullText)
}

/**
 * Parse an EPUB file and extract its text content
 * @param {File} file - The EPUB file to parse
 * @returns {Promise<string>} The extracted text
 */
export async function parseEPUB(file) {
  const ePub = (await import('epubjs')).default

  const arrayBuffer = await file.arrayBuffer()
  const book = ePub(arrayBuffer)

  await book.ready
  await book.loaded.spine

  let fullText = ''

  // Get spine items - the API varies between versions
  const spineItems = book.spine?.spineItems || book.spine?.items || []

  for (const item of spineItems) {
    try {
      // Load the section content using the book's load method
      const href = item.href || item.url
      if (!href) continue

      const contents = await book.load(href)
      if (contents) {
        let text = ''
        // contents can be a Document, string, or XML document
        if (typeof contents === 'string') {
          const doc = new DOMParser().parseFromString(contents, 'text/html')
          text = doc.body?.textContent || ''
        } else if (contents.body) {
          text = contents.body.textContent || ''
        } else if (contents.documentElement) {
          text = contents.documentElement.textContent || ''
        }
        fullText += text + ' '
      }
    } catch (e) {
      console.warn('Could not load section:', e)
    }
  }

  // Clean up the text
  return cleanText(fullText)
}

/**
 * Clean and normalize extracted text
 * @param {string} text - The raw text to clean
 * @returns {string} Cleaned text
 */
function cleanText(text) {
  return text
    // Replace multiple spaces/newlines with single space
    .replace(/\s+/g, ' ')
    // Remove excessive punctuation
    .replace(/([.!?])\1+/g, '$1')
    // Trim
    .trim()
}

/**
 * Detect file type and parse accordingly
 * @param {File} file - The file to parse
 * @returns {Promise<string>} The extracted text
 */
export async function parseFile(file) {
  const fileName = file.name.toLowerCase()

  if (fileName.endsWith('.pdf')) {
    return parsePDF(file)
  } else if (fileName.endsWith('.epub')) {
    return parseEPUB(file)
  } else {
    throw new Error(`Unsupported file type: ${fileName}`)
  }
}

/**
 * Get supported file extensions
 * @returns {string} Comma-separated list of supported extensions
 */
export function getSupportedExtensions() {
  return '.pdf,.epub'
}
