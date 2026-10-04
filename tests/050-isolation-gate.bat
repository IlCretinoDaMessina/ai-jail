@echo off
setlocal DisableDelayedExpansion
title AI Jail - Phase 050 Isolation Gate Review

REM ============================================================
REM PHASE 050 - HARD ISOLATION GATE
REM STATUS: OFFLINE REVIEW ONLY
REM ============================================================
REM
REM This entry point does NOT:
REM   - Execute commands inside WSL
REM   - Launch or terminate any distribution
REM   - Modify Linux or Windows configuration
REM   - Run the hard isolation gate
REM   - Authorize subsequent installation phases
REM
REM The offline review can validate the declared policy,
REM but CANNOT satisfy the runtime isolation gate.
REM ============================================================

set "RC=1"
set "STANDALONE=1"

if defined PHASE_LOG set "STANDALONE=0"

REM Accept no arguments or /review.
REM --elevated is reserved for internal UAC relaunch.
REM Reject everything else, including --apply and --runtime.

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

if not exist "%~dp0config.env" (
    echo ERROR: Missing config.env
    goto :finish
)

if not exist "%~dp0050-requirements.json" (
    echo ERROR: Missing 050-requirements.json
    goto :finish
)

if not exist "%~dp0050-isolation-gate.ps1" (
    echo ERROR: Missing 050-isolation-gate.ps1
    goto :finish
)

REM Administrator privileges are required by the review policy.
REM Orchestrated and CI execution must never request UAC.

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

echo ERROR: Phase 050 requires administrator privileges.
goto :finish

:execute

echo ========================================
echo AI JAIL - PHASE 050
echo OFFLINE ISOLATION POLICY REVIEW
echo ========================================
echo.

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0050-isolation-gate.ps1"

set "RC=%ERRORLEVEL%"

REM Unknown exit codes fail closed.
if not "%RC%"=="0" set "RC=1"

goto :finish

:usage

echo ERROR: Unsupported Phase 050 argument.
echo.
echo Accepted:
echo   050-isolation-gate.bat
echo   050-isolation-gate.bat /review
echo.
echo Runtime verification, installation, skipping and --apply are DISABLED.

:finish

echo.
echo 050-isolation-gate exit code: %RC%

if "%STANDALONE%"=="1" if not defined AIJAIL_CI pause

:return

endlocal & exit /b %RC%