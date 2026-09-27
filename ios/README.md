# Speed Reader — iOS

Native iPhone app for focused speed reading: words appear one at a time at a
fixed focal point, a port of the [web version](../README.md) in this
repository. Built with SwiftUI, no third-party dependencies — PDF import uses
PDFKit, EPUB/DOCX import uses a built-in ZIP/DEFLATE reader and XMLParser, FB2
is parsed as XML directly. Includes a Share Extension (share text or article
links from Safari/Messages straight into the reader) and English/Russian
localization with an in-app language switcher (System / English / Русский).

## Feature parity with the web app

- One-word-at-a-time display with **ORP highlighting** (red focus letter, pinned to
  the screen center, monospaced font, top/bottom focus markers)
- Reading speed **50–1000 WPM** with presets (200/300/400/500) and extra slowdown
  for long words (0–50% per character above 12)
- **Multi-word mode**: 1/3/5/7 words shown simultaneously with the highlighted
  word centered and context words dimmed
- **Fade effect** between words (toggle + 50–300 ms duration)
- **Pauses**: sentence punctuation multiplier (1–4×), periodic comprehension pause
  every N words (0–50) with configurable duration (100–2000 ms)
- **Progress**: seekable progress bar (tap/drag), word counter, WPM, time remaining
- **Jump to position**: word number or `50%`-style input plus quick presets
  (Start / 25% / 50% / 75%)
- **Save / resume session**: position, text and settings persist between launches
  (UserDefaults instead of localStorage), with a resume prompt on launch
- **Content loading**: paste text, or import **PDF / EPUB / TXT / FB2 / DOCX** via
  the document picker or "Open in Speed Reader" from the Files app. TXT decodes as
  UTF-8 with a Windows-1251 fallback (common for legacy Russian books); FB2 and
  DOCX follow their declared encodings (ZIP + XML parsing, tables included)
- **Focus mode**: minimal UI while playing/paused, dark theme
- Touch controls: back/forward 5 words, ±50 WPM on the fly
- Unicode-aware ORP (Latin, Cyrillic, Greek, CJK, accents) and RTL word mirroring

## Mobile-native UX (beyond the web version)

- **Tap the word** to play / pause / resume — the touch replacement for the web's `Space`
- **Long-press the word** (or the ↺ button) to repeat the current sentence
- **Vertical swipe on the word**: up = +25 WPM, down = −25 WPM without leaving focus mode
- **Screen stays awake** while reading (idle timer disabled during playback)
- **Paused state is actionable**: speed/word touch row, word count / WPM / time-remaining
  stats and the seekable progress bar stay available mid-session
- **Library** (books icon): every imported/read document is kept with its position —
  deduplicated by text hash (SHA-256), capped at 20 entries, swipe to delete; tap to
  reopen where you left off
- **Reading statistics**: words today / last 7 days / all time with a 7-day mini chart.
  Only words actually played back count (scrubbing does not); writes are batched and
  daily buckets are trimmed to 30 days
- **Auto-save on backgrounding**: position, text and settings persist when the app
  goes to the background or is killed (mobile replacement for `Ctrl+S`)
- **Auto-apply imported files**: a picked PDF/EPUB/TXT loads immediately, no extra tap
- **Haptics**: light impact on play/pause, success notification when the text finishes
- **Play at the end** restarts the text from the beginning
- **Alert on failed import** (e.g. corrupt file opened via "Open in Speed Reader")
- **Share Extension**: share selected text or a page URL from any app — plain text is
  stored directly, URLs are fetched and the article text extracted (tag-stripping
  fallback); hand-off via the shared App Group, picked up on the next app launch or
  through the `speedreader://` URL scheme
- **Localization**: full Russian translation (English keys as base,
  `ru.lproj/Localizable.strings` in both targets); in-app **language choice**
  (System / English / Русский) in Settings overrides the device language via
  `AppleLanguages` and applies from the next launch
- **Word font size**: 28–64 pt slider in settings; multi-word frames scale down
  proportionally so the whole frame fits one line
- **Background themes**: Black (default), Charcoal, Navy, Sepia and White with
  adaptive text/chip colors — light themes also switch the system appearance
- **Reading orientation**: Portrait, Landscape or Auto. Choosing a fixed
  orientation locks the app to it (the landscape mode gives the word display a
  wider centered area, which reduces eye travel at high WPM)
- Black launch screen and generated app icon (`ios/Tools/make_icon.swift` re-renders it)

Keyboard shortcuts from the web version do not apply on iPhone and are intentionally
not ported.

## Project layout

```
ios/
├── SpeedReader.xcodeproj
├── SpeedReader/
│   ├── SpeedReaderApp.swift        # App entry point
│   ├── ContentView.swift           # Main screen (App.svelte parity)
│   ├── Info.plist                  # Document types, URL scheme, launch screen
│   ├── SpeedReader.entitlements    # App Group for the Share Extension hand-off
│   ├── ru.lproj/Localizable.strings
│   ├── Core/
│   │   ├── ReadingUtils.swift      # ORP, delays, frames, sentence repeat (reading-utils.js port)
│   │   ├── TextCleaner.swift       # Extracted-text normalization
│   │   ├── ReaderSettings.swift    # Codable settings + SavedSession
│   │   ├── SessionStore.swift      # Session persistence (progress-storage.js port)
│   │   ├── LibraryStore.swift      # Recent-documents library (dedupe, cap 20)
│   │   ├── StatsStore.swift        # Reading statistics (batched, 30-day buckets)
│   │   ├── AppGroupStore.swift     # Share Extension → app hand-off channel
│   │   ├── LanguageOverride.swift  # In-app language choice (AppleLanguages)
│   │   └── ReaderEngine.swift      # Playback engine (ObservableObject)
│   ├── Views/
│   │   ├── WordStage.swift             # ORP-centered word display (WordStage.svelte port)
│   │   ├── ProgressBarView.swift       # Seekable progress + stats
│   │   ├── PlaybackControlsView.swift
│   │   ├── SettingsSheet.swift
│   │   ├── TextInputSheet.swift
│   │   ├── JumpToSheet.swift
│   │   ├── LibrarySheet.swift         # Documents + reading statistics
│   │   ├── ThemeColors.swift          # ReaderThemeKind → adaptive color palette
│   │   ├── OrientationLock.swift      # UIApplicationDelegate orientation lock
│   │   └── ReaderHeaderView.swift     # Top bar (title + action buttons)
│   └── FileParsers/
│       ├── PdfTextExtractor.swift # PDFKit
│       ├── ZipArchive.swift       # Minimal ZIP + raw DEFLATE (libcompression)
│       ├── EpubParser.swift       # container.xml → OPF spine → XHTML text
│       ├── Fb2Parser.swift        # FictionBook 2.x XML → body paragraphs
│       ├── DocxParser.swift       # word/document.xml → paragraphs/runs
│       └── FileImportService.swift
├── ShareExtension/
│   ├── ShareViewController.swift  # Text/URL extraction, article fetch, App Group save
│   ├── Info.plist                 # Activation rule: text + web page/URL
│   ├── SpeedReaderShareExtension.entitlements
│   └── ru.lproj/Localizable.strings
├── Tools/
│   └── make_icon.swift            # App icon generator (AppKit)
└── Tests/
    ├── ReadingUtilsTests.swift    # 90 assertions
    ├── ReaderEngineTests.swift    # 71 assertions (incl. settings theme/font/orientation/language decode)
    ├── LibraryStatsTests.swift    # 29 assertions
    ├── AppGroupStoreTests.swift   # 7 assertions
    ├── FileParsersTests.swift     # 17 assertions (FB2/DOCX/TXT encodings, routing)
    ├── LanguageOverrideTests.swift # 10 assertions (AppleLanguages override/reset)
    ├── Fixtures/                  # sample.fb2/-docx/-epub/-txt/-rtf (regenerate with make_fixtures.py)
    └── make_fixtures.py           # Fixture generator (python3, no deps)
```

## Requirements

- Xcode 15+ (built and verified with Xcode 26.3), iOS 17.0+ deployment target

## Build & run

```bash
# Open in Xcode and press Cmd+R, or from the CLI:
xcodebuild -project ios/SpeedReader.xcodeproj -scheme SpeedReader \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Or run on a booted simulator:
xcrun simctl install <udid> <path-to-SpeedReader.app>
xcrun simctl launch <udid> app.speedreader
```

## Tests

Five standalone suites (Foundation-only code, no simulator needed), mirroring the web
app's `src/tests/reading-utils.test.js` plus engine/store coverage:

```bash
# Core logic: ORP math, delays, frames, sentence repeat, percentages (90 assertions)
swiftc ios/SpeedReader/Core/ReadingUtils.swift ios/SpeedReader/Core/TextCleaner.swift \
       ios/Tests/ReadingUtilsTests.swift -o /tmp/reading_tests && /tmp/reading_tests

# Engine: navigation, jump parsing, WPM clamps, session roundtrip, settings
# decoding (theme/font/orientation/language), transport (71 assertions)
swiftc ios/SpeedReader/Core/ReadingUtils.swift ios/SpeedReader/Core/TextCleaner.swift \
       ios/SpeedReader/Core/ReaderSettings.swift ios/SpeedReader/Core/SessionStore.swift \
       ios/SpeedReader/Core/ReaderEngine.swift ios/SpeedReader/Core/LibraryStore.swift ios/SpeedReader/Core/StatsStore.swift \
       ios/Tests/ReaderEngineTests.swift -o /tmp/engine_tests && /tmp/engine_tests

# Library + stats stores: dedupe, cap, delete, batching, trim (29 assertions)
swiftc ios/SpeedReader/Core/LibraryStore.swift ios/SpeedReader/Core/StatsStore.swift \
       ios/Tests/LibraryStatsTests.swift -o /tmp/library_tests && /tmp/library_tests

# Share Extension hand-off channel (7 assertions)
swiftc ios/SpeedReader/Core/AppGroupStore.swift ios/Tests/AppGroupStoreTests.swift \
       -o /tmp/appgroup_tests && /tmp/appgroup_tests

# File parsers: FB2/DOCX extraction, TXT encodings, routing (17 assertions)
# Generate fixtures first:  python3 ios/Tests/make_fixtures.py
swiftc ios/SpeedReader/Core/TextCleaner.swift ios/SpeedReader/FileParsers/*.swift \
       ios/Tests/FileParsersTests.swift -o /tmp/fileparsers_tests && /tmp/fileparsers_tests

# In-app language override: AppleLanguages write/reset, launch re-apply (10 assertions)
swiftc ios/SpeedReader/Core/ReaderSettings.swift ios/SpeedReader/Core/LanguageOverride.swift \
       ios/Tests/LanguageOverrideTests.swift -o /tmp/language_tests && /tmp/language_tests
```

The fixture files in `ios/Tests/Fixtures/` are committed; regenerate them any time
with `python3 ios/Tests/make_fixtures.py` (stdlib only).

## Differences from the web version

| Web | iOS |
|-----|-----|
| pdfjs-dist / epubjs | PDFKit / built-in ZIP+XMLParser |
| localStorage | UserDefaults |
| Keyboard shortcuts | Touch controls only |
| CSS absolute positioning for ORP | Monospace advance-width math + `.position` |
| Fade via CSS opacity transition | SwiftUI `.transition(.opacity)` |