# Phase 1 — Foundation & Orchestrator Contract: SUMMARY

> Status: **COMPLETE — waves 1-3 + inline review closeout (2026-09-29).** Planning deviations first; execution deviations appended per wave.

## Deviations

### 0. Execution — wave 1 (plan 01-01, inline)

- **Executor failure → inline fallback (AGENTS.md empty-result recovery):** `gsd-executor` (sonnet) returned `completed` with 0/8 files twice (initial + one narrower retry naming exact output paths). Stated plainly, scratch listed (`%TEMP%\opencode\exp0101\t1-t3.bat`, `e5.bat`), logged in `deferred-items.md`; per AGENTS.md rule the second failure triggered inline execution without further asking — user had chosen "Execute plan 01-01 inline".
- **`:run_phase` rebuild instead of `call %*` (plan line ~153):** `shift` does **not** affect `%*` (t17) — `call %*` inside the label would re-dispatch the label token and loop forever when invoked externally (`call _common.bat :run_phase ...`). Implemented `shift` + `call %1 %2 %3 %4 %5 %6 %7 %8 %9 > "%PHASE_LOG%" 2>&1`; plan's tee/capture-first/type-replay semantics unchanged, asserted by `verify-exit-contract.cmd`.
- **`:classify_rc` quoted exact-compare instead of `EQU`:** `if abc EQU 5` is a cmd parse error that leaves a stale ERRORLEVEL (fail-open for non-numeric input). `if "%~1"=="3010"` etc. is total and exact — same contract-member semantics (3010 → 1 → 0, checked in that order), any other input falls through to `exit /b 1` (fail-closed). T-1-02 property preserved and strengthened.
- **Hardcoded-path sweep hardened (fixed in pass, not deferred):** plan's inline `findstr /i /c:"D:\" *.bat` has the `\"` quoting trap and cwd-only scope. Implemented recursive `dir /b /s *.bat` sweep with a `for %%P in ("D:\\" "C:\\Users")` pattern loop (findstr accepts only **one** `/c:` per call — a second prints `/c ignored` and silently drops), regex-escaped backslashes (bare `D:` matched `found:` case-insensitively), comment filter `/c:"::"` (space form `/c "::"` warns and pollutes output). Detector proven: planted `D:\foo` hit → FAIL, clean → PASS.
- **`verify-all` stop-on-first corrected to plan (fixed in pass):** initial version continued after a failure; plan requires stop and `exit /b 1` on first nonzero. Planted-failure probe: run halted at first `verify-*.cmd`, later scripts not run, rc=1; clean run `RESULT=PASS run=3` rc=0.
- **Test-first honored for all 3 tasks:** each test file run RED before implementation, GREEN after (recorded in session log).

### 0b. Execution — wave 2 (plan 01-02, inline)

- **`shift` also shifts `%0` (research gap — t17 covered `%1` only):** `%~dp0` read **after** any `shift` resolves against the shifted value (the label token), degrading to CWD — sandbox runs silently wrote per-phase logs into the repo `logs\` instead of the sandbox. Fix: capture `RDIR` (`000-run-all.bat`), `AIJAIL_BASE` (`:load`), `LOG_BASE` (`:log`) **before** any shift and use those vars everywhere afterwards. Caught by the new `verify-run-all.cmd` sandbox assertions (logs-in-sandbox), not by review.
- **`)` inside `echo` text closes a parenthesized `if` block early:** `echo FAIL: ... (log exists ...)` inside `if exist (...)` made cmd end the block at the echo's `)` — the trailing `set "FAIL=1"` ran **unconditionally** (silent `FAIL=1`, no message; minimal repro confirmed the parse). Fix: reworded the echo without parens. House rule logged: no `(`/`)` in `echo` lines that sit inside `( ... )` blocks.
- **Parens inside quoted `call`-subroutine label args crash cmd:** `call :assert_in "S8 001 ran (default)" ...` mangled argument positions → assert failed → failure echo containing the parens then parse-crashed (`- was unexpected at this time`, rc=255, empty stdout). Fix: paren-free test labels (`ran default`). Same class as the block-`echo` bug — recorded as a test-writing constraint.
- **Test-first sequence (all 3 tasks):** task 1 RED→GREEN (log-path/`%~dp0` bugs above); task 2 scenarios S4–S8 passed immediately (selection arg parse had already landed with task 1), S9 (non-numeric `/from` → usage + rc=1) was the RED driver → implemented `:parse_from` validation (`for /f "delims=0123456789"` token check) + `:usage` label; task 3 S10 RED on the three message asserts → implemented real `:handle_reboot` (message with `3010`/`reboot`/`/from`, `if not defined AIJAIL_CI pause`, rc 3010 preserved).
- **Wave-2 gate:** `cmd /c tests\verify-all.cmd` → `RESULT=PASS run=4` rc=0; all plan-01-02 deliverables verified on disk non-empty (`000-run-all.bat` 7212 B, `verify-run-all.cmd` 11269 B, 4 fixtures, `_common.bat`, `config.env`).

### 0c. Execution — wave 3 (plan 01-03, inline)

- **`DriveInfo.AvailableFreeBytes` reports 0 on this machine (plan-literal probe swapped):** `AvailableFreeBytes` (quota-aware) returned 0 GB while `TotalFreeSpace`/CIM `FreeSpace`/`Get-PSDrive` all agree on the real 734 GB — the plan-literal probe would have failed preflight unconditionally. `:check_disk` uses `[int]($d.TotalFreeSpace/1GB)` (verified `D:` → 734 vs `MIN_FREE_GB=20`); message still states actual + required GB as the plan requires.
- **Dual-caller shift bug in `:classify_admin` (caught by test cross-check, not by the requirement test):** the external-dispatch label must `shift` the label token away, but the internal `call ... :classify_admin %RESULT%` from `:require_admin` had the value in `%1` — the bare shift ate it, so **every** `:require_admin` returned 1 regardless of the probe. Task-1's cross-check agreed *vacuously* (machine is unelevated → expected 1 anyway). Fix: self-dispatch guard `if /i "%~1"==":classify_admin" shift`. Lesson recorded: cross-checks must observe the branch under test (True branch unreachable here → unit fixtures on `:classify_admin` are the real guard).
- **`call`ed phases leak config into the caller's frame:** `call 010-preflight.bat` runs `:load` in the *shared* cmd frame; `010`'s later `setlocal` snapshot already contains the loaded vars, so `exit /b` restores them — a sandbox config with `TARGET_DRIVE` deleted still "saw" the value inherited from an earlier scenario, masking the missing-key failure (P1 RED failed for the wrong reason until isolated). Fix: test clears `TARGET_DRIVE`/`LINUX_USER`/`MIN_FREE_GB` before each sandbox run. Production path is unaffected (`run-all` `setlocal`s first, so phases loaded inside it are contained); a directly-`call`ed phase from an interactive shell would leave vars behind — noted, not fixed (no production caller does this).
- **Elevation test seam design (plan-approved, integrity asserted):** tests patch a *sandbox copy* of `_common.bat` with `findstr /v /c:"ADMIN_PROBE="` (strips the init line and the probe line; the test exports `ADMIN_PROBE=True` itself). The repo copy re-initializes `ADMIN_PROBE` and re-probes on every `:require_admin` call, so there is no production bypass; `:t_integrity` hashes the repo `_common.bat` before all scenarios and after the e2e runs — unchanged.
- **Test-first sequence (all 3 tasks):** task 1 RED→GREEN (classify bug above); task 2 RED exactly as designed — P1/P2/P3/P4 rc asserts passed while message/`all checks passed` asserts failed until the checks were implemented; task 3 is **test-only** by plan (no production change) so it passed on first run — that is the e2e wiring verification, not a skipped RED.
- **Wave-3 gate:** `cmd /c tests\verify-all.cmd` → `RESULT=PASS run=5` rc=0; deliverables non-empty on disk (`010-preflight.bat` 4442 B / 98 lines, `_common.bat` 9203 B, `verify-preflight.cmd` 8557 B); repo `_common.bat` unpatched after the run; e2e evidence inspected (A: `010-preflight | FAIL rc=1`, B: `010-preflight | OK` + `all checks passed` in the sandbox phase log). `SKELETON.md` Capability-Proven checklist → 6/6 checked.

### 0d. Execution — closeout wave (inline code review, 2026-09-29)

- **Inline review instead of `gsd-code-reviewer` (AGENTS.md empty-result recovery):** the reviewer subagent returned empty twice in a prior session (logged in `deferred-items.md` #1); per AGENTS.md the step was done inline in the main session with no further retry. `REVIEW.md` written with 9 findings (2 HIGH, 4 MED, 3 LOW), each probe-verified before being called a finding.
- **Review findings F1–F9, all fixed this pass (details in `REVIEW.md`):** F1 quoted-`LSS` string compare made `:check_disk` fail OPEN (734 GB passed a 1000 GB minimum) — fixed with digits-only/no-leading-zeros validation of `MIN_FREE_GB`, digit-guard on `FREE_GB`, unquoted numeric compare; F2 the `wsl\|docker\|bash` scope-fence regex was vacuous (findstr has no alternation) — replaced with three literal checks over all three Phase-1 root bats; F3 vacuous `elevation OK` needle → real `all checks passed`; F4 `t_unelevated` now probes elevation and emits an explicit `SKIP:` when elevated (SKIP branch NOT machine-verified — this machine cannot elevate); F5 `ENABLE_NONO=1` → `0` (documented default off) with an assert so it can't drift; F6 `/from` now requires exactly 3 digits + `;`-eol guard; F7 discovery digit-validates `PH_NUM` (stray `abc-def.bat` no longer runs); F8 unknown-arg echo goes through `set UNK` + `!UNK!` (metachars not re-parsed); F9 hardcoded-path sweep also strips `REM` comment lines.
- **Test-first RED→GREEN for every fix with a code change:** tests edited first, run against pre-fix code, then production files edited. RED evidence (pre-fix): `verify-preflight` → `P5 unsatisfiable MIN_FREE_GB rc=1 expected [1] got [0]` + `P6 whole-number needle missing` + `P7 leading-zero rc expected [1] got [0]`; `verify-run-all` → `S4 non-numeric no row - [abc-def] unexpectedly found` + `S9 short/long digit /from rc expected [1] got [0]`; `verify-config-load` → `ENABLE_NONO default must be 0 ... got [1]`. GREEN post-fix: all three suites pass. F2/F3/F4/F8/F9 changed the assertion/comment/echo line itself — F2 additionally probe-verified (planted `wsl` code line → HIT, comment line → CLEAN).
- **Closeout gate:** `cmd /c tests\verify-all.cmd` → **`RESULT=PASS run=5`, rc=0** after all fixes; CRLF re-normalized (bareLF=0) for every edited `.bat`/`.cmd`/`config.env`.

### 1. Inline planning (standing deviation, AGENTS.md)

- **Rule:** AGENTS.md forbids spawning a subagent to write PLAN.md — the main session writes plans itself; subagents allowed only for research, plan-checking, and execution.
- **What happened:** `gsd-planner` spawn returned `completed` with an empty result and zero files on disk (2026-09-28). Per AGENTS.md this was treated as a subagent failure: stated plainly, scratch files listed (`%TEMP%\opencode\res-phase1` held the researcher corpus), retried implicitly by falling back to inline planning with user authorization (resume directive "continue if you have next steps").
- **Result:** `01-01-PLAN.md`, `01-02-PLAN.md`, `01-03-PLAN.md`, `SKELETON.md` written by the main session. Research/validation/pattern artifacts were also hand-written after `gsd-phase-researcher` and `gsd-pattern-mapper` spawns failed (recovered from temp, verified in `1-RESEARCH.md`).
- **Independent verification preserved:** `gsd-plan-checker` was still spawned as a subagent for every verification iteration — its output is untrusted until checked against disk, and every claimed fix was verified on disk before being marked resolved.

### 2. Plan-checker revision loop — 3/3 iterations used

| Iter | Blockers | Warnings | Info | Action |
|------|----------|----------|------|--------|
| 1 | 1 | 2 | 3 | All 6 fixed (sandbox elevation test seam, VALIDATION quick-run command, per-task map rows, task-commit wording, `:run_phase` delegation, matching-test note) |
| 2 | 0 | 1 | 1 | Fail-closed rc handling (T-1-05) made consistent: exact `EQU` matching, out-of-contract rc → fatal in plans 01/02, new fixture `004-weird.bat`, plus sandbox-seam OK e2e run added to 1-03-03 |
| 3 | 0 | 2 | 2 | Final: stale "three fixtures" count, unsatisfiable `/from`//`skip`//bogus ACs reworded to scenario-local OK-variant stubs, T-1-02 ID collision (plan 03 elevation threat → T-1-10), VALIDATION Wave 0 fixture list corrected |

- **At cap:** iteration 3 returned 0 blockers / 2 warnings / 2 info. The four remaining items were pure plan-text defects with explicit fix hints; applied directly (mode=yolo, no re-spawn of the checker — the 3-iteration budget is exhausted). Post-edit `verify.plan-structure` re-run: all 3 plans `valid=true`, 3 tasks each.
- **Gate results after final edits:** requirements coverage 7/7 (INS-01..06, PLT-04); decision coverage passed (skipped — no trackable decisions in CONTEXT.md); gap analysis: all 7 phase requirements covered (31 uncovered items belong to later phases); `state.planned-phase` set (Status: Ready to execute); ROADMAP Phase 1 plan list + wave annotations written.

### 3. No git repository (user decision)

- `commit_docs=false`, no `.git` — every commit step (§13d, executor commits) is a **no-op**. Recovery = manual `xcopy`/zip backup of `.planning\` + project files before executing. Never run git commands.

### 4. One-shot resume artifacts consumed

- `.planning/HANDOFF.json` (task 6/11 marker) and phase `.continue-here.md` (stale "mid plan-phase" blockers) deleted after successful resumption — planning through task 11 is complete.

### 5. Out of scope (not deviations, locked by CONTEXT)

- No WSL/Docker/Linux commands in Phase 1 (scope fence); `D:\.coding\.astra` never read; UI gate skipped (false positive).

## Evidence

- Plans: `.planning/phases/01-foundation-orchestrator-contract/01-01-PLAN.md`, `01-02-PLAN.md`, `01-03-PLAN.md`, `SKELETON.md`
- Verification: `gsd-sdk query verify.plan-structure` → `valid=true` ×3; `frontmatter.validate --schema plan` → valid ×3; `gsd-plan-checker` verdicts logged above (final: 0 blockers)
- Gates: §13 7/7 ✓, §13a ✓ (skipped), §13b ✓, §13c ✓, §13d skipped (no git), §13e report generated (phase reqs all covered)

## Files Changed (planning)

| File | Change |
|------|--------|
| `01-01-PLAN.md`, `01-02-PLAN.md`, `01-03-PLAN.md` | Created (9 tasks total, waves 1-2-3) |
| `SKELETON.md` | Created (architecture decisions, out-of-scope, next slices) |
| `1-RESEARCH.md` | Open questions resolved (tee strategy, 3010 pause gating) |
| `01-VALIDATION.md` | Quick-run + map rows added; Wave 0 fixture list corrected |
| `.planning/STATE.md` | planned-phase recorded, session continuity updated |
| `.planning/ROADMAP.md` | Phase 1 `**Plans**:` list + wave/cross-cutting annotations |
| `.planning/HANDOFF.json`, `.continue-here.md` | Deleted (consumed) |

## Next

`/gsd-execute-phase 1` (after a manual backup of `.planning\` + project root, since no git).
