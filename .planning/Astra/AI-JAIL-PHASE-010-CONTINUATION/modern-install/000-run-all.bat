@echo off
setlocal DisableDelayedExpansion
title AI Jail - Modern Installation Orchestrator

set "ROOT=%~dp0"
set "RC=1"
set "MODE="
set "MOCK_WORKSPACE="
set "MOCK_APPROVAL="

REM Mode selection

if /I "%~1"=="/mock-execute" goto :mock_execute
if /I "%~1"=="--mock-execute" goto :mock_execute

if /I "%~1"=="/mock-resume" goto :mock_resume
if /I "%~1"=="--mock-resume" goto :mock_resume

if "%~1"=="" (
    if not "%~2"=="" goto :usage
    set "MODE=/review"
    goto :run
)

if not "%~2"=="" goto :usage

if /I "%~1"=="/review" set "MODE=/review"
if /I "%~1"=="--review" set "MODE=/review"

if /I "%~1"=="/plan" set "MODE=/plan"
if /I "%~1"=="--plan" set "MODE=/plan"

if /I "%~1"=="/apply" set "MODE=/apply"
if /I "%~1"=="--apply" set "MODE=/apply"

if /I "%~1"=="/verify" set "MODE=/verify"
if /I "%~1"=="--verify" set "MODE=/verify"

if not defined MODE goto :usage
goto :run

:mock_execute

if "%~2"=="" goto :usage
if "%~3"=="" goto :usage
if not "%~4"=="" goto :usage

set "MODE=/mock-execute"
set "MOCK_WORKSPACE=%~2"
set "MOCK_APPROVAL=%~3"
goto :run

:mock_resume

if "%~2"=="" goto :usage
if "%~3"=="" goto :usage
if not "%~4"=="" goto :usage

set "MODE=/mock-resume"
set "MOCK_WORKSPACE=%~2"
set "MOCK_APPROVAL=%~3"
goto :run

:run

echo ========================================
echo AI JAIL - MODERN INSTALLATION
echo PHASE 000 - %MODE%
echo ========================================
echo.

REM Required files

if not exist "%ROOT%000-requirements.json" (
    echo ERROR: Missing 000-requirements.json
    goto :finish
)

if not exist "%ROOT%000-review.ps1" (
    echo ERROR: Missing 000-review.ps1
    goto :finish
)

if not exist "%ROOT%000-engine.ps1" (
    echo ERROR: Missing 000-engine.ps1
    goto :finish
)

if not exist "%ROOT%000-config.ps1" (
    echo ERROR: Missing 000-config.ps1
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

if /I "%MODE%"=="/mock-execute" goto :run_mock
if /I "%MODE%"=="/mock-resume" goto :run_mock

REM Engine dispatch

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%ROOT%000-engine.ps1" %MODE%
goto :capture

:run_mock

REM Mock-only dispatch

if not exist "%ROOT%000-orchestration.ps1" (
    echo ERROR: Missing 000-orchestration.ps1
    goto :finish
)

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%ROOT%000-engine.ps1" %MODE% "%MOCK_WORKSPACE%" "%MOCK_APPROVAL%"

:capture

set "RC=%ERRORLEVEL%"

if "%RC%"=="0" goto :finish
if "%RC%"=="3010" goto :finish

set "RC=1"
goto :finish

:usage

echo ERROR: Unsupported argument.
echo.
echo Accepted usage:
echo 000-run-all.bat
echo 000-run-all.bat /review
echo 000-run-all.bat /plan
echo 000-run-all.bat /apply
echo 000-run-all.bat /verify
echo 000-run-all.bat /mock-execute ^<workspace^> ^<approval-path^>
echo 000-run-all.bat /mock-resume ^<workspace^> ^<approval-path^>
echo.
echo PLAN, APPLY and VERIFY remain blocked until implemented.
echo Production execution remains disabled.
echo Resume and skip remain disabled outside the explicit mock resume path.

:finish

echo.
echo ========================================
echo PHASE 000 EXIT CODE: %RC%
echo ========================================

if not defined PHASE_LOG pause

endlocal & exit /b %RC%