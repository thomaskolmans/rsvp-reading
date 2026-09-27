<script>
  import { createEventDispatcher } from 'svelte';
  import { FONT_CHOICES, getFontStack } from '../fonts.js';

  export let wordsPerMinute = 300;
  export let fadeEnabled = true;
  export let fadeDuration = 150;
  export let pauseOnPunctuation = true;
  export let punctuationPauseMultiplier = 2;
  export let pauseAfterWords = 0;
  export let pauseDuration = 500;
  export let frameWordCount = 1;
  export let wordLengthWPMMultiplier = 5;
  export let glowEnabled = true;
  export let glowBackground = true;
  export let glowFocus = true;
  export let glowInterface = true;
  export let patternEnabled = false;
  export let fontChoice = 'sans';

  const dispatch = createEventDispatcher();

  let justSaved = false;

  function close() {
    dispatch('close');
  }

  function save() {
    dispatch('save');
    justSaved = true;
    setTimeout(close, 900);
  }

  // Quick WPM presets
  const wpmPresets = [200, 300, 400, 500];
</script>

<div class="settings-panel">
  <div class="settings-header">
    <h3>Settings</h3>
    <button class="close-btn" on:click={close} title="Close">
      <svg viewBox="0 0 24 24" fill="currentColor">
        <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
      </svg>
    </button>
  </div>

  <!-- Speed Section -->
  <section class="settings-section">
    <div class="section-header">
      <svg viewBox="0 0 24 24" fill="currentColor" class="section-icon">
        <path d="M20.38 8.57l-1.23 1.85a8 8 0 0 1-.22 7.58H5.07A8 8 0 0 1 15.58 6.85l1.85-1.23A10 10 0 0 0 3.35 19a2 2 0 0 0 1.72 1h13.85a2 2 0 0 0 1.74-1 10 10 0 0 0-.27-10.44zm-9.79 6.84a2 2 0 0 0 2.83 0l5.66-8.49-8.49 5.66a2 2 0 0 0 0 2.83z"/>
      </svg>
      <span>Speed</span>
    </div>

    <div class="wpm-control">
      <div class="wpm-display">
        <span class="wpm-value">{wordsPerMinute}</span>
        <span class="wpm-label">words/min</span>
      </div>
      <input
        type="range"
        min="50"
        max="1000"
        step="25"
        bind:value={wordsPerMinute}
        class="slider"
        style="--fill: {(wordsPerMinute - 50) / 950 * 100}%"
      >
      <div class="wpm-presets">
        {#each wpmPresets as preset}
          <button
            class="preset-btn"
            class:active={wordsPerMinute === preset}
            on:click={() => wordsPerMinute = preset}
          >
            {preset}
          </button>
        {/each}
      </div>
    </div>

    <div class="control-row">
      <div class="control-header">
        <span>Lower WPM for longer words</span>
        <span class="control-value">{wordLengthWPMMultiplier}%</span>
      </div>
      <input
        type="range"
        min="0"
        max="50"
        step="1"
        bind:value={wordLengthWPMMultiplier}
        class="slider"
        style="--fill: {wordLengthWPMMultiplier / 50 * 100}%"
      >
      <p class="hint-text">How many percentage points each letter increases pause duration</p>
    </div>
  </section>

  <section class="settings-section">
    <div class="section-header">
      <svg viewBox="0 0 24 24" fill="currentColor" class="section-icon">
        <path d="M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z"/>
      </svg>
      <span>Display</span>
    </div>

    <div class="control-row">
      <div class="control-header">
        <span>Words shown simultaneously</span>
        <span class="control-value">{frameWordCount}</span>
      </div>
      <input
        type="range"
        min="1"
        max="7"
        step="2"
        bind:value={frameWordCount}
        class="slider"
        style="--fill: {(frameWordCount - 1) / 6 * 100}%"
      >
      <p class="hint-text">Odd numbers (1, 3, 5, 7) center the highlight best</p>
    </div>
  </section>

  <!-- Typography Section -->
  <section class="settings-section">
    <div class="section-header">
      <svg viewBox="0 0 24 24" fill="currentColor" class="section-icon">
        <path d="M7 5h10v2h-10v2h10v2h-10z"/>
      </svg>
      <span>Typography</span>
    </div>

    <div class="font-row">
      {#each FONT_CHOICES as choice}
        <button
          class="font-chip"
          class:active={fontChoice === choice.id}
          on:click={() => fontChoice = choice.id}
          aria-pressed={fontChoice === choice.id}
          aria-label="Font {choice.label}"
        >
          <span class="font-chip-sample" style="font-family: {getFontStack(choice.id)}">Ag</span>
          <span class="font-chip-label">{choice.label}</span>
        </button>
      {/each}
    </div>
    <p class="hint-text">Font used for the reading focus</p>
  </section>

  <!-- Effects Section -->
  <section class="settings-section">
    <div class="section-header">
      <svg viewBox="0 0 24 24" fill="currentColor" class="section-icon">
        <path d="M7.5 5.6L10 7 8.6 4.5 10 2 7.5 3.4 5 2l1.4 2.5L5 7zm12 9.8L17 14l1.4 2.5L17 19l2.5-1.4L22 19l-1.4-2.5L22 14zM22 2l-2.5 1.4L17 2l1.4 2.5L17 7l2.5-1.4L22 7l-1.4-2.5zm-7.63 5.29a.996.996 0 0 0-1.41 0L1.29 18.96a.996.996 0 0 0 0 1.41l2.34 2.34c.39.39 1.02.39 1.41 0L16.7 11.05a.996.996 0 0 0 0-1.41l-2.33-2.35zm-1.03 5.49l-2.12-2.12 2.44-2.44 2.12 2.12-2.44 2.44z"/>
      </svg>
      <span>Effects</span>
    </div>

    <div class="toggle-row">
      <span class="toggle-label">Word fade</span>
      <button
        class="toggle"
        class:active={fadeEnabled}
        on:click={() => fadeEnabled = !fadeEnabled}
        role="switch"
        aria-checked={fadeEnabled}
        aria-label="Toggle word fade effect"
      >
        <span class="toggle-thumb"></span>
      </button>
    </div>

    {#if fadeEnabled}
      <div class="sub-control">
        <div class="control-header">
          <span>Duration</span>
          <span class="control-value">{fadeDuration}ms</span>
        </div>
        <input
          type="range"
          min="50"
          max="300"
          step="25"
          bind:value={fadeDuration}
          class="slider slider-sm"
          style="--fill: {(fadeDuration - 50) / 250 * 100}%"
        >
      </div>
    {/if}
  </section>

  <!-- Ambient Section -->
  <section class="settings-section">
    <div class="section-header">
      <svg viewBox="0 0 24 24" fill="currentColor" class="section-icon">
        <path d="M7.5 5.6L10 7 8.6 4.5 10 2 7.5 3.4 5 2l1.4 2.5L5 7zm12 9.8L17 14l1.4 2.5L17 19l2.5-1.4L22 19l-1.4-2.5L22 14zM22 2l-2.5 1.4L17 2l1.4 2.5L17 7l2.5-1.4L22 7l-1.4-2.5zm-7.63 5.29a.996.996 0 0 0-1.41 0L1.29 18.96a.996.996 0 0 0 0 1.41l2.34 2.34c.39.39 1.02.39 1.41 0L16.7 11.05a.996.996 0 0 0 0-1.41l-2.33-2.35zm-1.03 5.49l-2.12-2.12 2.44-2.44 2.12 2.12-2.44 2.44z"/>
      </svg>
      <span>Ambient</span>
    </div>

    <div class="toggle-row">
      <span class="toggle-label">Ambient effects</span>
      <button
        class="toggle"
        class:active={glowEnabled}
        on:click={() => glowEnabled = !glowEnabled}
        role="switch"
        aria-checked={glowEnabled}
        aria-label="Toggle ambient glow effects"
      >
        <span class="toggle-thumb"></span>
      </button>
    </div>

    {#if glowEnabled}
      <div class="toggle-row sub">
        <span class="toggle-label">Background glow</span>
        <button
          class="toggle toggle-sm"
          class:active={glowBackground}
          on:click={() => glowBackground = !glowBackground}
          role="switch"
          aria-checked={glowBackground}
          aria-label="Toggle background glow"
        >
          <span class="toggle-thumb"></span>
        </button>
      </div>

      <div class="toggle-row sub">
        <span class="toggle-label">Focus letter</span>
        <button
          class="toggle toggle-sm"
          class:active={glowFocus}
          on:click={() => glowFocus = !glowFocus}
          role="switch"
          aria-checked={glowFocus}
          aria-label="Toggle focus letter glow"
        >
          <span class="toggle-thumb"></span>
        </button>
      </div>

      <div class="toggle-row sub">
        <span class="toggle-label">Interface glow</span>
        <button
          class="toggle toggle-sm"
          class:active={glowInterface}
          on:click={() => glowInterface = !glowInterface}
          role="switch"
          aria-checked={glowInterface}
          aria-label="Toggle interface glow"
        >
          <span class="toggle-thumb"></span>
        </button>
      </div>

      <div class="toggle-row sub">
        <span class="toggle-label">Concentration pattern</span>
        <button
          class="toggle toggle-sm"
          class:active={patternEnabled}
          on:click={() => patternEnabled = !patternEnabled}
          role="switch"
          aria-checked={patternEnabled}
          aria-label="Toggle concentration pattern"
        >
          <span class="toggle-thumb"></span>
        </button>
      </div>
    {/if}
  </section>

  <!-- Pauses Section -->
  <section class="settings-section">
    <div class="section-header">
      <svg viewBox="0 0 24 24" fill="currentColor" class="section-icon">
        <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/>
      </svg>
      <span>Pauses</span>
    </div>

    <div class="toggle-row">
      <span class="toggle-label">Pause on punctuation</span>
      <button
        class="toggle"
        class:active={pauseOnPunctuation}
        on:click={() => pauseOnPunctuation = !pauseOnPunctuation}
        role="switch"
        aria-checked={pauseOnPunctuation}
        aria-label="Toggle pause on punctuation"
      >
        <span class="toggle-thumb"></span>
      </button>
    </div>

    {#if pauseOnPunctuation}
      <div class="sub-control">
        <div class="control-header">
          <span>Pause multiplier</span>
          <span class="control-value">{punctuationPauseMultiplier}x</span>
        </div>
        <input
          type="range"
          min="1"
          max="4"
          step="0.5"
          bind:value={punctuationPauseMultiplier}
          class="slider slider-sm"
          style="--fill: {(punctuationPauseMultiplier - 1) / 3 * 100}%"
        >
      </div>
    {/if}

    <div class="control-row">
      <div class="control-header">
        <span>Pause every N words</span>
        <span class="control-value">{pauseAfterWords === 0 ? 'Off' : pauseAfterWords}</span>
      </div>
      <input
        type="range"
        min="0"
        max="50"
        step="5"
        bind:value={pauseAfterWords}
        class="slider"
        style="--fill: {pauseAfterWords / 50 * 100}%"
      >
    </div>

    {#if pauseAfterWords > 0}
      <div class="sub-control">
        <div class="control-header">
          <span>Pause duration</span>
          <span class="control-value">{pauseDuration}ms</span>
        </div>
        <input
          type="range"
          min="100"
          max="2000"
          step="100"
          bind:value={pauseDuration}
          class="slider slider-sm"
          style="--fill: {(pauseDuration - 100) / 1900 * 100}%"
        >
      </div>
    {/if}
  </section>

  <div class="settings-footer">
    <button class="save-btn" on:click={save} disabled={justSaved}>
      {justSaved ? 'Saved ✓' : 'Save'}
    </button>
    <p class="footer-hint">
      Changes apply instantly; Save remembers them for your next visit.
    </p>
  </div>
</div>

<style>
  .settings-panel {
    background: linear-gradient(180deg, rgba(10, 13, 24, 0.94), rgba(17, 22, 40, 0.94));
    border: 1px solid var(--line-1);
    border-radius: 24px;
    padding: 1.75rem;
    width: 480px;
    max-height: 85vh;
    overflow-y: auto;
    box-shadow: 0 24px 80px rgba(0, 0, 0, 0.55);
    animation: panel-in 0.22s cubic-bezier(0.16, 1, 0.3, 1);
  }

  @keyframes panel-in {
    from {
      opacity: 0;
      transform: translateY(12px) scale(0.97);
    }
    to {
      opacity: 1;
      transform: translateY(0) scale(1);
    }
  }

  .settings-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
    padding-bottom: 1.25rem;
    border-bottom: 1px solid var(--line-1);
  }

  h3 {
    margin: 0;
    font-weight: 600;
    color: var(--text-1);
    font-size: 1.5rem;
    letter-spacing: -0.01em;
  }

  .close-btn {
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid var(--line-1);
    color: var(--text-3);
    cursor: pointer;
    padding: 0.5rem;
    display: flex;
    border-radius: 10px;
    transition: all 0.15s;
  }

  .close-btn:hover {
    color: var(--text-1);
    background: rgba(255, 255, 255, 0.1);
    border-color: var(--line-2);
  }

  .close-btn svg {
    width: 24px;
    height: 24px;
  }

  /* Sections */
  .settings-section {
    margin-bottom: 2rem;
  }

  .settings-section:last-child {
    margin-bottom: 0;
  }

  .section-header {
    display: flex;
    align-items: center;
    gap: 0.625rem;
    color: var(--text-3);
    font-size: 0.82rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.07em;
    margin-bottom: 1rem;
  }

  .section-icon {
    width: 18px;
    height: 18px;
    opacity: 0.7;
  }

  /* WPM Control */
  .wpm-control {
    background: rgba(255, 255, 255, 0.045);
    border: 1px solid var(--line-1);
    border-radius: 16px;
    padding: 1.5rem;
  }

  .wpm-display {
    text-align: center;
    margin-bottom: 1.25rem;
  }

  .wpm-value {
    font-size: 4rem;
    font-weight: 700;
    color: var(--text-1);
    font-family: var(--font-mono);
    letter-spacing: -0.02em;
    text-shadow: 0 0 26px var(--glow-ui);
    font-variant-numeric: tabular-nums;
  }

  .wpm-label {
    display: block;
    color: var(--text-3);
    font-size: 0.95rem;
    margin-top: -0.25rem;
  }

  .wpm-presets {
    display: flex;
    gap: 0.75rem;
    margin-top: 1.25rem;
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
    scrollbar-width: none;
    -ms-overflow-style: none;
  }

  .wpm-presets::-webkit-scrollbar {
    display: none;
  }

  .preset-btn {
    flex: 1;
    min-width: fit-content;
    background: rgba(255, 255, 255, 0.045);
    border: 1px solid var(--line-1);
    color: var(--text-2);
    padding: 0.75rem 1rem;
    border-radius: 10px;
    font-size: 1rem;
    font-weight: 500;
    font-family: var(--font-mono);
    cursor: pointer;
    transition: all 0.15s;
  }

  .preset-btn:hover {
    background: rgba(255, 255, 255, 0.09);
    color: var(--text-1);
    border-color: var(--line-2);
  }

  .preset-btn.active {
    background: linear-gradient(135deg, var(--accent-2), var(--accent));
    border-color: transparent;
    color: #fff;
    box-shadow: 0 0 14px var(--glow-ui);
  }

  /* Font selection chips */
  .font-row {
    display: flex;
    gap: 0.6rem;
    flex-wrap: wrap;
    margin-top: 0.9rem;
  }

  .font-chip {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.35rem;
    min-width: 72px;
    padding: 0.55rem 0.8rem;
    background: rgba(255, 255, 255, 0.045);
    border: 1px solid var(--line-1);
    color: var(--text-2);
    border-radius: 12px;
    cursor: pointer;
    transition: all 0.15s;
  }

  .font-chip:hover {
    background: rgba(255, 255, 255, 0.09);
    border-color: var(--line-2);
    color: var(--text-1);
  }

  .font-chip.active {
    background: linear-gradient(135deg, var(--accent-2), var(--accent));
    border-color: transparent;
    color: #fff;
    box-shadow: 0 0 14px var(--glow-ui);
  }

  .font-chip-sample {
    font-size: 1.6rem;
    line-height: 1.1;
    color: var(--text-1);
  }

  .font-chip.active .font-chip-sample {
    color: #fff;
  }

  .font-chip-label {
    font-size: 0.75rem;
    letter-spacing: 0.02em;
  }

  /* Toggle switches */
  .toggle-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.875rem 0;
  }

  .toggle-row.sub {
    padding: 0.65rem 0 0.65rem 1.25rem;
    margin-left: 0.75rem;
    border-left: 2px solid var(--line-1);
  }

  .toggle-row.sub .toggle-label {
    color: var(--text-3);
    font-size: 1rem;
  }

  .toggle-label {
    color: var(--text-2);
    font-size: 1.1rem;
  }

  .toggle {
    position: relative;
    width: 52px;
    height: 30px;
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid var(--line-2);
    border-radius: 999px;
    cursor: pointer;
    transition: background 0.2s, border-color 0.2s, box-shadow 0.2s;
    padding: 0;
  }

  .toggle.active {
    background: linear-gradient(135deg, var(--accent-2), var(--accent));
    border-color: transparent;
    box-shadow: 0 0 14px var(--glow-ui-strong);
  }

  .toggle-thumb {
    position: absolute;
    top: 3px;
    left: 3px;
    width: 22px;
    height: 22px;
    background: #8a93a8;
    border-radius: 50%;
    transition: all 0.2s;
  }

  .toggle.active .toggle-thumb {
    left: 25px;
    background: #fff;
    box-shadow: 0 0 8px rgba(255, 255, 255, 0.5);
  }

  .toggle-sm {
    width: 44px;
    height: 26px;
  }

  .toggle-sm .toggle-thumb {
    width: 18px;
    height: 18px;
  }

  .toggle-sm.active .toggle-thumb {
    left: 21px;
  }

  /* Control rows */
  .control-row {
    padding: 0.875rem 0;
  }

  .control-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.75rem;
  }

  .control-header span:first-child {
    color: var(--text-2);
    font-size: 1.1rem;
  }

  .control-value {
    color: var(--accent);
    font-size: 1rem;
    font-weight: 600;
    font-family: var(--font-mono);
    text-shadow: 0 0 8px var(--glow-ui);
    font-variant-numeric: tabular-nums;
  }

  .sub-control {
    padding: 0.75rem 0 0.75rem 1.25rem;
    margin-left: 0.75rem;
    border-left: 2px solid var(--line-1);
  }

  .sub-control .control-header span:first-child {
    color: var(--text-3);
    font-size: 1rem;
  }

  /* Sliders with filled track */
  .slider {
    -webkit-appearance: none;
    appearance: none;
    width: 100%;
    height: 6px;
    background:
      linear-gradient(
        90deg,
        var(--accent-2) 0%,
        var(--accent) var(--fill, 50%),
        rgba(255, 255, 255, 0.1) var(--fill, 50%),
        rgba(255, 255, 255, 0.1) 100%
      );
    border-radius: 3px;
    cursor: pointer;
    outline: none;
  }

  .slider::-webkit-slider-thumb {
    -webkit-appearance: none;
    appearance: none;
    width: 20px;
    height: 20px;
    background: radial-gradient(circle, #fff 0%, #fff 32%, var(--accent) 32%, var(--accent) 100%);
    border: none;
    border-radius: 50%;
    cursor: pointer;
    transition: transform 0.12s, box-shadow 0.12s;
    box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.07), 0 0 12px var(--glow-ui);
  }

  .slider::-webkit-slider-thumb:hover {
    transform: scale(1.12);
    box-shadow: 0 0 0 4px rgba(255, 255, 255, 0.12), 0 0 20px var(--glow-ui-strong);
  }

  .slider::-moz-range-thumb {
    width: 20px;
    height: 20px;
    background: radial-gradient(circle, #fff 0%, #fff 32%, var(--accent) 32%, var(--accent) 100%);
    border: none;
    border-radius: 50%;
    cursor: pointer;
    box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.07), 0 0 12px var(--glow-ui);
  }

  .slider-sm::-webkit-slider-thumb {
    width: 18px;
    height: 18px;
  }

  .slider-sm::-moz-range-thumb {
    width: 18px;
    height: 18px;
  }

  /* Scrollbar */
  .settings-panel::-webkit-scrollbar {
    width: 6px;
  }

  .settings-panel::-webkit-scrollbar-track {
    background: transparent;
  }

  .settings-panel::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.18);
    border-radius: 3px;
  }

  .hint-text {
    margin: 0.5rem 0 0;
    color: var(--text-3);
    font-size: 0.8rem;
    line-height: 1.3;
  }

  /* Save footer */
  .settings-footer {
    margin-top: 1.5rem;
    padding: 1rem 0 0;
    border-top: 1px solid var(--line-1);
    display: flex;
    flex-direction: column;
    gap: 0.6rem;
  }

  .save-btn {
    width: 100%;
    padding: 0.85rem;
    border: none;
    border-radius: 12px;
    font-size: 1.05rem;
    font-weight: 600;
    cursor: pointer;
    background: linear-gradient(135deg, var(--accent-2), var(--accent));
    color: #fff;
    box-shadow: 0 4px 14px rgba(0, 0, 0, 0.35), 0 0 14px var(--glow-ui);
    transition: all 0.2s;
  }

  .save-btn:hover:not(:disabled) {
    box-shadow: 0 4px 18px rgba(0, 0, 0, 0.4), 0 0 22px var(--glow-ui-strong);
    transform: translateY(-1px);
  }

  .save-btn:disabled {
    background: rgba(121, 208, 132, 0.16);
    color: #7fd48a;
    cursor: default;
    box-shadow: none;
    border: 1px solid rgba(127, 212, 138, 0.35);
  }

  .footer-hint {
    margin: 0;
    color: var(--text-3);
    font-size: 0.8rem;
    line-height: 1.4;
    text-align: center;
  }

  /* Mobile */
  @media (max-width: 600px) {
    .settings-panel {
      width: 100%;
      max-width: none;
      border-radius: 18px;
      padding: 1.5rem;
    }

    h3 {
      font-size: 1.25rem;
    }

    .wpm-value {
      font-size: 3rem;
    }

    .slider::-webkit-slider-thumb {
      width: 26px;
      height: 26px;
    }

    .toggle {
      width: 56px;
      height: 34px;
    }

    .toggle-thumb {
      width: 26px;
      height: 26px;
    }

    .toggle.active .toggle-thumb {
      left: 27px;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .settings-panel {
      animation: none;
    }
  }
</style>