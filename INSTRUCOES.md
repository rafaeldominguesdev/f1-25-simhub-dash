# Instruções: transformar a versão 60 fps num app completo de F1

> Pedido do usuário em 14/11/2026. Leia também o `CLAUDE.md`.
> **Tudo em português do Brasil**: conversa, textos do app, comentários e mensagens de commit.
> O jogo, o controle e o SimHub ficam no **PC Windows**. No Mac não dá para testar com o jogo, então faça um **simulador de pacotes** para testar e deixe o teste de verdade para o usuário no PC.

## O que o usuário quer
Um **aplicativo de verdade para F1 25**, com **interface bonita**, que ele abre pelo ícone, configura tudo o que quiser mudar e usa no iPhone a 60 fps. Sem precisar do Claude para abrir.

## Como está hoje (pasta `versao-60fps/`)
- `servidor.js`: lê o UDP do jogo (porta 20777), serve a dash (`/`), o painel (`/painel`), `GET /status` e `POST /desligar` (só do próprio PC). Com `--app`, abre o painel como janela de app do Edge (`--app=`).
- `painel.html`: janela simples com o status do jogo, o endereço do iPhone e os botões **Abrir a dash no PC** e **Desligar**.
- `dash.html`: a dash a 60 fps (3 telas: Corrida, Carro, Info), menu de toque no canto.
- `F1 25 Rafa Pro.vbs` (abre sem janela preta), `icone.ico`, `Criar atalho.bat` (ícone na área de trabalho), `Iniciar.bat` (modo com janela preta, para ver erros).

## O que fazer

### 1. App de configuração com interface bonita (substitui o `painel.html`)
Uma janela de app, com cara de produto de F1: escura, vermelho de destaque, fonte Saira, cantos arredondados, ícones simples, abas laterais. Abas sugeridas:
- **Início:** status do jogo (conectado, pacotes/s, formato), **endereço do iPhone em letra grande + QR code** (gerar o QR no navegador, sem internet), aparelhos conectados, botões **Abrir a dash no PC** e **Desligar**.
- **Aparência / Skins:** escolher o tema com **prévia ao vivo** da dash (miniatura). Temas: o atual (preto/vermelho), neon verde, azul, claro e algumas cores "de equipe" genéricas, **sem logos nem nomes de equipes**. Permitir mudar a cor de destaque.
- **Telas e blocos:** ligar e desligar telas (Corrida, Carro, Info) e blocos de cada tela (ex.: esconder o gap, os danos, o clima); escolher a tela inicial.
- **Controle:** escolher o **botão para trocar de tela** (ver item 2), para ir para a tela anterior, e testar ("aperte o botão agora" → mostra que recebeu).
- **Avisos:** tempo que o aviso de bandeira fica na tela, ligar e desligar cada tipo (amarela, azul, verde, SC, VSC, vermelha, formação), som opcional.
- **Unidades e detalhes:** km/h ou mph, °C ou °F, estilo das luzes de RPM, mostrar ou não a distância do DRS.
- **Sobre / Ajuda:** como configurar a telemetria no jogo, firewall (redes privadas) e o iPhone (Adicionar à Tela de Início, bloqueio automático "Nunca").

Regras:
- Salvar tudo num **`config.json`** ao lado do `servidor.js` (criar com os padrões se não existir).
- Mudou no app → o servidor manda a config nova para a dash pelo WebSocket e **a dash aplica na hora**, sem recarregar.
- Tirar cores fixas espalhadas no `dash.html` (objeto `C`, linha ~149, e cores escritas direto no código) e passar tudo pelo **tema**.
- A interface de configuração roda só no PC (servida em `/painel`, rotas de alteração aceitas só de `127.0.0.1`/`::1`).

### 2. Botão do controle para trocar de tela (o usuário usava o R3 no SimHub)
O F1 25 manda os botões apertados pela telemetria: **pacote Event (id 3) com código `"BUTN"`**, campo `m_buttonStatus` (uint32, bits). Bits (conferir na especificação oficial do F1 25 UDP):
`0x00000001` Cruz/A · `0x00000002` Triângulo/Y · `0x00000004` Círculo/B · `0x00000008` Quadrado/X · `0x00000010` D-pad esquerda · `0x00000020` D-pad direita · `0x00000040` D-pad cima · `0x00000080` D-pad baixo · `0x00000100` Options/Menu · `0x00000200` L1/LB · `0x00000400` R1/RB · `0x00000800` L2/LT · `0x00001000` R2/RT · `0x00002000` clique analógico esquerdo (L3) · `0x00004000` **clique analógico direito (R3)** · `0x00008000`–`0x00040000` direções do analógico direito · `0x00080000` Special · `0x00100000` a `0x80000000` **UDP Action 1 a 12** (o usuário pode ligar qualquer botão do volante nelas em Controles do jogo).
- O evento chega quando o estado dos botões muda: troque de tela só na **borda de subida** (bit passou de 0 para 1).
- Padrão: **R3 = próxima tela**. Configurável no app (item 1, aba Controle).
- O servidor manda `{"tela": "proxima"}` (ou o índice) para a dash, que troca de tela com a mesma animação do toque.
- Atenção: os botões só chegam se a **telemetria UDP estiver ligada** no jogo; alguns botões já têm função no jogo (avisar no app).

### 3. Distância do DRS
No bloco do DRS, mostrar **"DRS 120m"** enquanto ele se aproxima da zona (`m_drsActivationDistance`, em metros, pacote Car Status), além de **"DRS"** (disponível) e **"DRS ABERTO"** (aceso). Sem piscar.

### 4. Formato 2026 da telemetria
O jogo do usuário tem o **pacote de temporada 2026** e está mandando o **formato 2026** (o servidor avisa: "o jogo está mandando o formato 2026"). Verificar se existe a opção 2025 no menu de telemetria; se não existir, **ler o formato 2026** (os tamanhos dos pacotes mudam; o SimHub tem um leitor próprio e campos como `m_activeAero*`, `m_overtakeActive`, `m_2026Regulations`). Procurar a especificação oficial do formato 2026 e ajustar os offsets. Mostrar no app qual formato está chegando.

### 5. Executável e jeito de app
- **`F1 25 Rafa Pro.exe`** com o ícone: launcher pequeno em C# que roda `node servidor.js --app` escondido. Deixar o código (`launcher/Launcher.cs`) e um **`Compilar exe.bat`** que compila no PC com o `csc.exe` do .NET Framework do Windows: `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /target:winexe /win32icon:icone.ico /out:"F1 25 Rafa Pro.exe" launcher\Launcher.cs`. O usuário roda o .bat uma vez no PC (o Mac não compila isso).
- Se o Node não estiver instalado, o launcher pergunta e instala pelo winget.
- O **`Criar atalho.bat`** passa a apontar para o `.exe`.
- Organizar as pastas (ex.: `app/` com `servidor.js`, `dash.html`, `painel/`, `config.json`, `fonte/`, `icone.ico`).
- **Release no GitHub:** um `.zip` pronto para baixar, com um LEIA-ME curto: baixar, extrair, rodar `Compilar exe.bat` e `Criar atalho.bat`, abrir pelo ícone.

## Não fazer
- Não usar arte da DeltaSimLabs nem logos/nomes da F1 e das equipes.
- Não colocar combustível de volta, nem bandeira quadriculada e preta, nem coisas piscando no ERS e no DRS.
- Não burlar a licença do SimHub (essa versão nem usa o SimHub).

## Quando terminar
Atualizar o `CLAUDE.md`, enviar ao GitHub e explicar ao usuário, em português e passo a passo, como atualizar no PC (`git pull`, compilar o exe, criar o atalho) e o que testar no jogo.
