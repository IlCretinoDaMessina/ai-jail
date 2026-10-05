# AI Jail — Phase 010 strict implementation plan

## Objective and current authority

Implement the first real, read-only Windows preflight, with separately verified evidence that can eventually satisfy the real `010 RUNTIME_PASS` prerequisite. Do not implement WSL installation or execute Phase 020.

The supplied Phase 000 exhaustive report records D1, D2 and D3 acceptance, including `PHASE_000_MOCK_ACCEPTANCE_OK` and exit 0. Treat this as reported acceptance of mock orchestration. This planning session did not rerun those tests or certify the current files against an independently captured accepted-run hash manifest.

The current source snapshot and acceptance report supersede historical statements that Phase 000 is unfinished. The original strict implementation plan still governs product scope and safety. This document narrows the next milestone; it does not authorize a live installation or an assistant-operated test run.

## Why this is the next milestone

The existing `010-requirements.json` declares read-only operation, administrator checks, configuration/user validation, virtualization, disk space and internet checks. It forbids WSL execution, downloads and system modifications. The inventory treats 010/020 as `LEGACY_READ_ONLY_QUERY` and rejects a modern `mode` field in those legacy requirements.

Concrete defects found in the current `010-preflight.ps1`:

1. It implements another config parser instead of calling `Read-AijConfig`.
2. It tests only that the Linux username is nonempty, bypassing the authoritative username rules.
3. It equates `HypervisorPresent = false` with failure. That is incompatible with the fresh-machine bootstrap objective.
4. It makes a network request during the normal path, rather than separating offline review from approved online checks.
5. `AIJAIL_CI=1` plus `AIJAIL_TEST_SKIP_INTERNET=1` skips connectivity but still permits an overall phase PASS.
6. It uses total free bytes rather than bytes available to the caller.
7. It lacks a complete build/architecture/readiness classification and separately bound verification evidence.
8. Its companion PS1 is not in the existing 33-file base PLAN source list. A real execution plan must explicitly bind it and every new executable dependency.

Fix these gaps. Do not restart Phase 000 or build another mock-only orchestration framework.

## Work in three consolidated deliverables

### Deliverable A — real observation collector and decision rules

Read the relevant files once, record the current hashes, and produce a short contract delta before supplying code. The delta must identify the permitted probes, per-mode requirements, evidence format, command syntax, intended file changes and compatibility impact. Keep it to one implementation-oriented description, then provide the files; do not turn it into another planning milestone.

Extend `010-preflight.ps1`, `010-preflight.bat` and `010-requirements.json`. Reuse `000-config.ps1` as the sole parser. Keep PowerShell 5.1 and thin BAT launching. A single `010-preflight-core.ps1` is permitted if needed to separate pure decision functions from live Windows queries and the process entry point. Do not introduce a framework or a second configuration schema.

Implement these observations:

| Observation | Required behavior |
| --- | --- |
| Configuration | Strictly parse all current keys once. Preserve empty allowlists and all enabled feature flags. Derive paths and usernames; never substitute historical defaults. |
| Windows platform | Record numeric OS build and native architecture using structured local Windows data. Declare the supported platform policy and compare numerically. Distinguish unsupported from unavailable/ambiguous observations. |
| Privilege | Observe current elevation. Preserve the administrator requirement for the complete real preflight until intentionally revised. Offline REVIEW must never elevate. Orchestrated execution must never prompt for UAC or pause. |
| Virtualization | Inspect documented CPU/firmware capability and hypervisor observations. Classify prerequisites as satisfied, bootstrap-needed, manual-action-needed, unsupported or unknown. Absence of a running hypervisor alone is not rejection. Do not turn unknown or contradictory data into success. |
| Storage | Resolve the configured local drive/volume, its identity and readiness; reject unsupported/ambiguous targets and unsafe path indirection. Compare `AvailableFreeSpace` in bytes against a validated threshold. Do not create the installation directory or write a probe file to the installation target. |
| Linux username | Validate proposed account syntax using the authoritative parser; do not require that the Linux account or distro already exists. |
| WSL readiness | Observe available Windows-side feature/package/file information without executing `wsl.exe`. Distinguish absent, present, known-too-old, version-unknown and bootstrap-needed. Missing WSL is compatible with eligibility for later bootstrap. Version/capability proof requiring WSL commands belongs to 020. |
| Reboot observations | Record the selected documented Windows indicators and their meaning. Do not claim a universal “no reboot pending” proof from one missing registry value. Never modify a reboot indicator or reboot the host. |
| Connectivity | Default off. A separately specified, approved probe may perform a bounded network check; see the network contract below. No environment-variable bypass. |

A clean supported host may pass eligibility while WSL is absent and bootstrap is required. That is not evidence that WSL already works. A machine requiring firmware changes must receive a precise manual-action result rather than automatic remediation.

Keep all observations typed. Missing CIM properties, nulls, partial arrays, command failures, unreadable volumes, timeouts and unsupported APIs produce explicit unknown/failed results. Evaluate every relevant CPU record; do not silently use an arbitrary first item.

### Deliverable B — bound read-only execution and real verification evidence

Reuse the accepted approval, source binding, locking, durable evidence and failure principles. Do not pass a real host through mock workspace validators or relabel mock results as real.

Use a distinct scope such as `REAL_WINDOWS_PREFLIGHT_010` for the plan, receipt and verification record. Phase remains `010`. General production APPLY/VERIFY remain blocked. Retain `production_apply_authorized: false` and all existing mock modes.

Provide a dedicated fixed phase-010 route through the existing BAT/engine, for example `/preflight-010 <session-directory> <approval-path>`. Fix the exact syntax in the initial contract delta, then test it in BAT and direct PowerShell. It must select only the known read-only handler; no arbitrary command, callback, script path, phase selector or shell fragment may be supplied by a plan.

The phase entry point must support offline review/plan preparation and deliberate approval separately from real collection/verification. Default invocation must not contact the network. Standalone auto-elevation, if retained, is available only for an explicitly requested live operation, never during REVIEW, PLAN or automated tests. Do not interpret `PHASE_LOG`, CI flags or inherited environment values as authorization.

Bind each operation to:

- exact plan, requirement profile and configuration hashes;
- the full real execution source closure, including `010-preflight.ps1`, any core/helper, BAT/engine, shared parser, persistence and authorization components;
- a real Windows-host identity reference and configured volume identity, with privacy-conscious fingerprints in ordinary logs;
- previous state/evidence identity and operation kind;
- explicit no-artifact acquisition lock;
- exact permitted probes, privilege and any network destinations;
- a real confirmation through the controlled entry point, recorded once and consumed once.

Validate source bytes before loading affected phase code. A changed script, requirement, config, target identity or network scope invalidates the approval. A checksum alone is not approval or publisher authentication.

Collection success and verification are separate results. Verification must check record integrity and completeness, recompute the decision using the bound requirements, and obtain fresh observations of mutable eligibility conditions. Do not merely read an exit code or copy the collector's boolean. When both steps are covered by one operation approval, list both in the plan and bound network request count. A later independent rerun needs a fresh receipt.

Minimum real evidence fields:

```text
schema / kind / execution scope / phase / operation ID
plan SHA / requirements SHA / config SHA / source-lock SHA
host identity reference / configured volume identity
previous state SHA / collection-result SHA
collector method identifiers and typed observations
required-check completion and individual decisions
network policy and whether the probe actually ran
verification method / fresh observations / decision
UTC timestamp / freshness policy / applicable boot-session reference
eligible-for-bootstrap / bootstrap-needed / manual-action reasons
dependency result and the explicit scope of that result
```

`010 RUNTIME_PASS` means the bound real Windows preflight profile was collected and verified successfully on the identified host/volume. It does not mean a distro exists, WSL is working, the sandbox is secure, an application is installed or provider access succeeded. No test fixture or mock VERIFY record may satisfy it.

Do not invent `APPLIED` evidence for a read-only phase. The accepted D1 store currently rejects persisted `RuntimeVerified=true`; the D3 verifier is mock-only. Account for these facts explicitly. If persistence needs a new read-only result/evidence shape, implement a small versioned extension in the existing shared persistence/validation path with regression coverage. Preserve schema-1 readers, writer signatures, `-Directory` aliases, file-path semantics, return objects and contractual diagnostics. Do not weaken schema-1 validation, hide real evidence in unchecked extra fields, or create a parallel state engine. Existing mock state must never be silently upgraded or adopted as a real-host session.

Store state, receipts, temporary journal data and redacted evidence only inside an explicitly designated installer-owned session directory. These bookkeeping writes are permitted; WSL/installation-target/system configuration changes are not. Protect paths from reparse/alias confusion, serialize cooperating writers, use expected-previous-SHA updates, and retain a recovery blocker after uncertain persistence. Do not overwrite an unrelated existing directory or follow arbitrary session paths from untrusted records.

Provide a real dependency-evidence validator capable of deciding whether the new record could satisfy `010 RUNTIME_PASS`. Test that predicate with valid and invalid evidence. Do not invoke 020 or enable its installation path in this milestone.

### Deliverable C — meaningful acceptance and operator handoff

Supply a focused test file and one consolidated Phase 010 runner, for example `010-preflight.tests.ps1` and `010-acceptance.tests.ps1`. One command per coherent deliverable is preferable to dozens of individually pasted commands.

The automated runner must use isolated fixtures and bounded child processes. It must not contact the network, prompt for UAC, execute WSL, run real downstream phase handlers, install software or change the host. Supplying mock observation data must never produce evidence labeled real. Tests may check the real entry route against denied and controlled fixture cases.

Required coverage:

1. All named existing defects, including strict parser reuse, unknown/duplicate configuration rejection, empty allowlists and CI-flag bypass attempts.
2. Fresh host without WSL or a running hypervisor; supported capability versus disabled firmware; active-hypervisor and missing/contradictory observation cases; unsupported build/architecture.
3. Ready, missing, inaccessible and changed volumes; exact threshold boundary; available versus total free bytes; no target directory creation.
4. Offline REVIEW/PLAN with a network spy proving zero requests and zero WSL/elevation calls. Missing/skipped required connectivity cannot yield a full runtime pass.
5. Bounded network adapter fixtures: valid expected response, unexpected status/body, redirect, proxy/captive portal, timeout and TLS failure where HTTPS is used. Distinguish reachability from security/provenance.
6. Missing/changed/replayed approvals; changed plan/config/requirements/PS1/source/host/volume/state; direct PS1 invocation; unknown or surplus BAT arguments.
7. Fixture and D2/D3 mock evidence rejected by the real dependency validator; successful collection without verification rejected; verification bound to another operation rejected; expired/different-boot evidence revalidated or rejected.
8. Required audit unavailable/corrupt, interrupted evidence persistence, stale CAS updates, reparse paths, competing cooperating attempts and preservation of recovery evidence.
9. Explicit no-effect guards and negative-test helper controls: wrong exception, skipped operation and unexpected acceptance must fail the test.
10. Phase 010's documented 0/1 result mapping. An unexpected 3010 from this read-only handler fails closed unless a deliberate future contract revision authorizes it. Preserve the existing Phase 000 3010 behavior for other scopes.
11. The full accepted D1+D2+D3 regression after changes to their shared execution path. Keep the exact known D2 negative stderr allowance; never suppress all stderr.

Run focused tests while fixing a concrete failure. Run the final consolidated regression once after the integration is stable, repeating only when changes/failures justify it. Do not demand a full rerun of an unchanged baseline merely to begin coding.

The human operates the machine. Supply complete files and copyable CMD commands; wait for returned output before claiming acceptance. Every command must state its purpose, working directory, elevation requirement, files written, network effects and expected exit/marker. Expected output is not evidence of execution.

Live read-only acceptance is a separately identified operator action after fixture acceptance. Present the precise probes and network scope. The user may approve a complete read-only attempt once; do not ask again for each probe in that approved scope. If live testing is not authorized or cannot complete, report `IMPLEMENTED / FIXTURE-TESTED / LIVE-UNVERIFIED` as applicable, not Phase 010 accepted. Fixtures can establish clean-host logic, but cannot prove a real clean-machine installation.

## Offline and network contract

Offline REVIEW remains completely offline, including DNS and connectivity tests. PLAN may prepare local metadata/evidence but acquires no software in this milestone. Do not change installation/runtime host allowlists merely to make a connectivity check pass.

The existing mandatory `internet` check requires a deliberate per-mode clarification in 010 requirements. Offline-only diagnostics can succeed as their own requested operation, but must report connectivity `NOT_RUN` and cannot emit a full `010 RUNTIME_PASS` while that required check is missing. Do not silently delete the requirement.

For an approved online profile, bind one explicit endpoint, protocol/port, method, expected status/content, timeout, response-size limit, maximum requests and redirect/proxy behavior into the plan. An explicit, separate preflight-probe policy may authorize that endpoint; it must not be inferred from CI, ordinary internet access or a runtime workload allowlist. An empty applicable network policy denies requests. Resolve this policy in the first contract delta rather than adding a thirteenth workaround later.

The existing Microsoft HTTP NCSI probe can establish only limited connectivity. It does not authenticate downloads, prove TLS readiness, prove all registries work, or prove sandbox network enforcement. If retained, label it accurately, validate the expected response and do not follow arbitrary redirects. Fetch only bounded probe data into memory, never an artifact or executable. If a different endpoint is selected, document the reason and official source before implementation.

## Non-negotiable restrictions

- No `wsl.exe` invocation in 010, including status/list commands; no distro start, stop, import, install, update, unregister or shutdown.
- No Windows feature changes, registry writes, BCD edits, global `.wslconfig`, firewall changes, service control, scheduled tasks, firmware changes or reboot.
- No artifact/package downloads, remote code, installer execution, credential requests or provider/model API calls.
- No live application/pilot changes, existing-distribution adoption, migration, destructive cleanup or secret access.
- No ComfyUI, VS Code, nono, 020–092 implementation or unrelated modernization.
- No changes to current config values to obtain a PASS; `INSTALL_COMFYUI=1` remains an outstanding requested feature outside this milestone.
- No automatic test execution by the assistant in the user-operated chat. No claim that a supplied file was saved or that an unreturned test passed.
- No old temporary paths, historical versions, existing caches, pilot artifacts or previous-chat knowledge as installation dependencies.
- Do not add `mode` to 010's legacy requirements without an intentional compatible inventory revision. Version any substantive contract change and update its consumers together.
- No repair-by-guessing: obtain the actual error and relevant call site before replacing interfaces. Do not successively patch parameter names without reconciling callers and tests.

## Stop conditions and completion

Stop the affected operation for unresolved contract conflicts, unexpected mutation, unclear target identity, failed required evidence or an unapproved material expansion. Continue independent source work where possible. Ask only for missing essential files, a material scope decision or a genuinely unauthorized live action; do not seek approval for routine implementation choices.

Complete this milestone only when the code, focused tests, compatibility regression and authorized real read-only verification have actual supporting results. Report changed files, exact commands/results, permitted effects, remaining unproven behavior and the next milestone. The next milestone after that is planning Phase 020 WSL bootstrap, with separate authority for Windows changes. Do not begin it automatically.

## Focused primary sources

Checked while preparing this plan; recheck only if implementation depends on a changed detail:

- Windows build prerequisites for Microsoft's installation route: [Install WSL](https://learn.microsoft.com/en-us/windows/wsl/install). Do not confuse that command's compatibility floor with the complete project's supported-OS policy.
- CPU virtualization observation properties: [Win32_Processor](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-processor).
- Running-hypervisor observation: [Win32_ComputerSystem](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-computersystem). The clean-host eligibility rule above is a project design decision using multiple observations.
- Virtualization/SLAT troubleshooting context: [WSL troubleshooting](https://learn.microsoft.com/en-us/windows/wsl/troubleshooting).
- Connectivity/proxy/captive-portal interpretation: [NCSI troubleshooting guidance](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/troubleshoot-ncsi-guidance).

These references inform Phase 010 only. Do not spend this milestone re-researching OpenCode/GSD releases or resolving later-phase artifacts.
