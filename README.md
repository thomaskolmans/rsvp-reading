# Speed Reader

A calm, focused speed reading app: words appear one at a time at a fixed focal
point, so your eyes stop scanning and your mind settles into a steady rhythm.

Built with Svelte 5 + Vite. Works offline as a PWA, supports PDF and EPUB
uploads, and keeps your reading session between visits.

## Features

- **Focus letter** — a highlighted letter anchors your gaze at the optimal
  recognition point of every word.
- **Font selection** — choose the reading font: Sans, Serif, Mono, or a
  Dyslexia-friendly face (Settings → Typography).
- **Adjustable speed** — 50–1000 words per minute, plus slower pacing for long
  words.
- **Ambient effects** — independently toggle background glow, the focus-letter
  glow, and interface glow (Settings → Ambient), or turn everything off.
- **Concentration pattern** — an optional symmetric star with passing rings
  behind the word to sharpen focus when you need it.
- **PDF & EPUB support** — upload documents directly in the browser.
- **Focus mode** — minimal UI during reading (press `Esc` to exit).
- **Punctuation & periodic pauses** — configurable breathing room for
  comprehension.
- **Progress tracking** — progress bar (click to seek), time remaining, and
  saved sessions you can resume later.
- **Keyboard-first** — full control without touching the mouse.

## Getting started

```bash
npm install
npm run dev        # development server
npm run build      # production build → dist/
npm run preview    # preview the production build
npm run test:run   # run unit tests
```

## Keyboard shortcuts

| Key | Action |
| --- | --- |
| `Space` | Play / pause / resume |
| `Esc` | Exit focus mode, close panels |
| `↑` / `↓` | Faster / slower |
| `←` / `→` | Skip backwards / forwards |
| `G` | Jump to word or percentage |
| `Ctrl+S` / `Cmd+S` | Save session |

## Project structure

```
src/
├── app.css                    # Design tokens (colors, glow gates, fonts)
├── App.svelte                 # Root component, session + settings wiring
├── main.js                    # Svelte mount point
├── lib/
│   ├── reading-utils.js       # Word parsing, delays, focus-point math
│   ├── fonts.js               # Reading font choices → CSS stacks
│   ├── file-parsers.js        # PDF / EPUB / TXT extraction
│   ├── progress-storage.js    # Session persistence (localStorage)
│   └── components/
│       ├── WordStage.svelte   # The reading surface (word, pattern, markers)
│       ├── Settings.svelte    # Glass settings panel
│       ├── Controls.svelte    # Play / pause / stop / restart
│       ├── ProgressBar.svelte # Seekable progress + stats
│       └── TextInput.svelte   # Text paste + file upload
└── tests/                     # Vitest unit tests (one file per module)
```

## Design system

The interface is driven by CSS custom properties defined in `src/app.css`:

- **Design tokens** — background, surfaces, lines, text, accent colors.
- **Glow gates** — components read `--glow-*` tokens; App flips them to
  `transparent`/`0` based on the Ambient settings, so every effect can be
  toggled declaratively without per-component logic.
- **Reading fonts** — `--font-reading` is set on `<main>` from Settings →
  Typography and consumed by the word display.

All settings are saved with the reading session and restored on the next
visit, with safe defaults for older saved sessions.

## Accessibility

- `prefers-reduced-motion` disables decorative animations.
- Visible `:focus-visible` outlines and switch/button roles for assistive tech.
- High-contrast text tokens with a dark, low-glare palette.

## Docker

```bash
cd docker
docker compose up -d   # serves the built app on port 8080
```

## Deployment

Live app: https://spid.reader.app/

A DigitalOcean App Platform spec (`do-app.yaml`) and a GitHub release workflow
are included; update the repository name placeholder in `do-app.yaml` before
deploying.

## License

MIT