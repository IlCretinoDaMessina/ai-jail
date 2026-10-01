@echo off
REM =====================================================================
REM _common.bat - shared helpers for every AI-Jail phase (INS-06/INS-03)
REM WHY one file: phases call `call "_common.bat" :label args` instead of
REM      copy-pasting config/exit/log logic - one implementation, one
REM      contract: 0 = OK, 1 = fatal, 3010 = reboot required.
REM Sections: dispatch | :load | :log | :run_phase | :classify_rc
REM           | :require_admin | :classify_admin | :write_lf | :usage
REM =====================================================================

REM ---- dispatch -------------------------------------------------------
REM WHY guards instead of a bare `goto %~1`: an unknown label would dump a
REM raw cmd error with a misleading rc - usage is the honest fail-closed
REM answer (t18 guard pattern).
if "%~1"=="" goto :usage
if /i "%~1"==":load" goto :load
if /i "%~1"==":log" goto :log
if /i "%~1"==":run_phase" goto :run_phase
if /i "%~1"==":classify_rc" goto :classify_rc
if /i "%~1"==":require_admin" goto :require_admin
if /i "%~1"==":classify_admin" goto :classify_admin
if /i "%~1"==":write_lf" goto :write_lf
goto :usage

REM ---- :load [config-path] -------------------------------------------
:load
REM WHY capture BEFORE shift: `shift` also shifts %0, and %~dp0 of the
REM   shifted value (:load) resolves to the CWD, not this script (verified
REM   - sandbox runs wrote logs into the wrong directory).
set "AIJAIL_BASE=%~dp0"
REM WHY shift first line: when called externally, %1 IS the label token -
REM without shift every argument reads offset by one (t17 vs t18).
shift
set "AIJAIL_CFG=%~1"
REM WHY default path: bare `:load` reads the canonical config.env next to
REM this script - the single source of truth (INS-06).
if not defined AIJAIL_CFG set "AIJAIL_CFG=%AIJAIL_BASE%config.env"
setlocal DisableDelayedExpansion
if not exist "%AIJAIL_CFG%" (
  echo [ERROR] config not found: "%AIJAIL_CFG%" 1>&2
  endlocal
  set "AIJAIL_CFG="
  set "AIJAIL_BASE="
  exit /b 1
)
REM WHY DisableDelayedExpansion: `!` in values survives only when the
REM parse runs with delayed expansion OFF (t13 corrupts, t16 preserves).
REM WHY usebackq eol=# tokens=1,* delims==: '#' comments skipped; only the
REM FIRST '=' splits, so URLs with '=' and values with '&','?' survive.
for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%AIJAIL_CFG%") do set "%%a=%%b"
REM WHY per-key endlocal & set: a naive setlocal leaks nothing back to the
REM caller (t18) - each parsed key must be exported across the setlocal
REM boundary or every bat would see empty knobs.
for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%AIJAIL_CFG%") do (endlocal & set "%%a=%%b")
set "AIJAIL_CFG="
set "AIJAIL_BASE="
exit /b 0

REM ---- :log <phase-name> ----------------------------------------------
:log
REM WHY capture BEFORE shift: %~dp0 must be taken while %0 is still this
REM   script - after shift %0 is the label token and %~dp0 degrades to CWD.
set "LOG_BASE=%~dp0"
REM WHY shift: external `call _common.bat :log name` puts the label token
REM in %1 - without shift every argument reads offset by one (t17/t18).
shift
if "%~1"=="" ( set "LOG_BASE=" & exit /b 1 )
setlocal
if not exist "%LOG_BASE%logs" mkdir "%LOG_BASE%logs"
REM WHY endlocal & set: PHASE_LOG must exist in the CALLER's scope - the
REM phase bat reads it right after this call returns.
endlocal & set "PHASE_LOG=%LOG_BASE%logs\%~1.log"
set "LOG_BASE="
exit /b 0

REM ---- :run_phase <command...> ----------------------------------------
:run_phase
REM WHY shift: same label-token offset as :log (t17/t18).
shift
REM WHY fail-closed guard: without a log target the redirect would land in
REM an unpredictable place - a missing :log call is a bug, not a fallback.
if not defined PHASE_LOG (
  echo [ERROR] :run_phase called without :log first 1>&2
  exit /b 1
)
setlocal EnableDelayedExpansion
REM WHY rebuild as %%1..%%9 instead of call %%*: %%* ignores `shift`
REM (t17) - `call %*` would re-dispatch the label token and loop forever.
REM WHY capture-first: `set "RC=!ERRORLEVEL!"` IMMEDIATELY after the call
REM defeats stale %ERRORLEVEL% inside parsed blocks (t8).
REM WHY capture-to-log + type replay (tee): console and log stay
REM byte-identical without a PowerShell wrapper in the hot loop.
call %1 %2 %3 %4 %5 %6 %7 %8 %9 > "%PHASE_LOG%" 2>&1
set "RC=!ERRORLEVEL!"
type "%PHASE_LOG%"
REM WHY endlocal & exit /b %RC%: %RC% expands at parse time, before
REM endlocal runs - the raw rc crosses the setlocal boundary intact.
endlocal & exit /b %RC%

REM ---- :classify_rc <raw-rc> ------------------------------------------
:classify_rc
shift
REM WHY quoted string compare instead of EQU: `if abc EQU 5` is a parse
REM error that leaves a stale ERRORLEVEL (fail-open) - string compare is
REM total and exact for any input, including empty.
REM WHY 3010 branch first, exact match only: never `GEQ 3010` (would
REM misroute 9009 to reboot) and never bare `if errorlevel 1`
REM (>= semantics would misroute reboot as fatal, t1).
REM WHY else exit /b 1: fail-closed - any rc outside {0,1,3010} must
REM never read as success (Roadmap demands fail-closed throughout).
if "%~1"=="3010" exit /b 3010
if "%~1"=="1" exit /b 1
if "%~1"=="0" exit /b 0
exit /b 1

REM ---- :require_admin -> rc 0 elevated / 1 not (INS-05, T-1-10) --------
:require_admin
REM WHY shift: external `call _common.bat :require_admin` puts the label
REM token in %1 (t17/t18) - no args are used, but shift keeps the frame
REM consistent with every other label.
shift
set "ADMIN_PROBE="
REM WHY -NoProfile + classify the OUTPUT: powershell.exe's own exit code
REM only reports whether the command executed - not admin status - and
REM every cmd probe (net session, fltmc, fsutil, net file) proved flaky
REM on this machine (t4), where a flaky probe fails OPEN (T-1-10).
for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)"`) do set "ADMIN_PROBE=%%p"
REM WHY classify last + bare exit /b: the rc rides through untouched -
REM any cleanup `set` after the call could clobber it (capture-first t8).
call :classify_admin "%ADMIN_PROBE%"
exit /b

REM ---- :classify_admin <probe-output> -> 0 True / 1 otherwise ----------
:classify_admin
REM WHY guarded shift: this label has TWO callers - external
REM   `call _common.bat :classify_admin True` puts the label token in %1
REM   (needs shift), while :require_admin's internal `call :classify_admin
REM   "%ADMIN_PROBE%"` has the VALUE already in %1 (a bare shift would eat
REM   it and every probe would read as not-elevated - verified).
if /i "%~1"==":classify_admin" shift
REM WHY its own label: both branches are unit-provable by feeding
REM True/False fixtures - an unelevated machine can never observe the
REM True branch end-to-end (verify-preflight.cmd).
REM WHY exact "True", fail-closed else: empty output, error text or
REM False all mean NOT elevated - a wrong True would grant unfettered
REM install rights (T-1-10).
if "%~1"=="True" exit /b 0
exit /b 1

REM ---- :write_lf <dest> <content-or-@srcfile> --------------------------
:write_lf
shift
REM WHY DisableDelayedExpansion: a caller may have delayed expansion on
REM (every test does) - `!` inside content would be eaten at set-time.
setlocal DisableDelayedExpansion
REM WHY fail-closed: writing to an empty path lands in an odd place.
if "%~1"=="" exit /b 1
REM WHY env-var channel instead of inline -Command: user content never
REM appears in the command line - no cmd/PS quoting hell for &, =, %.
set "LF_DEST=%~1"
set "LF_SRC=%~2"
REM WHY @srcfile channel: batch args cannot carry CR/LF at all (verified:
REM caret-newline joins lines, raw CR is stripped) - the only way to feed
REM an embedded-CRLF payload in is via a file whose bytes hold them.
REM WHY -replace CRLF then UTF8 no BOM: cmd emits CRLF; Linux-side files
REM poisoned by CR break bash - this is the only sanctioned emitter
REM (PLT-04). Windows cmd can never write a bare LF itself.
powershell -NoProfile -Command "if ($env:LF_SRC -like '@*') { if (-not (Test-Path -LiteralPath $env:LF_SRC.Substring(1))) { exit 1 }; $t = [IO.File]::ReadAllText($env:LF_SRC.Substring(1)) } else { $t = [string]$env:LF_SRC }; $t = $t.Replace([string][char]13 + [string][char]10, [string][char]10); [IO.File]::WriteAllText($env:LF_DEST, $t, [Text.UTF8Encoding]::new($false))"
set "RC=%ERRORLEVEL%"
endlocal & exit /b %RC%

REM ---- :usage (unexpected invocation) --------------------------------
:usage
echo Usage: call "_common.bat" :load [config-path] 1>&2
echo        call "_common.bat" :log ^<phase-name^> 1>&2
echo        call "_common.bat" :run_phase ^<command...^> 1>&2
echo        call "_common.bat" :classify_rc ^<raw-rc^> 1>&2
echo        call "_common.bat" :require_admin 1>&2
echo        call "_common.bat" :classify_admin ^<probe-output^> 1>&2
echo        call "_common.bat" :write_lf ^<dest^> ^<content-or-@srcfile^> 1>&2
exit /b 1
