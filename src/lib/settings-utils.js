/**
 * Settings utilities: building the persisted payload and merging saved
 * settings back onto current defaults.
 */

/**
 * The canonical set of reader setting keys persisted in a session.
 */
export const SETTING_KEYS = [
  'wordsPerMinute',
  'fadeEnabled',
  'fadeDuration',
  'pauseOnPunctuation',
  'punctuationPauseMultiplier',
  'wordLengthWPMMultiplier',
  'pauseAfterWords',
  'pauseDuration',
  'frameWordCount',
  'glowEnabled',
  'glowBackground',
  'glowFocus',
  'glowInterface',
  'patternEnabled',
  'fontChoice'
];

/**
 * Build a persisted settings object from runtime values.
 * @param {Object} values - Setting values by key
 * @returns {Object} Payload containing only the known setting keys
 */
export function buildSettingsPayload(values) {
  const payload = {};
  for (const key of SETTING_KEYS) {
    payload[key] = values[key] ?? false;
  }
  return payload;
}

/**
 * Merge saved settings onto defaults, ignoring unknown keys.
 * @param {Object|null} saved - Settings loaded from storage
 * @param {Object} defaults - Current setting values
 * @returns {Object} Merged settings
 */
export function mergeSettings(saved, defaults) {
  const merged = {};
  for (const [key, fallback] of Object.entries(defaults)) {
    merged[key] = saved && saved[key] != null ? saved[key] : fallback;
  }
  return merged;
}