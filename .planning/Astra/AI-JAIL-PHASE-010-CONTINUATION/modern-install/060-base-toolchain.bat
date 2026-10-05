@echo off
setlocal DisableDelayedExpansion
title AI Jail - Phase 060 Base Toolchain Review

REM ============================================================
REM PHASE 060 - BASE LINUX TOOLCHAIN
REM STATUS: OFFLINE REVIEW ONLY
REM ============================================================
REM
REM This version validates the declared toolchain requirements.
REM It does NOT:
REM   - Invoke WSL or execute Linux commands
REM   - Run Phase 050
REM   - Treat Phase 050 offline PASS as runtime proof
REM   - Download or install packages
REM   - Modify the existing distribution
REM   - Authorize subsequent installation phases
REM
REM ============================================================

set "RC=1"
set "STANDALONE=1"

if defined PHASE_LOG set "STANDALONE=0"

REM Accept no arguments, /review, or internal --elevated.
REM All other arguments, including --apply, are rejected.

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

if not exist "%~dp0060-requirements.json" (
    echo ERROR: Missing 060-requirements.json
    goto :finish
)

if not exist "%~dp0060-base-toolchain.ps1" (
    echo ERROR: Missing 060-base-toolchain.ps1
    goto :finish
)

REM Check administrator privileges.
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

echo ERROR: Phase 060 requires administrator privileges.
goto :finish

:execute

echo ========================================
echo AI JAIL - PHASE 060
echo OFFLINE BASE TOOLCHAIN REVIEW
echo ========================================
echo.

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0060-base-toolchain.ps1"

set "RC=%ERRORLEVEL%"

REM Unknown exit codes fail closed.
if not "%RC%"=="0" set "RC=1"

goto :finish

:usage

echo ERROR: Unsupported Phase 060 argument.
echo.
echo Accepted:
echo   060-base-toolchain.bat
echo   060-base-toolchain.bat /review
echo.
echo Runtime verification, installation, skipping and --apply are DISABLED.

:finish

echo.
echo 060-base-toolchain exit code: %RC%

if "%STANDALONE%"=="1" if not defined AIJAIL_CI pause

:return

endlocal & exit /b %RC%