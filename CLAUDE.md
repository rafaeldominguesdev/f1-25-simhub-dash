# Contexto do projeto (para o Claude)

- **Responder sempre em português do Brasil**, linguagem simples e informal. O usuário escreve rápido e com erros de digitação.
- Projeto: dashboard de **F1 25** para **iPhone 15** (base 1560x720, proporção 19.5:9), com 3 telas: **Corrida**, **Carro** e **Info**, mais um menu de 3 botões no canto superior esquerdo.

## Versão SimHub (pronta, nesta pasta)
- `gerar_dash.ps1` gera a dash e instala em `C:\Program Files (x86)\SimHub\DashTemplates\F1 25 - Rafa Pro` (no PC Windows).
- `ferramentas\gerar_carro.ps1` gera as imagens da pasta `carro/` a partir de `carro.html`, `clima.html` e `menu.html` (Edge headless; janelas menores que ~160 px travam o Edge).
- `ferramentas\render_preview.ps1` gera as prévias da pasta `imagens/`.
- O SimHub do usuário é **grátis**: limita as dashes a ~10–15 fps e **só alimenta uma tela por vez** (abrir a dash no PC ou numa aba de teste deixa o iPhone preto). Nunca abrir a dash no navegador para testar enquanto ele usa o iPhone.
- O usuário **não quer pagar a licença** do SimHub. Não burlar a licença.

## Versão própria a 60 fps (sem SimHub) — pasta `versao-60fps/`
App para o PC Windows do jogo (no jogo, IP da telemetria `127.0.0.1`, porta 20777; SimHub fechado, mesma porta). O Node.js já está instalado no PC do usuário. O usuário quer um app que ele abre sozinho, sem o Claude.

### Estrutura (feita em 14/11/2026, a partir do `INSTRUCOES.md`)
- `F1 25 Rafa Pro.exe` (não vai pro git): launcher compilado **no PC** por `Compilar exe.bat` (csc.exe do .NET Framework) a partir de `launcher/Launcher.cs`. Acha o node (instala pelo winget se faltar) e roda `node app\servidor.js --app` escondido. `Criar atalho.bat` compila se faltar e cria o ícone na área de trabalho. `Iniciar.bat` = modo com janela preta (erros); no modo app, erros vão para `app\erro.log`.
- `app/servidor.js` (Node, sem dependências): lê o UDP nos **formatos 2025 e 2026** (detecta pelo cabeçalho; tabela `FORMATOS`), manda tudo por WebSocket. Rotas: `/` dash, `/painel` app de configuração, `/temas.js`, `GET /status`, `GET|POST /config`, `POST /tela`, `POST /desligar` (POST só do próprio PC e de origem localhost:8888). Com `--app` abre o painel numa janela do Edge `--app`.
- `app/config.json` (não vai pro git): escolhas do usuário; criado com o padrão (`PADRAO` no servidor). Mudou no app → servidor manda `{tipo:'config'}` e a dash aplica na hora.
- `app/temas.js`: temas (Clássico, Neon, Azul noturno, Claro, Laranja, Prata, Verde inglês, Vinho) e estilos dos LEDs. A dash usa só `var(--nome)` do tema; não escrever cor fixa nova no `dash.html` (exceto cores de bandeira, estados do BOX e o neon do carro, que têm significado).
- `app/painel/painel.html`: app de configuração com **visual de F1** (pedido do usuário: "forte, estilo Fórmula 1", a versão escura genérica foi reprovada): letra Saira itálica pesada em caixa alta (`fonte/saira-italico.woff2`), blocos em paralelogramo, zebra vermelha e branca, menu como torre de posições (01, 02…; ativo em branco), números de cronometragem com faixa de cor de setor, fundo de fibra de carbono. Abas: Início (QR code), **Dash** (a dash ao vivo dentro do app, com tela cheia), Aparência, Telas e blocos, Controle, Avisos, Unidades, Ajuda. **Nada abre janela ou aba nova** (pedido do usuário): a dash fica na aba Dash; abrir o ícone com o app já ligado traz a janela existente para a frente (`focarOuAbrir`, AppActivate pelo título "Rafa Pro"). A prévia é a dash em `/?previa=1` (dados de exemplo sem o jogo); a aba Dash usa `/?pc=1`; nenhuma das duas conta como iPhone. QR com `painel/qrcode.js` (Kazuhiko Arase, MIT).
- `teste/simulador.js`: pacotes falsos nos dois formatos (`node teste/simulador.js <cenario> <2025|2026>`; cenários no topo do arquivo).

### Formato 2026 (pacote de temporada; spec oficial "Data Output from F1 25 2026 Season Pack")
- 24 carros; temperatura do motor virou 1 byte (pressão dos pneus em +39 em vez de +40; CarTelemetry 59 bytes); Car Status ganhou `m_ersHarvestedLimitPerLap` (ERS usado em +54 em vez de +50; 59 bytes); Lap Data, Dano, Histórico e o começo da Sessão iguais.
- Pacote novo **16 (Car Telemetry 2)**, 10 bytes por carro: aero ativa (modo reta/curva, liberada, distância), overtake (liberado, ligado, distância) e `m_2026Regulations`. Carro 2026 não tem DRS: o bloco do DRS mostra OVERTAKE e a linha de baixo a aero ativa.
- Botões: evento `BUTN` (uint32 em +33). Troca de tela na borda de subida; padrão R3 (0x4000); UDP Action 1–12 = 0x00100000…0x80000000.

### Regras da dash
- Repetir o visual e as funções da versão SimHub: as 3 telas, o carro neon com as peças mudando de cor pelo dano, os avisos de bandeira (vermelha/amarela em tela cheia; SC, VSC, azul, verde e formação roxa num painel grande; sem quadriculada e sem preta), ERS amarelo sem piscar, DRS que acende (sem piscar), marcha animada (cresce com toque verde ao subir e encolhe com toque laranja ao reduzir; vermelha na hora de trocar), luzes de RPM em retângulos, pneus com 3 faixas de temperatura, sem combustível, contornos finos.
- O jogo não manda temperatura fora/meio/dentro do pneu: as 3 faixas são superfície / média / carcaça.
- Os desenhos (`carro/`, `ferramentas/*.html`) são originais e podem ser reaproveitados. **Não usar arte da DeltaSimLabs** (licença proíbe) nem logos/nomes da F1 e das equipes.

### Falta
- Testar no PC: compilar o exe, abrir pelo ícone, jogar com o formato 2026 e conferir os números, o R3 trocando de tela e o iPhone de verdade. Tudo até aqui foi testado só com o simulador + Chrome no Mac.
