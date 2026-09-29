@echo off
REM =====================================================================
REM 070-ai-jail.bat - install and verify pinned ai-jail (Phase 3).
REM 050 gate is mandatory. Required flags/capabilities are fail-closed.
REM GPU passthrough is warn-only.
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
  set "MSG=ERROR: 050 isolation gate failed; refusing Phase 070"
  goto :failed
)

REM ---- verify user namespace prerequisite --------------------------------
wsl.exe -d !DISTRO! -e /bin/sh -c "unshare -Ur true"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: unprivileged user namespaces unavailable rc=!RC!"
  goto :failed
)

REM ---- verify base toolchain --------------------------------------------
wsl.exe -d !DISTRO! -e /bin/sh -c "command -v cargo >/dev/null 2>&1 && command -v bwrap >/dev/null 2>&1"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: Phase 060 base toolchain incomplete"
  goto :failed
)

REM ---- install exact pinned ai-jail -------------------------------------
wsl.exe -d !DISTRO! -e /bin/bash -lc "cargo install --locked --version 2.2.0 ai-jail"
set "RC=!ERRORLEVEL!"
call "%~dp0_common.bat" :classify_rc !RC!
set "CRC=!ERRORLEVEL!"
if not "!CRC!"=="0" (
  set "MSG=ERROR: ai-jail 2.2.0 install failed rc=!RC!"
  goto :failed
)

REM ---- exact version ----------------------------------------------------
wsl.exe -d !DISTRO! -e /home/!LINUX_USER!/.cargo/bin/ai-jail --version > "%TEMP%\ai-jail-070-version.txt"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  del /q "%TEMP%\ai-jail-070-version.txt" >nul 2>&1
  set "MSG=ERROR: ai-jail --version failed rc=!RC!"
  goto :failed
)

findstr /B /C:"ai-jail 2.2.0" "%TEMP%\ai-jail-070-version.txt" >nul
set "RC=!ERRORLEVEL!"
del /q "%TEMP%\ai-jail-070-version.txt" >nul 2>&1
if not "!RC!"=="0" (
  set "MSG=ERROR: installed ai-jail version is not exactly 2.2.0"
  goto :failed
)

REM ---- dry-run ----------------------------------------------------------
wsl.exe -d !DISTRO! -e /home/!LINUX_USER!/.cargo/bin/ai-jail --dry-run /bin/echo ok > "%TEMP%\ai-jail-070-dry.txt"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  del /q "%TEMP%\ai-jail-070-dry.txt" >nul 2>&1
  set "MSG=ERROR: ai-jail --dry-run failed rc=!RC!"
  goto :failed
)

findstr /C:"--unshare-net" "%TEMP%\ai-jail-070-dry.txt" >nul
if not "!ERRORLEVEL!"=="0" (
  del /q "%TEMP%\ai-jail-070-dry.txt" >nul 2>&1
  set "MSG=ERROR: dry-run did not show network namespace isolation"
  goto :failed
)

findstr /C:"--landlock" "%TEMP%\ai-jail-070-dry.txt" >nul
if not "!ERRORLEVEL!"=="0" (
  del /q "%TEMP%\ai-jail-070-dry.txt" >nul 2>&1
  set "MSG=ERROR: dry-run did not show Landlock"
  goto :failed
)

del /q "%TEMP%\ai-jail-070-dry.txt" >nul 2>&1

REM ---- real jail --------------------------------------------------------
wsl.exe -d !DISTRO! -e /home/!LINUX_USER!/.cargo/bin/ai-jail /bin/echo AI_JAIL_OK >nul
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: real ai-jail execution failed rc=!RC!"
  goto :failed
)

REM ---- --allow-host support ---------------------------------------------
REM ai-jail may materialize ~/.ai-jail from this invocation. Preserve it
REM only long enough to prove the feature, then remove the generated config
REM so Phase 070 remains default-deny.
wsl.exe -d !DISTRO! -e /home/!LINUX_USER!/.cargo/bin/ai-jail --allow-host example.com --dry-run /bin/echo ALLOW_HOST_OK > "%TEMP%\ai-jail-070-allow.txt"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  del /q "%TEMP%\ai-jail-070-allow.txt" >nul 2>&1
  set "MSG=ERROR: ai-jail --allow-host dry-run failed rc=!RC!"
  goto :failed
)

findstr /C:"--allow-host example.com" "%TEMP%\ai-jail-070-allow.txt" >nul
if not "!ERRORLEVEL!"=="0" (
  del /q "%TEMP%\ai-jail-070-allow.txt" >nul 2>&1
  set "MSG=ERROR: --allow-host was not reflected in dry-run"
  goto :failed
)

del /q "%TEMP%\ai-jail-070-allow.txt" >nul 2>&1

wsl.exe -d !DISTRO! -u root -e /bin/sh -c "if [ -f /home/!LINUX_USER!/.ai-jail ]; then rm -f /home/!LINUX_USER!/.ai-jail; fi"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: could not remove temporary ai-jail allowlist config rc=!RC!"
  goto :failed
)

REM ---- default deny -----------------------------------------------------
wsl.exe -d !DISTRO! -e /home/!LINUX_USER!/.cargo/bin/ai-jail curl --noproxy "*" --connect-timeout 3 --max-time 5 https://1.1.1.1 >nul 2>&1
set "RC=!ERRORLEVEL!"
if "!RC!"=="0" (
  set "MSG=ERROR: default-deny network probe unexpectedly succeeded"
  goto :failed
)

REM ---- GPU warn-only ----------------------------------------------------
wsl.exe -d !DISTRO! -e /bin/sh -c "test -e /usr/lib/wsl/lib/nvidia-smi"
set "GPU_RC=!ERRORLEVEL!"
if "!GPU_RC!"=="0" (
  echo 070 GPU: /usr/lib/wsl/lib/nvidia-smi present
) else (
  echo 070 WARN: /usr/lib/wsl/lib/nvidia-smi unavailable
)

wsl.exe -d !DISTRO! -e /bin/sh -c "test -e /dev/dxg"
set "GPU_RC=!ERRORLEVEL!"
if "!GPU_RC!"=="0" (
  echo 070 GPU: /dev/dxg present
) else (
  echo 070 WARN: /dev/dxg unavailable
)

wsl.exe -d !DISTRO! -e /bin/sh -c "/usr/lib/wsl/lib/nvidia-smi >/dev/null 2>&1"
set "GPU_RC=!ERRORLEVEL!"
if "!GPU_RC!"=="0" (
  echo 070 GPU: nvidia-smi works inside WSL
) else (
  echo 070 WARN: nvidia-smi unavailable inside WSL/sandbox
)

echo 070-ai-jail: !DISTRO! OK - ai-jail 2.2.0 installed; dry-run, real jail, --allow-host, and default-deny verified
exit /b 0

:not_admin
echo ERROR: 070-ai-jail must run as administrator. Re-run this terminal elevated.
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