// F1 25 - Rafa Pro (versao propria, 60 fps)
// Le a telemetria UDP do F1 25 (formato 2025) e manda para a dash (iPhone) por WebSocket.
// Uso: dois cliques em Iniciar.bat (ou: node servidor.js). Sem dependencias.
// Roda no mesmo PC do jogo; no F1 25 o IP da telemetria fica 127.0.0.1.

const dgram = require('dgram');
const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');

const UDP_PORT = 20777;
const HTTP_PORT = 8888;
const HDR = 29;

// ================= ESTADO =================
let S, sessionUID = null, playerIdx = 0, redLap = 0;
function novoEstado() {
  return {
    ok: false,
    // corrida
    pos: 0, lap: 0, totalLaps: 0, gap: null, delta: null,
    curLap: 0, lastLap: 0, bestLap: 0, invalid: false, sector: 0,
    warnings: 0, penalties: 0, dt: 0, sg: 0,
    pitStatus: 0, stops: 0, laneMs: 0, stopMs: 0,
    // telemetria
    speed: 0, gear: 0, rpm: 0, revPct: 0, drs: 0,
    brakeT: [0, 0, 0, 0], tyreSurf: [0, 0, 0, 0], tyreInner: [0, 0, 0, 0], press: [0, 0, 0, 0],
    // status
    bias: 0, limiter: 0, drsAllowed: 0, compound: 0, tyreAge: 0, fia: 0,
    ers: 0, ersMode: 0, ersUsed: 0,
    // danos
    wear: [0, 0, 0, 0], fwl: 0, fwr: 0, rw: 0, floor: 0, diff: 0, sidepod: 0,
    drsFault: 0, gearbox: 0, engine: 0, ice: 0, mguh: 0, mguk: 0, es: 0, ce: 0, tc: 0,
    // sessao
    weather: 0, air: 0, track: 0, sessionType: 0, sc: 0, red: false,
    pitIdeal: 0, pitLatest: 0, rejoin: 0, rainNow: null, forecast: [null, null, null], scDelta: 0,
    // setores
    secLast: [0, 0, 0], secBest: [0, 0, 0],
  };
}
S = novoEstado();
// ordem das rodas no jogo: 0 TE, 1 TD, 2 DE, 3 DD -> na dash usamos DE, DD, TE, TD
const W = [2, 3, 0, 1];
const roda = (a) => W.map((i) => a[i]);

// ================= DELTA AO VIVO vs MELHOR VOLTA =================
// Grava (distancia, tempo) da volta atual; a melhor volta valida vira referencia.
let dl = { lapNum: -1, d: [], t: [], invalid: false, ref: null, refMs: 0 };
function deltaUpdate(lapNum, dist, curMs, invalid, lastMs) {
  if (lapNum !== dl.lapNum) {
    if (dl.lapNum !== -1 && lapNum === dl.lapNum + 1 && !dl.invalid && lastMs > 0 && dl.d.length > 20 &&
        (dl.ref === null || lastMs < dl.refMs)) {
      dl.ref = { d: dl.d, t: dl.t }; dl.refMs = lastMs;
    }
    dl.lapNum = lapNum; dl.d = []; dl.t = []; dl.invalid = false;
  }
  if (invalid) dl.invalid = true;
  if (dist < 0) return null;
  const n = dl.d.length;
  if (n && dist < dl.d[n - 1] - 1) { // flashback: corta o que ficou "no futuro"
    let k = n; while (k > 0 && dl.d[k - 1] > dist) k--;
    dl.d.length = k; dl.t.length = k;
  }
  if (!dl.d.length || dist - dl.d[dl.d.length - 1] >= 4) { dl.d.push(dist); dl.t.push(curMs); }
  const r = dl.ref; if (!r) return null;
  const rd = r.d; if (dist < rd[0] || dist > rd[rd.length - 1]) return null;
  let lo = 0, hi = rd.length - 1;
  while (hi - lo > 1) { const m = (lo + hi) >> 1; if (rd[m] <= dist) lo = m; else hi = m; }
  const f = rd[hi] > rd[lo] ? (dist - rd[lo]) / (rd[hi] - rd[lo]) : 0;
  const refT = r.t[lo] + (r.t[hi] - r.t[lo]) * f;
  return (curMs - refT) / 1000;
}

// ================= PACOTES =================
function parse(b) {
  if (b.length < HDR) return;
  const fmt = b.readUInt16LE(0);
  if (fmt !== 2025) { avisarFormato(fmt); }
  const id = b.readUInt8(6);
  const uid = b.readBigUInt64LE(7).toString();
  playerIdx = b.readUInt8(27);
  if (playerIdx > 21) return;
  if (uid !== sessionUID) { // sessao nova: zera tudo
    sessionUID = uid; S = novoEstado(); dl = { lapNum: -1, d: [], t: [], invalid: false, ref: null, refMs: 0 };
  }
  S.ok = true;
  try {
    switch (id) {
      case 1: session(b); break;
      case 2: lapData(b); break;
      case 3: evento(b); break;
      case 6: telemetry(b); return true; // 1x por quadro do jogo: hora de mandar
      case 7: status(b); break;
      case 10: damage(b); break;
      case 11: history(b); break;
    }
  } catch (e) { /* pacote cortado: ignora */ }
}

function session(b) {
  const o = HDR;
  S.weather = b.readUInt8(o);
  S.track = b.readInt8(o + 1);
  S.air = b.readInt8(o + 2);
  S.totalLaps = b.readUInt8(o + 3);
  S.sessionType = b.readUInt8(o + 6);
  S.sc = b.readUInt8(o + 124);
  const n = b.readUInt8(o + 126);
  const fc = [null, null, null], want = [5, 15, 30];
  for (let i = 0; i < n && i < 64; i++) {
    const s = o + 127 + i * 8;
    if (b.readUInt8(s) !== S.sessionType) continue;
    const k = want.indexOf(b.readUInt8(s + 1));
    if (k >= 0 && !fc[k]) fc[k] = { w: b.readUInt8(s + 2), rain: b.readUInt8(s + 7) };
  }
  // chuva "agora" = amostra de offset 0
  for (let i = 0; i < n && i < 64; i++) {
    const s = o + 127 + i * 8;
    if (b.readUInt8(s) === S.sessionType && b.readUInt8(s + 1) === 0) { S.rainNow = b.readUInt8(s + 7); break; }
  }
  S.forecast = fc;
  S.pitIdeal = b.readUInt8(o + 653);
  S.pitLatest = b.readUInt8(o + 654);
  S.rejoin = b.readUInt8(o + 655);
}

function lapData(b) {
  const o = HDR + playerIdx * 57;
  S.lastLap = b.readUInt32LE(o);
  S.curLap = b.readUInt32LE(o + 4);
  S.gap = b.readUInt8(o + 16) * 60 + b.readUInt16LE(o + 14) / 1000;
  const dist = b.readFloatLE(o + 20);
  S.scDelta = b.readFloatLE(o + 28);
  S.pos = b.readUInt8(o + 32);
  S.lap = b.readUInt8(o + 33);
  S.pitStatus = b.readUInt8(o + 34);
  S.stops = b.readUInt8(o + 35);
  S.sector = b.readUInt8(o + 36);
  S.invalid = b.readUInt8(o + 37) === 1;
  S.penalties = b.readUInt8(o + 38);
  S.warnings = b.readUInt8(o + 40); // avisos de corte de curva
  S.dt = b.readUInt8(o + 41);
  S.sg = b.readUInt8(o + 42);
  S.laneMs = b.readUInt16LE(o + 47);
  S.stopMs = b.readUInt16LE(o + 49);
  if (S.red && S.lap > redLap) S.red = false;
  S.delta = deltaUpdate(S.lap, dist, S.curLap, S.invalid, S.lastLap);
}

function evento(b) {
  const code = b.toString('ascii', HDR, HDR + 4);
  if (code === 'RDFL') { S.red = true; redLap = S.lap; }
  // acaba na relargada (luzes), em sessao nova/fim, ou quando voce fecha uma volta depois da vermelha
  else if (['STLG', 'LGOT', 'SSTA', 'SEND'].includes(code)) S.red = false;
}

function telemetry(b) {
  const o = HDR + playerIdx * 60;
  S.speed = b.readUInt16LE(o);
  S.gear = b.readInt8(o + 15);
  S.rpm = b.readUInt16LE(o + 16);
  S.drs = b.readUInt8(o + 18);
  S.revPct = b.readUInt8(o + 19);
  const bt = [], ts = [], ti = [], pr = [];
  for (let i = 0; i < 4; i++) {
    bt.push(b.readUInt16LE(o + 22 + i * 2));
    ts.push(b.readUInt8(o + 30 + i));
    ti.push(b.readUInt8(o + 34 + i));
    pr.push(b.readFloatLE(o + 40 + i * 4));
  }
  S.brakeT = roda(bt); S.tyreSurf = roda(ts); S.tyreInner = roda(ti); S.press = roda(pr);
}

function status(b) {
  const o = HDR + playerIdx * 55;
  S.bias = b.readUInt8(o + 3);
  S.limiter = b.readUInt8(o + 4);
  S.drsAllowed = b.readUInt8(o + 22);
  S.compound = b.readUInt8(o + 26);
  S.tyreAge = b.readUInt8(o + 27);
  S.fia = b.readInt8(o + 28);
  S.ers = b.readFloatLE(o + 37) / 4e6 * 100;
  S.ersMode = b.readUInt8(o + 41);
  S.ersUsed = b.readFloatLE(o + 50) / 4e6 * 100;
}

function damage(b) {
  const o = HDR + playerIdx * 46;
  const w = [];
  for (let i = 0; i < 4; i++) w.push(b.readFloatLE(o + i * 4));
  S.wear = roda(w);
  const u = (k) => b.readUInt8(o + 28 + k);
  S.fwl = u(0); S.fwr = u(1); S.rw = u(2); S.floor = u(3); S.diff = u(4); S.sidepod = u(5);
  S.drsFault = u(6); S.gearbox = u(8); S.engine = u(9);
  S.mguh = u(10); S.es = u(11); S.ce = u(12); S.ice = u(13); S.mguk = u(14); S.tc = u(15);
}

function history(b) {
  const o = HDR;
  if (b.readUInt8(o) !== playerIdx) return; // o jogo manda um carro por vez
  const numLaps = b.readUInt8(o + 1);
  const bestLapNum = b.readUInt8(o + 3);
  const bestSec = [b.readUInt8(o + 4), b.readUInt8(o + 5), b.readUInt8(o + 6)];
  const lapAt = (n) => o + 7 + (n - 1) * 14; // n = numero da volta (1..)
  const secs = (n) => {
    if (n < 1 || n > 100) return [0, 0, 0];
    const p = lapAt(n);
    return [
      b.readUInt8(p + 6) * 60 + b.readUInt16LE(p + 4) / 1000,
      b.readUInt8(p + 9) * 60 + b.readUInt16LE(p + 7) / 1000,
      b.readUInt8(p + 12) * 60 + b.readUInt16LE(p + 10) / 1000,
    ];
  };
  if (bestLapNum >= 1 && bestLapNum <= 100) S.bestLap = b.readUInt32LE(lapAt(bestLapNum));
  // ultima volta completa = a de antes da volta em andamento
  const last = Math.min(numLaps, 100) - 1;
  if (last >= 1) {
    const s = secs(last);
    // sem tempo de volta completo, a volta ainda nao fechou
    S.secLast = b.readUInt32LE(lapAt(last)) > 0 ? s : [0, 0, 0];
  }
  S.secBest = [secs(bestSec[0])[0], secs(bestSec[1])[1], secs(bestSec[2])[2]];
}

let avisouFmt = false;
function avisarFormato(f) {
  if (avisouFmt) return; avisouFmt = true;
  console.log(`\n  ATENCAO: o jogo esta mandando o formato ${f}. Coloque "Formato UDP: 2025" na telemetria do jogo.\n`);
}

// ================= ENVIO PARA A DASH =================
function snapshot() {
  return JSON.stringify(S, (k, v) => (typeof v === 'number' && !Number.isInteger(v) ? Math.round(v * 1000) / 1000 : v));
}

const udp = dgram.createSocket({ type: 'udp4' });
let lastPacket = 0;
udp.on('message', (msg) => {
  lastPacket = Date.now();
  if (parse(msg)) broadcast(snapshot());
});
udp.on('error', (e) => {
  if (e.code === 'EADDRINUSE') console.error(`\n  A porta ${UDP_PORT} ja esta em uso: feche o SimHub antes (ele tambem escuta o jogo).\n`);
  else console.error('Erro no UDP:', e.message);
  process.exit(1);
});
udp.bind(UDP_PORT);

// sem jogo: avisa a dash 2x por segundo
setInterval(() => {
  if (Date.now() - lastPacket > 1500) { S.ok = false; broadcast(snapshot()); }
}, 500);

// ================= HTTP + WEBSOCKET (sem bibliotecas) =================
const files = {
  '/': ['dash.html', 'text/html; charset=utf-8'],
  '/fonte/saira.woff2': ['fonte/saira.woff2', 'font/woff2'],
};
const server = http.createServer((req, res) => {
  const f = files[req.url.split('?')[0]];
  if (!f) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { 'Content-Type': f[1], 'Cache-Control': 'no-cache' });
  fs.createReadStream(path.join(__dirname, f[0])).pipe(res);
});

const clients = new Set();
server.on('upgrade', (req, sock) => {
  const key = req.headers['sec-websocket-key'];
  if (!key) return sock.destroy();
  const accept = crypto.createHash('sha1').update(key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11').digest('base64');
  sock.write('HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n' +
             `Sec-WebSocket-Accept: ${accept}\r\n\r\n`);
  sock.setNoDelay(true);
  clients.add(sock);
  sock.on('data', (d) => { if ((d[0] & 0x0f) === 0x8) sock.destroy(); }); // pedido de fechar
  sock.on('close', () => clients.delete(sock));
  sock.on('error', () => clients.delete(sock));
  sock.write(frame(snapshot()));
});

function frame(str) {
  const p = Buffer.from(str);
  const n = p.length;
  const h = n < 126 ? Buffer.from([0x81, n])
    : n < 65536 ? Buffer.from([0x81, 126, n >> 8, n & 255])
    : (() => { const x = Buffer.alloc(10); x[0] = 0x81; x[1] = 127; x.writeBigUInt64BE(BigInt(n), 2); return x; })();
  return Buffer.concat([h, p]);
}
function broadcast(str) {
  if (!clients.size) return;
  const f = frame(str);
  for (const c of clients) {
    if (c.writableLength > 64 * 1024) continue; // celular atrasado: pula quadro em vez de acumular
    c.write(f);
  }
}

server.on('error', (e) => {
  if (e.code === 'EADDRINUSE') console.error(`\n  A porta ${HTTP_PORT} ja esta em uso. Feche o SimHub (ou outra dash aberta) e tente de novo.\n`);
  else console.error('Erro no servidor:', e.message);
  process.exit(1);
});
server.listen(HTTP_PORT, () => {
  // IP do PC na rede Wi-Fi/cabo (ignora placas virtuais: WSL, Hyper-V, VirtualBox, VMware, VPN)
  const virt = /vEthernet|WSL|Hyper-V|VirtualBox|VMware|Loopback|Tailscale|ZeroTier|Bluetooth|utun|bridge|docker/i;
  const all = Object.entries(os.networkInterfaces()).flatMap(([name, list]) =>
    (list || []).filter((i) => i.family === 'IPv4' && !i.internal).map((i) => ({ name, ip: i.address })));
  const lan = (a) => /^(192\.168\.|10\.|172\.(1[6-9]|2\d|3[01])\.)/.test(a.ip);
  const good = all.filter((a) => !virt.test(a.name) && lan(a)).concat(all.filter((a) => virt.test(a.name) || !lan(a)));
  const ip = good.length ? good[0].ip : 'IP-DO-PC';
  console.log('\n  F1 25 - Rafa Pro (60 fps) rodando\n');
  console.log(`  No F1 25 (Telemetria):  IP 127.0.0.1   Porta ${UDP_PORT}   Formato 2025   Taxa 60 Hz`);
  console.log(`  No iPhone (Safari):     http://${ip}:${HTTP_PORT}\n`);
  if (good.length > 1) console.log(`  Se nao abrir no iPhone, tente: ${good.slice(1).map((a) => 'http://' + a.ip + ':' + HTTP_PORT).join('  ')}\n`);
  console.log('  Deixe esta janela aberta enquanto joga. Para desligar, feche a janela.\n');
});
