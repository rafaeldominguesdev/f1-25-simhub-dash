param([string]$Djson, [string]$OutDir, [string]$Edge, [string]$Tmp)
$ErrorActionPreference = 'Continue'
$j = [IO.File]::ReadAllText($Djson) | ConvertFrom-Json
$W = $j.BaseWidth; $H = $j.BaseHeight
$carDir = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'carro'
# Grupos (Layer) viram a lista dos filhos; quem nao tem formula de "Visible" herda a do grupo.
function Flat($list) {
  foreach ($it in $list) {
    if ($it.Childrens) {
      foreach ($ch in $it.Childrens) {
        if ($it.Bindings -and $it.Bindings.Visible) {
          if (-not $ch.Bindings) { $ch | Add-Member -NotePropertyName Bindings -NotePropertyValue ([pscustomobject]@{}) -Force }
          if (-not $ch.Bindings.Visible) { $ch.Bindings | Add-Member -NotePropertyName Visible -NotePropertyValue $it.Bindings.Visible -Force }
        }
        $ch
      }
    } else { $it }
  }
}
New-Item -ItemType Directory -Force $OutDir | Out-Null

function css($c) { if (-not $c) { return 'transparent' }; if ($c -notmatch '^#[0-9A-Fa-f]{8}$') { return $c }
  $a = [Convert]::ToInt32($c.Substring(1,2),16)/255
  "rgba($([Convert]::ToInt32($c.Substring(3,2),16)),$([Convert]::ToInt32($c.Substring(5,2),16)),$([Convert]::ToInt32($c.Substring(7,2),16)),$([math]::Round($a,3)))" }

# Valores de exemplo (corrida normal)
$base = @{
  Pos = @{ Text = 'P4' }; Lap = @{ Text = '23/57' }
  Delta = @{ Text = '-0.231'; TextColor = '#FF00E676' }
  
  GapAhead = @{ Text = '+1.482' }; ErsPct = @{ Text = '68%' }; ErsMode = @{ Text = 'MEDIO'; TextColor = '#FFFFD600' }; ErsBar = @{ Gauge = '#FFFFD600' }; ErsBar2 = @{ Gauge = '#FFFFD600' }; Tile_ERS = @{ Border = '#FFFFD600' }; 'Tile_ERS ' = @{ Border = '#FFFFD600' }
  ErsUsed = @{ Text = 'USADO NA VOLTA 41%' }; FuelLaps = @{ Text = '+0.42' }
  Gear = @{ Text = '6' }; Speed = @{ Text = '287 KM/H' }
  Warnings = @{ Text = 'AVISOS 1'; TextColor = '#FFFFC400' }
  PitWindow = @{ Text = 'JANELA V24-29   PARADAS 0' }
  CurLap = @{ Text = '1:02.418' }; LastLap = @{ Text = '1:31.904'; TextColor = '#FFB14CFF' }; BestLap = @{ Text = '1:31.904' }
  Compound = @{ Text = 'MEDIO  18 VOLTAS' }
  TyreTemp_FrontLeft = @{ Text = '98°' }; TyreTemp_FrontRight = @{ Text = '108°'; BackgroundColor = '#FFEF6C00' }
  TyreTemp_RearLeft = @{ Text = '92°' }; TyreTemp_RearRight = @{ Text = '76°'; BackgroundColor = '#FF1565C0' }
  TyreWear_FrontLeft = @{ Text = 'DESG 31%' }; TyreWear_FrontRight = @{ Text = 'DESG 36%' }
  TyreWear_RearLeft = @{ Text = 'DESG 24%' }; TyreWear_RearRight = @{ Text = 'DESG 26%' }
  DmgVal_0 = @{ Text = '12%' }; DmgVal_1 = @{ Text = '27%'; BackgroundColor = '#FFFFC400' }
  DmgVal_3 = @{ Text = '4%' }; DmgVal_6 = @{ Text = '18%'; BackgroundColor = '#FFFFC400' }
  DRS = @{ TextColor = '#FF3A3A42'; Border = '#FF2A2A30' }
  StatusBanner = @{ Hidden = $true }; Penalty = @{ Hidden = $true }
}
function tcol($v) { if ($v -lt 80) { '#FF2979FF' } elseif ($v -le 105) { '#FF00C853' } elseif ($v -le 115) { '#FFFF8C00' } else { '#FFFF1744' } }
function wcol($v) { if ($v -lt 25) { '#FF00C853' } elseif ($v -lt 50) { '#FFFFD600' } elseif ($v -lt 70) { '#FFFF8C00' } else { '#FFFF1744' } }
$tyreSample = @{ FrontLeft = @(98, @(102,97,92), 31); FrontRight = @(108, @(104,109,113), 36); RearLeft = @(92, @(95,92,88), 24); RearRight = @(76, @(79,75,72), 56) }
foreach ($k in $tyreSample.Keys) {
  $v = $tyreSample[$k]
  $base["TyreTemp_$k"] = @{ Text = "$($v[0])" + [char]0x00B0; TextColor = (tcol $v[0]) }
  $z = @('Outer','Middle','Inner'); for ($i = 0; $i -lt 3; $i++) { $base["TyreZone_${k}_$($z[$i])"] = @{ BackgroundColor = (tcol $v[1][$i]) } }
  $base["TyreWearBar_$k"] = @{ Gauge = (wcol $v[2]); Pct = (100 - $v[2]) }
  $base["TyreWear_$k"] = @{ Text = "$($v[2])%"; TextColor = (wcol $v[2]) }
}
for ($i = 0; $i -lt 15; $i++) { $base["LED_$i"] = @{ BackgroundColor = $(if ($i -lt 9) { @('#FF00E676','#FFE10600','#FFB14CFF')[[math]::Floor($i/5)] } else { '#FF19191E' }) } }

$statesA = [ordered]@{
  '01_normal'          = @{ bg = '#FF050506' }
  '02_safety_car'      = @{ bg = '#FFFFC400'; p = '{"m_safetyCarStatus":1}' }
  '03_virtual_sc'      = @{ bg = '#FFFF8C00'; p = '{"m_safetyCarStatus":2}' }
  '04_bandeira_vermelha' = @{ bg = '#FFE10600'; p = '{"Flag_Red":1}' }
  '05_bandeira_amarela'  = @{ bg = '#FFE6B400'; p = '{"m_vehicleFiaFlags":3,"m_sector":0}' }
  '06_bandeira_azul'     = @{ bg = '#FF005AFF'; p = '{"m_vehicleFiaFlags":2}' }
  '07_bandeira_verde'    = @{ bg = '#FF00C850'; p = '{"Flag_Green":1}' }
  '10_volta_formacao'    = @{ bg = '#FF5A1A6E'; p = '{"m_safetyCarStatus":3}' }
  '11_box_drs_penalidade' = @{ bg = '#FF050506'; extra = @{
      BOX = @{ Text = 'LIMITADOR'; BackgroundColor = '#FF2979FF'; TextColor = '#FFFFFFFF'; Border = '#FF2979FF' }; PitWindow = @{ Text = 'NO PIT 6.2s'; TextColor = '#FFFFFFFF' }
      DRS = @{ Text = 'DRS ABERTO'; BackgroundColor = '#FF00E676'; TextColor = '#FF000000'; Border = '#FF00E676' }
      Penalty = @{ Text = 'PENAL +5s'; Hidden = $false }
      Warnings = @{ Text = 'AVISOS 3'; TextColor = '#FFFF1744' }
      Delta = @{ Text = '+0.387'; TextColor = '#FFFF3B30' }
      
      CurLap = @{ Text = '0:48.120'; TextColor = '#FFFF1744' }
      TyreIcon = @{ Text = 'S'; TextColor = '#FFFF1744'; Border = '#FFFF1744' }
      Compound = @{ Text = 'MACIO  3 VOLTAS'; TextColor = '#FFFF1744' }
      Speed = @{ Text = '80 KM/H' }; Gear = @{ Text = '2' }
  } }
}

$redLeds = @{}; for ($i = 0; $i -lt 15; $i++) { $redLeds["LED_$i"] = @{ BackgroundColor = '#FF4FC3F7' } }
$statesB = [ordered]@{
  '12_entrada_box' = @{ bg = '#FF050506'; extra = @{
      BOX = @{ Text = 'ENTRADA BOX'; BackgroundColor = '#FF2979FF'; TextColor = '#FFFFFFFF'; Border = '#FF2979FF' }
      PitWindow = @{ Text = 'NO PIT 1.8s'; TextColor = '#FFFFFFFF' }; Gear = @{ Text = '3' }; Speed = @{ Text = '80 KM/H' } } }
  '13_drs_aberto_ultrapassagem' = @{ bg = '#FF050506'; extra = ($redLeds + @{
      DRS = @{ Text = 'DRS ABERTO'; BackgroundColor = '#FF00E676'; TextColor = '#FF000000'; Border = '#FF00E676' }
      ErsMode = @{ Text = 'ULTRAPASSAGEM'; TextColor = '#FFFFD600' }; ErsBar = @{ Gauge = '#FFFFD600'; Pct = 41 }; ErsPct = @{ Text = '41%' }
      Gear = @{ Text = '7'; TextColor = '#FFFF1744' }; Speed = @{ Text = '318 KM/H' } }) }
  '14_bateria_baixa' = @{ bg = '#FF050506'; extra = @{
      ErsPct = @{ Text = '7%'; TextColor = '#FFFF1744' }; ErsMode = @{ Text = 'BATERIA BAIXA'; TextColor = '#FFFF1744' }
      ErsBar = @{ Gauge = '#FFFFD600'; Pct = 7 } } }
  '17_marcha_subindo' = @{ bg = '#FF050506'; extra = @{ Gear = @{ Text = '5'; TextColor = '#FF00E676'; Size = 0.78 }; Speed = @{ Text = '241 KM/H' } } }
  '18_marcha_reduzindo' = @{ bg = '#FF050506'; extra = @{ Gear = @{ Text = '3'; TextColor = '#FFFF8C00'; Size = 1.13 }; Speed = @{ Text = '142 KM/H' } } }
}

function dc($v) { if ($v -lt 10) { '#FF2BE04F' } elseif ($v -lt 30) { '#FFFFC400' } elseif ($v -lt 60) { '#FFFF8C00' } else { '#FFFF1744' } }
function tc($v) { if ($v -lt 25) { '#FF2BE04F' } elseif ($v -lt 50) { '#FFFFC400' } elseif ($v -lt 70) { '#FFFF8C00' } else { '#FFFF1744' } }
function carDamage($d) {
  $o = @{
    Gear2 = @{ Text = '6' }; Speed2 = @{ Text = '287 KM/H' }; Delta2 = @{ Text = '-0.231'; TextColor = '#FF00E676' }
    ErsPct2 = @{ Text = '68%' }; PosLap2 = @{ Text = 'P4   23/57' }
  }
  $parts = @{ FWingL = @('ASA E ', $d.fl); FWingR = @('ASA D ', $d.fr); RWing = @('ASA TRAS. ', $d.rw); Diffuser = @('DIFUSOR ', $d.di)
              SidepodL = @('', $d.sp); SidepodR = @('', $d.sp); Engine = @('', $d.en); Gearbox = @('', $d.gb); Floor = @('', $d.fo) }
  foreach ($k in $parts.Keys) { $cc = dc $parts[$k][1]; $o["Car_$k"] = @{ Text = $(if ($k -eq 'Floor' -or $k -eq 'Gearbox') { '' } else { "$($parts[$k][0])$($parts[$k][1])%" }); BackgroundColor = ('#8C' + $cc.Substring(3)); Border = $cc } }
  foreach ($c in @(@('Sidepod',$d.sp),@('Motor',$d.en),@('Floor',$d.fo),@('Gearbox',$d.gb))) { $o["CallVal_$($c[0])"] = @{ Text = "$($c[1])%"; TextColor = (dc $c[1]) } }
  $tw = @{ FrontLeft = $d.t[0]; FrontRight = $d.t[1]; RearLeft = $d.t[2]; RearRight = $d.t[3] }
  foreach ($k in $tw.Keys) { $tcc = tc $tw[$k]; $o["Car_Tyre_$k"] = @{ BackgroundColor = ('#8C' + $tcc.Substring(3)); Border = $tcc }; $o["Car_Ring_$k"] = @{ Text = "$($tw[$k])%"; Border = $tcc } }
  for ($i = 0; $i -lt 6; $i++) { $v = $d.e[$i]; $o["EngVal_$i"] = @{ Text = "$v%"; TextColor = (dc $v) }; $o["EngBar_$i"] = @{ Gauge = (dc $v); Pct = [math]::Max($v,1) } }
  $tt = @{ FrontLeft = @(98,'#FF1E9E4A'); FrontRight = @(108,'#FFE07800'); RearLeft = @(92,'#FF1E9E4A'); RearRight = @(76,'#FF1E4FD8') }; foreach ($q in $tt.Keys) { $o["Car_Temp_$q"] = @{ Text = "$($tt[$q][0])"; BackgroundColor = $tt[$q][1] } }
  $br = @(@('FrontLeft','DE',$d.b[0]),@('FrontRight','DD',$d.b[1]),@('RearLeft','TE',$d.b[2]),@('RearRight','TD',$d.b[3]))
  foreach ($b in $br) { $v = $b[2]; $o["Brake_$($b[0])"] = @{ Text = "$($b[1])  $v" + [char]0x00B0; TextColor = $(if ($v -lt 300) { '#FF4FC3F7' } elseif ($v -lt 800) { '#FF00E676' } elseif ($v -lt 1000) { '#FFFF8C00' } else { '#FFFF1744' }) } }
  function di($v, $l) { if ($v -lt $l[0]) { 0 } elseif ($v -lt $l[1]) { 1 } elseif ($v -lt $l[2]) { 2 } else { 3 } }
  foreach ($k in @('FWingL','FWingR','RWing','Diffuser','SidepodL','SidepodR','Engine','Gearbox','Floor')) { $o["Car_$k"] = @{ Img = "car_${k}_$(di $parts[$k][1] @(10,30,60))" } }
  $tmap = @{ TyreFL = 'FrontLeft'; TyreFR = 'FrontRight'; TyreRL = 'RearLeft'; TyreRR = 'RearRight' }
  foreach ($k in $tmap.Keys) { $o["Car_$k"] = @{ Img = "car_${k}_$(di $tw[$tmap[$k]] @(25,50,70))" } }
  $o['CarTxt_FWingL'] = @{ Text = "ASA E $($d.fl)%" }; $o['CarTxt_FWingR'] = @{ Text = "ASA D $($d.fr)%" }; $o['CarTxt_RWing'] = @{ Text = "ASA TRAS. $($d.rw)%" }
  $o['CallVal_Diffuser'] = @{ Text = "$($d.di)%"; TextColor = (dc $d.di) }
  $pr = @(@('FrontLeft','DE','22.6'),@('FrontRight','DD','22.8'),@('RearLeft','TE','20.4'),@('RearRight','TD','20.5'))
  foreach ($p in $pr) { $o["Press_$($p[0])"] = @{ Text = "$($p[1])  $($p[2])" } }
  $o
}
$statesC = [ordered]@{
  '01_tela1_corrida' = @{ bg = '#FF050506' }
  '15_tela2_carro'   = @{ bg = '#FF050506'; scr = 1; extra = (carDamage @{ fl = 4; fr = 12; rw = 0; di = 2; sp = 0; en = 6; gb = 3; fo = 1; t = @(31,36,24,26); e = @(14,9,11,7,5,12); b = @(612,640,540,552) }) }
  '19_tela3_info' = @{ bg = '#FF050506'; scr = 2 }
  '16_tela2_carro_danificado' = @{ bg = '#FF050506'; scr = 1
      extra = (carDamage @{ fl = 72; fr = 35; rw = 18; di = 44; sp = 9; en = 22; gb = 6; fo = 61; t = @(58,49,77,41); e = @(38,22,65,30,12,41); b = @(1040,860,410,280) }) }
}

$states = [ordered]@{}; foreach ($set in @($statesC, $statesA, $statesB)) { foreach ($k in $set.Keys) { if ($k -ne '01_normal') { $states[$k] = $set[$k] } } }
foreach ($name in $states.Keys) {
  $s = $states[$name]
  $ov = @{}; foreach ($k in $base.Keys) { $ov[$k] = $base[$k].Clone() }
  $ov['Fundo_Flags'] = @{ BackgroundColor = $s.bg }

  $popJs = New-Object Text.StringBuilder
  if ($s.extra) { foreach ($k in $s.extra.Keys) { if (-not $ov[$k]) { $ov[$k] = @{} }; foreach ($p in $s.extra[$k].Keys) { $ov[$k][$p] = $s.extra[$k][$p] } } }

  $sb = New-Object Text.StringBuilder
  [void]$sb.Append("<!doctype html><html><head><meta charset='utf-8'></head><body style='margin:0;background:#000'><div style='position:relative;width:${W}px;height:${H}px;overflow:hidden'>")
  foreach ($i in (Flat $j.Screens[[int]$s.scr].Items)) {
    $o = $ov[$i.Name]; if (-not $o) { $o = @{} }
    if ($o.Hidden) { continue }
    if ($i.'$type' -like '*ImageItem*' -or $i.'$type' -like '*ButtonItem*') {
      $imgName = $(if ($o.Img) { $o.Img } else { $i.Image })
      $src = 'file:///' + ((Join-Path $carDir "$imgName.png").Replace('\', '/').Replace(' ', '%20'))
      [void]$sb.Append("<img src='$src' style='position:absolute;left:$($i.Left)px;top:$($i.Top)px;width:$($i.Width)px;height:$($i.Height)px'>")
      continue
    }
    if ($i.Name -like 'Popup*') {
      [void]$sb.Append("<div id='$($i.Name)' style='position:absolute;display:none;box-sizing:border-box;align-items:center;justify-content:center;white-space:nowrap;overflow:hidden;line-height:1;font-family:""Formula1 Display"",sans-serif;font-weight:700'></div>")
      $bnd = @(); foreach ($bp in $i.Bindings.PSObject.Properties) { $bnd += ('"' + $bp.Name + '":' + ($bp.Value.Formula.Expression | ConvertTo-Json)) }
      [void]$popJs.Append("['$($i.Name)',{" + ($bnd -join ',') + "}],")
      continue
    }
    if ($name -eq '08_quadriculada' -and $i.Name -eq 'Fundo_Flags') { continue }
    $bs = $i.BorderStyle; $bw = 0 + $bs.BorderTop; $rad = 0 + $bs.RadiusTopLeft
    $bc = $(if ($o.Border) { css $o.Border } elseif ($bs.BorderColor) { css $bs.BorderColor } else { 'transparent' })
    $bgc = $(if ($o.BackgroundColor) { css $o.BackgroundColor } else { css $i.BackgroundColor })
    if ($i.'$type' -like '*Gauge*') { $gc = $(if ($o.Gauge) { css $o.Gauge } else { css $i.GaugeColor }); $gp = $(if ($o.Pct) { $o.Pct } else { 68 }); $bgc = "linear-gradient(90deg,$gc $gp%,$(css $i.BackgroundColor) $gp%)" }
    $tc = $(if ($o.TextColor) { css $o.TextColor } else { css $i.TextColor })
    $txt = [Net.WebUtility]::HtmlEncode($(if ($o.ContainsKey('Text')) { $o.Text } else { $i.Text }))
    $ja = @('flex-start','center','flex-end')[[int]$i.HorizontalAlignment]; $va = @('flex-start','center','flex-end')[[int]$i.VerticalAlignment]
    $fw = $(if ($i.FontWeight -eq 'Normal') { 400 } else { 700 })
    [void]$sb.Append("<div style='position:absolute;box-sizing:border-box;left:$($i.Left)px;top:$($i.Top)px;width:$($i.Width)px;height:$($i.Height)px;background:$bgc;border:$($bw)px solid $bc;border-radius:$($rad)px;color:$tc;font-family:""Formula1 Display"",""Formula1"",sans-serif;font-size:$([math]::Round($i.FontSize*$(if ($o.Size) { $o.Size } else { 1.0 })))px;font-weight:$fw;display:flex;align-items:$va;justify-content:$ja;overflow:hidden;white-space:nowrap;line-height:1'>$txt</div>")
  }
  $props = $(if ($s.p) { $s.p } else { '{}' })
  [void]$sb.Append("</div><script>var P=$props, root={};function `$prop(n){var k=n.split('.').pop();return (k in P)?P[k]:null;}" +
    "function col(c){if(!c||c.length!=9)return c;var a=parseInt(c.substr(1,2),16)/255;return 'rgba('+parseInt(c.substr(3,2),16)+','+parseInt(c.substr(5,2),16)+','+parseInt(c.substr(7,2),16)+','+a+')';}" +
    "var items=[" + $popJs.ToString() + "];var T0=10000000;" +
    "function run(){items.forEach(function(it){var el=document.getElementById(it[0]),b=it[1],v=function(k){return new Function('`$prop','root',b[k])(`$prop,root);};" +
    "el.style.display=(v('Visible'))?'flex':'none';['Left','Top','Width','Height'].forEach(function(k){if(b[k])el.style[k.toLowerCase()]=v(k)+'px';});" +
    "if(b.BackgroundColor)el.style.background=col(v('BackgroundColor'));if(b.TextColor)el.style.color=col(v('TextColor'));if(b.FontSize)el.style.fontSize=v('FontSize')+'px';if(b.Text)el.textContent=v('Text');});}" +
    "Date.now=function(){return T0;};run();Date.now=function(){return T0+1000;};run();</script></body></html>")
  $html = Join-Path $Tmp "$name.html"
  [IO.File]::WriteAllText($html, $sb.ToString(), (New-Object Text.UTF8Encoding($false)))
  $png = Join-Path $OutDir "$name.png"
  $url = 'file:///' + ($html -replace '\\','/')
  & $Edge --headless=new --disable-gpu --hide-scrollbars "--user-data-dir=$Tmp\edgeprof" "--window-size=$W,$H" "--screenshot=$png" $url 2>$null | Out-Null
  "$name -> $(Test-Path $png)"
}
