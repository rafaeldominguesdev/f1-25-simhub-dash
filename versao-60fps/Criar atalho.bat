@echo off
chcp 65001 >nul
rem Cria o icone "F1 25 Rafa Pro" na area de trabalho. Compila o exe antes, se faltar.
cd /d "%~dp0"
if not exist "F1 25 Rafa Pro.exe" call "Compilar exe.bat" /quieto
if not exist "F1 25 Rafa Pro.exe" exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p = (Get-Location).Path;" ^
  "$exe = Join-Path $p 'F1 25 Rafa Pro.exe';" ^
  "$lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'F1 25 Rafa Pro.lnk';" ^
  "$s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk);" ^
  "$s.TargetPath = $exe;" ^
  "$s.Arguments = '';" ^
  "$s.WorkingDirectory = $p;" ^
  "$s.IconLocation = $exe + ',0';" ^
  "$s.Description = 'F1 25 - Rafa Pro (dash 60 fps)';" ^
  "$s.Save();" ^
  "Write-Host '';" ^
  "Write-Host '  Pronto: o icone F1 25 Rafa Pro esta na area de trabalho.'"
pause
