<script>
  import { createEventDispatcher } from 'svelte';
  import { getSupportedExtensions, isElectron, openFileDialog } from '@rsvp/core';

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

  async function triggerFileUpload() {
    // Use native file dialog in Electron, browser file input otherwise
    if (isElectron()) {
      const result = await openFileDialog(getSupportedExtensions());
      if (result) {
        dispatch('fileselect', { file: result.file, filePath: result.filePath });
      }
    } else {
      fileInputEl?.click();
    }
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
    background: #111;
    border: 1px solid #333;
    border-radius: 12px;
    padding: 1.5rem;
    width: 100%;
    max-width: 500px;
  }

  .panel-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.5rem;
  }

  h3 {
    margin: 0;
    font-weight: 500;
    color: #fff;
    font-size: 1.1rem;
  }

  .close-icon {
    background: transparent;
    border: none;
    color: #666;
    cursor: pointer;
    padding: 0.25rem;
    display: flex;
    transition: color 0.2s;
  }

  .close-icon:hover {
    color: #fff;
  }

  .close-icon svg {
    width: 20px;
    height: 20px;
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
    background: #1a1a1a;
    border: 2px dashed #444;
    border-radius: 8px;
    color: #aaa;
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.2s;
  }

  .upload-btn:hover:not(:disabled) {
    border-color: #ff4444;
    color: #fff;
    background: #222;
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
    color: #ff4444;
    font-size: 0.9rem;
    text-align: center;
  }

  .divider {
    display: flex;
    align-items: center;
    margin: 1.25rem 0;
    color: #555;
    font-size: 0.85rem;
  }

  .divider::before,
  .divider::after {
    content: '';
    flex: 1;
    height: 1px;
    background: #333;
  }

  .divider span {
    padding: 0 1rem;
  }

  textarea {
    width: 100%;
    background: #1a1a1a;
    border: 1px solid #333;
    border-radius: 8px;
    color: #fff;
    padding: 1rem;
    font-size: 0.95rem;
    font-family: inherit;
    resize: vertical;
    box-sizing: border-box;
    min-height: 120px;
  }

  textarea:focus {
    outline: none;
    border-color: #555;
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
    border-radius: 8px;
    font-size: 0.95rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn-secondary {
    background: #222;
    border: 1px solid #444;
    color: #aaa;
  }

  .btn-secondary:hover {
    background: #333;
    color: #fff;
  }

  .btn-primary {
    background: #ff4444;
    border: none;
    color: #fff;
  }

  .btn-primary:hover:not(:disabled) {
    background: #ff5555;
  }

  .btn-primary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  @media (max-width: 600px) {
    .text-input-panel {
      max-width: 100%;
      padding: 1rem;
      border-radius: 8px;
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
</style>
