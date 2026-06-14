@echo off
REM START script for LifeLink / MediConnect FastAPI backend
REM AI Providers: Google Gemini & Sarvam AI
REM Core backend service configuration.

cd /d "%~dp0"

echo ============================================
echo  LifeLink / MediConnect FastAPI Backend
echo  AI Providers: Google Gemini & Sarvam AI
echo ============================================

REM Force Python produce UTF-8 output on Windows consoles
set "PYTHONUTF8=1"

REM ── Load GEMINI_API_KEY from backend\.env, then ..\\.env as fallback ──
if not defined GEMINI_API_KEY (
    if exist "%CD%\.env" (
        for /f "usebackq tokens=1,* delims==" %%A in ("%CD%\.env") do (
            if /I "%%A"=="GEMINI_API_KEY"  set "GEMINI_API_KEY=%%B"
            if /I "%%A"=="GEMINI_MODEL"    set "GEMINI_MODEL=%%B"
            if /I "%%A"=="SARVAM_API_KEY"  set "SARVAM_API_KEY=%%B"
        )
    )
)
if not defined GEMINI_API_KEY (
    if exist "%CD%\..\.env" (
        for /f "usebackq tokens=1,* delims==" %%A in ("%CD%\..\.env") do (
            if /I "%%A"=="GEMINI_API_KEY"  set "GEMINI_API_KEY=%%B"
            if /I "%%A"=="GEMINI_MODEL"    set "GEMINI_MODEL=%%B"
            if /I "%%A"=="SARVAM_API_KEY"  set "SARVAM_API_KEY=%%B"
        )
    )
)

REM ── Set default models if not loaded from env ──
if not defined GEMINI_MODEL set "GEMINI_MODEL=gemini-1.5-flash"

REM ── Validate GEMINI_API_KEY ──
if not defined GEMINI_API_KEY (
    echo [ERROR] GEMINI_API_KEY not set. Image analysis and chatbot will fail.
    echo [HINT]  Add GEMINI_API_KEY to backend\.env or project-root .env.
) else (
    echo [INFO] GEMINI_API_KEY detected. Gemini services are enabled.
    echo [INFO] GEMINI_MODEL: %GEMINI_MODEL%
)

REM ── PYTHONPATH ──
set "PYTHONPATH=%CD%"

REM ── Check for Python ──
where python >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found in PATH. Please install Python 3.9+ and add to PATH.
    pause
    exit /b 1
)

REM ── Create virtual environment if missing ──
if not exist "venv\Scripts\activate.bat" (
    echo [INFO] Virtual environment not found. Creating venv...
    python -m venv venv
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment
        pause
        exit /b 1
    )
)

REM ── Activate venv ──
call venv\Scripts\activate.bat
if errorlevel 1 (
    echo [ERROR] Failed to activate virtual environment
    pause
    exit /b 1
)

REM ── Upgrade pip ──
echo [INFO] Upgrading pip (best-effort)...
python -m pip install --upgrade pip setuptools wheel >nul 2>&1

REM ── Install requirements ──
if exist "requirements.txt" (
    echo [INFO] Installing/Updating Python requirements from requirements.txt...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo [WARNING] Pip install returned non-zero exit code. Continuing anyway.
    )
) else (
    echo [WARNING] requirements.txt not found. Skipping pip install.
)

if exist "requirements_fastapi.txt" (
    echo [INFO] Installing/Updating FastAPI requirements...
    pip install -r requirements_fastapi.txt
    if errorlevel 1 (
        echo [WARNING] Pip install returned non-zero exit code. Continuing anyway.
    )
)

REM ── Ensure FastAPI and Uvicorn ──
echo [INFO] Ensuring FastAPI and Uvicorn are installed (best-effort)...
pip install fastapi "uvicorn[standard]" >nul 2>&1 || echo [WARNING] Could not ensure FastAPI/uvicorn

REM ── Prepare logs directory ──
if not exist "logs" mkdir logs

echo.
echo Server will be available at:
echo   - API Docs:      http://localhost:8000/docs
echo   - Gemini Health: http://localhost:8000/api/gemini/health
echo   - Image Analyze: POST http://localhost:8000/api/accident-image/analyze
echo Logs: %CD%\logs\uvicorn.log
echo Starting server in a new window...

REM ── Start uvicorn ──
powershell -NoProfile -Command "$env:GEMINI_API_KEY='%GEMINI_API_KEY%'; $env:GEMINI_MODEL='%GEMINI_MODEL%'; $env:SARVAM_API_KEY='%SARVAM_API_KEY%'; Start-Process -FilePath '%CD%\venv\Scripts\python.exe' -ArgumentList '-u', '-m', 'uvicorn', 'app_fastapi:socket_app', '--host', '0.0.0.0', '--port', '8000', '--log-level', 'info' -WindowStyle Minimized -RedirectStandardOutput '%CD%\logs\uvicorn.log' -RedirectStandardError '%CD%\logs\uvicorn_err.log' -EnvironmentVariables @{'GEMINI_API_KEY'='%GEMINI_API_KEY%'; 'GEMINI_MODEL'='%GEMINI_MODEL%'; 'SARVAM_API_KEY'='%SARVAM_API_KEY%'}"

echo [INFO] Uvicorn starting in a separate window. Monitor: %CD%\logs\uvicorn.log
echo.
exit /b 0
