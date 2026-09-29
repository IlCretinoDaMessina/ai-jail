# Roadmap: AI Jail Automation (WSL2 + ai-jail)

## Overview

Build the installer in strict dependency order: a config-driven orchestrator with a hard exit-code contract first, then a dedicated WSL2 distro whose 050 isolation gate must pass before anything valuable installs, then the ai-jail toolchain with every relied-upon flag proven at install time, then per-tool jail wrappers through which opencode/ComfyUI are installed, then Windows-side hardening and maintenance, and finally the adversarial 900 suite that re-derives every isolation claim from the live system into an all-PASS `logs\REPORT.txt` — plus a C:-safe manual rollback. Fail-closed throughout: gates at 050/070/090 block subsequent phases; verification comes last.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation & Orchestrator Contract** - config-driven `000-run-all` (`/from`, `/skip`, stop-on-fail, summary table) plus shared `_common.bat` helpers and `010-preflight`
- [ ] **Phase 2: WSL2 Distro & Isolation Hard Gate** - dedicated distro on the target drive with `wsl.conf` in effect and a 050 gate proving Windows drives unreachable before anything installs
- [ ] **Phase 3: Verified Jail Toolchain** - Linux base packages + pinned ai-jail installed, with every relied-upon flag (`--allow-host`, `--dry-run`, GPU path) proven working
- [ ] **Phase 4: Jailed Workspaces & Per-Tool Installs** - `jail-*` wrappers enforce per-tool allowlists, secrets invisibility and write confinement; opencode and ComfyUI installed through the jail
- [ ] **Phase 5: Hardening, Maintenance & Editor** - passwordless sudo removed, weekly updates + backups scheduled, VS Code connected with Layer-1 warning, README.txt human steps documented
- [ ] **Phase 6: Adversarial Verification & Safe Rollback** - `900-verify-all` proves every isolation claim into an all-PASS `logs\REPORT.txt`; manual-only, C:-safe `999` rollback

## Ordering Constraints

Hard dependencies the plans must preserve:

- 050 gate before anything installs — 060+ blocked until isolation is proven (fail-closed)
- Hard gates at 050 (Phase 2), 070 (Phase 3), 090 (Phase 4) — a failed gate blocks all subsequent phases
- 040 (`wsl.conf` written + `wsl --shutdown` applied) → 050 (gate verifies behavior) ordering within Phase 2
- 060 AppArmor/userns fix → 070 ai-jail dry-run probe ordering within Phase 3
- Verification (900/999) last — Phase 6 depends on everything it asserts
- No phase between 050 and 080 may claim network default-deny (per-process: true only once a wrapper first execs)

## Phase Details

### Phase 1: Foundation & Orchestrator Contract
**Goal**: A config-driven, resumable orchestrator runs every phase in order under a strict exit-code contract — the trust foundation no later phase can be honest without.
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: INS-01, INS-02, INS-03, INS-04, INS-05, INS-06, PLT-04
**Success Criteria** (what must be TRUE):
  1. `000-run-all` executes phases 010→900 in order, stops on the first failure, and prints a final summary table (phase / status / time) for every phase it attempted.
  2. A user can resume an interrupted run with `/from NNN` or bypass a phase with `/skip NNN`; when any phase returns 3010, run-all pauses with a clear reboot + `/from` re-run message before stopping.
  3. Every phase writes `logs\NNN-name.log` and returns only 0 (OK/skip), 1 (fatal), or 3010 (reboot); admin phases run without elevation abort with a clear, actionable message.
  4. All drives, paths, usernames, allowlists and install flags come from `config.env` — changing `TARGET_DRIVE` or `LINUX_USER` requires no code edits — and Linux-side payloads emitted from bats contain no CRLF/BOM.
**Plans**:
- **Wave 1**: `01-01-PLAN.md` — config.env loading, `_common.bat` helpers, exit-code contract (0/1/3010 fail-closed), LF payload writer
- **Wave 2** *(blocked on Wave 1 completion)*: `01-02-PLAN.md` — `000-run-all.bat` discovery loop, stop-on-fail, `/from`//`skip`, 3010 handling, summary table
- **Wave 3** *(blocked on Wave 2 completion)*: `01-03-PLAN.md` — `_common.bat :require_admin`, `010-preflight.bat` checks, elevation e2e wiring

Cross-cutting constraints: capture-first errorlevel + exact-match fail-closed exit-code classification (threat T-1-02) hold across all three plans.

### Phase 2: WSL2 Distro & Isolation Hard Gate
**Goal**: A dedicated WSL2 distro on the configured drive exists with Windows drives, interop and Windows PATH fully severed — and a hard gate proves it before anything valuable installs.
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: ISO-01, ISO-05, INS-07, PLT-01, PLT-02, PLT-05
**Success Criteria** (what must be TRUE):
  1. The distro exists with its vhdx physically at `%TARGET_DRIVE%\ai-jail\wsl\` (verified, no hardcoded `D:`), and `/etc/wsl.conf` is written exactly as specified and demonstrably in effect after `wsl --shutdown`.
  2. In a fresh session the 050 gate observes: zero `drvfs` mounts (no `/mnt/c`, no `/mnt/d`), `cmd.exe`/`powershell.exe` not found, no `/mnt/*` in `$PATH`, and `whoami` = `LINUX_USER` (not root).
  3. When the gate fails, 060+ refuse to run — nothing installs until isolation is proven — and no phase ever re-enables automount to "make something work"; the system fails instead.
  4. Global `.wslconfig` and pre-existing distros are untouched — a pre-existing dev environment (e.g. Docker Desktop's distro) still works after the phase.
**Plans**: TBD

### Phase 3: Verified Jail Toolchain
**Goal**: The Linux base and pinned ai-jail are installed behind the gate, with every CLI capability the plan depends on proven at install time rather than assumed.
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: SBX-01, SBX-02, PLT-03
**Success Criteria** (what must be TRUE):
  1. All base packages (bubblewrap, git, curl, ca-certificates, build-essential, python3-venv/pip, pkg-config, jq, rustup, node LTS) are present, and the AppArmor/userns prerequisite is fixed so the 070 dry-run probe actually passes.
  2. ai-jail is installed pinned (`cargo install --locked --version 2.2.0`) and `ai-jail --version`, `ai-jail --dry-run echo ok`, and a real non-dry `ai-jail true` all succeed.
  3. `--allow-host` support is re-verified at install time; if any relied-upon flag is unsupported, the phase fails loudly with a proposed fallback (e.g. nftables/proxy allowlist) instead of silently continuing.
  4. GPU passthrough status (`/usr/lib/wsl/lib`, `nvidia-smi`, `/dev/dxg` mapping fallback) is logged as warn-only — GPU trouble never fails the phase.
**Plans**: TBD

### Phase 4: Jailed Workspaces & Per-Tool Installs
**Goal**: Every AI tool runs inside an ai-jail with its own project folder, hidden secrets and a per-tool network allowlist — and the tools themselves are installed *through* that jail.
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: ISO-02, ISO-03, ISO-04, NET-01, NET-02, NET-03, NET-04, NET-06, NET-07, SBX-03, SBX-04, SBX-05
**Success Criteria** (what must be TRUE):
  1. `~/projects/{opencode-work,comfyui,scratch}` exist with git history; `~/.secrets` (chmod 700, outside the projects) is unreadable from inside any jail while readable outside (paired positive control); each wrapper injects only its own tool's API key at launch — the full secrets directory is never mounted into any jail.
  2. From inside the respective jails: non-allowlisted hosts are unreachable, the opencode jail cannot reach ComfyUI's allowlisted hosts (and vice versa), `jail-shell` has zero network, and the Windows host/LAN IPs are unreachable — every deny paired with a positive control proving the path works when allowed.
  3. A jailed tool cannot write outside its own project directory (write elsewhere fails; write inside the project succeeds).
  4. opencode + GSD and ComfyUI (own venv, no custom nodes) are installed inside ai-jail with only `ALLOW_HOSTS_INSTALL` active, versions pinned to `~/projects/versions.txt`; ComfyUI binds `127.0.0.1` — reachable from the Windows browser at `localhost:8188`, unreachable from the LAN.
  5. Config policy holds: per-tool allowlists live in `config.env`, the single `ALLOW_HOSTS` is gone, the install list is active only during installs, no wildcards (installer fails on `*`), and an empty list means no network.
**Plans**: TBD

### Phase 5: Hardening, Maintenance & Editor
**Goal**: The installed system maintains itself and stays tight — privilege shortcuts removed, updates and backups automated, the editor connected honestly, humans documented.
**Mode:** mvp
**Depends on**: Phase 4
**Requirements**: INS-09, SBX-06, MNT-01, MNT-02, MNT-03, MNT-04
**Success Criteria** (what must be TRUE):
  1. `sudo -n true` fails for `LINUX_USER` (all NOPASSWD entries gone) and `~/.secrets` permissions verify as chmod 700.
  2. A weekly scheduled task exists and demonstrably runs `wsl --update` + apt upgrade (verified by an actual run + version diff, not just task creation).
  3. `backup.bat` produces a dated `wsl --export` backup on the target drive.
  4. When `INSTALL_VSCODE=1`, VS Code + the WSL extension connect to the distro with interop and automount disabled, and the Layer-1-only warning is printed; if it cannot connect, that limitation is documented — interop is never re-enabled to fix it.
  5. `README.txt` documents every human-only step: password entry, API keys → `~/.secrets`, importing large models via `\\wsl$`, and vhdx size/compaction limits.
**Plans**: TBD

### Phase 6: Adversarial Verification & Safe Rollback
**Goal**: `900-verify-all` proves every isolation claim from the live system with non-vacuous evidence, and a C:-safe manual rollback exists for teardown.
**Mode:** mvp
**Depends on**: Phase 5
**Requirements**: NET-05, INS-08, VER-01, VER-02, VER-03
**Success Criteria** (what must be TRUE):
  1. 900 re-runs all 050 gate tests plus secrets invisibility, write confinement, per-jail network denial, cross-tool denial, host/LAN denial, `jail-shell` no-network, ComfyUI bind/reachability, and wrapper existence/versions — each derived from the live system, never from marker files.
  2. Every deny test is preceded by a paired positive control that passes under the same timeout budget — no vacuous PASS (the DNS-less sandbox must not make deny tests pass for the wrong reason).
  3. `logs\REPORT.txt` ends with ALL-PASS including cross-tool denial, host/LAN denial and the 050 gate; CDN-fragile hosts (huggingface.co, github.com) report WARN, never flaky FAIL.
  4. `999-uninstall-rollback` runs only manually (confirm prompt, never invoked by run-all) and removes only `%TARGET_DRIVE%\ai-jail\` — C: user data untouched.
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Orchestrator Contract | 3/3 | Complete | 2026-09-29 |
| 2. WSL2 Distro & Isolation Hard Gate | 0/TBD | Not started | - |
| 3. Verified Jail Toolchain | 0/TBD | Not started | - |
| 4. Jailed Workspaces & Per-Tool Installs | 0/TBD | Not started | - |
| 5. Hardening, Maintenance & Editor | 0/TBD | Not started | - |
| 6. Adversarial Verification & Safe Rollback | 0/TBD | Not started | - |
