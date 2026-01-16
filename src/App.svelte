<script>
  import { onMount, onDestroy } from 'svelte';
  import {
    parseText as parseTextUtil,
    getWordDelay as getWordDelayUtil,
    formatTimeRemaining,
    shouldPauseAtWord
  } from './lib/rsvp-utils.js';
  import { parseFile } from './lib/file-parsers.js';
  import {
    saveSession,
    loadSession,
    clearSession,
    hasSession,
    getSessionSummary
  } from './lib/progress-storage.js';
  import RSVPDisplay from './lib/components/RSVPDisplay.svelte';
  import Controls from './lib/components/Controls.svelte';
  import Settings from './lib/components/Settings.svelte';
  import TextInput from './lib/components/TextInput.svelte';
  import ProgressBar from './lib/components/ProgressBar.svelte';
  import { extractWordFrame } from './lib/rsvp-utils.js';

  // State
  let frameWordCount = 1;
  let text = `Rapid serial visual presentation (RSVP) is a scientific method for studying the timing of vision. In RSVP, a sequence of stimuli is shown to an observer at one location in their visual field. This technique has been adapted for speed reading applications, where words are displayed one at a time at a fixed point, eliminating the need for eye movements and potentially increasing reading speed significantly.`;
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
  let searchResults = [];
  let isSearchMode = false;

  // Settings
  let wordsPerMinute = 300;
  let fadeEnabled = true;
  let fadeDuration = 150;
  let pauseAfterWords = 0;
  let pauseDuration = 500;
  let pauseOnPunctuation = true;
  let punctuationPauseMultiplier = 2;
  let wordLengthWPMMultiplier = 5;

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
      settings: {
        wordsPerMinute,
        fadeEnabled,
        fadeDuration,
        pauseOnPunctuation,
        punctuationPauseMultiplier,
        wordLengthWPMMultiplier,
        pauseAfterWords,
        pauseDuration,
        frameWordCount
      }
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
      wordsPerMinute = session.settings.wordsPerMinute ?? wordsPerMinute;
      fadeEnabled = session.settings.fadeEnabled ?? fadeEnabled;
      fadeDuration = session.settings.fadeDuration ?? fadeDuration;
      pauseOnPunctuation = session.settings.pauseOnPunctuation ?? pauseOnPunctuation;
      punctuationPauseMultiplier = session.settings.punctuationPauseMultiplier ?? punctuationPauseMultiplier;
      wordLengthWPMMultiplier = session.settings.wordLengthWPMMultiplier ?? wordLengthWPMMultiplier;
      pauseAfterWords = session.settings.pauseAfterWords ?? pauseAfterWords;
      pauseDuration = session.settings.pauseDuration ?? pauseDuration;
      frameWordCount = session.settings.frameWordCount ?? frameWordCount;
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

  function searchText(query) {
    if (!query || query.length < 2 || words.length === 0) return [];

    const results = [];
    const lowerQuery = query.toLowerCase();
    const maxResults = 20;

    for (let i = 0; i < words.length && results.length < maxResults; i++) {
      const contextWindow = words.slice(i, i + 10).join(' ').toLowerCase();

      if (contextWindow.includes(lowerQuery)) {
        const start = Math.max(0, i - 5);
        const end = Math.min(words.length, i + 15);
        const context = words.slice(start, end).join(' ');

        results.push({
          index: i,
          context: context,
          percentage: Math.round((i / words.length) * 100)
        });

        i += 5;
      }
    }

    return results;
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
          searchResults = [];
          isSearchMode = false;
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

<main class:focus-mode={isFocusMode}>
  <!-- Header - hidden during focus mode -->
  {#if !isFocusMode}
    <header>
      <h1>RSVP Reader</h1>
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
        on:close={() => showSettings = false}
      />
    </div>
  {/if}

  {#if showJumpTo && !isFocusMode}
    <div class="panel-overlay" on:click|self={() => { showJumpTo = false; searchResults = []; isSearchMode = false; }} role="presentation">
      <div class="jump-to-panel">
        <h3>Jump to position</h3>

        <!-- Tabs para alternar entre modos -->
        <div class="search-tabs">
          <button
            class:active={!isSearchMode}
            on:click={() => { isSearchMode = false; searchResults = []; jumpToValue = ''; }}
          >
            By Position
          </button>
          <button
            class:active={isSearchMode}
            on:click={() => { isSearchMode = true; jumpToValue = ''; }}
          >
            Search Text
          </button>
        </div>

        {#if isSearchMode}
          <!-- Modo de busca -->
          <p class="jump-hint">Search for a word or phrase in the text</p>
          <form on:submit|preventDefault={() => { searchResults = searchText(jumpToValue); }}>
            <!-- svelte-ignore a11y_autofocus -->
            <input
              type="text"
              bind:value={jumpToValue}
              placeholder="Type to search..."
              on:input={() => {
                if (jumpToValue.length >= 2) {
                  searchResults = searchText(jumpToValue);
                } else {
                  searchResults = [];
                }
              }}
              autofocus
            />
          </form>

          {#if searchResults.length > 0}
            <div class="search-results">
              {#each searchResults as result}
                <button
                  class="search-result"
                  on:click={() => {
                    currentWordIndex = result.index;
                    progress = (currentWordIndex / words.length) * 100;
                    showJumpTo = false;
                    jumpToValue = '';
                    searchResults = [];
                    isSearchMode = false;
                  }}
                >
                  <span class="result-position">Word {result.index} ({result.percentage}%)</span>
                  <span class="result-context">...{result.context}...</span>
                </button>
              {/each}
            </div>
          {:else if jumpToValue.length >= 2}
            <p class="no-results">No results found</p>
          {/if}

        {:else}
          <!-- Modo original por posição -->
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
        {/if}
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
    <RSVPDisplay
      word={currentWord}
      wordGroup={wordFrame.subset}
      highlightIndex={wordFrame.centerOffset}
      opacity={wordOpacity}
      {fadeDuration}
      {fadeEnabled}
      multiWordEnabled={frameWordCount > 1}
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
        <kbd>Space</kbd> Play
        <kbd>Esc</kbd> Exit
        <kbd>↑↓</kbd> Speed
        <kbd>←→</kbd> Skip
        <kbd>G</kbd> Jump
        <kbd>Ctrl+S</kbd> Save
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
    background-color: #000 !important;
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
    background-color: #000;
    color: #fff;
    font-family: 'Segoe UI', system-ui, sans-serif;
    padding: 2rem;
    box-sizing: border-box;
    transition: padding 0.3s ease;
    overflow: hidden;
  }

  main.focus-mode {
    padding: 1rem;
  }

  header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1rem;
    flex-shrink: 0;
  }

  h1 {
    font-size: 1.25rem;
    font-weight: 400;
    color: #555;
    margin: 0;
  }

  .header-actions {
    display: flex;
    gap: 0.5rem;
  }

  .icon-btn {
    background: transparent;
    border: 1px solid #333;
    color: #555;
    padding: 0.5rem;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .icon-btn:hover {
    border-color: #555;
    color: #fff;
  }

  .icon-btn.active {
    border-color: #ff4444;
    color: #ff4444;
  }

  .icon-btn svg {
    width: 20px;
    height: 20px;
  }

  .panel-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.8);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 100;
    padding: 2rem;
  }

  .display-area {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 0;
    overflow: hidden;
  }

  .bottom-bar {
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
    color: #444;
    font-size: 0.8rem;
  }

  kbd {
    background: #1a1a1a;
    padding: 0.15rem 0.4rem;
    border-radius: 3px;
    font-family: monospace;
    color: #666;
    margin-right: 0.25rem;
  }

  /* Touch controls for mobile */
  .touch-controls {
    display: none;
    justify-content: center;
    align-items: center;
    gap: 0.5rem;
  }

  .touch-btn {
    background: #1a1a1a;
    border: 1px solid #333;
    color: #888;
    padding: 0.5rem 0.75rem;
    border-radius: 6px;
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
    background: #333;
    color: #fff;
  }

  .touch-btn svg {
    width: 20px;
    height: 20px;
  }

  .wpm-display {
    color: #ff4444;
    font-family: monospace;
    font-size: 0.85rem;
    min-width: 3rem;
    text-align: center;
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

  /* Jump to panel */
  .jump-to-panel,
  .saved-session-panel {
    background: #1a1a1a;
    border: 1px solid #333;
    border-radius: 12px;
    padding: 1.5rem;
    max-width: 320px;
    width: 100%;
  }

  .jump-to-panel h3,
  .saved-session-panel h3 {
    margin: 0 0 0.5rem 0;
    color: #fff;
    font-size: 1.1rem;
  }

  .jump-hint {
    color: #666;
    font-size: 0.85rem;
    margin: 0 0 1rem 0;
  }

  .jump-to-panel input {
    width: 100%;
    padding: 0.75rem;
    background: #111;
    border: 1px solid #333;
    border-radius: 6px;
    color: #fff;
    font-size: 1rem;
    margin-bottom: 1rem;
    box-sizing: border-box;
  }

  .jump-to-panel input:focus {
    outline: none;
    border-color: #ff4444;
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
    border-radius: 6px;
    border: none;
    cursor: pointer;
    font-size: 0.9rem;
    transition: all 0.2s;
  }

  .jump-actions button.primary,
  .session-actions button.primary {
    background: #ff4444;
    color: #fff;
  }

  .jump-actions button.primary:hover,
  .session-actions button.primary:hover {
    background: #ff6666;
  }

  .jump-actions button.secondary,
  .session-actions button.secondary {
    background: #333;
    color: #fff;
  }

  .jump-actions button.secondary:hover,
  .session-actions button.secondary:hover {
    background: #444;
  }

  .quick-jumps {
    display: flex;
    gap: 0.5rem;
    margin-top: 1rem;
    padding-top: 1rem;
    border-top: 1px solid #333;
  }

  .quick-jumps button {
    flex: 1;
    padding: 0.5rem;
    background: #222;
    border: 1px solid #333;
    border-radius: 4px;
    color: #888;
    cursor: pointer;
    font-size: 0.8rem;
    transition: all 0.2s;
  }

  .quick-jumps button:hover {
    background: #333;
    color: #fff;
  }

  .saved-session-panel p {
    margin: 0.5rem 0;
    color: #ccc;
  }

  .saved-session-panel .saved-time {
    color: #666;
    font-size: 0.85rem;
    margin-bottom: 1rem;
  }

  .icon-btn:disabled {
    opacity: 0.3;
    cursor: not-allowed;
  }

  /* Search tabs */
  .search-tabs {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 1rem;
  }

  .search-tabs button {
    flex: 1;
    padding: 0.5rem;
    background: #222;
    border: 1px solid #333;
    border-radius: 6px;
    color: #888;
    cursor: pointer;
    font-size: 0.85rem;
    transition: all 0.2s;
  }

  .search-tabs button:hover {
    background: #333;
    color: #fff;
  }

  .search-tabs button.active {
    background: #ff4444;
    border-color: #ff4444;
    color: #fff;
  }

  /* Search results */
  .search-results {
    max-height: 250px;
    overflow-y: auto;
    margin-top: 1rem;
    border: 1px solid #333;
    border-radius: 6px;
  }

  .search-result {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    width: 100%;
    padding: 0.75rem;
    background: transparent;
    border: none;
    border-bottom: 1px solid #333;
    color: #fff;
    cursor: pointer;
    text-align: left;
    transition: background 0.2s;
  }

  .search-result:last-child {
    border-bottom: none;
  }

  .search-result:hover {
    background: #222;
  }

  .result-position {
    font-size: 0.75rem;
    color: #ff4444;
    margin-bottom: 0.25rem;
  }

  .result-context {
    font-size: 0.85rem;
    color: #aaa;
    line-height: 1.4;
    overflow: hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
  }

  .no-results {
    color: #666;
    text-align: center;
    padding: 1rem;
    font-size: 0.9rem;
  }
</style>
