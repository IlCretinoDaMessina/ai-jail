@echo off
REM =====================================================================
REM 040-wsl-conf.bat - configure the dedicated WSL distro (Phase 2).
REM Idempotent. Never touches docker-desktop or global .wslconfig.
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

REM ---- ensure distro is accessible --------------------------------------
wsl.exe -d !DISTRO! -u root -e /bin/true >nul 2>&1
set "RC=!ERRORLEVEL!"
call "%~dp0_common.bat" :classify_rc !RC!
set "CRC=!ERRORLEVEL!"
if not "!CRC!"=="0" (
  set "MSG=ERROR: distro !DISTRO! could not be started/accessed rc=!RC!"
  goto :failed
)

REM ---- create Linux user if missing -------------------------------------
wsl.exe -d !DISTRO! -u root -e /usr/bin/getent passwd !LINUX_USER! >nul 2>&1
set "RC=!ERRORLEVEL!"

if "!RC!"=="0" goto :make_conf
if not "!RC!"=="2" (
  set "MSG=ERROR: could not check Linux user !LINUX_USER! rc=!RC!"
  goto :failed
)

wsl.exe -d !DISTRO! -u root -e /usr/sbin/useradd -m -s /bin/bash !LINUX_USER!
set "RC=!ERRORLEVEL!"
call "%~dp0_common.bat" :classify_rc !RC!
set "CRC=!ERRORLEVEL!"
if not "!CRC!"=="0" (
  set "MSG=ERROR: could not create Linux user !LINUX_USER! rc=!RC!"
  goto :failed
)

REM ---- build CRLF source, then convert to LF using the common helper -----
:make_conf
set "CONF_SRC=!TEMP!\ai-jail-040-source.conf"
set "CONF_LF=!TEMP!\ai-jail-040-lf.conf"

> "!CONF_SRC!" echo [boot]
>>"!CONF_SRC!" echo systemd=true
>>"!CONF_SRC!" echo(
>>"!CONF_SRC!" echo [automount]
>>"!CONF_SRC!" echo enabled=false
>>"!CONF_SRC!" echo mountFsTab=false
>>"!CONF_SRC!" echo(
>>"!CONF_SRC!" echo [interop]
>>"!CONF_SRC!" echo enabled=false
>>"!CONF_SRC!" echo appendWindowsPath=false
>>"!CONF_SRC!" echo(
>>"!CONF_SRC!" echo [user]
>>"!CONF_SRC!" echo default=!LINUX_USER!

call "%~dp0_common.bat" :write_lf "!CONF_LF!" "@!CONF_SRC!"
set "RC=!ERRORLEVEL!"
call "%~dp0_common.bat" :classify_rc !RC!
set "CRC=!ERRORLEVEL!"
if not "!CRC!"=="0" (
  set "MSG=ERROR: could not create LF wsl.conf rc=!RC!"
  goto :failed
)

REM ---- install config ---------------------------------------------------
wsl.exe -d !DISTRO! -u root -e /bin/sh -c "cat > /etc/wsl.conf" < "!CONF_LF!"
set "RC=!ERRORLEVEL!"
call "%~dp0_common.bat" :classify_rc !RC!
set "CRC=!ERRORLEVEL!"
if not "!CRC!"=="0" (
  set "MSG=ERROR: could not write /etc/wsl.conf rc=!RC!"
  goto :failed
)

REM ---- restart only this distro -----------------------------------------
wsl.exe --terminate !DISTRO!
set "RC=!ERRORLEVEL!"
call "%~dp0_common.bat" :classify_rc !RC!
set "CRC=!ERRORLEVEL!"
if not "!CRC!"=="0" (
  set "MSG=ERROR: could not terminate !DISTRO! rc=!RC!"
  goto :failed
)

REM ---- verification: Linux user -----------------------------------------
wsl.exe -d !DISTRO! -e /usr/bin/id -un > "!CONF_SRC!"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" goto :verify_failed

set "WHO="
set /p WHO=<"!CONF_SRC!"
if /i not "!WHO!"=="!LINUX_USER!" goto :verify_failed

REM ---- verification: Windows drive mounts absent -----------------------
wsl.exe -d !DISTRO! -e /usr/bin/mountpoint -q /mnt/c
set "RC=!ERRORLEVEL!"
if "!RC!"=="0" goto :verify_failed

wsl.exe -d !DISTRO! -e /usr/bin/mountpoint -q /mnt/d
set "RC=!ERRORLEVEL!"
if "!RC!"=="0" goto :verify_failed

REM ---- verification: no drvfs mount -------------------------------------
wsl.exe -d !DISTRO! -e /bin/sh -c "if mount | grep -q drvfs; then exit 1; else exit 0; fi"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" goto :verify_failed

REM ---- verification: Windows executables unreachable --------------------
wsl.exe -d !DISTRO! -e /bin/sh -c "command -v cmd.exe > /dev/null 2>&1"
set "RC=!ERRORLEVEL!"
if "!RC!"=="0" goto :verify_failed

wsl.exe -d !DISTRO! -e /bin/sh -c "command -v powershell.exe > /dev/null 2>&1"
set "RC=!ERRORLEVEL!"
if "!RC!"=="0" goto :verify_failed

REM ---- verification: /mnt absent from PATH -------------------------------
wsl.exe -d !DISTRO! -e /bin/printenv PATH > "!CONF_SRC!"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" goto :verify_failed

findstr /C:"/mnt" "!CONF_SRC!" >nul
set "RC=!ERRORLEVEL!"
if "!RC!"=="0" goto :verify_failed

del /q "!CONF_SRC!" "!CONF_LF!" >nul 2>&1
set "CONF_SRC="
set "CONF_LF="

echo 040-wsl-conf: !DISTRO! OK - user !LINUX_USER!, isolation prerequisites verified
exit /b 0

:not_admin
echo ERROR: 040-wsl-conf must run as administrator. Re-run this terminal elevated.
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

:verify_failed
if defined CONF_SRC del /q "!CONF_SRC!" >nul 2>&1
if defined CONF_LF del /q "!CONF_LF!" >nul 2>&1
set "MSG=ERROR: Phase 040 isolation verification failed"
goto :failed

:failed
echo !MSG!
set "MSG="
exit /b 1