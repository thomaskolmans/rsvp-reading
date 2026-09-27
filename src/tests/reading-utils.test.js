import { describe, it, expect } from 'vitest'
import {
  parseText,
  getORPIndex,
  getActualORPIndex,
  getWordFontSize,
  getWordDelay,
  formatTimeRemaining,
  splitWordForDisplay,
  shouldPauseAtWord,
  extractWordFrame
} from '../lib/reading-utils.js'

describe('parseText', () => {
  it('should split text into words', () => {
    const result = parseText('Hello world test')
    expect(result).toEqual(['Hello', 'world', 'test'])
  })

  it('should handle multiple spaces', () => {
    const result = parseText('Hello   world    test')
    expect(result).toEqual(['Hello', 'world', 'test'])
  })

  it('should trim leading and trailing whitespace', () => {
    const result = parseText('  Hello world  ')
    expect(result).toEqual(['Hello', 'world'])
  })

  it('should return empty array for empty string', () => {
    expect(parseText('')).toEqual([])
  })

  it('should return empty array for whitespace only', () => {
    expect(parseText('   ')).toEqual([])
  })

  it('should return empty array for null/undefined', () => {
    expect(parseText(null)).toEqual([])
    expect(parseText(undefined)).toEqual([])
  })

  it('should handle newlines and tabs', () => {
    const result = parseText('Hello\nworld\ttest')
    expect(result).toEqual(['Hello', 'world', 'test'])
  })
})

describe('getORPIndex', () => {
it('should return 0 for 1-2 letter words', () => {
    expect(getORPIndex('a')).toBe(0)
    expect(getORPIndex('I')).toBe(0)
    expect(getORPIndex('to')).toBe(0)
  })

  it('should pick the middle letter for 3-letter words', () => {
    expect(getORPIndex('the')).toBe(1)
    expect(getORPIndex('cat')).toBe(1)
  })

  it('should pick the middle letter for 4-5 letter words', () => {
    expect(getORPIndex('word')).toBe(1)
    expect(getORPIndex('hello')).toBe(2)
  })

  it('should pick the middle letter for 6-9 letter words', () => {
    expect(getORPIndex('reading')).toBe(3)
    expect(getORPIndex('beautiful')).toBe(4)
  })

  it('should pick the middle letter for 10+ letter words', () => {
    expect(getORPIndex('interesting')).toBe(5)
    expect(getORPIndex('presentation')).toBe(5)
  })

  it('should pick a central letter for very long words', () => {
    // 13 letters -> exactly the 7th (index 6)
    expect(getORPIndex('international')).toBe(6)
    // 20 letters -> index 9
    expect(getORPIndex('supercalifragilistic')).toBe(9)
  })

  it('should ignore non-letter characters when counting', () => {
    expect(getORPIndex("don't")).toBe(1) // 4 letters: d-o-n-t
    expect(getORPIndex('e-mail')).toBe(2) // 5 letters: e-m-a-i-l
  })

  it('should return 0 for empty/null input', () => {
    expect(getORPIndex('')).toBe(0)
    expect(getORPIndex(null)).toBe(0)
    expect(getORPIndex(undefined)).toBe(0)
  })

  // Unicode / International language support
  it('should handle French accented characters', () => {
    expect(getORPIndex('café')).toBe(1)      // 4 letters
    expect(getORPIndex('résumé')).toBe(2)    // 6 letters
    expect(getORPIndex('français')).toBe(3)  // 8 letters
  })

  it('should handle Spanish characters', () => {
    expect(getORPIndex('niño')).toBe(1)      // 4 letters
    expect(getORPIndex('mañana')).toBe(2)    // 6 letters
    expect(getORPIndex('español')).toBe(3)   // 7 letters
  })

  it('should handle German characters', () => {
    expect(getORPIndex('über')).toBe(1)      // 4 letters
    expect(getORPIndex('größe')).toBe(2)     // 5 letters
    expect(getORPIndex('Mädchen')).toBe(3)   // 7 letters
  })

  it('should handle Cyrillic (Russian)', () => {
    expect(getORPIndex('мир')).toBe(1)       // 3 letters
    expect(getORPIndex('слово')).toBe(2)     // 5 letters
    expect(getORPIndex('привет')).toBe(2)    // 6 letters
  })

  it('should handle Greek', () => {
    expect(getORPIndex('και')).toBe(1)       // 3 letters
    expect(getORPIndex('λόγος')).toBe(2)     // 5 letters
    expect(getORPIndex('ελληνικά')).toBe(3)  // 8 letters
  })

  it('should handle Chinese characters', () => {
    expect(getORPIndex('中')).toBe(0)        // 1 character
    expect(getORPIndex('中国')).toBe(0)      // 2 characters
    expect(getORPIndex('你好世界')).toBe(1)   // 4 characters
  })

  it('should handle Japanese', () => {
    expect(getORPIndex('日本')).toBe(0)      // 2 characters
    expect(getORPIndex('こんにちは')).toBe(2) // 5 characters
  })

  it('should handle Arabic', () => {
    expect(getORPIndex('مرحبا')).toBe(2)     // 5 letters
    expect(getORPIndex('العربية')).toBe(3)   // 7 letters
  })

  it('should handle Hebrew', () => {
    expect(getORPIndex('שלوم')).toBe(1)      // 4 letters
    expect(getORPIndex('עברית')).toBe(2)     // 5 letters
  })
})

describe('getActualORPIndex', () => {
  it('should return the middle letter index for simple words', () => {
    expect(getActualORPIndex('hello')).toBe(2) // 5 letters -> 'l'
    expect(getActualORPIndex('cat')).toBe(1)   // 3 letters -> 'a'
  })

  it('should skip leading punctuation', () => {
    expect(getActualORPIndex('"hello')).toBe(3) // Skip " to get to 'l'
    expect(getActualORPIndex('(test')).toBe(2)  // Skip ( to get to 'e'
  })

  it('should handle words with only punctuation', () => {
    expect(getActualORPIndex('...')).toBe(0)
  })

  it('should handle empty input', () => {
    expect(getActualORPIndex('')).toBe(0)
    expect(getActualORPIndex(null)).toBe(0)
  })

  // Unicode / International language support
  it('should handle accented characters correctly', () => {
    expect(getActualORPIndex('café')).toBe(1)      // 'a' is ORP
    expect(getActualORPIndex('résumé')).toBe(2)    // 's' is ORP
    expect(getActualORPIndex('über')).toBe(1)      // 'b' is ORP
  })

  it('should skip punctuation with Unicode words', () => {
    expect(getActualORPIndex('"café"')).toBe(2)    // Skip " to get to 'a'
    expect(getActualORPIndex('¡hola!')).toBe(2)    // Skip ¡ to get to 'o'
    expect(getActualORPIndex('«привет»')).toBe(3) // Skip « to get to 'и'
  })

  it('should handle Cyrillic words', () => {
    expect(getActualORPIndex('привет')).toBe(2)    // 'и' is ORP
    expect(getActualORPIndex('мир')).toBe(1)       // middle letter 'и'
  })

  it('should handle CJK characters', () => {
    expect(getActualORPIndex('你好')).toBe(0)       // First character
    expect(getActualORPIndex('你好世界')).toBe(1)   // Second character is ORP
  })
})

describe('getWordDelay', () => {
  it('should calculate base delay from WPM', () => {
    // 300 WPM = 60000 / 300 = 200ms per word
    expect(getWordDelay('hello', 300)).toBe(200)
    // 600 WPM = 60000 / 600 = 100ms per word
    expect(getWordDelay('hello', 600)).toBe(100)
  })

  it('should multiply delay for sentence-ending punctuation', () => {
    // 300 WPM base = 200ms, with 2x multiplier = 400ms
    expect(getWordDelay('word.', 300, true, 2)).toBe(400)
    expect(getWordDelay('word!', 300, true, 2)).toBe(400)
    expect(getWordDelay('word?', 300, true, 2)).toBe(400)
    expect(getWordDelay('word;', 300, true, 2)).toBe(400)
    expect(getWordDelay('word:', 300, true, 2)).toBe(400)
  })

  it('should add 1.5x delay for commas', () => {
    // 300 WPM base = 200ms, with 1.5x = 300ms
    expect(getWordDelay('word,', 300, true, 2)).toBe(300)
  })

  it('should not add punctuation delay when disabled', () => {
    expect(getWordDelay('word.', 300, false, 2)).toBe(200)
    expect(getWordDelay('word,', 300, false, 2)).toBe(200)
  })

  it('should handle invalid WPM', () => {
    expect(getWordDelay('hello', 0)).toBe(200) // Default fallback
    expect(getWordDelay('hello', -100)).toBe(200)
  })

  it('should handle empty word', () => {
    expect(getWordDelay('', 300)).toBe(200)
  })

  it('should increase delay for long words when multiplier is set', () => {
    // 300 WPM base = 200ms
    // "extraordinary" is 13 chars, 1 char above threshold of 12
    // With 10% multiplier: 200 * (1 + 0.1 * 1) = 220ms
    expect(getWordDelay('extraordinary', 300, false, 2, 10)).toBeCloseTo(220)

    // "acknowledgement" is 15 chars, 3 chars above threshold
    // With 10% multiplier: 200 * (1 + 0.1 * 3) = 260ms
    expect(getWordDelay('acknowledgement', 300, false, 2, 10)).toBeCloseTo(260)
  })

  it('should not increase delay for long words when multiplier is 0', () => {
    // Default multiplier is 0, so long words should have normal delay
    expect(getWordDelay('extraordinary', 300, false, 2, 0)).toBeCloseTo(200)
    expect(getWordDelay('acknowledgement', 300, false, 2)).toBeCloseTo(200)
  })

  it('should not affect short words regardless of multiplier', () => {
    // "hello" is 5 chars, below threshold of 12
    expect(getWordDelay('hello', 300, false, 2, 10)).toBeCloseTo(200)
    // "programming" is 11 chars, still below threshold
    expect(getWordDelay('programming', 300, false, 2, 10)).toBeCloseTo(200)
  })

  it('should combine long word delay with punctuation delay', () => {
    // "extraordinary." is 14 chars (13 letters + period), 2 chars above threshold
    // Base: 200ms, long word: 200 * 1.2 = 240ms, punctuation 2x: 480ms
    expect(getWordDelay('extraordinary.', 300, true, 2, 10)).toBeCloseTo(480)
  })
})

describe('formatTimeRemaining', () => {
  it('should format time correctly', () => {
    // 300 words at 300 WPM = 1 minute
    expect(formatTimeRemaining(300, 300)).toBe('1:00')
    // 150 words at 300 WPM = 30 seconds
    expect(formatTimeRemaining(150, 300)).toBe('0:30')
    // 450 words at 300 WPM = 1.5 minutes
    expect(formatTimeRemaining(450, 300)).toBe('1:30')
  })

  it('should pad seconds with leading zero', () => {
    expect(formatTimeRemaining(15, 300)).toBe('0:03')
    expect(formatTimeRemaining(25, 300)).toBe('0:05')
  })

  it('should return 0:00 for zero remaining words', () => {
    expect(formatTimeRemaining(0, 300)).toBe('0:00')
  })

  it('should return 0:00 for invalid WPM', () => {
    expect(formatTimeRemaining(100, 0)).toBe('0:00')
    expect(formatTimeRemaining(100, -100)).toBe('0:00')
  })

  it('should handle negative remaining words', () => {
    expect(formatTimeRemaining(-10, 300)).toBe('0:00')
  })
})

describe('splitWordForDisplay', () => {
  it('should split word at the middle letter', () => {
    // 'hello' has ORP at index 2 (letter 'l')
    const result = splitWordForDisplay('hello')
    expect(result).toEqual({ before: 'he', orp: 'l', after: 'lo' })
  })

  it('should handle short words', () => {
    // 'cat' has ORP at index 1 (letter 'a')
    const result = splitWordForDisplay('cat')
    expect(result).toEqual({ before: 'c', orp: 'a', after: 't' })
  })

  it('should handle single letter words', () => {
    const result = splitWordForDisplay('I')
    expect(result).toEqual({ before: '', orp: 'I', after: '' })
  })

  it('should handle empty input', () => {
    expect(splitWordForDisplay('')).toEqual({ before: '', orp: '', after: '' })
    expect(splitWordForDisplay(null)).toEqual({ before: '', orp: '', after: '' })
  })

  it('should handle words with leading punctuation', () => {
    // '"hello' - ORP on the middle letter 'l'
    const result = splitWordForDisplay('"hello')
    expect(result.orp).toBe('l')
    expect(result.before).toBe('"he')
    expect(result.after).toBe('lo')
  })
})

describe('getWordFontSize', () => {
  it('should return null for short words (CSS clamp handles them)', () => {
    expect(getWordFontSize('hello')).toBeNull()
    expect(getWordFontSize('beautiful')).toBeNull() // 9 letters
    expect(getWordFontSize('presentation')).toBe(2.5) // 12 letters: 30 / 12
    expect(getWordFontSize('international')).toBeCloseTo(30 / 13, 5)
  })

  it('should shrink long words so they fit a phone screen', () => {
    expect(getWordFontSize('supercalifragilistic')).toBe(1.5) // 20 letters
    expect(getWordFontSize('supercalifragilisticexpialidocious')).toBe(1.4) // floor
  })

  it('should ignore punctuation when counting letters', () => {
    expect(getWordFontSize("don't")).toBeNull()       // 5 letters
    expect(getWordFontSize('extraordinary.')).toBeCloseTo(30 / 13, 5)
  })

  it('should return null for empty/null input', () => {
    expect(getWordFontSize('')).toBeNull()
    expect(getWordFontSize(null)).toBeNull()
    expect(getWordFontSize(undefined)).toBeNull()
  })
})

describe('shouldPauseAtWord', () => {
  it('should return false when pauseAfterWords is 0', () => {
    expect(shouldPauseAtWord(10, 0)).toBe(false)
    expect(shouldPauseAtWord(20, 0)).toBe(false)
  })

  it('should return false for first word', () => {
    expect(shouldPauseAtWord(0, 10)).toBe(false)
  })

  it('should return true at correct intervals', () => {
    expect(shouldPauseAtWord(10, 10)).toBe(true)
    expect(shouldPauseAtWord(20, 10)).toBe(true)
    expect(shouldPauseAtWord(30, 10)).toBe(true)
  })

  it('should return false between intervals', () => {
    expect(shouldPauseAtWord(5, 10)).toBe(false)
    expect(shouldPauseAtWord(15, 10)).toBe(false)
    expect(shouldPauseAtWord(25, 10)).toBe(false)
  })

  it('should work with different interval values', () => {
    expect(shouldPauseAtWord(5, 5)).toBe(true)
    expect(shouldPauseAtWord(25, 25)).toBe(true)
  })
})

describe('extractWordFrame', () => {
  const words = ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten']

  it('should extract a centered frame of words', () => {
    const result = extractWordFrame(words, 5, 5)
    expect(result.subset).toEqual(['four', 'five', 'six', 'seven', 'eight'])
    expect(result.centerOffset).toBe(2)
  })

  it('should handle frame at the beginning', () => {
    const result = extractWordFrame(words, 1, 5)
    expect(result.subset).toEqual(['one', 'two', 'three', 'four'])
    expect(result.centerOffset).toBe(1)
  })

  it('should handle frame at the end', () => {
    const result = extractWordFrame(words, 8, 5)
    expect(result.subset).toEqual(['seven', 'eight', 'nine', 'ten'])
    expect(result.centerOffset).toBe(2)
  })

  it('should handle frame size of 1', () => {
    const result = extractWordFrame(words, 5, 1)
    expect(result.subset).toEqual(['six'])
    expect(result.centerOffset).toBe(0)
  })

  it('should handle center index beyond array length', () => {
    const result = extractWordFrame(words, 15, 5)
    expect(result.subset).toEqual([''])
    expect(result.centerOffset).toBe(0)
  })

  it('should handle even frame sizes', () => {
    const result = extractWordFrame(words, 5, 4)
    expect(result.subset).toEqual(['four', 'five', 'six', 'seven', 'eight'])
    expect(result.centerOffset).toBe(2)
  })

  it('should handle large frame sizes', () => {
    const result = extractWordFrame(words, 3, 20)
    expect(result.subset).toEqual(words)
    expect(result.centerOffset).toBe(3)
  })

  it('should handle first word', () => {
    const result = extractWordFrame(words, 0, 5)
    expect(result.subset).toEqual(['one', 'two', 'three'])
    expect(result.centerOffset).toBe(0)
  })

  it('should handle last word', () => {
    const result = extractWordFrame(words, 9, 5)
    expect(result.subset).toEqual(['eight', 'nine', 'ten'])
    expect(result.centerOffset).toBe(2)
  })
})
