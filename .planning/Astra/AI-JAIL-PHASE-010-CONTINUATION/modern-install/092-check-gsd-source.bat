
@echo off
setlocal DisableDelayedExpansion
title AI Jail - Phase 092 GSD Core Review

REM ============================================================
REM PHASE 092 - GSD CORE INSTALLATION AND OPENCODE INTEGRATION
REM STATUS: OFFLINE REVIEW ONLY
REM ============================================================
REM
REM This is NOT the original executable pilot installer.
REM
REM Permitted:
REM   - Validate Phase 092 modernization requirements
REM   - Validate the historical GSD baseline declaration
REM   - Review source, dependency and generation requirements
REM   - Review installation, migration and rollback policies
REM   - Check security and approval restrictions
REM
REM Prohibited:
REM   - Invoke WSL
REM   - Access or modify the existing GSD pilot
REM   - Use historical staging or generation directories
REM   - Download packages or generate GSD files
REM   - Install dependencies or modify OpenCode configuration
REM   - Migrate existing runtime commands
REM   - Start the GSD MCP server
REM   - Authorize production installation
REM
REM The PowerShell companion independently enforces
REM review-only execution.
REM ============================================================

set "RC=1"
set "STANDALONE=1"

if defined PHASE_LOG set "STANDALONE=0"

REM ------------------------------------------------------------
REM Argument validation
REM ------------------------------------------------------------
REM Double-click: offline review.
REM Explicit --review: permitted.
REM Orchestrated execution requires explicit --review.
REM --elevated: internal standalone UAC relaunch only.
REM --pilot, --install, --apply and extra arguments: rejected.

if "%~1"=="" (
    if "%STANDALONE%"=="0" goto :usage
    goto :check_files
)

if /I "%~1"=="--review" (
    if not "%~2"=="" goto :usage
    goto :check_files
)

if /I "%~1"=="--elevated" (
    if not "%~2"=="" goto :usage
    if "%STANDALONE%"=="0" goto :usage
    goto :check_files
)

goto :usage

REM ------------------------------------------------------------
REM Validate required local files
REM ------------------------------------------------------------

:check_files

if not exist "%~dp0_common.bat" (
    echo ERROR: Missing _common.bat
    goto :finish
)

if not exist "%~dp0config.env" (
    echo ERROR: Missing config.env
    goto :finish
)

if not exist "%~dp0092-requirements.json" (
    echo ERROR: Missing 092-requirements.json
    goto :finish
)

if not exist "%~dp0092-check-gsd-source.ps1" (
    echo ERROR: Missing modernized 092-check-gsd-source.ps1
    goto :finish
)

REM ------------------------------------------------------------
REM Administrator privileges
REM ------------------------------------------------------------
REM Preserve the modern installer elevation convention.
REM Orchestrated execution and CI must never request UAC.

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

echo ERROR: Phase 092 requires administrator privileges.
goto :finish

REM ------------------------------------------------------------
REM Execute offline review
REM ------------------------------------------------------------

:execute

echo ========================================
echo AI JAIL - PHASE 092
echo OFFLINE GSD CORE INSTALLATION REVIEW
echo ========================================
echo.

REM Preserve PHASE_LOG if supplied by the orchestrator.
REM No downloads, WSL operations or state changes occur here.

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0092-check-gsd-source.ps1" -Mode "--review"

set "RC=%ERRORLEVEL%"

REM Only exit code 0 is accepted as a successful review.
REM Fail closed on all other or unexpected exit codes.

if not "%RC%"=="0" set "RC=1"

goto :finish

REM ------------------------------------------------------------
REM Invalid arguments
REM ------------------------------------------------------------

:usage

echo ERROR: Unsupported Phase 092 argument.
echo.
echo Standalone usage:
echo   092-check-gsd-source.bat
echo   092-check-gsd-source.bat --review
echo.
echo Orchestrated usage:
echo   092-check-gsd-source.bat --review
echo.
echo Pilot installation, generation, downloads and --apply are DISABLED.

REM ------------------------------------------------------------
REM Exit handling
REM ------------------------------------------------------------

:finish

echo.
echo 092-check-gsd-source exit code: %RC%

if "%STANDALONE%"=="1" if not defined AIJAIL_CI pause

:return

endlocal & exit /b %RC%
