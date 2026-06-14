@echo off
REM Simple Backend Launcher - Shows logs in terminal for easy debugging
REM Double-click this file to start the backend and see logs live

cd /d "%~dp0"

echo ============================================
echo    Smart-Aid Backend - Simple Launcher
echo ============================================
echo.
echo Starting backend on http://0.0.0.0:8000
echo Press CTRL+C to stop the server
echo.
echo Logs will appear below:
echo ----------------------------------------
echo.

REM Set UTF-8 encoding for Python output
set "PYTHONUTF8=1"

REM Run uvicorn directly using venv Python (shows output in this window)
venv\Scripts\python.exe -u -m uvicorn app_fastapi:socket_app --host 0.0.0.0 --port 8000 --log-level info

echo.
echo ============================================
echo Backend stopped
echo ============================================
pause
