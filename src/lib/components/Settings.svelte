<script>
  import { createEventDispatcher } from 'svelte';

  export let wordsPerMinute = 300;
  export let fadeEnabled = true;
  export let fadeDuration = 150;
  export let pauseOnPunctuation = true;
  export let punctuationPauseMultiplier = 2;
  export let pauseAfterWords = 0;
  export let pauseDuration = 500;
  export let frameWordCount = 1;
  export let wordLengthWPMMultiplier = 5;

  const dispatch = createEventDispatcher();

  function close() {
    dispatch('close');
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
      <input type="range" min="0" max="50" step="1" bind:value={wordLengthWPMMultiplier} class="slider">
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
      <input type="range" min="1" max="7" step="2" bind:value={frameWordCount} class="slider">
      <p class="hint-text">Odd numbers (1, 3, 5, 7) center the highlight best</p>
    </div>
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
        <input type="range" min="50" max="300" step="25" bind:value={fadeDuration} class="slider slider-sm">
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
        <input type="range" min="1" max="4" step="0.5" bind:value={punctuationPauseMultiplier} class="slider slider-sm">
      </div>
    {/if}

    <div class="control-row">
      <div class="control-header">
        <span>Pause every N words</span>
        <span class="control-value">{pauseAfterWords === 0 ? 'Off' : pauseAfterWords}</span>
      </div>
      <input type="range" min="0" max="50" step="5" bind:value={pauseAfterWords} class="slider">
    </div>

    {#if pauseAfterWords > 0}
      <div class="sub-control">
        <div class="control-header">
          <span>Pause duration</span>
          <span class="control-value">{pauseDuration}ms</span>
        </div>
        <input type="range" min="100" max="2000" step="100" bind:value={pauseDuration} class="slider slider-sm">
      </div>
    {/if}
  </section>
</div>

<style>
  .settings-panel {
    background: #0a0a0a;
    border: 1px solid #222;
    border-radius: 20px;
    padding: 2rem;
    width: 480px;
    max-height: 85vh;
    overflow-y: auto;
  }

  .settings-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
    padding-bottom: 1.25rem;
    border-bottom: 1px solid #1a1a1a;
  }

  h3 {
    margin: 0;
    font-weight: 600;
    color: #fff;
    font-size: 1.5rem;
    letter-spacing: -0.01em;
  }

  .close-btn {
    background: transparent;
    border: none;
    color: #444;
    cursor: pointer;
    padding: 0.5rem;
    display: flex;
    border-radius: 10px;
    transition: all 0.15s;
  }

  .close-btn:hover {
    color: #fff;
    background: #1a1a1a;
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
    color: #666;
    font-size: 0.85rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin-bottom: 1rem;
  }

  .section-icon {
    width: 18px;
    height: 18px;
    opacity: 0.7;
  }

  /* WPM Control */
  .wpm-control {
    background: #111;
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
    color: #fff;
    font-family: 'SF Mono', 'Monaco', monospace;
    letter-spacing: -0.02em;
  }

  .wpm-label {
    display: block;
    color: #555;
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
    background: #1a1a1a;
    border: 1px solid #252525;
    color: #888;
    padding: 0.75rem 1rem;
    border-radius: 10px;
    font-size: 1rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.15s;
  }

  .preset-btn:hover {
    background: #222;
    color: #fff;
    border-color: #333;
  }

  .preset-btn.active {
    background: #ff4444;
    border-color: #ff4444;
    color: #fff;
  }

  /* Toggle switches */
  .toggle-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.875rem 0;
  }

  .toggle-label {
    color: #ccc;
    font-size: 1.1rem;
  }

  .toggle {
    position: relative;
    width: 56px;
    height: 32px;
    background: #222;
    border: none;
    border-radius: 16px;
    cursor: pointer;
    transition: background 0.2s;
    padding: 0;
  }

  .toggle.active {
    background: #ff4444;
  }

  .toggle-thumb {
    position: absolute;
    top: 4px;
    left: 4px;
    width: 24px;
    height: 24px;
    background: #666;
    border-radius: 50%;
    transition: all 0.2s;
  }

  .toggle.active .toggle-thumb {
    left: 28px;
    background: #fff;
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
    color: #ccc;
    font-size: 1.1rem;
  }

  .control-value {
    color: #ff4444;
    font-size: 1rem;
    font-weight: 600;
    font-family: 'SF Mono', 'Monaco', monospace;
  }

  .sub-control {
    padding: 0.75rem 0 0.75rem 1.25rem;
    margin-left: 0.75rem;
    border-left: 2px solid #1a1a1a;
  }

  .sub-control .control-header span:first-child {
    color: #888;
    font-size: 1rem;
  }

  /* Sliders */
  .slider {
    width: 100%;
    height: 8px;
    background: #222;
    border-radius: 4px;
    appearance: none;
    cursor: pointer;
    outline: none;
  }

  .slider::-webkit-slider-thumb {
    appearance: none;
    width: 24px;
    height: 24px;
    background: #ff4444;
    border-radius: 50%;
    cursor: pointer;
    transition: transform 0.1s, box-shadow 0.1s;
    box-shadow: 0 2px 8px rgba(255, 68, 68, 0.3);
  }

  .slider::-webkit-slider-thumb:hover {
    transform: scale(1.1);
    box-shadow: 0 2px 12px rgba(255, 68, 68, 0.5);
  }

  .slider::-moz-range-thumb {
    width: 24px;
    height: 24px;
    background: #ff4444;
    border-radius: 50%;
    cursor: pointer;
    border: none;
    box-shadow: 0 2px 8px rgba(255, 68, 68, 0.3);
  }

  .slider-sm::-webkit-slider-thumb {
    width: 20px;
    height: 20px;
  }

  .slider-sm::-moz-range-thumb {
    width: 20px;
    height: 20px;
  }

  /* Scrollbar */
  .settings-panel::-webkit-scrollbar {
    width: 6px;
  }

  .settings-panel::-webkit-scrollbar-track {
    background: transparent;
  }

  .settings-panel::-webkit-scrollbar-thumb {
    background: #333;
    border-radius: 3px;
  }
  
  .hint-text {
    margin: 0.5rem 0 0;
    color: #666;
    font-size: 0.8rem;
    line-height: 1.3;
  }
  /* Mobile */
  @media (max-width: 600px) {
    .settings-panel {
      width: 100%;
      max-width: none;
      border-radius: 16px;
      padding: 1.5rem;
    }

    h3 {
      font-size: 1.25rem;
    }

    .wpm-value {
      font-size: 3rem;
    }

    .slider::-webkit-slider-thumb {
      width: 28px;
      height: 28px;
    }

    .toggle {
      width: 60px;
      height: 36px;
    }

    .toggle-thumb {
      width: 28px;
      height: 28px;
    }

    .toggle.active .toggle-thumb {
      left: 28px;
    }
  }
</style>
