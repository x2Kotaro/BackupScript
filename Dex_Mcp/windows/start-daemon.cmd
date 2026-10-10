@echo off
REM Dex_Mcp daemon - keeps the bridge listener alive across Claude sessions.
REM Claude connects to it over http://127.0.0.1:8790/mcp instead of spawning it as a child,
REM so closing a session no longer drops DexBridge inside Roblox.
REM
REM Run once per boot. To start it automatically: press Win+R, type  shell:startup ,
REM and drop a shortcut to this file in the folder that opens.

cd /d "%~dp0"

powershell -NoProfile -Command "try { (New-Object Net.WebClient).DownloadString('http://127.0.0.1:8790/ping') | Out-Null; exit 0 } catch { exit 1 }"
if %ERRORLEVEL%==0 (
  echo [dex-mcp] already running on 127.0.0.1:8790
  timeout /t 2 >nul
  exit /b 0
)

echo [dex-mcp] starting daemon on 127.0.0.1:8790
node server.js --daemon
echo.
echo [dex-mcp] daemon exited. Press any key to close.
pause >nul
