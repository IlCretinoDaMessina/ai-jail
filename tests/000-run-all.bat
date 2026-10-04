@echo off
setlocal DisableDelayedExpansion
title AI Jail - Modern Installation Orchestrator

REM =====================================================
REM PHASE 000 - MODERN INSTALLATION ORCHESTRATOR
REM Status: REVIEW ONLY
REM =====================================================
REM Installation and production apply are disabled.
REM No WSL invocation, downloads or installation actions.
REM =====================================================

set "ROOT=%~dp0"
set "RC=1"

REM Accept no argument or exactly /review.
if "%~1"=="" goto :review
if /I not "%~1"=="/review" goto :usage
if not "%~2"=="" goto :usage

:review

echo ========================================
echo AI JAIL - MODERN INSTALLATION
echo PHASE 000 - REVIEW ONLY
echo ========================================
echo.

if not exist "%ROOT%000-requirements.json" (
    echo ERROR: Missing 000-requirements.json
    goto :finish
)

if not exist "%ROOT%000-review.ps1" (
    echo ERROR: Missing 000-review.ps1
    goto :finish
)

if not exist "%ROOT%_common.bat" (
    echo ERROR: Missing _common.bat
    goto :finish
)

if not exist "%ROOT%config.env" (
    echo ERROR: Missing config.env
    goto :finish
)

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%ROOT%000-review.ps1"

set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" set "RC=1"

goto :finish

:usage
echo ERROR: Unsupported argument.
echo.
echo Accepted usage:
echo 000-run-all.bat
echo 000-run-all.bat /review
echo.
echo Installation, /from, /skip and --apply are DISABLED.

:finish
echo.
echo ========================================
echo PHASE 000 EXIT CODE: %RC%
echo ========================================

if not defined PHASE_LOG pause

endlocal & exit /b %RC%