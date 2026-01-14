/**
 * Native file dialog abstraction for Electron and browser compatibility
 */

// Type for Electron API exposed via preload
interface ElectronAPI {
  platform: string
  isElectron: boolean
  openFileDialog: () => Promise<string | null>
  readFile: (filePath: string) => Promise<ArrayBuffer>
  getFileInfo: (filePath: string) => Promise<{ name: string; extension: string; path: string }>
  onFileOpened: (callback: (filePath: string) => void) => () => void
  onMenuCommand: (callback: (command: string) => void) => () => void
}

// Extend window type for Electron
declare global {
  interface Window {
    electronAPI?: ElectronAPI
  }
}

/**
 * Check if running in Electron environment
 */
export function isElectron(): boolean {
  return typeof window !== 'undefined' && !!window.electronAPI?.isElectron
}

/**
 * Get the platform (darwin, win32, linux, or 'web')
 */
export function getPlatform(): string {
  if (isElectron() && window.electronAPI) {
    return window.electronAPI.platform
  }
  return 'web'
}

/**
 * Result from file selection
 */
export interface FileSelectionResult {
  file: File
  filePath?: string // Only available in Electron
}

/**
 * Open a file dialog and return the selected file
 * Uses native dialog in Electron, browser file input otherwise
 */
export async function openFileDialog(accept: string = '.pdf,.epub,.txt'): Promise<FileSelectionResult | null> {
  if (isElectron() && window.electronAPI) {
    return openNativeFileDialog()
  }
  return openBrowserFileDialog(accept)
}

/**
 * Open native Electron file dialog
 */
async function openNativeFileDialog(): Promise<FileSelectionResult | null> {
  if (!window.electronAPI) return null

  const filePath = await window.electronAPI.openFileDialog()
  if (!filePath) return null

  const fileInfo = await window.electronAPI.getFileInfo(filePath)
  const buffer = await window.electronAPI.readFile(filePath)

  // Create a File object from the buffer
  const file = new File([buffer], fileInfo.name, {
    type: getMimeType(fileInfo.extension)
  })

  return { file, filePath }
}

/**
 * Open browser file input dialog
 */
function openBrowserFileDialog(accept: string): Promise<FileSelectionResult | null> {
  return new Promise((resolve) => {
    const input = document.createElement('input')
    input.type = 'file'
    input.accept = accept
    input.style.display = 'none'

    input.onchange = () => {
      const file = input.files?.[0]
      if (file) {
        resolve({ file })
      } else {
        resolve(null)
      }
      input.remove()
    }

    input.oncancel = () => {
      resolve(null)
      input.remove()
    }

    document.body.appendChild(input)
    input.click()
  })
}

/**
 * Read a file from path (Electron only)
 * Returns null in browser environment
 */
export async function readFileFromPath(filePath: string): Promise<File | null> {
  if (!isElectron() || !window.electronAPI) return null

  const fileInfo = await window.electronAPI.getFileInfo(filePath)
  const buffer = await window.electronAPI.readFile(filePath)

  return new File([buffer], fileInfo.name, {
    type: getMimeType(fileInfo.extension)
  })
}

/**
 * Subscribe to file opened events (from Finder, dock, etc.)
 * Returns unsubscribe function
 */
export function onFileOpened(callback: (filePath: string) => void): () => void {
  if (!isElectron() || !window.electronAPI) {
    // Return no-op unsubscribe for browser
    return () => {}
  }
  return window.electronAPI.onFileOpened(callback)
}

/**
 * Subscribe to menu command events
 * Returns unsubscribe function
 */
export function onMenuCommand(callback: (command: string) => void): () => void {
  if (!isElectron() || !window.electronAPI) {
    // Return no-op unsubscribe for browser
    return () => {}
  }
  return window.electronAPI.onMenuCommand(callback)
}

/**
 * Get MIME type from file extension
 */
function getMimeType(extension: string): string {
  const mimeTypes: Record<string, string> = {
    pdf: 'application/pdf',
    epub: 'application/epub+zip',
    txt: 'text/plain'
  }
  return mimeTypes[extension.toLowerCase()] || 'application/octet-stream'
}
