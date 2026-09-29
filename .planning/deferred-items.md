# Deferred Items — Phase 1

| # | Subagent | Model | Phase/Plan | Failure | Attempts | Scratch / Recoverable | Status |
|---|----------|-------|-----------|---------|----------|----------------------|--------|
| 1 | `gsd-executor` | sonnet | Phase 1 / plan 01-01 (wave 1) | Returned `completed` with empty result and **zero files written** — 0/8 target outputs on disk after both attempts | 2 (initial + narrower retry naming exact paths; AGENTS.md max-retry of 1 exhausted) | Run 1 left `%TEMP%\opencode\exp0101\t1-t3.bat` (1,269 B) and `%TEMP%\opencode\exp0101\e5.bat` (1,207 B) — re-runs of RESEARCH.md experiments, NOT plan deliverables; run 2 left nothing | Unresolved — user decision required (inline / retry override / diagnose spawn layer) |

Context: same empty-return pattern seen 2026-09-28 for `gsd-phase-researcher`, `gsd-pattern-mapper`, `gsd-planner`. `gsd-plan-checker` spawns worked (3/3 on 2026-09-29). Pattern suggests `gsd-executor`-specific spawn failure on this runtime, not a prompt-quality issue (retry 2 was minimal-path).

Logged: 2026-09-29, execute-phase 1 wave 1.

---

## Code-review deferrals (inline review, 2026-09-29)

Source: `REVIEW.md` §Deferred — findings consciously left unfixed this pass (defects found AND fixed in the same pass live in `01-SUMMARY.md` §0d instead).

| ID | Sev | File | Item | Why deferred |
|----|-----|------|------|--------------|
| D1 | LOW | `_common.bat:50-54` (`:load`) | `:load` inherits ambient env for any key absent from `config.env` — `setlocal` snapshots the environment, it does not sanitize it | Fix needs a canonical key list (design change, cross-phase); every key is defined today and tests clear knobs per-scenario |
| D2 | LOW | `010-preflight.bat` (`:check_user`) | Unreachable branch — cmd can't hold an empty var, so `:check_config`'s `not defined` always fires first | Plan-mandated checklist item (`01-03-PLAN.md:143`); harmless defense-in-depth; removing it would diverge from the approved plan |
| D3 | LOW | `000-run-all.bat` | `/skip` accepts garbage (benign exact-match no-op); `/probe-cs` test seam ships in the orchestrator (plan-approved); `;`-prefixed 3-char filename slips discovery's digit check (eol hole, self-authored filename only) | Adversarial-local only; guards add complexity without a real failure mode |
| D4 | LOW | `_common.bat:93` (`:run_phase`) | `call %1 ... %9` unquoted — a caller passing an unquoted spaced path breaks loudly, not silently | Internal API; every current caller quotes (`000-run-all.bat:105`) |
| D5 | LOW | `010-preflight.bat:75`, `:87` | Config values interpolated into PowerShell one-liners (`'%TARGET_DRIVE%'`); a `'` in the value would break the probe | `config.env` is operator-owned and pre-validated; hostile config values are outside the threat model |
| D6 | INFO | `010-preflight.bat` | Standalone invocation writes no `logs\010-preflight.log` — the tee lives in `_common.bat :run_phase` (run-all path only) | INS-03 satisfied through the orchestrator (e2e asserts the log); standalone is diagnostic |

Logged: 2026-09-29, closeout review wave.
