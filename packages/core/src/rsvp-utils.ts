/**
 * RSVP utility functions for text processing and display calculations
 */

export interface WordDisplayParts {
  before: string
  orp: string
  after: string
}

export interface WordFrame {
  subset: string[]
  centerOffset: number
}

/**
 * Parse text into an array of words
 * @param text - The input text to parse
 * @returns Array of words
 */
export function parseText(text: string | null | undefined): string[] {
  if (!text || typeof text !== 'string') return []
  return text.trim().split(/\s+/).filter(w => w.length > 0)
}

// Pre-compiled regex for Unicode letter matching
const unicodeLetterRegex = /\p{L}/u

/**
 * Calculate the Optimal Recognition Point (ORP) index for a word.
 * The ORP is the character position where the eye naturally focuses when reading.
 * Based on word length, this determines which letter should be highlighted.
 * Supports all Unicode letters (Latin, Cyrillic, CJK, Arabic, etc.)
 *
 * @param word - The word to calculate ORP for
 * @returns The index of the letter that should be highlighted
 */
export function getORPIndex(word: string | null | undefined): number {
  if (!word || typeof word !== 'string') return 0
  // Use Unicode letter category to support all languages
  const len = word.replace(/[^\p{L}]/gu, '').length
  if (len <= 1) return 0
  if (len <= 3) return 0
  if (len <= 5) return 1
  if (len <= 9) return 2
  if (len <= 12) return 3
  return Math.floor(Math.log2(len - 1)) + 1
}

/**
 * Get the actual character index for ORP, accounting for leading punctuation.
 * This adjusts the ORP index to skip over non-letter characters.
 * Supports all Unicode letters.
 *
 * @param word - The word to calculate actual ORP for
 * @returns The actual character index in the word
 */
export function getActualORPIndex(word: string | null | undefined): number {
  if (!word || typeof word !== 'string') return 0

  const orpIndex = getORPIndex(word)
  let letterCount = 0

  for (let i = 0; i < word.length; i++) {
    if (unicodeLetterRegex.test(word[i])) {
      if (letterCount === orpIndex) return i
      letterCount++
    }
  }

  return Math.min(orpIndex, word.length - 1)
}

/**
 * Calculate the display delay for a word based on WPM and punctuation.
 * Words ending with sentence punctuation get a longer pause.
 *
 * @param word - The word to calculate delay for
 * @param wordsPerMinute - Reading speed in WPM
 * @param pauseOnPunctuation - Whether to add extra pause on punctuation
 * @param punctuationMultiplier - Multiplier for sentence-ending punctuation
 * @param wordLengthWPMMultiplier - Extra delay per character for long words (0 = disabled)
 * @returns Delay in milliseconds
 */
export function getWordDelay(
  word: string | null | undefined,
  wordsPerMinute: number,
  pauseOnPunctuation: boolean = true,
  punctuationMultiplier: number = 2,
  wordLengthWPMMultiplier: number = 0
): number {
  if (!word || typeof word !== 'string') return 60000 / wordsPerMinute
  if (!wordsPerMinute || wordsPerMinute <= 0) return 200 // Default fallback

  let baseDelay = 60000 / wordsPerMinute

  // Longer pause for long words (12+ characters is roughly 2 standard deviations above average English word length)
  if (wordLengthWPMMultiplier > 0 && word.length >= 12) {
    // For every character above 12, add wordLengthWPMMultiplier percentage points to delay
    baseDelay *= 1 + ((wordLengthWPMMultiplier / 100) * (word.length - 12))
  }

  if (pauseOnPunctuation) {
    // Longer pause for sentence-ending punctuation
    if (/[.!?;:]$/.test(word)) {
      return baseDelay * punctuationMultiplier
    }
    // Shorter pause for commas
    if (/[,]$/.test(word)) {
      return baseDelay * 1.5
    }
  }

  return baseDelay
}

/**
 * Format remaining reading time as MM:SS
 *
 * @param remainingWords - Number of words remaining
 * @param wordsPerMinute - Reading speed in WPM
 * @returns Formatted time string (e.g., "2:30")
 */
export function formatTimeRemaining(remainingWords: number, wordsPerMinute: number): string {
  if (remainingWords <= 0 || !wordsPerMinute || wordsPerMinute <= 0) return '0:00'

  const seconds = Math.ceil((remainingWords / wordsPerMinute) * 60)
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60

  return `${mins}:${secs.toString().padStart(2, '0')}`
}

/**
 * Split a word into parts for ORP display (before, ORP letter, after)
 *
 * @param word - The word to split
 * @returns Word parts
 */
export function splitWordForDisplay(word: string | null | undefined): WordDisplayParts {
  if (!word || typeof word !== 'string') {
    return { before: '', orp: '', after: '' }
  }

  const orpIndex = getActualORPIndex(word)

  return {
    before: word.slice(0, orpIndex),
    orp: word[orpIndex] || '',
    after: word.slice(orpIndex + 1)
  }
}

/**
 * Check if a word should trigger a pause based on pause-every-N-words setting
 *
 * @param wordIndex - Current word index (0-based)
 * @param pauseAfterWords - Pause after every N words (0 = disabled)
 * @returns Whether to pause
 */
export function shouldPauseAtWord(wordIndex: number, pauseAfterWords: number): boolean {
  if (pauseAfterWords <= 0) return false
  if (wordIndex <= 0) return false
  return wordIndex % pauseAfterWords === 0
}

/**
 * Extract a subset of words centered on current position
 * @param allWords - Complete word array
 * @param centerIdx - Index to center on
 * @param frameSize - Total words to display (odd numbers recommended)
 * @returns Word frame with subset and center offset
 */
export function extractWordFrame(allWords: string[], centerIdx: number, frameSize: number): WordFrame {
  if (frameSize <= 1 || centerIdx >= allWords.length) {
    return { subset: [allWords[centerIdx] || ''], centerOffset: 0 }
  }

  const radius = Math.floor(frameSize / 2)
  const leftBound = Math.max(0, centerIdx - radius)
  const rightBound = Math.min(allWords.length, centerIdx + radius + 1)

  const subset = allWords.slice(leftBound, rightBound)
  const centerOffset = centerIdx - leftBound

  return { subset, centerOffset }
}
