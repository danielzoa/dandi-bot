@echo off
setlocal
cd /d "%~dp0"
flutter build web --release
echo.
echo Build Web:
echo %CD%\build\web
pause
