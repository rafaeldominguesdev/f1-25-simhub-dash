// F1 25 - Rafa Pro (versao propria, 60 fps)
// Le a telemetria UDP do F1 25 (formatos 2025 e 2026, detecta sozinho) e manda para a dash por WebSocket.
// Uso normal: icone "F1 25 Rafa Pro" (exe). Para ver erros: Iniciar.bat. Sem dependencias.
// Roda no mesmo PC do jogo; no F1 25 o IP da telemetria fica 127.0.0.1.

const dgram = require('dgram');
const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');
const { spawn } = require('child_process');
const MODO_APP = process.argv.includes('--app'); // aberto pelo icone: mostra a janela do app

const UDP_PORT = 20777;
const HTTP_PORT = 8888;
const HDR = 29;
const PASTA = __dirname;

// no modo app nao tem janela preta: erros vao para erro.log
if (MODO_APP) {
  const log = (e) => { try { fs.appendFileSync(path.join(PASTA, 'erro.log'), `[${new Date().toLocaleString('pt-BR')}] ${e && e.stack || e}\n`); } catch (x) {} };
  process.on('uncaughtException', (e) => { log(e); process.exit(1); });
}

// ================= CONFIGURACAO (config.json) =================
const CONFIG_PATH = path.join(PASTA, 'config.json');
const PADRAO = {
  tema: 'classico',
  destaque: '',                 // cor de destaque propria ('' = a do tema)
  telas: { corrida: true, carro: true, info: true },
  telaInicial: 0,
  blocos: {
    delta: true, gap: true, drs: true, box: true, ers: true, pneus: true, tempos: true, danos: true,
    motor: true, freios: true, pressao: true,
    restantes: true, parada: true, setores: true, clima: true,
  },
  controle: { proxima: 0x4000, anterior: 0 }, // R3 = proxima tela
  avisos: { duracao: 4, amarela: true, azul: true, verde: true, sc: true, vsc: true, vermelha: true, formacao: true, som: false },
  unidades: { velocidade: 'kmh', temperatura: 'c' },
  leds: 'classico',
  drsDistancia: true,
};
// junta o que veio com o padrao: so aceita chaves conhecidas e do mesmo tipo
function juntar(padrao, veio) {
  if (typeof padrao !== 'object' || padrao === null) return typeof veio === typeof padrao ? veio : padrao;
  const out = {};
  for (const k of Object.keys(padrao)) out[k] = (veio && k in veio) ? juntar(padrao[k], veio[k]) : juntar(padrao[k], undefined);
  return out;
}
function limpar(c) {
  c.telaInicial = Math.max(0, Math.min(2, Math.round(c.telaInicial) || 0));
  c.avisos.duracao = Math.max(1, Math.min(15, Math.round(c.avisos.duracao) || 4));
  c.controle.proxima = c.controle.proxima >>> 0; c.controle.anterior = c.controle.anterior >>> 0;
  if (!['kmh', 'mph'].includes(c.unidades.velocidade)) c.unidades.velocidade = 'kmh';
  if (!['c', 'f'].includes(c.unidades.temperatura)) c.unidades.temperatura = 'c';
  if (!/^#[0-9a-fA-F]{6}$/.test(c.destaque)) c.destaque = '';
  if (!c.telas.corrida && !c.telas.carro && !c.telas.info) c.telas.corrida = true; // pelo menos uma tela
  return c;
}
let CFG;
try { CFG = limpar(juntar(PADRAO, JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8')))); }
catch (e) { CFG = limpar(juntar(PADRAO, {})); }
function salvarConfig() { try { fs.writeFileSync(CONFIG_PATH, JSON.stringify(CFG, null, 2)); } catch (e) {} }
salvarConfig();

// ================= FORMATOS =================
// O pacote de temporada 2026 muda: 24 carros, temperatura do motor com 1 byte (mexe na pressao dos pneus)
// e um campo novo no Car Status (mexe no ERS usado na volta). Pacote 16 novo: aero ativa e overtake.
const FORMATOS = {
  2025: { carros: 22, tel: 60, pressao: 40, status: 55, ersUsado: 50, dano: 46, volta: 57 },
  2026: { carros: 24, tel: 59, pressao: 39, status: 59, ersUsado: 54, dano: 46, volta: 57 },
};

// ================= ESTADO =================
let S, sessionUID = null, playerIdx = 0, redLap = 0, F = FORMATOS[2025];
function novoEstado() {
  return {
    ok: false, fmt: 0,
    // corrida
    pos: 0, lap: 0, totalLaps: 0, gap: null, delta: null,
    curLap: 0, lastLap: 0, bestLap: 0, invalid: false, sector: 0,
    warnings: 0, penalties: 0, dt: 0, sg: 0,
    pitStatus: 0, stops: 0, laneMs: 0, stopMs: 0,
    // telemetria
    speed: 0, gear: 0, rpm: 0, revPct: 0, drs: 0,
    brakeT: [0, 0, 0, 0], tyreSurf: [0, 0, 0, 0], tyreInner: [0, 0, 0, 0], press: [0, 0, 0, 0],
    // status
    bias: 0, limiter: 0, drsAllowed: 0, drsDist: 0, compound: 0, tyreAge: 0, fia: 0,
    ers: 0, ersMode: 0, ersUsed: 0,
    // 2026: aero ativa e overtake (pacote 16)
    reg26: 0, aeroMode: 0, aeroAvail: 0, aeroDist: 0, otAvail: 0, otActive: 0, otDist: 0,
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
let ultimoFormato = 0;
function parse(b) {
  if (b.length < HDR) return;
  const fmt = b.readUInt16LE(0);
  ultimoFormato = fmt;
  if (!FORMATOS[fmt]) { avisarFormato(fmt); return; }
  F = FORMATOS[fmt];
  const id = b.readUInt8(6);
  const uid = b.readBigUInt64LE(7).toString();
  playerIdx = b.readUInt8(27);
  if (playerIdx >= F.carros) return;
  if (uid !== sessionUID) { // sessao nova: zera tudo
    sessionUID = uid; S = novoEstado(); dl = { lapNum: -1, d: [], t: [], invalid: false, ref: null, refMs: 0 };
  }
  S.ok = true; S.fmt = fmt;
  try {
    switch (id) {
      case 1: session(b); break;
      case 2: lapData(b); break;
      case 3: evento(b); break;
      case 6: telemetry(b); return true; // 1x por quadro do jogo: hora de mandar
      case 7: status(b); break;
      case 10: damage(b); break;
      case 11: history(b); break;
      case 16: telemetry2(b); break;
    }
  } catch (e) { /* pacote cortado: ignora */ }
}

function session(b) {
  const o = HDR; // o comeco do pacote de sessao e igual em 2025 e 2026
  S.weather = b.readUInt8(o);
  S.track = b.readInt8(o + 1);
  S.air = b.readInt8(o + 2);
  S.totalLaps = b.readUInt8(o + 3);
  S.sessionType = b.readUInt8(o + 6);
  S.sc = b.readUInt8(o + 124);
  const n = b.readUInt8(o + 126);
  const fc = [null, null, null], want = [5, 15, 30];
  S.rainNow = null;
  for (let i = 0; i < n && i < 64; i++) {
    const s = o + 127 + i * 8;
    if (b.readUInt8(s) !== S.sessionType) continue;
    const off = b.readUInt8(s + 1);
    if (off === 0 && S.rainNow === null) S.rainNow = b.readUInt8(s + 7);
    const k = want.indexOf(off);
    if (k >= 0 && !fc[k]) fc[k] = { w: b.readUInt8(s + 2), rain: b.readUInt8(s + 7) };
  }
  S.forecast = fc;
  S.pitIdeal = b.readUInt8(o + 653);
  S.pitLatest = b.readUInt8(o + 654);
  S.rejoin = b.readUInt8(o + 655);
}

function lapData(b) {
  const o = HDR + playerIdx * F.volta;
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

// ---- botoes do controle (evento BUTN): troca de tela na hora que aperta ----
let botoes = 0, ultimoBotao = { bit: 0, em: 0 };
function evento(b) {
  const code = b.toString('ascii', HDR, HDR + 4);
  if (code === 'RDFL') { S.red = true; redLap = S.lap; }
  // acaba na relargada (luzes), em sessao nova/fim, ou quando voce fecha uma volta depois da vermelha
  else if (['STLG', 'LGOT', 'SSTA', 'SEND'].includes(code)) S.red = false;
  else if (code === 'BUTN') {
    const m = b.readUInt32LE(HDR + 4);
    const subiu = (m & ~botoes) >>> 0; // so os que acabaram de ser apertados
    botoes = m;
    if (!subiu) return;
    ultimoBotao = { bit: (subiu & -subiu) >>> 0, em: Date.now() };
    if (CFG.controle.proxima && (subiu & CFG.controle.proxima)) enviar({ tipo: 'tela', acao: 'proxima' });
    else if (CFG.controle.anterior && (subiu & CFG.controle.anterior)) enviar({ tipo: 'tela', acao: 'anterior' });
  }
}

function telemetry(b) {
  const o = HDR + playerIdx * F.tel;
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
    pr.push(b.readFloatLE(o + F.pressao + i * 4));
  }
  S.brakeT = roda(bt); S.tyreSurf = roda(ts); S.tyreInner = roda(ti); S.press = roda(pr);
}

function status(b) {
  const o = HDR + playerIdx * F.status;
  S.bias = b.readUInt8(o + 3);
  S.limiter = b.readUInt8(o + 4);
  S.drsAllowed = b.readUInt8(o + 22);
  S.drsDist = b.readUInt16LE(o + 23);
  S.compound = b.readUInt8(o + 26);
  S.tyreAge = b.readUInt8(o + 27);
  S.fia = b.readInt8(o + 28);
  S.ers = b.readFloatLE(o + 37) / 4e6 * 100;
  S.ersMode = b.readUInt8(o + 41);
  S.ersUsed = b.readFloatLE(o + F.ersUsado) / 4e6 * 100;
}

function telemetry2(b) { // so no formato 2026
  const o = HDR + playerIdx * 10;
  S.aeroMode = b.readUInt8(o);
  S.aeroAvail = b.readUInt8(o + 1);
  S.aeroDist = b.readUInt16LE(o + 2);
  S.otAvail = b.readUInt8(o + 4);
  S.otActive = b.readUInt8(o + 5);
  S.otDist = b.readUInt16LE(o + 6);
  S.reg26 = b.readUInt8(o + 8);
}

function damage(b) {
  const o = HDR + playerIdx * F.dano;
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
  if (last >= 1) S.secLast = b.readUInt32LE(lapAt(last)) > 0 ? secs(last) : [0, 0, 0];
  S.secBest = [secs(bestSec[0])[0], secs(bestSec[1])[1], secs(bestSec[2])[2]];
}

let avisouFmt = false, pacotesSeg = 0, contPacotes = 0, meuIp = 'IP-DO-PC', meusIps = [];
setInterval(() => { pacotesSeg = contPacotes; contPacotes = 0; }, 1000);
function avisarFormato(f) {
  if (avisouFmt) return; avisouFmt = true;
  console.log(`\n  ATENCAO: o jogo esta mandando o formato ${f}. Este app le 2025 e 2026.\n`);
}

// ================= ENVIO PARA A DASH =================
function snapshot() {
  return JSON.stringify(S, (k, v) => (typeof v === 'number' && !Number.isInteger(v) ? Math.round(v * 1000) / 1000 : v));
}

const udp = dgram.createSocket({ type: 'udp4' });
let lastPacket = 0;
udp.on('message', (msg) => {
  lastPacket = Date.now(); contPacotes++;
  if (parse(msg)) broadcast(snapshot());
});
udp.on('error', (e) => {
  if (e.code === 'EADDRINUSE' && MODO_APP) {
    // porta ocupada: ou o app ja esta aberto (mostra a janela dele) ou e o SimHub (avisa)
    http.get(`http://localhost:${HTTP_PORT}/status`, (r) => {
      let t = ''; r.on('data', (d) => (t += d)); r.on('end', () => {
        if (t.includes('"jogo"')) abrirJanela(); else avisoWindows();
        setTimeout(() => process.exit(0), 500);
      });
    }).on('error', () => { avisoWindows(); setTimeout(() => process.exit(0), 500); });
    return;
  }
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
  '/painel': ['painel/painel.html', 'text/html; charset=utf-8'],
  '/painel/qrcode.js': ['painel/qrcode.js', 'text/javascript; charset=utf-8'],
  '/temas.js': ['temas.js', 'text/javascript; charset=utf-8'],
  '/fonte/saira.woff2': ['fonte/saira.woff2', 'font/woff2'],
  '/icone.ico': ['icone.ico', 'image/x-icon'],
};
const ehLocal = (req) => /^(::1|127\.0\.0\.1|::ffff:127\.0\.0\.1)$/.test(req.socket.remoteAddress || '');
// pedidos de mudanca: so do proprio PC e so vindos das paginas do app
const origemOk = (req) => !req.headers.origin || /^http:\/\/(localhost|127\.0\.0\.1):8888$/.test(req.headers.origin);
function json(res, code, obj) {
  res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-cache' });
  res.end(JSON.stringify(obj));
}
function lerCorpo(req, cb) {
  let t = '';
  req.on('data', (d) => { t += d; if (t.length > 65536) req.destroy(); });
  req.on('end', () => { try { cb(JSON.parse(t || '{}')); } catch (e) { cb(null); } });
}

const server = http.createServer((req, res) => {
  const url = req.url.split('?')[0];
  if (url === '/status') {
    return json(res, 200, {
      jogo: Date.now() - lastPacket < 1500, formato: ultimoFormato, formatoOk: !ultimoFormato || !!FORMATOS[ultimoFormato],
      regras2026: !!S.reg26, porSegundo: pacotesSeg, aparelhos: [...clients].filter((c) => !c.previa).length,
      endereco: `http://${meuIp}:${HTTP_PORT}`, enderecos: meusIps.map((ip) => `http://${ip}:${HTTP_PORT}`),
      botoes, ultimoBotao: { bit: ultimoBotao.bit, ha: ultimoBotao.em ? Date.now() - ultimoBotao.em : null },
    });
  }
  if (url === '/config' && req.method === 'GET') return json(res, 200, { config: CFG, padrao: PADRAO });
  if (url === '/config' && req.method === 'POST') {
    if (!ehLocal(req) || !origemOk(req)) return json(res, 403, { erro: 'so no PC' });
    return lerCorpo(req, (c) => {
      if (!c) return json(res, 400, { erro: 'config invalida' });
      CFG = limpar(juntar(PADRAO, c));
      salvarConfig();
      enviar({ tipo: 'config', config: CFG });
      json(res, 200, { config: CFG });
    });
  }
  if (url === '/tela' && req.method === 'POST' && ehLocal(req) && origemOk(req)) { // botao "testar" do app
    enviar({ tipo: 'tela', acao: 'proxima' });
    return json(res, 200, { ok: true });
  }
  if (url === '/desligar' && req.method === 'POST' && ehLocal(req) && origemOk(req)) {
    res.writeHead(200); res.end('ok');
    return setTimeout(() => process.exit(0), 300);
  }
  const f = files[url];
  if (!f || req.method !== 'GET') { res.writeHead(404); return res.end(); }
  res.writeHead(200, { 'Content-Type': f[1], 'Cache-Control': 'no-cache' });
  fs.createReadStream(path.join(PASTA, f[0])).pipe(res);
});

const clients = new Set();
server.on('upgrade', (req, sock) => {
  const key = req.headers['sec-websocket-key'];
  if (!key) return sock.destroy();
  const accept = crypto.createHash('sha1').update(key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11').digest('base64');
  sock.write('HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n' +
             `Sec-WebSocket-Accept: ${accept}\r\n\r\n`);
  sock.setNoDelay(true);
  sock.previa = /[?&]previa=1/.test(req.url); // miniatura do app nao conta como aparelho
  clients.add(sock);
  sock.on('data', (d) => { if ((d[0] & 0x0f) === 0x8) sock.destroy(); }); // pedido de fechar
  sock.on('close', () => clients.delete(sock));
  sock.on('error', () => clients.delete(sock));
  sock.write(frame(JSON.stringify({ tipo: 'config', config: CFG })));
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
function enviar(obj) { // mensagens que nao podem ser puladas (config, troca de tela)
  const f = frame(JSON.stringify(obj));
  for (const c of clients) c.write(f);
}

function avisoWindows() {
  if (process.platform !== 'win32') return;
  const msg = 'Feche o SimHub antes de abrir o F1 25 - Rafa Pro. Os dois usam a mesma porta do jogo.';
  spawn('powershell', ['-NoProfile', '-Command', `Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('${msg}', 'F1 25 - Rafa Pro') | Out-Null`],
    { detached: true, stdio: 'ignore', windowsHide: true }).unref();
}

// Abre o app (painel) como janela de aplicativo (Edge sem barra de endereco)
function abrirJanela() {
  if (process.platform !== 'win32') return;
  const edges = ['C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe', 'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe'];
  const edge = edges.find((p) => fs.existsSync(p));
  const perfil = path.join(os.tmpdir(), 'f125-rafa-pro-app');
  const args = [`--app=http://localhost:${HTTP_PORT}/painel`, '--window-size=1120,780', `--user-data-dir=${perfil}`, '--no-first-run'];
  if (edge) spawn(edge, args, { detached: true, stdio: 'ignore' }).unref();
  else spawn('cmd', ['/c', 'start', '', `http://localhost:${HTTP_PORT}/painel`], { detached: true, stdio: 'ignore' }).unref();
}

server.on('error', (e) => {
  // ja tem um app aberto? so mostra a janela dele de novo
  if (e.code === 'EADDRINUSE' && MODO_APP) { abrirJanela(); setTimeout(() => process.exit(0), 500); return; }
  if (e.code === 'EADDRINUSE') console.error(`\n  A porta ${HTTP_PORT} ja esta em uso. Feche o SimHub (ou o app ja aberto) e tente de novo.\n`);
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
  meusIps = good.map((a) => a.ip);
  meuIp = meusIps[0] || 'IP-DO-PC';
  if (MODO_APP) abrirJanela();
  console.log('\n  F1 25 - Rafa Pro (60 fps) rodando\n');
  console.log(`  No F1 25 (Telemetria):  IP 127.0.0.1   Porta ${UDP_PORT}   Formato 2025 ou 2026   Taxa 60 Hz`);
  console.log(`  No iPhone (Safari):     http://${meuIp}:${HTTP_PORT}`);
  console.log(`  Configuracoes:          http://localhost:${HTTP_PORT}/painel\n`);
  if (good.length > 1) console.log(`  Se nao abrir no iPhone, tente: ${good.slice(1).map((a) => 'http://' + a.ip + ':' + HTTP_PORT).join('  ')}\n`);
  console.log('  Deixe esta janela aberta enquanto joga. Para desligar, feche a janela.\n');
});
