@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-mobile-api-ip.ps1" %*
endlocal
