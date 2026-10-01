# Roadmap 004 — AI Jail Automation

**Status date:** 2026-10-01  
**Authority:** Supersedes `ROADMAP-003.md` for forward planning. Keep roadmaps 001–003 as historical snapshots. Phase results below are based on the OpenCode reports supplied for review, not independently rerun here.

## Goal and immutable boundaries

Config-driven, fail-closed Windows 11 BAT orchestration of the dedicated WSL2 distro `ai-jail` (Linux user `aijail`, on D:). Run workload processes through isolated ai-jail 2.2.0 project launchers; distinguish installation-time permissions from runtime allowlists. `ENABLE_NONO=0`: nono is not an active protection in the accepted build.

Never rerun completed phases 000–070, touch other distros or `docker-desktop`, edit global `.wslconfig`, enable automount/interop/Windows PATH propagation, or run `wsl --shutdown`. Do not loosen security to enable a tool. A targeted `wsl --terminate ai-jail`, if ever needed, requires separate approval. Phase 999 is manual-only and confirmation-gated.

## Current phase plan

| Phase | Scope | Actual status / next gate |
|---|---|---|
| 000–070 | Orchestrator, dedicated WSL2 installation/isolation and ai-jail toolchain | **COMPLETE**, based on prior accepted evidence. Do not rerun. |
| 080 | Secure project directories, Git scaffolding, secrets metadata, Option C launchers, validated transactional installer | **COMPLETE / ACCEPTED**, based on successful live apply, idempotent rerun, isolation tests and final corrected proxy-aware network acceptance (22/22). Rename/integration regression passed. |
| 090 | OpenCode + VS Code integration + GSD | **NOT STARTED**. First produce requirements/design and resolve `INSTALL_VSCODE=0` without weakening WSL isolation. |
| 100 | Adapt user's existing **90-step Windows 11 BAT ComfyUI automation** to Linux and build ComfyUI | **NOT STARTED**. Inventory original scripts and dependencies first. |
| 110 | Hardening, maintenance, backup, operator documentation | **NOT STARTED**. |
| 900 | Live end-to-end functional/adversarial acceptance | **NOT STARTED**. Retest real OpenCode/ComfyUI behavior, not only launcher policy. |
| 999 | Manual, explicit-confirmation rollback/uninstall | **NOT STARTED; excluded from automatic run-all**. |

## Phase 080 closure evidence

The **final production names** are `080-setup-sandboxes.bat` and `080-setup-sandboxes.ps1`; the orchestrator `000-run-all.bat` discovers the BAT and forwards `--apply` to Phase 080 only. Direct Phase 080 invocations require `--review` or `--apply`. The mocked forwarding test passed; the real orchestrator was not executed during rename verification. The PowerShell implementation was byte-identical across the rename.

Latest **reported local SHA-256** values (verify independently before any future live operation):

| File | SHA-256 |
|---|---|
| `000-run-all.bat` | `2c188e0e3d95465f44b87b623e991a1723c97ad6615fbe0ff3ba33d5fb399775` |
| `080-setup-sandboxes.bat` | `1122dc891bfddf0259d41d792ad3a6f2da15df9230a41aedbab1f358639ad1b9` |
| `080-setup-sandboxes.ps1` | `84d0f8f4ea1983cfb4f6bf6f151ae2f3262b898391dfe5fd2e6ff15946e05245` |
| `config.env` | `affc004de57e1dfedc5c12d850957904e1f2b9356b82de856e33effe5fd4c0d5` |
| `_common.bat` | `f32827ecbb861a7ae1df9dd280b9ab6cc3a804849761ad8491318b4288214e8b` |
| `080-review-gates.md` | `0086ccabf95029b5090f4202a43fa5c052b8ec05ef689926445e35d9fc5144dd` |
| `phase-080-validation-report.md` | `bd6295ba04d6514fe70ae3f59f3a867305b7aebe9435679e757ae5085e2343d1` |

**Installation and safety evidence reported:** 96/96 config validation; 64/64 static apply checks; 3/3 `set -e` regressions; 13/13 disposable Linux behavioral scenarios; 52/52 final read-only live preflight; successful live apply (exit 0) promoting three wrappers; successful subsequent idempotent apply (exit 0), with unchanged wrapper hashes/inodes/metadata, Git HEADs and secret metadata. Cross-project access, hidden secrets, private home, read-only system paths, wrapper invocation and exit propagation passed. Final corrected proxy-aware network acceptance was **22/22 PASS**: six positive allowlisted CONNECT requests, ten policy denials, two scratch-offline tests and four direct DNS/TCP negatives. No active old filename references remained after rename; historical references were deliberately kept.

**Network interpretation:** ai-jail 2.2.0 filtered mode intentionally has no sandbox DNS or direct outbound TCP. It injects `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY` pointing to `127.0.0.1:15919` and uses supervisor-side DNS/HTTP CONNECT. The initial `/dev/tcp` positive test was invalid; preserve its failure as history. Use proxy-aware HTTPS clients for positive tests and direct DNS/TCP as expected negatives. Application-specific support for the proxy is still to be proved in 090 and 100.

The live wrapper set after successful apply was reported as mode 0700 and owned by `aijail:aijail`:

- `jail-shell`: `46b3b6671e1f68ddec4b4714eb986c418a8d36343e150b659201ec1590c23e8e`.
- `jail-opencode`: `580f4200fca25b10c2887341053fe8f5c91ec368261c04a9af165e874226b11d`.
- `jail-comfyui`: `698774b3d5373699a2ce60052b7ce9bb7f6ca9ac0c9f5aeffdd18bc6f02ce118`.

`/home/aijail/projects/{scratch,opencode-work,comfyui}` each had preserved Git HEAD `b128d2a03c0dede852982196c0819cb810d45e24`. Existing `.secrets/{opencode.env,comfyui.env}` remained regular mode 0600, owned by `aijail:aijail`, with contents unread during tests. No staging residue remained.

## Phase 080 permanent launcher contract

`jail-shell`, `jail-opencode`, and `jail-comfyui` use Option C: no args launches Bash; `-c COMMAND [ARG...]` runs Bash command; `-- COMMAND [ARG...]` executes directly; malformed invocation exits 64; child exit codes propagate. Common restrictions: `--clean --no-save-config --private-home --hide-dotdir .secrets`, and writable mapping of **own project only**. Scratch has `--no-network`; OpenCode and ComfyUI get only their validated host allowlists and matching `--env-from-file`. Explicitly empty allowlists produce `--no-network`. Never create persistent project `.ai-jail` config. No real OpenCode/ComfyUI application was installed by 080.

## Phase 090 — OpenCode + VS Code + GSD

Before coding: inspect current system/config and existing launcher/orchestrator interfaces; determine pinned tool versions, GSD integration method, VS Code connection path, trusted install-time hosts, dependency downloads, proxy compatibility and safe update/recovery flow. Current config explicitly sets `INSTALL_OPENCODE=1`, `INSTALL_VSCODE=0`: do not silently flip the flag or re-enable Windows interop/automount to make editor connectivity work. Proposed changes require approval. Verify real OpenCode/network/download clients honor ai-jail's injected CONNECT proxy; do not equate Node core `fetch` or raw sockets with proxy-aware traffic. Record real `jail-opencode` execution and positive/negative sandbox checks. Keep execution, credentials and persistence in designated project boundaries.

## Phase 100 — ComfyUI using existing automation

Request/inventory all 90 Windows BAT steps and original requirements first. Map each step to Linux while preserving order, prerequisites, version pins, per-step logs, checks, resumability, failure handling and idempotence. Separate install-time egress approval from runtime `jail-comfyui` restrictions. Plan Python environment, GPU requirements and dependencies explicitly; no unapproved custom nodes. Verify actual download tooling uses ai-jail proxy or an approved install-time mechanism without widening runtime allowlists. Run ComfyUI via its launcher, bind service only to `127.0.0.1`, test intended Windows-localhost access if supported without changing WSL isolation, and deny LAN exposure.

## Phase 110 / 900 / 999

110: maintenance, least privilege, backup/restore, operator instructions and reconciliation of new phase flags; preserve earlier completed phases. 900: fresh end-to-end adversarial and functional tests with positive controls, exact exit codes and mandatory PASS/WARN/FAIL decision in `logs/REPORT.txt`; reverify ai-jail proxy behavior with installed applications. 999: separate manual-only rollback with explicit confirmation and C:-safe scope, never automatic.

## Change control and documentation

Keep `ROADMAP-003.md`, prior status, original failed network report and old hashes as history, not current instructions. Read this file with `REQUIREMENTS-004-ADDENDUM.md`, `STATUS-004.md`, and `HANDOFF.md`. The original `REQUIREMENTS.md` and `REVIEW.md` have not been inspected here; do not overwrite them wholesale without comparing their current content. ChatGPT drafts/reviews; OpenCode performs user-approved local inspections and actions; the user approves state-changing commands. Before Phase 090 installation, review its plan and obtain separate approval.
