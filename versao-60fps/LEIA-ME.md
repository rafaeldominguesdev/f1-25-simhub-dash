# F1 25 - Rafa Pro (60 fps, sem SimHub)

Roda no mesmo PC Windows do jogo. **Feche o SimHub antes** (os dois escutam o jogo na mesma porta).

1. **No PC:** dois cliques em `Iniciar.bat`.
   - Na primeira vez, se não tiver o Node.js, ele instala sozinho pelo winget. Depois é só abrir o `Iniciar.bat` de novo.
   - Se o Windows perguntar sobre o firewall, marque **Redes privadas** e clique em Permitir (senão o iPhone não conecta).
   - A janela mostra o endereço para abrir no iPhone. Deixe ela aberta enquanto joga.
2. **No F1 25**, em Configurações → Telemetria:
   - Telemetria UDP: **Ligada** · Broadcast: **Desligado**
   - IP: **127.0.0.1** · Porta: **20777**
   - Formato UDP: **2025** · Taxa de envio: **60 Hz**
3. **No iPhone** (mesma rede Wi-Fi): abra no Safari o endereço que aparece na janela (`http://IP-DO-PC:8888`) e deite o celular.
   - Compartilhar → **Adicionar à Tela de Início** abre em tela cheia.
   - Ajustes → Tela e Brilho → Bloqueio Automático → **Nunca**, para a tela não apagar no meio da corrida.

Toque nos 3 botões do canto de cima para trocar de tela (Corrida, Carro, Info).

Se o iPhone não abrir a página: confira se a rede do Windows está como **Privada** (Configurações → Rede e Internet → propriedades do Wi-Fi/Ethernet).
