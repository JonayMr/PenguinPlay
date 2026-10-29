import { app, BrowserWindow, dialog } from 'electron';

let mainWindow;
let isClosing = false;
let closeServer = async () => {};

app.commandLine.appendSwitch('disable-gpu-vulkan');

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1120,
    height: 900,
    minWidth: 360,
    minHeight: 640,
    show: false,
    title: 'PenguinPlay',
    backgroundColor: '#f2f1e9',
    autoHideMenuBar: true,
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  mainWindow.once('ready-to-show', () => mainWindow.show());
  mainWindow.on('closed', () => {
    mainWindow = null;
  });
  mainWindow.loadURL('http://127.0.0.1:4173');
}

const hasSingleInstanceLock = app.requestSingleInstanceLock();
if (!hasSingleInstanceLock) {
  app.quit();
} else {
  app.on('second-instance', () => {
    if (!mainWindow) return;
    if (mainWindow.isMinimized()) mainWindow.restore();
    mainWindow.focus();
  });

  app.whenReady().then(async () => {
    process.env.PENGUINPLAY_DESKTOP = '1';
    const server = await import('../server.js');
    closeServer = server.closeServer;
    createWindow();
  });
}

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow();
});

app.on('before-quit', (event) => {
  if (isClosing) return;
  event.preventDefault();
  isClosing = true;
  closeServer().catch((error) => {
    dialog.showErrorBox('PenguinPlay', `No se pudo cerrar el receptor correctamente: ${error.message}`);
  }).finally(() => app.quit());
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});