import { Menu, app } from 'electron'

export function createMenu(mainWindow) {
  const isMac = process.platform === 'darwin'

  const template = [
    // App Menu (macOS only)
    ...(isMac ? [{
      label: app.name,
      submenu: [
        { role: 'about' },
        { type: 'separator' },
        {
          label: 'Preferences...',
          accelerator: 'Cmd+,',
          click: () => mainWindow.webContents.send('menu-command', 'preferences')
        },
        { type: 'separator' },
        { role: 'services' },
        { type: 'separator' },
        { role: 'hide' },
        { role: 'hideOthers' },
        { role: 'unhide' },
        { type: 'separator' },
        { role: 'quit' }
      ]
    }] : []),

    // File Menu
    {
      label: 'File',
      submenu: [
        {
          label: 'Open...',
          accelerator: 'CmdOrCtrl+O',
          click: () => mainWindow.webContents.send('menu-command', 'open')
        },
        { type: 'separator' },
        {
          label: 'Save Progress',
          accelerator: 'CmdOrCtrl+S',
          click: () => mainWindow.webContents.send('menu-command', 'save')
        },
        { type: 'separator' },
        isMac ? { role: 'close' } : { role: 'quit' }
      ]
    },

    // Edit Menu
    {
      label: 'Edit',
      submenu: [
        { role: 'undo' },
        { role: 'redo' },
        { type: 'separator' },
        { role: 'cut' },
        { role: 'copy' },
        { role: 'paste' },
        ...(isMac ? [
          { role: 'pasteAndMatchStyle' },
          { role: 'delete' },
          { role: 'selectAll' },
        ] : [
          { role: 'delete' },
          { type: 'separator' },
          { role: 'selectAll' }
        ])
      ]
    },

    // Playback Menu
    {
      label: 'Playback',
      submenu: [
        {
          label: 'Play/Pause',
          accelerator: 'Space',
          click: () => mainWindow.webContents.send('menu-command', 'toggle-play')
        },
        {
          label: 'Stop',
          accelerator: 'Escape',
          click: () => mainWindow.webContents.send('menu-command', 'stop')
        },
        { type: 'separator' },
        {
          label: 'Increase Speed',
          accelerator: 'Up',
          click: () => mainWindow.webContents.send('menu-command', 'speed-up')
        },
        {
          label: 'Decrease Speed',
          accelerator: 'Down',
          click: () => mainWindow.webContents.send('menu-command', 'speed-down')
        },
        { type: 'separator' },
        {
          label: 'Jump Forward',
          accelerator: 'Right',
          click: () => mainWindow.webContents.send('menu-command', 'jump-forward')
        },
        {
          label: 'Jump Backward',
          accelerator: 'Left',
          click: () => mainWindow.webContents.send('menu-command', 'jump-backward')
        },
        { type: 'separator' },
        {
          label: 'Jump to Position...',
          accelerator: 'CmdOrCtrl+G',
          click: () => mainWindow.webContents.send('menu-command', 'jump-to')
        }
      ]
    },

    // View Menu
    {
      label: 'View',
      submenu: [
        {
          label: 'Focus Mode',
          accelerator: 'CmdOrCtrl+F',
          click: () => mainWindow.webContents.send('menu-command', 'focus-mode')
        },
        { type: 'separator' },
        { role: 'reload' },
        { role: 'forceReload' },
        { role: 'toggleDevTools' },
        { type: 'separator' },
        { role: 'resetZoom' },
        { role: 'zoomIn' },
        { role: 'zoomOut' },
        { type: 'separator' },
        { role: 'togglefullscreen' }
      ]
    },

    // Window Menu
    {
      label: 'Window',
      submenu: [
        { role: 'minimize' },
        { role: 'zoom' },
        ...(isMac ? [
          { type: 'separator' },
          { role: 'front' },
          { type: 'separator' },
          { role: 'window' }
        ] : [
          { role: 'close' }
        ])
      ]
    },

    // Help Menu
    {
      role: 'help',
      submenu: [
        {
          label: 'Keyboard Shortcuts',
          click: () => mainWindow.webContents.send('menu-command', 'show-shortcuts')
        },
        { type: 'separator' },
        {
          label: 'Learn More',
          click: async () => {
            const { shell } = await import('electron')
            await shell.openExternal('https://github.com/yourusername/rsvp-reader')
          }
        }
      ]
    }
  ]

  const menu = Menu.buildFromTemplate(template)
  Menu.setApplicationMenu(menu)
}
