@echo off
setlocal
cd /d "%~dp0"
flutter build windows --release
echo.
echo Executavel:
echo %CD%\build\windows\x64\runner\Release\dandi_bot.exe
pause
