@echo off
REM =====================================================================
REM 010-preflight.bat - fail fast before anything installs (INS-05).
REM LOCKED check list (order fixed, fail-fast, first failure stops):
REM   1. elevation            2. config validity    3. LINUX_USER non-empty
REM   4. virtualization       5. free space >= MIN_FREE_GB on TARGET_DRIVE
REM   6. internet reachable
REM EXCLUSIONS (scope fence, locked): NO Docker check (dropped); NO
REM   WSL/Linux commands - WSL presence -> phase 020, distro conflict ->
REM   030/020. Plan 01-03 extends this file; it does not re-scope it.
REM WHY elevation first: no later check may run on an unelevated shell
REM   and no check output may precede the abort (T-1-08).
REM WHY AIJAIL_TEST_SKIP_INTERNET: test-only escape hatch so the suite
REM   stays offline-safe and fast - production never sets it, so the real
REM   Invoke-WebRequest probe still runs in the field.
REM Stateless/idempotent (INS-03): nothing written outside logs\.
REM =====================================================================
call "%~dp0_common.bat" :load
if not "%ERRORLEVEL%"=="0" exit /b 1
REM WHY setlocal only AFTER :load: config values must parse under
REM   DisableDelayedExpansion (plan 01 contract) before delayed is on.
setlocal EnableDelayedExpansion
call "%~dp0_common.bat" :require_admin
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" goto :not_admin
call :check_config
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" exit /b 1
call :check_user
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" exit /b 1
call :check_virt
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" exit /b 1
call :check_disk
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" exit /b 1
call :check_internet
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" exit /b 1
echo 010-preflight: all checks passed
exit /b 0

:not_admin
echo ERROR: 010-preflight must run as administrator. Re-run this terminal elevated.
exit /b 1

REM ---- :check_config - required keys present after :load (INS-06) ------
:check_config
if not defined TARGET_DRIVE ( set "MSG=ERROR: TARGET_DRIVE missing from config.env" & goto :failed )
if not defined LINUX_USER ( set "MSG=ERROR: LINUX_USER missing from config.env" & goto :failed )
if not defined MIN_FREE_GB ( set "MSG=ERROR: MIN_FREE_GB missing from config.env" & goto :failed )
REM WHY digits-only (review F1): the free-space compare must be numeric -
REM   a value like 20.5 or 1GB would otherwise reach it as text and string
REM   ordering can pass an unsatisfiable minimum (fail-open). Reject the
REM   format here, in the config-validity check, so it fails closed.
for /f "delims=0123456789" %%z in ("!MIN_FREE_GB!") do set "MSG=ERROR: MIN_FREE_GB must be a whole number of GB - digits only - got !MIN_FREE_GB!"
if defined MSG goto :failed
REM WHY no leading zeros (review F1): an unquoted numeric with a leading
REM   zero does not parse as plain decimal (probed: 9 LSS 010 is FALSE) -
REM   reject the format rather than silently compare the wrong number.
if not "!MIN_FREE_GB!"=="0" if "!MIN_FREE_GB:~0,1!"=="0" ( set "MSG=ERROR: MIN_FREE_GB must not have leading zeros - got !MIN_FREE_GB!" & goto :failed )
exit /b 0

REM ---- :check_user - LINUX_USER non-empty -------------------------------
:check_user
if not "!LINUX_USER!"=="" exit /b 0
set "MSG=ERROR: LINUX_USER is empty in config.env"
goto :failed

REM ---- :check_virt - HypervisorPresent must be True ---------------------
:check_virt
set "HV=unknown"
for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "(Get-CimInstance Win32_ComputerSystem).HypervisorPresent"`) do set "HV=%%v"
if "!HV!"=="True" exit /b 0
set "MSG=ERROR: virtualization not present - HypervisorPresent=!HV! - enable virtualization in firmware BIOS and retry"
goto :failed

REM ---- :check_disk - free GB on TARGET_DRIVE >= MIN_FREE_GB -------------
REM WHY TotalFreeSpace not AvailableFreeBytes: AvailableFreeBytes reports
REM   0 on this machine while TotalFreeSpace/CIM report the real 734 GB -
REM   the quota-aware figure would fail preflight unconditionally (verified).
:check_disk
set "FREE_GB="
for /f "usebackq delims=" %%g in (`powershell -NoProfile -Command "$d=[IO.DriveInfo]::new('%TARGET_DRIVE%'); [int]($d.TotalFreeSpace/1GB)"`) do set "FREE_GB=%%g"
REM WHY digit-validate FREE_GB (review F1): for /f captures the FIRST line
REM   of powershell output - an error line would otherwise reach the compare
REM   as text and string ordering could pass it (fail-open).
for /f "delims=0123456789" %%z in ("!FREE_GB!") do set "FREE_GB="
if "!FREE_GB!"=="" ( set "MSG=ERROR: could not read free space on !TARGET_DRIVE!" & goto :failed )
REM WHY UNQUOTED numeric LSS (review F1): quoted operands compare as
REM   STRINGS in cmd - probed, "9" LSS "20" is FALSE, so 9 GB free passed a
REM   20 GB minimum (fail-open); 734 GB passed a 1000 GB minimum the same
REM   way. Both operands are digit-validated upstream, so this is numeric.
if not !FREE_GB! LSS !MIN_FREE_GB! exit /b 0
set "MSG=ERROR: free space on %TARGET_DRIVE% is !FREE_GB! GB, MIN_FREE_GB requires !MIN_FREE_GB! GB"
goto :failed

REM ---- :check_internet - msftconnecttest reachable ----------------------
:check_internet
if defined AIJAIL_TEST_SKIP_INTERNET exit /b 0
powershell -NoProfile -Command "try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 10 'https://www.msftconnecttest.com/connecttest.txt' | Out-Null; exit 0 } catch { exit 1 }"
set "RC=!ERRORLEVEL!"
if "!RC!"=="0" exit /b 0
set "MSG=ERROR: internet check failed - https://www.msftconnecttest.com/connecttest.txt not reachable"
goto :failed

REM ---- :failed - one exit path: stdout AND the phase log ----------------
:failed
echo !MSG!
if defined PHASE_LOG echo(!MSG!>>"%PHASE_LOG%"
set "MSG="
exit /b 1
