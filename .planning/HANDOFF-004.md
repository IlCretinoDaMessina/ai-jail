# HANDOFF — ai-jail automation, after Phase 080 closure

**Date:** 2026-10-01  
**Read first:** `.planning/ROADMAP-004.md`, `.planning/REQUIREMENTS-004-ADDENDUM.md`, `.planning/STATUS-004.md`. These supersede the planning/status descriptions in 003; preserve older files as historical evidence. The local project root is `D:\.coding\.ai-jail\`; the dedicated Linux distro is `ai-jail`, user `aijail`, located on D:. Reports and hashes below are supplied OpenCode/user evidence, not independently reproduced by this handoff.

## Operational state

000–070: complete, **never rerun**. 080: **accepted and complete**, including safe live apply and second idempotent run; three sandbox wrappers were installed and security checks passed. 090 (OpenCode + VS Code + GSD): **not started**. 100 (ComfyUI from user's existing 90-step Windows 11 BAT workflow, adapted to Linux): **not started**. 110/900/999: not started. `ENABLE_NONO=0`, so nono is not yet enabled.

**Final Phase 080 production files/hashes:**

| File | SHA-256 |
|---|---|
| `000-run-all.bat` | `2c188e0e3d95465f44b87b623e991a1723c97ad6615fbe0ff3ba33d5fb399775` |
| `080-setup-sandboxes.bat` | `1122dc891bfddf0259d41d792ad3a6f2da15df9230a41aedbab1f358639ad1b9` |
| `080-setup-sandboxes.ps1` | `84d0f8f4ea1983cfb4f6bf6f151ae2f3262b898391dfe5fd2e6ff15946e05245` |
| `config.env` | `affc004de57e1dfedc5c12d850957904e1f2b9356b82de856e33effe5fd4c0d5` |
| `_common.bat` | `f32827ecbb861a7ae1df9dd280b9ab6cc3a804849761ad8491318b4288214e8b` |

`080-setup-sandboxes.bat` requires explicit `--review`/`--apply` when called directly and invokes the renamed PS1. `000-run-all.bat` discovers Phase 080 and passes `--apply` only to it. Mocked forwarding, rename regressions and PS syntax passed; the full runner was **not** executed for the rename. The PowerShell installer hash remained unchanged by the rename.

**Reported Phase 080 acceptance:** config 96/96, static apply 64/64, `set -e` 3/3, disposable live-behavior fixture 13/13, final live read-only preflight 52/52, successful apply exit 0, idempotent apply exit 0 (unchanged wrapper inodes/hashes/timestamps, Git HEADs and secret metadata), positive/negative isolation checks, corrected network 22/22. Existing Git HEADs in all three projects stayed `b128d2a03c0dede852982196c0819cb810d45e24`. Secret files remained regular 0600 and owned by `aijail:aijail`; their contents were not read. No staging residue or rollback after successful apply.

**Installed wrapper hashes:**

- `/home/aijail/bin/jail-shell`: `46b3b6671e1f68ddec4b4714eb986c418a8d36343e150b659201ec1590c23e8e`
- `/home/aijail/bin/jail-opencode`: `580f4200fca25b10c2887341053fe8f5c91ec368261c04a9af165e874226b11d`
- `/home/aijail/bin/jail-comfyui`: `698774b3d5373699a2ce60052b7ce9bb7f6ca9ac0c9f5aeffdd18bc6f02ce118`

All were reported as `aijail:aijail`, mode 0700. Workspaces: `/home/aijail/projects/{scratch,opencode-work,comfyui}`. Secret files: `/home/aijail/.secrets/{opencode.env,comfyui.env}`; never disclose, replace or truncate them. Option C for every wrapper: no args -> Bash, `-c COMMAND [ARG...]` -> Bash command, `-- COMMAND [ARG...]` -> direct execution; other forms exit 64; child statuses propagate. Own-project writable map only, `--clean --no-save-config --private-home --hide-dotdir .secrets`. Scratch offline; the other two use respective host allowlists and secret env-file paths.

## Essential DNS/proxy finding (do not regress)

The original six positive `/dev/tcp` host checks failed, but the diagnostic established **incorrect test methodology**, not installer or wrapper breakage. ai-jail 2.2.0 filtered networking intentionally has no direct sandbox DNS/TCP; it injects `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY` = `http://127.0.0.1:15919` and uses supervisor-side DNS plus HTTP CONNECT. `NO_PROXY` empty. Proxy-aware approved HTTPS requests passed 6/6; denied-host/IP/LAN/loopback checks, scratch-offline and direct DNS/TCP negatives all passed in the final **22/22** matrix. Historic failing results were retained and explained in `phase-080-validation-report.md`. Never change resolv.conf, open direct egress or widen allowlists to make `getent`, `/dev/tcp`, raw sockets or Node core `fetch` work in filtered mode. When installing OpenCode and ComfyUI, test their **actual clients** with proxy-aware download paths; app-specific proxy agent/config needs design approval if necessary.

## Next task — Phase 090 planning only

1. Inspect existing planning and current source, launcher, `config.env` and orchestrator. Do not assume 090 has already been implemented. Define OpenCode version/install method, GSD version/integration, VS Code-to-distro approach and strict install-time downloads/checksums. `INSTALL_OPENCODE=1`, `INSTALL_VSCODE=0`, `INSTALL_COMFYUI=1`; do not silently change flags. Resolve editor requirements while preserving WSL no-interop/no-automount isolation.
2. Distinguish installation-time download privileges from `jail-opencode` restricted runtime. Determine how Node/npm/Git and real OpenCode honour injected HTTP CONNECT proxy. Validate working project and credential boundaries.
3. Produce the design, test plan, dependency/host inventory and proposed Phase 090 BAT/PS1 names before implementing or installing anything; obtain explicit approval for live operations.
4. Phase 100 comes afterward: inventory and map user's original **90-step BAT automation** into Linux; do not substitute an unrelated ComfyUI installer.

## Never do without separate approval

Do not rerun 000–070; execute `000-run-all.bat` merely to test filenames; modify another distro/`docker-desktop`; change global `.wslconfig`; re-enable automount, Windows interop or PATH injection; run `wsl --shutdown`; dilute sandbox policies; access secret contents; automatically enable nono; run manual 999. Use `wsl --terminate ai-jail` only with explicit separate approval. Phase script outcomes must conform to 0/1/3010. User approves OpenCode edits/commands with **Allow once** for specific actions; ChatGPT designs and reviews, OpenCode executes approved local tests and reports evidence.

## Documentation reconciliation

Copy these four 004 files into `.planning/` in the local project and corresponding repository. Treat `ROADMAP-004.md` as the active planning authority; preserve `ROADMAP-003.md`, `STATUS-003.md`, `REQUIREMENTS-003-ADDENDUM.md`, original 080 failure records and historical names/hashes. The original `.planning/REQUIREMENTS.md` and `.planning/REVIEW.md` were not provided for direct inspection: compare them before updating living summaries, do not invent original IDs or overwrite historical evidence. Current reported `080-review-gates.md` hash: `0086ccabf95029b5090f4202a43fa5c052b8ec05ef689926445e35d9fc5144dd`; `phase-080-validation-report.md`: `bd6295ba04d6514fe70ae3f59f3a867305b7aebe9435679e757ae5085e2343d1`.
