@echo off
REM START script for LifeLink / MediConnect FastAPI backend
REM AI Provider: Groq exclusively (meta-llama/llama-4-scout-17b-16e-instruct)
REM No Gemini. No deprecated models.

cd /d "%~dp0"

echo ============================================
echo  LifeLink / MediConnect FastAPI Backend
echo  AI Provider: Groq (llama-4-scout)
echo ============================================

REM Force Python produce UTF-8 output on Windows consoles
set "PYTHONUTF8=1"

REM ── Load GROQ_API_KEY from backend\.env, then ..\\.env as fallback ──
if not defined GROQ_API_KEY (
    if exist "%CD%\.env" (
        for /f "usebackq tokens=1,* delims==" %%A in ("%CD%\.env") do (
            if /I "%%A"=="GROQ_API_KEY"  set "GROQ_API_KEY=%%B"
            if /I "%%A"=="VISION_MODEL"  set "VISION_MODEL=%%B"
            if /I "%%A"=="CHAT_MODEL"    set "CHAT_MODEL=%%B"
        )
    )
)
if not defined GROQ_API_KEY (
    if exist "%CD%\..\.env" (
        for /f "usebackq tokens=1,* delims==" %%A in ("%CD%\..\.env") do (
            if /I "%%A"=="GROQ_API_KEY"  set "GROQ_API_KEY=%%B"
            if /I "%%A"=="VISION_MODEL"  set "VISION_MODEL=%%B"
            if /I "%%A"=="CHAT_MODEL"    set "CHAT_MODEL=%%B"
        )
    )
)

REM ── Set default models if not loaded from env ──
if not defined VISION_MODEL set "VISION_MODEL=meta-llama/llama-4-scout-17b-16e-instruct"
if not defined CHAT_MODEL   set "CHAT_MODEL=meta-llama/llama-4-scout-17b-16e-instruct"

REM ── Validate GROQ_API_KEY ──
if not defined GROQ_API_KEY (
    echo [ERROR] GROQ_API_KEY not set. Image analysis and chatbot will fail.
    echo [HINT]  Add GROQ_API_KEY to backend\.env or project-root .env.
) else (
    echo [INFO] GROQ_API_KEY detected. Groq services are enabled.
    echo [INFO] VISION_MODEL: %VISION_MODEL%
    echo [INFO] CHAT_MODEL:   %CHAT_MODEL%
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
echo   - Groq Health:   http://localhost:8000/api/groq/health
echo   - Image Analyze: POST http://localhost:8000/api/accident-image/analyze
echo Logs: %CD%\logs\uvicorn.log
echo Starting server in a new window...

REM ── Start uvicorn ──
powershell -NoProfile -Command "$env:GROQ_API_KEY='%GROQ_API_KEY%'; $env:VISION_MODEL='%VISION_MODEL%'; $env:CHAT_MODEL='%CHAT_MODEL%'; Start-Process -FilePath '%CD%\venv\Scripts\python.exe' -ArgumentList '-u', '-m', 'uvicorn', 'app_fastapi:socket_app', '--host', '0.0.0.0', '--port', '8000', '--log-level', 'info' -WindowStyle Minimized -RedirectStandardOutput '%CD%\logs\uvicorn.log' -RedirectStandardError '%CD%\logs\uvicorn_err.log' -EnvironmentVariables @{'GROQ_API_KEY'='%GROQ_API_KEY%'; 'VISION_MODEL'='%VISION_MODEL%'; 'CHAT_MODEL'='%CHAT_MODEL%'}"

echo [INFO] Uvicorn starting in a separate window. Monitor: %CD%\logs\uvicorn.log
echo.
exit /b 0
