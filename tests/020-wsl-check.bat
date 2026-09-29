@echo off
REM =====================================================================
REM 020-wsl-check.bat - verify WSL is installed and new enough (Phase 2).
REM Read-only: never installs, updates, shuts down or touches any distro
REM (docker-desktop stays untouched). Fix hint on failure: wsl --update
REM WHY min version: `wsl --install <distro> --name --location` (used by
REM 030) needs WSL 2.4.4+. Minimum lives in config.env MIN_WSL_VERSION.
REM WHY WSL_UTF8=1: wsl.exe output is UTF-16 by default and unparseable
REM by for /f. WHY parse "after first colon": the label text is localized.
REM WHY no append to PHASE_LOG in :failed: run-all already redirects this
REM phase's stdout into that log (:run_phase) - a second writer collides
REM ("file in use"). stdout is enough: it lands in the log either way.
REM Exit codes: 0 OK, 1 fatal. Idempotent, writes nothing.
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

call :check_wsl
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" exit /b 1

echo 020-wsl-check: WSL !WSLV! OK - minimum !MIN_WSL_VERSION!
exit /b 0

:not_admin
echo ERROR: 020-wsl-check must run as administrator. Re-run this terminal elevated.
exit /b 1

REM ---- :check_config - MIN_WSL_VERSION present, form N.N.N --------------
:check_config
if not defined MIN_WSL_VERSION ( set "MSG=ERROR: MIN_WSL_VERSION missing from config.env" & goto :failed )
set "MA=" & set "MI=" & set "MP="
for /f "tokens=1-3 delims=." %%a in ("!MIN_WSL_VERSION!") do ( set "MA=%%a" & set "MI=%%b" & set "MP=%%c" )
call :num_ok "!MA!"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" ( set "MSG=ERROR: MIN_WSL_VERSION must look like 2.4.4 - got !MIN_WSL_VERSION!" & goto :failed )
call :num_ok "!MI!"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" ( set "MSG=ERROR: MIN_WSL_VERSION must look like 2.4.4 - got !MIN_WSL_VERSION!" & goto :failed )
call :num_ok "!MP!"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" ( set "MSG=ERROR: MIN_WSL_VERSION must look like 2.4.4 - got !MIN_WSL_VERSION!" & goto :failed )
set /a "MIN_NUM=!MA!*1000000+!MI!*1000+!MP!"
exit /b 0

REM ---- :check_wsl - wsl.exe present, version >= MIN_WSL_VERSION ---------
:check_wsl
where wsl.exe >nul 2>&1
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" ( set "MSG=ERROR: wsl.exe not found - install WSL first: wsl --install --no-distribution" & goto :failed )
set "WSL_UTF8=1"
set "WSLV="
for /f "usebackq tokens=1,* delims=:" %%a in (`wsl.exe --version 2^>^&1`) do if not defined WSLV set "WSLV=%%b"
set "WSLV=!WSLV: =!"
set "VA=" & set "VI=" & set "VP="
for /f "tokens=1-3 delims=." %%a in ("!WSLV!") do ( set "VA=%%a" & set "VI=%%b" & set "VP=%%c" )
REM WHY validate before compare: unparseable output must fail closed.
call :num_ok "!VA!"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" ( set "MSG=ERROR: could not read WSL version - got [!WSLV!] - try: wsl --update" & goto :failed )
call :num_ok "!VI!"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" ( set "MSG=ERROR: could not read WSL version - got [!WSLV!] - try: wsl --update" & goto :failed )
call :num_ok "!VP!"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" ( set "MSG=ERROR: could not read WSL version - got [!WSLV!] - try: wsl --update" & goto :failed )
set /a "CUR_NUM=!VA!*1000000+!VI!*1000+!VP!"
if not !CUR_NUM! LSS !MIN_NUM! exit /b 0
set "MSG=ERROR: WSL !WSLV! is older than required !MIN_WSL_VERSION! - run: wsl --update"
goto :failed

REM ---- :num_ok <value> - rc 0 if digits only, non-empty, no leading 0 ---
:num_ok
set "NV=%~1"
if "!NV!"=="" exit /b 1
for /f "delims=0123456789" %%z in ("!NV!") do exit /b 1
if not "!NV!"=="0" if "!NV:~0,1!"=="0" exit /b 1
exit /b 0

REM ---- :failed - one exit path (stdout only, see header) ----------------
:failed
echo !MSG!
set "MSG="
exit /b 1
