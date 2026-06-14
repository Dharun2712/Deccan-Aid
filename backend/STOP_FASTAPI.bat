@echo off
REM STOP script for Smart-Aid FastAPI backend
cd /d "%~dp0"

echo Looking for running uvicorn/app_fastapi processes...

powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'app_fastapi:socket_app' } | ForEach-Object { Write-Output ("Stopping PID {0} - {1}" -f $_.ProcessId, $_.CommandLine); Stop-Process -Id $_.ProcessId -Force }"

echo Done.
exit /b 0
