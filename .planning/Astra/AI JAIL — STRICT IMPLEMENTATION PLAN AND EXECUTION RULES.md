AI JAIL — STRICT IMPLEMENTATION PLAN AND EXECUTION RULES

Research baseline: 4 October 2026



1\. OBJECTIVE AND MEANING OF “FRESH START”



Build a configuration-driven Windows installer that can provision a new

WSL environment and install AI Jail, OpenCode, TPS Meter and GSD from

verified upstream sources.



A fresh installation must work without:

\- An existing AI Jail distribution or Linux user.

\- An existing pilot installation.

\- Previously downloaded binaries, npm caches or node\_modules.

\- Historical staging folders or generated GSD files.

\- A particular Windows drive letter, Windows username or Linux home path.

\- Access to the old installer.

\- Knowledge from a previous conversation.



The installer must create or acquire everything it needs.



The final handoff must also be self-contained: another assistant must

understand the objective, current state, rules and next action without

reading the previous chat.



This document is a plan. It does not authorize live installation,

production changes, distro termination, destructive cleanup or provider

requests.





2\. FIXED SCOPE AND FIRST DELIVERABLE



The implementation sequence is:



A. Make Phase 000 a real, tested orchestration foundation.

B. Implement fresh provisioning and verification in phases 010–080.

C. Implement independent acquisition and installation in 090–092.

D. Run approved disposable-environment acceptance tests.

E. Produce the final installation guide and evidence-based handoff.



The FIRST deliverable is A only.



Do not start changing installation behavior in 010–092 until Phase 000

passes its acceptance checks. Small interface changes needed to connect

existing review scripts to Phase 000 are allowed; they must not introduce

live installation behavior.



Do not implement these within this milestone:

\- A replacement GUI.

\- A different sandbox platform.

\- An OpenCode major-version migration.

\- VS Code integration.

\- nono integration.

\- ComfyUI installation.

\- Automatic migration of an existing production installation.

\- A new general-purpose package manager or orchestration framework.



If an enabled configuration option requires an unimplemented component,

report it explicitly. Never silently change the option or report the

whole requested installation as complete.



In particular, INSTALL\_COMFYUI=1 must remain visible as an outstanding

requirement until its separate implementation is approved and complete.

The historical 90-step ComfyUI procedure must be inventoried before

planning that migration.





3\. WORKING RULES — PREVENT DRIFT AND REPEATED WORK



At the start of implementation:

1\. Identify the supplied project root.

2\. Read applicable repository instructions.

3\. Inventory relevant files once.

4\. Record the current file state and any user changes.

5\. Compare the implementation against this plan.

6\. Start the first unfinished deliverable.



Use the modern installer as the implementation target.

Use legacy files only as behavioral references when available.

Do not edit historical files to make modern checks pass.



Preserve:

\- BAT entry points.

\- Windows PowerShell 5.1 compatibility.

\- Numbered phases.

\- Per-phase requirements.

\- Standalone and orchestrated operation.

\- Per-phase logs.

\- Exit codes 0, 1 and 3010.

\- Safe resume behavior.



Do not recreate the withdrawn 000-plan.ps1 design.

Planning may be implemented inside the shared orchestration engine.



Implement one coherent milestone at a time.

Finish its meaningful tests before advancing.

Do not repeatedly re-review files that have not changed.



Do not produce additional scripts that only print PASS while the promised

operation remains unimplemented.



Do not refactor unrelated code, rename phases cosmetically or change the

technology stack.



Research only questions that affect the current implementation decision.

Stop researching once primary sources and a focused test resolve it.

Record unrelated improvements for later.



If a check fails, diagnose and fix the cause.

Do not weaken the check, broaden permissions or suppress the failure.



Ask the user only for a material scope decision, missing essential input

or an action requiring authorization. Do not ask them to approve routine

implementation details already covered by this plan.





4\. CONFIGURATION CONTRACT



Keep one authoritative parser and schema.



For the existing configuration, support these keys:

\- TARGET\_DRIVE

\- DISTRO

\- BASE\_DISTRO

\- LINUX\_USER

\- MIN\_WSL\_VERSION

\- MIN\_FREE\_GB

\- ALLOW\_HOSTS\_OPENCODE

\- ALLOW\_HOSTS\_COMFYUI

\- ALLOW\_HOSTS\_INSTALL

\- INSTALL\_COMFYUI

\- INSTALL\_OPENCODE

\- INSTALL\_VSCODE

\- ENABLE\_NONO



Rules:

\- Parse config.env as data; never execute or source its contents.

\- Reject duplicate keys, unknown keys and malformed assignments.

\- Validate booleans as exactly 0 or 1.

\- Validate numeric values and compare versions numerically.

\- Reject unsafe distro names, usernames and target paths.

\- Never substitute historical names when a required value is absent.

\- Keep secrets out of config.env.

\- Document encoding, whitespace and comment handling.

\- Test PowerShell 5.1 encoding and argument behavior explicitly.



An empty allowlist is valid and means network access is denied.

Missing an allowlist key is a configuration error.

Do not confuse those two cases.



Parse semicolon-separated hosts as validated hostnames.

Reject URLs, ports, wildcard expressions and shell syntax unless a future

schema explicitly supports them.



Resolve paths from configuration and system discovery.

Read the actual Linux home directory from the account database.

Do not assume /home/<name>.



Use a versioned schema change if new configuration fields become

necessary. Update the parser, examples, requirements and tests together.



Do not import arbitrary config keys into the parent process environment.





5\. PHASE 000 — IMPLEMENTATION CONTRACT



Keep 000-run-all.bat as the Windows front door.

Use PowerShell for parsing, validation, planning and orchestration.

Keep BAT responsible for minimal launching and exact exit-code forwarding.



A small shared PowerShell module is allowed for configuration, process

execution, approvals, logging and state validation.

Avoid duplicated implementations in every phase.



Provide these distinct modes:



REVIEW:

\- Default when no mode is supplied.

\- Offline structural and policy validation.

\- May write its own review report.

\- Must not contact the network, invoke WSL, execute downloaded code,

&#x20; install packages, elevate or change the target.



PLAN:

\- Resolve configuration, phase dependencies and installation actions.

\- May retrieve explicitly requested upstream metadata/artifacts into

&#x20; managed staging.

\- Must not execute acquired code or modify the installation target.

\- Produce a readable plan and a machine-readable manifest.



APPLY:

\- Execute only the approved manifest.

\- Require an implemented apply handler for every selected action.

\- Reject missing, stale or mismatched approval.

\- Stop on failure or required reboot.



VERIFY:

\- Run the checks explicitly listed in the selected verification plan.

\- Distinguish offline checks from checks that start or access a distro.

\- Require appropriate target authorization for runtime verification.



Normalize existing /review and --review aliases where needed.

Reject unknown options, missing values and incompatible combinations.

Do not silently ignore extra arguments.



Preserve /from and /skip compatibility, with the restrictions below.

Document the exact final syntax once, then test BAT and PowerShell entry

points against the same contract.





6\. DISCOVERY, DEPENDENCIES, RESUME AND RESULTS



Discover NNN-\*.bat files in the installer directory.

Sort by numeric phase ID.

Exclude 000 and 999 from automatic phase execution.



For each discovered phase:

\- Require exactly one matching phase entry point.

\- Require a valid requirements document.

\- Check that the declared ID matches the filename.

\- Reject unsupported schemas and incorrectly typed values.

\- Declare dependencies and supported execution modes.

\- Include the relevant files in the execution manifest.



Discovery is not permission to execute an unexpected new phase.

An added or changed phase invalidates the affected approved plan.



Security-critical phases:

010, 020, 030, 040, 050, 070 and 080.



They cannot be bypassed with /skip or /from.

Phase 060 is also mandatory whenever selected software depends on it.

Feature-disabled phases may be excluded only through validated dependency

resolution, with an explicit reason in the report.



/from means “resume with prerequisites validated.”

It must not mean “ignore everything before this number.”



A resumable record must identify:

\- Configuration hash.

\- Installer and requirements hashes.

\- Approved artifact lock.

\- Target distro identity and storage location.

\- Completed operations and their evidence.

\- Pending reboot or interrupted transaction.



Recheck current target identity and security prerequisites on resume.

A previous PASS does not replace fresh runtime verification when state

could have changed.



Use distinct result states:

\- REVIEW\_PASS

\- RUNTIME\_PASS

\- APPLIED

\- NOT\_APPLICABLE

\- BLOCKED

\- FAILED

\- REBOOT\_REQUIRED



Do not collapse them into a generic PASS.



Process exit codes:

\- 0: the requested operation completed successfully.

\- 1: failure, invalid input, blocked execution or unexpected child result.

\- 3010: reboot required; stop immediately and preserve resume information.



A review command may succeed while reporting apply as unavailable.

That must never be presented as successful installation.



Preserve 3010 through every wrapper.

No orchestrated pauses, nested UAC prompts or automatic reboot.

Standalone prompts must be deliberate and documented.





7\. APPROVAL, TARGET PROTECTION AND CHANGE JOURNAL



Every apply plan must show:

\- Target distro name and resolved storage path.

\- Windows/WSL changes.

\- Files and directories created or changed.

\- Selected versions and acquisition sources.

\- Required network destinations.

\- Required privilege.

\- Any target termination or reboot.

\- Rollback limits.

\- Unimplemented or excluded requested features.



Bind approval to the exact plan, target, configuration, relevant script

hashes and artifact lock.



A hash identifies the plan; it is not proof of human approval.

The installer must record an actual confirmation through its controlled

entry point.



Direct PowerShell apply entry points must enforce the same checks as BAT.

Environment variables such as CI, logging flags or “yes” flags must not

bypass authorization or security gates.



Use one target-specific execution lock to prevent concurrent apply runs.

Record intent before mutations and record results afterward.



Protect existing state:

\- Do not adopt an existing same-name distro automatically.

\- Do not overwrite an existing installation directory.

\- Do not alter other distributions.

\- Do not change the default distro.

\- Do not edit global .wslconfig.

\- Do not run global wsl --shutdown.

\- Do not unregister a distro automatically.

\- Do not terminate the selected distro unless that action is included in

&#x20; the explicitly approved plan.



Existing-target migration is a separate operation and scope.



Separate approvals may cover:

1\. Windows/WSL bootstrap.

2\. Provisioning and testing a named disposable target.

3\. Production installation.

4\. Provider authentication and live requests.



Do not repeatedly ask within an already approved scope.

If a material plan change occurs, show the change before proceeding.



A clean machine may need bootstrap before Linux package resolution is

possible. Use staged plans instead of pretending every later detail was

known before WSL existed.





8\. UPSTREAM ACQUISITION AND VERSION POLICY



Research snapshot — candidates, not approved compatibility results:

\- AI Jail: v2.6.3

\- OpenCode: v1.18.34

\- TPS Meter: v0.4.0

\- GSD Core: v1.15.0



At implementation time, resolve the latest compatible stable releases.

Do not permanently pin historical versions merely because old tests used

them. Do not follow moving latest tags during apply.



For each selected artifact record:

\- Official repository and package identity.

\- Exact release/version.

\- Tag and resolved commit where available.

\- Platform, architecture and binary variant.

\- Exact download URL.

\- SHA-256 or package integrity value.

\- Available signature/provenance evidence.

\- Dependencies and lifecycle scripts.

\- Reviewed installation procedure.



Distinguish checksum matching from publisher authentication.

Do not invent signature verification when the publisher supplies none.

Document the evidence actually available.



Download to private staging.

Verify before extraction or execution.

Reject archive path traversal and unsafe link destinations.

Use bounded timeouts and limited retries.

Never disable TLS verification.



Do not use:

\- curl | bash.

\- Unreviewed remote PowerShell execution.

\- Floating npx @latest during apply.

\- An arbitrary mirror after an official download fails.

\- Silent fallback from a failed release to another version.



For npm dependencies:

\- Resolve and lock the complete selected dependency graph.

\- Inspect lifecycle behavior.

\- Suppress lifecycle execution during initial acquisition.

\- Run only reviewed, necessary installation/build steps.

\- Treat optional dependencies explicitly.



A changed dependency graph, artifact, major version or required network

scope must be reflected in the plan before execution.





9\. PHASES 010–050 — FRESH WINDOWS AND WSL PROVISIONING



010 — Preflight

\- Detect Windows build, architecture, available disk space, administrator

&#x20; capability and virtualization prerequisites.

\- Distinguish WSL absent, installed, outdated and reboot-pending states.

\- Do not require an already running hypervisor as proof that a clean

&#x20; Windows machine is eligible for bootstrap.

\- Report unsupported hardware/builds clearly.

\- Perform connectivity checks only in a mode that permits network access.



020 — WSL bootstrap

\- Implement actual installation/update using supported Microsoft paths.

\- Install WSL without an unwanted default distribution.

\- Check required command capabilities as well as the version.

\- Never update WSL merely because a newer version exists if the approved

&#x20; plan does not require that update.

\- Return 3010 when necessary and stop before provisioning continues.



030 — New distribution

\- Confirm that the configured name and resolved storage location are free.

\- Obtain the configured Ubuntu release through a verified official path.

\- Use the installed WSL version’s supported name/location options.

\- If those options are unavailable, stop or use a separately planned,

&#x20; verified import procedure; do not improvise.

\- Verify the registered distro’s actual BasePath and WSL version.

\- Record its identity for every later action.



040 — User and distro configuration

\- Create the configured Linux user without depending on interactive OOBE.

\- Do not introduce an embedded password or passwordless sudo.

\- Apply necessary administrative actions through the Windows-controlled

&#x20; provisioning process.

\- Create /etc/wsl.conf when absent.

\- Preserve unrelated existing content when handling installer-owned state.

\- Configure automount disabled, fstab automount disabled, Windows interop

&#x20; disabled, Windows PATH injection disabled and the intended default user.

\- Stage, validate and replace configuration safely.

\- Restart only the approved target when necessary.



050 — Effective runtime checks

\- Verify the effective non-root user and its actual home.

\- Inspect the real mount inventory, including custom mount locations.

\- Check for Windows drive exposure and DrvFs-backed mounts.

\- Test Windows executable reachability and Windows PATH injection.

\- Verify checks ran successfully and produced interpretable output.



Do not treat:

\- Missing mountpoint/findmnt as proof of isolation.

\- An empty result from a failed command as success.

\- Any nonzero status as the expected denial.

\- The presence of wsl.conf as proof of effective settings.

\- Offline review as runtime proof.



Stop before workload installation if required runtime checks fail.



Describe this as enforcement of the configured WSL restrictions.

Do not describe it as proof that WSL securely contains hostile code.





10\. PHASES 060–080 — TOOLCHAIN, AI JAIL AND WORKSPACES



060 — Toolchain

\- Install missing prerequisites; do not only check for their existence.

\- Use trusted distribution packages or verified upstream artifacts.

\- Record the selected package versions and installation actions.

\- Validate bubblewrap, git, curl, jq, Python, pip, compiler/pkg-config and

&#x20; the Node/npm versions required by the selected application stack.

\- Honor the declared Rust requirements when Rust is required.

\- Prefer verified AI Jail release binaries where supported; do not add a

&#x20; source build merely to increase scope.

\- For the researched GSD candidate, require Node >=24 and npm >=10.

\- Verify unprivileged namespace operation as the intended Linux user.

\- Do not weaken system-wide restrictions to make the test pass.

\- Keep GPU checks conditional on the selected feature profile.



070 — AI Jail

\- Acquire and verify the selected release independently.

\- Confirm the installed executable and bubblewrap ownership/permissions.

\- Never install a build with test-only security-bypass features enabled.

\- Verify actual CLI behavior for the locked release.



The launcher policy must explicitly control:

\- Project configuration loading and config saving.

\- Private home behavior.

\- Agent-state mounts and credential inheritance.

\- Toolchain caches and their automatic network additions.

\- mise integration.

\- Environment inheritance.

\- Update checks.

\- Network access.

\- Filesystem mappings.

\- Landlock/seccomp and other required protections.



For the researched version, review and use the supported explicit opt-outs

such as --no-agent-state, --no-toolchains, --no-mise, --no-inherit-env and

\--no-update-check where required by this policy.



Do not assume --clean alone disables every default exposure.



Empty allowlist:

\- Explicit network denial.

\- No automatic registry hosts.



Nonempty allowlist:

\- Filtered access only.

\- No unrestricted network flag.

\- Show that upstream hostname matching also includes subdomains.

\- Do not claim exact-host-only enforcement unless independently provided

&#x20; and tested.



Check both allowed operations and denied operations.

A network test passes only when the reason for denial is established;

a DNS failure, missing curl or disconnected machine is not sufficient.



080 — Workspaces and launchers

\- Derive all paths from configuration and resolved Linux identity.

\- Create only installer-owned directories.

\- Never reset an existing Git repository.

\- Map only approved workspace and runtime paths.

\- Keep credentials, application configuration, caches and editable project

&#x20; files deliberately scoped.

\- Keep installer state and approval records inaccessible to workloads.

\- Use validated byte-preserving transport for scripts/configuration.

\- Do not depend on Windows drive mounts or Windows interop.



Preserve the launcher interface:

\- No arguments: interactive Bash.

\- -c COMMAND: Bash command behavior with documented argument handling.

\- -- COMMAND ARGUMENTS: preserve the argument vector.



Test spaces, quotes, Unicode, empty arguments and more than nine arguments.



Make terminal passthrough an explicit reviewed choice for interactive use.

Do not silently lose required TUI behavior.



Do not fall back to an unjailed Windows OpenCode executable if startup fails.





11\. PHASE 090 — OPENCODE



Acquire OpenCode from its official release/package sources.

Do not copy a pilot binary.



Select the correct Linux architecture, libc and CPU-compatible variant.

Record why the chosen variant is appropriate.



Install into a versioned, installer-managed location.

Verify artifact integrity, executable version and a provider-free smoke

test before promotion.



Separate:

\- Application binaries and managed configuration.

\- Writable cache/session/state directories.

\- Editable projects.

\- Credentials.



Inspect the selected release’s configuration precedence and discovery.

OPENCODE\_CONFIG alone must not be treated as a policy boundary.



Account for:

\- Project configuration.

\- Environment overrides.

\- Automatically discovered plugins.

\- Automatic dependency installation.

\- Update behavior.



Sanitize inherited configuration variables and restrict project overrides

where supported. Verify the effective result.



Do not enable providers, add provider domains, import credentials or make

model calls merely to prove that OpenCode launches.





12\. PHASE 091 — TPS METER



Use the official installation path for the selected OpenCode generation.



For the researched OpenCode v1 candidate, the supported path is:

opencode plug opencode-tps-meter@<locked-version> --global



Before execution:

\- Inspect the exact installer behavior.

\- Identify all config, cache and package locations it will touch.

\- Place those locations inside the approved managed environment.

\- Verify package identity, integrity, exports and compatibility.



Do not assume changing XDG\_CONFIG\_HOME also redirects every cache.



Do not fabricate OpenCode’s internal package/cache structure.

Do not migrate to v2 instructions while installing v1.



After installation:

\- Parse registration as structured data.

\- Check the expected server/TUI registrations for that release.

\- Check the resolved package version.

\- Verify the plugin loads without a provider request.

\- Confirm a second install is idempotent.



Do not use substring searches over serialized JSON as proof of correct

registration.





13\. PHASE 092 — GSD



Acquire the exact @opengsd/gsd-core package and its locked dependencies.

Do not use historical staging directories or a previous generated output.



Audit:

\- Package lifecycle scripts.

\- The official installer entry point.

\- Child processes and network actions.

\- Files written outside the requested configuration directory.

\- Optional native dependencies.

\- Runtime hooks and MCP behavior.



Generate OpenCode integration using the verified official installer:

\- Select OpenCode explicitly.

\- Select the intended installation scope explicitly.

\- Redirect output into private staging using the supported config-dir

&#x20; mechanism.

\- Isolate HOME/XDG/cache paths used during generation.



Do not copy raw Claude-oriented agents or commands into OpenCode.



For the researched release, verify the generated commands, agents, skills

and native plugin. Account for its CommonJS package marker and effects on

other plugins. Preserve unrelated user files.



Do not assume a fixed command count such as 72.

Derive the expected inventory from the locked release and chosen profile.



If MCP integration is required:

\- Use the package’s actual MCP entry point.

\- Verify the required runtime files/dependencies are present.

\- Test initialization and tool discovery without a provider call.

\- Do not confuse the generated OpenCode plugin with the MCP server.



Reject generated absolute references to temporary staging paths.



Promote only after validation.

Retain a manifest of owned files and hashes.

A rerun must not duplicate commands, corrupt registration or overwrite

unrelated configuration.





14\. TRANSACTIONS, IDEMPOTENCE AND CLEANUP



For application/configuration changes:

1\. Create private staging.

2\. Acquire or generate content.

3\. Verify hashes, structure, ownership and behavior.

4\. Record the intended changes.

5\. Promote validated content.

6\. Verify the installed result.

7\. Record completion.



Prefer a single versioned directory and controlled pointer switch where

that makes promotion atomic.



Where multiple files cannot be changed atomically, use a journal and

explicit recovery procedure. Do not claim atomicity for several unrelated

renames.



Never label the whole installation reversible because one wrapper can be

restored.



WSL installation, Windows feature changes and some package operations have

different rollback limits. Record them separately.



If interrupted:

\- Detect incomplete staging or promotion.

\- Recover using the journal.

\- Never guess that a partial installation succeeded.



Delete only paths proved to belong to the current operation.

Validate resolved paths, including symlinks/reparse points, before cleanup.

Do not use broad recursive deletion or cross-shell path reconstruction.



Leave destructive recovery, including distro unregister, as an explicit

manual operation requiring separate authorization.





15\. REQUIRED TESTS AND ACCEPTANCE GATES



Gate A — Phase 000

Use mock execution adapters and temporary fixtures.



Cover:

\- Missing/duplicate/unknown configuration.

\- Empty allowlists.

\- Invalid booleans and version comparisons.

\- Phase ordering and duplicate IDs.

\- Missing/unsupported requirements.

\- Unknown arguments.

\- Unimplemented apply handlers.

\- Direct PowerShell approval enforcement.

\- Changed configuration/scripts/artifacts after approval.

\- /from prerequisite validation.

\- Forbidden skips.

\- Concurrent apply rejection.

\- Child failure and unexpected exit codes.

\- Exact propagation of 3010.

\- Interrupted-run recovery.

\- Paths and arguments containing special characters.



Assert that review/mock execution makes no real WSL calls, performs no

installation and writes only to the test/report locations.



Gate A passes when orchestration behavior is implemented and tested.

It does not certify any live installer phase.



Gate B — Fresh disposable distro

Requires explicit approval for the named disposable target.



Start without pilot folders, npm caches or preinstalled application tools.

Verify provisioning, effective restrictions, installation, launchers,

OpenCode, TPS Meter, GSD and rerun behavior.



Use dummy credentials and harmless test content.

Keep provider calls disabled.



Gate C — Clean Windows bootstrap

Use an approved clean Windows test machine or VM with WSL initially absent.

Verify bootstrap, reboot/resume and subsequent provisioning.



A new distro on a machine with WSL already installed does not satisfy

this gate.



Gate D — Failure and policy tests

Verify:

\- Tampered artifacts are rejected.

\- Offline/unavailable sources produce clear failure.

\- Existing target collisions are refused.

\- Missing security capabilities block execution.

\- Empty allowlists deny network access.

\- Required allowed operations succeed.

\- Unapproved mounts/configuration/credentials are absent.

\- Interrupted promotion recovers correctly.

\- Unrelated distro and user files remain unchanged.



Each result must identify the script/config/artifact versions tested.



Run focused checks after changes.

Repeat broader tests only when changed behavior or a failure justifies it.

Do not repeatedly run unchanged successful suites.





16\. COMPLETION CLAIMS AND HANDOFF



Maintain a small phase matrix showing:

\- Review implemented.

\- Apply implemented.

\- Offline tests passed.

\- Runtime tests passed.

\- Fresh-Windows tests passed.

\- Remaining blocker.



Never mark an untested field complete.



Use these distinct milestones:

\- Phase 000 complete.

\- Fresh-distro installation verified.

\- Clean-Windows installation verified.

\- Selected feature profile complete.



If ComfyUI or another requested enabled feature remains unimplemented,

do not claim the full requested installation is complete.



The final handoff must contain:

\- Project purpose and supported installation profile.

\- How to locate the project root.

\- Configuration reference and a portable example.

\- Exact entry-point commands.

\- Current implementation status.

\- Selected versions, source URLs and integrity records.

\- Approval boundaries.

\- Runtime policy and its known limits.

\- Test commands, outcomes and evidence locations.

\- Resume and recovery instructions.

\- Known limitations and unfinished work.

\- The single next action.



Do not write “as discussed,” “same as before” or references that require

the previous chat.



Historical paths may appear only as historical context, never as required

installation inputs.



Separate reported historical results from newly reproduced evidence.

Do not describe downloaded-source inspection as runtime testing.





17\. FIRST IMPLEMENTATION ACTION AFTER AUTHORIZATION



Inspect the current Phase 000 files, configuration loader and wrapper

interfaces once.



Then implement:

1\. The authoritative configuration/requirements validation.

2\. The mode and result contracts.

3\. Phase discovery and dependency enforcement.

4\. Plan manifests and direct-entry approval checks.

5\. Exit-code/logging/resume behavior.

6\. The mock test suite.



Preserve existing review functionality while connecting it to the shared

contracts.



Deliver:

\- Working Phase 000.

\- Focused test results.

\- Exact file-change summary.

\- Explicit list of phases still lacking apply/runtime implementation.

\- A short updated handoff.



Stop at that milestone boundary unless implementation of the following

milestone has also been authorized.



Do not perform a live installation as an implicit test.





18\. AUTHORITATIVE SOURCES TO RECHECK WHEN SELECTING RELEASES



Project requirements and history:

https://github.com/IlCretinoDaMessina/ai-jail



AI Jail:

https://github.com/akitaonrails/ai-jail

Review releases, CLI implementation, security documentation and release

verification instructions.



OpenCode:

https://github.com/anomalyco/opencode

Review the selected release’s installer, plugin installation code,

configuration precedence and plugin discovery.



TPS Meter:

https://github.com/ChiR24/opencode-tps-meter

Review the selected release’s package exports, compatibility requirements

and generation-specific installation procedure.



GSD Core:

https://github.com/open-gsd/gsd-core

Review package.json, bin/install.js, runtime installation documentation

and the MCP entry point when required.



WSL:

https://github.com/microsoft/WSL

https://learn.microsoft.com/en-us/windows/wsl/basic-commands

https://learn.microsoft.com/en-us/windows/wsl/wsl-config



Bubblewrap:

https://github.com/containers/bubblewrap



Use documentation and source corresponding to the selected release.

A repository’s moving default branch is not automatically the behavior

of its stable published package.

