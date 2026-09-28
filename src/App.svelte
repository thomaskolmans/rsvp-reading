<script>
  import { onMount, onDestroy } from 'svelte';
  import {
    parseText as parseTextUtil,
    getWordDelay as getWordDelayUtil,
    formatTimeRemaining,
    shouldPauseAtWord,
    extractWordFrame
  } from './lib/reading-utils.js';
  import { parseFile } from './lib/file-parsers.js';
  import { getFontStack } from './lib/fonts.js';
  import { buildSettingsPayload, mergeSettings } from './lib/settings-utils.js';
  import {
    saveSession,
    loadSession,
    clearSession,
    hasSession,
    getSessionSummary
  } from './lib/progress-storage.js';
  import WordStage from './lib/components/WordStage.svelte';
import { getDefaultText } from './lib/reading-utils.js';
  import Controls from './lib/components/Controls.svelte';
  import Settings from './lib/components/Settings.svelte';
  import TextInput from './lib/components/TextInput.svelte';
  import ProgressBar from './lib/components/ProgressBar.svelte';

  // State
  let frameWordCount = 1;
  // Base text for a fresh session follows the UI locale: Russian device/browser
  // (ru*) gets the Russian text, everything else the English one.
  // WKWebView exposes navigator.language; elsewhere Intl reflects the locale.
  const uiLocale =
    typeof navigator.language === 'string'
      ? navigator.language
      : Intl.DateTimeFormat().resolvedOptions().locale;
  let text = getDefaultText(uiLocale);
  let words = [];
  let currentWordIndex = 0;
  let isPlaying = false;
  let isPaused = false;
  let showSettings = false;
  let showTextInput = false;
  let progress = 0;
  let isLoadingFile = false;
  let loadingMessage = '';
  let showJumpTo = false;
  let jumpToValue = '';
  let savedSessionInfo = null;
  let showSavedSessionPrompt = false;

  // Settings
  let wordsPerMinute = 300;
  let fadeEnabled = true;
  let fadeDuration = 150;
  let pauseAfterWords = 0;
  let pauseDuration = 500;
  let pauseOnPunctuation = true;
  let punctuationPauseMultiplier = 2;
  let wordLengthWPMMultiplier = 5;

  // Visual effects
  let glowEnabled = true;
  let glowBackground = true;
  let glowFocus = true;
  let glowInterface = true;
  let patternEnabled = false;

  // Typography
  let fontChoice = 'sans';

  // Animation
  let wordOpacity = 1;
  let intervalId = null;
  let fadeTimeoutId = null;

  // Derived state
  $: currentWord = words[currentWordIndex - 1] || (words.length > 0 ? words[0] : '');
  $: wordFrame = extractWordFrame(words, Math.max(0, currentWordIndex - 1), frameWordCount);
  $: timeRemaining = formatTimeRemaining(words.length - currentWordIndex, wordsPerMinute);
  $: isFocusMode = isPlaying || isPaused;

  function parseText() {
    words = parseTextUtil(text);
    currentWordIndex = 0;
    progress = 0;
  }

  function getWordDelay(word) {
    return getWordDelayUtil(word, wordsPerMinute, pauseOnPunctuation, punctuationPauseMultiplier, wordLengthWPMMultiplier);
  }

  // Map a glow gate to a CSS token value: keeps the glow when enabled,
  // makes it transparent (invisible) when disabled.
  function glowGate(enabled, token) {
    return enabled ? `var(${token})` : 'transparent';
  }

  function showNextWord() {
    if (currentWordIndex >= words.length) {
      stop();
      return;
    }

    if (shouldPauseAtWord(currentWordIndex, pauseAfterWords)) {
      isPaused = true;
      setTimeout(() => {
        if (isPlaying) {
          isPaused = false;
          scheduleNextWord();
        }
      }, pauseDuration);
      return;
    }

    if (fadeEnabled) {
      wordOpacity = 0;
      fadeTimeoutId = setTimeout(() => {
        wordOpacity = 1;
      }, 10);
    }

    progress = ((currentWordIndex + 1) / words.length) * 100;
    currentWordIndex++;
    scheduleNextWord();
  }

  function scheduleNextWord() {
    if (!isPlaying || currentWordIndex >= words.length) return;
    const word = words[currentWordIndex - 1] || '';
    intervalId = setTimeout(showNextWord, getWordDelay(word));
  }

  function start() {
    if (words.length === 0) parseText();
    if (words.length === 0) return;
    isPlaying = true;
    isPaused = false;
    showSettings = false;
    showTextInput = false;
    showNextWord();
  }

  function pause() {
    isPlaying = false;
    isPaused = true;
    if (intervalId) {
      clearTimeout(intervalId);
      intervalId = null;
    }
  }

  function resume() {
    if (currentWordIndex < words.length) {
      isPlaying = true;
      isPaused = false;
      scheduleNextWord();
    }
  }

  function stop() {
    isPlaying = false;
    isPaused = false;
    currentWordIndex = 0;
    progress = 0;
    wordOpacity = 1;
    if (intervalId) {
      clearTimeout(intervalId);
      intervalId = null;
    }
  }

  function restart() {
    stop();
    start();
  }

  function handleTextApply(event) {
    text = event.detail.text;
    stop();
    parseText();
    showTextInput = false;
  }

  async function handleFileSelect(event) {
    const file = event.detail.file;
    if (!file) return;

    isLoadingFile = true;
    loadingMessage = `Loading ${file.name}...`;

    try {
      text = await parseFile(file);
      stop();
      parseText();
      showTextInput = false;
      loadingMessage = '';
    } catch (error) {
      console.error('Error parsing file:', error);
      loadingMessage = `Error: ${error.message}`;
      setTimeout(() => { loadingMessage = ''; }, 3000);
    } finally {
      isLoadingFile = false;
    }
  }

  function saveCurrentSession() {
    if (words.length === 0) return false;
    return saveSession({
      text,
      currentWordIndex,
      totalWords: words.length,
      settings: buildSettingsPayload({
        wordsPerMinute,
        fadeEnabled,
        fadeDuration,
        pauseOnPunctuation,
        punctuationPauseMultiplier,
        wordLengthWPMMultiplier,
        pauseAfterWords,
        pauseDuration,
        frameWordCount,
        glowEnabled,
        glowBackground,
        glowFocus,
        glowInterface,
        patternEnabled,
        fontChoice
      })
    });
  }

  function loadSavedSession() {
    const session = loadSession();
    if (!session) return false;

    text = session.text;
    parseText();
    currentWordIndex = session.currentWordIndex;
    progress = (currentWordIndex / words.length) * 100;

    if (session.settings) {
      const restored = mergeSettings(session.settings, {
        wordsPerMinute,
        fadeEnabled,
        fadeDuration,
        pauseOnPunctuation,
        punctuationPauseMultiplier,
        wordLengthWPMMultiplier,
        pauseAfterWords,
        pauseDuration,
        frameWordCount,
        glowEnabled,
        glowBackground,
        glowFocus,
        glowInterface,
        patternEnabled,
        fontChoice
      });
      wordsPerMinute = restored.wordsPerMinute;
      fadeEnabled = restored.fadeEnabled;
      fadeDuration = restored.fadeDuration;
      pauseOnPunctuation = restored.pauseOnPunctuation;
      punctuationPauseMultiplier = restored.punctuationPauseMultiplier;
      wordLengthWPMMultiplier = restored.wordLengthWPMMultiplier;
      pauseAfterWords = restored.pauseAfterWords;
      pauseDuration = restored.pauseDuration;
      frameWordCount = restored.frameWordCount;
      glowEnabled = restored.glowEnabled;
      glowBackground = restored.glowBackground;
      glowFocus = restored.glowFocus;
      glowInterface = restored.glowInterface;
      patternEnabled = restored.patternEnabled;
      fontChoice = restored.fontChoice;
    }

    showSavedSessionPrompt = false;
    return true;
  }

  function clearSavedSession() {
    clearSession();
    showSavedSessionPrompt = false;
    savedSessionInfo = null;
  }

  function jumpToWord(value) {
    if (!value || words.length === 0) return;

    let targetIndex;
    const trimmed = value.trim();

    if (trimmed.endsWith('%')) {
      const percent = parseFloat(trimmed.slice(0, -1));
      if (!isNaN(percent)) {
        targetIndex = Math.floor((Math.max(0, Math.min(100, percent)) / 100) * words.length);
      }
    } else {
      const num = parseInt(trimmed, 10);
      if (!isNaN(num)) {
        targetIndex = Math.max(0, Math.min(words.length, num));
      }
    }

    if (targetIndex !== undefined) {
      currentWordIndex = targetIndex;
      progress = (currentWordIndex / words.length) * 100;
    }

    showJumpTo = false;
    jumpToValue = '';
  }

  function handleProgressClick(event) {
    const percentage = event.detail.percentage;
    const targetIndex = Math.floor((percentage / 100) * words.length);
    currentWordIndex = Math.max(0, Math.min(words.length, targetIndex));
    progress = (currentWordIndex / words.length) * 100;
  }

  function handleKeydown(e) {
    if (e.target.tagName === 'TEXTAREA' || e.target.tagName === 'INPUT') return;

    switch (e.code) {
      case 'Space':
        e.preventDefault();
        if (isPlaying) pause();
        else if (isPaused) resume();
        else start();
        break;
      case 'Escape':
        if (showJumpTo) {
          showJumpTo = false;
          jumpToValue = '';
        } else if (showSettings || showTextInput) {
          showSettings = false;
          showTextInput = false;
        } else if (showSavedSessionPrompt) {
          showSavedSessionPrompt = false;
        } else if (isPlaying || isPaused) {
          // Exit focus mode but preserve position
          isPlaying = false;
          isPaused = false;
          if (intervalId) {
            clearTimeout(intervalId);
            intervalId = null;
          }
        }
        break;
      case 'KeyG':
        if (!isPlaying && !showSettings && !showTextInput) {
          e.preventDefault();
          showJumpTo = !showJumpTo;
        }
        break;
      case 'KeyS':
        if (e.ctrlKey || e.metaKey) {
          e.preventDefault();
          saveCurrentSession();
        }
        break;
      case 'ArrowUp':
        e.preventDefault();
        wordsPerMinute = Math.min(1000, wordsPerMinute + 25);
        break;
      case 'ArrowDown':
        e.preventDefault();
        wordsPerMinute = Math.max(50, wordsPerMinute - 25);
        break;
      case 'ArrowLeft':
        e.preventDefault();
        if (currentWordIndex > 1) {
          currentWordIndex = Math.max(0, currentWordIndex - 2);
          progress = (currentWordIndex / words.length) * 100;
        }
        break;
      case 'ArrowRight':
        e.preventDefault();
        if (currentWordIndex < words.length) {
          progress = ((currentWordIndex + 1) / words.length) * 100;
          currentWordIndex++;
        }
        break;
    }
  }

  onMount(() => {
    parseText();
    window.addEventListener('keydown', handleKeydown);

    // Check for saved session
    if (hasSession()) {
      savedSessionInfo = getSessionSummary();
      if (savedSessionInfo) {
        showSavedSessionPrompt = true;
      }
    }
  });

  onDestroy(() => {
    if (intervalId) clearTimeout(intervalId);
    if (fadeTimeoutId) clearTimeout(fadeTimeoutId);
    window.removeEventListener('keydown', handleKeydown);
  });
</script>

<main
  class:focus-mode={isFocusMode}
  style="
    --glow-word: {glowGate(glowEnabled && glowFocus, '--accent-glow')};
    --glow-ui: {glowGate(glowEnabled && glowInterface, '--accent-glow')};
    --glow-ui-strong: {glowGate(glowEnabled && glowInterface, '--accent-glow-strong')};
    --glow-amber: {glowGate(glowEnabled && glowInterface, '--amber-glow')};
    --glow-amber-strong: {glowGate(glowEnabled && glowInterface, '--amber-glow-strong')};
    --glow-ambient: {glowEnabled && glowBackground ? 1 : 0};
    --font-reading: {getFontStack(fontChoice)};
  "
>
  <!-- Ambient backdrop -->
  <div class="backdrop" aria-hidden="true">
    <div class="orb orb-a"></div>
    <div class="orb orb-b"></div>
  </div>

  <!-- Header - hidden during focus mode -->
  {#if !isFocusMode}
    <header>
      <h1 class="brand">
        <span class="brand-dot" aria-hidden="true"></span>
        <span class="brand-name">Speed</span>
        <span class="brand-sub">Reader</span>
      </h1>
      <div class="header-actions">
        <button
          class="icon-btn"
          on:click={() => { showJumpTo = !showJumpTo; showSettings = false; showTextInput = false; }}
          title="Jump to word (G)"
          class:active={showJumpTo}
        >
          <svg viewBox="0 0 24 24" fill="currentColor">
            <path d="M9.4 16.6L4.8 12l4.6-4.6L8 6l-6 6 6 6 1.4-1.4zm5.2 0l4.6-4.6-4.6-4.6L16 6l6 6-6 6-1.4-1.4z"/>
          </svg>
        </button>
        <button
          class="icon-btn"
          on:click={saveCurrentSession}
          title="Save progress (Ctrl+S)"
          disabled={words.length === 0}
        >
          <svg viewBox="0 0 24 24" fill="currentColor">
            <path d="M17 3H5c-1.11 0-2 .9-2 2v14c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V7l-4-4zm-5 16c-1.66 0-3-1.34-3-3s1.34-3 3-3 3 1.34 3 3-1.34 3-3 3zm3-10H5V5h10v4z"/>
          </svg>
        </button>
        <button
          class="icon-btn"
          on:click={() => { showTextInput = !showTextInput; showSettings = false; showJumpTo = false; }}
          title="Load Content"
          class:active={showTextInput}
        >
          <svg viewBox="0 0 24 24" fill="currentColor">
            <path d="M14 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V8l-6-6zM6 20V4h7v5h5v11H6z"/>
          </svg>
        </button>
        <button
          class="icon-btn"
          on:click={() => { showSettings = !showSettings; showTextInput = false; showJumpTo = false; }}
          title="Settings"
          class:active={showSettings}
        >
          <svg viewBox="0 0 24 24" fill="currentColor">
            <path d="M19.14 12.94c.04-.31.06-.63.06-.94 0-.31-.02-.63-.06-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.04.31-.06.63-.06.94s.02.63.06.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/>
          </svg>
        </button>
      </div>
    </header>
  {/if}

  <!-- Panels -->
  {#if showTextInput && !isFocusMode}
    <div class="panel-overlay">
      <TextInput
        {text}
        isLoading={isLoadingFile}
        {loadingMessage}
        on:apply={handleTextApply}
        on:fileselect={handleFileSelect}
        on:close={() => showTextInput = false}
      />
    </div>
  {/if}


  {#if showSettings && !isFocusMode}
    <div class="panel-overlay">
      <Settings
        bind:wordsPerMinute
        bind:fadeEnabled
        bind:fadeDuration
        bind:pauseOnPunctuation
        bind:punctuationPauseMultiplier
        bind:wordLengthWPMMultiplier
        bind:pauseAfterWords
        bind:pauseDuration
        bind:frameWordCount
        bind:glowEnabled
        bind:glowBackground
        bind:glowFocus
        bind:glowInterface
        bind:patternEnabled
        bind:fontChoice
        on:save={saveCurrentSession}
        on:close={() => showSettings = false}
      />
    </div>
  {/if}

  {#if showJumpTo && !isFocusMode}
    <div class="panel-overlay" on:click|self={() => showJumpTo = false} role="presentation">
      <div class="jump-to-panel">
        <h3>Jump to position</h3>
        <p class="jump-hint">Enter word number (e.g., 150) or percentage (e.g., 50%)</p>
        <form on:submit|preventDefault={() => jumpToWord(jumpToValue)}>
          <!-- svelte-ignore a11y_autofocus -->
          <input
            type="text"
            bind:value={jumpToValue}
            placeholder="Word # or %"
            autofocus
          />
          <div class="jump-actions">
            <button type="button" class="secondary" on:click={() => showJumpTo = false}>Cancel</button>
            <button type="submit" class="primary">Go</button>
          </div>
        </form>
        <div class="quick-jumps">
          <button on:click={() => jumpToWord('0')}>Start</button>
          <button on:click={() => jumpToWord('25%')}>25%</button>
          <button on:click={() => jumpToWord('50%')}>50%</button>
          <button on:click={() => jumpToWord('75%')}>75%</button>
        </div>
      </div>
    </div>
  {/if}

  {#if showSavedSessionPrompt && savedSessionInfo}
    <div class="panel-overlay">
      <div class="saved-session-panel">
        <h3>Resume reading?</h3>
        <p>You have a saved session at word {savedSessionInfo.currentWordIndex} of {savedSessionInfo.totalWords}</p>
        <p class="saved-time">Saved {new Date(savedSessionInfo.savedAt).toLocaleString()}</p>
        <div class="session-actions">
          <button class="secondary" on:click={clearSavedSession}>Start Fresh</button>
          <button class="primary" on:click={loadSavedSession}>Resume</button>
        </div>
      </div>
    </div>
  {/if}

  <!-- Main Display -->
  <div class="display-area">
    <WordStage
      word={currentWord}
      wordGroup={wordFrame.subset}
      highlightIndex={wordFrame.centerOffset}
      opacity={wordOpacity}
      {fadeDuration}
      {fadeEnabled}
      multiWordEnabled={frameWordCount > 1}
      patternEnabled={glowEnabled && patternEnabled}
    />
  </div>

  <!-- Bottom Bar -->
  <div class="bottom-bar" class:minimal={isFocusMode}>
    <ProgressBar
      {progress}
      currentWord={currentWordIndex}
      totalWords={words.length}
      wpm={wordsPerMinute}
      {timeRemaining}
      minimal={isFocusMode}
      clickable={!isPlaying}
      on:seek={handleProgressClick}
    />

    <div class="controls-area">
      <Controls
        {isPlaying}
        {isPaused}
        canPlay={words.length > 0}
        minimal={isFocusMode}
        on:play={start}
        on:pause={pause}
        on:resume={resume}
        on:stop={stop}
        on:restart={restart}
      />
    </div>

    {#if !isFocusMode}
      <div class="shortcuts desktop-only">
        <span class="shortcut"><kbd>Space</kbd> Play</span>
        <span class="shortcut"><kbd>Esc</kbd> Exit</span>
        <span class="shortcut"><kbd>↑↓</kbd> Speed</span>
        <span class="shortcut"><kbd>←→</kbd> Skip</span>
        <span class="shortcut"><kbd>G</kbd> Jump</span>
        <span class="shortcut"><kbd>Ctrl+S</kbd> Save</span>
      </div>
      <div class="touch-controls mobile-only">
        <button class="touch-btn" on:click={() => currentWordIndex = Math.max(0, currentWordIndex - 5)} title="Back 5 words">
          <svg viewBox="0 0 24 24" fill="currentColor"><path d="M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z"/></svg>
        </button>
        <button class="touch-btn" on:click={() => wordsPerMinute = Math.max(50, wordsPerMinute - 50)} title="Slower">
          <span>−WPM</span>
        </button>
        <span class="wpm-display">{wordsPerMinute}</span>
        <button class="touch-btn" on:click={() => wordsPerMinute = Math.min(1000, wordsPerMinute + 50)} title="Faster">
          <span>+WPM</span>
        </button>
        <button class="touch-btn" on:click={() => currentWordIndex = Math.min(words.length, currentWordIndex + 5)} title="Forward 5 words">
          <svg viewBox="0 0 24 24" fill="currentColor"><path d="M8.59 16.59L10 18l6-6-6-6-1.41 1.41L13.17 12z"/></svg>
        </button>
      </div>
    {/if}
  </div>
</main>

<style>
  :global(body) {
    background-color: transparent !important;
    margin: 0;
    padding: 0;
    overflow: hidden;
    position: fixed;
    width: 100%;
    height: 100%;
  }

  main {
    height: 100vh;
    height: 100dvh; /* Dynamic viewport height for mobile */
    display: flex;
    flex-direction: column;
    background: transparent;
    color: var(--text-1);
    font-family: 'SF Pro Text', 'Inter', 'Segoe UI', system-ui, sans-serif;
    -webkit-font-smoothing: antialiased;
    padding: 2rem;
    box-sizing: border-box;
    transition: padding 0.3s ease;
    overflow: hidden;
  }

  main.focus-mode {
    padding: 1rem;
  }

  /* ── Ambient backdrop ─────────────────────────────────────── */
  .backdrop {
    position: fixed;
    inset: 0;
    z-index: 0;
    pointer-events: none;
  }

  .orb {
    position: absolute;
    border-radius: 50%;
    filter: blur(90px);
    opacity: var(--glow-ambient, 1);
    will-change: transform;
    transform: translateZ(0);
  }

  .orb-a {
    width: 55vmax;
    height: 55vmax;
    left: -18vmax;
    top: -22vmax;
    background: radial-gradient(circle, rgba(64, 82, 180, 0.16) 0%, rgba(64, 82, 180, 0.05) 40%, transparent 70%);
    animation: orb-drift-a 70s ease-in-out infinite alternate;
  }

  .orb-b {
    width: 45vmax;
    height: 45vmax;
    right: -16vmax;
    bottom: -20vmax;
    background: radial-gradient(circle, rgba(255, 59, 92, 0.07) 0%, transparent 65%);
    animation: orb-drift-b 90s ease-in-out infinite alternate;
  }

  @keyframes orb-drift-a {
    from { transform: translate3d(0, 0, 0); }
    to { transform: translate3d(6vmax, 4vmax, 0); }
  }

  @keyframes orb-drift-b {
    from { transform: translate3d(0, 0, 0); }
    to { transform: translate3d(-5vmax, -3vmax, 0); }
  }

  header {
    position: relative;
    z-index: 1;
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1rem;
    flex-shrink: 0;
  }

  .brand {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin: 0;
  }

  .brand-dot {
    width: 10px;
    height: 10px;
    border-radius: 50%;
    background: var(--accent);
    box-shadow: 0 0 12px var(--glow-ui-strong);
  }

  .brand-name {
    font-size: 1.15rem;
    font-weight: 700;
    letter-spacing: 0.03em;
    color: var(--text-1);
    font-family: var(--font-mono);
  }

  .brand-sub {
    font-size: 1.05rem;
    font-weight: 400;
    color: var(--text-3);
    letter-spacing: 0.08em;
  }

  .header-actions {
    display: flex;
    gap: 0.5rem;
  }

  .icon-btn {
    background: rgba(255, 255, 255, 0.04);
    border: 1px solid var(--line-2);
    color: var(--text-2);
    width: 40px;
    height: 40px;
    padding: 0.5rem;
    border-radius: 12px;
    cursor: pointer;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .icon-btn:hover:not(:disabled) {
    background: rgba(255, 255, 255, 0.09);
    border-color: rgba(255, 255, 255, 0.26);
    color: var(--text-1);
    transform: translateY(-1px);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.35);
  }

  .icon-btn.active {
    background: rgba(255, 59, 92, 0.14);
    border-color: var(--accent);
    color: var(--accent);
    box-shadow: 0 0 16px var(--glow-ui);
  }

  .icon-btn svg {
    width: 20px;
    height: 20px;
  }

  .icon-btn:disabled {
    opacity: 0.3;
    cursor: not-allowed;
  }

  /* ── Overlays & panels ────────────────────────────────────── */
  .panel-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(4, 6, 12, 0.72);
    backdrop-filter: blur(10px);
    -webkit-backdrop-filter: blur(10px);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 100;
    padding: 2rem;
    animation: overlay-in 0.18s ease-out;
  }

  @keyframes overlay-in {
    from { opacity: 0; }
    to { opacity: 1; }
  }

  .display-area {
    position: relative;
    z-index: 1;
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 0;
    overflow: hidden;
  }

  .bottom-bar {
    position: relative;
    z-index: 1;
    flex-shrink: 0;
    display: flex;
    flex-direction: column;
    gap: 1rem;
    padding-top: 1rem;
    transition: all 0.3s ease;
  }

  .bottom-bar.minimal {
    gap: 0.5rem;
    padding-top: 0.5rem;
  }

  .controls-area {
    display: flex;
    justify-content: center;
  }

  .shortcuts {
    display: flex;
    justify-content: center;
    gap: 1.5rem;
    color: var(--text-3);
    font-size: 0.8rem;
  }

  .shortcut {
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
  }

  kbd {
    background: rgba(255, 255, 255, 0.06);
    border: 1px solid var(--line-2);
    border-bottom-color: rgba(255, 255, 255, 0.28);
    padding: 0.14rem 0.45rem;
    border-radius: 6px;
    font-family: var(--font-mono);
    font-size: 0.72rem;
    color: var(--text-2);
    box-shadow: 0 1px 0 rgba(0, 0, 0, 0.6);
  }

  /* Touch controls for mobile */
  .touch-controls {
    display: none;
    justify-content: center;
    align-items: center;
    gap: 0.5rem;
  }

  .touch-btn {
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid var(--line-2);
    color: var(--text-2);
    padding: 0.5rem 0.75rem;
    border-radius: 10px;
    font-size: 0.75rem;
    cursor: pointer;
    min-width: 44px;
    min-height: 44px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
  }

  .touch-btn:active {
    background: rgba(255, 255, 255, 0.12);
    color: var(--text-1);
    transform: scale(0.94);
  }

  .touch-btn svg {
    width: 20px;
    height: 20px;
  }

  .wpm-display {
    color: var(--accent);
    font-family: var(--font-mono);
    font-size: 0.85rem;
    min-width: 3rem;
    text-align: center;
    text-shadow: 0 0 10px var(--glow-ui);
    font-variant-numeric: tabular-nums;
  }

  .mobile-only {
    display: none;
  }

  .desktop-only {
    display: flex;
  }

  /* Mobile styles */
  @media (max-width: 600px) {
    main {
      padding: 1rem;
    }

    main.focus-mode {
      padding: 0.5rem;
    }

    .panel-overlay {
      padding: 1rem;
    }

    .desktop-only {
      display: none;
    }

    .mobile-only {
      display: flex;
    }
  }

  /* Jump to panel & saved session panel */
  .jump-to-panel,
  .saved-session-panel {
    background: linear-gradient(180deg, rgba(10, 13, 24, 0.94), rgba(17, 22, 40, 0.94));
    border: 1px solid var(--line-1);
    border-radius: 20px;
    padding: 1.5rem;
    max-width: 320px;
    width: 100%;
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

  .jump-to-panel h3,
  .saved-session-panel h3 {
    margin: 0 0 0.5rem 0;
    color: var(--text-1);
    font-size: 1.1rem;
    font-weight: 600;
  }

  .jump-hint {
    color: var(--text-3);
    font-size: 0.85rem;
    margin: 0 0 1rem 0;
  }

  .jump-to-panel input {
    width: 100%;
    padding: 0.75rem 1rem;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid var(--line-2);
    border-radius: 10px;
    color: var(--text-1);
    font-size: 1rem;
    margin-bottom: 1rem;
    box-sizing: border-box;
    transition: border-color 0.2s, box-shadow 0.2s;
  }

  .jump-to-panel input:focus {
    outline: none;
    border-color: var(--accent);
    box-shadow: 0 0 0 3px rgba(255, 59, 92, 0.15), 0 0 14px var(--glow-ui);
  }

  .jump-actions,
  .session-actions {
    display: flex;
    gap: 0.5rem;
    justify-content: flex-end;
  }

  .jump-actions button,
  .session-actions button {
    padding: 0.5rem 1rem;
    border-radius: 10px;
    border: none;
    cursor: pointer;
    font-size: 0.9rem;
    font-weight: 500;
    transition: all 0.2s;
  }

  .jump-actions button.primary,
  .session-actions button.primary {
    background: linear-gradient(135deg, var(--accent-2), var(--accent));
    color: #fff;
    box-shadow: 0 4px 14px rgba(0, 0, 0, 0.35), 0 0 14px var(--glow-ui);
  }

  .jump-actions button.primary:hover,
  .session-actions button.primary:hover {
    box-shadow: 0 4px 18px rgba(0, 0, 0, 0.4), 0 0 22px var(--glow-ui-strong);
    transform: translateY(-1px);
  }

  .jump-actions button.secondary,
  .session-actions button.secondary {
    background: rgba(255, 255, 255, 0.06);
    border: 1px solid var(--line-2);
    color: var(--text-2);
  }

  .jump-actions button.secondary:hover,
  .session-actions button.secondary:hover {
    background: rgba(255, 255, 255, 0.1);
    color: var(--text-1);
  }

  .quick-jumps {
    display: flex;
    gap: 0.5rem;
    margin-top: 1rem;
    padding-top: 1rem;
    border-top: 1px solid var(--line-1);
  }

  .quick-jumps button {
    flex: 1;
    padding: 0.5rem;
    background: rgba(255, 255, 255, 0.04);
    border: 1px solid var(--line-1);
    border-radius: 8px;
    color: var(--text-3);
    cursor: pointer;
    font-size: 0.8rem;
    transition: all 0.2s;
  }

  .quick-jumps button:hover {
    background: rgba(255, 255, 255, 0.09);
    border-color: var(--line-2);
    color: var(--text-1);
  }

  .saved-session-panel p {
    margin: 0.5rem 0;
    color: var(--text-2);
  }

  .saved-session-panel .saved-time {
    color: var(--text-3);
    font-size: 0.85rem;
    margin-bottom: 1rem;
  }

  @media (prefers-reduced-motion: reduce) {
    .orb {
      animation: none;
    }

    .panel-overlay,
    .jump-to-panel,
    .saved-session-panel {
      animation: none;
    }
  }
</style>