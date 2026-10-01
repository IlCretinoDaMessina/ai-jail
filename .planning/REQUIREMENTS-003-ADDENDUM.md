# Requirements addendum 003 — scope and traceability

**2026-10-01.** Read with `.planning/REQUIREMENTS.md`; this addendum supersedes conflicting future-phase allocations without rewriting historical requirement IDs or marking untested work complete. Reconcile IDs against the actual original file before merging.

| Area | Updated requirement | Current evidence/status |
|---|---|---|
| 000–070 | Preserve completed orchestration, dedicated distro, isolation and ai-jail 2.2.0 gates. | Completed according to prior operational handoff; no reruns. |
| 080 | Safe config validation, three Option C wrappers, project/secret preservation, transactional apply, idempotence and rollback/recovery. | Individual wrappers tested; reported 96/96 review + 64/64 static apply PASS; live installer gate OPEN. |
| 090 | Install and verify OpenCode, approved VS Code integration and GSD in the dedicated WSL workflow, with `jail-opencode` runtime boundary. | Not started. Current `INSTALL_VSCODE=0`; implementation requires explicit resolution. |
| 100 | Adapt user's existing 90-step Windows 11 BAT ComfyUI automation to Linux; retain checks, sequencing, logs, recovery and version control; verify `jail-comfyui` and localhost-only service. | Not started; original 90 steps must be supplied and audited. |
| 110 | Hardening, maintenance, backup and documentation after application installation. | Not started. |
| 900 | Live adversarial verification with meaningful positive controls and full report. | Not started. |
| 999 | Manual-only, confirmation-gated, C:-safe rollback. | Not started. |

**Non-negotiable constraints:** no global `.wslconfig`, other distro or `docker-desktop` changes; no automount/interop restoration; no `wsl --shutdown`; no relaxation of sandbox policy for installation convenience; installation-time network access must not silently broaden runtime allowlists; existing credentials, project data and Git history must survive reruns. `ENABLE_NONO=0` means nono is optional future scope, not an existing security control. Phase exit-code contract is 0/1/3010.

**Migration note:** review the orchestrator's future-phase references and `INSTALL_COMFYUI`, `INSTALL_OPENCODE`, `INSTALL_VSCODE` semantics before editing; do not retroactively rerun or alter completed phases. An original requirement conflicting with the new 090/100 allocation should be cross-referenced here until the source is reviewed.
