import { describe, it, expect } from 'vitest'
import { FONT_CHOICES, getFontStack } from '../lib/fonts.js'

describe('getFontStack', () => {
  it('should return the sans stack for the default choice', () => {
    expect(getFontStack('sans')).toBe('var(--font-sans)')
  })

  it('should return the serif stack for the serif choice', () => {
    expect(getFontStack('serif')).toBe('var(--font-serif)')
  })

  it('should return the mono stack for the mono choice', () => {
    expect(getFontStack('mono')).toBe('var(--font-mono)')
  })

  it('should return the dyslexic stack for the dyslexic choice', () => {
    expect(getFontStack('dyslexic')).toBe('var(--font-dyslexic)')
  })

  it('should fall back to the sans stack for unknown choices', () => {
    expect(getFontStack('gothic')).toBe('var(--font-sans)')
  })

  it('should fall back to the sans stack for empty or missing input', () => {
    expect(getFontStack('')).toBe('var(--font-sans)')
    expect(getFontStack(null)).toBe('var(--font-sans)')
    expect(getFontStack(undefined)).toBe('var(--font-sans)')
  })
})

describe('FONT_CHOICES', () => {
  it('should expose every choice that getFontStack knows', () => {
    for (const choice of FONT_CHOICES) {
      expect(getFontStack(choice.id)).not.toBe('')
    }
  })

  it('should contain four distinct choices with labels', () => {
    expect(FONT_CHOICES).toHaveLength(4)
    const ids = FONT_CHOICES.map((c) => c.id)
    expect(new Set(ids).size).toBe(4)
    for (const choice of FONT_CHOICES) {
      expect(choice.label).toBeTruthy()
    }
  })
})