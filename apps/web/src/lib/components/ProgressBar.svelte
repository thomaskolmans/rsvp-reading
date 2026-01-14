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
    height: 3px;
    background: #222;
    border-radius: 2px;
    overflow: hidden;
  }

  .progress-container.clickable {
    cursor: pointer;
    height: 6px;
    transition: height 0.2s ease;
  }

  .progress-container.clickable:hover,
  .progress-container.clickable:focus {
    height: 10px;
    outline: none;
  }

  .progress-container.clickable:focus-visible {
    box-shadow: 0 0 0 2px #ff4444;
  }

  .minimal .progress-container {
    height: 2px;
  }

  .progress-bar {
    height: 100%;
    background: linear-gradient(90deg, #ff4444, #ff6666);
    transition: width 0.1s linear;
  }

  .stats {
    display: flex;
    justify-content: space-between;
    margin-top: 0.75rem;
    font-size: 0.85rem;
    color: #555;
  }

  .stat {
    font-family: monospace;
  }

  .wpm {
    color: #ff4444;
  }

  @media (max-width: 600px) {
    .stats {
      font-size: 0.75rem;
      gap: 0.5rem;
    }
  }
</style>
