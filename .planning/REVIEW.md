# Phase 1 — Code Review (inline) — REVIEW.md

**Date:** 2026-09-29 · **Reviewer:** main session (inline, no subagents — `gsd-code-reviewer` exhausted per AGENTS.md empty-result recovery, see `deferred-items.md` #1)
**Scope:** `config.env`, `000-run-all.bat`, `010-preflight.bat`, `_common.bat`, `tests\verify-*.cmd` (6), `tests\bytecheck.ps1`, `tests\fixtures\*.bat` (4)
**Lens (from closeout brief):** fail-open handling, ERRORLEVEL races, injection via config/arg values, scope fence, exit-code contract 0/1/3010, CRLF, documented anti-patterns (paren-in-echo, `shift`/`%~dp0`, quoted `EQU`, `findstr /c:`).
**Method:** every claim below was verified by reading the file and/or an empirical cmd/PowerShell probe — probe transcripts in "Probe evidence".

**Verdict:** gate was GREEN before review (`RESULT=PASS run=5`, rc=0). Review found **2 HIGH fail-open/vacuous guards, 4 MEDIUM, 3 LOW** — all 9 fixed in this pass, each with a test that reproduces RED against the pre-fix code (except F2/F3/F8/F9, where the defect is the assertion/line itself; RED-proven where feasible, see Status column). Gate re-run after fixes: **PASS run=5, rc=0**.

## Findings

| ID | Sev | Location | Finding | Fix | Status |
|----|-----|----------|---------|-----|--------|
| F1 | HIGH | `010-preflight.bat:80` (`:check_disk`) | **Free-space check fails OPEN.** Operands are quoted (`if not "!FREE_GB!" LSS "!MIN_FREE_GB!"`) and cmd compares quoted operands as **strings** (probed: `"5" LSS "20"` = FALSE, `5 LSS 20` = TRUE). Any free/min pair whose string form doesn't sort correctly passes: 9 GB free passes `MIN_FREE_GB=20`; 734 GB passes `1000`. | Validate `MIN_FREE_GB` is digits-only, no leading zeros (rejects octal/string misparse) in `:check_config`; digit-validate `FREE_GB` (a captured PS error line would otherwise reach the compare as text); compare **unquoted** (numeric). | FIXED — test P5/P6/P7 added; P5/P6/P7 RED pre-fix (rc=0 / missing needle), GREEN post-fix |
| F2 | HIGH | `tests\verify-preflight.cmd:85` (`:t_scope_fence`) | **Scope-fence guard is vacuous.** `findstr /r /c:"wsl \|docker\|bash"` — findstr has no alternation; `\|` is a literal pipe, so the whole pattern can never match (probed: file containing `docker`, `wsl`, `bash` → NO_MATCH). The locked Phase-1 fence has no automated protection. Also covered only `010-preflight.bat`, while the fence applies to all Phase-1 root bats. | Three literal `findstr` checks (one per token) in a `:fence_one` helper, run over `010-preflight.bat`, `000-run-all.bat`, `_common.bat`; comment strip extended to ` rem`-prefixed and `::` lines. | FIXED — fence now fires on any of the three tokens/files (probe-verified pattern; code reviewed, gate green) |
| F3 | MED | `tests\verify-preflight.cmd:75` | **Vacuous needle:** asserts output does NOT contain `elevation OK` — that string appears nowhere in the repo, so the "no later-check output before the elevation abort" assertion can never fail. | Needle → `all checks passed` (010's real success line, printed only if checks run past elevation). | FIXED — assertion now meaningful (unelevated gate run exercises it) |
| F4 | MED | `tests\verify-preflight.cmd:66-80` (`:t_unelevated`) | **Suite is not deterministic on an elevated shell.** Asserts `010` rc=1 unconditionally; elevated, 010 passes all checks → rc=0 → suite RED. `:t_e2e` branches on real elevation; this test doesn't. | Probe elevation first; elevated → explicit `SKIP:` line (no silent pass, no false FAIL). | FIXED — unelevated path exercised by the gate; the elevated SKIP branch is code-reviewed but **not machine-verified** (this machine cannot elevate) |
| F5 | MED | `config.env:27` | **`ENABLE_NONO=1` contradicts the documented default.** `PROJECT.md:82` ("`ENABLE_NONO=0` by default"), `REQUIREMENTS.md` SBX-08 ("default off"), `research/SUMMARY.md:50`. Would install the optional Layer-3 tool by default — against the documented posture. | `ENABLE_NONO=0`; assertion added to `verify-config-load.cmd` so the default can't drift silently. | FIXED — test asserts value 0 (RED pre-fix, GREEN post-fix) |
| F6 | MED | `000-run-all.bat:56-65` (`:parse_from`) | **`/from` accepts any digit run → silent no-op.** Digit check only; `/from 9` or `/from 1000` make every `PH_NUM LSS FROM` string comparison true → zero phases run, rc=0 (fail-open against the NNN contract). Plus a `for /f` eol=`;` hole: a leading-`;` value skips the digit check entirely. | Exact-3-digit length validation + explicit `;` first-char guard, all before any phase runs. | FIXED — S9 extended with `/from 9` and `/from 1000` (RED pre-fix: rc=0; GREEN post-fix) |
| F7 | MED | `000-run-all.bat:76-89` (`:discover`) | **Discovery executes non-numeric phase files.** Only `000`/`999` excluded by name; a stray `abc-def.bat` / `bak-old.bat` matches `???-*.bat`, passes the `LSS` filter and runs as a phase. | Digit-validate `PH_NUM` per iteration (`NONNUM` guard) before the filter chain. | FIXED — S4 seeds `abc-def.bat` and asserts it is neither run nor listed (RED pre-fix, GREEN post-fix) |
| F8 | LOW | `000-run-all.bat:49` | **Metachars in an echoed argument are re-parsed:** `echo Unknown argument: %~1` — `000-run-all.bat "a&b"` executes `b`; quotes break the line. | Capture into `UNK` (quoted `set`, safe), print via delayed expansion `!UNK!` (expanded after metachar parse). | FIXED — S8 needle unchanged and green |
| F9 | LOW | `tests\verify-config-load.cmd:68` | **Hardcoded-path sweep excludes `::` comments but not `REM`** — any future `REM ... D:\...` comment false-FAILs the whole suite (latent flakiness, not a wrong pass). | Chain `findstr /v /i /b /c:"rem"` into the filter. | FIXED — no functional change on current code |

## Deferred / accepted (not fixed this pass)

| ID | Sev | Location | Item | Why deferred |
|----|-----|----------|------|--------------|
| D1 | LOW | `_common.bat:50-54` (`:load`) | `:load` inherits **ambient environment** for any key absent from `config.env` (a shell-level `LINUX_USER` would flow into preflight if the key were removed from the file). Corrects `.continue-here.md`'s "production safe — run-all setlocals first": `setlocal` snapshots the environment, it does not sanitize it. | Fix needs a canonical key list (design change, cross-phase); current `config.env` defines every key and the suite clears knobs per-scenario. → `deferred-items.md` |
| D2 | LOW | `010-preflight.bat:55-59` (`:check_user`) | Unreachable branch: cmd cannot hold an empty variable (`set "K="` deletes it) and `:load` drops empty keys, so `:check_config`'s `not defined` always fires first — the "LINUX_USER is empty" message can never print. | Plan-mandated checklist item (`01-03-PLAN.md:143`) and harmless defense-in-depth; removing it would diverge from the approved plan. Documented, kept. → `deferred-items.md` |
| D3 | LOW | `000-run-all.bat:47`, `:17`, discovery | `/skip` accepts garbage (exact-match no-op — benign); `/probe-cs` test seam ships in the orchestrator (plan-approved); a `;`-prefixed 3-char filename still slips the discovery digit check (eol hole — self-authored filename, not user input). | Benign or adversarial-local only; guarding `/skip` and filenames adds complexity without a real failure mode. → `deferred-items.md` |
| D4 | LOW | `_common.bat:93` (`:run_phase`) | `call %1 %2 ... %9` is unquoted — a caller passing an unquoted path with spaces breaks (loudly, not silently). | Internal API; every current caller quotes (`000-run-all.bat:105`). Guarding costs a `%~1` re-quote that changes nothing today. → `deferred-items.md` |
| D5 | LOW | `010-preflight.bat:75`, `:87` | Config values are interpolated into PowerShell one-liners (`'%TARGET_DRIVE%'`); a value containing `'` would break the probe. | `config.env` is operator-owned, no-secrets, and pre-validated; hostile config values are outside the threat model. → `deferred-items.md` |
| D6 | INFO | `010-preflight.bat` | Running `010-preflight.bat` standalone writes no `logs\010-preflight.log` — the per-phase tee lives in `_common.bat :run_phase` (run-all path only). | INS-03 is satisfied through the orchestrator (e2e asserts the log); standalone invocation is diagnostic. Design choice, documented in `000-run-all.bat:98-99`. |

## Probe evidence (all run on this machine, 2026-09-29)

| Probe | Result | Consequence |
|-------|--------|-------------|
| `if "5" LSS "20"` vs `if 5 LSS 20` | FALSE vs TRUE | quoted operands → string compare ⇒ F1 fail-open |
| `if "734" LSS "1000"` | FALSE | 734 GB passes a 1000 GB minimum under the old code |
| `if 734 LSS 1000000000` / `if not ...` | TRUE / FALSE | unquoted numeric compare behaves correctly ⇒ fix direction |
| `if 9 LSS 010` | FALSE | leading zeros do **not** parse as plain decimal (octal/string) ⇒ reject them |
| `if 734 LSS abc` | TRUE | garbage reaching the compare still falls into `:failed` ⇒ fail-closed belt under the fix |
| `findstr /r /c:"wsl \|docker\|bash"` on a file containing all three tokens | NO_MATCH | F2: alternation unsupported ⇒ old fence vacuous |
| `for /f "delims=0123456789" in ("20"/"abc"/";")` with delayed expansion ON in-file | CLEAN / FIRED / CLEAN | validation idiom sound in `010` (`setlocal` at line 22); eol=`;` hole exists ⇒ explicit `;` guard in F6 |
| all edited `.bat`/`.cmd` | CRLF, no BOM | line endings preserved (CRLF normalizer run after every edit) |

## Approved design — not re-litigated

Exact-match rc classification (no `EQU`/`GEQ`), `TotalFreeSpace` disk probe, sandbox-only `ADMIN_PROBE` seam with repo-hash integrity, `AIJAIL_TEST_SKIP_INTERNET` test hatch, scope-fence verification itself (per `.continue-here.md` closeout brief).

## Gate evidence

`cmd /c tests\verify-all.cmd` → **`RESULT=PASS run=5`, rc=0** after all fixes (see `01-SUMMARY.md` §0d for the RED→GREEN sequence).
