@echo off
chcp 65001 >nul 2>&1
title Nexus
setlocal enabledelayedexpansion

echo.
echo   ╔══════════════════════════════════╗
echo   ║         Nexus for Windows        ║
echo   ╚══════════════════════════════════╝
echo.

:: Find this script's directory
set "NEXUS_DIR=%~dp0"
cd /d "%NEXUS_DIR%"

:: ─── Check Python ────────────────────────────────────────
where python >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYVER=%%i
    echo   Python: !PYVER!
    set "PYTHON=python"
    goto :python_found
)

where python3 >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('python3 --version 2^>^&1') do set PYVER=%%i
    echo   Python: !PYVER!
    set "PYTHON=python3"
    goto :python_found
)

echo   [ERROR] Python 3 wurde nicht gefunden.
echo.
echo   Bitte installiere Python 3.9+ von:
echo   https://www.python.org/downloads/
echo.
echo   WICHTIG: Setze bei der Installation den Haken bei
echo   "Add Python to PATH"
echo.
pause
exit /b 1

:python_found

:: ─── Setup venv ──────────────────────────────────────────
if not exist "venv\Scripts\python.exe" (
    echo.
    echo   → Erstelle Python-Umgebung...
    %PYTHON% -m venv venv
    if %errorlevel% neq 0 (
        echo   [ERROR] Konnte keine virtuelle Umgebung erstellen.
        pause
        exit /b 1
    )
)

set "VENV_PYTHON=venv\Scripts\python.exe"

:: ─── Install dependencies ────────────────────────────────
:: Hash-check: only pip install if requirements changed
set "HASH_FILE=venv\.req_hash"
set "NEED_INSTALL=0"

if not exist "%HASH_FILE%" (
    set "NEED_INSTALL=1"
) else (
    for /f "tokens=*" %%h in ('certutil -hashfile requirements.txt SHA256 2^>nul ^| findstr /v "hash certutil"') do (
        set "CURRENT_HASH=%%h"
    )
    set /p SAVED_HASH=<"%HASH_FILE%"
    if "!CURRENT_HASH!" neq "!SAVED_HASH!" set "NEED_INSTALL=1"
)

if "!NEED_INSTALL!" equ "1" (
    echo   → Installiere Abhaengigkeiten (kann 1-2 Minuten dauern^)...
    "%VENV_PYTHON%" -m pip install --upgrade pip >nul 2>&1
    "%VENV_PYTHON%" -m pip install -r requirements.txt >nul 2>&1
    if %errorlevel% neq 0 (
        echo   [ERROR] pip install fehlgeschlagen.
        pause
        exit /b 1
    )
    for /f "tokens=*" %%h in ('certutil -hashfile requirements.txt SHA256 2^>nul ^| findstr /v "hash certutil"') do (
        echo %%h>"%HASH_FILE%"
    )
    echo   ✓ Abhaengigkeiten installiert.
)

:: ─── Create data directory ───────────────────────────────
if not exist "data" mkdir data

:: ─── Start Flask server ──────────────────────────────────
echo.
echo   → Starte Nexus...

:: Kill any stale server on port 5050
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":5050 " ^| findstr "LISTENING" 2^>nul') do (
    taskkill /PID %%p /F >nul 2>&1
)

:: Start server in background
set "NEXUS_HOST=127.0.0.1"
set "FLASK_ENV=production"
start /b "" "%VENV_PYTHON%" -m app.app >nul 2>&1

:: Wait for server to start
set "RETRIES=0"
:wait_loop
if !RETRIES! geq 30 (
    echo   [ERROR] Server konnte nicht gestartet werden.
    pause
    exit /b 1
)
timeout /t 1 /nobreak >nul
powershell -command "try { (Invoke-WebRequest -Uri 'http://127.0.0.1:5050' -UseBasicParsing -TimeoutSec 1).StatusCode } catch { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    set /a RETRIES+=1
    goto :wait_loop
)

echo.
echo   ╔══════════════════════════════════╗
echo   ║   ✓ Nexus laeuft!               ║
echo   ║   → http://localhost:5050/hub    ║
echo   ╚══════════════════════════════════╝
echo.
echo   Dieses Fenster offen lassen.
echo   Zum Beenden: Fenster schliessen oder Ctrl+C
echo.

:: Open browser
start "" "http://localhost:5050/hub"

:: Keep running until user closes
:keep_alive
timeout /t 5 /nobreak >nul
:: Check if server is still running
powershell -command "try { (Invoke-WebRequest -Uri 'http://127.0.0.1:5050' -UseBasicParsing -TimeoutSec 2).StatusCode } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 goto :keep_alive

echo.
echo   Server beendet.
pause
