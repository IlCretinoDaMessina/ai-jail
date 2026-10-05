# Phase 010 warning completion — implementation for user-run verification

## Status and scope

Prepared from the full current files on D:, with baseline hashes verified against SHA256.json. The earlier warning patch and stale ZIP were not used as source. No project code, tests, live observations, PLAN, approvals, WSL, or installation were executed. Files on D: and all existing sessions remain untouched. Static parsing is not runtime acceptance.

This package implements a read-only continuation policy. Pending-file-renames alone, with complete redacted observations, produce WARN. CBS or Windows Update indicators remain FAIL. Missing, duplicate or unreadable required indicators produce UNKNOWN. Unknown conditions do not become harmless.

The online probe still uses the approved network policy, at most one request per pass and two across collection and verification. The pending-operation values are represented by counts and an ordered aggregate SHA-256, never raw paths. A hash is a consistency fingerprint, not encryption or proof of anonymity.

Clean collection and fresh verification retain `010 RUNTIME_PASS`. Stable warning-only collection and fresh verification can produce `010 PREFLIGHT_COMPLETE`, with `RuntimePass=false` and `InstallationAuthorized=false`. A changed warning between the two passes fails closed.

## Files to save

Copy the four files from `files/` directly into:

`D:\.coding\.ai-jail\modern-install\`

| File | Action |
| --- | --- |
| 010-preflight-core.ps1 | Replace the verified current file; keep a byte-for-byte backup outside modern-install. |
| 010-boundary.ps1 | Replace the verified current file; keep a byte-for-byte backup outside modern-install. |
| 010-warning-completion.tests.ps1 | New offline test suite. |
| 020-verified-wsl-check.ps1 | New explicit read-only entry point consuming bound evidence. |

Check the baseline hashes in SHA256.json before replacement and replacement hashes afterward. If a baseline differs, stop and inspect the current full file; do not force replacement or adjust the hashes to bypass the check. Save both replacements before running any project command. Do not run the earlier `010-warning-continuation.patch.ps1` or its earlier proposed tests. No patch script is needed here.

Do not replace 000-engine.ps1, any Phase 000 dependency/orchestration/state module, 020-wsl-check.ps1, 020-requirements.json, config.env, or the retained test suites. Those are deliberately outside this replacement set. The reviewed original Phase 020 source and requirements hashes are recorded in the manifest and checked before the new entry point invokes them.

## Real consumer and practical progression

`Assert-Aij010PreflightCompleteEvidence` reads the actual session on disk. It validates current PLAN/source/config/requirements/host/target-volume/boot bindings, recomputes decisions from both observation records, checks the warning and network counts, rejects stale/future timestamps, and validates the approval, used marker, receipt, and execution audit chain. Existing runtime-pass readers still reject warning-only evidence.

`020-verified-wsl-check.ps1` calls that consumer before invoking the reviewed existing `020-wsl-check.ps1` in Windows PowerShell 5.1. It does not elevate automatically. Invoking it is a separate user decision to perform a WSL version query. The Phase 010 approval itself does not authorize WSL execution.

Important limit: the Phase 000 generic orchestrator and mock dependency rules remain unchanged. This package provides an explicit real read-only route; it does not claim to integrate all later installation phases or emit durable Phase 020 runtime evidence for Phase 030. Do not attempt generic APPLY or treat the new completion state as satisfying an installation dependency. Later modifying phases require their own implementation, authorization and warning disposition.

## User-run verification — no elevation required

The assistant/chat must not run tests. Give the user these commands, review actual output, and stop at the first failure. The new suite writes only to a unique %TEMP% fixture, retains it for diagnostics, mocks external observations, and uses the actual PLAN/approval/execution/evidence-consumer functions. It never invokes the Phase 020 script or WSL.

In ordinary CMD:

```bat
cd /d "D:\.coding\.ai-jail\modern-install"
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ".\010-warning-completion.tests.ps1"
echo WARNING_COMPLETION_EXIT=%ERRORLEVEL%
```

Expected only after an actual successful run: `PHASE_010_WARNING_COMPLETION_FIXTURES_OK` and exit 0. Do not predict or invent an assertion count.

Then run each retained suite, inspecting its exit and output before continuing:

```bat
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ".\010-engine-bootstrap.tests.ps1"
echo ENGINE_BOOTSTRAP_EXIT=%ERRORLEVEL%
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ".\010-preflight.tests.ps1"
echo PHASE_010_A_FIXTURE_EXIT=%ERRORLEVEL%
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ".\010-bound-execution.tests.ps1"
echo PHASE_010_B_FIXTURE_EXIT=%ERRORLEVEL%
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ".\000-deliverable3.tests.ps1"
echo DELIVERABLE_3_EXIT=%ERRORLEVEL%
```

Optional: VERIFY.cmd in the package runs these five suites sequentially and stops on the first nonzero result. Invoke it from modern-install, using its absolute path; do not run it from the extracted package directory.

Final Phase 000 regression must retain `DELIVERABLE_3_ACCEPTANCE_OK`, `PHASE_000_MOCK_ACCEPTANCE_OK`, and exit 0. Do not loosen old assertions to hide an unexpected incompatibility. Diagnose the first failing statement and change only the concrete defect.

## Live continuation only after the suites pass

1. Preserve all previous real sessions, including -002, -003 and -004. Their source locks are stale after replacement. Do not edit or reuse them.
2. Choose a genuinely unused session path. Confirm the current configuration still selects the user's intended C: target. Create a fresh bound PLAN using the existing /preflight-010-plan route.
3. Review the actual PLAN, obtain explicit approval through the existing separate route, then perform the already-scoped read-only collection/verification. Do not combine these steps into an unattended command chain.
4. Inspect the actual receipt and verification output. A warning result is complete read-only evidence, not a clean machine, not installation approval, and not proof that pending operations are harmless.
5. Supply the new consumer command with the actual session path and actual verification filename; never invent either. `-EvidenceOnly` checks admission without WSL execution:

```bat
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ".\020-verified-wsl-check.ps1" -SessionDirectory "ACTUAL_NEW_SESSION" -VerificationPath "ACTUAL_VERIFICATION_JSON" -EvidenceOnly
echo PHASE_020_ADMISSION_EXIT=%ERRORLEVEL%
```

6. Only when the user elects to run the read-only WSL version check, supply that same command without `-EvidenceOnly`. The existing Phase 020 check requires an already elevated shell; it will not elevate itself. It executes `wsl.exe --version`, and does not install/update/shut down WSL or execute any distro. Keep warning information visible.

Evidence expires under the existing five-minute freshness policy. Do not disable freshness or reuse consumed approvals to get past expiration. Arrange the user-run sequence accordingly and obtain fresh evidence through a new properly approved cycle when necessary.

## Handoff rule

Report separately: files supplied, saved/hash-checked, syntax parsing, focused behavior tests, retained regressions, live collection, actual consumer acceptance and actual WSL check. Currently only source preparation and syntax parsing have been performed here. No PASS or acceptance claim is authorized by the package alone.
