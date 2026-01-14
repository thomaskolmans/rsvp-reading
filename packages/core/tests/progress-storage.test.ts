import { describe, it, expect, beforeEach, vi } from 'vitest'
import {
  saveSession,
  loadSession,
  hasSession,
  clearSession,
  getSessionSummary,
  percentageToWordIndex,
  wordIndexToPercentage
} from '../src/progress-storage'

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {}
  return {
    getItem: vi.fn((key: string) => store[key] || null),
    setItem: vi.fn((key: string, value: string) => { store[key] = value }),
    removeItem: vi.fn((key: string) => { delete store[key] }),
    clear: vi.fn(() => { store = {} })
  }
})()

Object.defineProperty(globalThis, 'localStorage', {
  value: localStorageMock
})

describe('progress-storage', () => {
  beforeEach(() => {
    localStorageMock.clear()
    vi.clearAllMocks()
  })

  describe('saveSession', () => {
    it('should save session data to localStorage', () => {
      const session = {
        text: 'Hello world test',
        currentWordIndex: 5,
        totalWords: 100,
        settings: {
          wordsPerMinute: 300,
          fadeEnabled: true
        }
      }

      const result = saveSession(session)

      expect(result).toBe(true)
      expect(localStorageMock.setItem).toHaveBeenCalled()

      const savedData = JSON.parse(localStorageMock.setItem.mock.calls[0][1])
      expect(savedData.text).toBe('Hello world test')
      expect(savedData.currentWordIndex).toBe(5)
      expect(savedData.totalWords).toBe(100)
      expect(savedData.settings.wordsPerMinute).toBe(300)
      expect(savedData.savedAt).toBeDefined()
    })

    it('should include timestamp in saved data', () => {
      const before = Date.now()

      saveSession({
        text: 'Test',
        currentWordIndex: 0,
        totalWords: 1,
        settings: {}
      })

      const after = Date.now()
      const savedData = JSON.parse(localStorageMock.setItem.mock.calls[0][1])

      expect(savedData.savedAt).toBeGreaterThanOrEqual(before)
      expect(savedData.savedAt).toBeLessThanOrEqual(after)
    })
  })

  describe('loadSession', () => {
    it('should return null when no session exists', () => {
      const result = loadSession()
      expect(result).toBeNull()
    })

    it('should load and parse session data', () => {
      const sessionData = {
        text: 'Test text',
        currentWordIndex: 10,
        totalWords: 50,
        settings: { wordsPerMinute: 400 },
        savedAt: Date.now()
      }
      localStorageMock.getItem.mockReturnValueOnce(JSON.stringify(sessionData))

      const result = loadSession()

      expect(result).toEqual(sessionData)
    })

    it('should return null for invalid JSON', () => {
      localStorageMock.getItem.mockReturnValueOnce('invalid json{')

      const result = loadSession()

      expect(result).toBeNull()
    })
  })

  describe('hasSession', () => {
    it('should return false when no session exists', () => {
      expect(hasSession()).toBe(false)
    })

    it('should return true when session exists', () => {
      localStorageMock.getItem.mockReturnValueOnce('{"text":"test"}')

      expect(hasSession()).toBe(true)
    })
  })

  describe('clearSession', () => {
    it('should remove session from localStorage', () => {
      clearSession()

      expect(localStorageMock.removeItem).toHaveBeenCalledWith('rsvp-reading-session')
    })

    it('should return true on success', () => {
      expect(clearSession()).toBe(true)
    })
  })

  describe('getSessionSummary', () => {
    it('should return null when no session exists', () => {
      expect(getSessionSummary()).toBeNull()
    })

    it('should return summary without full text', () => {
      const sessionData = {
        text: 'This is a very long text...',
        currentWordIndex: 25,
        totalWords: 100,
        savedAt: 1234567890
      }
      localStorageMock.getItem.mockReturnValueOnce(JSON.stringify(sessionData))

      const summary = getSessionSummary()

      expect(summary!.currentWordIndex).toBe(25)
      expect(summary!.totalWords).toBe(100)
      expect(summary!.savedAt).toBe(1234567890)
      expect(summary!.hasText).toBe(true)
      expect('text' in summary! === false || (summary as { text?: string }).text === undefined).toBe(true)
    })

    it('should indicate when text is missing', () => {
      const sessionData = {
        currentWordIndex: 25,
        totalWords: 100,
        savedAt: 1234567890
      }
      localStorageMock.getItem.mockReturnValueOnce(JSON.stringify(sessionData))

      const summary = getSessionSummary()

      expect(summary!.hasText).toBe(false)
    })
  })

  describe('percentageToWordIndex', () => {
    it('should convert percentage to word index', () => {
      expect(percentageToWordIndex(0, 100)).toBe(0)
      expect(percentageToWordIndex(50, 100)).toBe(50)
      expect(percentageToWordIndex(100, 100)).toBe(100)
    })

    it('should handle decimal percentages', () => {
      expect(percentageToWordIndex(25.5, 100)).toBe(25)
      expect(percentageToWordIndex(33.33, 300)).toBe(99)
    })

    it('should clamp values to 0-100 range', () => {
      expect(percentageToWordIndex(-10, 100)).toBe(0)
      expect(percentageToWordIndex(150, 100)).toBe(100)
    })

    it('should return 0 for invalid totalWords', () => {
      expect(percentageToWordIndex(50, 0)).toBe(0)
      expect(percentageToWordIndex(50, -10)).toBe(0)
    })
  })

  describe('wordIndexToPercentage', () => {
    it('should convert word index to percentage', () => {
      expect(wordIndexToPercentage(0, 100)).toBe(0)
      expect(wordIndexToPercentage(50, 100)).toBe(50)
      expect(wordIndexToPercentage(100, 100)).toBe(100)
    })

    it('should round to nearest integer', () => {
      expect(wordIndexToPercentage(33, 100)).toBe(33)
      expect(wordIndexToPercentage(1, 3)).toBe(33)
    })

    it('should return 0 for invalid totalWords', () => {
      expect(wordIndexToPercentage(50, 0)).toBe(0)
      expect(wordIndexToPercentage(50, -10)).toBe(0)
    })
  })
})
