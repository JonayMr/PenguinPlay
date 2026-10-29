import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { access, readFile } from 'node:fs/promises';
import { constants } from 'node:fs';
import { homedir } from 'node:os';
import { extname, join, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('.', import.meta.url));
const publicRoot = resolve(root, 'public');
const port = Number(process.env.PORT ?? 4173);
const logs = [];
let receiver = null;
let lastExit = null;

function addLog(line) {
  const cleanLine = line.replace(/\u001b\[[0-9;]*m/g, '').trim();
  if (!cleanLine) return;
  logs.push({ time: new Date().toISOString(), text: cleanLine.slice(0, 500) });
  if (logs.length > 120) logs.shift();
}

async function findUxPlay() {
  const isWindows = process.platform === 'win32';
  const executableName = isWindows ? 'uxplay.exe' : 'uxplay';
  const candidates = [
    process.env.UXPLAY_BIN,
    ...(isWindows ? [
      join(process.env.MSYS2_ROOT ?? 'C:\\msys64', 'ucrt64', 'bin', executableName),
      join(process.env.MSYS2_ROOT ?? 'C:\\msys64', 'mingw64', 'bin', executableName),
      join(homedir(), 'AppData', 'Local', 'Programs', 'UxPlay', executableName),
    ] : []),
    join(homedir(), '.local', 'bin', 'uxplay'),
    '/usr/local/bin/uxplay',
    '/usr/bin/uxplay',
    ...((process.env.PATH ?? '').split(isWindows ? ';' : ':').flatMap((directory) => [
      join(directory, executableName),
      ...(isWindows ? [join(directory, 'uxplay')] : []),
    ])),
  ].filter(Boolean);

  for (const candidate of candidates) {
    try {
      await access(candidate, isWindows ? constants.F_OK : constants.X_OK);
      return candidate;
    } catch {
      // Try the next known location.
    }
  }
  return null;
}

function sendJson(response, status, value) {
  response.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
  });
  response.end(JSON.stringify(value));
}

function currentStatus() {
  return {
    running: Boolean(receiver && receiver.exitCode === null && receiver.signalCode === null),
    pid: receiver?.pid ?? null,
    binary: receiver?.binary ?? null,
    lastExit,
    logs,
  };
}

async function readJson(request) {
  let body = '';
  for await (const chunk of request) {
    body += chunk;
    if (body.length > 4096) throw new Error('Request body is too large.');
  }
  return JSON.parse(body || '{}');
}

async function serveStatic(pathname, response) {
  const relativePath = pathname === '/' ? 'index.html' : decodeURIComponent(pathname.slice(1));
  const filePath = resolve(publicRoot, relativePath);
  if (!filePath.startsWith(`${publicRoot}${sep}`)) {
    sendJson(response, 404, { error: 'Not found.' });
    return;
  }

  try {
    const content = await readFile(filePath);
    const contentTypes = {
      '.css': 'text/css; charset=utf-8',
      '.html': 'text/html; charset=utf-8',
      '.js': 'text/javascript; charset=utf-8',
      '.svg': 'image/svg+xml',
    };
    response.writeHead(200, {
      'Content-Type': contentTypes[extname(filePath)] ?? 'application/octet-stream',
      'Cache-Control': 'no-cache',
      'X-Content-Type-Options': 'nosniff',
    });
    response.end(content);
  } catch {
    sendJson(response, 404, { error: 'Not found.' });
  }
}

const server = createServer(async (request, response) => {
  const url = new URL(request.url, `http://${request.headers.host ?? '127.0.0.1'}`);

  if (request.method === 'GET' && url.pathname === '/api/status') {
    sendJson(response, 200, currentStatus());
    return;
  }

  if (request.method === 'POST' && ['/api/start', '/api/stop'].includes(url.pathname)) {
    if (request.headers.origin && request.headers.origin !== `http://127.0.0.1:${port}` && request.headers.origin !== `http://localhost:${port}`) {
      sendJson(response, 403, { error: 'Origin not allowed.' });
      return;
    }

    if (url.pathname === '/api/stop') {
      if (receiver && receiver.exitCode === null && receiver.signalCode === null && !receiver.killed) receiver.kill('SIGTERM');
      sendJson(response, 200, currentStatus());
      return;
    }

    if (receiver && receiver.exitCode === null && receiver.signalCode === null) {
      sendJson(response, 409, { error: 'The receiver is already running.' });
      return;
    }

    try {
      const body = await readJson(request);
      const name = typeof body.name === 'string' ? body.name.trim() : '';
      if (!/^[\p{L}\p{N} _.-]{1,40}$/u.test(name)) {
        sendJson(response, 400, { error: 'Use a name with 1–40 letters, numbers, spaces, periods, hyphens, or underscores.' });
        return;
      }

      const binary = await findUxPlay();
      if (!binary) {
        sendJson(response, 503, { error: 'UxPlay was not found. Run ./scripts/install-uxplay.sh or see the README.' });
        return;
      }

      logs.length = 0;
      lastExit = null;
      const args = ['-n', name, '-nh', '-p', '35000', '-fps', '60'];
      addLog('Starting UxPlay with automatic decoder and video output selection.');
      addLog('Requesting up to 60 FPS; audio/video synchronization is enabled.');
      const command = process.platform === 'win32' ? binary : 'stdbuf';
      const commandArgs = process.platform === 'win32' ? args : ['-oL', '-eL', binary, ...args];
      const childEnv = { ...process.env };
      if (process.platform === 'win32') {
        const mingwPrefix = resolve(binary, '..', '..');
        const mingwBin = resolve(binary, '..');
        const gstPluginDir = join(mingwPrefix, 'lib', 'gstreamer-1.0');
        const gstScanner = join(mingwPrefix, 'libexec', 'gstreamer-1.0', 'gst-plugin-scanner.exe');
        childEnv.PATH = [mingwBin, childEnv.PATH].filter(Boolean).join(';');
        childEnv.GST_PLUGIN_PATH = childEnv.GST_PLUGIN_PATH
          ? `${gstPluginDir};${childEnv.GST_PLUGIN_PATH}`
          : gstPluginDir;
        childEnv.GST_PLUGIN_SCANNER = childEnv.GST_PLUGIN_SCANNER ?? gstScanner;
      }
      const child = spawn(command, commandArgs, { stdio: ['ignore', 'pipe', 'pipe'], env: childEnv });
      receiver = Object.assign(child, { binary });
      addLog(`Process started: ${name} (${binary}).`);
      child.stdout.setEncoding('utf8').on('data', (text) => text.split(/\r?\n/).forEach(addLog));
      child.stderr.setEncoding('utf8').on('data', (text) => text.split(/\r?\n/).forEach(addLog));
      child.on('error', (error) => {
        addLog(`Could not start UxPlay: ${error.message}`);
        lastExit = { code: null, signal: null };
      });
      child.on('exit', (code, signal) => {
        lastExit = { code, signal };
        addLog(`UxPlay exited (${signal ?? `code ${code}`}).`);
      });
      sendJson(response, 202, currentStatus());
    } catch (error) {
      sendJson(response, 400, { error: error instanceof SyntaxError ? 'Invalid JSON.' : error.message });
    }
    return;
  }

  if (request.method === 'GET') {
    await serveStatic(url.pathname, response);
    return;
  }

  sendJson(response, 405, { error: 'Method not allowed.' });
});

server.listen(port, '127.0.0.1', () => {
  console.log(`PenguinPlay is ready at http://127.0.0.1:${port}`);
});

export function stopReceiver() {
  if (receiver && receiver.exitCode === null && receiver.signalCode === null && !receiver.killed) receiver.kill('SIGTERM');
  if (!receiver || receiver.exitCode !== null || receiver.signalCode !== null) return Promise.resolve();
  return new Promise((resolve) => receiver.once('exit', resolve));
}

export async function closeServer() {
  await stopReceiver();
  if (!server.listening) return;
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
}

if (process.env.PENGUINPLAY_DESKTOP !== '1') {
  const shutDown = () => {
    closeServer().then(() => process.exit(0));
    setTimeout(() => process.exit(1), 3000).unref();
  };
  process.on('SIGINT', shutDown);
  process.on('SIGTERM', shutDown);
}