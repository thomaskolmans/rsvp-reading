import { app, BrowserWindow, ipcMain, dialog, nativeImage } from 'electron'
import { join, dirname } from 'path'
import { readFile } from 'fs/promises'
import { fileURLToPath } from 'url'
import { createMenu } from './menu.js'

const __filename = fileURLToPath(import.meta.url)
const __dirnameESM = dirname(__filename)

// Handle file opened from Finder/dock before app is ready
let pendingFilePath = null

// Keep a global reference of the window object
let mainWindow = null

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 600,
    minHeight: 400,
    titleBarStyle: 'hiddenInset',
    trafficLightPosition: { x: 16, y: 16 },
    backgroundColor: '#000000',
    webPreferences: {
      preload: join(__dirname, '../preload/preload.mjs'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  })

  // Load the app
  // electron-vite sets ELECTRON_RENDERER_URL in dev mode
  if (process.env.ELECTRON_RENDERER_URL) {
    mainWindow.loadURL(process.env.ELECTRON_RENDERER_URL)
  } else {
    mainWindow.loadFile(join(__dirname, '../renderer/index.html'))
  }

  // Create application menu
  createMenu(mainWindow)

  // Handle pending file from open-file event
  if (pendingFilePath) {
    mainWindow.webContents.once('did-finish-load', () => {
      mainWindow.webContents.send('file-opened', pendingFilePath)
      pendingFilePath = null
    })
  }

  mainWindow.on('closed', () => {
    mainWindow = null
  })
}

// macOS: Handle file opened from Finder before app is ready
app.on('open-file', (event, filePath) => {
  event.preventDefault()

  if (mainWindow) {
    mainWindow.webContents.send('file-opened', filePath)
  } else {
    pendingFilePath = filePath
  }
})

// Quit when all windows are closed (except on macOS)
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

app.on('activate', () => {
  if (mainWindow === null) {
    createWindow()
  }
})

app.whenReady().then(() => {
  // Set dock icon in dev mode (production uses embedded icon from electron-builder)
  if (process.platform === 'darwin' && process.env.ELECTRON_RENDERER_URL) {
    // From out/main/ -> ../../build/icon.png
    const iconPath = join(__dirnameESM, '../../build/icon.png')
    const icon = nativeImage.createFromPath(iconPath)
    if (!icon.isEmpty()) {
      app.dock.setIcon(icon)
    }
  }

  createWindow()
})

// IPC Handlers

// Open native file dialog
ipcMain.handle('open-file-dialog', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openFile'],
    filters: [
      { name: 'Documents', extensions: ['pdf', 'epub', 'txt'] },
      { name: 'PDF', extensions: ['pdf'] },
      { name: 'EPUB', extensions: ['epub'] },
      { name: 'Text', extensions: ['txt'] },
      { name: 'All Files', extensions: ['*'] }
    ]
  })

  if (result.canceled || result.filePaths.length === 0) {
    return null
  }

  return result.filePaths[0]
})

// Read file contents
ipcMain.handle('read-file', async (event, filePath) => {
  try {
    const buffer = await readFile(filePath)
    return buffer
  } catch (error) {
    console.error('Failed to read file:', error)
    throw error
  }
})

// Get file info (name, extension)
ipcMain.handle('get-file-info', async (event, filePath) => {
  const name = filePath.split('/').pop()
  const extension = name.split('.').pop().toLowerCase()
  return { name, extension, path: filePath }
})

// Menu command handlers - these forward to renderer
ipcMain.on('menu-command', (event, command) => {
  if (mainWindow) {
    mainWindow.webContents.send('menu-command', command)
  }
})
