@echo off
REM =====================================================================
REM 000-run-all.bat - the orchestrator: runs every NNN-*.bat phase in
REM   name order under the strict exit-code contract 0 / 1 / 3010.
REM WHY: no later phase may run on top of a broken foundation - one
REM   command proves the whole chain, stop-on-fail, resumable via /from.
REM Contract:
REM   - discovery: repo-root ???-*.bat sorted by name; 000-* (this file)
REM     and 999-* (manual-only uninstall, INS-08) never auto-run (T-1-04)
REM   - exit codes: 0=OK, 1=fatal, 3010=reboot; anything else fails
REM     closed as 1 (T-1-05) - never OK, never REBOOT
REM   - every phase is idempotent (INS-03/T-1-07): /from re-runs earlier
REM     phases, so each must self-detect "already done" and return 0
REM   - per-phase tee: output captured to logs\NNN.log AND replayed
REM Arguments: /from NNN (resume >= NNN), /skip NNN (bypass exactly NNN),
REM   unknown args reported, defaults preserved. Debug: /probe-cs T1 T2
REM   prints elapsed cs between two HH:MM:SS.CC stamps (octal/midnight
REM   probe seam for tests\verify-run-all.cmd).
REM =====================================================================
setlocal EnableDelayedExpansion
REM WHY RDIR captured before arg parse: `shift` also shifts %0, so any
REM   %~dp0 read after /from //skip parsing degrades to CWD (verified).
set "RDIR=%~dp0"
set "FROM=000"
set "SKIP="
set "PROBE_A="
set "PROBE_B="
set "N=0"
set "OKC=0"
set "FAILC=0"
set "REBOOTC=0"
set "STOP="
set "EXIT_CODE=0"
set "LAST="

REM WHY fail-closed: no config, no orchestrator - running phases with
REM   unknown knobs would be guessing (INS-06).
call "%RDIR%_common.bat" :load
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" exit /b 1

REM ---- arg parse (research t7: whole pattern on one line so shift &
REM      %~2 read happen in the same parse) --------------------------------
:parse
if "%~1"=="" goto :parsed
if /i "%~1"=="/from" goto :parse_from
if /i "%~1"=="/skip" ( set "SKIP=%~2" & shift & shift & goto :parse )
if /i "%~1"=="/probe-cs" ( set "PROBE_A=%~2" & set "PROBE_B=%~3" & shift & shift & shift & goto :parse )
REM WHY delayed expansion (review F8): %~1 metachars (&, |, quotes) in an
REM   echoed line are re-parsed as commands - capture into a var first,
REM   print via !VAR! (expanded after the metachar parse), then shift.
set "UNK=%~1"
echo Unknown argument: !UNK!
shift
goto :parse

REM ---- :parse_from - /from needs a numeric NNN or we fail closed -------
REM WHY validate: string LSS against a non-numeric FROM silently skips
REM   every phase (verified) - usage + rc=1 instead of silent misbehavior.
:parse_from
if "%~2"=="" goto :usage
REM WHY delims=digits: for /f splits the value on digit chars, so the
REM   first token is the first NON-digit run - an all-digit value yields
REM   no token and the body (the goto :usage) never executes.
for /f "delims=0123456789" %%a in ("%~2") do goto :usage
set "FROM=%~2"
REM WHY exact 3 digits (review F6): PH_NUM is always 3 wide and the filter
REM   below is a STRING LSS - /from 9 or /from 1000 makes every phase
REM   compare true, so zero phases ran and rc=0 (fail-open, verified).
REM   Any width other than NNN fails closed before discovery starts.
if not "!FROM:~3,1!"=="" goto :usage
if "!FROM:~2,1!"=="" goto :usage
REM WHY ';' guard (review F6): for /f's default eol is ';' - a leading-;
REM   value is skipped by the digit check above and would slip past it.
if "!FROM:~0,1!"==";" goto :usage
shift
shift
goto :parse

:parsed
REM ---- /probe-cs debug seam (elapsed math unit probe) -------------------
if not defined PROBE_A goto :discover
call :elapsed "!PROBE_A!" "!PROBE_B!"
echo PROBE_CS=!ELAPSED!
exit /b 0

REM ---- discovery + run loop (INS-01) ------------------------------------
:discover
for /f "delims=" %%f in ('dir /b /on "%RDIR%???-*.bat" 2^>nul') do (
  REM WHY lowercase %%~nf: for-var refs are CASE-SENSITIVE - the loop
  REM   declares %%f, so the capital-F spelling is not substituted at all
  REM   (single-percent path substitution inside REM would also parse-error).
  set "PH_NAME=%%~nf"
  set "PH_NUM=!PH_NAME:~0,3!"
  REM WHY NONNUM (review F7): only NNN-digit files are phases - a stray
  REM   abc-def.bat matches the ???-*.bat glob and would otherwise be
  REM   discovered, executed and listed as a phase row.
  set "NONNUM="
  for /f "delims=0123456789" %%z in ("!PH_NUM!") do set "NONNUM=1"
  if not defined NONNUM if not "!PH_NUM!"=="000" if not "!PH_NUM!"=="999" (
    if not "!PH_NUM!" LSS "!FROM!" if not "!PH_NUM!"=="!SKIP!" (
      call :run_one "%%f"
      set "LAST=!PH_NUM!"
      if "!STOP!"=="1" goto :after_loop
    )
  )
)

:after_loop
if defined STOP echo NOT RUN: phases after !LAST! were not executed.
call :print_summary
if "!EXIT_CODE!"=="3010" call :handle_reboot "!LAST!"
exit /b !EXIT_CODE!

REM ---- :run_one <phase-file> --------------------------------------------
REM WHY delegation: the tee (capture-to-log + type replay) lives ONLY in
REM   _common.bat :run_phase - this label adds summary bookkeeping on top.
:run_one
set /a N+=1
set "PH_NAME=%~n1"
call "%RDIR%_common.bat" :log "!PH_NAME!"
set "T_START=!TIME!"
call "%RDIR%_common.bat" :run_phase "%RDIR%%~1"
set "RC=!ERRORLEVEL!"
set "T_END=!TIME!"
call :elapsed "!T_START!" "!T_END!"
set /a "SECS=ELAPSED/100"
REM WHY UNQUOTED !RC! EQU: `if "0" EQU 0` is FALSE (quotes make it a
REM   string compare - verified) - research t1/t8 form is bare operands.
REM WHY 3010 first, exact match only: never `GEQ 3010` (misroutes 9009 to
REM   reboot) and never bare `if errorlevel 1` (>= semantics, t1).
if !RC! EQU 3010 (
  set "STATUS=REBOOT"
  set /a REBOOTC+=1
  set "STOP=1"
  set "EXIT_CODE=3010"
) else if !RC! EQU 1 (
  set "STATUS=FAIL rc=1"
  set /a FAILC+=1
  set "STOP=1"
  set "EXIT_CODE=1"
) else if !RC! EQU 0 (
  set "STATUS=OK"
  set /a OKC+=1
) else (
  set "STATUS=FAIL rc=!RC!"
  set /a FAILC+=1
  set "STOP=1"
  set "EXIT_CODE=1"
)
set "ROW!N!=!PH_NAME!|!STATUS!|!SECS!"
exit /b 0

REM ---- :elapsed <start> <end> -> ELAPSED cs (octal + midnight safe) -----
:elapsed
REM WHY fixed-position substrings instead of for /f delims: a space in
REM   the delims option string breaks for /f parsing (." was unexpected
REM   at this time - verified); space-strip + zero-pad make positions safe.
set "TS=%~1"
set "TS=%TS: =%"
if "!TS:~1,1!"==":" set "TS=0!TS!"
REM WHY 1xx %% 100: set /a rejects 08/09 as invalid octal (t6) - the
REM   1-prefix + mod trick parses any two-digit part as decimal.
set /a "T1=(1!TS:~0,2! %% 100)*360000+(1!TS:~3,2! %% 100)*6000+(1!TS:~6,2! %% 100)*100+(1!TS:~9,2! %% 100)"
set "TS=%~2"
set "TS=%TS: =%"
if "!TS:~1,1!"==":" set "TS=0!TS!"
set /a "T2=(1!TS:~0,2! %% 100)*360000+(1!TS:~3,2! %% 100)*6000+(1!TS:~6,2! %% 100)*100+(1!TS:~9,2! %% 100)"
REM WHY (neg>>31)*8640000: arithmetic shift of a negative value is -1,
REM   so end-before-start (midnight crossing) adds back one day in cs (t6b).
set /a "NEG=T2-T1, ELAPSED=NEG-(NEG>>31)*8640000"
exit /b 0

REM ---- :print_summary (INS-01: name, status, elapsed for ATTEMPTED) ----
:print_summary
echo.
echo ============================================
echo PHASE ^| STATUS ^| TIME(s)
for /l %%i in (1,1,!N!) do (
  for /f "tokens=1-3 delims=|" %%a in ("!ROW%%i!") do echo(%%a ^| %%b ^| %%c
)
echo --------------------------------------------
echo OK=!OKC! FAIL=!FAILC! REBOOT=!REBOOTC! attempted=!N!
exit /b 0

REM ---- :handle_reboot <phase-num> (INS-04) ------------------------------
:handle_reboot
REM WHY stop here: per CONTEXT run-all stops on 3010 - it does NOT
REM   auto-resume; re-running a completed phase is safe (INS-03) and the
REM   resume is the user's explicit /from action.
echo PHASE %~1 returned 3010 - reboot required.
echo Re-run with: 000-run-all.bat /from %~1
REM WHY AIJAIL_CI gate: unattended runs (tests/CI) must not block on the
REM   interactive pause - research t11; rc 3010 still exits after pause.
if not defined AIJAIL_CI pause
exit /b 3010

REM ---- :usage (bad /from value - fail closed before any phase runs) -----
:usage
echo Usage: 000-run-all.bat [/from NNN] [/skip NNN]
exit /b 1
