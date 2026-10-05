
@echo off
setlocal DisableDelayedExpansion
title AI Jail - Phase 080 Sandbox Setup Review

REM ============================================================
REM PHASE 080 - SANDBOX WORKSPACE AND LAUNCHER SETUP
REM STATUS: OFFLINE REVIEW ONLY
REM ============================================================
REM
REM Permitted:
REM   - Validate Phase 080 requirements and configuration
REM   - Generate proposed launchers in memory
REM   - Review intended operations and security invariants
REM
REM Prohibited:
REM   - Invoke WSL
REM   - Execute any installation payload
REM   - Create or change project directories or secrets
REM   - Modify existing launchers
REM   - Treat offline Phase 050 PASS as runtime proof
REM   - Authorize installation or production apply
REM
REM IMPORTANT:
REM   The PowerShell companion must independently reject apply.
REM   This BAT is not the sole security/approval boundary.
REM ============================================================

set "RC=1"
set "STANDALONE=1"

if defined PHASE_LOG set "STANDALONE=0"

REM ------------------------------------------------------------
REM Argument handling
REM ------------------------------------------------------------
REM Standalone double-click: review only.
REM Orchestrated execution: require explicit --review.
REM --elevated is exclusively for internal UAC relaunch.
REM Everything else, including --apply, fails closed.

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

if not exist "%~dp0080-requirements.json" (
    echo ERROR: Missing 080-requirements.json
    goto :finish
)

if not exist "%~dp0080-setup-sandboxes.ps1" (
    echo ERROR: Missing modernized 080-setup-sandboxes.ps1
    goto :finish
)

REM ------------------------------------------------------------
REM Administrator privileges
REM ------------------------------------------------------------
REM Standalone execution can request elevation.
REM Orchestrated or CI execution must not request UAC.

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

echo ERROR: Phase 080 requires administrator privileges.
goto :finish

REM ------------------------------------------------------------
REM Execute offline review
REM ------------------------------------------------------------

:execute

echo ========================================
echo AI JAIL - PHASE 080
echo OFFLINE SANDBOX SETUP REVIEW
echo ========================================
echo.

REM Do not overwrite PHASE_LOG.
REM The orchestrator owns output redirection when supplied.
REM The companion implements review only and rejects apply.

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0080-setup-sandboxes.ps1" -Mode "--review"

set "RC=%ERRORLEVEL%"

REM Only success (0) is accepted for the offline review.
REM Unexpected exit codes fail closed.

if not "%RC%"=="0" set "RC=1"

goto :finish

:usage

echo ERROR: Unsupported Phase 080 argument.
echo.
echo Standalone usage:
echo   080-setup-sandboxes.bat
echo   080-setup-sandboxes.bat --review
echo.
echo Orchestrated usage:
echo   080-setup-sandboxes.bat --review
echo.
echo Installation, --apply, runtime execution and skipping are DISABLED.

:finish

echo.
echo 080-setup-sandboxes exit code: %RC%

if "%STANDALONE%"=="1" if not defined AIJAIL_CI pause

:return

endlocal & exit /b %RC%
