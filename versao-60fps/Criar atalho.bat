@echo off
rem Cria o icone "F1 25 Rafa Pro" na area de trabalho (so precisa rodar uma vez).
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p = (Get-Location).Path;" ^
  "$lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'F1 25 Rafa Pro.lnk';" ^
  "$s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk);" ^
  "$s.TargetPath = 'wscript.exe';" ^
  "$s.Arguments = '\"' + (Join-Path $p 'F1 25 Rafa Pro.vbs') + '\"';" ^
  "$s.WorkingDirectory = $p;" ^
  "$s.IconLocation = (Join-Path $p 'icone.ico');" ^
  "$s.Description = 'F1 25 - Rafa Pro (dash 60 fps)';" ^
  "$s.Save();" ^
  "Write-Host 'Pronto: o icone F1 25 Rafa Pro esta na area de trabalho.'"
pause
