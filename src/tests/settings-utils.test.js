import { describe, it, expect } from 'vitest';
import { buildSettingsPayload, mergeSettings } from '../lib/settings-utils.js';

describe('buildSettingsPayload', () => {
  it('should return an object with every expected setting key', () => {
    const payload = buildSettingsPayload({ wordsPerMinute: 400 });
    expect(Object.keys(payload).sort()).toEqual([
      'fadeDuration',
      'fadeEnabled',
      'fontChoice',
      'frameWordCount',
      'glowBackground',
      'glowEnabled',
      'glowFocus',
      'glowInterface',
      'patternEnabled',
      'pauseAfterWords',
      'pauseDuration',
      'pauseOnPunctuation',
      'punctuationPauseMultiplier',
      'wordLengthWPMMultiplier',
      'wordsPerMinute'
    ]);
  });

  it('should map input values through unchanged', () => {
    const values = {
      wordsPerMinute: 425,
      fadeEnabled: false,
      fadeDuration: 200,
      pauseOnPunctuation: false,
      punctuationPauseMultiplier: 1.5,
      wordLengthWPMMultiplier: 0,
      pauseAfterWords: 10,
      pauseDuration: 1200,
      frameWordCount: 3,
      glowEnabled: false,
      glowBackground: false,
      glowFocus: false,
      glowInterface: false,
      patternEnabled: true,
      fontChoice: 'mono'
    };
    const payload = buildSettingsPayload(values);
    for (const [key, value] of Object.entries(values)) {
      expect(payload[key], `payload[${key}]`).toBe(value);
    }
  });

  it('should fill missing keys with false or glyph defaults (no undefined)', () => {
    const payload = buildSettingsPayload({});
    for (const value of Object.values(payload)) {
      expect(value, `value ${value}`).not.toBeUndefined();
    }
  });
});

describe('mergeSettings', () => {
  const defaults = {
    wordsPerMinute: 300,
    glowEnabled: true,
    fontChoice: 'sans',
    pauseAfterWords: 0
  };

  it('should override defaults with saved values', () => {
    const merged = mergeSettings({ wordsPerMinute: 500, fontChoice: 'serif' }, defaults);
    expect(merged).toEqual({
      wordsPerMinute: 500,
      glowEnabled: true,
      fontChoice: 'serif',
      pauseAfterWords: 0
    });
  });

  it('should fall back to defaults for missing keys', () => {
    const merged = mergeSettings({ wordsPerMinute: 350 }, defaults);
    expect(merged.wordsPerMinute).toBe(350);
    expect(merged.glowEnabled).toBe(true);
    expect(merged.fontChoice).toBe('sans');
    expect(merged.pauseAfterWords).toBe(0);
  });

  it('should ignore unknown keys from the saved object', () => {
    const merged = mergeSettings({ wordsPerMinute: 400, rsvpOldSetting: 9 }, defaults);
    expect(merged).not.toHaveProperty('rsvpOldSetting');
    expect(Object.keys(merged).sort()).toEqual(Object.keys(defaults).sort());
  });

  it('should return defaults for null or undefined saved settings', () => {
    expect(mergeSettings(null, defaults)).toEqual(defaults);
    expect(mergeSettings(undefined, defaults)).toEqual(defaults);
  });

  it('should preserve falsy saved values like 0 and false', () => {
    const merged = mergeSettings({ pauseAfterWords: 0, glowEnabled: false }, defaults);
    expect(merged.pauseAfterWords).toBe(0);
    expect(merged.glowEnabled).toBe(false);
  });

  it('should fall back to defaults for explicit null values', () => {
    const merged = mergeSettings({ fontChoice: null, wordsPerMinute: 500 }, defaults);
    expect(merged.fontChoice).toBe('sans');
    expect(merged.wordsPerMinute).toBe(500);
  });
});