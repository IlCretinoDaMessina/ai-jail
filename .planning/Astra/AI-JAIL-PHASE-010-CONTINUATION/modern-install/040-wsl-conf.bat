@echo off
setlocal DisableDelayedExpansion
title AI Jail - Phase 040 Offline Configuration Review

REM ============================================================
REM PHASE 040 - WSL CONFIGURATION AND ISOLATION
REM STATUS: OFFLINE REVIEW ONLY
REM ============================================================
REM
REM Permitted:
REM   - Validate Phase 040 requirements and config.env
REM   - Review the declared isolation policy
REM   - Inspect local modernization files
REM
REM Prohibited:
REM   - WSL invocation or distro execution
REM   - Linux user creation
REM   - /etc/wsl.conf modification
REM   - Distribution termination or shutdown
REM   - Production installation
REM
REM ============================================================

set "RC=1"
set "STANDALONE=1"

if defined PHASE_LOG set "STANDALONE=0"

REM Accept no arguments, /review, or internal --elevated.
REM All installation/apply arguments are rejected.

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

if not exist "%~dp0040-requirements.json" (
    echo ERROR: Missing 040-requirements.json
    goto :finish
)

if not exist "%~dp0040-wsl-conf.ps1" (
    echo ERROR: Missing 040-wsl-conf.ps1
    goto :finish
)

REM Administrator privileges are required by Phase 040 policy.
REM Never request UAC in orchestrated or CI execution.

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

REM The elevated child handles its standalone pause.
goto :return

:not_admin

echo ERROR: Phase 040 requires administrator privileges.
goto :finish

:execute

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0040-wsl-conf.ps1"

set "RC=%ERRORLEVEL%"

REM Fail closed on unexpected exit codes.
if not "%RC%"=="0" set "RC=1"

goto :finish

:usage

echo ERROR: Unsupported Phase 040 argument.
echo.
echo Accepted:
echo   040-wsl-conf.bat
echo   040-wsl-conf.bat /review
echo.
echo Runtime verification, installation and --apply are DISABLED.

:finish

echo.
echo 040-wsl-conf exit code: %RC%

if "%STANDALONE%"=="1" if not defined AIJAIL_CI pause

:return

endlocal & exit /b %RC%