@echo off
setlocal
cd /d "%~dp0"
echo Godfall Enhanced H35 - Offline Frontend Resource Locator
echo This only scans the local game installation and creates one report.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GodfallFrontendLocator.ps1"
if errorlevel 1 (
  echo ERROR: locator did not complete. Please report the error text.
) else (
  echo Report: GodfallFrontendAssetsReport.txt
)
pause
