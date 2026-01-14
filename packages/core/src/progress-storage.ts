/**
 * Progress storage utilities for persisting reading sessions
 */

const STORAGE_KEY = 'rsvp-reading-session'

export interface SessionSettings {
  wordsPerMinute?: number
  fadeEnabled?: boolean
  fadeDuration?: number
  pauseOnPunctuation?: boolean
  punctuationPauseMultiplier?: number
  pauseAfterWords?: number
  pauseDuration?: number
}

export interface Session {
  text: string
  currentWordIndex: number
  totalWords: number
  settings?: SessionSettings
}

export interface SavedSession extends Session {
  savedAt: number
}

export interface SessionSummary {
  currentWordIndex: number
  totalWords: number
  savedAt: number
  hasText: boolean
}

/**
 * Save the current reading session to localStorage
 * @param session - The session data to save
 * @returns Whether the save was successful
 */
export function saveSession(session: Session): boolean {
  try {
    const data: SavedSession = {
      text: session.text,
      currentWordIndex: session.currentWordIndex,
      totalWords: session.totalWords,
      settings: session.settings,
      savedAt: Date.now()
    }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data))
    return true
  } catch (error) {
    console.error('Failed to save session:', error)
    return false
  }
}

/**
 * Load a saved reading session from localStorage
 * @returns The saved session data or null if none exists
 */
export function loadSession(): SavedSession | null {
  try {
    const data = localStorage.getItem(STORAGE_KEY)
    if (!data) return null
    return JSON.parse(data) as SavedSession
  } catch (error) {
    console.error('Failed to load session:', error)
    return null
  }
}

/**
 * Check if a saved session exists
 * @returns Whether a saved session exists
 */
export function hasSession(): boolean {
  try {
    return localStorage.getItem(STORAGE_KEY) !== null
  } catch {
    return false
  }
}

/**
 * Clear the saved session from localStorage
 * @returns Whether the clear was successful
 */
export function clearSession(): boolean {
  try {
    localStorage.removeItem(STORAGE_KEY)
    return true
  } catch (error) {
    console.error('Failed to clear session:', error)
    return false
  }
}

/**
 * Get a summary of the saved session without loading full text
 * @returns Summary with wordIndex, totalWords, savedAt, or null
 */
export function getSessionSummary(): SessionSummary | null {
  try {
    const data = localStorage.getItem(STORAGE_KEY)
    if (!data) return null
    const parsed = JSON.parse(data) as SavedSession
    return {
      currentWordIndex: parsed.currentWordIndex,
      totalWords: parsed.totalWords,
      savedAt: parsed.savedAt,
      hasText: !!parsed.text
    }
  } catch {
    return null
  }
}

/**
 * Calculate word index from a percentage
 * @param percentage - Percentage (0-100)
 * @param totalWords - Total word count
 * @returns The word index
 */
export function percentageToWordIndex(percentage: number, totalWords: number): number {
  if (!totalWords || totalWords <= 0) return 0
  const clamped = Math.max(0, Math.min(100, percentage))
  return Math.floor((clamped / 100) * totalWords)
}

/**
 * Calculate percentage from word index
 * @param wordIndex - Current word index
 * @param totalWords - Total word count
 * @returns The percentage (0-100)
 */
export function wordIndexToPercentage(wordIndex: number, totalWords: number): number {
  if (!totalWords || totalWords <= 0) return 0
  return Math.round((wordIndex / totalWords) * 100)
}
