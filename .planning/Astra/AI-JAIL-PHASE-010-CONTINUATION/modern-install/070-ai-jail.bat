@echo off
setlocal DisableDelayedExpansion
title AI Jail - Phase 070 Sandbox Engine Review

REM ============================================================
REM PHASE 070 - AI JAIL SANDBOX ENGINE
REM STATUS: OFFLINE REVIEW ONLY
REM ============================================================
REM
REM Permitted:
REM   - Validate Phase 070 requirements
REM   - Review toolchain and sandbox security policy
REM   - Review version and installation policy
REM
REM Prohibited:
REM   - Invoke WSL
REM   - Execute Phase 050 or treat its offline PASS as proof
REM   - Execute the sandbox engine
REM   - Download or install packages
REM   - Modify the existing distribution
REM   - Authorize production installation
REM
REM ============================================================

set "RC=1"
set "STANDALONE=1"

if defined PHASE_LOG set "STANDALONE=0"

REM Accept no arguments or /review.
REM --elevated is exclusively for the internal UAC relaunch.
REM Reject --apply, --runtime, /skip and all unknown arguments.

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

if not exist "%~dp0070-requirements.json" (
    echo ERROR: Missing 070-requirements.json
    goto :finish
)

if not exist "%~dp0070-ai-jail.ps1" (
    echo ERROR: Missing 070-ai-jail.ps1
    goto :finish
)

REM Administrator privileges are required by Phase 070 policy.
REM Never request UAC during orchestrated or CI execution.

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

echo ERROR: Phase 070 requires administrator privileges.
goto :finish

:execute

echo ========================================
echo AI JAIL - PHASE 070
echo OFFLINE SANDBOX ENGINE REVIEW
echo ========================================
echo.

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0070-ai-jail.ps1"

set "RC=%ERRORLEVEL%"

REM Fail closed on unexpected exit codes.
if not "%RC%"=="0" set "RC=1"

goto :finish

:usage

echo ERROR: Unsupported Phase 070 argument.
echo.
echo Accepted:
echo   070-ai-jail.bat
echo   070-ai-jail.bat /review
echo.
echo Runtime verification, installation, skipping and --apply are DISABLED.

:finish

echo.
echo 070-ai-jail exit code: %RC%

if "%STANDALONE%"=="1" if not defined AIJAIL_CI pause

:return

endlocal & exit /b %RC%