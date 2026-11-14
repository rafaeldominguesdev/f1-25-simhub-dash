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
var red = $prop('{N}Flag_Red') == 1, chq = $prop('{N}Flag_Checkered') == 1;
var blk = $prop('{N}Flag_Black') == 1, grn = $prop('{N}Flag_Green') == 1 || fl == 1;
if (red) return mix([230,0,0],[100,0,0]);
if (sc == 1) return mix([255,196,0],[150,105,0]);
if (sc == 2) return mix([255,140,0],[110,55,0]);
if (sc == 3) return mix([0,140,60],[0,60,25]);
if (chq) return (Math.floor(Date.now() / 400) % 2 == 0) ? '#FFE8E8E8' : '#FF202020';
if (blk) return mix([60,60,60],[10,10,10]);
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
  Txt -Name "LED_$i" -X (18 + $i * 102) -Y 8 -W 96 -H 34 -Bg '#FF19191E' -Border (Border '#00FFFFFF' 0 6) `
      -Bindings ([ordered]@{ BackgroundColor = (B 'BackgroundColor' (JS $js)) })
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
var flash = (low || ot) && fast;
var mc = '#FFFFD600';
'@
Tile 'ERS' $LX 478 $LW 234 $C.Yellow ([ordered]@{
  BackgroundColor           = (B 'BackgroundColor' (JS "$ersMode if (!flash) return '#FF000000'; return low ? '#FFFF1744' : '#FFFF8C00';"))
  'BorderStyle.BorderColor' = (B 'BorderStyle.BorderColor' (JS "$ersMode if (low) return fast ? '#FFFFFFFF' : '#FFFF1744'; if (ot) return fast ? '#FFFFFFFF' : '#FFFF8C00'; return '#FFFFD600';"))
})
Txt -Name 'ErsPct' -X ($LX + $LW - 200) -Y 484 -W 186 -H 40 -Size 34 -HA 2 -Text '100%' -Bindings ([ordered]@{
  Text      = (B 'Text' (NC "format(round(isnull([{R}PlayerCarStatusData.m_ersStoreEnergy],0) / 4000000 * 100, 0), '0') + '%'"))
  TextColor = (B 'TextColor' (JS "$ersMode return flash ? '#FF000000' : (low ? '#FFFF1744' : '#FFFFFFFF');"))
})
Gauge -Name 'ErsBar' -X ($LX + 14) -Y 532 -W ($LW - 28) -H 64 -Bindings ([ordered]@{
  Value      = (B 'Value' (NC "isnull([{R}PlayerCarStatusData.m_ersStoreEnergy],0) / 4000000 * 100"))
  GaugeColor = (B 'GaugeColor' (JS "$ersMode if (flash) return '#FFFFFFFF'; return low ? '#FFFF1744' : mc;"))
})
Txt -Name 'ErsMode' -X ($LX + 14) -Y 608 -W ($LW - 28) -H 44 -Size 30 -HA 0 -Text 'MEDIO' -Bindings ([ordered]@{
  Text      = (B 'Text' (JS "$ersMode if (low) return 'BATERIA BAIXA'; return m == 3 ? 'ULTRAPASSAGEM' : m == 2 ? 'HOTLAP' : m == 1 ? 'MEDIO' : 'NENHUM';"))
  TextColor = (B 'TextColor' (JS "$ersMode if (flash) return '#FF000000'; return low ? '#FFFF1744' : mc;"))
})
Txt -Name 'ErsUsed' -X ($LX + 14) -Y 660 -W ($LW - 28) -H 36 -Size 20 -HA 0 -Color $C.Label -Text 'USADO NA VOLTA 0%' -Bindings ([ordered]@{
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
Txt -Name 'DRS' -X $CX -Y 50 -W 360 -H 104 -Size 44 -Text 'DRS' -Bg $C.Tile -Border (Border '#FF2A2A30') -Bindings ([ordered]@{
  Text            = (B 'Text' (JS "$drsJs if (fault) return 'DRS FALHA'; if (open) return 'DRS ABERTO'; if (allowed) return 'DRS'; if (dist > 0) return 'DRS ' + dist + 'm'; return 'DRS';"))
  BackgroundColor = (B 'BackgroundColor' (JS "$drsJs if (fault) return '#FF4A0000'; if (open) return fast ? '#FF00E676' : '#FF003D1A'; if (allowed) return '#FF0D2614'; return '#FF000000';"))
  TextColor       = (B 'TextColor' (JS "$drsJs if (fault) return '#FFFF3B30'; if (open) return fast ? '#FF000000' : '#FF00E676'; if (allowed) return '#FF00E676'; if (dist > 0) return '#FFB0B0B8'; return '#FF3A3A42';"))
  'BorderStyle.BorderColor' = (B 'BorderStyle.BorderColor' (JS "$drsJs if (fault) return '#FFFF3B30'; if (open) return fast ? '#FFFFFFFF' : '#FF00E676'; if (allowed) return '#FF00E676'; return '#FF2A2A30';"))
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
Txt -Name 'BOX' -X ($CX + 368) -Y 50 -W 360 -H 104 -Size 36 -Text 'BOX' -Bg $C.Tile -Border (Border '#FF2A2A30') -Bindings ([ordered]@{
  Text            = (B 'Text' (JS "$pitJs if (ps == 2) return 'PARADO'; if (noLim) return 'LIMITADOR!'; if (ps == 1 && laneT < 4) return 'ENTRADA BOX'; if (lim) return 'LIMITADOR'; if (lane) return 'PIT LANE'; if (inWin) return 'BOX BOX'; return 'BOX';"))
  BackgroundColor = (B 'BackgroundColor' (JS "$pitJs if (ps == 2) return '#FF2979FF'; if (noLim) return blink ? '#FFFF1744' : '#FF3A0000'; if (ps == 1 && laneT < 4) return blink ? '#FF2979FF' : '#FFFFFFFF'; if (lim) return blink ? '#FF2979FF' : '#FF0D2A66'; if (lane) return '#FF0D2A66'; if (inWin) return blink ? '#FF00838F' : '#FF003C42'; return '#FF000000';"))
  TextColor       = (B 'TextColor' (JS "$pitJs if (ps == 1 && laneT < 4 && !noLim) return blink ? '#FFFFFFFF' : '#FF0D2A66'; return (lim || lane || inWin || ps > 0) ? '#FFFFFFFF' : '#FF3A3A42';"))
  'BorderStyle.BorderColor' = (B 'BorderStyle.BorderColor' (JS "$pitJs if (noLim) return '#FFFF1744'; if (inWin) return '#FF00E5FF'; return (lim || lane || ps > 0) ? '#FF2979FF' : '#FF2A2A30';"))
})
Txt -Name 'PitWindow' -X ($CX + 368) -Y 120 -W 360 -H 30 -Size 16 -Color $C.Label -Weight 'Normal' -Text 'JANELA --  PARADAS 0' -Bindings ([ordered]@{
  Text = (B 'Text' (JS "$pitJs if (ps == 2) return 'PARADA ' + stopT.toFixed(1) + 's'; if (lane || ps > 0) return 'NO PIT ' + laneT.toFixed(1) + 's'; return (ideal > 0 ? 'JANELA V' + ideal + '-' + latest : 'JANELA --') + '   PARADAS ' + stops;"))
  TextColor = (B 'TextColor' (JS "$pitJs return (lane || ps > 0) ? '#FFFFFFFF' : '#FF8E8E96';"))
})

# MARCHA + VELOCIDADE
Tile 'MARCHA' $CX 162 $CW 330 $C.Red
$shiftJs = @'
var p = $prop('{R}PlayerCarTelemetryData.m_revLightsPercent');
if (p == null) { var r = $prop('{N}Rpms'), m = $prop('{N}MaxRpm'); p = m ? (r / m - 0.75) / 0.23 * 100 : 0; }
'@
Txt -Name 'Gear' -X $CX -Y 170 -W $CW -H 250 -Size 250 -Text 'N' -Bindings ([ordered]@{
  Text      = (B 'Text' (NC "isnull([{N}Gear],'N')"))
  TextColor = (B 'TextColor' (JS "$shiftJs return (p >= 97) ? '#FFFF1744' : '#FFFFFFFF';"))
})
Txt -Name 'Speed' -X $CX -Y 420 -W $CW -H 66 -Size 52 -Text '0' -Bindings ([ordered]@{ Text = (B 'Text' (NC "format(isnull([{N}SpeedKmh],0),'0') + ' KM/H'")) })

# FAIXA DE STATUS (Safety Car / VSC / bandeiras) por cima da marcha
$statusJs = @'
var sc = $prop('{R}PacketSessionData.m_safetyCarStatus') || 0;
var fl = $prop('{R}PlayerCarStatusData.m_vehicleFiaFlags');
var ye = $prop('{N}Flag_Yellow');
var red = $prop('{N}Flag_Red') == 1, chq = $prop('{N}Flag_Checkered') == 1;
var blk = $prop('{N}Flag_Black') == 1, grn = $prop('{N}Flag_Green') == 1 || fl == 1;
var scd = $prop('{R}PlayerLapData.m_safetyCarDelta');
var scs = (scd == null) ? '' : '  ' + (scd >= 0 ? '+' : '') + scd.toFixed(1) + 's';
var t = '', bg = '#FFFFC400', fg = '#FF000000';
if (red) { t = 'BANDEIRA VERMELHA'; bg = '#FFE10600'; fg = '#FFFFFFFF'; }
else if (sc == 1) t = 'SAFETY CAR' + scs;
else if (sc == 2) { t = 'VSC' + scs; bg = '#FFFF8C00'; }
else if (sc == 3) { t = 'VOLTA DE FORMACAO'; bg = '#FF00C853'; }
else if (chq) { t = 'BANDEIRA QUADRICULADA'; bg = '#FFFFFFFF'; }
else if (blk) { t = 'BANDEIRA PRETA'; bg = '#FF000000'; fg = '#FFFFFFFF'; }
else if (fl == 3 || ye == 1) t = 'BANDEIRA AMARELA';
else if (fl == 2) { t = 'BANDEIRA AZUL'; bg = '#FF2979FF'; fg = '#FFFFFFFF'; }
else if (grn) { t = 'BANDEIRA VERDE'; bg = '#FF00C853'; }
else {
  var ps = $prop('{R}PlayerLapData.m_pitStatus') || 0;
  var laneT = ($prop('{R}PlayerLapData.m_pitLaneTimeInLaneInMS') || 0) / 1000;
  if (ps == 1 && laneT < 4) { t = 'ENTRADA DOS BOX'; bg = '#FF2979FF'; fg = '#FFFFFFFF'; }
}
'@
function Add-Banner([double]$X, [double]$Y, [double]$Wd, [double]$Hh, [double]$Size) {
Txt -Name 'StatusBanner' -X $X -Y $Y -W $Wd -H $Hh -Size $Size -Text 'SAFETY CAR' -Color '#FF000000' -Bg $C.Yellow -Border (Border '#FF000000' 2 8) -Bindings ([ordered]@{
  Text            = (B 'Text' (JS "$statusJs return t;"))
  Visible         = (B 'Visible' (JS "$statusJs return t != '';"))
  BackgroundColor = (B 'BackgroundColor' (JS "$statusJs return bg;"))
  TextColor       = (B 'TextColor' (JS "$statusJs return fg;"))
})
}
Add-Banner ($CX + 14) 176 ($CW - 28) 62 38

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

$screen1Items = $script:items.ToArray()

# =====================================================================
# ================= TELA 2: CARRO (desenho + danos) ===================
# =====================================================================
$script:items = New-Object System.Collections.ArrayList
Add-BgAndLeds

function DmgColor([string]$p) { "if(isnull($p,0) < 10, '#FF1FAE5B', if(isnull($p,0) < 30, '#FFFFC400', if(isnull($p,0) < 60, '#FFFF8C00', '#FFFF1744')))" }
function DmgPart([string]$Name, [double]$X, [double]$Y, [double]$Wd, [double]$Hh, [string]$Field, [int]$Rad = 8, [string]$Label = '', [double]$Size = 17) {
  $p = "[{R}PlayerCarDamageData.$Field]"
  $txt = $(if ($Label) { "'$Label ' + format(isnull($p,0),'0') + '%'" } else { "format(isnull($p,0),'0') + '%'" })
  Txt -Name "Car_$Name" -X $X -Y $Y -W $Wd -H $Hh -Size $Size -Color '#FF0A0A0C' -Text '0%' -Bg '#FF1FAE5B' -Border (Border '#FF0A0A0C' 2 $Rad) -Bindings ([ordered]@{
    Text            = (B 'Text' (NC $txt))
    BackgroundColor = (B 'BackgroundColor' (NC (DmgColor $p)))
  })
}
function Shape([string]$Name, [double]$X, [double]$Y, [double]$Wd, [double]$Hh, [int]$Rad, [string]$Bg = '#FF2A2D36', [string]$Bd = '#FF4A4E5A') {
  Txt -Name "Car_$Name" -X $X -Y $Y -W $Wd -H $Hh -Bg $Bg -Border (Border $Bd 2 $Rad)
}
function CarTyre([string]$K, [double]$X, [double]$Y, [double]$Wd, [double]$Hh) {
  $p = "[{N}TyreWear$K]"
  Txt -Name "Car_Tyre_$K" -X $X -Y $Y -W $Wd -H $Hh -Size 20 -Color '#FF0A0A0C' -Text '0%' -Bg '#FF1FAE5B' -Border (Border '#FF0A0A0C' 3 14) -Bindings ([ordered]@{
    Text            = (B 'Text' (NC "format(isnull($p,0),'0') + '%'"))
    BackgroundColor = (B 'BackgroundColor' (NC "if(isnull($p,0) < 25, '#FF1FAE5B', if(isnull($p,0) < 50, '#FFFFC400', if(isnull($p,0) < 70, '#FFFF8C00', '#FFFF1744')))"))
  })
}
function Callout([string]$Name, [double]$X, [double]$Y, [string]$Label, [string]$Field, [int]$HA = 0) {
  $p = "[{R}PlayerCarDamageData.$Field]"
  Txt -Name "CallLbl_$Name" -X $X -Y $Y -W 120 -H 22 -Size 14 -HA $HA -Color $C.Label -Text $Label
  Txt -Name "CallVal_$Name" -X $X -Y ($Y + 22) -W 120 -H 32 -Size 26 -HA $HA -Text '0%' -Bindings ([ordered]@{
    Text      = (B 'Text' (NC "format(isnull($p,0),'0') + '%'"))
    TextColor = (B 'TextColor' (NC (DmgColor $p)))
  })
}

# ---- coluna esquerda: resumo ao vivo ----
Tile 'MARCHA ' $LX 50 $LW 250 $C.Red
Txt -Name 'Gear2' -X $LX -Y 62 -W $LW -H 170 -Size 160 -Text 'N' -Bindings ([ordered]@{
  Text      = (B 'Text' (NC "isnull([{N}Gear],'N')"))
  TextColor = (B 'TextColor' (JS "$shiftJs return (p >= 97) ? '#FFFF1744' : '#FFFFFFFF';"))
})
Txt -Name 'Speed2' -X $LX -Y 234 -W $LW -H 58 -Size 40 -Text '0 KM/H' -Bindings ([ordered]@{ Text = (B 'Text' (NC "format(isnull([{N}SpeedKmh],0),'0') + ' KM/H'")) })

Tile 'DELTA ' $LX 308 $LW 150 '#FF5A5A62'
Txt -Name 'Delta2' -X $LX -Y 336 -W $LW -H 116 -Size 72 -Text '+0.000' -Bindings ([ordered]@{
  Text      = (B 'Text' (JS "$deltaVal if (d == null) return '+0.000'; return (d >= 0 ? '+' : '-') + Math.abs(d).toFixed(3);"))
  TextColor = (B 'TextColor' (JS "$deltaVal if (d == null || Math.abs(d) < 0.0005) return '#FFFFFFFF'; return d < 0 ? '$($C.Green)' : '#FFFF3B30';"))
})

Tile 'ERS ' $LX 466 $LW 120 $C.Yellow ([ordered]@{
  BackgroundColor           = (B 'BackgroundColor' (JS "$ersMode if (!flash) return '#FF000000'; return low ? '#FFFF1744' : '#FFFF8C00';"))
  'BorderStyle.BorderColor' = (B 'BorderStyle.BorderColor' (JS "$ersMode if (low) return fast ? '#FFFFFFFF' : '#FFFF1744'; if (ot) return fast ? '#FFFFFFFF' : '#FFFF8C00'; return '#FFFFD600';"))
})
Txt -Name 'ErsPct2' -X ($LX + $LW - 200) -Y 470 -W 186 -H 36 -Size 30 -HA 2 -Text '100%' -Bindings ([ordered]@{
  Text      = (B 'Text' (NC "format(round(isnull([{R}PlayerCarStatusData.m_ersStoreEnergy],0) / 4000000 * 100, 0), '0') + '%'"))
  TextColor = (B 'TextColor' (JS "$ersMode return flash ? '#FF000000' : (low ? '#FFFF1744' : '#FFFFFFFF');"))
})
Gauge -Name 'ErsBar2' -X ($LX + 14) -Y 516 -W ($LW - 28) -H 54 -Bindings ([ordered]@{
  Value      = (B 'Value' (NC "isnull([{R}PlayerCarStatusData.m_ersStoreEnergy],0) / 4000000 * 100"))
  GaugeColor = (B 'GaugeColor' (JS "$ersMode if (flash) return '#FFFFFFFF'; return low ? '#FFFF1744' : mc;"))
})

Tile 'POSICAO / VOLTA' $LX 594 $LW 118 $C.Red
Txt -Name 'PosLap2' -X $LX -Y 622 -W $LW -H 84 -Size 46 -Text 'P1   1/57' -Bindings ([ordered]@{ Text = (B 'Text' (NC "'P' + format(isnull([{N}Position],0),'0') + '   ' + format(isnull([{N}CurrentLap],0),'0') + '/' + format(isnull([{N}TotalLaps],0),'0')")) })

# ---- centro: desenho do carro (vista de cima, bico para cima) ----
$CarX = 408; $CarW = 624
Tile 'CARRO' $CarX 50 $CarW 662 $C.Red
$cx = $CarX + $CarW / 2
# assoalho (por baixo de tudo)
DmgPart 'Floor' ($cx - 150) 300 300 262 'm_floorDamage' 30 '' 1
# suspensao dianteira e traseira
foreach ($sy in @(222, 262)) { Shape "SuspFL_$sy" ($cx - 112) $sy 92 6 3 '#FF5A5E6A' '#FF5A5E6A'; Shape "SuspFR_$sy" ($cx + 20) $sy 92 6 3 '#FF5A5E6A' '#FF5A5E6A' }
foreach ($sy in @(548, 592)) { Shape "SuspRL_$sy" ($cx - 112) $sy 80 6 3 '#FF5A5E6A' '#FF5A5E6A'; Shape "SuspRR_$sy" ($cx + 32) $sy 80 6 3 '#FF5A5E6A' '#FF5A5E6A' }
# bico + monocoque + cockpit
Shape 'Nose' ($cx - 20) 150 40 150 18
Shape 'Mono' ($cx - 44) 280 88 196 28
DmgPart 'SidepodL' ($cx - 132) 332 90 170 'm_sidepodDamage' 24
DmgPart 'SidepodR' ($cx + 42) 332 90 170 'm_sidepodDamage' 24
Shape 'Cockpit' ($cx - 26) 318 52 78 26 '#FF050506' '#FF7A7E8A'
Shape 'Halo' ($cx - 6) 300 12 30 6 '#FF7A7E8A' '#FF7A7E8A'
DmgPart 'Engine' ($cx - 36) 462 72 128 'm_engineDamage' 20
DmgPart 'Gearbox' ($cx - 24) 588 48 40 'm_gearBoxDamage' 8 '' 14
# asas
DmgPart 'FWingL' ($cx - 192) 130 184 30 'm_frontLeftWingDamage' 6 'ASA E' 16
DmgPart 'FWingR' ($cx + 8) 130 184 30 'm_frontRightWingDamage' 6 'ASA D' 16
Shape 'FEndL' ($cx - 204) 118 14 54 4 '#FF4A4E5A' '#FF0A0A0C'
Shape 'FEndR' ($cx + 190) 118 14 54 4 '#FF4A4E5A' '#FF0A0A0C'
DmgPart 'Diffuser' ($cx - 100) 626 200 28 'm_diffuserDamage' 6 'DIFUSOR' 15
DmgPart 'RWing' ($cx - 150) 656 300 38 'm_rearWingDamage' 6 'ASA TRASEIRA' 17
Shape 'REndL' ($cx - 162) 646 14 56 4 '#FF4A4E5A' '#FF0A0A0C'
Shape 'REndR' ($cx + 148) 646 14 56 4 '#FF4A4E5A' '#FF0A0A0C'
# pneus (cor = desgaste)
CarTyre 'FrontLeft'  ($cx - 182) 186 72 118
CarTyre 'FrontRight' ($cx + 110) 186 72 118
CarTyre 'RearLeft'   ($cx - 196) 506 84 124
CarTyre 'RearRight'  ($cx + 112) 506 84 124
# legendas laterais
Callout 'Sidepod' ($CarX + 14) 360 'SIDEPOD' 'm_sidepodDamage'
Callout 'Motor'   ($CarX + 14) 440 'MOTOR' 'm_engineDamage'
Callout 'Floor'   ($CarX + $CarW - 134) 360 'ASSOALHO' 'm_floorDamage' 2
Callout 'Gearbox' ($CarX + $CarW - 134) 440 'CAMBIO' 'm_gearBoxDamage' 2
# legenda de cores
$leg = @(@('#FF1FAE5B','OK'), @('#FFFFC400','LEVE'), @('#FFFF8C00','MEDIO'), @('#FFFF1744','GRAVE'))
for ($i = 0; $i -lt 4; $i++) {
  $ly = 560 + $i * 34
  Txt -Name "LegSq_$i" -X ($CarX + 16) -Y ($ly + 6) -W 18 -H 18 -Bg $leg[$i][0] -Border (Border '#00FFFFFF' 0 4)
  Txt -Name "LegTx_$i" -X ($CarX + 42) -Y $ly -W 90 -H 30 -Size 15 -HA 0 -Color $C.Label -Text $leg[$i][1]
}
Add-Banner ($CarX + 14) 62 ($CarW - 28) 50 30

# ---- coluna direita: motor, freios, pressao ----
$PX = 1040; $PW = 512
Tile 'DESGASTE DO MOTOR' $PX 50 $PW 300 $C.Orange
$eng = @(@('MOTOR (ICE)','m_engineICEWear'), @('MGU-H','m_engineMGUHWear'), @('MGU-K','m_engineMGUKWear'),
         @('BATERIA (ES)','m_engineESWear'), @('CENTRAL (CE)','m_engineCEWear'), @('TURBO (TC)','m_engineTCWear'))
for ($i = 0; $i -lt $eng.Count; $i++) {
  $ey = 90 + $i * 42
  $p = "[{R}PlayerCarDamageData.$($eng[$i][1])]"
  Txt -Name "EngLbl_$i" -X ($PX + 16) -Y $ey -W 170 -H 34 -Size 17 -HA 0 -Color '#FFCFCFD6' -Weight 'Normal' -Text $eng[$i][0]
  Gauge -Name "EngBar_$i" -X ($PX + 190) -Y ($ey + 10) -W 220 -H 14 -Bindings ([ordered]@{
    Value      = (B 'Value' (NC "isnull($p,0)"))
    GaugeColor = (B 'GaugeColor' (NC (DmgColor $p)))
  })
  Txt -Name "EngVal_$i" -X ($PX + 420) -Y $ey -W 76 -H 34 -Size 20 -HA 2 -Text '0%' -Bindings ([ordered]@{
    Text      = (B 'Text' (NC "format(isnull($p,0),'0') + '%'"))
    TextColor = (B 'TextColor' (NC (DmgColor $p)))
  })
}

$wheels = @(@('FrontLeft','DE',0,0), @('FrontRight','DD',1,0), @('RearLeft','TE',0,1), @('RearRight','TD',1,1))
Tile 'FREIOS' $PX 358 $PW 170 $C.Red
foreach ($wh in $wheels) {
  $p = "[{N}BrakeTemperature$($wh[0])]"
  Txt -Name "Brake_$($wh[0])" -X ($PX + 16 + $wh[2] * 244) -Y (392 + $wh[3] * 66) -W 236 -H 58 -Size 26 -Text "$($wh[1]) 0$DEG" -Bg '#FF16161B' -Border (Border '#FF2A2A30' 2 8) -Bindings ([ordered]@{
    Text      = (B 'Text' (NC "'$($wh[1])  ' + format(isnull($p,0),'0') + '$DEG'"))
    TextColor = (B 'TextColor' (NC "if(isnull($p,0) < 300, '#FF4FC3F7', if(isnull($p,0) < 800, '#FF00E676', if(isnull($p,0) < 1000, '#FFFF8C00', '#FFFF1744')))"))
  })
}
Tile 'PRESSAO DOS PNEUS (PSI)' $PX 536 $PW 176 $C.Cyan
foreach ($wh in $wheels) {
  $p = "[{N}TyrePressure$($wh[0])]"
  Txt -Name "Press_$($wh[0])" -X ($PX + 16 + $wh[2] * 244) -Y (572 + $wh[3] * 66) -W 236 -H 58 -Size 26 -Color $C.Cyan -Text "$($wh[1]) 0.0" -Bg '#FF16161B' -Border (Border '#FF2A2A30' 2 8) -Bindings ([ordered]@{
    Text = (B 'Text' (NC "'$($wh[1])  ' + format(isnull($p,0),'0.0')"))
  })
}
$screen2Items = $script:items.ToArray()

# ================= MONTA O ARQUIVO =================
$screenId = [guid]::NewGuid().ToString()
$dash = [ordered]@{
  Version = 2; Id = [guid]::NewGuid().ToString(); BaseHeight = $H; BaseWidth = $W; BackgroundColor = '#FF000000'
  Screens = @(
    [ordered]@{
      Name = 'Corrida'; InGameScreen = $true; IdleScreen = $true; PitScreen = $false; ScreenId = $screenId
      IsForegroundLayer = $false; IsBackgroundLayer = $false; BackgroundColor = '#FF000000'
      Items = $screen1Items; Id = [guid]::NewGuid().ToString(); Sid = 0
    },
    [ordered]@{
      Name = 'Carro'; InGameScreen = $true; IdleScreen = $false; PitScreen = $false; ScreenId = [guid]::NewGuid().ToString()
      IsForegroundLayer = $false; IsBackgroundLayer = $false; BackgroundColor = '#FF000000'
      Items = $screen2Items; Id = [guid]::NewGuid().ToString(); Sid = 0
    })
  SnapToGrid = $false; HideLabels = $false; ShowForeground = $true; ForegroundOpacity = 100.0
  ShowBackground = $true; BackgroundOpacity = 100.0; ShowBoundingRectangles = $false; GridSize = 10
  Images = @()
  Metadata = [ordered]@{
    ScreenCount = 2.0; InGameScreensIndexs = @(0, 1); IdleScreensIndexs = @(0); MainPreviewIndex = 0
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

"OK: tela 1 = $($screen1Items.Count) elementos, tela 2 = $($screen2Items.Count) elementos"
"Instalado em: $OutDir"
"Pacote: $zip"
