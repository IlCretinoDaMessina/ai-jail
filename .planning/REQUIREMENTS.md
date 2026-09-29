# Requirements: AI Jail Automation (WSL2 + ai-jail)

**Defined:** 2026-09-28
**Core Value:** A jailed AI agent cannot touch the Windows host: `C:` unreachable, `~/.secrets` unreadable, non-allowlisted network dead — and 900-verify-all proves every claim with evidence.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Isolation

- [ ] **ISO-01**: 050 hard gate proves `/mnt/c` AND `/mnt/d` absent-or-empty with no `drvfs` mounts, `cmd.exe`/`powershell.exe` not found, no `/mnt/*` in `$PATH`, and default user is `LINUX_USER` (not root) — failure blocks 060+
- [ ] **ISO-02**: `~/.secrets` and `~/.ssh` are unreadable from inside any jail, proven by 900 with a paired positive control
- [ ] **ISO-03**: A jailed tool cannot write outside its own project directory, proven by 900 with a paired positive control
- [ ] **ISO-04**: `jail-shell` has zero network access, proven by 900
- [ ] **ISO-05**: Automount stays disabled for ALL drives (including D:) — never re-enabled to "make something work"; the system fails instead

### Network

- [ ] **NET-01**: Network is default-deny — a non-allowlisted internet host is unreachable from every jail, proven by 900 with a paired positive control
- [ ] **NET-02**: Per-tool allowlists in `config.env` (`ALLOW_HOSTS_OPENCODE`, `ALLOW_HOSTS_COMFYUI`, `ALLOW_HOSTS_INSTALL`); the install list is active only during 090 and never at runtime; single `ALLOW_HOSTS` is removed
- [ ] **NET-03**: Cross-tool denial — the opencode jail cannot reach ComfyUI's allowlisted hosts and vice versa, proven by 900
- [ ] **NET-04**: No wildcards (installer fails on any `*` in allowlists); empty list = no network; explicit hostnames only
- [ ] **NET-05**: CDN/IP-distributed hosts (huggingface.co, github.com) are reported as WARN, never flaky FAIL, in 900
- [ ] **NET-06**: The Windows host (default gateway IP, Windows-side localhost services) and LAN IPs are unreachable from inside jails, proven by 900 with a paired positive control
- [ ] **NET-07**: ComfyUI binds to `127.0.0.1` only — reachable from the Windows browser via `localhost:8188`, unreachable from the LAN; 900 tests both directions

### Installer Suite

- [x] **INS-01**: `000-run-all` executes 010→900 in order, stop-on-fail, printing a final summary table (phase / status / time)
- [x] **INS-02**: `000-run-all` supports `/from NNN` (resume) and `/skip NNN` options
- [x] **INS-03**: Every phase is idempotent (detects "already done"), writes `logs\NNN-name.log`, and returns exit code 0 (OK/skip), 1 (fatal), or 3010 (reboot)
- [x] **INS-04**: On exit 3010, run-all pauses with a reboot message and re-run (`/from`) instructions, then stops
- [x] **INS-05**: Admin phases self-check elevation and abort with a clear, actionable message when not elevated
- [x] **INS-06**: `config.env` drives everything (`TARGET_DRIVE`, `DISTRO`, `LINUX_USER`, allowlists, `INSTALL_*`, `MIN_FREE_GB`); no hardcoded paths, drives, or usernames anywhere
- [ ] **INS-07**: Hard gates at 050 (isolation proven), 070 (ai-jail installed and flags verified), and 090 (tools run under jail) — a failed gate blocks all subsequent phases
- [ ] **INS-08**: `999-uninstall-rollback` is manual-only with a confirm prompt, never called by run-all, and never touches C: user data
- [ ] **INS-09**: `README.txt` documents human-only steps: password entry, API keys → `~/.secrets`, importing large models via `\\wsl$`, and vhdx size/compaction limits on the target drive

### Platform

- [ ] **PLT-01**: The system installs to `%TARGET_DRIVE%\ai-jail\` (distro vhdx in `%TARGET_DRIVE%\ai-jail\wsl\`) as the first directory of the drive; 030 verifies the vhdx location; no hardcoded `D:`
- [ ] **PLT-02**: `/etc/wsl.conf` written exactly (`default=LINUX_USER`, automount + mountFsTab off, interop + appendWindowsPath off), applied via `wsl --shutdown`, and confirmed effective by 050
- [ ] **PLT-03**: GPU passthrough still works with automount off (`/usr/lib/wsl/lib`, `nvidia-smi`, `/dev/dxg` mapping fallback) — verified warn-only in 060
- [x] **PLT-04**: All Linux-side payloads emitted from `.bat` files use LF line endings (no CRLF/BOM poisoning)
- [ ] **PLT-05**: Never edits global `.wslconfig` or touches pre-existing distros — changes are scoped to the new distro only

### Sandbox & Tools

- [ ] **SBX-01**: 070 installs ai-jail pinned to 2.2.0 (`cargo install --locked --version`), asserts `--version` and `--dry-run echo ok`, and re-verifies `--allow-host` support at install time; an unsupported flag is flagged with a proposed fallback (e.g. nftables/proxy allowlist), never silently skipped
- [ ] **SBX-02**: 060 installs the Linux base (bubblewrap, git, curl, ca-certificates, build-essential, python3-venv, python3-pip, pkg-config, jq, rustup, node LTS) plus the AppArmor/userns prerequisite so the 070 dry-run probe can pass
- [ ] **SBX-03**: 080 creates `~/projects/{opencode-work,comfyui,scratch}` (git init + initial commit), `~/.secrets` (chmod 700, outside project folders), and executable wrappers `jail-opencode`, `jail-comfyui`, `jail-shell` in `~/bin` (added to PATH) — each with its own allowlist, fake home, and project-only writability
- [ ] **SBX-04**: API keys are injected per-tool at launch — each wrapper passes only its own tool's key (env var or single read-only file); the whole `~/.secrets` is never mounted or visible inside any jail
- [ ] **SBX-05**: 090 runs all installs INSIDE ai-jail with only `ALLOW_HOSTS_INSTALL`, using project-local prefixes (ephemeral home), pinning versions to `~/projects/versions.txt`; ComfyUI gets no custom nodes (safetensors only, GGUF from a pinned source)
- [ ] **SBX-06**: 100 (if `INSTALL_VSCODE=1`) installs VS Code + WSL extension via winget, prints the Layer-1-only warning, and verifies the WSL extension connects with interop and automount disabled — if it cannot, the limitation is documented and interop is NEVER re-enabled to fix it

### Maintenance

- [ ] **MNT-01**: 110 removes all passwordless sudo for `LINUX_USER` (NOPASSWD entries gone; `sudo -n true` fails)
- [ ] **MNT-02**: 110 verifies `~/.secrets` permissions (chmod 700)
- [ ] **MNT-03**: 110 creates a weekly scheduled task running `wsl --update` + apt upgrade (highest privileges, verified via version diff)
- [ ] **MNT-04**: 110 creates `backup.bat` producing a dated `wsl --export` backup

### Verification

- [ ] **VER-01**: 900 re-runs all 050 tests plus: secrets invisibility, write confinement, per-jail network denial, cross-tool denial, host/LAN denial, jail-shell no-network, ComfyUI bind/reachability, and wrapper existence/versions
- [ ] **VER-02**: Every deny test is preceded by a paired positive control proving the tool/network path demonstrably works (no vacuous PASS)
- [ ] **VER-03**: Done = 900 writes `logs\REPORT.txt` with ALL-PASS, including cross-tool denial, host/LAN denial, and the 050 gate (CDN-fragile checks report as WARN)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Verification

- **VER-04**: Zipped evidence bundle of per-phase logs for third-party sharing

### Sandbox

- **SBX-07**: GPU verification hardened from warn-only to fatal
- **SBX-08**: `nono` Layer-3 tool installed when `ENABLE_NONO=1` (default off)
- **SBX-09**: Disposable per-run jails with snapshot/restore

### Maintenance

- **MNT-05**: Phantom credentials (`--secret KEY=host`) keeping real keys out of jail env
- **MNT-06**: Resource-limit tuning / multi-tenant hardening

## Out of Scope

| Feature | Reason |
|---------|--------|
| Malware analysis / untrusted-binary detonation | WSL2 shares the host kernel — hostile code needs a VM, not WSL2 |
| Secrets automation (auto-fill passwords/API keys) | Human-only flow; storing secrets in `.bat` is the exact failure mode the product defends against |
| Wildcard host allowlists (`*`, `*.host`) | Weaken default-deny; installer fails on any `*` |
| Docker socket / systemd bus passthrough into jail | "Effectively host-root" — voids the isolation claim |
| TLS interception / content-inspecting proxy | Complexity + breaks pinned clients; hostname fence is stronger and simpler |
| Custom ComfyUI nodes by default | Arbitrary-code supply chain inside the jail; user opts in manually at own risk |
| Touching C: user data (including 999 rollback) | Writes never go to C: — a rollback visiting C: can only destroy pre-existing data |
| Claiming VM-grade / malware-proof isolation | WSL2 = same kernel; honest scope: protects against misbehaving agents, not kernel exploits |
| Editing global `.wslconfig` / other distros | Would break pre-existing dev environments (Docker Desktop etc.) |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ISO-01 | Phase 2 | Pending |
| ISO-02 | Phase 4 | Pending |
| ISO-03 | Phase 4 | Pending |
| ISO-04 | Phase 4 | Pending |
| ISO-05 | Phase 2 | Pending |
| NET-01 | Phase 4 | Pending |
| NET-02 | Phase 4 | Pending |
| NET-03 | Phase 4 | Pending |
| NET-04 | Phase 4 | Pending |
| NET-05 | Phase 6 | Pending |
| NET-06 | Phase 4 | Pending |
| NET-07 | Phase 4 | Pending |
| INS-01 | Phase 1 | Complete |
| INS-02 | Phase 1 | Complete |
| INS-03 | Phase 1 | Complete |
| INS-04 | Phase 1 | Complete |
| INS-05 | Phase 1 | Complete |
| INS-06 | Phase 1 | Complete |
| INS-07 | Phase 2 | Pending |
| INS-08 | Phase 6 | Pending |
| INS-09 | Phase 5 | Pending |
| PLT-01 | Phase 2 | Pending |
| PLT-02 | Phase 2 | Pending |
| PLT-03 | Phase 3 | Pending |
| PLT-04 | Phase 1 | Complete |
| PLT-05 | Phase 2 | Pending |
| SBX-01 | Phase 3 | Pending |
| SBX-02 | Phase 3 | Pending |
| SBX-03 | Phase 4 | Pending |
| SBX-04 | Phase 4 | Pending |
| SBX-05 | Phase 4 | Pending |
| SBX-06 | Phase 5 | Pending |
| MNT-01 | Phase 5 | Pending |
| MNT-02 | Phase 5 | Pending |
| MNT-03 | Phase 5 | Pending |
| MNT-04 | Phase 5 | Pending |
| VER-01 | Phase 6 | Pending |
| VER-02 | Phase 6 | Pending |
| VER-03 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 39 total
- Mapped to phases: 39 ✓
- Unmapped: 0 ✓

**Per-phase counts:** Phase 1: 7 · Phase 2: 6 · Phase 3: 3 · Phase 4: 12 · Phase 5: 6 · Phase 6: 5

---
*Requirements defined: 2026-09-28*
*Last updated: 2026-09-29 — Phase 1 complete (INS-01..06, PLT-04); traceability statuses refreshed*
