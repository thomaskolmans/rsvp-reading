<script>
  import { createEventDispatcher } from 'svelte';
  import { getSupportedExtensions } from '../file-parsers.js';

  export let text = '';
  export let isLoading = false;
  export let loadingMessage = '';

  const dispatch = createEventDispatcher();
  let fileInputEl;

  function handleApply() {
    dispatch('apply', { text });
  }

  function handleClose() {
    dispatch('close');
  }

  function handleFileChange(event) {
    dispatch('fileselect', { file: event.target.files?.[0] });
  }

  function triggerFileUpload() {
    fileInputEl?.click();
  }
</script>

<div class="text-input-panel">
  <div class="panel-header">
    <h3>Load Content</h3>
    <button class="close-icon" on:click={handleClose} title="Close">
      <svg viewBox="0 0 24 24" fill="currentColor">
        <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
      </svg>
    </button>
  </div>

  <div class="upload-section">
    <input
      type="file"
      accept={getSupportedExtensions()}
      on:change={handleFileChange}
      bind:this={fileInputEl}
      class="hidden-input"
    />
    <button class="upload-btn" on:click={triggerFileUpload} disabled={isLoading}>
      <svg viewBox="0 0 24 24" fill="currentColor">
        <path d="M14 2H6c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 1.99 2H18c1.1 0 2-.9 2-2V8l-6-6zm4 18H6V4h7v5h5v11zM8 15.01l1.41 1.41L11 14.84V19h2v-4.16l1.59 1.59L16 15.01 12.01 11 8 15.01z"/>
      </svg>
      <span>Upload PDF or EPUB</span>
    </button>
    {#if loadingMessage}
      <p class="loading-message">{loadingMessage}</p>
    {/if}
  </div>

  <div class="divider">
    <span>or paste text</span>
  </div>

  <textarea
    bind:value={text}
    placeholder="Paste or type your text here..."
    rows="8"
    disabled={isLoading}
  ></textarea>

  <div class="panel-actions">
    <button class="btn-secondary" on:click={handleClose}>Cancel</button>
    <button class="btn-primary" on:click={handleApply} disabled={isLoading || !text.trim()}>
      Load Text
    </button>
  </div>
</div>

<style>
  .text-input-panel {
    background: linear-gradient(180deg, rgba(10, 13, 24, 0.94), rgba(17, 22, 40, 0.94));
    border: 1px solid var(--line-1);
    border-radius: 20px;
    padding: 1.5rem;
    width: 100%;
    max-width: 500px;
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

  .panel-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.5rem;
  }

  h3 {
    margin: 0;
    font-weight: 600;
    color: var(--text-1);
    font-size: 1.2rem;
  }

  .close-icon {
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid var(--line-1);
    color: var(--text-3);
    cursor: pointer;
    padding: 0.4rem;
    display: flex;
    border-radius: 9px;
    transition: all 0.2s;
  }

  .close-icon:hover {
    color: var(--text-1);
    background: rgba(255, 255, 255, 0.1);
    border-color: var(--line-2);
  }

  .close-icon svg {
    width: 19px;
    height: 19px;
  }

  .hidden-input {
    display: none;
  }

  .upload-section {
    margin-bottom: 1rem;
  }

  .upload-btn {
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.75rem;
    padding: 1rem;
    background: rgba(255, 255, 255, 0.03);
    border: 1.5px dashed var(--line-2);
    border-radius: 14px;
    color: var(--text-2);
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.25s;
  }

  .upload-btn:hover:not(:disabled) {
    border-color: var(--accent);
    color: var(--text-1);
    background: rgba(255, 59, 92, 0.08);
    box-shadow: 0 0 20px var(--glow-ui);
    transform: translateY(-1px);
  }

  .upload-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .upload-btn svg {
    width: 24px;
    height: 24px;
  }

  .loading-message {
    margin: 0.75rem 0 0;
    color: var(--accent);
    font-size: 0.9rem;
    text-align: center;
    text-shadow: 0 0 10px var(--glow-ui);
  }

  .divider {
    display: flex;
    align-items: center;
    margin: 1.25rem 0;
    color: var(--text-3);
    font-size: 0.85rem;
  }

  .divider::before,
  .divider::after {
    content: '';
    flex: 1;
    height: 1px;
    background: var(--line-1);
  }

  .divider span {
    padding: 0 1rem;
  }

  textarea {
    width: 100%;
    background: rgba(255, 255, 255, 0.045);
    border: 1px solid var(--line-2);
    border-radius: 12px;
    color: var(--text-1);
    padding: 1rem;
    font-size: 0.95rem;
    font-family: inherit;
    resize: vertical;
    box-sizing: border-box;
    min-height: 120px;
    transition: border-color 0.2s, box-shadow 0.2s;
  }

  textarea:focus {
    outline: none;
    border-color: rgba(255, 255, 255, 0.3);
    box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.05);
  }

  textarea:disabled {
    opacity: 0.5;
  }

  .panel-actions {
    display: flex;
    gap: 0.75rem;
    margin-top: 1rem;
  }

  .panel-actions button {
    flex: 1;
    padding: 0.75rem 1rem;
    border-radius: 12px;
    font-size: 0.95rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn-secondary {
    background: rgba(255, 255, 255, 0.06);
    border: 1px solid var(--line-2);
    color: var(--text-2);
  }

  .btn-secondary:hover {
    background: rgba(255, 255, 255, 0.1);
    color: var(--text-1);
  }

  .btn-primary {
    background: linear-gradient(135deg, var(--accent-2), var(--accent));
    border: none;
    color: #fff;
    box-shadow: 0 4px 14px rgba(0, 0, 0, 0.35), 0 0 14px var(--glow-ui);
  }

  .btn-primary:hover:not(:disabled) {
    box-shadow: 0 4px 18px rgba(0, 0, 0, 0.4), 0 0 22px var(--glow-ui-strong);
    transform: translateY(-1px);
  }

  .btn-primary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  @media (max-width: 600px) {
    .text-input-panel {
      max-width: 100%;
      padding: 1rem;
      border-radius: 14px;
    }

    textarea {
      min-height: 100px;
      font-size: 16px; /* Prevents iOS zoom */
    }

    .upload-btn {
      padding: 0.875rem;
      font-size: 0.9rem;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .text-input-panel {
      animation: none;
    }
  }
</style>