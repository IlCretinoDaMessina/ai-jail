# Requirements addendum 004 — accepted 080 and split application phases

**Date:** 2026-10-01. Read alongside the original `.planning/REQUIREMENTS.md`. This document supersedes the future-phase/status statements in `REQUIREMENTS-003-ADDENDUM.md`, without replacing or inventing the original requirement IDs. Reconcile IDs against the actual original before merging.

| Area | Requirement and current acceptance status |
|---|---|
| 000–070 | Preserve completed orchestrator, dedicated distro, isolation and pinned ai-jail. Do not rerun completed phases. |
| 080 | **ACCEPTED.** Exact config validation before import; own-project Option C wrappers; secret and Git preservation; staged transactional promotion; rollback/recovery; LF-only verified transport; idempotence; explicit-mode direct invocation and orchestrator `--apply` forwarding. Successful live apply, repeat apply, functional isolation and corrected proxy-aware network acceptance reported. |
| 090 | **NOT STARTED.** Install/integrate OpenCode, VS Code and GSD with `jail-opencode` as the intended workload boundary; define pinning, downloads, logging, resumability, real application networking and editor connection without weakening WSL. Resolve current `INSTALL_VSCODE=0` by explicit design/approval; do not change it silently. |
| 100 | **NOT STARTED.** Adapt user's *existing 90-step Windows 11 BAT ComfyUI system* to Linux; preserve sequencing, prerequisites, logs, checks, recovery and idempotence. Verify real `jail-comfyui` runtime, localhost-only UI and permitted network flow. |
| 110 | **NOT STARTED.** Hardening, backup/restoration, maintenance and operator docs. |
| 900 | **NOT STARTED.** Independent final live functional/adversarial acceptance, with positive controls and report. |
| 999 | **NOT STARTED.** Explicit manual-only, C:-safe rollback; excluded from `000-run-all.bat`. |

## New enduring network requirement

ai-jail 2.2.0 filtered sandboxing uses a forced local HTTP CONNECT proxy, `127.0.0.1:15919`, for allowlisted destinations; direct DNS and direct outbound TCP are intentionally unavailable. Positive hostname connectivity MUST use a proxy-aware client, with approved and denied hosts both tested through CONNECT. Direct DNS, `/dev/tcp`, raw sockets and bypass are NEGATIVE isolation tests, never positive acceptance checks. In 090/100, explicitly verify real application's package managers, HTTP libraries and runtime requests honor injected proxy variables (or design separately reviewed, application-specific proxy support). Do not solve failures by globally enabling DNS, direct-IP exceptions, unrestricted egress, interop or automount.

## Final production integration

- `080-setup-sandboxes.bat` invokes `080-setup-sandboxes.ps1`.
- Direct BAT invocation requires `--review` or `--apply`; `000-run-all.bat` discovers the renamed phase and passes `--apply` to phase 080 alone. The mocked integration test passed; do not run the full orchestrator to test a rename.
- Phase 080 stays scoped to project/secrets/wrapper setup; Phase 090 owns OpenCode/editor/GSD installation; Phase 100 owns ComfyUI adaptation/installation.
- Installation-time privileges and hosts must be separately reviewed from restrictive runtime policy.

## Non-negotiable safety and evidence

No `docker-desktop`/other-distro operations, global `.wslconfig` edits, `wsl --shutdown`, auto-mount/interop restoration, secret disclosure, data/Git-history loss, or runtime network policy weakening. `ENABLE_NONO=0`; nono must not be described as enabled. Phase script exit contract is 0/1/3010. Keep original unsuccessful `/dev/tcp` network report as explained historical evidence and link its corrected 22/22 PASS addendum. Old phase-specific reports do not substitute for Phase 900 final tests.
