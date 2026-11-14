// Temas de cores da dash. Usado pela dash (aplica na hora) e pelo app de configuracao (lista e amostras).
// Cores genericas: nada de logos nem nomes de equipes.
var BASE_TEMA = {
  fundo: '#050506',    // fundo da tela (aparece entre os blocos)
  bloco: '#000000',    // fundo dos blocos
  caixa: '#101014',    // caixinhas dentro dos blocos
  caixa2: '#18181D',   // trilho das barras, borracha do pneu
  borda: '#2A2A30',    // contornos neutros
  apagado: '#3A3A42',  // texto apagado (DRS desligado, BOX parado)
  rotulo: '#8E8E96',   // titulos pequenos dos blocos
  texto: '#FFFFFF',
  texto2: '#CFCFD6',
  destaque: '#E10600', // cor principal: botao da tela atual e contornos fortes
  forte: '#FFFFFF',    // contorno dos blocos de tempo / pneus
  frio: '#00E5FF',     // gap, pressao, clima
  cinza: '#5A5A62',
  roxo: '#B14CFF',     // melhor volta / setores
  laranja: '#FF8C00',
  verde: '#00E676',
  verde2: '#00C853',
  amarelo: '#FFD600',
  amarelo2: '#FFC400',
  vermelho: '#FF1744',
  vermelho2: '#FF3B30',
  azul: '#2979FF',
  ciano: '#4FC3F7',
  duro: '#F2F2F2',     // pneu duro
  tinta: '#000000',    // texto em cima de etiqueta colorida
  ledoff: '#19191E',
  ledshift: '#4FC3F7', // luzes piscando na hora de trocar
};

var TEMAS = {
  classico: { nome: 'Clássico', desc: 'Preto e vermelho', cores: {} },
  neon: { nome: 'Neon', desc: 'Preto com verde neon', cores: {
    fundo: '#010603', destaque: '#00F07A', forte: '#B8FFD9', frio: '#00F0D0', borda: '#163323', apagado: '#24432F',
    rotulo: '#6FA88A', caixa: '#06120B', caixa2: '#0C1F14', ledoff: '#0C1F14' } },
  azul: { nome: 'Azul noturno', desc: 'Azul-marinho e azul', cores: {
    fundo: '#030915', bloco: '#050C1A', caixa: '#0A1428', caixa2: '#101D36', borda: '#1C2C4A', apagado: '#2C3E60',
    rotulo: '#7F93B8', texto2: '#C9D5EC', destaque: '#2F7BFF', forte: '#DCE6FF', ledoff: '#101D36' } },
  claro: { nome: 'Claro', desc: 'Fundo claro para dia', cores: {
    fundo: '#C9CED6', bloco: '#FFFFFF', caixa: '#EEF1F5', caixa2: '#E1E5EB', borda: '#C3C9D2', apagado: '#B3B9C3',
    rotulo: '#5C6370', texto: '#0E1116', texto2: '#2B313B', destaque: '#D10A00', forte: '#0E1116', frio: '#0089A0',
    cinza: '#8A909A', roxo: '#8424D9', laranja: '#D96500', verde: '#00A651', verde2: '#00A651', amarelo: '#C49400',
    amarelo2: '#C49400', vermelho: '#E0002B', vermelho2: '#E0002B', azul: '#1E5FD8', ciano: '#0089A0',
    duro: '#6B7280', ledoff: '#E1E5EB', ledshift: '#1E5FD8' } },
  laranja: { nome: 'Laranja', desc: 'Preto e laranja', cores: {
    fundo: '#070401', destaque: '#FF7A00', forte: '#FFE3C4', borda: '#33240F', apagado: '#4A3517', rotulo: '#A88E70',
    caixa: '#120B04', caixa2: '#1E1308', ledoff: '#1E1308' } },
  prata: { nome: 'Prata', desc: 'Grafite, prata e verde-água', cores: {
    fundo: '#0B0C0E', bloco: '#111316', caixa: '#191C20', caixa2: '#22262B', borda: '#3A3F46', apagado: '#4B515A',
    rotulo: '#9AA1AB', destaque: '#C7CDD6', forte: '#E6EAF0', frio: '#00D2BE', ledoff: '#22262B' } },
  verde: { nome: 'Verde inglês', desc: 'Verde-escuro e creme', cores: {
    fundo: '#020805', bloco: '#03100A', caixa: '#082016', caixa2: '#0D2B1E', borda: '#1B4232', apagado: '#28563F',
    rotulo: '#7FA592', texto2: '#D9E6DD', destaque: '#1FAA6C', forte: '#F1EBD8', ledoff: '#0D2B1E' } },
  vinho: { nome: 'Vinho', desc: 'Preto e vinho', cores: {
    fundo: '#080204', caixa: '#14070C', caixa2: '#200C14', borda: '#3A1424', apagado: '#4F1D31', rotulo: '#A47F8E',
    destaque: '#C2185B', forte: '#FFE0EA', ledoff: '#200C14' } },
};

// Estilos das luzes de RPM: [primeiras 5, do meio, ultimas 5] (nomes de cores do tema)
var LEDS = {
  classico: { nome: 'Verde, vermelho e roxo', cores: ['verde', 'vermelho', 'roxo'] },
  f1: { nome: 'Verde, vermelho e azul', cores: ['verde', 'vermelho', 'azul'] },
  semaforo: { nome: 'Verde, amarelo e vermelho', cores: ['verde', 'amarelo', 'vermelho'] },
  destaque: { nome: 'Tudo na cor de destaque', cores: ['destaque', 'destaque', 'destaque'] },
};

function coresDoTema(id, destaque) {
  var t = TEMAS[id] || TEMAS.classico, c = {}, k;
  for (k in BASE_TEMA) c[k] = BASE_TEMA[k];
  for (k in t.cores) c[k] = t.cores[k];
  if (destaque) c.destaque = destaque;
  return c;
}
