# ai-jail handoff — updated 2026-09-29

Repo: https://github.com/IlCretinoDaMessina/ai-jail
Local path: `D:\.coding\.ai-jail\`
Local bats currently live in the repo root; GitHub currently shows the bats under `tests/`.

## Workflow rules

- Be VERY brief.
- One small step at a time: user runs it and pastes output.
- Before writing any `.bat`, fetch the relevant existing files so names/helpers match.
- When fixing a `.bat`, provide the COMPLETE fixed file, not a snippet.
- Every test command must include `cd /d D:\.coding\.ai-jail` first.
- Never touch `docker-desktop`.
- Never use `wsl --shutdown`; use `wsl --terminate ai-jail` when only this distro should be restarted.
- Never re-enable automount/interop to make something work.
- Never touch global `.wslconfig`.

## Machine

- Windows 11 `10.0.26200.9457`
- WSL `2.7.14.0`
- Kernel `6.18.33.2-2`
- Dedicated distro: `ai-jail`
- Base distro: Ubuntu 24.04.5 LTS
- Other distro: `docker-desktop` (Stopped; leave untouched)
- Distro VHDX: `D:\ai-jail\wsl\ext4.vhdx`
- D: started with about 734 GB free.
- NVIDIA GPU: GeForce RTX 3080 Ti
- WSL GPU interfaces verified: `/usr/lib/wsl/lib/nvidia-smi`, `/dev/dxg`

## Hard project rules

- Exit codes: only `0` OK/skip, `1` fatal, `3010` reboot.
- Phases are idempotent.
- 050 must pass before installs.
- 050 must prove:
  - default user = `LINUX_USER`
  - no `/mnt/c` mount
  - no `/mnt/d` mount
  - no `drvfs`
  - `cmd.exe` unreachable
  - `powershell.exe` unreachable
  - no `/mnt` in PATH
- No hardcoded D: inside bats; values come from `config.env`.
- Bats: CRLF, no BOM.
- Linux files: LF, UTF-8, no BOM.
- Existing helper conventions:
  - `call "%~dp0_common.bat" :load`
  - `call "%~dp0_common.bat" :require_admin`
  - `:classify_rc`
  - `:write_lf`
  - `:run_phase`
- Capture `ERRORLEVEL` immediately; exact-match checks only.

## Phase 1 / Foundation — COMPLETE

Previously completed and verified:
- 010-preflight
- 020-wsl-check
- 030-create-distro
- `config.env` updated to `BASE_DISTRO=Ubuntu-24.04`
- `MIN_WSL_VERSION=2.4.4`

Known existing issue:
- `010-preflight.bat` has a failure-path logging bug: `:failed` appends to `%PHASE_LOG%` while `:run_phase` already redirects stdout to the same file. Patch later by removing the append line.
- This does not affect the successful 010 path.

## Phase 2 — COMPLETE

### Distro creation

Verified:
- `ai-jail` registered as WSL2.
- `docker-desktop` remains untouched.
- VHDX is exactly:
  `D:\ai-jail\wsl\ext4.vhdx`

### 040 — WSL isolation config — COMPLETE

Linux user:
- `aijail`
- `uid=1000(aijail) gid=1000(aijail)`

Final `/etc/wsl.conf`:

```ini
[boot]
systemd=true

[automount]
enabled=false
mountFsTab=false

[interop]
enabled=false
appendWindowsPath=false

[user]
default=aijail
```

`wsl --terminate ai-jail` used, never `wsl --shutdown`.

Final verification passed:
- `WHO=aijail`
- `/mnt/c` not mounted
- `/mnt/d` not mounted
- `drvfs=0`
- `cmd.exe` not found
- `powershell.exe` not found
- `/mnt` absent from PATH

Current local file:
- `040-wsl-conf.bat`

Final 040 result:
`040-wsl-conf: ai-jail OK - user aijail, isolation prerequisites verified`

Important 040 debugging history:
- Multiple early generated versions had Windows/WSL quoting and newline bugs.
- Final version uses a temp LF config and then writes it into `/etc/wsl.conf` through WSL.

### 050 — isolation gate — COMPLETE

Final result:
`050-isolation-gate: ai-jail PASS - user aijail, no drvfs, Windows drives unreachable, interop unreachable, PATH clean`

Important debugging history:
- Early versions falsely failed due to Linux command exit-code semantics and Windows batch quoting.
- Final version uses a WSL shell probe and explicit fail-closed checks.

Current local file:
- `050-isolation-gate.bat`

## Phase 3 — COMPLETE OPERATIONALLY

### 060 — base toolchain — COMPLETE

Observed AppArmor/userns state:
- `/sys/module/apparmor/parameters/enabled` = `N`
- AppArmor module is loaded, but AppArmor filesystem is not mounted.
- `apparmor.service` is inactive because `ConditionSecurity=apparmor` is unmet.
- `/proc/sys/kernel/apparmor_restrict_unprivileged_userns` does not exist.
- `/sys/kernel/security/lsm` does not exist.
- `user.max_user_namespaces` = `128159`
- `unshare -Ur true` returned `RC=0`

Conclusion:
- No AppArmor workaround was needed on this WSL kernel.
- Unprivileged user namespaces work natively.

Installed/verified:
- bubblewrap `0.9.0`
- Node `v24.21.0`
- npm `11.19.0`
- rustup `1.26.0`
- rustc `1.98.1`
- Python `3.12.3`
- Git `2.43.0`
- jq, curl, build tools, Python venv/pip, pkg-config

GPU in WSL:
- `/usr/lib/wsl/lib/nvidia-smi` works
- `/dev/dxg` present
- raw WSL `nvidia-smi` reports RTX 3080 Ti, driver 580.88, CUDA 13.0

Current local file:
- `060-base-toolchain.bat`

Final result:
`060-base-toolchain: ai-jail OK`

### 070 — ai-jail 2.2.0 — COMPLETE

Installed exactly:
- `ai-jail v2.2.0`
- `/home/aijail/.cargo/bin/ai-jail`

Version check:
- `ai-jail 2.2.0`

Verified:
1. `--dry-run` emits bubblewrap + Landlock + network namespace isolation.
2. Real `ai-jail echo ok` succeeds.
3. Output reports `Landlock: fully enforced`.
4. `--allow-host example.com --dry-run` emits the expected proxy bridge wiring.
5. Actual allowed network to `https://example.com` returned HTTP 200.
6. After removing the persistent allowlist, default-deny `curl https://example.com` failed with `Could not resolve host`.
7. `--gpu --dry-run` emits GPU mode.

### Persistent config gotcha — IMPORTANT

The earlier `--allow-host example.com` test created:

`/home/aijail/.ai-jail`

Its contents were:

```toml
# ai-jail sandbox configuration
# https://github.com/akitaonrails/ai-jail
# Edit freely. Regenerate with: ai-jail --clean --init

command = [
    "echo",
    "ok",
]
allow_hosts = ["example.com"]
```

This persisted the allowlist and caused a false default-deny test.

It was moved to:

`/home/aijail/.ai-jail.phase070-backup`

The active `/home/aijail/.ai-jail` was removed.

A subsequent clean `--dry-run` showed `--no-network` with no `--allow-host`, proving the default-deny state is restored.

Do NOT restore `.ai-jail.phase070-backup` as active runtime config.

### GPU caveat

Direct sandbox GPU test:

`ai-jail --gpu nvidia-smi`

returned:

`Failed to initialize NVML: GPU access blocked by the operating system`

Raw WSL GPU access works outside the sandbox via `/usr/lib/wsl/lib/nvidia-smi`.

The roadmap treats GPU as warn-only, so 070 was not blocked.

IMPORTANT for later:
- Do not claim that GPU inside the ai-jail sandbox is proven.
- The current `070-ai-jail.bat` also prints `nvidia-smi works inside WSL` for the raw WSL probe; that is not equivalent to sandbox GPU success. Fix wording/verification later if necessary.

Current local file:
- `070-ai-jail.bat`

Final 070 result:
- 050 gate passed
- ai-jail 2.2.0 already installed / verified
- real jail passed
- default-deny passed after removing persistent config
- GPU raw WSL probes passed

## Phase 4 — NOT STARTED

Next roadmap work is jailed workspaces + per-tool installs.

Expected Phase 4 areas include:
- `~/projects/opencode-work`
- `~/projects/comfyui`
- `~/projects/scratch`
- git history
- `~/.secrets` mode 700
- secrets invisible from jails
- per-tool network allowlists
- cross-tool network denial
- write confinement
- tool installation through ai-jail
- 090 hard gate before tool installs

## Current persistent state

- `ai-jail` isolated and operational.
- `aijail` UID 1000 and default user.
- `/etc/wsl.conf` active as above.
- `/mnt/c` and `/mnt/d` unmounted.
- no drvfs.
- Windows executable interop unavailable.
- no `/mnt` in PATH.
- bubblewrap, Node, Rust, Python, Git, jq and related base tools installed.
- ai-jail 2.2.0 installed.
- active `/home/aijail/.ai-jail` should remain absent/default-deny.
- temporary backup exists at `/home/aijail/.ai-jail.phase070-backup`.

## Local files created/updated during this session

Repo root:
- `040-wsl-conf.bat`
- `050-isolation-gate.bat`
- `060-base-toolchain.bat`
- `070-ai-jail.bat`

Existing foundation files:
- `000-run-all.bat`
- `010-preflight.bat`
- `020-wsl-check.bat`
- `030-create-distro.bat`
- `_common.bat`
- `config.env`

GitHub/local sync is NOT assumed. The user should commit/push later.

## Next exact step

Before writing any 080/090 batch, fetch the relevant Phase 4 planning docs and current helper/script files.

Then do exactly one read-only state check:

```bat
cd /d D:\.coding\.ai-jail
wsl -d ai-jail -e /bin/sh -c "echo PROJECTS; ls -ld /home/aijail/projects 2>&1; echo SECRETS; ls -ld /home/aijail/.secrets 2>&1; echo BIN; ls -ld /home/aijail/bin 2>&1"
```

Paste the complete output.

## Repo handoff source status

The GitHub `.planning/handoff.md` previously ended at the unconfirmed 040 stage. This local handoff supersedes it with the verified 040/050/060/070 state above.

## Later cleanup / maintenance items

- Patch the 010 `%PHASE_LOG%` append bug.
- Review 070 GPU wording/probe so it never implies sandbox NVML success when only raw WSL GPU access is verified.
- Commit/push local changes.
- Reconcile root-local bat paths with GitHub `tests/` layout if needed.
- Continue through Phase 4 and 090 gate before installing OpenCode/ComfyUI.
- Later Phase 5 hardening/maintenance/VS Code.
- Later `900-verify-all` and `999` manual C:-safe rollback.
