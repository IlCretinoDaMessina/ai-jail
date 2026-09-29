@echo off
REM =====================================================================
REM 050-isolation-gate.bat - hard isolation gate (Phase 2).
REM Must pass before any install phase is allowed to run.
REM Exit codes: 0 OK, 1 fatal, 3010 reboot required.
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

set "TMP=!TEMP!\ai-jail-050"
set "WHO_FILE=!TMP!-who.txt"
set "PATH_FILE=!TMP!-path.txt"
set "MNT_FILE=!TMP!-mnt.txt"

REM ---- identity ---------------------------------------------------------
wsl.exe -d !DISTRO! -e /bin/sh -c "id -un" > "!WHO_FILE!"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: could not read Linux identity rc=!RC!"
  goto :failed
)

set "WHO="
set /p WHO=<"!WHO_FILE!"
if /i not "!WHO!"=="!LINUX_USER!" (
  set "MSG=ERROR: Linux user is !WHO!, expected !LINUX_USER!"
  goto :failed
)

REM ---- Windows drive mounts --------------------------------------------
wsl.exe -d !DISTRO! -e /bin/sh -c "if mountpoint -q /mnt/c; then exit 1; else exit 0; fi"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: /mnt/c is mounted or could not be checked rc=!RC!"
  goto :failed
)

wsl.exe -d !DISTRO! -e /bin/sh -c "if mountpoint -q /mnt/d; then exit 1; else exit 0; fi"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: /mnt/d is mounted or could not be checked rc=!RC!"
  goto :failed
)

REM ---- drvfs ------------------------------------------------------------
wsl.exe -d !DISTRO! -e /bin/sh -c "if grep -q drvfs /proc/mounts; then exit 1; else exit 0; fi"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: drvfs mount detected or could not be checked rc=!RC!"
  goto :failed
)

REM ---- Windows executables ---------------------------------------------
wsl.exe -d !DISTRO! -e /bin/sh -c "if command -v cmd.exe >/dev/null 2>&1; then exit 1; else exit 0; fi"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: cmd.exe is reachable"
  goto :failed
)

wsl.exe -d !DISTRO! -e /bin/sh -c "if command -v powershell.exe >/dev/null 2>&1; then exit 1; else exit 0; fi"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: powershell.exe is reachable"
  goto :failed
)

REM ---- PATH -------------------------------------------------------------
wsl.exe -d !DISTRO! -e /bin/sh -c "printf '%%s\n' \"$PATH\"" > "!PATH_FILE!"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: could not read Linux PATH rc=!RC!"
  goto :failed
)

findstr /C:"/mnt" "!PATH_FILE!" >nul
set "RC=!ERRORLEVEL!"
if "!RC!"=="0" (
  set "MSG=ERROR: /mnt appears in Linux PATH"
  goto :failed
)
if not "!RC!"=="1" (
  set "MSG=ERROR: could not verify Linux PATH rc=!RC!"
  goto :failed
)

REM ---- /mnt itself must contain no Windows drive mounts -----------------
wsl.exe -d !DISTRO! -e /bin/sh -c "findmnt -rn -o TARGET,FSTYPE | grep -E '^/mnt/(c|d)( |$)|drvfs' || true" > "!MNT_FILE!"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  set "MSG=ERROR: mount inventory failed rc=!RC!"
  goto :failed
)

for %%A in ("!MNT_FILE!") do if %%~zA GTR 0 (
  set "MSG=ERROR: Windows mount detected in mount inventory"
  goto :failed
)

del /q "!WHO_FILE!" "!PATH_FILE!" "!MNT_FILE!" >nul 2>&1
echo 050-isolation-gate: !DISTRO! PASS - user !LINUX_USER!, no drvfs, Windows drives unreachable, interop unreachable, PATH clean
exit /b 0

:not_admin
echo ERROR: 050-isolation-gate must run as administrator. Re-run this terminal elevated.
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
del /q "!WHO_FILE!" "!PATH_FILE!" "!MNT_FILE!" >nul 2>&1
echo !MSG!
set "MSG="
exit /b 1