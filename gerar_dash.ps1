# Gera a dashboard "F1 25 - Rafa Pro" para o SimHub (Dash Studio)
# Uso: powershell -ExecutionPolicy Bypass -File gerar_dash.ps1
# Edite cores/posicoes aqui e rode de novo para regerar.

$ErrorActionPreference = 'Stop'
$DashName = 'F1 25 - Rafa Pro'
$OutDir   = Join-Path 'C:\Program Files (x86)\SimHub\DashTemplates' $DashName
$N = 'DataCorePlugin.GameData.NewData.'
$R = 'DataCorePlugin.GameRawData.'
$DEG = [string][char]0x00B0

# ---------- layout: iPhone 15 (2556x1179 = 19.5:9) -> base 1560x720 ----------
$W = 1560; $H = 720
$LX = 8;    $LW = 400   # coluna esquerda
$CX = 416;  $CW = 728   # centro
$RX = 1152; $RW = 400   # coluna direita

# ---------- cores ----------
$C = @{
  Tile   = '#FF000000'; Label = '#FF8E8E96'; White = '#FFFFFFFF'
  Red    = '#FFE10600'; Green = '#FF00E676'; Purple = '#FFB14CFF'
  Yellow = '#FFFFC400'; Blue  = '#FF2979FF'; Cyan = '#FF00E5FF'; Orange = '#FFFF8C00'
  None   = '#00FFFFFF'
}

function P([string]$s) { $s.Replace('{N}', $N).Replace('{R}', $R) }
function JS([string]$code) { [ordered]@{ Interpreter = 1; Expression = (P $code) } }
function NC([string]$expr) { [ordered]@{ Expression = (P $expr) } }
function B([string]$prop, $formula, [string]$fmt = $null) {
  $b = [ordered]@{}
  if ($fmt) { $b.FormatString = $fmt }
  $b.Formula = $formula; $b.Mode = 2; $b.TargetPropertyName = $prop
  $b
}
function Border([string]$color, [int]$w = 2, [int]$r = 10) {
  [ordered]@{ BorderColor = $color; BorderTop = $w; BorderBottom = $w; BorderLeft = $w; BorderRight = $w
              RadiusTopLeft = $r; RadiusTopRight = $r; RadiusBottomLeft = $r; RadiusBottomRight = $r }
}

$script:items = New-Object System.Collections.ArrayList

function Txt {
  param([string]$Name, [double]$X, [double]$Y, [double]$W, [double]$H, [string]$Text = '',
        [double]$Size = 24, [string]$Color = '#FFFFFFFF', [string]$Bg = '#00FFFFFF',
        [int]$HA = 1, [int]$VA = 1, [string]$Weight = 'Bold', [string]$Font = 'Formula1 Display',
        $Border = $null, $Bindings = $null)
  $o = [ordered]@{
    '$type' = 'SimHub.Plugins.OutputPlugins.GraphicalDash.Models.TextItem, SimHub.Plugins'
    IsTextItem = $true; Font = $Font; FontWeight = $Weight; FontStyle = 'Normal'; FontSize = $Size
    Text = $Text; TextColor = $Color; HorizontalAlignment = $HA; VerticalAlignment = $VA
    BackgroundColor = $Bg; BorderStyle = $(if ($Border) { $Border } else { [ordered]@{} })
    Height = $H; Left = $X; Top = $Y; Visible = $true; Width = $W
    Id = [guid]::NewGuid().ToString(); Name = $Name; Sid = 0
  }
  if ($Bindings) { $o.Bindings = $Bindings }
  [void]$script:items.Add($o)
}

function Gauge {
  param([string]$Name, [double]$X, [double]$Y, [double]$W, [double]$H, $Bindings, [string]$Color = '#FF00E676', [string]$Bg = '#FF1A1A1E')
  [void]$script:items.Add([ordered]@{
    '$type' = 'SimHub.Plugins.OutputPlugins.GraphicalDash.Models.LinearGaugeItem, SimHub.Plugins'
    IsLinearGauge = $true; GaugeOrientation = 0; GaugeAlignment = 0; AutoSize = $false
    GaugeColor = $Color; Minimum = 0.0; Maximum = 100.0; Value = 50.0; Steps = 0.0; PAW = 0.0
    BackgroundColor = $Bg; BorderStyle = (Border '#00FFFFFF' 0 6)
    Height = $H; Left = $X; Top = $Y; Visible = $true; Width = $W
    Id = [guid]::NewGuid().ToString(); Name = $Name; Sid = 0; Bindings = $Bindings
  })
}

# Bloco com fundo escuro, borda colorida e titulo pequeno
function Tile([string]$Label, [double]$X, [double]$Y, [double]$W, [double]$H, [string]$Accent, $Bindings = $null) {
  Txt -Name "Tile_$Label" -X $X -Y $Y -W $W -H $H -Bg $C.Tile -Border (Border $Accent) -Bindings $Bindings
  Txt -Name "Lbl_$Label" -X ($X + 14) -Y ($Y + 6) -W ($W - 28) -H 26 -Text $Label -Size 17 -Color $C.Label -HA 0 -VA 1 -Weight 'Bold'
}

# ================= FUNDO (SAFETY CAR / BANDEIRAS) =================
# Pulsa suavemente entre dois tons: amarelo = SC/VSC/bandeira amarela, azul = bandeira azul
$bgJs = @'
var sc = $prop('{R}PacketSessionData.m_safetyCarStatus') || 0;
var fl = $prop('{R}PlayerCarStatusData.m_vehicleFiaFlags');
var ye = $prop('{N}Flag_Yellow');
var k = 0.5 + 0.5 * Math.sin((Date.now() % 1400) / 1400 * 2 * Math.PI);
function hx(v){ v = Math.max(0, Math.min(255, Math.round(v))); var s = v.toString(16); return s.length < 2 ? '0' + s : s; }
function mix(a, b){ return '#FF' + hx(a[0]+(b[0]-a[0])*k) + hx(a[1]+(b[1]-a[1])*k) + hx(a[2]+(b[2]-a[2])*k); }
var red = $prop('{N}Flag_Red') == 1;
var grn = $prop('{N}Flag_Green') == 1 || fl == 1;
if (red) return mix([230,0,0],[100,0,0]);
if (sc == 1) return mix([255,196,0],[150,105,0]);
if (sc == 2) return mix([255,140,0],[110,55,0]);
if (sc == 3) return mix([142,36,170],[60,15,75]);
if (fl == 3 || ye == 1) return mix([230,180,0],[120,90,0]);
if (fl == 2) return mix([0,90,255],[0,35,120]);
if (grn) return mix([0,200,80],[0,70,30]);
return '#FF050506';
'@
# Fundo + LEDs sao iguais nas duas telas
function Add-BgAndLeds {
Txt -Name 'Fundo_Flags' -X 0 -Y 0 -W $W -H $H -Bg '#FF050506' -Bindings ([ordered]@{ BackgroundColor = (B 'BackgroundColor' (JS $bgJs)) })

# ================= LEDS DE RPM (15) =================
$ledColors = @($C.Green,$C.Green,$C.Green,$C.Green,$C.Green,$C.Red,$C.Red,$C.Red,$C.Red,$C.Red,$C.Purple,$C.Purple,$C.Purple,$C.Purple,$C.Purple)
for ($i = 0; $i -lt 15; $i++) {
  $js = @'
var p = $prop('{R}PlayerCarTelemetryData.m_revLightsPercent');
if (p == null) { var r = $prop('{N}Rpms'), m = $prop('{N}MaxRpm'); p = m ? (r / m - 0.75) / 0.23 * 100 : 0; }
if (p >= 99) return (Math.floor(Date.now() / 90) % 2 == 0) ? '#FF4FC3F7' : '#FF141418';
return (p / 100 * 15 > IDX) ? 'COL' : '#FF19191E';
'@
  $js = $js.Replace('IDX', "$i").Replace('COL', $ledColors[$i])
  Txt -Name "LED_$i" -X (212 + $i * 89) -Y 8 -W 84 -H 34 -Bg '#FF19191E' -Border (Border '#00FFFFFF' 0 6) `
      -Bindings ([ordered]@{ BackgroundColor = (B 'BackgroundColor' (JS $js)) })
}
}

# ================= MENU (3 botoes no canto superior esquerdo) =================
# Toque no icone para ir para a tela: 0 Corrida, 1 Carro/Motor, 2 Info. O da tela atual fica destacado.
$ScreenIds = @([guid]::NewGuid().ToString(), [guid]::NewGuid().ToString(), [guid]::NewGuid().ToString())
function Add-Menu([int]$Active) {
  for ($k = 0; $k -lt 3; $k++) {
    $img = $(if ($k -eq $Active) { "menu_${k}_on" } else { "menu_$k" })
    [void]$script:items.Add([ordered]@{
      '$type' = 'SimHub.Plugins.OutputPlugins.GraphicalDash.Models.ButtonItem, SimHub.Plugins'
      SimulatedKey = 0; SimulatedKeyV2 = [ordered]@{ KeyCode = 0; Win = $false; Ctrl = $false; Alt = $false; Shift = $false }
      SimulateKey = $false; TriggerSimHubInputName = ''
      PressedImage = "menu_${k}_on"; Image = $img; AutoSize = $false; BackgroundColor = '#00FFFFFF'
      Height = 42; Left = 8 + $k * 64; Top = 4; Visible = $true; Width = 60
      Behavior = [ordered]@{
        '$type' = 'SimHub.Plugins.OutputPlugins.GraphicalDash.Behaviors.Buttons.GotoScreenBehavior, SimHub.Plugins'
        Settings = [ordered]@{ TargetScreen = $ScreenIds[$k] }
      }
      Id = [guid]::NewGuid().ToString(); Name = "Menu_$k"; Sid = 0
    })
  }
}
Add-BgAndLeds

# ================= COLUNA ESQUERDA =================
# POS / VOLTA
Tile 'POS' $LX 50 196 104 $C.Red
Txt -Name 'Pos' -X $LX -Y 74 -W 196 -H 78 -Size 52 -Text 'P1' -Bindings ([ordered]@{ Text = (B 'Text' (NC "'P' + format(isnull([{N}Position],0),'0')")) })
Tile 'VOLTA' ($LX + 204) 50 196 104 $C.Red
Txt -Name 'Lap' -X ($LX + 204) -Y 74 -W 196 -H 78 -Size 38 -Text '1/57' -Bindings ([ordered]@{ Text = (B 'Text' (NC "format(isnull([{N}CurrentLap],0),'0') + '/' + format(isnull([{N}TotalLaps],0),'0')")) })

# DELTA (verde negativo / vermelho positivo, com fundo tingido)
$deltaVal = "var d = `$prop('PersistantTrackerPlugin.SessionBestLiveDeltaSeconds');"
Tile 'DELTA vs MELHOR' $LX 162 $LW 180 '#FF5A5A62'
Txt -Name 'Delta' -X $LX -Y 192 -W $LW -H 144 -Size 84 -Text '+0.000' -Bindings ([ordered]@{
  Text      = (B 'Text' (JS "$deltaVal if (d == null) return '+0.000'; return (d >= 0 ? '+' : '-') + Math.abs(d).toFixed(3);"))
  TextColor = (B 'TextColor' (JS "$deltaVal if (d == null || Math.abs(d) < 0.0005) return '#FFFFFFFF'; return d < 0 ? '$($C.Green)' : '#FFFF3B30';"))
})

# GAP para o carro da frente
Tile 'GAP FRENTE' $LX 350 $LW 120 $C.Cyan
Txt -Name 'GapAhead' -X $LX -Y 378 -W $LW -H 86 -Size 50 -Color $C.Cyan -Text '+0.000' -Bindings ([ordered]@{ Text = (B 'Text' (JS @'
var pos = $prop('{N}Position');
if (pos == 1) return 'LIDER';
var ms = $prop('{R}PlayerLapData.m_deltaToCarInFrontMSPart') || 0;
var mn = $prop('{R}PlayerLapData.m_deltaToCarInFrontMinutesPart') || 0;
return '+' + (mn * 60 + ms / 1000).toFixed(3);
'@)) })

# ERS
# Pisca rapido alternando: laranja em ULTRAPASSAGEM, vermelho com bateria < 10%
$ersMode = @'
var m = $prop('{R}PlayerCarStatusData.m_ersDeployMode');
var e = ($prop('{R}PlayerCarStatusData.m_ersStoreEnergy') || 0) / 4000000 * 100;
var fast = Math.floor(Date.now() / 120) % 2 == 0;
var low = e < 10, ot = m == 3;
var flash = false;
var mc = '#FFFFD600';
'@
Tile 'ERS' $CX 50 $CW 104 $C.Yellow ([ordered]@{
  BackgroundColor           = (B 'BackgroundColor' (JS "$ersMode if (!flash) return '#FF000000'; return low ? '#FFFF1744' : '#FFFF8C00';"))
  'BorderStyle.BorderColor' = (B 'BorderStyle.BorderColor' (JS "$ersMode return '#FFFFD600';"))
})
Txt -Name 'ErsPct' -X ($CX + $CW - 200) -Y 52 -W 186 -H 36 -Size 32 -HA 2 -Text '100%' -Bindings ([ordered]@{
  Text      = (B 'Text' (NC "format(round(isnull([{R}PlayerCarStatusData.m_ersStoreEnergy],0) / 4000000 * 100, 0), '0') + '%'"))
  TextColor = (B 'TextColor' (JS "$ersMode return flash ? '#FF000000' : (low ? '#FFFF1744' : '#FFFFFFFF');"))
})
Gauge -Name 'ErsBar' -X ($CX + 14) -Y 92 -W ($CW - 28) -H 30 -Bindings ([ordered]@{
  Value      = (B 'Value' (NC "isnull([{R}PlayerCarStatusData.m_ersStoreEnergy],0) / 4000000 * 100"))
  GaugeColor = (B 'GaugeColor' (JS "$ersMode return '#FFFFD600';"))
})
Txt -Name 'ErsMode' -X ($CX + 70) -Y 54 -W 330 -H 32 -Size 22 -HA 0 -Text 'MEDIO' -Bindings ([ordered]@{
  Text      = (B 'Text' (JS "$ersMode if (low) return 'BATERIA BAIXA'; return m == 3 ? 'ULTRAPASSAGEM' : m == 2 ? 'HOTLAP' : m == 1 ? 'MEDIO' : 'NENHUM';"))
  TextColor = (B 'TextColor' (JS "$ersMode if (flash) return '#FF000000'; return low ? '#FFFF1744' : mc;"))
})
Txt -Name 'ErsUsed' -X ($CX + 14) -Y 124 -W ($CW - 28) -H 26 -Size 16 -HA 0 -Color $C.Label -Text 'USADO NA VOLTA 0%' -Bindings ([ordered]@{
  Text      = (B 'Text' (NC "'USADO NA VOLTA ' + format(round(isnull([{R}PlayerCarStatusData.m_ersDeployedThisLap],0) / 4000000 * 100, 0), '0') + '%'"))
  TextColor = (B 'TextColor' (JS "$ersMode return flash ? '#FF000000' : '#FF8E8E96';"))
})

# ================= CENTRO =================
# DRS
$drsJs = @'
var open = $prop('{R}PlayerCarTelemetryData.m_drs') == 1 || $prop('{N}DRSEnabled') == 1;
var allowed = $prop('{R}PlayerCarStatusData.m_drsAllowed') == 1 || $prop('{N}DRSAvailable') == 1;
var fault = $prop('{R}PlayerCarDamageData.m_drsFault') == 1;
var dist = $prop('{R}PlayerCarStatusData.m_drsActivationDistance') || 0;
var fast = Math.floor(Date.now() / 110) % 2 == 0;
'@
Txt -Name 'DRS' -X $LX -Y 478 -W $LW -H 113 -Size 44 -Text 'DRS' -Bg $C.Tile -Border (Border '#FF2A2A30') -Bindings ([ordered]@{
  Text            = (B 'Text' (JS "$drsJs if (fault) return 'DRS FALHA'; if (open) return 'DRS ABERTO'; return 'DRS';"))
  BackgroundColor = (B 'BackgroundColor' (JS "$drsJs if (fault) return '#FF4A0000'; if (open) return '#FF00E676'; return '#FF000000';"))
  TextColor       = (B 'TextColor' (JS "$drsJs if (fault) return '#FFFF3B30'; if (open) return '#FF000000'; return '#FF3A3A42';"))
  'BorderStyle.BorderColor' = (B 'BorderStyle.BorderColor' (JS "$drsJs if (fault) return '#FFFF3B30'; if (open) return '#FF00E676'; return '#FF2A2A30';"))
})

# BOX / PIT
$pitJs = @'
var lane = $prop('{N}IsInPitLane') == 1 || ($prop('{R}PlayerLapData.m_pitStatus') || 0) > 0;
var lim = $prop('{N}PitLimiterOn') == 1;
var blink = Math.floor(Date.now() / 300) % 2 == 0;
var ideal = $prop('{R}PacketSessionData.m_pitStopWindowIdealLap') || 0;
var latest = $prop('{R}PacketSessionData.m_pitStopWindowLatestLap') || 0;
var lap = $prop('{N}CurrentLap') || 0;
var stops = $prop('{R}PlayerLapData.m_numPitStops') || 0;
var inWin = ideal > 0 && lap >= ideal && lap <= latest && !lane;
var ps = $prop('{R}PlayerLapData.m_pitStatus') || 0;
var laneT = ($prop('{R}PlayerLapData.m_pitLaneTimeInLaneInMS') || 0) / 1000;
var stopT = ($prop('{R}PlayerLapData.m_pitStopTimerInMS') || 0) / 1000;
var noLim = lane && !lim && ps != 2;
'@
Txt -Name 'BOX' -X $LX -Y 599 -W $LW -H 113 -Size 38 -Text 'BOX' -Bg $C.Tile -Border (Border '#FF2A2A30') -Bindings ([ordered]@{
  Text            = (B 'Text' (JS "$pitJs if (ps == 2) return 'PARADO'; if (noLim) return 'LIMITADOR!'; if (ps == 1 && laneT < 4) return 'ENTRADA BOX'; if (lim) return 'LIMITADOR'; if (lane) return 'PIT LANE'; if (inWin) return 'BOX BOX'; return 'BOX';"))
  BackgroundColor = (B 'BackgroundColor' (JS "$pitJs if (ps == 2) return '#FF2979FF'; if (noLim) return blink ? '#FFFF1744' : '#FF3A0000'; if (ps == 1 && laneT < 4) return blink ? '#FF2979FF' : '#FFFFFFFF'; if (lim) return blink ? '#FF2979FF' : '#FF0D2A66'; if (lane) return '#FF0D2A66'; if (inWin) return blink ? '#FF00838F' : '#FF003C42'; return '#FF000000';"))
  TextColor       = (B 'TextColor' (JS "$pitJs if (ps == 1 && laneT < 4 && !noLim) return blink ? '#FFFFFFFF' : '#FF0D2A66'; return (lim || lane || inWin || ps > 0) ? '#FFFFFFFF' : '#FF3A3A42';"))
  'BorderStyle.BorderColor' = (B 'BorderStyle.BorderColor' (JS "$pitJs if (noLim) return '#FFFF1744'; if (inWin) return '#FF00E5FF'; return (lim || lane || ps > 0) ? '#FF2979FF' : '#FF2A2A30';"))
})
Txt -Name 'PitWindow' -X $LX -Y 674 -W $LW -H 30 -Size 16 -Color $C.Label -Weight 'Normal' -Text 'JANELA --  PARADAS 0' -Bindings ([ordered]@{
  Text = (B 'Text' (JS "$pitJs if (ps == 2) return 'PARADA ' + stopT.toFixed(1) + 's'; if (lane || ps > 0) return 'NO PIT ' + laneT.toFixed(1) + 's'; return (ideal > 0 ? 'JANELA V' + ideal + '-' + latest : 'JANELA --') + '   PARADAS ' + stops;"))
  TextColor = (B 'TextColor' (JS "$pitJs return (lane || ps > 0) ? '#FFFFFFFF' : '#FF8E8E96';"))
})

# MARCHA + VELOCIDADE
Tile 'MARCHA' $CX 162 $CW 330 $C.Red
$shiftJs = @'
var p = $prop('{R}PlayerCarTelemetryData.m_revLightsPercent');
if (p == null) { var r = $prop('{N}Rpms'), m = $prop('{N}MaxRpm'); p = m ? (r / m - 0.75) / 0.23 * 100 : 0; }
'@
# Animacao da marcha: detecta a troca e guarda o momento em "root" (memoria entre quadros).
# Subiu: nasce menor e cresce (toque verde). Reduziu: nasce maior e encolhe (toque laranja). ~0,26 s.
function GearDetect([string]$key) {
  @"
var g = `$prop('{N}Gear'); var n = (g == 'R') ? -1 : ((g == null || g == 'N') ? 0 : parseInt(g));
var now = Date.now();
if (root['${key}L'] === undefined) { root['${key}L'] = n; root['${key}T'] = 0; root['${key}D'] = 0; }
if (n !== root['${key}L']) { root['${key}D'] = (n > root['${key}L']) ? 1 : -1; root['${key}L'] = n; root['${key}T'] = now; }
var DUR = 260; var el = now - root['${key}T']; var k = Math.min(1, el / DUR); var e = 1 - Math.pow(1 - k, 3); var dir = root['${key}D'];
"@
}
function GearAnimBindings([string]$key, [double]$base) {
  $size = (GearDetect "${key}s") + "if (k >= 1) return $base; var s0 = dir > 0 ? 0.72 : 1.15; return $base * (s0 + (1 - s0) * e);"
  $col = $shiftJs + (GearDetect "${key}c") + @'
if (p >= 97) return '#FFFF1744';
if (k >= 1 || dir == 0) return '#FFFFFFFF';
var t = dir > 0 ? [0, 230, 118] : [255, 140, 0];
function hx(v){ v = Math.max(0, Math.min(255, Math.round(v))); var s = v.toString(16); return s.length < 2 ? '0' + s : s; }
return '#FF' + hx(t[0] + (255 - t[0]) * e) + hx(t[1] + (255 - t[1]) * e) + hx(t[2] + (255 - t[2]) * e);
'@
  [ordered]@{
    Text      = (B 'Text' (NC "isnull([{N}Gear],'N')"))
    TextColor = (B 'TextColor' (JS $col))
    FontSize  = (B 'FontSize' (JS $size))
  }
}
Txt -Name 'Gear' -X $CX -Y 170 -W $CW -H 250 -Size 250 -Text 'N' -Bindings (GearAnimBindings 'g1' 250)
Txt -Name 'Speed' -X $CX -Y 420 -W $CW -H 66 -Size 52 -Text '0' -Bindings ([ordered]@{ Text = (B 'Text' (NC "format(isnull([{N}SpeedKmh],0),'0') + ' KM/H'")) })

# AVISO (bandeiras / Safety Car)
# Vermelha e amarela: TELA INTEIRA. SC, VSC, azul, verde, formacao: PAINEL GRANDE no meio.
# Surge rapido (0,18 s). Fica 4 s a cada mudanca; a vermelha fica ate acabar.
$statusJs = @'
var sc = $prop('{R}PacketSessionData.m_safetyCarStatus') || 0;
var fl = $prop('{R}PlayerCarStatusData.m_vehicleFiaFlags');
var ye = $prop('{N}Flag_Yellow');
var red = $prop('{N}Flag_Red') == 1;
var grn = $prop('{N}Flag_Green') == 1 || fl == 1;
var sec = ($prop('{R}PlayerLapData.m_sector') || 0) + 1;
var scd = $prop('{R}PlayerLapData.m_safetyCarDelta');
var scs = (scd == null) ? '' : 'DELTA ' + (scd >= 0 ? '+' : '') + scd.toFixed(1) + 's';
var t1 = '', t2 = '', sub = '', bg = '#FFFFD600', fg = '#FF000000', full = false;
if (red) { t1 = 'BANDEIRA'; t2 = 'VERMELHA'; bg = '#FFFF0000'; full = true; }
else if (sc == 1) { t1 = 'SAFETY CAR'; }
else if (sc == 2) { t1 = 'VIRTUAL'; t2 = 'SAFETY CAR'; }
else if (sc == 3) { t1 = 'VOLTA DE'; t2 = 'FORMACAO'; bg = '#FF8E24AA'; fg = '#FFFFFFFF'; }
else if (fl == 3 || ye == 1) { t1 = 'BANDEIRA'; t2 = 'AMARELA'; sub = 'SETOR ' + sec; full = true; }
else if (fl == 2) { t1 = 'BANDEIRA'; t2 = 'AZUL'; bg = '#FF2979FF'; fg = '#FFFFFFFF'; }
else if (grn) { t1 = 'BANDEIRA'; t2 = 'VERDE'; bg = '#FF00C853'; }
var t = t1 + ' ' + t2;
var now = Date.now();
if (root.pkL !== t) { root.pkL = t; root.pkT = now; }
var el = now - root.pkT;
var show = t1 != '' && (el < 4000 || red);
var k = Math.min(1, el / 180); var e = 1 - Math.pow(1 - k, 3); var s = 0.8 + 0.2 * e;
var PW = full ? 1560 : 1220, PH = full ? 720 : 500;
var pw = PW * s, ph = PH * s, px = 780 - pw / 2, py = 360 - ph / 2;
var bh = (sub != '') ? ph * 0.27 : 0, ah = ph - bh;
var maxLen = Math.max(t1.length, t2.length, 1);
var fs = Math.min(ah * 0.34, pw * 0.88 / (maxLen * 0.72));
var subFs = Math.min(bh * 0.6, pw * 0.88 / (Math.max(sub.length, 1) * 0.72));
'@
function Add-Popup {
  function PB([string]$code) { B ($code.Split(':')[0]) (JS ("$statusJs " + $code.Substring($code.IndexOf(':') + 1))) }
  Txt -Name 'PopupBox' -X 170 -Y 110 -W 1220 -H 500 -Bg '#FFFFD600' -Bindings ([ordered]@{
    Visible = (PB 'Visible:return show;'); BackgroundColor = (PB 'BackgroundColor:return bg;')
    Left = (PB 'Left:return px;'); Top = (PB 'Top:return py;'); Width = (PB 'Width:return pw;'); Height = (PB 'Height:return ph;')
  })
  Txt -Name 'PopupT1' -X 170 -Y 140 -W 1220 -H 160 -Size 120 -Text 'BANDEIRA' -Color '#FF000000' -Bindings ([ordered]@{
    Visible = (PB 'Visible:return show;'); Text = (PB 'Text:return t1;'); TextColor = (PB 'TextColor:return fg;'); FontSize = (PB 'FontSize:return fs;')
    Left = (PB 'Left:return px;'); Top = (PB "Top:return py + (t2 == '' ? ah * 0.29 : ah * 0.08);"); Width = (PB 'Width:return pw;'); Height = (PB 'Height:return ah * 0.42;')
  })
  Txt -Name 'PopupT2' -X 170 -Y 300 -W 1220 -H 160 -Size 120 -Text 'AMARELA' -Color '#FF000000' -Bindings ([ordered]@{
    Visible = (PB "Visible:return show && t2 != '';"); Text = (PB 'Text:return t2;'); TextColor = (PB 'TextColor:return fg;'); FontSize = (PB 'FontSize:return fs;')
    Left = (PB 'Left:return px;'); Top = (PB 'Top:return py + ah * 0.5;'); Width = (PB 'Width:return pw;'); Height = (PB 'Height:return ah * 0.42;')
  })
  Txt -Name 'PopupBand' -X 170 -Y 475 -W 1220 -H 135 -Bg '#FF000000' -Bindings ([ordered]@{
    Visible = (PB "Visible:return show && sub != '';")
    Left = (PB 'Left:return px;'); Top = (PB 'Top:return py + ah;'); Width = (PB 'Width:return pw;'); Height = (PB 'Height:return bh;')
  })
  Txt -Name 'PopupSub' -X 170 -Y 475 -W 1220 -H 135 -Size 80 -Text 'SETOR 1' -Color '#FFFFFFFF' -Bindings ([ordered]@{
    Visible = (PB "Visible:return show && sub != '';"); Text = (PB 'Text:return sub;'); FontSize = (PB 'FontSize:return subFs;')
    Left = (PB 'Left:return px;'); Top = (PB 'Top:return py + ah;'); Width = (PB 'Width:return pw;'); Height = (PB 'Height:return bh;')
  })
}

# AVISOS DE LIMITE DE PISTA / PENALIDADES (cantos do bloco da marcha)
$warnJs = "var w = `$prop('{R}PlayerLapData.m_cornerCuttingWarnings'); if (w == null) w = `$prop('{R}PlayerLapData.m_totalWarnings') || 0;"
Txt -Name 'Warnings' -X ($CX + 14) -Y 244 -W 200 -H 34 -Size 18 -HA 0 -Text 'AVISOS 0' -Color $C.Label -Bindings ([ordered]@{
  Text      = (B 'Text' (JS "$warnJs return 'AVISOS ' + w;"))
  TextColor = (B 'TextColor' (JS "$warnJs return w >= 3 ? '#FFFF1744' : w >= 1 ? '#FFFFC400' : '#FF8E8E96';"))
})
$penJs = @'
var p = $prop('{R}PlayerLapData.m_penalties') || 0;
var dt = $prop('{R}PlayerLapData.m_numUnservedDriveThroughPens') || 0;
var sg = $prop('{R}PlayerLapData.m_numUnservedStopGoPens') || 0;
var t = '';
if (dt > 0) t = 'DRIVE THROUGH'; else if (sg > 0) t = 'STOP & GO'; else if (p > 0) t = 'PENAL +' + p + 's';
'@
Txt -Name 'Penalty' -X ($CX + $CW - 274) -Y 244 -W 260 -H 34 -Size 18 -HA 2 -Text '' -Color '#FFFF1744' -Bindings ([ordered]@{
  Text    = (B 'Text' (JS "$penJs return t;"))
  Visible = (B 'Visible' (JS "$penJs return t != '';"))
})

# PNEUS
Tile 'PNEUS' $CX 500 $CW 212 $C.White
# Cada pneu: desenho de pneu com 3 faixas (fora / meio / dentro) coloridas pela temperatura,
# temperatura grande ao lado e barra de desgaste. Lado esquerdo espelhado do direito.
function TempCol([string]$p) { "if(isnull($p,0) < 80, '#FF2979FF', if(isnull($p,0) <= 105, '#FF00C853', if(isnull($p,0) <= 115, '#FFFF8C00', '#FFFF1744')))" }
function WearCol([string]$p) { "if(isnull($p,0) < 25, '#FF00C853', if(isnull($p,0) < 50, '#FFFFD600', if(isnull($p,0) < 70, '#FFFF8C00', '#FFFF1744')))" }
$tyres = @(
  @{ K = 'FrontLeft';  Side = 'L'; Y = 530 }, @{ K = 'FrontRight'; Side = 'R'; Y = 530 },
  @{ K = 'RearLeft';   Side = 'L'; Y = 620 }, @{ K = 'RearRight';  Side = 'R'; Y = 620 }
)
foreach ($t in $tyres) {
  $k = $t.K; $y = $t.Y
  $sx = $(if ($t.Side -eq 'L') { $CX + 22 } else { $CX + $CW - 86 })
  # borracha
  Txt -Name "TyreBody_$k" -X $sx -Y $y -W 64 -H 82 -Bg '#FF17171B' -Border (Border '#FF34343C' 2 14)
  # faixas: fora/meio/dentro (no lado esquerdo o "fora" fica a esquerda; no direito, a direita)
  $zones = $(if ($t.Side -eq 'L') { @('Outer','Middle','Inner') } else { @('Inner','Middle','Outer') })
  for ($z = 0; $z -lt 3; $z++) {
    $zp = "[{N}TyreTemperature$k$($zones[$z])]"
    Txt -Name "TyreZone_${k}_$($zones[$z])" -X ($sx + 6 + $z * 18) -Y ($y + 7) -W 16 -H 68 -Bg '#FF00C853' -Border (Border '#00FFFFFF' 0 5) -Bindings ([ordered]@{
      BackgroundColor = (B 'BackgroundColor' (NC (TempCol $zp)))
    })
  }
  $tp = "[{N}TyreTemperature$k]"; $wp = "[{N}TyreWear$k]"
  if ($t.Side -eq 'L') { $tx = $CX + 98; $ha = 0; $barX = $CX + 98; $pctX = $CX + 202; $pctHA = 0 }
  else                 { $tx = $CX + $CW - 238; $ha = 2; $barX = $CX + $CW - 194; $pctX = $CX + $CW - 240; $pctHA = 2 }
  Txt -Name "TyreTemp_$k" -X $tx -Y ($y + 2) -W 140 -H 44 -Size 36 -HA $ha -Text "90$DEG" -Bindings ([ordered]@{
    Text      = (B 'Text' (NC "format(isnull($tp,0),'0') + '$DEG'"))
    TextColor = (B 'TextColor' (NC (TempCol $tp)))
  })
  Gauge -Name "TyreWearBar_$k" -X $barX -Y ($y + 58) -W 96 -H 10 -Color '#FF00C853' -Bg '#FF26262C' -Bindings ([ordered]@{
    Value      = (B 'Value' (NC "100 - isnull($wp,0)"))
    GaugeColor = (B 'GaugeColor' (NC (WearCol $wp)))
  })
  Txt -Name "TyreWear_$k" -X $pctX -Y ($y + 48) -W 44 -H 30 -Size 17 -HA $pctHA -Color '#FFCFCFD6' -Text '0%' -Bindings ([ordered]@{
    Text      = (B 'Text' (NC "format(isnull($wp,0),'0') + '%'"))
    TextColor = (B 'TextColor' (NC (WearCol $wp)))
  })
}
$cmpJs = "var c = `$prop('{R}PlayerCarStatusData.m_visualTyreCompound');"
$cmpCol = "$cmpJs return c == 16 ? '#FFFF1744' : c == 17 ? '#FFFFD600' : c == 18 ? '#FFF2F2F2' : c == 7 ? '#FF00E676' : c == 8 ? '#FF2979FF' : '#FF8E8E96';"
# Icone do pneu: anel na cor do composto + letra
$tcx = $CX + [math]::Floor($CW / 2)
Txt -Name 'TyreIconRubber' -X ($tcx - 46) -Y 520 -W 92 -H 92 -Bg '#FF1B1B1F' -Border (Border '#FF2C2C32' 4 46)
Txt -Name 'TyreIcon' -X ($tcx - 40) -Y 526 -W 80 -H 80 -Size 40 -Text 'M' -Color '#FFFFD600' -Bg '#FF101013' -Border (Border '#FFFFD600' 9 40) -Bindings ([ordered]@{
  Text                      = (B 'Text' (JS "$cmpJs return c == 16 ? 'S' : c == 17 ? 'M' : c == 18 ? 'H' : c == 7 ? 'I' : c == 8 ? 'W' : '?';"))
  TextColor                 = (B 'TextColor' (JS $cmpCol))
  'BorderStyle.BorderColor' = (B 'BorderStyle.BorderColor' (JS $cmpCol))
})
Txt -Name 'Compound' -X ($CX + 230) -Y 616 -W ($CW - 460) -H 34 -Size 22 -Text 'MEDIO  0 VOLTAS' -Bindings ([ordered]@{
  Text      = (B 'Text' (JS "$cmpJs var a = `$prop('{R}PlayerCarStatusData.m_tyresAgeLaps') || 0; return (c == 16 ? 'MACIO' : c == 17 ? 'MEDIO' : c == 18 ? 'DURO' : c == 7 ? 'INTER' : c == 8 ? 'CHUVA' : '---') + '  ' + a + ' VOLTAS';"))
  TextColor = (B 'TextColor' (JS $cmpCol))
})
Txt -Name 'BrakeBias' -X ($CX + 230) -Y 654 -W ($CW - 460) -H 50 -Size 28 -Color $C.Cyan -Text 'BB 56.0' -Bindings ([ordered]@{ Text = (B 'Text' (NC "'BB ' + format(isnull([{N}BrakeBias],0),'0.0')")) })

# ================= COLUNA DIREITA =================
Tile 'VOLTA ATUAL' $RX 50 $RW 104 $C.White
Txt -Name 'CurLap' -X $RX -Y 76 -W $RW -H 74 -Size 54 -Text '0:00.000' -Bindings ([ordered]@{
  Text      = (B 'Text' (NC '[{N}CurrentLapTime]') 'm\:ss\.fff')
  TextColor = (B 'TextColor' (NC "if(isnull([{R}PlayerLapData.m_currentLapInvalid],0) = 1, '#FFFF1744', '#FFFFFFFF')"))
})

Tile 'ULTIMA' $RX 162 $RW 96 $C.Yellow
Txt -Name 'LastLap' -X $RX -Y 186 -W $RW -H 68 -Size 46 -Text '0:00.000' -Bindings ([ordered]@{
  Text      = (B 'Text' (NC '[{N}LastLapTime]') 'm\:ss\.fff')
  TextColor = (B 'TextColor' (NC "if([{N}LastLapTime] = [{N}BestLapTime] && [{N}BestLapTime] > 0, '$($C.Purple)', '#FFFFFFFF')"))
})

Tile 'MELHOR' $RX 266 $RW 96 $C.Purple
Txt -Name 'BestLap' -X $RX -Y 290 -W $RW -H 68 -Size 46 -Color $C.Purple -Text '0:00.000' -Bindings ([ordered]@{ Text = (B 'Text' (NC '[{N}BestLapTime]') 'm\:ss\.fff') })

# DANOS DO CARRO
Tile 'DANOS DO CARRO' $RX 370 $RW 342 $C.Red
$dmg = @(
  @('ASA DIANT. E', 'm_frontLeftWingDamage'), @('ASA DIANT. D', 'm_frontRightWingDamage'),
  @('ASA TRASEIRA', 'm_rearWingDamage'),      @('ASSOALHO', 'm_floorDamage'),
  @('DIFUSOR', 'm_diffuserDamage'),           @('SIDEPOD', 'm_sidepodDamage'),
  @('MOTOR', 'm_engineDamage'),               @('CAMBIO', 'm_gearBoxDamage')
)
for ($i = 0; $i -lt $dmg.Count; $i++) {
  $y = 406 + $i * 37
  $p = "[{R}PlayerCarDamageData.$($dmg[$i][1])]"
  Txt -Name "DmgLbl_$i" -X ($RX + 16) -Y $y -W 240 -H 34 -Size 18 -HA 0 -Color '#FFCFCFD6' -Weight 'Normal' -Text $dmg[$i][0]
  Txt -Name "DmgVal_$i" -X ($RX + $RW - 116) -Y ($y + 3) -W 100 -H 28 -Size 18 -HA 1 -Text '0%' -Color '#FF000000' -Bg $C.Green -Border (Border '#00FFFFFF' 0 6) -Bindings ([ordered]@{
    Text            = (B 'Text' (NC "format(isnull($p,0),'0') + '%'"))
    BackgroundColor = (B 'BackgroundColor' (NC "if(isnull($p,0) < 15, '#FF00C853', if(isnull($p,0) < 40, '#FFFFC400', '#FFFF1744'))"))
  })
}

Add-Menu 0
Add-Popup
$screen1Items = $script:items.ToArray()

# =====================================================================
# ================= TELA 2: CARRO (desenho + danos) ===================
# =====================================================================
$script:items = New-Object System.Collections.ArrayList
Add-BgAndLeds

# Cores de dano: contorno neon forte + preenchimento translucido da mesma cor
function DmgColor([string]$p) { "if(isnull($p,0) < 10, '#FF2BE04F', if(isnull($p,0) < 30, '#FFFFD600', if(isnull($p,0) < 60, '#FFFF8C00', '#FFFF1744')))" }
function DmgFill([string]$p)  { "if(isnull($p,0) < 10, '#8C2BE04F', if(isnull($p,0) < 30, '#8CFFD600', if(isnull($p,0) < 60, '#8CFF8C00', '#8CFF1744')))" }
function WearColor([string]$p) { "if(isnull($p,0) < 25, '#FF2BE04F', if(isnull($p,0) < 50, '#FFFFD600', if(isnull($p,0) < 70, '#FFFF8C00', '#FFFF1744')))" }
function WearFill([string]$p)  { "if(isnull($p,0) < 25, '#8C2BE04F', if(isnull($p,0) < 50, '#8CFFD600', if(isnull($p,0) < 70, '#8CFF8C00', '#8CFF1744')))" }

function DmgPart([string]$Name, [double]$X, [double]$Y, [double]$Wd, [double]$Hh, [string]$Field, [int]$Rad = 8, [string]$Label = '', [double]$Size = 16) {
  $p = "[{R}PlayerCarDamageData.$Field]"
  $txt = $(if ($Label -eq '-') { "''" } elseif ($Label) { "'$Label ' + format(isnull($p,0),'0') + '%'" } else { "format(isnull($p,0),'0') + '%'" })
  Txt -Name "Car_$Name" -X $X -Y $Y -W $Wd -H $Hh -Size $Size -Color '#FFFFFFFF' -Text '' -Bg '#8C2BE04F' -Border (Border '#FF2BE04F' 4 $Rad) -Bindings ([ordered]@{
    Text                      = (B 'Text' (NC $txt))
    BackgroundColor           = (B 'BackgroundColor' (NC (DmgFill $p)))
    'BorderStyle.BorderColor' = (B 'BorderStyle.BorderColor' (NC (DmgColor $p)))
  })
}
function Shape([string]$Name, [double]$X, [double]$Y, [double]$Wd, [double]$Hh, [int]$Rad, [string]$Bg = '#FF141418', [string]$Bd = '#FF8A8A92', [int]$Bw = 3) {
  Txt -Name "Car_$Name" -X $X -Y $Y -W $Wd -H $Hh -Bg $Bg -Border (Border $Bd $Bw $Rad)
}
function CarTyre([string]$K, [double]$X, [double]$Y, [double]$Wd, [double]$Hh) {
  $p = "[{N}TyreWear$K]"
  Txt -Name "Car_Tyre_$K" -X $X -Y $Y -W $Wd -H $Hh -Bg '#8C2BE04F' -Border (Border '#FF2BE04F' 4 16) -Bindings ([ordered]@{
    BackgroundColor           = (B 'BackgroundColor' (NC (WearFill $p)))
    'BorderStyle.BorderColor' = (B 'BorderStyle.BorderColor' (NC (WearColor $p)))
  })
}
# Anel com o desgaste do pneu + linha pontilhada ate o pneu
function WearRing([string]$K, [double]$RX, [double]$RY, [double]$DotX, [double]$DotW) {
  $p = "[{N}TyreWear$K]"
  Txt -Name "Car_Ring_$K" -X ($RX - 65) -Y ($RY - 65) -W 130 -H 130 -Size 36 -Text '0%' -Bg '#FF000000' -Border (Border '#FF2BE04F' 9 65) -Bindings ([ordered]@{
    Text                      = (B 'Text' (NC "format(isnull($p,0),'0') + '%'"))
    'BorderStyle.BorderColor' = (B 'BorderStyle.BorderColor' (NC (WearColor $p)))
  })
  Txt -Name "Car_Dots_$K" -X $DotX -Y ($RY - 18) -W $DotW -H 30 -Size 22 -Weight 'Normal' -Color '#FFB0B0B8' -Text '. . . . . .'
}
# Caixinha com a temperatura do pneu
function TempBox([string]$K, [double]$X, [double]$Y) {
  $p = "[{N}TyreTemperature$K]"
  Txt -Name "Car_Temp_$K" -X $X -Y $Y -W 76 -H 46 -Size 28 -Text '90' -Bg '#FF1E4FD8' -Border (Border '#FFFFFFFF' 2 4) -Bindings ([ordered]@{
    Text            = (B 'Text' (NC "format(isnull($p,0),'0')"))
    BackgroundColor = (B 'BackgroundColor' (NC "if(isnull($p,0) < 80, '#FF1E4FD8', if(isnull($p,0) <= 105, '#FF1E9E4A', if(isnull($p,0) <= 115, '#FFE07800', '#FFD81B3B')))"))
  })
}
function Callout([string]$Name, [double]$X, [double]$Y, [string]$Label, [string]$Field, [int]$HA = 0) {
  $p = "[{R}PlayerCarDamageData.$Field]"
  Txt -Name "CallLbl_$Name" -X $X -Y $Y -W 150 -H 22 -Size 15 -HA $HA -Color $C.Label -Text $Label
  Txt -Name "CallVal_$Name" -X $X -Y ($Y + 22) -W 150 -H 36 -Size 30 -HA $HA -Text '0%' -Bindings ([ordered]@{
    Text      = (B 'Text' (NC "format(isnull($p,0),'0') + '%'"))
    TextColor = (B 'TextColor' (NC (DmgColor $p)))
  })
}

# ---- coluna esquerda: resumo ao vivo (mais estreita) ----
$L2X = 8; $L2W = 330
Tile 'MARCHA ' $L2X 50 $L2W 250 $C.Red
Txt -Name 'Gear2' -X $L2X -Y 62 -W $L2W -H 170 -Size 160 -Text 'N' -Bindings (GearAnimBindings 'g2' 160)
Txt -Name 'Speed2' -X $L2X -Y 234 -W $L2W -H 58 -Size 36 -Text '0 KM/H' -Bindings ([ordered]@{ Text = (B 'Text' (NC "format(isnull([{N}SpeedKmh],0),'0') + ' KM/H'")) })

Tile 'DELTA ' $L2X 308 $L2W 150 '#FF5A5A62'
Txt -Name 'Delta2' -X $L2X -Y 336 -W $L2W -H 116 -Size 64 -Text '+0.000' -Bindings ([ordered]@{
  Text      = (B 'Text' (JS "$deltaVal if (d == null) return '+0.000'; return (d >= 0 ? '+' : '-') + Math.abs(d).toFixed(3);"))
  TextColor = (B 'TextColor' (JS "$deltaVal if (d == null || Math.abs(d) < 0.0005) return '#FFFFFFFF'; return d < 0 ? '$($C.Green)' : '#FFFF3B30';"))
})

Tile 'ERS ' $L2X 466 $L2W 120 $C.Yellow
Txt -Name 'ErsPct2' -X ($L2X + $L2W - 200) -Y 470 -W 186 -H 36 -Size 30 -HA 2 -Text '100%' -Bindings ([ordered]@{
  Text      = (B 'Text' (NC "format(round(isnull([{R}PlayerCarStatusData.m_ersStoreEnergy],0) / 4000000 * 100, 0), '0') + '%'"))
  TextColor = (B 'TextColor' (JS "$ersMode return low ? '#FFFF1744' : '#FFFFFFFF';"))
})
Gauge -Name 'ErsBar2' -X ($L2X + 14) -Y 516 -W ($L2W - 28) -H 54 -Color '#FFFFD600' -Bindings ([ordered]@{
  Value = (B 'Value' (NC "isnull([{R}PlayerCarStatusData.m_ersStoreEnergy],0) / 4000000 * 100"))
})

Tile 'POSICAO / VOLTA' $L2X 594 $L2W 118 $C.Red
Txt -Name 'PosLap2' -X $L2X -Y 622 -W $L2W -H 84 -Size 40 -Text 'P1   1/57' -Bindings ([ordered]@{ Text = (B 'Text' (NC "'P' + format(isnull([{N}Position],0),'0') + '   ' + format(isnull([{N}CurrentLap],0),'0') + '/' + format(isnull([{N}TotalLaps],0),'0')")) })

# ---- centro: menu do carro (desenho proprio em camadas de imagem, pasta carro\) ----
# Cada peca tem 4 imagens (_0 verde, _1 amarelo, _2 laranja, _3 vermelho) e o SimHub escolhe pela formula.
function ImgItem([string]$Name, [double]$X, [double]$Y, [double]$Wd, [double]$Hh, [string]$Image, $Bindings = $null) {
  $o = [ordered]@{
    '$type' = 'SimHub.Plugins.OutputPlugins.GraphicalDash.Models.ImageItem, SimHub.Plugins'
    Image = $Image; AutoSize = $false; BackgroundColor = '#00FFFFFF'
    Height = $Hh; Left = $X; Top = $Y; Visible = $true; Width = $Wd
    Id = [guid]::NewGuid().ToString(); Name = $Name; Sid = 0
  }
  if ($Bindings) { $o.Bindings = $Bindings }
  [void]$script:items.Add($o)
}
function CarLayer([string]$Part, [string]$Prop, [int[]]$Lim) {
  $img = "if(isnull($Prop,0) < $($Lim[0]), 'car_${Part}_0', if(isnull($Prop,0) < $($Lim[1]), 'car_${Part}_1', if(isnull($Prop,0) < $($Lim[2]), 'car_${Part}_2', 'car_${Part}_3')))"
  ImgItem "Car_$Part" $carL $carT 360 640 "car_${Part}_0" ([ordered]@{ Image = (B 'Image' (NC $img)) })
}
function DmgText([string]$Name, [double]$X, [double]$Y, [double]$Wd, [double]$Hh, [string]$Field, [string]$Label, [double]$Size = 16) {
  $p = "[{R}PlayerCarDamageData.$Field]"
  Txt -Name "CarTxt_$Name" -X $X -Y $Y -W $Wd -H $Hh -Size $Size -Text "$Label 0%" -Bindings ([ordered]@{ Text = (B 'Text' (NC "'$Label ' + format(isnull($p,0),'0') + '%'")) })
}

$CarX = 346; $CarW = 868
Tile 'CARRO' $CarX 50 $CarW 662 '#FF2A2A30'
$cx = $CarX + $CarW / 2
$carL = $cx - 180; $carT = 66
$dmgLim = @(10, 30, 60); $wearLim = @(25, 50, 70)
# ordem das camadas (de baixo para cima)
CarLayer 'Floor' '[{R}PlayerCarDamageData.m_floorDamage]' $dmgLim
ImgItem 'Car_BaseUnder' $carL $carT 360 640 'car_BaseUnder'
CarLayer 'SidepodL' '[{R}PlayerCarDamageData.m_sidepodDamage]' $dmgLim
CarLayer 'SidepodR' '[{R}PlayerCarDamageData.m_sidepodDamage]' $dmgLim
CarLayer 'Engine'   '[{R}PlayerCarDamageData.m_engineDamage]' $dmgLim
CarLayer 'Gearbox'  '[{R}PlayerCarDamageData.m_gearBoxDamage]' $dmgLim
CarLayer 'Diffuser' '[{R}PlayerCarDamageData.m_diffuserDamage]' $dmgLim
CarLayer 'RWing'    '[{R}PlayerCarDamageData.m_rearWingDamage]' $dmgLim
CarLayer 'FWingL'   '[{R}PlayerCarDamageData.m_frontLeftWingDamage]' $dmgLim
CarLayer 'FWingR'   '[{R}PlayerCarDamageData.m_frontRightWingDamage]' $dmgLim
CarLayer 'TyreFL'   '[{N}TyreWearFrontLeft]' $wearLim
CarLayer 'TyreFR'   '[{N}TyreWearFrontRight]' $wearLim
CarLayer 'TyreRL'   '[{N}TyreWearRearLeft]' $wearLim
CarLayer 'TyreRR'   '[{N}TyreWearRearRight]' $wearLim
ImgItem 'Car_BaseTop' $carL $carT 360 640 'car_BaseTop'
# % em cima das asas
DmgText 'FWingL' ($carL + 26) ($carT + 40) 150 40 'm_frontLeftWingDamage' 'ASA E' 16
DmgText 'FWingR' ($carL + 184) ($carT + 40) 150 40 'm_frontRightWingDamage' 'ASA D' 16
DmgText 'RWing'  ($carL + 98) ($carT + 592) 164 32 'm_rearWingDamage' 'ASA TRAS.' 14
# temperatura embaixo de cada pneu
TempBox 'FrontLeft'  ($carL + 31)  ($carT + 228)
TempBox 'FrontRight' ($carL + 253) ($carT + 228)
TempBox 'RearLeft'   ($carL - 10)  ($carT + 586)
TempBox 'RearRight'  ($carL + 294) ($carT + 586)
# aneis de desgaste com linha pontilhada
WearRing 'FrontLeft'  ($cx - 290) ($carT + 170) ($cx - 222) 76
WearRing 'FrontRight' ($cx + 290) ($carT + 170) ($carL + 326) 76
WearRing 'RearLeft'   ($cx - 290) ($carT + 526) ($cx - 222) 68
WearRing 'RearRight'  ($cx + 290) ($carT + 526) ($carL + 334) 68
# valores laterais
Callout 'Sidepod'  ($CarX + 16) 330 'SIDEPOD' 'm_sidepodDamage'
Callout 'Motor'    ($CarX + 16) 410 'MOTOR' 'm_engineDamage'
Callout 'Floor'    ($CarX + $CarW - 166) 330 'ASSOALHO' 'm_floorDamage' 2
Callout 'Gearbox'  ($CarX + $CarW - 166) 410 'CAMBIO' 'm_gearBoxDamage' 2
Callout 'Diffuser' ($CarX + $CarW - 166) 490 'DIFUSOR' 'm_diffuserDamage' 2

# ---- coluna direita: motor, freios, pressao (mais estreita) ----
$PX = 1222; $PW = 330
Tile 'DESGASTE DO MOTOR' $PX 50 $PW 300 $C.Orange
$eng = @(@('ICE','m_engineICEWear'), @('MGU-H','m_engineMGUHWear'), @('MGU-K','m_engineMGUKWear'),
         @('BATERIA','m_engineESWear'), @('CENTRAL','m_engineCEWear'), @('TURBO','m_engineTCWear'))
for ($i = 0; $i -lt $eng.Count; $i++) {
  $ey = 90 + $i * 42
  $p = "[{R}PlayerCarDamageData.$($eng[$i][1])]"
  Txt -Name "EngLbl_$i" -X ($PX + 14) -Y $ey -W 110 -H 34 -Size 16 -HA 0 -Color '#FFCFCFD6' -Weight 'Normal' -Text $eng[$i][0]
  Gauge -Name "EngBar_$i" -X ($PX + 124) -Y ($ey + 11) -W 130 -H 12 -Bindings ([ordered]@{
    Value      = (B 'Value' (NC "isnull($p,0)"))
    GaugeColor = (B 'GaugeColor' (NC (DmgColor $p)))
  })
  Txt -Name "EngVal_$i" -X ($PX + 258) -Y $ey -W 60 -H 34 -Size 18 -HA 2 -Text '0%' -Bindings ([ordered]@{
    Text      = (B 'Text' (NC "format(isnull($p,0),'0') + '%'"))
    TextColor = (B 'TextColor' (NC (DmgColor $p)))
  })
}

$wheels = @(@('FrontLeft','DE',0,0), @('FrontRight','DD',1,0), @('RearLeft','TE',0,1), @('RearRight','TD',1,1))
Tile 'FREIOS' $PX 358 $PW 170 $C.Red
foreach ($wh in $wheels) {
  $p = "[{N}BrakeTemperature$($wh[0])]"
  Txt -Name "Brake_$($wh[0])" -X ($PX + 12 + $wh[2] * 155) -Y (392 + $wh[3] * 66) -W 151 -H 58 -Size 22 -Text "$($wh[1]) 0$DEG" -Bg '#FF16161B' -Border (Border '#FF2A2A30' 2 8) -Bindings ([ordered]@{
    Text      = (B 'Text' (NC "'$($wh[1]) ' + format(isnull($p,0),'0') + '$DEG'"))
    TextColor = (B 'TextColor' (NC "if(isnull($p,0) < 300, '#FF4FC3F7', if(isnull($p,0) < 800, '#FF00E676', if(isnull($p,0) < 1000, '#FFFF8C00', '#FFFF1744')))"))
  })
}
Tile 'PRESSAO PNEUS (PSI)' $PX 536 $PW 176 $C.Cyan
foreach ($wh in $wheels) {
  $p = "[{N}TyrePressure$($wh[0])]"
  Txt -Name "Press_$($wh[0])" -X ($PX + 12 + $wh[2] * 155) -Y (572 + $wh[3] * 66) -W 151 -H 58 -Size 22 -Color $C.Cyan -Text "$($wh[1]) 0.0" -Bg '#FF16161B' -Border (Border '#FF2A2A30' 2 8) -Bindings ([ordered]@{
    Text = (B 'Text' (NC "'$($wh[1]) ' + format(isnull($p,0),'0.0')"))
  })
}
Add-Menu 1
Add-Popup
$screen2Items = $script:items.ToArray()

# =====================================================================
# ================= TELA 3: INFO (estrategia, setores, clima) =========
# =====================================================================
$script:items = New-Object System.Collections.ArrayList
Add-BgAndLeds

# ---- voltas restantes ----
Tile 'VOLTAS RESTANTES' 8 50 380 250 $C.White
Txt -Name 'LapsLeft' -X 8 -Y 80 -W 380 -H 160 -Size 130 -Text '35' -Bindings ([ordered]@{
  Text = (B 'Text' (JS "var t = `$prop('{N}TotalLaps') || 0, c = `$prop('{N}CurrentLap') || 0; return '' + Math.max(0, t - c + 1);"))
})
Txt -Name 'LapsLeftSub' -X 8 -Y 244 -W 380 -H 40 -Size 24 -Color $C.Label -Text 'VOLTA 23/57' -Bindings ([ordered]@{
  Text = (B 'Text' (NC "'VOLTA ' + format(isnull([{N}CurrentLap],0),'0') + '/' + format(isnull([{N}TotalLaps],0),'0')"))
})

# ---- se parar agora, volta em ----
$rejJs = @'
var r = $prop('{R}PacketSessionData.m_pitStopRejoinPosition') || 0;
var pos = $prop('{N}Position') || 0;
'@
Tile 'SE PARAR AGORA, VOLTA EM' 396 50 380 250 $C.Cyan
Txt -Name 'Rejoin' -X 396 -Y 80 -W 380 -H 160 -Size 130 -Text 'P8' -Color '#FFFFD600' -Bindings ([ordered]@{
  Text      = (B 'Text' (JS "$rejJs return r > 0 ? 'P' + r : '--';"))
  TextColor = (B 'TextColor' (JS "$rejJs if (r <= 0) return '#FF8E8E96'; if (r <= pos + 1) return '#FF00E676'; if (r <= pos + 4) return '#FFFFD600'; return '#FFFF5A4D';"))
})
Txt -Name 'RejoinSub' -X 396 -Y 244 -W 380 -H 40 -Size 24 -Color $C.Label -Text 'VOCE ESTA EM P4' -Bindings ([ordered]@{
  Text = (B 'Text' (NC "'VOCE ESTA EM P' + format(isnull([{N}Position],0),'0')"))
})

# ---- setores: ultima volta (verde = seu melhor, amarelo = mais lento) e melhor ----
$secFns = @'
function sec(v) { if (v == null) return null; if (typeof v == 'number') return v; if (v.TotalSeconds !== undefined) return v.TotalSeconds;
  var s = String(v); var p = s.split(':'); if (p.length == 3) return (+p[0]) * 3600 + (+p[1]) * 60 + parseFloat(p[2]);
  if (p.length == 2) return (+p[0]) * 60 + parseFloat(p[1]); var f = parseFloat(s); return isNaN(f) ? null : f; }
function fmt(x) { if (x == null || !(x > 0)) return '--.---'; if (x < 60) return x.toFixed(3);
  var m = Math.floor(x / 60); var r = x - m * 60; return m + ':' + (r < 10 ? '0' : '') + r.toFixed(3); }
'@
Tile 'SETORES' 784 50 768 250 $C.Purple
Txt -Name 'SecRowLast' -X 798 -Y 120 -W 130 -H 76 -Size 20 -HA 0 -Color $C.Label -Text 'ULTIMA'
Txt -Name 'SecRowBest' -X 798 -Y 206 -W 130 -H 76 -Size 20 -HA 0 -Color $C.Label -Text 'MELHOR'
for ($k = 1; $k -le 3; $k++) {
  $sx = 936 + ($k - 1) * 204
  $vals = "$secFns var last = sec(`$prop('{N}Sector${k}LastLapTime')); var best = sec(`$prop('{N}Sector${k}BestTime'));"
  Txt -Name "SecHead_$k" -X $sx -Y 84 -W 196 -H 30 -Size 22 -Color '#FFCFCFD6' -Text "S$k"
  Txt -Name "SecLast_$k" -X $sx -Y 120 -W 196 -H 76 -Size 36 -Text '28.412' -Color '#FF00E676' -Bg '#FF101014' -Border (Border '#FF2A2A30' 2 10) -Bindings ([ordered]@{
    Text      = (B 'Text' (JS "$vals return fmt(last);"))
    TextColor = (B 'TextColor' (JS "$vals if (!(last > 0)) return '#FF8E8E96'; return (best > 0 && last <= best + 0.0005) ? '#FF00E676' : '#FFFFD600';"))
  })
  Txt -Name "SecBest_$k" -X $sx -Y 206 -W 196 -H 76 -Size 36 -Text '28.105' -Color $C.Purple -Bg '#FF101014' -Border (Border '#FF2A2A30' 2 10) -Bindings ([ordered]@{
    Text = (B 'Text' (JS "$vals return fmt(best);"))
  })
}

# ---- clima: agora + previsao 5 / 15 / 30 min ----
$wxJs = @'
var arr = $prop('{R}PacketSessionData.m_weatherForecastSamples');
var n = $prop('{R}PacketSessionData.m_numWeatherForecastSamples') || 0;
var st = $prop('{R}PacketSessionData.m_sessionType');
function fc(min) { if (arr == null) return null; for (var i = 0; i < n; i++) { var s = arr[i]; if (s == null) continue;
  if ((st == null || s.m_sessionType == st) && s.m_timeOffset == min) return s; } return null; }
var names = ['LIMPO', 'POUCAS NUVENS', 'NUBLADO', 'CHUVA FRACA', 'CHUVA FORTE', 'TEMPESTADE'];
var s = fc(OFFSET);
var w = (OFFSET == 0 && $prop('{R}PacketSessionData.m_weather') != null) ? $prop('{R}PacketSessionData.m_weather') : (s ? s.m_weather : null);
var rain = s ? s.m_rainPercentage : null;
'@
Tile 'CLIMA' 8 308 1544 404 $C.Cyan
Txt -Name 'WxTemps' -X 1000 -Y 312 -W 538 -H 30 -Size 20 -HA 2 -Color '#FFCFCFD6' -Text "AR 24$DEG   PISTA 38$DEG" -Bindings ([ordered]@{
  Text = (B 'Text' (NC "'AR ' + format(isnull([{R}PacketSessionData.m_airTemperature],0),'0') + '$DEG   PISTA ' + format(isnull([{R}PacketSessionData.m_trackTemperature],0),'0') + '$DEG'"))
})
$cards = @(@(0, 'AGORA', 1, 10), @(5, '5 MIN', 1, 10), @(15, '15 MIN', 2, 30), @(30, '30 MIN', 3, 60))
for ($k = 0; $k -lt 4; $k++) {
  $off = $cards[$k][0]; $cx3 = 24 + $k * 382
  $js = $wxJs.Replace('OFFSET', "$off")
  Txt -Name "WxCard_$k" -X $cx3 -Y 350 -W 366 -H 346 -Bg '#FF101014' -Border (Border '#FF2A2A30' 2 16)
  Txt -Name "WxWhen_$k" -X $cx3 -Y 360 -W 366 -H 44 -Size 32 -Text $cards[$k][1]
  ImgItem "WxIcon_$k" ($cx3 + 108) 408 150 150 "wx_$($cards[$k][2])" ([ordered]@{ Image = (B 'Image' (JS "$js return 'wx_' + (w == null ? 0 : w);")) })
  Txt -Name "WxName_$k" -X $cx3 -Y 566 -W 366 -H 40 -Size 26 -Color '#FFCFCFD6' -Text @('POUCAS NUVENS','POUCAS NUVENS','NUBLADO','CHUVA FRACA')[$k] -Bindings ([ordered]@{
    Text = (B 'Text' (JS "$js return w == null ? '--' : names[w];"))
  })
  Txt -Name "WxRain_$k" -X $cx3 -Y 614 -W 366 -H 60 -Size 40 -Color '#FF4FA8FF' -Text "CHUVA $($cards[$k][3])%" -Bindings ([ordered]@{
    Text      = (B 'Text' (JS "$js return rain == null ? 'CHUVA --' : 'CHUVA ' + rain + '%';"))
    TextColor = (B 'TextColor' (JS "$js if (rain == null) return '#FF8E8E96'; return rain >= 50 ? '#FF2F8BFF' : (rain >= 20 ? '#FF4FA8FF' : '#FFCFCFD6');"))
  })
}
Add-Menu 2
Add-Popup
$screen3Items = $script:items.ToArray()

# ================= IMAGENS (pasta carro\: carro, clima e menu; geradas por ferramentas\gerar_carro.ps1) =================
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$carPngs = Get-ChildItem (Join-Path $Root 'carro') -Filter '*.png' | Sort-Object Name
if ($carPngs.Count -eq 0) { throw 'Faltam as imagens. Rode antes: ferramentas\gerar_carro.ps1' }
$md5 = [Security.Cryptography.MD5]::Create()
Add-Type -AssemblyName System.Drawing
$carImages = @(foreach ($f in $carPngs) {
  $bytes = [IO.File]::ReadAllBytes($f.FullName)
  $bm = [Drawing.Image]::FromFile($f.FullName); $iw = $bm.Width; $ih = $bm.Height; $bm.Dispose()
  [ordered]@{ Name = $f.BaseName; Extension = '.png'; Modified = $false; Optimized = $false; Width = $iw; Height = $ih
              Length = $bytes.Length; MD5 = (($md5.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join '') }
})

# ================= MONTA O ARQUIVO =================
$screenId = [guid]::NewGuid().ToString()
$dash = [ordered]@{
  Version = 2; Id = [guid]::NewGuid().ToString(); BaseHeight = $H; BaseWidth = $W; BackgroundColor = '#FF000000'
  Screens = @(
    [ordered]@{
      Name = 'Corrida'; InGameScreen = $true; IdleScreen = $true; PitScreen = $false; ScreenId = $ScreenIds[0]
      IsForegroundLayer = $false; IsBackgroundLayer = $false; BackgroundColor = '#FF000000'
      Items = $screen1Items; Id = [guid]::NewGuid().ToString(); Sid = 0
    },
    [ordered]@{
      Name = 'Carro'; InGameScreen = $true; IdleScreen = $false; PitScreen = $false; ScreenId = $ScreenIds[1]
      IsForegroundLayer = $false; IsBackgroundLayer = $false; BackgroundColor = '#FF000000'
      Items = $screen2Items; Id = [guid]::NewGuid().ToString(); Sid = 0
    },
    [ordered]@{
      Name = 'Info'; InGameScreen = $true; IdleScreen = $false; PitScreen = $false; ScreenId = $ScreenIds[2]
      IsForegroundLayer = $false; IsBackgroundLayer = $false; BackgroundColor = '#FF000000'
      Items = $screen3Items; Id = [guid]::NewGuid().ToString(); Sid = 0
    })
  SnapToGrid = $false; HideLabels = $false; ShowForeground = $true; ForegroundOpacity = 100.0
  ShowBackground = $true; BackgroundOpacity = 100.0; ShowBoundingRectangles = $false; GridSize = 10
  Images = $carImages
  Metadata = [ordered]@{
    ScreenCount = 3.0; InGameScreensIndexs = @(0, 1, 2); IdleScreensIndexs = @(0); MainPreviewIndex = 0
    IsOverlay = $false; ShowInTaskBar = $true; Width = [double]$W; Height = [double]$H; OverlaySizeWarning = $false
    MetadataVersion = 2.0; EnableOnDashboardMessaging = $true; PitScreensIndexs = @()
    Title = $DashName; Author = 'Rafa'; Description = 'Dashboard F1 25: delta, DRS, ERS, pneus, danos, safety car'
  }
  ShowOnScreenControls = $true; ShowInTaskBar = $true; IsOverlay = $false
  EnableClickThroughOverlay = $true; EnableOnDashboardMessaging = $true
}

$json = $dash | ConvertTo-Json -Depth 40
$utf8 = New-Object System.Text.UTF8Encoding($false)
New-Item -ItemType Directory -Force $OutDir | Out-Null
[IO.File]::WriteAllText((Join-Path $OutDir "$DashName.djson"), $json, $utf8)
[IO.File]::WriteAllText((Join-Path $OutDir "$DashName.djson.metadata"), ($dash.Metadata | ConvertTo-Json -Depth 5), $utf8)
# imagens embutidas: <dash>.djson.ressources = zip com os PNGs
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$res = Join-Path $OutDir "$DashName.djson.ressources"
if (Test-Path $res) { Remove-Item $res -Force }
$zipRes = [IO.Compression.ZipFile]::Open($res, 'Create')
foreach ($f in $carPngs) { [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipRes, $f.FullName, $f.Name) }
$zipRes.Dispose()

# Copia local + pacote .simhubdash (para compartilhar / GitHub)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$pkgRoot = Join-Path $here 'build'
$pkgDir = Join-Path $pkgRoot $DashName
if (Test-Path $pkgRoot) { Remove-Item $pkgRoot -Recurse -Force }
New-Item -ItemType Directory -Force $pkgDir | Out-Null
Copy-Item (Join-Path $OutDir "$DashName.djson*") $pkgDir
$zip = Join-Path $here "$DashName.simhubdash"
if (Test-Path $zip) { Remove-Item $zip -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($pkgRoot, $zip)
Remove-Item $pkgRoot -Recurse -Force

"OK: tela 1 = $($screen1Items.Count), tela 2 = $($screen2Items.Count), tela 3 = $($screen3Items.Count) elementos; $($carPngs.Count) imagens"
"Instalado em: $OutDir"
"Pacote: $zip"
