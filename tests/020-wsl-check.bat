@echo off
setlocal DisableDelayedExpansion
title AI Jail - Modern WSL Verification

REM =====================================================
REM PHASE 020 - WSL VERIFICATION
REM =====================================================
REM Read-only: wsl.exe --version only.
REM No WSL update, installation, shutdown or distro access.
REM =====================================================

set "RC=1"
set "STANDALONE=1"

if defined PHASE_LOG set "STANDALONE=0"

if "%~1"=="" goto :admin_check

if /I not "%~1"=="--elevated" goto :usage
if not "%~2"=="" goto :usage

:admin_check

REM Require elevation before running system checks.

call "%~dp0_common.bat" :require_admin

if not errorlevel 1 goto :execute

if "%STANDALONE%"=="0" goto :not_admin
if defined AIJAIL_CI goto :not_admin
if /I "%~1"=="--elevated" goto :not_admin

echo Requesting administrator privileges...

set "AIJAIL_ELEVATE_SCRIPT=%~f0"

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$q=[char]34; $a='/d /c '+$q+$q+$env:AIJAIL_ELEVATE_SCRIPT+$q+' --elevated'+$q; try { $p=Start-Process -FilePath $env:ComSpec -ArgumentList $a -Verb RunAs -Wait -PassThru -ErrorAction Stop; exit $p.ExitCode } catch { [Console]::Error.WriteLine('Elevation failed or cancelled: '+$_.Exception.Message); exit 1 }"

set "RC=%ERRORLEVEL%"
set "AIJAIL_ELEVATE_SCRIPT="

if not "%RC%"=="0" pause
goto :return

:not_admin

echo ERROR: Phase 020 requires administrator privileges.
goto :finish

:execute

if not exist "%~dp0020-requirements.json" (
    echo ERROR: Missing 020-requirements.json
    goto :finish
)

if not exist "%~dp0020-wsl-check.ps1" (
    echo ERROR: Missing 020-wsl-check.ps1
    goto :finish
)

if not exist "%~dp0config.env" (
    echo ERROR: Missing config.env
    goto :finish
)

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0020-wsl-check.ps1"

set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" set "RC=1"

goto :finish

:usage

echo ERROR: Unsupported Phase 020 argument.

:finish

echo.
echo 020-wsl-check exit code: %RC%

if "%STANDALONE%"=="1" if not defined AIJAIL_CI pause

:return
endlocal & exit /b %RC%