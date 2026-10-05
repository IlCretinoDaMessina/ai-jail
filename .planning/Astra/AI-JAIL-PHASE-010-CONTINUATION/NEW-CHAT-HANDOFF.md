# AI Jail — self-contained continuation handoff

## What we are building

A configuration-driven Windows installer that starts from a fresh supported Windows machine and provisions this stack:

```text
Windows → WSL2 → configured Ubuntu distribution → AI Jail
        → managed Linux OpenCode → TPS Meter → GSD Core
```

AI Jail supplies the Linux sandbox layer for AI tools. The intended product enforces restricted filesystem exposure, per-tool workspaces, protected credentials and default-deny networking with explicitly reviewed allowances. WSL restrictions must prevent ordinary Windows-drive/interop exposure inside the intended environment. These are requirements to implement and verify, not security properties already proven by Phase 000; WSL is not being presented as containment for arbitrary hostile code.

“Fresh start” means no existing AI Jail distro/account, old installer, pilot, downloaded binary, npm cache, node_modules, historical staging directory, generated GSD configuration, fixed username/drive/home path or previous conversation is required. The installer must obtain or create what it needs from validated configuration and verified upstream sources. Existing installations are preserved; adopting or migrating one is separate scope.

OpenCode, TPS Meter and GSD are the planned initial application stack. ComfyUI is an outstanding requested feature requiring its own future work. VS Code and nono are also outside the immediate milestone. Do not erase requested features from config to make completion claims easier.

The governing project plan identifies these upstream projects for later acquisition work: [AI Jail](https://github.com/akitaonrails/ai-jail), [OpenCode](https://github.com/anomalyco/opencode), [TPS Meter](https://github.com/ChiR24/opencode-tps-meter), [GSD Core](https://github.com/open-gsd/gsd-core), [Microsoft WSL](https://github.com/microsoft/WSL) and [bubblewrap](https://github.com/containers/bubblewrap). They are project references, not resolved artifacts or approved current versions. Phase 010 does not acquire any of them.

## Human-operated workflow

The user creates/replaces local files and runs commands. The assistant supplies complete files in copyable code blocks or downloadable files, with exact destination paths and separate CMD verification commands. Do not assume this chat has an editable checkout or local execution access. Do not claim a source file was saved, a command ran or a test passed without evidence.

Supply one coherent deliverable at a time, with one consolidated verification command where practical. State working directory, privileges, writes, network effects, expected exit code and marker. Wait for the user's returned output before acceptance or dependent progression. Do not fragment the work into dozens of tiny batches, repeatedly inspect unchanged files, or create more PASS-only scaffolding.

The current instruction is planning/continuation preparation. No tests, installation, WSL operations or provider requests were run while preparing this handoff. When the user asks the new chat to implement, the authorized output is source files and operator commands; live operations still follow their declared scope.

## Source locations and supplied bundle

Current local implementation: `D:\.coding\.ai-jail\modern-install\`.

Repository context: [IlCretinoDaMessina/ai-jail](https://github.com/IlCretinoDaMessina/ai-jail).

Historical material: `D:\.coding\.ai-jail\old system\` and `.planning\` in the repository. Neither is a runtime dependency or required input to begin 010. Do not execute old installers or edit historical material.

Local files may be newer than GitHub. The attached source snapshot takes precedence over a stale remote copy. Paths here identify the development machine only; use `$PSScriptRoot`, validated config and system discovery in implementation.

The companion `FILES-TO-PROVIDE.md` lists the exact attached files and reading order. `SOURCE-SNAPSHOT-SHA256.json` records their copied bytes. This is a fresh handoff snapshot, not proof those exact hashes participated in the earlier accepted test run. No repository code was changed by preparing the bundle.

## Read in this order

1. This handoff.
2. `PHASE-010-STRICT-PLAN.md` — the current implementation task and restrictions.
3. `modern-install/AI Jail Phase 000 — Exhaustive Implementation, Test, and Acceptance Report.md` — reported completed behavior and acceptance evidence.
4. `modern-install/AI JAIL — STRICT IMPLEMENTATION PLAN AND EXECUTION RULES.md` — long-term requirements and test-discipline addendum.
5. Current 010 files, then the relevant Phase 000 callers/validators/tests identified in the file inventory.

The original strict plan's instruction to begin with unfinished Phase 000 is historical and is superseded by the supplied acceptance report and this next-phase plan. Do not restart Phase 000 or deliver D2 files from an old package. Preserve accepted behavior while implementing the new real read-only path.

If an essential file is unavailable, identify it by name in one request. A Windows path in a message is not proof a cloud chat can read that file. Extract an attached ZIP if tools permit; otherwise ask for the listed core contents, not the whole previous conversation.

## Accepted Phase 000 baseline, as reported by the user

| Milestone | Reported result |
| --- | --- |
| D1 | Durable state transitions, previous-SHA compare-and-replace, state-store API compatibility, cooperative concurrency and same-phase 3010 resume state |
| D2 | Strict config bridge, bound one-use mock approvals, mock execution gate, redacted durable audit, interrupted-operation blocking |
| D3 | Dependency-ordered multi-phase mocks, separate mock verification, failure/3010/restart behavior, actual BAT → engine entry mapping |

Reported final markers:

```text
DELIVERABLE_3_ACCEPTANCE_OK
PHASE_000_MOCK_ACCEPTANCE_OK
DELIVERABLE_3_EXIT=0
```

The report gives 83 D2 focused assertions, 107 D3 orchestration assertions and 35 D3 entry assertions. These are historical results, not quotas or new test output.

Supported top-level entry concepts are REVIEW, blocked PLAN, blocked production APPLY/VERIFY, `/mock-execute <workspace> <approval-path>` and `/mock-resume <workspace> <approval-path>`. Generic `/from` and `/skip` remain blocked. The mock routes have no authority to run real installers.

Still unproven: real WSL provisioning, target creation, artifacts/download provenance, package/application installation, runtime health, isolation, and an actual Windows reboot boundary. Process-restart testing is not host-reboot testing. Audit hashes are not signatures, and cooperative locking does not defeat a hostile process that ignores it.

## Architecture and compatibility facts

- `000-config.ps1` is the authoritative 13-key config parser. `_common.bat :load` calls `000-config-export.ps1`; it must not parse raw config itself. Legacy `_common.bat :run_phase` is blocked.
- `000-dependencies.ps1` defines discovery and prerequisites. Discovery cannot execute a phase.
- `000-manifest.ps1` builds a deterministic blocked base snapshot, currently with 33 sources. Its list does not automatically bind every phase PS1 companion. A real 010 plan must bind its complete executable dependencies explicitly.
- `000-state.ps1` provides result transitions and resume directives. An exit 0 alone is not runtime verification.
- `000-state-store.ps1` preserves existing writer return objects, `-Directory` aliases, file reader semantics, exact diagnostics and expected-previous-SHA updates. It rejects durable active authority and currently rejects `RuntimeVerified=true`.
- `000-authorization.ps1` is D2's single-phase mock boundary. It intentionally supports only mock phase 010.
- `000-orchestration.ps1` adds D3 multi-phase MOCK_ONLY orchestration and its own bound mock verification. Do not turn that implementation into real execution by changing a scope string or passing a live target.
- `000-engine.ps1` and `000-run-all.bat` contain the accepted D3 entry integration; earlier handoff hashes for these files are stale.
- `000-deliverable3.tests.ps1` runs D2 (including D1), D3 focused orchestration and real entry integration. It allows only the known exact `D2_FAILURE_AUDIT_UNAVAILABLE` stderr diagnostic for the relevant negative tests. Do not broaden this allowance.

Core dependency order:

| Phase | Purpose / prerequisite context |
| --- | --- |
| 010 | Windows preflight; no preceding phase |
| 020 | WSL bootstrap/checks; requires real 010 runtime evidence before future real execution |
| 030 | New distro; depends on 010 and 020 runtime evidence |
| 040 | Linux user and WSL configuration |
| 050 | Effective runtime restrictions; hard security gate |
| 060 | Base toolchain |
| 070 | AI Jail |
| 080 | Workspaces and launchers |
| 090 | Managed Linux OpenCode |
| 091 | TPS Meter integration |
| 092 | Independent GSD acquisition/integration |

For precise later dependencies, read the current dependency module. Mock evidence may satisfy mock progression only. It must never satisfy the real 020 prerequisite.

Current feature values include `INSTALL_OPENCODE=1`, `INSTALL_COMFYUI=1`, `INSTALL_VSCODE=0`, `ENABLE_NONO=0`. Treat the actual config as authoritative. Its current distro/drive/user/version values are development inputs, not required defaults for every machine or permanently approved upstream versions.

## Next milestone: real read-only Phase 010

Follow `PHASE-010-STRICT-PLAN.md` strictly. Its three deliverables are:

1. Correct the actual Windows observation collector and fresh-host eligibility decisions.
2. Add a bounded real read-only execution/verification path with explicit source/config/host/state bindings and scoped evidence.
3. Supply focused and consolidated tests, obtain operator results, and finish with an honest acceptance report.

Known current defects: duplicate config parsing, weak username validation, running-hypervisor-only eligibility, unconditional HTTP connectivity, CI flags that skip a required check while retaining PASS, use of total free rather than caller-available disk bytes, incomplete real evidence and missing PS1 binding in the base source inventory.

Important design constraint: 010 is read-only. It must not fabricate APPLIED evidence or bypass the D1 prohibition on persisted runtime verification. Define the smallest explicit versioned extension required for real read-only evidence, preserving existing schema-1 behavior. A full `010 RUNTIME_PASS` must be distinct from local diagnostic success, mock verification and WSL-runtime readiness.

REVIEW stays offline. Missing WSL or an inactive hypervisor alone does not make a fresh supported host ineligible for bootstrap. Required probes that did not run cannot pass. Network access, if included, needs a precise approved probe policy; no environment variable can bypass it.

No phase 020 execution, WSL invocation, Windows feature changes, distro manipulation, software acquisition/installation, pilot migration, provider calls, automatic reboot or destructive recovery belongs to this milestone. Leave production APPLY disabled.

## First response required from the new chat

Briefly acknowledge the accepted mock baseline and that the next task is real read-only 010. Identify any genuinely missing core files once. Otherwise inspect the supplied current files and return the compact contract delta plus the first complete implementation deliverable and its bounded operator verification command.

Do not start by requesting the entire old conversation, rerunning eleven unchanged reviews, reimplementing D1–D3, enabling APPLY, or merely promising to continue. Diagnose any returned error against the actual call site and interface; do not alter tests/configuration to manufacture PASS.

Once real 010 acceptance is actually established, stop and report it. Phase 020 bootstrap is the next separate milestone and requires its own Windows-mutation scope.
