<script>
  import { createEventDispatcher } from 'svelte';

  export let progress = 0;
  export let currentWord = 0;
  export let totalWords = 0;
  export let wpm = 300;
  export let timeRemaining = '0:00';
  export let minimal = false;
  export let clickable = false;

  const dispatch = createEventDispatcher();

  function handleClick(event) {
    if (!clickable) return;
    const rect = event.currentTarget.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const percentage = (x / rect.width) * 100;
    dispatch('seek', { percentage: Math.max(0, Math.min(100, percentage)) });
  }

  function handleKeydown(event) {
    if (!clickable) return;
    const step = event.shiftKey ? 10 : 1;
    if (event.key === 'ArrowLeft' || event.key === 'ArrowDown') {
      event.preventDefault();
      dispatch('seek', { percentage: Math.max(0, progress - step) });
    } else if (event.key === 'ArrowRight' || event.key === 'ArrowUp') {
      event.preventDefault();
      dispatch('seek', { percentage: Math.min(100, progress + step) });
    } else if (event.key === 'Home') {
      event.preventDefault();
      dispatch('seek', { percentage: 0 });
    } else if (event.key === 'End') {
      event.preventDefault();
      dispatch('seek', { percentage: 100 });
    }
  }
</script>

<div class="progress-wrapper" class:minimal>
  <!-- svelte-ignore a11y_no_noninteractive_tabindex -->
  <div
    class="progress-container"
    class:clickable
    style="--progress: {progress}%"
    role={clickable ? "slider" : undefined}
    tabindex={clickable ? 0 : undefined}
    aria-valuenow={clickable ? Math.round(progress) : undefined}
    aria-valuemin={clickable ? 0 : undefined}
    aria-valuemax={clickable ? 100 : undefined}
    aria-label={clickable ? "Reading progress" : undefined}
    on:click={handleClick}
    on:keydown={handleKeydown}
  >
    <div class="progress-bar" style="width: {progress}%"></div>
  </div>

  {#if !minimal}
    <div class="stats">
      <span class="stat">{currentWord} / {totalWords}</span>
      <span class="stat wpm">{wpm} WPM</span>
      <span class="stat">{timeRemaining}</span>
    </div>
  {/if}
</div>

<style>
  .progress-wrapper {
    width: 100%;
  }

  .progress-container {
    position: relative;
    height: 4px;
    background: rgba(255, 255, 255, 0.09);
    border-radius: 999px;
    box-shadow: inset 0 0 6px rgba(0, 0, 0, 0.6);
  }

  .progress-container.clickable {
    cursor: pointer;
    height: 6px;
    transition: height 0.2s ease;
  }

  .progress-container.clickable:hover,
  .progress-container.clickable:focus {
    height: 8px;
    outline: none;
  }

  .progress-container.clickable:focus-visible {
    box-shadow: 0 0 0 2px var(--accent), 0 0 14px var(--glow-ui);
  }

  .minimal .progress-container {
    height: 2px;
  }

  .progress-bar {
    height: 100%;
    border-radius: 999px;
    background: linear-gradient(90deg, var(--accent-2), var(--accent));
    box-shadow: 0 0 10px var(--glow-ui);
    transition: width 0.1s linear;
  }

  /* Glowing position dot, visible while seeking */
  .progress-container::after {
    content: '';
    position: absolute;
    top: 50%;
    left: var(--progress, 0%);
    width: 12px;
    height: 12px;
    transform: translate(-50%, -50%) scale(0);
    background: #fff;
    border-radius: 50%;
    box-shadow: 0 0 10px var(--glow-ui-strong), 0 0 0 2px var(--accent);
    transition: transform 0.25s ease;
  }

  .progress-container.clickable::after {
    transform: translate(-50%, -50%) scale(1);
  }

  .progress-container.clickable:hover::after {
    transform: translate(-50%, -50%) scale(1.35);
  }

  .minimal .progress-container::after {
    display: none;
  }

  .stats {
    display: flex;
    justify-content: space-between;
    margin-top: 0.7rem;
    font-size: 0.85rem;
    color: var(--text-3);
  }

  .stat {
    font-family: var(--font-mono);
    font-size: 0.82rem;
    letter-spacing: 0.02em;
    font-variant-numeric: tabular-nums;
  }

  .wpm {
    color: var(--accent);
    text-shadow: 0 0 8px var(--glow-ui);
  }

  @media (max-width: 600px) {
    .stats {
      font-size: 0.75rem;
      gap: 0.5rem;
    }
  }
</style>