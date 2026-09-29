@echo off
REM =====================================================================
REM 060-base-toolchain.bat - Phase 3 base toolchain.
REM 050 isolation gate MUST pass before any installation.
REM Exit codes: 0 OK/skip, 1 fatal, 3010 reboot required.
REM =====================================================================
call "%~dp0_common.bat" :load
if not "%ERRORLEVEL%"=="0" exit /b 1
setlocal EnableDelayedExpansion

call "%~dp0_common.bat" :require_admin
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" goto :not_admin

call :check_config
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" goto :failed

REM ---- hard gate --------------------------------------------------------
call "%~dp0\050-isolation-gate.bat"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: 050 isolation gate failed; refusing Phase 060"
  goto :failed
)

REM ---- base packages ----------------------------------------------------
wsl.exe -d !DISTRO! -u root -e /bin/bash -lc "apt-get update && apt-get install -y bubblewrap git curl ca-certificates build-essential python3-venv python3-pip pkg-config jq rustup"
set "RC=!ERRORLEVEL!"
call "%~dp0_common.bat" :classify_rc !RC!
set "CRC=!ERRORLEVEL!"
if not "!CRC!"=="0" (
  set "MSG=ERROR: base apt packages failed rc=!RC!"
  goto :failed
)

REM ---- Node.js LTS ------------------------------------------------------
wsl.exe -d !DISTRO! -u root -e /bin/bash -lc "curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt-get install -y nodejs"
set "RC=!ERRORLEVEL!"
call "%~dp0_common.bat" :classify_rc !RC!
set "CRC=!ERRORLEVEL!"
if not "!CRC!"=="0" (
  set "MSG=ERROR: Node.js LTS installation failed rc=!RC!"
  goto :failed
)

REM ---- Rust -------------------------------------------------------------
wsl.exe -d !DISTRO! -e /bin/bash -lc "rustup default stable"
set "RC=!ERRORLEVEL!"
call "%~dp0_common.bat" :classify_rc !RC!
set "CRC=!ERRORLEVEL!"
if not "!CRC!"=="0" (
  set "MSG=ERROR: rustup stable toolchain failed rc=!RC!"
  goto :failed
)

REM ---- user namespaces --------------------------------------------------
wsl.exe -d !DISTRO! -e /bin/bash -lc "unshare -Ur true"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: unprivileged user namespaces are unavailable rc=!RC!"
  goto :failed
)

REM ---- required binaries ------------------------------------------------
wsl.exe -d !DISTRO! -e /bin/bash -lc "command -v bwrap >/dev/null && command -v git >/dev/null && command -v curl >/dev/null && command -v jq >/dev/null && command -v rustup >/dev/null && command -v node >/dev/null && command -v npm >/dev/null && command -v python3 >/dev/null"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: required Phase 060 binaries are missing"
  goto :failed
)

REM ---- GPU checks: warn-only --------------------------------------------
wsl.exe -d !DISTRO! -e /bin/bash -lc "test -d /usr/lib/wsl/lib"
set "GPU_RC=!ERRORLEVEL!"
if "!GPU_RC!"=="0" (
  echo 060 GPU: /usr/lib/wsl/lib present
) else (
  echo 060 WARN: /usr/lib/wsl/lib not present
)

wsl.exe -d !DISTRO! -e /bin/bash -lc "command -v nvidia-smi >/dev/null 2>&1"
set "GPU_RC=!ERRORLEVEL!"
if "!GPU_RC!"=="0" (
  echo 060 GPU: nvidia-smi available
) else (
  echo 060 WARN: nvidia-smi unavailable
)

wsl.exe -d !DISTRO! -e /bin/bash -lc "test -e /dev/dxg"
set "GPU_RC=!ERRORLEVEL!"
if "!GPU_RC!"=="0" (
  echo 060 GPU: /dev/dxg present
) else (
  echo 060 WARN: /dev/dxg unavailable
)

REM ---- versions ---------------------------------------------------------
wsl.exe -d !DISTRO! -e /bin/bash -lc "printf 'bwrap='; bwrap --version; printf 'node='; node --version; printf 'npm='; npm --version; printf 'rustup='; rustup --version; printf 'python='; python3 --version; printf 'git='; git --version"

echo 060-base-toolchain: !DISTRO! OK
exit /b 0

:not_admin
echo ERROR: 060-base-toolchain must run as administrator. Re-run this terminal elevated.
exit /b 1

:check_config
if not defined DISTRO (
  set "MSG=ERROR: DISTRO missing from config.env"
  exit /b 1
)
if not defined LINUX_USER (
  set "MSG=ERROR: LINUX_USER missing from config.env"
  exit /b 1
)
exit /b 0

:failed
echo !MSG!
set "MSG="
exit /b 1