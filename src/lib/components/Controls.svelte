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
    align-items: center;
    gap: 0.9rem;
  }

  .controls.minimal {
    gap: 0.75rem;
  }

  .control-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 0.65rem 1.4rem;
    min-height: 44px;
    font-size: 0.95rem;
    font-weight: 600;
    border: none;
    border-radius: 999px;
    cursor: pointer;
    transition: transform 0.15s ease, box-shadow 0.2s ease, background 0.2s ease, color 0.2s ease;
    color: var(--text-1);
  }

  .controls.minimal .control-btn {
    padding: 0;
    width: 48px;
    height: 48px;
    border-radius: 50%;
  }

  .control-btn svg {
    width: 20px;
    height: 20px;
  }

  .controls.minimal .control-btn svg {
    width: 20px;
    height: 20px;
  }

  .control-btn:hover:not(:disabled) {
    transform: translateY(-1px);
  }

  .control-btn:active:not(:disabled) {
    transform: translateY(1px) scale(0.96);
  }

  .control-btn:disabled {
    opacity: 0.35;
    cursor: not-allowed;
  }

  .control-btn.play {
    background: linear-gradient(135deg, var(--accent-2), var(--accent));
    color: #fff;
    box-shadow:
      0 0 0 1px rgba(255, 255, 255, 0.12),
      0 6px 20px rgba(0, 0, 0, 0.4),
      0 0 18px var(--glow-ui);
  }

  .control-btn.play:hover:not(:disabled) {
    box-shadow:
      0 0 0 1px rgba(255, 255, 255, 0.16),
      0 8px 26px rgba(0, 0, 0, 0.45),
      0 0 28px var(--glow-ui-strong);
  }

  .control-btn.pause {
    background: linear-gradient(135deg, #ffcf6e, #ff9f2e);
    color: #2b1d00;
    box-shadow:
      0 0 0 1px rgba(255, 255, 255, 0.12),
      0 6px 20px rgba(0, 0, 0, 0.4),
      0 0 18px var(--glow-amber);
  }

  .control-btn.pause:hover {
    box-shadow:
      0 0 0 1px rgba(255, 255, 255, 0.16),
      0 8px 26px rgba(0, 0, 0, 0.45),
      0 0 28px var(--glow-amber-strong);
  }

  .control-btn.stop,
  .control-btn.restart {
    background: rgba(255, 255, 255, 0.06);
    border: 1px solid var(--line-2);
    color: var(--text-2);
    box-shadow: 0 4px 14px rgba(0, 0, 0, 0.35);
  }

  .control-btn.stop:hover:not(:disabled),
  .control-btn.restart:hover:not(:disabled) {
    background: rgba(255, 255, 255, 0.12);
    border-color: rgba(255, 255, 255, 0.28);
    color: var(--text-1);
    box-shadow: 0 6px 18px rgba(0, 0, 0, 0.4);
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
      width: 52px;
      height: 52px;
    }
  }
</style>