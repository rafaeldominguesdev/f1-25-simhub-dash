@echo off
chcp 65001 >nul
rem Compila o "F1 25 Rafa Pro.exe" (so precisa rodar uma vez, ou depois de atualizar o launcher).
cd /d "%~dp0"
set "CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" (
  echo.
  echo   Nao achei o compilador do .NET Framework no Windows.
  echo   Use o Iniciar.bat para abrir o app.
  pause
  exit /b 1
)
"%CSC%" /nologo /codepage:65001 /target:winexe /optimize /win32icon:app\icone.ico /r:System.Windows.Forms.dll /out:"F1 25 Rafa Pro.exe" launcher\Launcher.cs
if errorlevel 1 (
  echo.
  echo   Deu erro ao compilar. Mande um print desta janela.
  pause
  exit /b 1
)
echo.
echo   Pronto: "F1 25 Rafa Pro.exe" criado.
if /i not "%~1"=="/quieto" pause
