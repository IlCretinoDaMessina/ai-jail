# ai-jail handoff

Repo: https://github.com/IlCretinoDaMessina/ai-jail (public)
Local path: `D:\.coding\.ai-jail\` (bats sit in the repo root locally; GitHub shows them under `tests/`)

## Workflow rules (from user)
- Be VERY brief. One small step at a time; user runs it and pastes output.
- If a step works, write the .bat for it, matching existing conventions. User tests, then move on.
- Fetch existing files before writing any bat. Give complete fixed files (not snippets) whenever a fix is needed.
- Hard rules: the 050 gate must prove Windows drives are unreachable before anything installs (no drvfs/mnt, no cmd.exe/powershell.exe, no /mnt in PATH, whoami = LINUX_USER). Never re-enable automount/interop. Never touch global `.wslconfig` or the docker-desktop distro.

## Machine
Windows 11 10.0.26200.9457, WSL 2.7.14.0, VPN DNS in use. D: has about 734 GB free. Only other distro: `docker-desktop` (Stopped, leave alone).

## Done so far
1. **Distro created manually** (Step 2): `wsl --install Ubuntu-24.04 --name ai-jail --location D:\ai-jail\wsl --no-launch`. Registered as WSL2, vhdx at `D:\ai-jail\wsl\ext4.vhdx`.
2. **010-preflight bug fixed**: the internet probe used `https://www.msftconnecttest.com/...`, which fails with SEC_E_WRONG_PRINCIPAL. It now uses `http://`. Fixed file delivered and running locally.
3. **020-wsl-check.bat** written and passing. It is read-only: it checks `wsl.exe` exists and the version is at least `MIN_WSL_VERSION`, parsing `wsl --version` with `WSL_UTF8=1`. It never updates or shuts anything down.
4. **030-create-distro.bat** written and passing via the "already exists" path. Idempotent: it detects the registered distro, requires WSL2, and requires the vhdx at `%TARGET_DRIVE%\%DISTRO%\wsl\ext4.vhdx`. It refuses to touch a distro registered elsewhere or an orphan vhdx. The create path (`wsl --install ... --no-launch`) is untested because the distro already existed.
5. **config.env updated**: `BASE_DISTRO=Ubuntu-24.04`, new `MIN_WSL_VERSION=2.4.4`.

Last run-all result: 010 OK, 020 OK, 030 OK (OK=3 FAIL=0).

## Known issue
`:failed` in 010 appends to `%PHASE_LOG%`, but `:run_phase` in `_common.bat` already redirects the phase's stdout into that same file, so the append fails with "The process cannot access the file because it is being used by another process". It only shows on failures. 020 and 030 avoid it by echoing only. 010 should be patched the same way (remove the append line in `:failed`).

## Current step: 040 (not yet confirmed run)
Commands given to the user, to be run in an elevated cmd:

```bat
wsl -d ai-jail -u root -e useradd -m -s /bin/bash aijail
wsl -d ai-jail -u root -e bash -c "printf '[boot]\nsystemd=true\n\n[automount]\nenabled=false\nmountFsTab=false\n\n[interop]\nenabled=false\nappendWindowsPath=false\n\n[user]\ndefault=aijail\n' > /etc/wsl.conf && cat /etc/wsl.conf"
wsl --terminate ai-jail
wsl -d ai-jail -e bash -c "whoami; mount | grep -ci 9p; ls /mnt; echo $PATH; command -v cmd.exe powershell.exe"
```

Use `wsl --terminate ai-jail`, not `wsl --shutdown`, so docker-desktop is never stopped.

Expected output: `aijail`, `0`, empty `/mnt`, no `/mnt` in PATH, no path printed for either exe. Waiting on the user to paste the result.

## Next
1. If the 040 output is as expected, write `040-wsl-conf.bat`. It should be idempotent, write `/etc/wsl.conf` via `:write_lf` (LF, UTF-8 no BOM), create `LINUX_USER` only if missing, and run `wsl --terminate` on the distro only. All values come from config.env.
2. Write `050-isolation-gate.bat`. It must fail closed and prove: no drvfs/9p mounts, `/mnt` empty or absent, no `cmd.exe` or `powershell.exe` reachable, no `/mnt` in PATH, and whoami equal to `LINUX_USER`.
3. Patch 010 (remove the `%PHASE_LOG%` append).
4. Commit the local changes: the fixed 010, 020, 030 and config.env are newer than what is on GitHub.
5. Open question: `aijail` has no password or sudo yet. Root operations later (apt, AppArmor fix in 060) can go through `wsl -u root`. Decide whether the user needs sudo at all.

## Conventions to keep
- Exit codes only 0 (OK/skip), 1 (fatal), 3010 (reboot). Phases must be idempotent.
- Start with `call "%~dp0_common.bat" :load`, then `setlocal EnableDelayedExpansion`.
- Capture ERRORLEVEL immediately, use exact-match rc checks (no GEQ), compare numbers UNQUOTED and digit-validated, and fail through a `:failed` label.
- No hardcoded D:; read everything from config.env. Bats use CRLF with no BOM. Linux-side files are written through `:write_lf`.
- Phase order: 020 WSL check, 030 create distro, 040 wsl.conf, 050 isolation gate, 060 AppArmor/userns fix, 070 ai-jail 2.2.0 probe. Later: 090 gate, Phase 5 hardening, 900-verify-all, 999 manual C:-safe rollback.
- run-all: discovers NNN-*.bat by name, skips 000/999, stops on first fail, supports `/from NNN` and `/skip NNN`, logs to `logs\NNN-name.log`.
