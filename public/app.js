const form = document.querySelector('#receiver-form');
const nameInput = document.querySelector('#receiver-name');
const nameCount = document.querySelector('#name-count');
const startButton = document.querySelector('#start-button');
const stopButton = document.querySelector('#stop-button');
const statusBadge = document.querySelector('#status-badge');
const statusLabel = document.querySelector('#status-label');
const receiverState = document.querySelector('#receiver-state');
const notice = document.querySelector('#notice');
const logList = document.querySelector('#log-list');
const logCount = document.querySelector('#log-count');

let lastLogCount = 0;

function setStatus(running) {
  statusBadge.dataset.state = running ? 'running' : 'stopped';
  statusLabel.textContent = running ? 'EN ESPERA' : 'DETENIDO';
  receiverState.textContent = running ? 'Activo y visible' : 'Apagado';
  startButton.disabled = running;
  stopButton.disabled = !running;
  document.querySelector('.signal-visual').classList.toggle('is-running', running);
}

function renderLogs(logs) {
  if (logs.length === lastLogCount) return;
  lastLogCount = logs.length;
  logCount.textContent = `${logs.length} ${logs.length === 1 ? 'EVENTO' : 'EVENTOS'}`;
  if (!logs.length) {
    logList.innerHTML = '<p class="empty-log">Los mensajes de UxPlay aparecerán aquí.</p>';
    return;
  }

  const fragment = document.createDocumentFragment();
  logs.slice(-60).forEach(({ time, text }) => {
    const row = document.createElement('p');
    const timestamp = document.createElement('time');
    const message = document.createElement('span');
    timestamp.dateTime = time;
    timestamp.textContent = new Date(time).toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
    message.textContent = text;
    row.append(timestamp, message);
    fragment.append(row);
  });
  logList.replaceChildren(fragment);
  logList.scrollTop = logList.scrollHeight;
}

async function refreshStatus() {
  try {
    const response = await fetch('/api/status', { cache: 'no-store' });
    const status = await response.json();
    setStatus(status.running);
    renderLogs(status.logs);
  } catch {
    notice.textContent = 'No se pudo contactar con el controlador local.';
  }
}

nameInput.addEventListener('input', () => {
  nameCount.textContent = String(nameInput.value.length);
});

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  notice.textContent = '';
  startButton.disabled = true;
  try {
    const response = await fetch('/api/start', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: nameInput.value }),
    });
    const result = await response.json();
    if (!response.ok) throw new Error(result.error);
    notice.textContent = 'UxPlay inicializado y esperando una conexión AirPlay.';
    await refreshStatus();
  } catch (error) {
    notice.textContent = error.message;
    startButton.disabled = false;
  }
});

stopButton.addEventListener('click', async () => {
  stopButton.disabled = true;
  try {
    await fetch('/api/stop', { method: 'POST' });
    notice.textContent = 'Receptor detenido.';
    await refreshStatus();
  } catch {
    notice.textContent = 'No se pudo detener el receptor.';
  }
});

function updateClock() {
  document.querySelector('#clock').textContent = new Intl.DateTimeFormat('es-ES', { hour: '2-digit', minute: '2-digit' }).format(new Date());
}

updateClock();
refreshStatus();
setInterval(updateClock, 15000);
setInterval(refreshStatus, 1500);