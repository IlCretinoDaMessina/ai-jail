---
phase: 1
slug: foundation-orchestrator-contract
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-09-28
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None (pure batch) — `cmd /d /c` assertion scripts per AGENTS.md matching-test convention |
| **Config file** | none — Wave 0 creates `tests\verify-*.cmd` harness |
| **Quick run command** | `tests\verify-all.cmd` |
| **Full suite command** | `tests\verify-all.cmd` (runs every `tests\verify-*.cmd`, nonzero exit on any FAIL) |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task completes:** Run `tests\verify-all.cmd`
- **After every plan wave:** Run `tests\verify-all.cmd`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | INS-06 | T-1-01 / none | config.env sole source; no hardcoded drive/user in bats | unit | `tests\verify-config-load.cmd` | yes / no W0 | ✓ pending |
| 1-01-02 | 01 | 1 | INS-03 | T-1-02 / none | phases return only 0/1/3010; log written per phase | unit | `tests\verify-exit-contract.cmd` | yes / no W0 | ✓ pending |
| 1-01-03 | 01 | 1 | PLT-04 | T-1-03 / none | LF-only payload bytes (no 0x0D, no BOM) | unit | `tests\verify-lf-payload.cmd` | yes / no W0 | ✓ pending |
| 1-02-01 | 02 | 2 | INS-01 | none | 000 runs stubs in order, stop-on-fail, summary table emitted | unit | `tests\verify-run-all.cmd` | yes / no W0 | ✓ pending |
| 1-02-02 | 02 | 2 | INS-02 | none | `/from NNN` resumes, `/skip NNN` bypasses | unit | `tests\verify-run-all.cmd` | yes / no W0 | ✓ pending |
| 1-02-03 | 02 | 2 | INS-04 | none | 3010 → reboot + `/from` message, run stops, rc 3010 | unit | `tests\verify-run-all.cmd` (CI gate skips interactive `pause`) | yes / no W0 | ✓ pending |
| 1-03-01 | 03 | 3 | INS-05 | none | unelevated run aborts 010 with actionable message (PS principal probe) | unit | `tests\verify-preflight.cmd` | yes / no W0 | ✓ pending |
| 1-03-02 | 03 | 3 | INS-05 / INS-06 | none | six locked checks in order, fail-fast rc=1, config-driven; sandbox-only elevation seam (repo `_common.bat` untouched) | unit | `tests\verify-preflight.cmd` | yes / no W0 | ✓ pending |
| 1-03-03 | 03 | 3 | INS-01 / INS-05 | none | e2e: run-all discovers and runs real 010, summary row + `logs\010-preflight.log` | unit | `tests\verify-preflight.cmd` | yes / no W0 | ✓ pending |

*Status: ✓ pending · ✓ green · ✗ red · ~ flaky*

---

## Wave 0 Requirements

- [ ] `tests\fixtures\NNN-*.bat` — stub phases (001-ok / 002-fail / 003-reboot / 004-weird-out-of-contract) derived from experiment `t5b` fixture
- [ ] `tests\verify-all.cmd` — aggregate runner
- [ ] `tests\bytecheck.ps1` — LF/BOM byte assertion helper (from experiment `lfconv`)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 3010 reboot pause shows readable message then stops | INS-04 | interactive `pause` blocks unattended runs | Run stub 3010 phase via `000-run-all`, confirm message + rc; automated test uses CI gate variant |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
