# F1 25 - Rafa Pro (60 fps, sem SimHub)

App para o PC Windows do jogo: liga a dash do iPhone a 60 fps e tem uma janela para configurar tudo
(2 layouts da dash, Clássico e F1, tema, telas, botão do volante para trocar de tela, avisos, unidades).

## Instalar (uma vez)

1. Baixe o `.zip` em **Releases** no GitHub e extraia numa pasta fixa (ex.: `Documentos\F1 25 Rafa Pro`).
   Quem usa o `git`: `git pull` e entre na pasta `versao-60fps`.
2. Dois cliques em **`Criar atalho.bat`**. Ele compila o `F1 25 Rafa Pro.exe` e cria o ícone **F1 25 Rafa Pro** na área de trabalho.
3. Abra pelo ícone. Se não tiver o Node.js, o app pergunta e instala sozinho. Depois é só abrir o ícone de novo.
4. Se o Windows perguntar sobre o firewall, marque **Redes privadas** e clique em Permitir (senão o iPhone não conecta).

## No F1 25 (Configurações → Telemetria)

| | |
|---|---|
| Telemetria UDP | Ligada |
| Broadcast UDP | Desligado |
| IP | `127.0.0.1` |
| Porta | `20777` |
| Taxa de envio | 60 Hz |
| Formato UDP | 2025 ou 2026 (com o pacote de temporada 2026, use **2026**: só ele manda o overtake e a aero ativa) |

**Feche o SimHub** antes de abrir o app: os dois escutam o jogo na mesma porta.

## No iPhone

Abra no Safari o endereço que aparece no app (ou aponte a câmera para o QR code) e deite o celular.
- Compartilhar → **Adicionar à Tela de Início** abre em tela cheia.
- Ajustes → Tela e Brilho → Bloqueio Automático → **Nunca**.

## Trocar de tela pelo volante

Padrão: **R3** (clique do analógico direito). Dá para trocar no app, na aba **Controle**, e testar lá mesmo.
Para não misturar com funções do jogo, ligue um botão livre a **UDP Action 1** nos controles do F1 25 e escolha "UDP Action 1" no app.

## Arquivos

- `F1 25 Rafa Pro.exe`: abre o app (criado pelo `Compilar exe.bat`).
- `app/`: o app (servidor, dash, janela de configuração, `config.json` com as suas escolhas).
- `Iniciar.bat`: abre com a janela preta, para ver erros. No modo normal, erros vão para `app\erro.log`.
- `teste/simulador.js`: manda dados falsos para testar sem o jogo (`node teste\simulador.js normal 2026`).
