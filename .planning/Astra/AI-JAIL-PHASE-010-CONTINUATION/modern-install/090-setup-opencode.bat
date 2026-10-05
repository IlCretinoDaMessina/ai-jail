
@echo off
setlocal DisableDelayedExpansion
title AI Jail - Phase 090 OpenCode Review

REM ============================================================
REM PHASE 090 - OPENCODE INSTALLATION
REM STATUS: OFFLINE REVIEW ONLY
REM ============================================================
REM
REM Permitted:
REM   - Validate modernization requirements
REM   - Review the historical experimental manifest
REM   - Validate OpenCode version and installation policy
REM   - Inspect declared acceptance and approval gates
REM
REM Prohibited:
REM   - Invoke WSL
REM   - Install or modify the existing OpenCode pilot
REM   - Download or install packages
REM   - Invoke OpenCode or contact model providers
REM   - Modify launchers, runtime configuration or secrets
REM   - Authorize production installation
REM
REM The PowerShell companion MUST independently reject apply
REM and pilot execution. This BAT is not the sole safety gate.
REM ============================================================

set "RC=1"
set "STANDALONE=1"

if defined PHASE_LOG set "STANDALONE=0"

REM ------------------------------------------------------------
REM Argument validation
REM ------------------------------------------------------------
REM Double-click: offline review.
REM Orchestrated: require an explicit --review argument.
REM --elevated is reserved exclusively for UAC relaunch.
REM Reject --pilot, --apply and everything else.

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

:check_files

if not exist "%~dp0_common.bat" (
    echo ERROR: Missing _common.bat
    goto :finish
)

if not exist "%~dp0config.env" (
    echo ERROR: Missing config.env
    goto :finish
)

if not exist "%~dp0090-requirements.json" (
    echo ERROR: Missing 090-requirements.json
    goto :finish
)

if not exist "%~dp0090-setup-opencode.ps1" (
    echo ERROR: Missing modernized 090-setup-opencode.ps1
    goto :finish
)

REM The original pilot manifest is historical evidence.
REM It must not authorize installation or replace the
REM modernized requirements file.

REM ------------------------------------------------------------
REM Administrator privileges
REM ------------------------------------------------------------
REM Standalone execution may request elevation.
REM Orchestrated and CI execution must not request UAC.

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

echo ERROR: Phase 090 requires administrator privileges.
goto :finish

REM ------------------------------------------------------------
REM Execute offline review
REM ------------------------------------------------------------

:execute

echo ========================================
echo AI JAIL - PHASE 090
echo OFFLINE OPENCODE INSTALLATION REVIEW
echo ========================================
echo.

REM Preserve any PHASE_LOG provided by the orchestrator.
REM Do not initialize another log or redirect its output.
REM The companion has no installation or pilot execution path.

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0090-setup-opencode.ps1" -Mode "--review"

set "RC=%ERRORLEVEL%"

REM Fail closed on unexpected exit codes.
if not "%RC%"=="0" set "RC=1"

goto :finish

:usage

echo ERROR: Unsupported Phase 090 argument.
echo.
echo Standalone usage:
echo   090-setup-opencode.bat
echo   090-setup-opencode.bat --review
echo.
echo Orchestrated usage:
echo   090-setup-opencode.bat --review
echo.
echo Pilot installation, downloads, --apply and skipping are DISABLED.

:finish

echo.
echo 090-setup-opencode exit code: %RC%

if "%STANDALONE%"=="1" if not defined AIJAIL_CI pause

:return

endlocal & exit /b %RC%
