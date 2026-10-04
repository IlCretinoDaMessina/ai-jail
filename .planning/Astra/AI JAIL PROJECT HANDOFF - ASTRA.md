AI JAIL — PROJECT HANDOFF

Prepared: 4 October 2026

Status: Source review and implementation planning completed.

Implementation has not started in this conversation.



1\. PURPOSE



Modernize the existing AI Jail Windows installer into a reliable,

configuration-driven installer that works from a fresh Windows setup.



The intended stack is:

Windows → WSL → configured Ubuntu distribution → AI Jail →

OpenCode → TPS Meter → GSD.



“Fresh installation” means no dependency on:

\- An existing AI Jail distro or Linux account.

\- A previous pilot installation.

\- Historical staging directories.

\- Previously downloaded binaries, npm caches or node\_modules.

\- Previously generated GSD files.

\- A particular drive letter, username or home directory.

\- The old installer being present.

\- Knowledge from this conversation.



Development paths listed below identify the current source material.

They must not become hardcoded installation dependencies.





2\. USER INTENT AND WORKING PREFERENCES



The user requested:

\- Review of the existing handoff and both installer generations.

\- A specific implementation plan with firm rules and restrictions.

\- Research of the relevant upstream GitHub repositories.

\- A self-contained handoff for continuing in another chat.



The user has requested planning and documentation, not live installation.



Work efficiently:

\- Read the relevant current files once.

\- Start the first unfinished milestone.

\- Implement and verify concrete behavior.

\- Avoid repeated reviews, unnecessary redesign and unrelated refactoring.

\- Do not create more scripts that print PASS without implementing the

&#x20; operation they claim to support.

\- Ask only for essential information, material scope changes or genuinely

&#x20; unauthorized actions.

\- Do not repeatedly request approval for work already authorized.

\- Give concise progress updates and clear completion evidence.



When implementation is requested, begin with Phase 000.

Do not jump directly to installing OpenCode or copying the old pilot.





3\. CURRENT SOURCE LOCATIONS



Modern installer:

D:\\.coding\\.ai-jail\\modern-install



Legacy installer and reference material:

D:\\.coding\\.ai-jail\\old system



Project repository:

https://github.com/IlCretinoDaMessina/ai-jail



Original handoff:

https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/AI%20JAIL%20%E2%80%94%20COMPLETE%20MODERN%20INSTALLATION%20HANDOFF.md



Read applicable repository instructions before editing.



Use the modern installer as the implementation target.

Use the old system as a behavioral reference.

Do not modify historical files as a shortcut.



These locations describe this development machine only.

The finished installer must obtain all operational paths from validated

configuration and system discovery.





4\. WORK ACTUALLY COMPLETED



Completed:

\- Read the original installation handoff.

\- Inspected the modern installer files.

\- Inspected the relevant legacy scripts and documentation.

\- Compared the review scaffolding with the old execution paths.

\- Researched upstream release metadata, package manifests, installers,

&#x20; configuration loading, plugin installation and security documentation.

\- Produced a detailed implementation plan in the conversation.



Not completed:

\- No installer implementation changes.

\- No WSL provisioning or installation execution.

\- No distro termination, shutdown, unregister or migration.

\- No package installation.

\- No application/plugin execution for testing.

\- No runtime isolation verification.

\- No clean-Windows acceptance test.

\- No production deployment.

\- No provider authentication or model requests.



Research downloaded metadata and source text only.



Research notes/source snapshots exist under:

C:\\Users\\4l3x\\Documents\\Codex\\2026-10-04\\what-is-the-folder-you-have\\work\\upstream-research



That folder is optional supporting evidence, not a runtime dependency.



Do not describe the research as a full security audit or runtime validation.





5\. CURRENT MODERN INSTALLER STATE



The modern folder contains:

\- config.env

\- \_common.bat

\- 000-run-all.bat

\- 000-review.ps1

\- 000-requirements.json

\- Numbered BAT, PowerShell and requirements files for phases 010–092.



Current phase purposes:

010 — preflight

020 — WSL checks

030 — distribution/storage checks

040 — distro configuration

050 — isolation gate

060 — base toolchain

070 — AI Jail

080 — sandboxes/workspaces/launchers

090 — OpenCode

091 — OpenCode plugins

092 — GSD source/integration



The modern files are predominantly review scaffolding.

They do not collectively implement a fresh installation.



Some early review paths already perform host, connectivity or WSL-related

probes. Do not assume every existing “review” entry point is offline.



Phase 000 currently validates and reviews; it is not the complete execution

orchestrator required by the plan.



Phase 050 requirements explicitly distinguish offline policy review from

runtime proof. Preserve that distinction.



Phase 080 generates launcher content during review but does not provide the

complete fresh installation payload.



Phases 090–092 still contain historical assumptions about selected

versions, targets or feature settings. These must be replaced by validated

configuration and independent acquisition.



Do not recreate the withdrawn 000-plan.ps1 design.





6\. CONFIGURATION OBSERVED



The existing schema has these 13 keys:



TARGET\_DRIVE

DISTRO

BASE\_DISTRO

LINUX\_USER

MIN\_WSL\_VERSION

MIN\_FREE\_GB

ALLOW\_HOSTS\_OPENCODE

ALLOW\_HOSTS\_COMFYUI

ALLOW\_HOSTS\_INSTALL

INSTALL\_COMFYUI

INSTALL\_OPENCODE

INSTALL\_VSCODE

ENABLE\_NONO



Observed current values include:

\- TARGET\_DRIVE=D:

\- DISTRO=ai-jail

\- BASE\_DISTRO=Ubuntu-24.04

\- LINUX\_USER=aijail

\- MIN\_WSL\_VERSION=2.4.4

\- MIN\_FREE\_GB=20

\- INSTALL\_COMFYUI=1

\- INSTALL\_OPENCODE=1

\- INSTALL\_VSCODE=0

\- ENABLE\_NONO=0



These are existing configuration values, not mandatory defaults for every

fresh machine.



Important inconsistency:

Phase 080 allows an empty host allowlist to mean no network access, while

Phase 000 currently rejects empty required values generally.



Required resolution:

\- Missing allowlist key: error.

\- Present but empty allowlist: valid, network denied.



Implement one authoritative parser.

Treat config.env as data, never executable shell input.

Reject duplicate/unknown keys, invalid types and unsafe values.

Do not export arbitrary config keys into the process environment.



ComfyUI is enabled in the current configuration but is outside the immediate

000–092 implementation milestone. Do not silently disable it or claim the

entire requested profile is complete while it remains unimplemented.





7\. IMPORTANT LEGACY FINDINGS



The legacy installer contains useful implementation ideas but must not be

copied wholesale.



Known issues to address:



Orchestration:

\- /from can bypass earlier phases.

\- /skip is insufficiently restricted.

\- Unknown arguments may be ignored.

\- Approval and apply behavior differ between BAT and PowerShell.



Configuration/logging helpers:

\- \_common.bat needs careful review of environment handling, quoting,

&#x20; argument forwarding and exit-code preservation.

\- Preserve its user-facing contract, not unsafe internals.



WSL configuration:

\- Existing logic handles an absent wsl.conf poorly.

\- Configuration writing and distro termination are insufficiently separated.

\- Runtime checks can misinterpret missing tools or failed probes as success.



Isolation:

\- “Command failed” is not automatically “access denied.”

\- Empty grep output is not proof if the command or pipeline failed.

\- Network failure alone does not prove policy enforcement.



Toolchain:

\- The old phase checks many prerequisites but does not install all of them.



Workspaces:

\- Some staging, byte transport and rollback ideas are useful.

\- Wrapper rollback does not imply all created directories/repos were rolled

&#x20; back.

\- Direct PowerShell execution must not bypass approval enforced by BAT.



OpenCode/GSD:

\- Old installation paths depend on pilot binaries and historical staging.

\- GSD generation/output locations are not portable.

\- A historical fixed command count is not a valid future acceptance rule.

\- Native Windows OpenCode fallback would bypass the intended jail.



Historical documentation reports some successful live work.

Those reports do not prove that the current modern installer works on a

fresh machine.





8\. EXISTING STATE THAT MUST BE PROTECTED



The original handoff identifies existing state including:

\- Distro: ai-jail

\- Linux user: aijail

\- VHDX: D:\\ai-jail\\wsl\\ext4.vhdx

\- Existing projects, credentials, pilot files and staging material.

\- Reported backup:

&#x20; D:\\.coding\\.ai-jail\\.bkps\\ai-jail-baseline-backup.tar



The backup’s existence, integrity and restorability were not independently

verified in this conversation.



Do not:

\- Adopt or replace an existing same-name distro automatically.

\- Modify production merely because its name matches config.env.

\- Terminate a distro without explicit authorization covering that action.

\- Run global wsl --shutdown.

\- Unregister a distro.

\- Edit global .wslconfig.

\- Alter unrelated distros or the default distro.

\- Delete historical staging, projects or backups.



Discover and verify actual target identity and storage before every apply.



A disposable test distro must have an explicitly approved distinct identity

and location. Creating another distro does not make WSL a security boundary

from the Windows account.





9\. UPSTREAM RESEARCH SNAPSHOT



Observed release/package candidates on 4 October 2026:

\- AI Jail: v2.6.3

\- OpenCode: v1.18.34

\- TPS Meter: v0.4.0

\- GSD Core: v1.15.0



These are research candidates, not an approved or runtime-tested combination.



Recheck the latest compatible stable releases when implementing acquisition.

Resolve once and lock exact versions/artifacts for an approved installation.

Do not follow moving latest tags during apply.



Primary sources:

https://github.com/akitaonrails/ai-jail

https://github.com/anomalyco/opencode

https://github.com/ChiR24/opencode-tps-meter

https://github.com/open-gsd/gsd-core

https://github.com/microsoft/WSL

https://github.com/containers/bubblewrap



Microsoft command/configuration references:

https://learn.microsoft.com/en-us/windows/wsl/basic-commands

https://learn.microsoft.com/en-us/windows/wsl/wsl-config



Use source and documentation matching the selected release.

Default branches and stable published packages can differ.





10\. RESEARCH FINDINGS THAT AFFECT IMPLEMENTATION



AI Jail:

\- Upstream describes it as protection against mistakes by trusted-but-

&#x20; fallible agents, not a complete boundary for hostile code.

\- Defaults can expose agent state and credentials.

\- Toolchain integration can add registry hosts to network allowances.

\- --clean alone is not a complete policy.

\- Review explicit controls for agent state, toolchains, mise, environment,

&#x20; update checks, private home, mounts and network access.

\- The researched CLI supports relevant opt-outs including --no-agent-state,

&#x20; --no-toolchains, --no-mise, --no-inherit-env and --no-update-check.

\- Host allowances include subdomains.

\- Terminal passthrough has security implications and must be deliberate.

\- Never enable test-only security-bypass build features.



OpenCode:

\- The researched v1 release supports:

&#x20; opencode plug opencode-tps-meter@<exact-version> --global

\- Configuration loads from multiple sources.

\- OPENCODE\_CONFIG alone is not an immutable policy boundary.

\- Account for project configuration, environment overrides, plugin

&#x20; discovery and automatic dependency installation.

\- Select the correct architecture/libc/CPU binary variant.



TPS Meter:

\- Instructions differ for OpenCode generations.

\- Use the procedure matching the locked OpenCode release.

\- Validate structured registrations and the installed package identity.

\- Do not fabricate OpenCode’s cache/package layout.

\- Redirecting config does not necessarily redirect every cache.



GSD:

\- The researched package declares Node >=24 and npm >=10.

\- Its runtime guide contains older Node guidance; package requirements and

&#x20; compatibility testing must resolve that discrepancy.

\- The official installer transforms runtime-specific files.

\- Do not copy raw commands/agents directly into OpenCode.

\- Supported config-directory redirection allows controlled staging.

\- Generated integration includes commands, agents, skills and a native

&#x20; plugin.

\- Its plugin-directory CommonJS marker can affect other JavaScript plugins.

\- Lifecycle scripts, dependencies and optional dependencies require review.

\- The MCP entry point and generated OpenCode plugin are different things.

\- Do not assume a permanent command count or historical output layout.



WSL/Bubblewrap:

\- Microsoft does not treat a WSL distro as a security boundary from its

&#x20; associated Windows user.

\- Disabling automount and interop changes behavior; it does not prove

&#x20; containment of hostile code.

\- Bubblewrap’s protection depends on the policy and arguments supplied.

\- Report tested restrictions precisely; do not promise complete isolation.





11\. NEXT IMPLEMENTATION MILESTONE: PHASE 000



When the user authorizes implementation, start here.



Preserve:

\- BAT front doors.

\- PowerShell 5.1 compatibility.

\- Numbered phase discovery.

\- Per-phase requirements and logs.

\- Standalone and orchestrated use.

\- Exit codes 0, 1 and 3010.

\- Resume support with prerequisite validation.



Implement:

1\. Shared configuration and requirements validation.

2\. Distinct REVIEW, PLAN, APPLY and VERIFY modes.

3\. Numeric phase discovery and dependency validation.

4\. Readable plans plus machine-readable manifests.

5\. Approval binding to target/config/scripts/artifact selection.

6\. Direct PowerShell enforcement of the same approval rules.

7\. Target-specific concurrency locking.

8\. Logging, exact exit-code forwarding and reboot handling.

9\. State records and safe resume checks.

10\. Focused mock tests.



Mode rules:

REVIEW:

\- Default.

\- Offline structural/policy checks.

\- No WSL execution, network, elevation or target modification.



PLAN:

\- Resolve intended actions.

\- Permit explicitly requested metadata/artifact acquisition into staging.

\- Do not execute acquired code or mutate the installation target.



APPLY:

\- Require the approved manifest.

\- Refuse unimplemented handlers.

\- Stop on failure or required reboot.



VERIFY:

\- Distinguish offline checks from runtime checks.

\- Require appropriate authorization for starting/accessing a target.



Discover NNN-\*.bat numerically.

Exclude 000 and 999 from automatic execution.

Reject duplicate IDs, missing requirements and unsupported schemas.



Security-critical phases:

010, 020, 030, 040, 050, 070, 080.



Do not allow /skip or /from to bypass them.

Phase 060 is mandatory when selected software depends on it.



/from means resume with validated prerequisites.



Result states must distinguish:

REVIEW\_PASS, RUNTIME\_PASS, APPLIED, NOT\_APPLICABLE,

BLOCKED, FAILED and REBOOT\_REQUIRED.



Preserve 3010 through every wrapper.

Do not continue after it or reboot automatically.

No nested UAC prompts or pauses during orchestration.



A successful review is not successful installation.





12\. PHASE 000 ACCEPTANCE



Use temporary fixtures and mock process adapters.



Test:

\- Invalid/missing/duplicate/unknown configuration.

\- Empty allowlists.

\- Requirement schema and type errors.

\- Phase ordering and duplicate IDs.

\- Unknown/malformed arguments.

\- Unimplemented apply rejection.

\- Direct-entry approval enforcement.

\- Stale approval after relevant changes.

\- Forbidden skips and invalid resume.

\- Concurrent apply rejection.

\- Child failure and unexpected exit codes.

\- Exact propagation of 3010.

\- Interrupted-state handling.

\- Quoting, spaces, Unicode, empty arguments and long argument lists.



Assert that mock/review tests perform no real WSL calls or installations.



Deliver Phase 000 with:

\- Exact changed-file summary.

\- Test outcomes.

\- Remaining unimplemented phase list.

\- Updated handoff.



Do not claim runtime installation readiness from these tests.





13\. FOLLOWING MILESTONES



After Phase 000 acceptance:



010–050:

Implement real preflight, WSL bootstrap, distro provisioning, Linux user

creation, configuration and effective runtime checks.



Handle WSL absent and reboot-required states.

Do not require an already running hypervisor before bootstrap.

Verify actual distro registration and storage location.

Treat unavailable or ambiguous security checks as failure.



060–080:

Install required toolchains.

Acquire verified AI Jail independently.

Enforce explicit launcher policy.

Create configured workspaces and argument-safe launchers.

Test allowed and denied operations with interpretable evidence.



090:

Acquire and install verified OpenCode independently.

Separate managed configuration from writable runtime state.

Perform provider-free smoke tests.

Never fall back to an unjailed executable.



091:

Install pinned TPS Meter through the release-appropriate official mechanism.

Verify registration, loading and idempotence.



092:

Acquire pinned GSD and dependencies.

Audit lifecycle/generation behavior.

Generate into private staging using the official installer.

Validate output and promote with ownership manifests and recovery support.

Test MCP separately if it is part of the approved integration.



Then:

\- Approved fresh-distro acceptance.

\- Approved clean-Windows/WSL-absent acceptance.

\- Final portable installation guide and evidence-based handoff.



A fresh distro test does not replace a clean-Windows bootstrap test.





14\. ACQUISITION, CHANGE SAFETY AND EVIDENCE RULES



For every selected artifact record:

\- Official source and package identity.

\- Exact version/tag/commit where applicable.

\- Platform variant.

\- Download URL.

\- Hash/integrity.

\- Available authenticity/provenance evidence.

\- Dependency/lifecycle decisions.



Do not use curl | bash or floating npx @latest during apply.

Do not disable TLS verification or silently switch mirrors/versions.

Reject unsafe archive paths and links.



Stage → validate → journal → promote → verify → record.



Use atomic promotion where genuinely possible.

Use explicit recovery for multi-file changes.

Do not claim all WSL/Windows operations are automatically reversible.



Never delete a computed path until its resolved ownership and containment

are verified.



Use dummy credentials for tests.

Provider authentication, extra provider domains and model requests require

separate authorization.



Record exact versions/configuration/scripts tested.

Separate:

\- Historical reported results.

\- Source-review findings.

\- Mock test results.

\- Newly reproduced runtime evidence.





15\. AUTHORIZATION AND ENVIRONMENT NOTES



No live installation or production modification is authorized by this

handoff.



An instruction to implement Phase 000 authorizes its normal code changes

and focused tests within permitted workspace boundaries; it does not

authorize provisioning or modifying a real distro.



In the originating session, the project on D: was readable but outside the

default writable workspace. Editing it may require filesystem permission

in a future session.



If a permission boundary blocks an otherwise authorized edit, request only

the necessary access and explain the actual boundary. Do not treat this as

a reason to redesign or abandon the task.





16\. CONTINUATION RULE



First determine whether the user is requesting implementation or further

planning.



If implementation is requested:

\- Inspect current Phase 000 and shared interfaces.

\- Confirm the baseline has not changed.

\- Implement the Phase 000 milestone.

\- Run its focused tests.

\- Report concrete results and remaining work.



Do not repeat the entire research process unless a changed release or

unresolved implementation question requires it.



Do not jump ahead to live installation.

Do not mark the project complete while requested enabled features or

required acceptance gates remain unfinished.

