// Simulador de telemetria do F1 25, para testar a dash sem o jogo.
// Uso: node teste/simulador.js [cenario] [2025|2026]
// Cenarios: normal, drs, overtake (2026), amarela, vermelha, azul, verde, sc, vsc, formacao, box, bateria, dano, botao
// "botao" aperta o R3 a cada 2 s (troca de tela se o R3 estiver configurado no app).
const dgram = require('dgram');
const sock = dgram.createSocket('udp4');
const cen = process.argv[2] || 'normal';
const FMT = Number(process.argv[3] || (cen === 'overtake' ? 2026 : 2025));
const L = FMT === 2026
  ? { carros: 24, tel: 59, pressao: 39, status: 59, ersUsado: 54, sessao: 926, voltas: 1399, telPkt: 1448, staPkt: 1445, danoPkt: 1133 }
  : { carros: 22, tel: 60, pressao: 40, status: 55, ersUsado: 50, sessao: 753, voltas: 1285, telPkt: 1352, staPkt: 1239, danoPkt: 1041 };
const P = 3; // carro do jogador (diferente de 0 para pegar erro de indice)
let frameN = 0;
const t0 = Date.now();

function header(id, size) {
  const b = Buffer.alloc(size);
  b.writeUInt16LE(FMT, 0); b.writeUInt8(25, 2); b.writeUInt8(1, 3); b.writeUInt8(0, 4); b.writeUInt8(1, 5);
  b.writeUInt8(id, 6); b.writeBigUInt64LE(BigInt(1000 + FMT), 7); b.writeFloatLE((Date.now() - t0) / 1000, 15);
  b.writeUInt32LE(frameN, 19); b.writeUInt32LE(frameN, 23); b.writeUInt8(P, 27); b.writeUInt8(255, 28);
  return b;
}
const send = (b) => sock.send(b, 20777, '127.0.0.1');

function telemetry(t) {
  const b = header(6, L.telPkt), o = 29 + P * L.tel;
  const ph = (t % 6000) / 6000;
  const gear = Math.min(8, 1 + Math.floor(ph * 8));
  const rev = cen === 'normal' ? Math.floor(((ph * 8) % 1) * 105) : 60;
  b.writeUInt16LE(Math.round(120 + ph * 200), o);
  b.writeInt8(gear, o + 15); b.writeUInt16LE(11000, o + 16);
  b.writeUInt8(cen === 'drs' && ph > 0.5 ? 1 : 0, o + 18); b.writeUInt8(Math.min(100, rev), o + 19);
  [410, 280, 1040, 860].forEach((v, i) => b.writeUInt16LE(v, o + 22 + i * 2)); // TE TD DE DD
  [92, 76, 98, 108].forEach((v, i) => b.writeUInt8(v, o + 30 + i));
  [95, 80, 101, 112].forEach((v, i) => b.writeUInt8(v, o + 34 + i));
  b.writeUInt8(110, o + 38); // temperatura do motor (1o byte)
  [20.4, 20.5, 22.6, 22.8].forEach((v, i) => b.writeFloatLE(v, o + L.pressao + i * 4));
  return b;
}
function lap(t) {
  const b = header(2, L.voltas), o = 29 + P * 57;
  const lapMs = (t % 90000);
  b.writeUInt32LE(91904, o); b.writeUInt32LE(lapMs, o + 4);
  b.writeUInt16LE(482, o + 14); b.writeUInt8(1, o + 16);
  b.writeFloatLE(lapMs / 90000 * 5000, o + 20);
  b.writeUInt8(4, o + 32); b.writeUInt8(23 + Math.floor(t / 90000), o + 33);
  b.writeUInt8(cen === 'box' ? 1 : 0, o + 34); b.writeUInt8(0, o + 35); b.writeUInt8(1, o + 36);
  b.writeUInt8(cen === 'box' ? 1 : 0, o + 37); b.writeUInt8(cen === 'box' ? 5 : 0, o + 38);
  b.writeUInt8(1, o + 39); b.writeUInt8(1, o + 40);
  b.writeUInt16LE(cen === 'box' ? 2500 : 0, o + 47);
  return b;
}
function status(t) {
  const b = header(7, L.staPkt), o = 29 + P * L.status;
  b.writeUInt8(56, o + 3); b.writeUInt8(0, o + 4);
  const ph = (t % 6000) / 6000;
  b.writeUInt8(cen === 'drs' && ph > 0.3 ? 1 : 0, o + 22);
  b.writeUInt16LE(cen === 'drs' && ph <= 0.3 ? Math.round(300 - ph * 900) : 0, o + 23);
  b.writeUInt8(17, o + 26); b.writeUInt8(18, o + 27);
  b.writeInt8({ amarela: 3, azul: 2, verde: 1 }[cen] || 0, o + 28);
  b.writeFloatLE(cen === 'bateria' ? 0.06 * 4e6 : 0.68 * 4e6, o + 37); b.writeUInt8(1, o + 41);
  b.writeFloatLE(0.41 * 4e6, o + L.ersUsado);
  return b;
}
function telemetry2(t) { // so 2026
  const b = header(16, 269), o = 29 + P * 10;
  const ph = (t % 6000) / 6000;
  b.writeUInt8(ph > 0.6 ? 1 : 0, o);                         // modo reta
  b.writeUInt8(ph > 0.5 ? 1 : 0, o + 1);
  b.writeUInt16LE(ph <= 0.5 ? Math.round(200 - ph * 380) : 0, o + 2);
  b.writeUInt8(ph > 0.3 ? 1 : 0, o + 4);                     // overtake liberado
  b.writeUInt8(ph > 0.7 ? 1 : 0, o + 5);                     // overtake ligado
  b.writeUInt16LE(ph <= 0.3 ? Math.round(150 - ph * 480) : 0, o + 6);
  b.writeUInt8(1, o + 8);                                    // regras 2026
  return b;
}
function damage() {
  const b = header(10, L.danoPkt), o = 29 + P * 46;
  const d = cen === 'dano';
  [77, 41, 58, 49].forEach((v, i) => b.writeFloatLE(d ? v : [24, 56, 31, 36][i], o + i * 4)); // TE TD DE DD
  const v = d ? [72, 35, 18, 61, 44, 9, 0, 0, 6, 22, 22, 30, 12, 38, 65, 41]
              : [12, 27, 0, 4, 0, 0, 0, 0, 0, 18, 10, 10, 10, 10, 10, 10];
  v.forEach((x, i) => b.writeUInt8(x, o + 28 + i));
  return b;
}
function session() {
  const b = header(1, L.sessao), o = 29;
  b.writeUInt8(1, o); b.writeInt8(38, o + 1); b.writeInt8(24, o + 2); b.writeUInt8(57, o + 3); b.writeUInt8(15, o + 6);
  b.writeUInt8({ sc: 1, vsc: 2, formacao: 3 }[cen] || 0, o + 124);
  const fc = [[0, 1, 10], [5, 1, 10], [15, 2, 30], [30, 3, 60]];
  b.writeUInt8(fc.length, o + 126);
  fc.forEach(([off, w, r], i) => { const s = o + 127 + i * 8; b.writeUInt8(15, s); b.writeUInt8(off, s + 1); b.writeUInt8(w, s + 2); b.writeUInt8(r, s + 7); });
  b.writeUInt8(24, o + 653); b.writeUInt8(29, o + 654); b.writeUInt8(8, o + 655);
  return b;
}
function history() {
  const b = header(11, 1460), o = 29;
  b.writeUInt8(P, o); b.writeUInt8(23, o + 1); b.writeUInt8(1, o + 2); b.writeUInt8(5, o + 3);
  b.writeUInt8(5, o + 4); b.writeUInt8(5, o + 5); b.writeUInt8(5, o + 6);
  for (let n = 1; n <= 22; n++) {
    const p = o + 7 + (n - 1) * 14;
    b.writeUInt32LE(n === 5 ? 91904 : 93000, p);
    const s = n === 5 ? 28105 : 28412;
    b.writeUInt16LE(s, p + 4); b.writeUInt16LE(s, p + 7); b.writeUInt16LE(s, p + 10);
  }
  return b;
}
function event(code, u32) { const b = header(3, 45); b.write(code, 29, 'ascii'); if (u32 != null) b.writeUInt32LE(u32, 33); return b; }

setInterval(() => {
  const t = Date.now() - t0; frameN++;
  send(lap(t)); send(status(t)); send(telemetry(t));
  if (FMT === 2026) send(telemetry2(t));
  if (frameN % 6 === 0) send(damage());
  if (frameN % 30 === 0) { send(session()); send(history()); }
  if (cen === 'vermelha' && frameN % 60 === 0) send(event('RDFL'));
  if (cen === 'botao' && frameN % 120 === 0) send(event('BUTN', 0x4000));
  if (cen === 'botao' && frameN % 120 === 6) send(event('BUTN', 0));
}, 1000 / 60);
console.log(`simulando "${cen}" no formato ${FMT}`);
