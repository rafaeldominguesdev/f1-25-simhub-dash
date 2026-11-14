# Gera TODAS as imagens da dash (pasta ..\carro) usando o Microsoft Edge em modo headless:
#  - car_*  : pecas do carro (carro.html). Cada peca com dano sai em 4 cores: _0 verde, _1 amarelo, _2 laranja, _3 vermelho.
#  - wx_*   : icones de clima (clima.html), 0 limpo ... 5 tempestade.
#  - menu_* : botoes do menu (menu.html), normal e "_on" (tela atual).
# Uso: powershell -ExecutionPolicy Bypass -File ferramentas\gerar_carro.ps1
param([string]$Edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe')
$ErrorActionPreference = 'Continue'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$out = Join-Path (Split-Path -Parent $here) 'carro'
New-Item -ItemType Directory -Force $out | Out-Null
$prof = Join-Path $env:TEMP 'f125dash_edge'
function Url([string]$file) { 'file:///' + ((Join-Path $here $file) -replace '\\', '/' -replace ' ', '%20') }
function Shot([string]$name, [string]$url, [int]$w, [int]$h) {
  $png = Join-Path $out "$name.png"
  & $Edge --headless=new --disable-gpu --hide-scrollbars "--user-data-dir=$prof" "--window-size=$w,$h" --default-background-color=00000000 "--screenshot=$png" $url 2>$null | Out-Null
}

$parts = @('Floor','SidepodL','SidepodR','Engine','Gearbox','Diffuser','RWing','FWingL','FWingR','TyreFL','TyreFR','TyreRL','TyreRR')
foreach ($p in $parts) { for ($c = 0; $c -lt 4; $c++) { Shot "car_${p}_$c" "$(Url 'carro.html')?part=$p&c=$c" 360 640 } }
Shot 'car_BaseUnder' "$(Url 'carro.html')?part=BaseUnder&c=0" 360 640
Shot 'car_BaseTop'   "$(Url 'carro.html')?part=BaseTop&c=0" 360 640
for ($w = 0; $w -lt 6; $w++) { Shot "wx_$w" "$(Url 'clima.html')?w=$w" 160 160 }
for ($i = 0; $i -lt 3; $i++) { Shot "menu_$i" "$(Url 'menu.html')?i=$i&on=0" 240 168; Shot "menu_${i}_on" "$(Url 'menu.html')?i=$i&on=1" 240 168 }
"Imagens geradas: $((Get-ChildItem $out -Filter '*.png').Count) em $out"
