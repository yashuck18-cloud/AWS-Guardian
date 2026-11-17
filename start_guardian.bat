@echo off
title AWS Guardian - Backend and Ngrok Runner
color 0A

echo ========================================================
echo               AWS GUARDIAN - BACKEND LAUNCHER           
echo ========================================================
echo.

:: 1. Check & Start XAMPP MySQL if needed
netstat -ano | findstr 127.0.0.1:3306 >nul 2>&1
if %errorlevel% neq 0 (
    echo [1/3] MySQL is not running on port 3306. Starting XAMPP MySQL...
    if exist "C:\xampp\mysql\bin\mysqld.exe" (
        start "" /B "C:\xampp\mysql\bin\mysqld.exe" --defaults-file=C:\xampp\mysql\bin\my.ini --standalone
        timeout /t 3 /nobreak >nul
    ) else (
        echo [WARNING] C:\xampp\mysql\bin\mysqld.exe not found. Please ensure MySQL is started.
    )
) else (
    echo [1/3] MySQL is already running on port 3306.
)

:: 2. Start Django Backend Server in new window
echo [2/3] Starting Django backend server on 0.0.0.0:8000...
start "AWS Guardian Django Server" cmd /k "cd /d %~dp0backend && .\venv\Scripts\activate && python manage.py runserver 0.0.0.0:8000"

timeout /t 3 /nobreak >nul

:: 3. Check for connected Android device and reverse port 8000
echo [3/4] Checking Android device connectivity...
if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
    "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:8000 tcp:8000 >nul 2>&1
    echo       Android USB port 8000 reverse enabled.
)

:: 4. Start Ngrok Tunnel in new window (optional)
echo [4/4] Starting Ngrok tunnel (optional fallback)...
start "AWS Guardian Ngrok Tunnel" cmd /k "ngrok http 8000 --url=utter-settle-sedation.ngrok-free.dev"

echo.
echo ========================================================
echo  All services ready!
echo  Local API:   http://127.0.0.1:8000/api/health/
echo  LAN API:     http://10.42.173.165:8000/api/health/
echo  Public URL:  https://utter-settle-sedation.ngrok-free.dev/api/health/
echo ========================================================
pause
