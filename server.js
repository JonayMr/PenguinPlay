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
  const candidates = [
    process.env.UXPLAY_BIN,
    join(homedir(), '.local', 'bin', 'uxplay'),
    '/usr/local/bin/uxplay',
    '/usr/bin/uxplay',
    ...((process.env.PATH ?? '').split(':').map((directory) => join(directory, 'uxplay'))),
  ].filter(Boolean);

  for (const candidate of candidates) {
    try {
      await access(candidate, constants.X_OK);
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
    if (body.length > 4096) throw new Error('La solicitud es demasiado grande.');
  }
  return JSON.parse(body || '{}');
}

async function serveStatic(pathname, response) {
  const relativePath = pathname === '/' ? 'index.html' : decodeURIComponent(pathname.slice(1));
  const filePath = resolve(publicRoot, relativePath);
  if (!filePath.startsWith(`${publicRoot}${sep}`)) {
    sendJson(response, 404, { error: 'No encontrado.' });
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
    sendJson(response, 404, { error: 'No encontrado.' });
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
      sendJson(response, 403, { error: 'Origen no permitido.' });
      return;
    }

    if (url.pathname === '/api/stop') {
      if (receiver && receiver.exitCode === null && receiver.signalCode === null && !receiver.killed) receiver.kill('SIGTERM');
      sendJson(response, 200, currentStatus());
      return;
    }

    if (receiver && receiver.exitCode === null && receiver.signalCode === null) {
      sendJson(response, 409, { error: 'El receptor ya está activo.' });
      return;
    }

    try {
      const body = await readJson(request);
      const name = typeof body.name === 'string' ? body.name.trim() : '';
      if (!/^[\p{L}\p{N} _.-]{1,40}$/u.test(name)) {
        sendJson(response, 400, { error: 'Usa un nombre de 1 a 40 letras, números, espacios, puntos, guiones o guiones bajos.' });
        return;
      }

      const binary = await findUxPlay();
      if (!binary) {
        sendJson(response, 503, { error: 'No encuentro uxplay. Ejecuta ./scripts/install-uxplay.sh o revisa el README.' });
        return;
      }

      logs.length = 0;
      lastExit = null;
      const args = ['-n', name, '-nh', '-p', '35000', '-fps', '60'];
      addLog('Arrancando UxPlay con selección automática de decoder y salida de vídeo.');
      addLog('Solicito hasta 60 FPS; sincronización de audio/vídeo activa.');
      const child = spawn('stdbuf', ['-oL', '-eL', binary, ...args], { stdio: ['ignore', 'pipe', 'pipe'] });
      receiver = Object.assign(child, { binary });
      addLog(`Proceso iniciado: ${name} (${binary}).`);
      child.stdout.setEncoding('utf8').on('data', (text) => text.split(/\r?\n/).forEach(addLog));
      child.stderr.setEncoding('utf8').on('data', (text) => text.split(/\r?\n/).forEach(addLog));
      child.on('error', (error) => {
        addLog(`Error al iniciar: ${error.message}`);
        lastExit = { code: null, signal: null };
      });
      child.on('exit', (code, signal) => {
        lastExit = { code, signal };
        addLog(`UxPlay finalizó (${signal ?? `código ${code}`}).`);
      });
      sendJson(response, 202, currentStatus());
    } catch (error) {
      sendJson(response, 400, { error: error instanceof SyntaxError ? 'JSON no válido.' : error.message });
    }
    return;
  }

  if (request.method === 'GET') {
    await serveStatic(url.pathname, response);
    return;
  }

  sendJson(response, 405, { error: 'Método no permitido.' });
});

server.listen(port, '127.0.0.1', () => {
  console.log(`PenguinPlay listo en http://127.0.0.1:${port}`);
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