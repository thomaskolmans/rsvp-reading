import { contextBridge, ipcRenderer } from 'electron'

// Expose protected methods that allow the renderer process to use
// ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
  // Platform detection
  platform: process.platform,
  isElectron: true,

  // File operations
  openFileDialog: () => ipcRenderer.invoke('open-file-dialog'),
  readFile: (filePath) => ipcRenderer.invoke('read-file', filePath),
  getFileInfo: (filePath) => ipcRenderer.invoke('get-file-info', filePath),

  // Event listeners for file opened from Finder/dock
  onFileOpened: (callback) => {
    const handler = (_event, filePath) => callback(filePath)
    ipcRenderer.on('file-opened', handler)
    // Return cleanup function
    return () => ipcRenderer.removeListener('file-opened', handler)
  },

  // Menu command listeners
  onMenuCommand: (callback) => {
    const handler = (_event, command) => callback(command)
    ipcRenderer.on('menu-command', handler)
    // Return cleanup function
    return () => ipcRenderer.removeListener('menu-command', handler)
  }
})
