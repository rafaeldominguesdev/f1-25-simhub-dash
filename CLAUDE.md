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
- Feita em 14/11/2026. `servidor.js` (Node, sem dependências) lê a **telemetria UDP do F1 25** (formato 2025; o jogo usa o pacote de temporada 2026) e manda para o iPhone por WebSocket; `dash.html` desenha a 60 fps. O jeito normal de abrir é o ícone "F1 25 Rafa Pro" (ver "O app no PC" abaixo). O Node.js já está instalado no PC do usuário.
- Roda **no PC Windows do jogo**: no jogo o IP da telemetria é `127.0.0.1`. O SimHub precisa estar fechado (mesma porta 20777).
- Só tem o necessário para jogar: o usuário não quer extras.
- Testada só com simulador de pacotes + Chrome; falta testar com o jogo e no iPhone de verdade.
- O jogo não manda temperatura fora/meio/dentro do pneu: as 3 faixas são superfície / média / carcaça.
- Repetir o visual e as funções da versão SimHub: as 3 telas, o carro neon com as peças mudando de cor pelo dano, os avisos de bandeira (vermelha/amarela em tela cheia; SC, VSC, azul, verde e formação roxa num painel grande; sem quadriculada e sem preta), ERS amarelo sem piscar, DRS que acende, marcha animada (cresce com toque verde ao subir e encolhe com toque laranja ao reduzir; vermelha na hora de trocar), luzes de RPM em retângulos, pneus com 3 faixas de temperatura, sem combustível, contornos finos e fundo preto.
- Os desenhos (`carro/`, `ferramentas/*.html`) são originais e podem ser reaproveitados. **Não usar arte da DeltaSimLabs** (licença proíbe) nem logos da F1.
- O jogo manda o UDP para **um IP só**: por isso o programa roda no mesmo PC do jogo (127.0.0.1).

### O app no PC (feito no PC Windows em 14/11/2026)
- **`F1 25 Rafa Pro.vbs`** abre tudo sem janela preta: liga o `servidor.js --app` escondido e o servidor abre o **painel** (`painel.html`, em `/painel`) como janela de aplicativo do Edge (`--app`).
- O painel mostra: se o jogo está mandando dados (pacotes/s), um aviso se o formato da telemetria não for 2025, o **endereço para o iPhone** e quantos aparelhos estão conectados, a configuração do jogo, e os botões **"Abrir a dash no PC"** e **"Desligar"** (`POST /desligar`, aceito só do próprio PC). `GET /status` devolve o JSON do painel.
- Abrir o app de novo com ele já aberto só mostra a janela; com o SimHub aberto, aparece um aviso do Windows pedindo para fechar o SimHub.
- **`icone.ico`** (velocímetro vermelho) e **`Criar atalho.bat`**, que cria o ícone "F1 25 Rafa Pro" na área de trabalho. O atalho já foi criado no PC do usuário.
- A faixa "AGUARDANDO O F1 25..." foi **tirada** da dash; ela só avisa "SEM CONEXAO COM O PC".
- `Iniciar.bat` continua funcionando (modo com janela preta, bom para ver erros).

## A FAZER (pedido do usuário em 14/11/2026)
**A lista completa e detalhada está em `INSTRUCOES.md`** (app de configuração com interface bonita, skins, botão do controle para trocar de tela, distância do DRS, formato 2026, executável). Resumo:
O usuário quer que isso vire **um app de verdade** para F1, que ele abre sozinho, sem precisar do Claude:
1. **Executável `.exe`** que abre e liga tudo (hoje é o `.vbs`). Dá para compilar um launcher pequeno em C# com o `csc.exe` do .NET Framework do Windows (`C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`, opção `/win32icon:icone.ico /target:winexe`), que roda `node servidor.js --app` escondido. Precisa ser feito/compilado no PC Windows.
2. **Trocar skin (tema):** escolher no painel do app entre alguns temas de cores da dash (ex.: o atual preto/vermelho, um neon verde, um claro, cores de equipe genéricas, sem logos). Salvar a escolha num `config.json` ao lado do `servidor.js` e mandar para a dash junto com os dados (a dash troca as cores na hora). Hoje as cores ficam no objeto `C` do `dash.html` (linha ~149) e em várias cores fixas espalhadas: centralizar tudo no tema.
3. **Distância do DRS:** mostrar "DRS 120m" no bloco do DRS quando estiver chegando na zona (campo `m_drsActivationDistance` do pacote Car Status, em metros), além de "DRS" (disponível) e "DRS ABERTO".
4. **O jogo está mandando o formato 2026** (pacote de temporada 2026), não 2025, mesmo com 2025 escolhido no menu. Conferir se a opção 2025 existe no jogo; se não existir, adaptar o `servidor.js` para ler o formato 2026 (os tamanhos dos pacotes mudam; o SimHub tem leitor próprio `CodemastersF12026Manager`, com campos novos como `m_activeAero*`, `m_overtakeActive`, `m_2026Regulations`). Os valores atuais podem sair errados até isso ser resolvido.
5. **Estruturar como app:** pasta organizada, um `LEIA-ME` simples de instalar (baixar, dois cliques em `Criar atalho.bat`, abrir pelo ícone) e, se possível, um instalador ou um `.zip` pronto para baixar no GitHub (Releases).
- Ainda falta testar com o jogo na pista e no iPhone de verdade.
