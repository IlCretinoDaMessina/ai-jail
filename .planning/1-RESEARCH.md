# Phase 1 Research: Foundation & Orchestrator Contract

**Phase:** 1 — Foundation & Orchestrator Contract
**Date:** 2026-09-28
**Source:** Empirical batch experiments (18 test scripts in `%TEMP%\opencode\res-phase1`, re-run and verified after agent interruption)

## Summary

Every batch idiom Phase 1 depends on was tested empirically on this machine (Windows 11, PowerShell 5.1 host). Findings below are verified behavior, not documentation claims. The orchestrator design that falls out of them: a thin `000-run-all.bat` (arg parsing, phase discovery, loop, summary), a label-dispatch `_common.bat` with `shift`, config loaded under `DisableDelayedExpansion`, and a PS helper for LF payloads.

## Verified batch idioms

### Errorlevel contract (INS-03/INS-04) — experiment t1/t8/t19

- `call :sub` / `call child.bat` propagates child `exit /b N` correctly: `%ERRORLEVEL%` on its own line after `call` reads fresh (rc=3010 observed).
- **`if errorlevel N` is ≥ comparison, not equality** — after `exit /b 3010`, both `if errorlevel 3010` AND `if errorlevel 1` are TRUE. Never use bare `if errorlevel 1` to detect failure when 3010 is also possible; use `if %ERRORLEVEL% EQU 1` (top-level line) or check 3010 first.
- `if %ERRORLEVEL% EQU N` on a **top-level line after call** reads fresh. Inside a parenthesized `(...)` block parsed before execution, `%ERRORLEVEL%` is stale — capture first: `set "RC=!ERRORLEVEL!"` (with `EnableDelayedExpansion`) then compare `!RC!`.
- `if errorlevel 1 ( ... )` immediately after `call` inside a block: branch fires correctly (runtime comparison), but the `%ERRORLEVEL%` *text* inside that block is stale — t8 confirmed the capture-first pattern gives the right value (`correct-capture-eq1`).
- **Rule for plans:** after every `call`, capture `set "RC=!ERRORLEVEL!"` on the next line, then branch on `!RC!` with `EQU`/`GEQ`. Never compare `%ERRORLEVEL%` inside `(...)` blocks.

### `_common.bat` dispatcher (label dispatch + shift) — experiments t17/t18

- `call "_common.bat" :label args` + `goto %~1` works; labels set caller-visible vars (`PHASE_LOG`, `INIT_OK`) and return rc via `exit /b N` — **but only with `shift` after the label**.
- Without `shift`, `:add 2 3` returned 2 (args offset by label token). With `shift` as first line of each label (t18/`_common2.bat`): `:add 2 3` → rc=5 as expected.
- Bare `call "_common.bat"` (no label) → usage message + rc=1 (guard pattern verified).
- Cross-file variable export works: `:load config.env` exported `PARSED_OK` back to caller via `endlocal & set "VAR=!VAR!"` pattern — but **the naive `setlocal`-inside-callee version leaked nothing back** (t18: `TARGET=` empty because parse happened inside callee's setlocal without the endlocal-and-set export). Config loading must either run in the caller's context or export each var across `endlocal`.
- **`goto :eof` must come after all labels are reachable** — placing `goto :eof` between labels silently truncates dispatch.

### config.env parsing (INS-06) — experiments t3/t13/t16

Verified working pattern:

```bat
setlocal DisableDelayedExpansion
for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%~dp0config.env") do (
  set "%%a=%%b"
)
```

- `#` comments and blank lines skipped (`eol=#`); `tokens=1,* delims==` keeps everything after the FIRST `=` intact — URLs with `=` (`https://example.com/path?a=b=c`) survive.
- **Values containing `&`, `?`, `=` parse fine** (t13: `URL=[https://ex.com/a?b=c&d=e]`).
- **Values containing `!` are corrupted under `EnableDelayedExpansion`** (t13: `has!bang` → `hasbang`); preserved under `DisableDelayedExpansion` (t16: `has!bang` intact). → **Parse config under `DisableDelayedExpansion`, then `setlocal EnableDelayedExpansion` afterward.**
- Quoted `set "K=V"` prevents `&` from being treated as command separator.
- Semicolon lists (`ALLOW_HOSTS_INSTALL=crates.io;github.com;...`) pass through intact — safe for per-tool allowlists later.

### Phase discovery / `/from` `/skip` (INS-01/INS-02) — experiments t5/t5b/t7

- `for /f "delims=" %%f in ('dir /b /on "%~dp0???-*.bat"')` enumerates phase files sorted by name; `!N:~0,3!` extracts the number prefix.
- Excluding `000` (self) and `999` (manual uninstall, INS-08) via nested `if not` works: only `001, 010, 020, 100, 110, 900` found in the test fixture — exactly the intended set.
- Arg parse loop: `if /i "%~1"=="/from" ( set "FROM=%~2" & shift & shift & goto :parse )` — verified `/from 030 /skip 070` → `FROM=030 SKIP=070`; unknown arg `/bogus` reported, defaults preserved (`FROM=000`). Note: `shift & shift` inside `(...)` works because it's a single parsed line executed top-down — but `%~2` must be read before the shifts (it is).

### Logging (INS-03) — experiment t12

- `call :phase > "%LOGFILE%" 2>&1` captures output while `echo captured=%ERRORLEVEL%` after the call still sees the child's rc (3010 propagated). Log content verified: `some phase output`.
- Console-vs-log: to show AND tee simultaneously, the pattern is `call :inner > log 2>&1` + `type log` after, or PowerShell `Tee-Object` wrapper — plan should pick one and state it in acceptance criteria.

### Timing for the summary table — experiment t6/t6b

- Octal trap (`08`/`09` invalid in `set /A`) defeated by the `1%%a %% 100` trick — verified elapsed `346` cs between `08:09:09.09` and `08:09:12.55`.
- Midnight rollover: `adj = neg - (neg>>31)*8640000` verified (`-499900` → `8140100`). `%TIME%` format `HH:MM:SS.CC` confirmed on this machine (`20:29:18.69`).

### Elevation self-check (INS-05) — experiment t4

- Probed `net session`, `fltmc`, `fsutil dirty query`, `net file` — results inconsistent on one machine (`net session` rc=0 once, rc=2 later; `fltmc` rc=2; `fsutil` rc=1; `net file` rc=1). **No single cmd probe is reliable.**
- **Recommendation:** PowerShell principal check as primary: `powershell -NoProfile -Exit ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator")` (emits `True`/`False`), optionally cross-checked with `net session`. Acceptance criteria must be phrased against the PS check since cmd probes vary.

### LF-only payload emission (PLT-04) — experiments lfconv + payload

- **Verified byte-level:** `[IO.File]::WriteAllText($dst, $content -replace "`r`n","`n", [Text.UTF8Encoding]::new($false))` produces pure LF (`10` bytes only, no `13`, no BOM `239,187,191`). Script: `lfconv.ps1`.
- `wsl bash -c` heredoc from .bat (t2) and printf (t2b) exist as prior art but belong to Phase 2+ — Phase 1 only needs the helper to exist and be tested (write a payload, assert bytes).

### Orchestrator interface for later phases (contract surface)

- Discovery convention: files named `NNN-name.bat` in repo root, `000` excluded, `999` excluded from auto-run.
- Each phase: idempotent self-detect, writes `logs\NNN-name.log`, returns 0/1/3010, honors elevation abort via `_common.bat :require_admin`-style helper.
- `000-run-all` resume semantics: `/from NNN` starts at first phase ≥ NNN; `/skip NNN` skips that exact phase; 3010 → pause (t11: `pause` works, rc preserved after) with reboot + `/from` message → stop.
- No phase exists between 010 and 900 until Phases 2–6 land → **Phase 1 must verify with stub/test phases** (see Validation Architecture); the glob fixture `t5b` proved discovery logic against a synthetic set (`001-test`, etc.).

## Pitfalls to bake into plans

1. `%ERRORLEVEL%` stale inside `( )` blocks — capture-first rule (t8/t19).
2. `if errorlevel N` means ≥N — never the sole failure detector when 3010 exists (t1).
3. `shift` missing in dispatcher labels silently mis-binds args (t17 vs t18).
4. `!` corruption in config values under `EnableDelayedExpansion` (t13 vs t16).
5. `endlocal` without `& set` export leaks callee variables (t18).
6. `goto :eof` placed mid-file unreachable-labels bug.
7. Octal `set /A` on `%TIME%` parts 08/09 — `1xx %% 100` trick (t6).
8. CRLF/BOM in emitted payloads — use the PS writer, byte-assert (lfconv).
9. `net session` alone is an unreliable elevation probe (t4).
10. AGENTS.md: one file = one responsibility, ≤400 lines, banner comments, no hardcoded paths (INS-06).

## Validation Architecture

How Phase 1's deliverables can be proven (feeds `01-VALIDATION.md`):

- **Unit/contract tests (matching-test convention, AGENTS.md):** `tests\verify-000-run-all.cmd` + per-helper checks exercising: arg parsing (`/from`, `/skip`, unknown), discovery (fixture dir of `NNN-*.bat`), stop-on-fail (stub phase exits 1 → run-all exits 1, later stubs never run), 3010 path (stub exits 3010 → pause + message + rc 3010), summary table emitted with phase/status/time, log files written per phase.
- **Stub phases:** throwaway `tests\fixtures\` phases (derived from `t5b`'s `001-test` set) to test run-all without Phases 2–6.
- **Config purity:** test mutates a temp copy of `config.env` (`TARGET_DRIVE`, `LINUX_USER`) and asserts no bats contain hardcoded `D:`/usernames (grep-style `findstr` check).
- **PLT-04:** helper writes a sample payload → PowerShell byte assert: no `0x0D`, no BOM.
- **Elevation:** PS-principal check returns `False` in a deliberately unelevated invocation → `010` aborts with the actionable message (acceptance phrased against PS probe).
- **Nyquist sampling:** deterministic batch tests + byte asserts — no stochastic sampling needed; every success criterion maps to at least one executable check.

## Open Questions (RESOLVED)

1. **Tee strategy** — RESOLVED (plan 01-02): capture-to-log + `type` replay (`call :run_phase > "%LOGFILE%" 2>&1` then `type "%LOGFILE%"`). Pure cmd, no PowerShell wrapper in the hot loop; console output and log content stay byte-identical. Stated in plan 01-02 acceptance criteria.
2. **`pause` on 3010 blocks automated tests** — RESOLVED (plan 01-02): gate `pause` behind `if not defined AIJAIL_CI pause`. Automated `tests\verify-run-all.cmd` sets `AIJAIL_CI=1`; interactive runs still pause with the reboot + `/from` message. Manual UAT path retained in 01-VALIDATION.md Manual-Only table.
