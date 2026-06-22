<script>
  import { getActualORPIndex } from '../rsvp-utils.js';

  export let word = '';
  export let wordGroup = [];
  export let highlightIndex = 0;
  export let opacity = 1;
  export let fadeDuration = 150;
  export let fadeEnabled = true;
  export let multiWordEnabled = false;

  $: useMultiMode = multiWordEnabled && wordGroup.length > 0;
  $: currentWord = useMultiMode ? (wordGroup[highlightIndex] || '') : word;
  $: orpIdx = currentWord ? getActualORPIndex(currentWord) : -1;
  $: wordPrefix = currentWord ? currentWord.slice(0, orpIdx) : '';
  $: focusChar = currentWord ? (currentWord[orpIdx] || '') : '';
  $: wordSuffix = currentWord ? currentWord.slice(orpIdx + 1) : '';
  $: wordsBefore = useMultiMode ? wordGroup.slice(0, highlightIndex) : [];
  $: wordsAfter = useMultiMode ? wordGroup.slice(highlightIndex + 1) : [];
  $: isRtl = /[\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC]/.test(currentWord);
  $: rtlDisplayWord = currentWord || '';
  $: rtlWordLength = currentWord ? currentWord.length : 1;
</script>

<div class="rsvp-display">
  <div class="focus-marker">
    <div class="marker-line top"></div>
    <div class="marker-line bottom"></div>
  </div>

  <div
    class="word-container"
    class:multi-mode={useMultiMode}
    style="opacity: {opacity}; transition: opacity {fadeEnabled ? fadeDuration : 0}ms ease-in-out;"
  >
    {#if currentWord}
      {#if isRtl}
        <span
          class="rtl-shaped-word"
          style="--orp-index: {orpIdx}; --word-length: {rtlWordLength}; --anchor-pad: 2%; --anchor-bottom: 0.35em;"
        >
          <span class="rtl-word-base">{rtlDisplayWord}</span>
          <span class="rtl-word-anchor" aria-hidden="true">{rtlDisplayWord}</span>
        </span>
      {:else}
        <span class="orp">{focusChar}</span>

        <span class="before-orp" style="direction: ltr">
          {#if useMultiMode && wordsBefore.length > 0}
            <span class="context-words">{wordsBefore.join(' ')}</span>&nbsp;
          {/if}{wordPrefix}
        </span>

        <span class="after-orp" style="direction: ltr">
          {wordSuffix}{#if useMultiMode && wordsAfter.length > 0}
            &nbsp;<span class="context-words">{wordsAfter.join(' ')}</span>
          {/if}
        </span>
      {/if}
    {:else}
      <span class="placeholder">Ready</span>
    {/if}
  </div>
</div>

<style>
  @font-face {
    font-family: 'Digilalezar';
    src: url('/fonts/digilalezar.woff2') format('woff2');
    font-weight: 400 900;
    font-style: normal;
    font-display: swap;
  }

  .rsvp-display {
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

  .focus-marker {
    position: absolute;
    left: 50%;
    transform: translateX(-50%);
    height: 100%;
    width: 3px;
    pointer-events: none;
    z-index: 10;
  }

  .marker-line {
    position: absolute;
    left: 0;
    width: 100%;
    height: 50px;
  }

  .marker-line.top {
    top: 0;
    background: linear-gradient(to bottom, #ff4444, transparent);
  }

  .marker-line.bottom {
    bottom: 0;
    background: linear-gradient(to top, #ff4444, transparent);
  }

  .word-container {
    position: relative;
    font-family: 'Digilalezar', system-ui, 'Segoe UI', Tahoma, Arial, sans-serif;
    font-size: clamp(3rem, 8vw, 6rem);
    font-weight: 500;
    line-height: 1;
    white-space: nowrap;
    text-rendering: geometricPrecision;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    width: 100%;
    height: 1.2em;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .word-container.multi-mode {
    font-size: clamp(1.2rem, 4vw, 3rem);
  }

  .context-words {
    color: #666;
    font-weight: 400;
  }

  .orp {
    position: absolute;
    left: 50%;
    transform: translateX(-50%);
    color: #ff4444;
    font-weight: 700;
    text-shadow: 0 0 30px rgba(255, 68, 68, 0.6);
    z-index: 2;
  }

  .before-orp {
    position: absolute;
    left: 50%;
    transform: translateX(calc(-100% - 0.5ch));
    color: #fff;
    text-align: right;
  }

  .after-orp {
    position: absolute;
    left: calc(50% + 0.5ch);
    color: #fff;
    text-align: left;
  }

.rtl-shaped-word {
  position: relative;
  direction: rtl;
  unicode-bidi: isolate;
  display: inline-block;
  font-family: 'Digilalezar', system-ui, 'Segoe UI', Tahoma, Arial, sans-serif;
  font-variant-ligatures: normal;
  letter-spacing: 0;
  text-rendering: optimizeLegibility;
  overflow: visible;
}

  .rtl-word-base,
  .rtl-word-anchor {
    direction: rtl;
    unicode-bidi: isolate;
    font: inherit;
    letter-spacing: inherit;
    white-space: nowrap;
  }

  .rtl-word-base {
    color: #fff;
  }

  .rtl-word-anchor {
    position: absolute;
    inset: 0 0 calc(-1 * var(--anchor-bottom)) 0;
    color: #ff4444;
    font-weight: 700;
    pointer-events: none;

    clip-path: inset(
      0
      max(0%, calc(((var(--orp-index) / var(--word-length)) * 100%) - var(--anchor-pad)))
      calc(-1 * var(--anchor-bottom))
      max(0%, calc((((var(--word-length) - var(--orp-index) - 1) / var(--word-length)) * 100%) - var(--anchor-pad)))
    );
  }

  .placeholder {
    color: #333;
    font-size: 2rem;
    font-weight: 300;
    font-family: system-ui, sans-serif;
    line-height: 1;
  }

  @media (max-width: 600px) {
    .rsvp-display {
      min-height: 200px;
    }

    .marker-line {
      height: 30px;
    }

    .word-container.multi-mode {
      font-size: clamp(0.9rem, 3.5vw, 2rem);
    }
  }

  @media (max-width: 400px) {
    .word-container.multi-mode {
      font-size: clamp(0.75rem, 3vw, 1.5rem);
    }
  }
</style>
