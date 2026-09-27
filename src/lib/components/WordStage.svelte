<script>
  import { getActualORPIndex, getWordFontSize } from '../reading-utils.js';

  export let word = '';
  export let wordGroup = [];
  export let highlightIndex = 0;
  export let opacity = 1;
  export let fadeDuration = 150;
  export let fadeEnabled = true;
  export let multiWordEnabled = false;
  export let patternEnabled = false;

  $: useMultiMode = multiWordEnabled && wordGroup.length > 0;

  // Get the current word (either from single mode or the highlighted word in group)
  $: currentWord = useMultiMode ? (wordGroup[highlightIndex] || '') : word;

  // Always calculate ORP for the current word
  $: orpIdx = currentWord ? getActualORPIndex(currentWord) : -1;
  $: wordPrefix = currentWord ? currentWord.slice(0, orpIdx) : '';
  $: focusChar = currentWord ? (currentWord[orpIdx] || '') : '';
  $: wordSuffix = currentWord ? currentWord.slice(orpIdx + 1) : '';

  // Long single words shrink so they don't overflow the screen edge
  $: fontSizeRem = getWordFontSize(currentWord);
  $: fontSizeStyle = useMultiMode || fontSizeRem == null ? '' : `${fontSizeRem}rem`;

  // Words before and after the highlighted word (for multi-word mode)
  $: wordsBefore = useMultiMode ? wordGroup.slice(0, highlightIndex) : [];
  $: wordsAfter = useMultiMode ? wordGroup.slice(highlightIndex + 1) : [];

  // FIX: Detect Hebrew, Arabic, and other RTL scripts
  $: isRtl = /[\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC]/.test(currentWord);
</script>

<div class="word-stage">
  <div class="stage-glow" aria-hidden="true"></div>

  <div class="focus-marker">
    <div class="marker-line top"></div>
    <div class="marker-line bottom"></div>
  </div>

  {#if currentWord}
    {#if patternEnabled}
      <!-- Concentration pattern: symmetric star + rings "gates" passing by -->
      <div class="focus-pattern" aria-hidden="true">
        <div class="pattern-star">
          <span class="star-a"></span>
          <span class="star-b"></span>
        </div>
        <span class="gate g1"></span>
        <span class="gate g2"></span>
        <span class="gate g3"></span>
      </div>
    {/if}

    <div
      class="word-container"
      class:multi-mode={useMultiMode}
      style="opacity: {opacity}; transition: opacity {fadeEnabled ? fadeDuration : 0}ms ease-in-out;{fontSizeStyle ? ` --word-font: ${fontSizeStyle};` : ''}"
    >
      <!-- ORP letter always centered at 50% -->
      <span class="orp">{focusChar}</span>

      <!-- Content before ORP: prefix of current word + words before -->
      <span class="before-orp" style="direction: {isRtl ? 'rtl' : 'ltr'}">
        {#if isRtl}
          {wordSuffix}{#if useMultiMode && wordsAfter.length > 0}
            &nbsp;<span class="context-words">{wordsAfter.join(' ')}</span>
          {/if}
        {:else}
          {#if useMultiMode && wordsBefore.length > 0}
            <span class="context-words">{wordsBefore.join(' ')}</span>&nbsp;
          {/if}{wordPrefix}
        {/if}
      </span>

      <!-- Content after ORP: suffix of current word + words after -->
      <span class="after-orp" style="direction: {isRtl ? 'rtl' : 'ltr'}">
        {#if isRtl}
          {#if useMultiMode && wordsBefore.length > 0}
            <span class="context-words">{wordsBefore.join(' ')}</span>&nbsp;
          {/if}{wordPrefix}
        {:else}
          {wordSuffix}{#if useMultiMode && wordsAfter.length > 0}
            &nbsp;<span class="context-words">{wordsAfter.join(' ')}</span>
          {/if}
        {/if}
      </span>
    </div>
  {:else}
    <!-- Standby state shown before any content is loaded -->
    <div class="standby">
      <span class="standby-dot" aria-hidden="true"></span>
      <span class="standby-title">Ready</span>
      <span class="standby-hint">Load content to begin</span>
    </div>
  {/if}
</div>

<style>
  .word-stage {
    position: relative;
    width: 100%;
    height: 100%;
    min-height: 300px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex: 1;
    overflow: hidden;
  }

  /* Soft halo behind the reading position */
  .stage-glow {
    position: absolute;
    top: 12%;
    left: 0;
    right: 0;
    height: 60%;
    background: radial-gradient(ellipse at 50% 50%, rgba(122, 138, 208, 0.055) 0%, transparent 62%);
    opacity: var(--glow-ambient, 1);
    pointer-events: none;
    z-index: 0;
  }

  /* ── Concentration pattern ────────────────────────────────── */
  .focus-pattern {
    position: absolute;
    inset: 0;
    pointer-events: none;
    opacity: var(--glow-ambient, 1);
    z-index: 0;
  }

  /* Symmetric polygonal star, slowly counter-rotating layers */
  .pattern-star {
    position: absolute;
    left: 50%;
    top: 50%;
    width: 46vmin;
    height: 46vmin;
  }

  .star-a,
  .star-b {
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    border: 1.5px solid rgba(150, 161, 222, 0.2);
    border-radius: 6%;
    transform-origin: 50% 50%;
  }

  .star-a {
    animation: star-spin-a 80s linear infinite;
  }

  .star-b {
    border-style: dashed;
    animation: star-spin-b 120s linear infinite;
  }

  @keyframes star-spin-a {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }

  @keyframes star-spin-b {
    from { transform: rotate(45deg); }
    to { transform: rotate(-675deg); }
  }

  /* Expanding "gates" the reader passes through */
  .gate {
    position: absolute;
    left: 50%;
    top: 50%;
    width: 30vmin;
    height: 30vmin;
    border: 1.5px solid rgba(150, 161, 222, 0.22);
    border-radius: 50%;
    animation: gate-pass 4.8s cubic-bezier(0.4, 0, 0.2, 1) infinite;
  }

  .g2 {
    border-color: rgba(255, 92, 122, 0.2);
    animation-delay: 1.6s;
  }

  .g3 {
    animation-delay: 3.2s;
  }

  @keyframes gate-pass {
    0% {
      transform: translate(-50%, -50%) scale(0.4);
      opacity: 0.8;
    }
    100% {
      transform: translate(-50%, -50%) scale(1.65);
      opacity: 0;
    }
  }

  .focus-marker {
    position: absolute;
    left: 50%;
    transform: translateX(-50%);
    height: 100%;
    width: 2px;
    pointer-events: none;
    z-index: 10;
  }

  .marker-line {
    position: absolute;
    left: 0;
    width: 100%;
    height: 64px;
  }

  .marker-line.top {
    top: 0;
    background: linear-gradient(to bottom, var(--accent), transparent);
    box-shadow: 0 0 14px var(--glow-ui);
  }

  .marker-line.bottom {
    bottom: 0;
    background: linear-gradient(to top, var(--accent), transparent);
    box-shadow: 0 0 14px var(--glow-ui);
  }

  .word-container {
    position: relative;
    font-family: var(--font-reading);
    /* Long words supply --word-font via getWordFontSize() so they fit on screen */
    font-size: var(--word-font, clamp(3rem, 8vw, 6rem));
    font-weight: 500;
    line-height: 1;
    white-space: nowrap;
    text-rendering: geometricPrecision;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    /* Container needs width for absolute children to position against */
    width: 100%;
    height: 1.2em;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1;
  }

  .word-container.multi-mode {
    font-size: clamp(1.2rem, 4vw, 3rem);
  }

  .context-words {
    color: var(--text-3);
    font-weight: 400;
  }

  .orp {
    position: absolute;
    left: 50%;
    transform: translateX(-50%);
    color: var(--accent);
    font-weight: 700;
    text-shadow:
      0 0 2px rgba(255, 255, 255, 0.25),
      0 0 16px var(--glow-word),
      0 0 48px var(--glow-word);
    z-index: 2;
  }

  /* Anchor tick under the focus letter */
  .orp::after {
    content: '';
    position: absolute;
    left: 50%;
    top: 128%;
    width: 2px;
    height: 0.4em;
    transform: translateX(-50%);
    background: linear-gradient(to bottom, var(--accent), transparent);
    border-radius: 1px;
    box-shadow: 0 0 6px var(--glow-word);
    opacity: 0.8;
  }

  .before-orp {
    position: absolute;
    left: 50%;
    transform: translateX(calc(-100% - 0.5ch));
    color: var(--text-1);
    /* direction: ltr; -- REMOVED to support dynamic RTL/LTR via inline style */
    text-align: right; /* Keeps text growing towards the center */
  }

  .after-orp {
    position: absolute;
    left: calc(50% + 0.5ch);
    color: var(--text-1);
    text-align: left;
  }

  /* Standby state */
  .standby {
    position: absolute;
    inset: 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 0.9rem;
    z-index: 1;
  }

  .standby-dot {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    background: var(--accent);
    box-shadow: 0 0 14px var(--glow-ui-strong);
    animation: standby-pulse 2.4s ease-in-out infinite;
  }

  .standby-title {
    color: var(--text-2);
    font-family: var(--font-mono);
    font-size: 1.4rem;
    font-weight: 500;
    letter-spacing: 0.06em;
  }

  .standby-hint {
    color: var(--text-3);
    font-size: 0.85rem;
  }

  @keyframes standby-pulse {
    0%, 100% {
      transform: scale(1);
      opacity: 1;
    }
    50% {
      transform: scale(0.72);
      opacity: 0.55;
    }
  }

  @media (max-width: 600px) {
    .word-stage {
      min-height: 200px;
    }

    .marker-line {
      height: 36px;
    }

    .word-container.multi-mode {
      font-size: clamp(0.9rem, 3.5vw, 2rem);
    }

    .standby-title {
      font-size: 1.1rem;
    }
  }

  @media (max-width: 400px) {
    .word-container.multi-mode {
      font-size: clamp(0.75rem, 3vw, 1.5rem);
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .standby-dot {
      animation: none;
    }

    .star-a,
    .star-b,
    .gate {
      animation: none;
    }
  }
</style>