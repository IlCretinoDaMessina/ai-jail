@echo off
setlocal DisableDelayedExpansion
title AI Jail - Phase 030 Distribution Review

REM ============================================================
REM PHASE 030 - DEDICATED WSL DISTRIBUTION
REM STATUS: REVIEW ONLY
REM ============================================================
REM No distro creation, execution, import, unregister or shutdown.
REM No filesystem modifications.
REM ============================================================

set "RC=1"
set "STANDALONE=1"

if defined PHASE_LOG set "STANDALONE=0"

REM Accept no arguments, /review, or internal --elevated.
REM Reject all other arguments, including --apply.

if "%~1"=="" goto :check_files

if /I "%~1"=="/review" (
    if not "%~2"=="" goto :usage
    goto :check_files
)

if /I "%~1"=="--elevated" (
    if not "%~2"=="" goto :usage
    goto :check_files
)

goto :usage

:check_files

if not exist "%~dp0_common.bat" (
    echo ERROR: Missing _common.bat
    goto :finish
)

if not exist "%~dp0030-requirements.json" (
    echo ERROR: Missing 030-requirements.json
    goto :finish
)

if not exist "%~dp0030-create-distro.ps1" (
    echo ERROR: Missing 030-create-distro.ps1
    goto :finish
)

if not exist "%~dp0config.env" (
    echo ERROR: Missing config.env
    goto :finish
)

REM Administrator privileges required.
REM Orchestrated and CI execution never launches UAC.

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

REM The elevated child handles its own standalone pause.
goto :return

:not_admin

echo ERROR: Phase 030 requires administrator privileges.
goto :finish

:execute

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0030-create-distro.ps1"

set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" set "RC=1"

goto :finish

:usage

echo ERROR: Unsupported Phase 030 argument.
echo.
echo Accepted:
echo   030-create-distro.bat
echo   030-create-distro.bat /review
echo.
echo Installation and --apply are DISABLED.

:finish

echo.
echo 030-create-distro exit code: %RC%

if "%STANDALONE%"=="1" if not defined AIJAIL_CI pause

:return

endlocal & exit /b %RC%