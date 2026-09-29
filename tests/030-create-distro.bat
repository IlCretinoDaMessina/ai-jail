@echo off
REM =====================================================================
REM 030-create-distro.bat - create the dedicated WSL2 distro (Phase 2).
REM Idempotent: distro already registered + vhdx in place + WSL2 -> skip.
REM Fail-closed: a registered distro whose vhdx is NOT at DEST, or an
REM orphan vhdx at DEST with no registration, is never touched or
REM overwritten - the phase stops and says so.
REM DEST = TARGET_DRIVE\DISTRO\wsl  (vhdx = DEST\ext4.vhdx)
REM WHY --no-launch: no first-run user prompt; user setup is phase 040.
REM Never touches docker-desktop or global .wslconfig.
REM WHY WSL_UTF8=1 / no PHASE_LOG append: see 020-wsl-check.bat header.
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
if not "!RC!"=="0" exit /b 1

set "WSL_UTF8=1"
set "DEST=!TARGET_DRIVE!\!DISTRO!\wsl"

call :query_distro
if "!REG!"=="1" goto :verify_only

call :check_dest_free
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" exit /b 1

call :create_distro
set "RC=!ERRORLEVEL!"
if "!RC!"=="3010" exit /b 3010
if not "!RC!"=="0" exit /b 1

call :query_distro

:verify_only
call :verify
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" exit /b 1
echo 030-create-distro: !DISTRO! OK - WSL2, vhdx at !DEST!\ext4.vhdx
exit /b 0

:not_admin
echo ERROR: 030-create-distro must run as administrator. Re-run this terminal elevated.
exit /b 1

REM ---- :check_config - required keys present ----------------------------
:check_config
if not defined TARGET_DRIVE ( set "MSG=ERROR: TARGET_DRIVE missing from config.env" & goto :failed )
if not defined DISTRO ( set "MSG=ERROR: DISTRO missing from config.env" & goto :failed )
if not defined BASE_DISTRO ( set "MSG=ERROR: BASE_DISTRO missing from config.env" & goto :failed )
exit /b 0

REM ---- :query_distro - sets REG (0/1) and VER for DISTRO ----------------
REM WHY two shapes: the default distro row starts with a "*" token, which
REM shifts the columns by one.
:query_distro
set "REG=0"
set "VER="
for /f "usebackq tokens=1-4" %%a in (`wsl.exe --list --verbose 2^>nul`) do (
  if "%%a"=="*" (
    if /i "%%b"=="!DISTRO!" ( set "REG=1" & set "VER=%%d" )
  ) else (
    if /i "%%a"=="!DISTRO!" ( set "REG=1" & set "VER=%%c" )
  )
)
exit /b 0

REM ---- :check_dest_free - no orphan vhdx at DEST ------------------------
:check_dest_free
if not exist "!DEST!\ext4.vhdx" exit /b 0
set "MSG=ERROR: !DEST!\ext4.vhdx exists but distro !DISTRO! is not registered - refusing to overwrite; remove it manually if it is stale"
goto :failed

REM ---- :create_distro - wsl --install into DEST -------------------------
:create_distro
if not exist "!DEST!" mkdir "!DEST!"
if not exist "!DEST!" ( set "MSG=ERROR: could not create !DEST!" & goto :failed )
wsl.exe --install !BASE_DISTRO! --name !DISTRO! --location "!DEST!" --no-launch
set "RC=!ERRORLEVEL!"
call "%~dp0_common.bat" :classify_rc !RC!
set "CRC=!ERRORLEVEL!"
if "!CRC!"=="0" exit /b 0
if "!CRC!"=="3010" exit /b 3010
set "MSG=ERROR: wsl --install !BASE_DISTRO! failed rc=!RC!"
goto :failed

REM ---- :verify - registered, WSL2, vhdx exactly at DEST -----------------
:verify
if not "!REG!"=="1" ( set "MSG=ERROR: distro !DISTRO! not registered after create" & goto :failed )
if not "!VER!"=="2" ( set "MSG=ERROR: distro !DISTRO! is WSL version [!VER!], expected 2" & goto :failed )
if not exist "!DEST!\ext4.vhdx" ( set "MSG=ERROR: !DISTRO! is registered but !DEST!\ext4.vhdx is missing - distro lives elsewhere, not touching it" & goto :failed )
exit /b 0

REM ---- :failed - one exit path (stdout only, see header) ----------------
:failed
echo !MSG!
set "MSG="
exit /b 1
