/**
 * Reading font choices for the focus display.
 *
 * Stacks are CSS variable references: the actual font-family lists live in
 * app.css design tokens (--font-sans, --font-serif, --font-mono,
 * --font-dyslexic), so the UI and the layout share a single source of truth.
 */

export const FONT_CHOICES = [
  { id: 'sans', label: 'Sans' },
  { id: 'serif', label: 'Serif' },
  { id: 'mono', label: 'Mono' },
  { id: 'dyslexic', label: 'Dyslexia' }
];

/**
 * Resolve a font choice id to its CSS variable reference.
 * Unknown or missing choices gracefully fall back to the default sans stack.
 *
 * @param {string|undefined|null} choice - Font choice id from FONT_CHOICES
 * @returns {string} CSS var() reference for the font-family
 */
export function getFontStack(choice) {
  switch (choice) {
    case 'serif':
      return 'var(--font-serif)';
    case 'mono':
      return 'var(--font-mono)';
    case 'dyslexic':
      return 'var(--font-dyslexic)';
    case 'sans':
    default:
      return 'var(--font-sans)';
  }
}