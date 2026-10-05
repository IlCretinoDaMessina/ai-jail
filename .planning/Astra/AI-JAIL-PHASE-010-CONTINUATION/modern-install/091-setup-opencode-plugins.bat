
@echo off
setlocal DisableDelayedExpansion
title AI Jail - Phase 091 OpenCode Plugin Review

REM ============================================================
REM PHASE 091 - OPENCODE TPS METER PLUGIN
REM STATUS: OFFLINE REVIEW ONLY
REM ============================================================
REM
REM Permitted:
REM   - Validate Phase 091 modernization requirements
REM   - Review historical TPS Meter version and official method
REM   - Validate future plugin installation and integrity policy
REM   - Review registration, cache and runtime approval gates
REM
REM Prohibited:
REM   - Invoke WSL or the existing OpenCode pilot
REM   - Download or install a plugin
REM   - Run opencode plug
REM   - Modify the plugin cache or runtime configuration
REM   - Contact provider services
REM   - Modify the existing OpenCode/GSD/TPS pilot
REM   - Authorize production installation
REM
REM The PowerShell companion must independently enforce
REM review-only operation. This BAT is not the sole safety gate.
REM ============================================================

set "RC=1"
set "STANDALONE=1"

if defined PHASE_LOG set "STANDALONE=0"

REM ------------------------------------------------------------
REM Argument validation
REM ------------------------------------------------------------
REM Double-click: offline review.
REM Explicit --review: permitted.
REM Orchestrated: --review must be explicit.
REM --elevated: reserved for standalone UAC relaunch.
REM Everything else is rejected.

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

if not exist "%~dp0091-requirements.json" (
    echo ERROR: Missing 091-requirements.json
    goto :finish
)

if not exist "%~dp0091-setup-opencode-plugins.ps1" (
    echo ERROR: Missing modernized 091-setup-opencode-plugins.ps1
    goto :finish
)

REM ------------------------------------------------------------
REM Administrator privileges
REM ------------------------------------------------------------
REM Standalone execution may request elevation.
REM Orchestrated execution must never request UAC.
REM CI must never request UAC.

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

REM Elevated child handles its own standalone pause.
goto :return

:not_admin

echo ERROR: Phase 091 requires administrator privileges.
goto :finish

REM ------------------------------------------------------------
REM Execute offline review
REM ------------------------------------------------------------

:execute

echo ========================================
echo AI JAIL - PHASE 091
echo OFFLINE OPENCODE PLUGIN REVIEW
echo ========================================
echo.

REM Preserve PHASE_LOG when supplied by the orchestrator.
REM Do not start an independent log or redirect its output.
REM No Linux commands or installation operations exist here.

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0091-setup-opencode-plugins.ps1" -Mode "--review"

set "RC=%ERRORLEVEL%"

REM Fail closed on unexpected exit codes.
if not "%RC%"=="0" set "RC=1"

goto :finish

REM ------------------------------------------------------------
REM Invalid arguments
REM ------------------------------------------------------------

:usage

echo ERROR: Unsupported Phase 091 argument.
echo.
echo Standalone usage:
echo   091-setup-opencode-plugins.bat
echo   091-setup-opencode-plugins.bat --review
echo.
echo Orchestrated usage:
echo   091-setup-opencode-plugins.bat --review
echo.
echo Pilot installation, downloads, --apply and skipping are DISABLED.

REM ------------------------------------------------------------
REM Exit handling
REM ------------------------------------------------------------

:finish

echo.
echo 091-setup-opencode-plugins exit code: %RC%

if "%STANDALONE%"=="1" if not defined AIJAIL_CI pause

:return

endlocal & exit /b %RC%
