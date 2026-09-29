# Phase 1: Foundation & Orchestrator Contract - Context

**Gathered:** 2026-09-28
**Status:** Ready for planning
**Source:** User directives (direct, discuss-phase skipped by explicit user instruction)

<domain>
## Phase Boundary

Phase 1 delivers ONLY:
- `000-run-all.bat` — config-driven orchestrator (`/from NNN`, `/skip NNN`, stop-on-fail, summary table)
- `_common.bat` — shared helpers (incl. `require_admin` for INS-05, LF-emitting payload helper for PLT-04)
- `config.env` — all knobs (`TARGET_DRIVE`, `DISTRO`, `LINUX_USER`, allowlists, `INSTALL_*`, `MIN_FREE_GB`)
- `010-preflight.bat` — Windows-only preflight (see decisions)
- The exit-code contract: 0 (OK/skip), 1 (fatal), 3010 (reboot)

NO WSL, distro, or Linux commands anywhere in this phase. WSL presence/version → 020; distro-name conflict → 030 (or guarded check skipped when WSL absent).

</domain>

<decisions>
## Implementation Decisions

### Scope fence
- Phase 1 produces ONLY the five items listed in Phase Boundary. Nothing from Phase 2+ (distro import, wsl.conf, gates 050/070/090) may leak in.
- 010-preflight contents (locked): admin/elevation check, virtualization enabled, free disk space on `TARGET_DRIVE`, `config.env` validity, `LINUX_USER` non-empty, internet reachable. NO Docker Desktop check (Docker/systemd out of scope). NO WSL checks.

### Exit-code contract
- Every phase returns exactly 0, 1, or 3010. `000-run-all` stops on first failure; on 3010 it pauses with reboot + `/from` re-run instructions, then stops.
- All bats live in the repo (`D:\.coding\.ai-jail\`), logs in `logs\NNN-name.log` under the repo. Never hardcode drive letters — everything derives from `config.env` (`TARGET_DRIVE` etc.).

### Platform constraints
- No git repository exists — commit steps are no-ops. Recommend the user make a manual backup (e.g. `xcopy`/zip of `D:\.coding\.ai-jail`) before executing this phase; plans may include such a reminder but must not invoke git.
- Linux-side payloads emitted from .bat files must use LF line endings (PLT-04) — an `_common.bat` helper owns this.

### Bat-coding gotchas (locked)
- `_common.bat` must handle `%ERRORLEVEL%` inside `if` blocks via delayed expansion (`setlocal EnableDelayedExpansion` / `!ERRORLEVEL!`) or `call :sub` patterns — plain `%ERRORLEVEL%` inside a block reads a stale value.
- `wsl -l` emits UTF-16 (relevant later, NOT this phase).

### Claude's Discretion
- Exact file/row layout of `config.env`, log line format, summary table column widths, ordering of preflight checks, testing approach for idempotency simulation.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — INS-01..INS-06, PLT-04 (Phase 1 requirement IDs)
- `.planning/ROADMAP.md` — Phase 1 goal, success criteria, Mode: mvp
- `.planning/research/SUMMARY.md` + STACK/FEATURES/ARCHITECTURE/PITFALLS — project research incl. bat/WSL pitfalls

No external specs — requirements fully captured in decisions above.

</canonical_refs>

<specifics>
## Specific Ideas

- Recommended pre-phase manual backup of the project folder (no-git recovery story).
- `000-run-all` must be testable end-to-end in Phase 1 against 010 (elevation, virtualization, free space, config validity, internet) — no empty phase list.

</specifics>

<deferred>
## Deferred Ideas

- WSL presence/version checks → Phase 2 (020)
- Distro-name conflict check → Phase 3 (030) or guarded skip-if-no-WSL
- Docker Desktop presence check → dropped entirely (out of scope)

</deferred>

---

*Phase: 01-foundation-orchestrator-contract*
*Context gathered: 2026-09-28 from user directives (discuss-phase skipped by instruction)*
