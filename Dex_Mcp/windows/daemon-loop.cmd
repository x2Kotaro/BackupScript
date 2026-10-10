@echo off
REM Dex_Mcp watchdog loop. Starts the daemon and restarts it if node ever exits.
REM Never launches a second node while the port already answers, so running this
REM twice is harmless. Launch it hidden via start-daemon-hidden.vbs.

cd /d "%~dp0"

:loop
powershell -NoProfile -Command "try { (New-Object Net.WebClient).DownloadString('http://127.0.0.1:8790/ping') | Out-Null; exit 0 } catch { exit 1 }"
if %ERRORLEVEL%==0 goto wait
node server.js --daemon
:wait
timeout /t 10 /nobreak >nul
goto loop
