# Contexto do projeto (para o Claude)

- **Responder sempre em português do Brasil**, linguagem simples e informal. O usuário escreve rápido e com erros de digitação.
- Projeto: dashboard de **F1 25** para **iPhone 15** (base 1560x720, proporção 19.5:9), com 3 telas: **Corrida**, **Carro** e **Info**, mais um menu de 3 botões no canto superior esquerdo.

## Versão SimHub (pronta, nesta pasta)
- `gerar_dash.ps1` gera a dash e instala em `C:\Program Files (x86)\SimHub\DashTemplates\F1 25 - Rafa Pro` (no PC Windows).
- `ferramentas\gerar_carro.ps1` gera as imagens da pasta `carro/` a partir de `carro.html`, `clima.html` e `menu.html` (Edge headless; janelas menores que ~160 px travam o Edge).
- `ferramentas\render_preview.ps1` gera as prévias da pasta `imagens/`.
- O SimHub do usuário é **grátis**: limita as dashes a ~10–15 fps e **só alimenta uma tela por vez** (abrir a dash no PC ou numa aba de teste deixa o iPhone preto). Nunca abrir a dash no navegador para testar enquanto ele usa o iPhone.
- O usuário **não quer pagar a licença** do SimHub. Não burlar a licença.

## Próximo projeto: versão própria a 60 fps (sem SimHub)
- Programa próprio que lê a **telemetria UDP do F1 25** (formato 2025; o jogo usa o pacote de temporada 2026) e manda para o iPhone por WebSocket. A dash vira uma página web desenhada a 60 fps.
- Repetir o visual e as funções da versão SimHub: as 3 telas, o carro neon com as peças mudando de cor pelo dano, os avisos de bandeira (vermelha/amarela em tela cheia; SC, VSC, azul, verde e formação roxa num painel grande; sem quadriculada e sem preta), ERS amarelo sem piscar, DRS que acende, marcha animada (cresce com toque verde ao subir e encolhe com toque laranja ao reduzir; vermelha na hora de trocar), luzes de RPM em retângulos, pneus com 3 faixas de temperatura, sem combustível, contornos finos e fundo preto.
- Os desenhos (`carro/`, `ferramentas/*.html`) são originais e podem ser reaproveitados. **Não usar arte da DeltaSimLabs** (licença proíbe) nem logos da F1.
- O jogo manda o UDP para **um IP só**: para rodar o programa no MacBook, colocar o IP do Mac na configuração de telemetria do jogo (mesma rede Wi-Fi).
