<script>
  import { createEventDispatcher } from 'svelte';

  export let isPlaying = false;
  export let isPaused = false;
  export let canPlay = true;
  export let minimal = false;

  const dispatch = createEventDispatcher();
</script>

<div class="controls" class:minimal>
  {#if !isPlaying && !isPaused}
    <button
      class="control-btn play"
      on:click={() => dispatch('play')}
      disabled={!canPlay}
      title="Play (Space)"
    >
      {#if minimal}
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M8 5v14l11-7z"/>
        </svg>
      {:else}
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M8 5v14l11-7z"/>
        </svg>
        <span>Play</span>
      {/if}
    </button>
  {:else if isPlaying}
    <button
      class="control-btn pause"
      on:click={() => dispatch('pause')}
      title="Pause (Space)"
    >
      {#if minimal}
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/>
        </svg>
      {:else}
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/>
        </svg>
        <span>Pause</span>
      {/if}
    </button>
  {:else}
    <button
      class="control-btn play"
      on:click={() => dispatch('resume')}
      title="Resume (Space)"
    >
      {#if minimal}
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M8 5v14l11-7z"/>
        </svg>
      {:else}
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M8 5v14l11-7z"/>
        </svg>
        <span>Resume</span>
      {/if}
    </button>
  {/if}

  <button
    class="control-btn stop"
    on:click={() => dispatch('stop')}
    disabled={!isPlaying && !isPaused}
    title="Stop (Esc)"
  >
    {#if minimal}
      <svg viewBox="0 0 24 24" fill="currentColor">
        <path d="M6 6h12v12H6z"/>
      </svg>
    {:else}
      <svg viewBox="0 0 24 24" fill="currentColor">
        <path d="M6 6h12v12H6z"/>
      </svg>
      <span>Stop</span>
    {/if}
  </button>

  {#if !minimal}
    <button
      class="control-btn restart"
      on:click={() => dispatch('restart')}
      disabled={!canPlay}
      title="Restart"
    >
      <svg viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 5V1L7 6l5 5V7c3.31 0 6 2.69 6 6s-2.69 6-6 6-6-2.69-6-6H4c0 4.42 3.58 8 8 8s8-3.58 8-8-3.58-8-8-8z"/>
      </svg>
      <span>Restart</span>
    </button>
  {/if}
</div>

<style>
  .controls {
    display: flex;
    justify-content: center;
    gap: 1rem;
  }

  .controls.minimal {
    gap: 0.5rem;
  }

  .control-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    font-size: 1rem;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s;
    font-weight: 500;
    color: #fff;
  }

  .controls.minimal .control-btn {
    padding: 0.5rem;
    border-radius: 50%;
    width: 40px;
    height: 40px;
  }

  .control-btn svg {
    width: 20px;
    height: 20px;
  }

  .controls.minimal .control-btn svg {
    width: 18px;
    height: 18px;
  }

  .control-btn:disabled {
    opacity: 0.3;
    cursor: not-allowed;
  }

  .control-btn.play {
    background: #ff4444;
  }

  .control-btn.play:hover:not(:disabled) {
    background: #ff6666;
  }

  .control-btn.pause {
    background: #ffaa00;
    color: #000;
  }

  .control-btn.pause:hover {
    background: #ffcc44;
  }

  .control-btn.stop,
  .control-btn.restart {
    background: #333;
  }

  .control-btn.stop:hover:not(:disabled),
  .control-btn.restart:hover:not(:disabled) {
    background: #444;
  }

  @media (max-width: 600px) {
    .controls {
      gap: 0.75rem;
    }

    .control-btn {
      padding: 0.875rem 1.25rem;
      min-height: 48px; /* Touch-friendly minimum */
    }

    .control-btn span {
      display: none;
    }

    .controls.minimal .control-btn {
      width: 48px;
      height: 48px;
    }
  }
</style>
