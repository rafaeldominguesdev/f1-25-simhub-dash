@echo off
chcp 65001 >nul
title F1 25 - Rafa Pro (60 fps)
rem Abre o app com a janela preta (bom para ver erros). O jeito normal e o icone.
cd /d "%~dp0"
where node >nul 2>nul
if errorlevel 1 (
  echo.
  echo   Node.js nao esta instalado. Instalando agora pelo winget...
  echo.
  winget install -e --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
  echo.
  echo   Pronto. Feche esta janela e de dois cliques em Iniciar.bat de novo.
  pause
  exit /b
)
node app\servidor.js
pause
