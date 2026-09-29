# Walking Skeleton — AI Jail Automation (WSL2 + ai-jail)

**Phase:** 1
**Generated:** 2026-09-29

## Capability Proven End-to-End

> One command: `000-run-all.bat` discovers `NNN-*.bat` phases, loads `config.env`, runs `010-preflight.bat` for real under the 0/1/3010 exit-code contract, writes `logs\010-preflight.log`, and prints a summary table — proven by `tests\verify-all.cmd`, not by fixtures alone.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Language / runtime | cmd batch + in-box PowerShell 5.1 probes | Project constraint (PROJECT.md): no JS/TS build tooling; PS only where cmd is unreliable (elevation, bytes, DriveInfo) |
| Shared helpers | `_common.bat` label dispatcher: `shift` first line, `endlocal & set` exports, `goto :eof` only after all labels | Empirically verified dispatch (t17/t18); naive setlocal leaks nothing, missing shift mis-binds args |
| Config | single `config.env`, `KEY=VALUE`, parsed under `DisableDelayedExpansion` (`eol=# tokens=1,* delims==`) | `!`-values survive (t16), `&`/`=`/URLs intact (t13); one file drives all drives/users/flags (INS-06) |
| Error handling | capture-first `set "RC=!ERRORLEVEL!"` after every call; classify 3010 → 1 → 0 with `EQU`/`GEQ` | Stale `%ERRORLEVEL%` in parsed blocks and ≥-semantics of `if errorlevel` both proven (t1/t8/t19) |
| Logging | per-phase `logs\NNN-name.log` via capture-to-log + `type` replay | Console and log byte-identical; tee without PowerShell in the hot loop (RESEARCH open question RESOLVED) |
| LF payloads | `_common.bat :write_lf` → PowerShell `[IO.File]::WriteAllText(... UTF8Encoding($false))` | Byte-verified no CRLF/BOM (lfconv); only sanctioned emitter for Linux-side files (PLT-04) |
| Elevation | single `:require_admin` helper, PowerShell-principal `IsInRole(Administrator)` | No cmd probe is reliable on this machine (t4); one helper, no per-phase copies |
| Test harness | pure-cmd `tests\verify-*.cmd` + aggregate `tests\verify-all.cmd` + `tests\bytecheck.ps1` + fixture stubs | AGENTS.md matching-test convention; no framework dependency; <5s feedback |
| 3010 UX | `if not defined AIJAIL_CI pause` + reboot/`/from` message | Interactive pause kept, unattended tests unblocked (RESEARCH open question RESOLVED) |

## Stack Touched in Phase 1

- [x] Config scaffold — `config.env` with every knob (TARGET_DRIVE, DISTRO, BASE_DISTRO, LINUX_USER, ALLOW_HOSTS_*, MIN_FREE_GB, INSTALL_*, ENABLE_NONO)
- [x] Shared helpers — `_common.bat` (`:load`, `:log`, `:classify_rc`, `:write_lf`, `:require_admin`)
- [x] Routing — `000-run-all.bat` phase discovery (`???-*.bat`), `/from`, `/skip`, stop-on-fail, summary table
- [x] Contract — exit codes 0/1/3010 honored by orchestrator AND the real phase (3010 path CI-gated)
- [x] Real phase — `010-preflight.bat` (elevation, virtualization, free space, config validity, LINUX_USER, internet) run end-to-end by run-all with `logs\010-preflight.log`
- [x] Verification — `tests\verify-all.cmd` green covers config, exit contract, LF bytes, run-all, preflight

## Out of Scope (Deferred to Later Slices)

- WSL presence/version checks → Phase 2 (020)
- Distro import, `wsl.conf`, automount severing, 050 isolation gate → Phase 2
- ai-jail install, `--allow-host`/GPU capability proofs, 070 gate → Phase 3
- Wrappers, per-tool allowlists, jailed installs, 090 gate → Phase 4
- Hardening, scheduled tasks, VS Code, README.txt → Phase 5
- 900-verify-all, 999-uninstall-rollback → Phase 6
- Docker Desktop check → dropped entirely (out of scope)

## Subsequent Slice Plan

Each later phase adds one vertical slice on top of this skeleton without altering its architectural decisions (config.env sole source, capture-first rc, `_common.bat` dispatch, LF writer, matching tests):

- Phase 2: dedicated WSL2 distro on `%TARGET_DRIVE%` + 050 gate proving Windows drives unreachable
- Phase 3: pinned ai-jail behind the gate with every relied-upon flag proven at install time
- Phase 4: `jail-*` wrappers enforcing per-tool allowlists, secrets invisibility, write confinement
- Phase 5: hardening, automated updates/backups, VS Code, README.txt human steps
- Phase 6: adversarial 900 suite → all-PASS `logs\REPORT.txt` + C:-safe 999 rollback
