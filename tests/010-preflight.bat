@echo off
setlocal DisableDelayedExpansion
title AI Jail - Modern Windows Preflight

REM =====================================================
REM PHASE 010 - WINDOWS PREFLIGHT
REM =====================================================
REM Read-only.
REM Standalone: request UAC elevation if necessary.
REM Orchestrated: never start a separate elevation prompt.
REM =====================================================

set "RC=1"
set "STANDALONE=1"

if defined PHASE_LOG set "STANDALONE=0"

if "%~1"=="" goto :admin_check

if /I not "%~1"=="--elevated" goto :usage
if not "%~2"=="" goto :usage

:admin_check

REM Elevation is checked before any system preflight checks.

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
echo ERROR: Phase 010 requires administrator privileges.
goto :finish

:execute

if not exist "%~dp0010-requirements.json" (
    echo ERROR: Missing 010-requirements.json
    goto :finish
)

if not exist "%~dp0010-preflight.ps1" (
    echo ERROR: Missing 010-preflight.ps1
    goto :finish
)

if not exist "%~dp0config.env" (
    echo ERROR: Missing config.env
    goto :finish
)

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0010-preflight.ps1"

set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" set "RC=1"

goto :finish

:usage
echo ERROR: Unsupported Phase 010 argument.

:finish

echo.
echo 010-preflight exit code: %RC%

if "%STANDALONE%"=="1" if not defined AIJAIL_CI pause

:return
endlocal & exit /b %RC%