# Roadmap: AI Jail Automation (WSL2 + ai-jail)

## Overview

Build and verify a config-driven, fail-closed installer for a dedicated WSL2 distro, with isolated per-tool sandboxes, controlled network access, human-managed secrets, and an adversarial final verification suite. The original six-phase milestones remain the project scope. The operational status below reflects the work completed through 2026-10-01; it does not imply that unexecuted installer or final verification tests have passed.

**Current execution point:** Phases 000–070 have been completed on the dedicated `ai-jail` distro. The three Phase 080 Option C wrappers have passed individual tests, but Phase 080 is **INCOMPLETE** until its installer and lifecycle tests pass. Phase 090 and later phases have not started.

**Safety boundary for remaining work:** Do not rerun Phases 000–070, modify other WSL distros (including `docker-desktop`), edit global `.wslconfig`, re-enable automount or interop, or invoke `wsl --shutdown`. If restarting the dedicated distro is necessary, scope the operation to `wsl --terminate ai-jail` after explicit review. Never relax isolation to make an application install succeed.

## Phases

- [x] **Phase 1: Foundation & Orchestrator Contract** — `000-run-all`, `_common.bat`, preflight and the strict `0` / `1` / `3010` exit-code contract.
- [x] **Phase 2: WSL2 Distro & Isolation Hard Gate** — dedicated distro and verified 050 isolation gate; preserve its accepted configuration.
- [x] **Phase 3: Verified Jail Toolchain** — completed through 070; pinned ai-jail 2.2.0 and relied-upon flags verified.
- [ ] **Phase 4: Jailed Workspaces & Per-Tool Installs** — Phase 080 wrapper testing completed; installer acceptance and Phase 090 installs remain.
- [ ] **Phase 5: Hardening, Maintenance & Editor** — follow Phase 090; preserve optional feature flags and existing isolation.
- [ ] **Phase 6: Adversarial Verification & Safe Rollback** — Phase 900 evidence and manual-only 999 rollback remain.

## Ordering and hard gates

1. The accepted 050 and 070 gates are prerequisites for 080. Preserve their evidence; do not rerun completed phases as a shortcut.
2. Finish and accept 080 before beginning 090. A failed 080 check blocks 090 and later phases.
3. Phase 090 must install tools inside the jail, with install-time network access separate from runtime per-tool allowlists. A failed 090 gate blocks subsequent phases.
4. Complete applicable 100/110 hardening, maintenance, backup and human documentation work before final 900 acceptance.
5. Run 900 against the live system, with positive controls and non-vacuous negative tests. Do not treat a report, marker file or earlier wrapper test as a substitute.
6. `999-uninstall-rollback` is manual-only, requires confirmation, and is never called by the orchestrator. It must not touch C: user data.
7. Network default-deny applies to processes launched through the wrappers; do not claim that an unsandboxed process in the WSL distro is itself network-isolated.

## Phase details and acceptance criteria

### Phase 1 — Foundation & Orchestrator Contract (complete)

Config-driven `000-run-all` supports `/from` and `/skip`, stops on failure, handles `3010`, and summarizes attempted phases. `_common.bat` defines configuration loading, logging, classification and LF payload writing. Preserve the exact-match exit-code contract and capture error codes immediately.

### Phase 2 — WSL2 Distro & Isolation Hard Gate (complete)

The dedicated distro was established on the target drive and the 050 gate was completed. Preserve disabled drive automount, mountFsTab, interop and Windows PATH propagation. No global WSL settings or pre-existing distros are in scope. Historical phase plans may describe `wsl --shutdown`; it is prohibited in the current remaining-work procedure.

### Phase 3 — Verified Jail Toolchain (complete)

The Linux prerequisites and pinned ai-jail 2.2.0 were installed through 070. The relied-upon sandbox flags were individually probed. Preserve the accepted installation and avoid changes to earlier phase scripts.

### Phase 4 — Jailed Workspaces & Per-Tool Installs (in progress)

**080 — Jailed workspaces and wrappers**

The operational state already contains `~/projects/{opencode-work,comfyui,scratch}`, initial Git history, `~/.secrets`, and three tested wrappers. The two tool environment files are reported empty and mode `0600`; wrappers are reported owned by `aijail:aijail` and mode `0700`. The Option C interface is:

- No arguments: launch interactive Bash.
- `-c COMMAND [ARG...]`: launch Bash with the supplied command and arguments.
- `-- COMMAND [ARG...]`: execute the command directly.
- Other forms: usage failure inside the wrapper; child exit codes propagate unchanged.

All wrappers must use `--clean --no-save-config --private-home --hide-dotdir .secrets`, map only their own project for writing, and preserve the respective network and environment-file policies. `jail-shell` must remain offline. See `tests/phase-080-validation-report.md` for chronological wrapper evidence and exact final tested contents.

**080 installer acceptance remains outstanding:**

1. Produce corrected `080.bat` and, if retained, its companion `080-install.ps1` using `_common.bat` conventions. The earlier draft pair is rejected and must not be executed.
2. Generate runtime allowlists from `config.env`, rejecting wildcards (`*`), malformed hostnames, empty list elements, whitespace, shell metacharacters and unsafe values before making changes. A wholly empty allowlist means `--no-network`. Keep `ALLOW_HOSTS_INSTALL` separate for 090 only.
3. Validate the configured distro and Linux user, prerequisites, target file types, ownership and symlinks. Fail closed on invalid configuration, sandbox startup failure or unexpected return codes.
4. Handle clean and partial installation without truncating or overwriting existing credentials, project data or Git history. Create new empty secret files securely, preserve existing secret contents, and enforce the intended permissions.
5. Stage all generated wrappers, verify their contents and permissions, then deploy with a reviewed recovery/rollback procedure that cannot leave an unreported mixed state. Do not generate `.ai-jail` files in project worktrees.
6. Test negative configuration cases before applying the complete installer. Test a fresh install in an appropriate disposable test state, then controlled application to the dedicated distro, idempotent rerun and partial-state recovery. Retest security properties after deployment.
7. Log actual commands, expected and observed outcomes, exit codes, corrections and final hashes. Mark 080 complete only after all acceptance gates pass.

**090 — Per-tool installation (not started):**

Install OpenCode and ComfyUI only when their `INSTALL_*` flags enable them. Use the installation-specific allowlist only during jailed installation; retain project-local installation and version pinning in `~/projects/versions.txt`. ComfyUI uses its own virtual environment, no custom nodes by default, and binds `127.0.0.1`; verify Windows localhost access and LAN denial. Do not widen runtime allowlists or disable isolation to fix dependencies. The 090 gate requires real application startup under the intended jails.

### Phase 5 — Hardening, Maintenance & Editor (not started)

Complete applicable 100/110 work after 090: remove passwordless sudo; verify secret permissions; implement and actually verify scheduled maintenance; produce a dated target-drive backup; document password/API-key handling, model import and VHDX limits. `INSTALL_VSCODE=0` means the optional editor installation is skipped. If enabled later, document Layer-1 limitations and never restore interop or automount as a workaround.

### Phase 6 — Adversarial Verification & Safe Rollback (not started)

Implement and execute `900-verify-all` against the live installation. Recheck the 050 properties, secret hiding with a positive control, own-project writes and cross-project read/write denial, runtime allowlists and cross-tool denial, scratch no-network, direct-IP/host/LAN bypass denial, read-only system paths, disposable private-home writes, exit propagation, wrapper integrity and ComfyUI localhost-only binding. Pair deny tests with meaningful positive controls and bounded timeouts; document CDN-dependent checks as WARN where the requirements specify. Acceptance requires `logs\REPORT.txt` with all mandatory checks PASS and explicit treatment of warnings. Implement the separate manual-only, confirmation-gated, C:-safe 999 rollback.

## Execution plan from 2026-10-01

| Step | Deliverable | Gate to proceed |
|---|---|---|
| 1 | Corrected 080 installer files | Static review passes; rejected drafts remain blocked |
| 2 | 080 negative, fresh/partial, idempotency and live regression tests | Documented 080 acceptance PASS |
| 3 | 090 application installation and startup evidence | Jailed tools work without relaxing isolation |
| 4 | Applicable 100/110 hardening, maintenance, backup and README | Verified operation and human instructions |
| 5 | 900 adversarial suite and report | All mandatory live checks PASS |
| 6 | Manual-only 999 rollback design and final audit | Scope and confirmation reviewed; handover complete |

## Evidence and change-control rules

- Preserve `.planning/01-*`, `1-RESEARCH.md`, `REVIEW.md` and `VERIFICATION.md` as historical Phase 1 records. Do not retroactively rewrite them to imply later testing.
- `REQUIREMENTS.md` is the requirements/traceability specification. Change completion marks only after the corresponding phase gate supplies evidence; a wrapper-only PASS does not close all Phase 4 or final 900 requirements.
- Append new installer and application test evidence to the relevant phase validation report rather than replacing prior results. Distinguish observed facts from proposed design and untested claims.
- ChatGPT prepares and reviews scripts; the user approves local changes and execution; OpenCode may inspect and run approved commands in the local environment and return evidence. No unattended destructive or broad-scope operation.
- No completed earlier phases are rerun; no Phase 090 work starts before Phase 080 acceptance.

## Progress

| Phase | Operational status | Acceptance basis / outstanding work |
|---|---|---|
| 1. Foundation & Orchestrator | Complete | Existing Phase 1 validation |
| 2. Distro & 050 isolation | Complete | Prior operational gate; preserve configuration |
| 3. Toolchain through 070 | Complete | Prior operational gate and CLI probes |
| 4. 080 / 090 | In progress | Option C wrapper tests passed; 080 installer and 090 outstanding |
| 5. Hardening & maintenance | Not started | 100/110 and documentation outstanding |
| 6. Adversarial verification & rollback | Not started | 900 live evidence and manual-only 999 outstanding |

*Roadmap status updated: 2026-10-01. Completion statements for Phases 2–3 reflect the operational handoff; consult the corresponding execution logs for their original evidence.*
