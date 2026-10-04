\# AI JAIL — COMPLETE MODERN INSTALLATION HANDOFF



\*\*Project:\*\* AI Jail Windows/WSL installer modernization  

\*\*Status:\*\* Offline review layer completed for Phases 000–092. Actual fresh-machine installation implementation remains incomplete.  

\*\*Last completed verification:\*\* Phase 000 discovered all 11 phases, validated their requirements, and exited successfully.  

\*\*Production installation:\*\* NOT AUTHORIZED.



\---



\# 1. YOUR ROLE AND THE OBJECTIVE



You are continuing the modernization of an existing project called \*\*AI Jail\*\*.



Your job is to help complete a reproducible, secure, fresh-machine installer for Windows using BAT, PowerShell, WSL and Linux components.



The objective is NOT to continue creating review-only scaffolding indefinitely.



The objective is to finish a real installation system that can eventually:



1\. Validate Windows prerequisites.

2\. Install or configure WSL when needed.

3\. Provision a dedicated Linux distribution.

4\. Apply secure WSL configuration.

5\. Establish and verify mandatory isolation.

6\. Install the required Linux toolchain.

7\. Install and verify AI Jail.

8\. Configure isolated sandbox projects and launchers.

9\. Independently acquire, install and verify approved OpenCode.

10\. Install approved OpenCode plugins using their official methods.

11\. Independently acquire, generate, install and verify GSD Core and its OpenCode integration.

12\. Correctly orchestrate all phases with explicit approval, logging, idempotency, failure propagation and rollback.



All of this must ultimately work on a clean machine, without depending on historical experimental files or temporary staging directories.



\*\*Important:\*\* The existing eleven-phase modernization is not useless or broken. Its current implementations primarily provide working requirements and offline reviews. Preserve that work and extend it with actual functionality.



Do not restart the modernization from scratch.



\---



\# 2. PRIMARY PROJECT PATHS



Original project:



`D:\\.coding\\.ai-jail\\`



Independent modernization directory:



`D:\\.coding\\.ai-jail\\modern-install\\`



Existing production/experimental WSL distribution:



`ai-jail`



Existing Linux user:



`aijail`



Existing registered WSL disk:



`D:\\ai-jail\\wsl\\ext4.vhdx`



Existing full WSL baseline backup:



`D:\\.coding\\.ai-jail\\.bkps\\ai-jail-baseline-backup.tar`



The backup was previously exported and verified, approximately \*\*6,645 MB\*\*.



Original files at the project root must remain unchanged.



The complete existing `ai-jail` distribution, OpenCode/GSD/TPS pilot, Linux projects, configuration, secrets and experimental installations must be preserved.



\*\*Do not execute production installation against this existing distro without a separate, explicit approval.\*\*



Do not call `wsl --shutdown` or terminate the distribution as an incidental development step.



\---



\# 3. GITHUB REFERENCES



The project repository is:



https://github.com/IlCretinoDaMessina/ai-jail



Previously supplied project planning references:



\- https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/REQUIREMENTS-004-ADDENDUM.md

\- https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/STATUS-004.md

\- https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/ROADMAP-004.md



These provide additional project history and context.



Do not assume that GitHub's main branch necessarily contains the user's latest local `modern-install` files. The user has created those files locally during this conversation.



Ask for the actual local contents when editing a file, rather than guessing.



\---



\# 4. CONFIGURATION AND INSTALLATION CONVENTIONS



The modernization directory contains its own copies of:



`\_common.bat`



`config.env`



The configuration has an exact documented schema of 13 keys:



```env

TARGET\_DRIVE=

DISTRO=

BASE\_DISTRO=

LINUX\_USER=

MIN\_WSL\_VERSION=

MIN\_FREE\_GB=

ALLOW\_HOSTS\_OPENCODE=

ALLOW\_HOSTS\_COMFYUI=

ALLOW\_HOSTS\_INSTALL=

INSTALL\_COMFYUI=

INSTALL\_OPENCODE=

INSTALL\_VSCODE=

ENABLE\_NONO=

```



Known target values include:



```env

TARGET\_DRIVE=D:

DISTRO=ai-jail

BASE\_DISTRO=Ubuntu-24.04

LINUX\_USER=aijail

MIN\_WSL\_VERSION=2.4.4

INSTALL\_OPENCODE=1

INSTALL\_VSCODE=0

ENABLE\_NONO=0

```



The currently tested network allowlists contained three entries each. Exact values should always be read from the user's actual `config.env`.



The Phase 080 review previously generated these allow-host entries:



OpenCode:



\- registry.npmjs.org

\- github.com

\- objects.githubusercontent.com



ComfyUI:



\- registry.npmjs.org

\- github.com

\- huggingface.co



These values describe the reviewed configuration, NOT automatically approved production runtime network access.



The three host lists have separate purposes. Installation hosts must not be silently carried into production sandbox runtime allowlists.



For Phase 080, an explicitly empty allowlist means `--no-network`; a missing list is invalid.



All configuration parsing should reject missing, duplicate, malformed and unknown keys as required by its phase contract.



\---



\# 5. CURRENT MODERN-INSTALL DIRECTORY



The user has created the following files in:



`D:\\.coding\\.ai-jail\\modern-install\\`



\## Shared files



```text

\_common.bat

config.env

```



\## Phase 000



```text

000-requirements.json

000-run-all.bat

000-review.ps1

```



\## Phase 010



```text

010-requirements.json

010-preflight.bat

010-preflight.ps1

```



\## Phase 020



```text

020-requirements.json

020-wsl-check.bat

020-wsl-check.ps1

```



\## Phase 030



```text

030-requirements.json

030-create-distro.bat

030-create-distro.ps1

```



\## Phase 040



```text

040-requirements.json

040-wsl-conf.bat

040-wsl-conf.ps1

```



\## Phase 050



```text

050-requirements.json

050-isolation-gate.bat

050-isolation-gate.ps1

```



\## Phase 060



```text

060-requirements.json

060-base-toolchain.bat

060-base-toolchain.ps1

```



\## Phase 070



```text

070-requirements.json

070-ai-jail.bat

070-ai-jail.ps1

```



\## Phase 080



```text

080-requirements.json

080-setup-sandboxes.bat

080-setup-sandboxes.ps1

```



\## Phase 090



```text

090-requirements.json

090-setup-opencode.bat

090-setup-opencode.ps1

```



\## Phase 091



```text

091-requirements.json

091-setup-opencode-plugins.bat

091-setup-opencode-plugins.ps1

```



\## Phase 092



```text

092-requirements.json

092-check-gsd-source.bat

092-check-gsd-source.ps1

```



\*\*One additional proposed file:\*\*



`000-plan.ps1`



This file was proposed in the last part of the conversation, but the user did NOT confirm saving it.



The assistant subsequently acknowledged that creating yet another intermediate review/planning file was unnecessary and explicitly told the user they did not need to create it.



Therefore:



\- Do not assume `000-plan.ps1` exists.

\- Do not make further work depend on it.

\- If it happens to exist, leave it unused until an actual implementation design calls for it.



\---



\# 6. WORK COMPLETED AND VERIFIED



\## Phase 000 — Orchestrator



Current behaviour:



\- Reviews the modernization directory.

\- Reads `000-requirements.json`.

\- Validates configuration.

\- Dynamically discovers `NNN-\*.bat` files, excluding 000 and 999.

\- Finds each phase's matching requirements JSON.

\- Validates its schema and phase identity.

\- Does not execute discovered phases.

\- Does not invoke WSL or perform downloads.



\*\*Latest result: PASS.\*\*



Actual final output included:



```text

010-preflight.bat: REQUIREMENTS PRESENT

020-wsl-check.bat: REQUIREMENTS PRESENT

030-create-distro.bat: REQUIREMENTS PRESENT

040-wsl-conf.bat: REQUIREMENTS PRESENT

050-isolation-gate.bat: REQUIREMENTS PRESENT

060-base-toolchain.bat: REQUIREMENTS PRESENT

070-ai-jail.bat: REQUIREMENTS PRESENT

080-setup-sandboxes.bat: REQUIREMENTS PRESENT

090-setup-opencode.bat: REQUIREMENTS PRESENT

091-setup-opencode-plugins.bat: REQUIREMENTS PRESENT

092-check-gsd-source.bat: REQUIREMENTS PRESENT



PHASE 000 REVIEW: PASS



Installation phases discovered: 11

Requirements validation: PASS



INSTALLATION: DISABLED

PRODUCTION APPLY: DISABLED

WSL INVOCATION: NONE

DOWNLOADS: NONE

SYSTEM MODIFICATIONS: NONE



PHASE 000 EXIT CODE: 0

```



\## Phase 010 — Preflight



Standalone check passed.



Checks prerequisites including administrator context, configuration, virtualization, available disk space and network conditions.



Previously reported disk availability was approximately 718 GB.



\## Phase 020 — WSL Check



Standalone check passed.



Actual WSL version previously reported:



`2.7.14.0`



Required minimum:



`2.4.4`



A PowerShell issue was corrected because `Get-Command wsl.exe` can return two executable matches. The implementation now selects the first result where required.



\## Phase 030 — Distribution Check



Standalone check passed.



Uses the WSL registry and `wsl --list --verbose` to inspect the existing distribution without starting it.



Verified:



\- Distribution: `ai-jail`

\- WSL version: 2

\- Registered disk: `D:\\ai-jail\\wsl\\ext4.vhdx`



A PowerShell syntax issue was corrected: `-cjoin` is not a valid PowerShell operator; use `-join`.



\## Phase 040 — WSL Configuration



Offline review passed.



Actual Linux configuration has NOT been applied or independently runtime-verified by the modernized implementation.



\## Phase 050 — Isolation Gate



Offline policy review passed.



\*\*Actual runtime isolation gate is NOT SATISFIED.\*\*



This is a critical distinction throughout the project.



Never allow an offline review PASS to stand in for successful runtime security verification.



\## Phase 060 — Base Toolchain



Offline review passed.



The modernized requirements include an inventory of 11 required tool commands and approved stable-version/integrity policies.



Actual toolchain installation and runtime verification remain incomplete.



\## Phase 070 — AI Jail



Offline review passed.



Requirements cover the AI Jail sandbox engine and associated security checks.



The historical experimental baseline used AI Jail `2.2.0`.



Actual fresh installation and runtime sandbox verification remain incomplete.



\## Phase 080 — Sandbox Workspace and Launchers



The complete modernization triplet exists:



```text

080-requirements.json

080-setup-sandboxes.bat

080-setup-sandboxes.ps1

```



Standalone review passed all six sections.



The PowerShell companion:



\- Validates exact configuration keys.

\- Validates DNS allowlists.

\- Generates three proposed launchers in memory.

\- Validates required launcher flags.

\- Computes SHA-256 hashes.

\- Reviews project, secrets and transaction requirements.

\- Explicitly rejects apply.

\- Does not execute WSL.

\- Does not modify Linux projects, files or secrets.



Three proposed launchers:



```text

jail-shell

jail-opencode

jail-comfyui

```



The intended launchers use the reviewed Option C parser, which supports:



```text

launcher

launcher -c COMMAND \[ARG...]

launcher -- COMMAND \[ARG...]

```



Important AI Jail flags include:



```text

\--clean

\--no-save-config

\--private-home

\--hide-dotdir .secrets

\--rw-map

\--terminal-passthrough

\--exec

```



Scratch uses `--no-network`.



OpenCode and ComfyUI use their distinct allow-host lists and separate environment files:



```text

/home/aijail/.secrets/opencode.env

/home/aijail/.secrets/comfyui.env

```



Requirements:



\- UTF-8 without BOM.

\- LF line endings.

\- Wrapper permissions `0700`.

\- Secret directory permissions `0700`.

\- Secret file permissions `0600`.

\- Preserve existing secret bytes.

\- Preserve existing Git repositories and project data.

\- Reject managed-path symlinks.

\- Private staging.

\- Hash and syntax verification.

\- Transactional promotion and rollback.



Actual executable installation payload has NOT yet been implemented.



The original project also contains:



`080-review-gates.md`



This document contains further acceptance tests and should be consulted before implementing actual installation.



\## Phase 090 — OpenCode



The following modernized files exist:



```text

090-requirements.json

090-setup-opencode.bat

090-setup-opencode.ps1

```



Standalone offline review passed all seven sections.



Historical experimental baseline:



```text

OpenCode: 1.18.34

```



Historical archive SHA-256:



```text

24b0d458d21ef548b2752166303defcf7f4945b049fb4876ab78dfaf86d81b27

```



Historical extracted binary SHA-256:



```text

9ca0b9953d49997601655e54f846a3efa464f237e47c6f1b04716d0f2e64c4c2

```



Official repository:



https://github.com/anomalyco/opencode



The existing historical manifest is:



`D:\\.coding\\.ai-jail\\090-tool-manifest.json`



The original acceptance document is:



`D:\\.coding\\.ai-jail\\090-review-gates.md`



Its approval gates A1–A12 must remain relevant during implementation.



The historical OpenCode pilot was experimentally verified. It was not approved as a general production installation source.



The modern installation target is:



`LATEST\_APPROVED\_COMPATIBLE\_STABLE`



The version must be resolved, compatibility-checked, integrity-verified, explicitly approved and recorded.



Do not automatically permanently pin the installer to OpenCode 1.18.34.



Modern OpenCode installation is NOT implemented.



\## Phase 091 — OpenCode TPS Meter Plugin



Modernized files:



```text

091-requirements.json

091-setup-opencode-plugins.bat

091-setup-opencode-plugins.ps1

```



Standalone offline review passed all seven sections.



Historical experimental plugin:



```text

opencode-tps-meter@0.4.0

```



Official repository:



https://github.com/ChiR24/opencode-tps-meter



Historical official installation method:



```bash

opencode plug opencode-tps-meter@0.4.0 --global

```



The eventual installer must retain the plugin author's official installation method, substituting an explicitly approved compatible version.



Do not manually fabricate `package.json` or populate the OpenCode plugin cache yourself.



The original implementation verified package metadata inside the actual `node\_modules` location and registration in both:



```text

opencode.json

tui.json

```



The modernized requirements demand exact structured JSON validation rather than a serialized substring search.



Sandbox access to the installed plugin cache must be narrowly scoped and reviewed.



Do not broadly expose the host cache.



Modern TPS Meter installation is NOT implemented.



\## Phase 092 — GSD Core



Modernized files:



```text

092-requirements.json

092-check-gsd-source.bat

092-check-gsd-source.ps1

```



Standalone offline review passed all eight sections.



The original project contains only one file beginning with `092`:



`D:\\.coding\\.ai-jail\\092-check-gsd-source.bat`



Despite its name, that original file is an executable offline pilot installer and migration script—not merely a source checker.



Historical experimental versions:



```text

GSD Core: 1.15.0

OpenCode: 1.18.34

```



Official GSD repository:



https://github.com/open-gsd/gsd-core



Package:



`@opengsd/gsd-core`



Historical original GSD configuration SHA-256:



```text

a2f07f6d83252ccd0cc1417410e04705b6234765130b392c1e18dfaf298ecbb1

```



Historical generated GSD commands:



`72`



The number 72 belongs to the historical experiment and must NOT become a permanent count requirement for all future GSD versions.



The original installer copied an experimental generated OpenCode integration and a previously prepared offline `node\_modules` tree into a versioned pilot directory, configured the local GSD MCP server, and corrected old paths in generated command Markdown.



Its successful experimental pilot does NOT replace the source, dependency, generation and lifecycle audits required for production.



Modern GSD installation is NOT implemented.



\---



\# 7. IMPORTANT: FIX THE HISTORICAL STAGING DEPENDENCIES



The user explicitly asked when the fixed staging and generation identifiers would be corrected.



This is a priority implementation requirement, not something to defer indefinitely.



The original Phase 092 uses paths such as:



```text

/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548/output/opencode

```



and:



```text

/home/aijail/projects/opencode-work/.phase090-staging/gsd-lock-5c0a1640/offline-confirm-4231a6b0/node\_modules

```



Its pilot installation is rooted at:



```text

/home/aijail/phase092-pilot

```



The modern installer MUST NOT depend on these directories.



Instead, implement reproducible acquisition and staging:



1\. Resolve the approved compatible GSD version and exact source commit.

2\. Acquire artifacts independently from reviewed official sources.

3\. Validate integrity-bearing dependency resolution and lockfile.

4\. Audit lifecycle scripts, installer transformations and generation process.

5\. Create a dynamically generated, private, transaction-owned staging directory.

6\. Build or generate the GSD OpenCode integration using the audited method.

7\. Verify the complete generated tree and dependency inventory.

8\. Verify MCP configuration, command paths and file hashes.

9\. Promote the complete installation transactionally.

10\. Record the actual installed version, provenance, hashes and approval reference.

11\. Support idempotent reruns, conflict rejection and tested rollback.



Existing experimental directories are historical reference material only.



Do not copy them as installation sources.



\---



\# 8. HISTORICAL OPENCODE/GSD/TPS PILOT



The original experimental setup includes paths resembling:



```text

/home/aijail/phase092-pilot/opencode/1.18.34/opencode

/home/aijail/phase092-pilot/gsd/1.15.0/

```



The original OpenCode staging binary was:



```text

/home/aijail/projects/opencode-work/.phase090-staging/opencode

```



The historical isolated runtime was:



```text

/home/aijail/projects/opencode-work/.phase092-runtime/opencode

```



The pilot had experimental success including:



\- Verified historical OpenCode artifact and binary hashes.

\- Working OpenCode TUI.

\- An experimental `opencode/big-pickle` model request returning `OK`.

\- Experimental Linux sandbox-local loopback checks.

\- Installed TPS Meter plugin.

\- GSD Core MCP integration.

\- Corrected generated GSD command paths.



These are useful experimental findings, not automatic production approvals.



The existing pilot must not be overwritten by development work.



\---



\# 9. CRITICAL SECURITY AND APPROVAL RULES



These rules apply throughout the remaining development.



\*\*Production apply remains prohibited.\*\*



No installation is authorized merely because:



\- A BAT file exists.

\- A PowerShell file exists.

\- A requirements JSON validates.

\- A phase returns offline review PASS.

\- The orchestrator discovers a phase.

\- The historical pilot worked.

\- The user has administrator privileges.



Installation must require independently reviewed executable logic, actual runtime prerequisites, specific authorization and the appropriate tests.



The isolation gate must fail closed.



Phase 050 runtime verification cannot be replaced by Phase 050 offline policy validation.



Additional safeguards:



\- Never call `wsl --shutdown` implicitly.

\- Never terminate the existing distribution incidentally.

\- Do not modify other WSL distributions.

\- Do not alter global `.wslconfig` without separate approval.

\- Do not silently replace existing OpenCode binaries.

\- Do not overwrite existing plugins or project configuration.

\- Do not expose secrets in logs.

\- Do not put secrets into a writable project directory.

\- Do not silently broaden sandbox network access.

\- Installation hosts and runtime provider hosts must remain independently scoped.

\- A sandbox cannot be promoted to production merely because it passed static validation.

\- Download/install approval and live provider-request approval must be separate.

\- Existing pilot artifact hashes alone are not sufficient production provenance.



Use an explicitly approved disposable environment for runtime installation testing before any production installation.



\---



\# 10. PHASE 000: CURRENT EXACT IMPLEMENTATION



The current `000-run-all.bat` is small and review-only.



It:



1\. Accepts no argument or `/review`.

2\. Checks the presence of four local supporting files.

3\. Calls `000-review.ps1`.

4\. Converts nonzero review failures to exit code `1`.

5\. Pauses standalone execution.

6\. Does not execute installation phases.



Known current issues to fix when implementing orchestration:



\### Argument validation



The current implementation handles an empty first argument by immediately jumping to review. It should also strictly reject unexpected additional arguments.



\### Exit-code propagation



The documented contract is:



```text

0    Success

1    Failure

3010 Reboot required

```



The future executable orchestrator needs to preserve these codes appropriately and fail closed on unexpected results.



\### Execution authorization



Current phase discovery does not grant installation capability.



Do not simply add a loop that executes every discovered BAT.



The executable orchestrator must distinguish:



\- Phase discovered.

\- Requirements validated.

\- Installation implementation exists.

\- Dependencies actually satisfied.

\- Runtime security gates satisfied.

\- Version and installation plan resolved.

\- Specific approval granted.

\- Phase eligible for execution.



\### Resume and phase skipping



Current requirements say skipping defaults to `DENY`.



Security-critical phases include:



```text

010

020

030

040

050

070

080

```



Resume-from must verify prerequisites and existing state before allowing execution to continue.



No implicit security-gate bypass.



\### Logging



Maintain the existing `\_common.bat` and `PHASE\_LOG` conventions.



Standalone BAT execution should pause appropriately.



Orchestrated phases should not create nested pauses.



Preserve the useful standalone auto-elevation behaviour, but never trigger surprise elevation during orchestrated/CI execution.



\---



\# 11. CURRENT PHASE 000 REQUIREMENTS



The existing file is:



`modern-install\\000-requirements.json`



Its principal sections are:



```text

schema

phase

name

status

execution

exit\_codes

requirements

approvals

phase\_skipping

logging

compatibility

```



Its execution contract currently requires:



```text

discover\_phases = true

phase\_filename\_pattern = NNN-\*.bat

exclude\_phases = \["000", "999"]

strict\_ordering = true

stop\_on\_failure = true

idempotency\_required = true

```



Approval policy currently includes:



```text

resolve\_versions\_before\_installation = true

display\_installation\_plan = true

explicit\_installation\_approval = true

production\_apply\_authorized = false

automatic\_security\_downgrades = false

```



The full local file contents were previously supplied in this conversation and should be obtained again only when actually replacing the file.



`000-review.ps1` is a working offline checker and should not be discarded merely to add an installation capability.



\---



\# 12. KNOWN DEVELOPMENT ISSUES AND LESSONS



\### A. Too much review-only scaffolding



The prior assistant spent a substantial amount of time generating requirements, BAT wrappers and PowerShell review companions.



Those files are useful and most were successfully tested, but they are not a completed installer.



Do not repeat this development cycle.



The user explicitly questioned why working files were being revisited and why additional review-only files kept being proposed.



The assistant acknowledged the issue and committed to building missing executable functionality rather than continuously extending reviews.



\### B. `000-plan.ps1`



A separate read-only `000-plan.ps1` was proposed after all eleven phases passed review.



The user did not confirm creating it.



The prior assistant subsequently said not to create it because it represented another unnecessary intermediate step.



Do not require or recreate it reflexively.



\### C. Offline tests are not runtime tests



The PASS messages from Phases 040–092 validate their declared requirements and review logic.



They do not prove:



\- Linux installation succeeds.

\- Generated scripts pass an actual shell syntax check.

\- External artifact provenance is approved.

\- Dependency trees are audited.

\- The runtime isolation gate is satisfied.

\- Transactional rollback works.

\- OpenCode or GSD is installed by the modernized scripts.



\### D. Historical source scripts can be executable



Original `092-check-gsd-source.bat` actually performs filesystem writes.



Do not infer that a script is read-only from its filename.



\### E. Guard direct PowerShell entry points



Some original scripts placed approval prompts in their BAT wrappers while allowing their PowerShell companions to execute an installation directly.



All installation-capable code must enforce approval independently of the wrapper.



\### F. PowerShell compatibility



The user has been testing on Windows PowerShell via `powershell.exe`.



Avoid PowerShell 7-only syntax unless explicitly introducing and verifying a PowerShell 7 dependency.



Known corrections from previous work:



\- Use `-join`, not `-cjoin`.

\- Handle multiple `Get-Command wsl.exe` results correctly.



\### G. Review configuration consistency



One issue to revisit during implementation:



The current `000-review.ps1` rejects empty values for all required configuration keys, whereas Phase 080's reviewed allowlist policy permits an explicitly empty list to mean `--no-network`.



The shared configuration schema should be reconciled rather than implementing contradictory acceptance rules.



\### H. Hashes and fingerprints



The historical pilot hashes must remain historical evidence.



Do not treat a local requirements-file hash or an installer-plan fingerprint as artifact provenance or installation approval.



\---



\# 13. WHAT STILL NEEDS TO BE IMPLEMENTED



This is the actual remaining development backlog.



\## A. Installer orchestration and approvals



Extend the existing Phase 000 implementation to support a real installation mode only after implementing:



\- Strict CLI parsing.

\- Explicit installation plan.

\- Specific approval tied to the plan, target and resolved artifacts.

\- Execution capability validation.

\- Ordered phase execution.

\- Runtime dependency checks.

\- Error and reboot-code propagation.

\- Default-deny skipping.

\- Safe resume.

\- Idempotency.

\- Proper logging.

\- Standalone/orchestrated behaviour.

\- Mocked positive and negative tests.



Keep production apply disabled during development.



\## B. Actual early-phase installation



Implement the missing install paths for Phases 010–030 where appropriate, including clean-machine provisioning.



Be especially careful not to overwrite or unregister the existing distribution.



\## C. Secure WSL configuration and isolation



Implement Phase 040's actual approved WSL configuration changes.



Implement Phase 050's actual runtime isolation tests.



Phase 050 must become a real HARD SECURITY GATE, not simply a requirements checker.



\## D. Base toolchain and AI Jail



Implement actual approved acquisition, installation, integrity validation and runtime verification for Phases 060 and 070.



Use compatible stable releases and record their resolved versions.



\## E. Phase 080 workspace and launchers



Implement:



\- Safe project creation.

\- Git initial state where required.

\- Preservation of existing repositories and project data.

\- Secret-directory creation.

\- Secret byte preservation.

\- Exact launcher generation.

\- Base64 UTF-8/LF payload transport where appropriate.

\- Linux-side SHA-256 and syntax checks.

\- Transactional file staging and promotion.

\- Rollback.

\- Negative tests.

\- Actual AI Jail sandbox isolation checks.



\## F. Phase 090 OpenCode



Implement:



\- Official release discovery.

\- Compatible stable-version resolution.

\- Provenance and integrity review.

\- Exact approved artifact acquisition.

\- Versioned managed installation.

\- Conflict detection.

\- Existing installation preservation.

\- Version and integrity recording.

\- Approved runtime integration.

\- Separate provider-network authorization.

\- No Windows OpenCode fallback.



\## G. Phase 091 TPS Meter



Implement the official `opencode plug` installation process against the modern approved Linux OpenCode binary.



Use an explicitly approved compatible plugin version.



Verify:



\- Package identity.

\- Exact version.

\- Actual installed metadata.

\- Structured configuration registration.

\- Existing plugin preservation.

\- Plugin cache isolation.

\- Runtime functionality.



\## H. Phase 092 GSD Core



This is a priority because the historical installer contains fixed staging dependencies.



Implement the complete independent acquisition, lockfile, generation, audit, staging, integration and rollback process.



Do not reuse the old temporary generation identifiers or existing pilot as installation prerequisites.



The GSD MCP server must be correctly integrated with managed OpenCode configuration without overwriting TPS Meter registration or unrelated settings.



\## I. Testing and production readiness



Before production apply is even considered:



\- Static analysis.

\- PowerShell/BAT argument and exit-code tests.

\- Mocked orchestrator tests.

\- Missing prerequisite tests.

\- Security-gate rejection tests.

\- Fresh installation in an explicitly approved disposable environment.

\- Idempotent rerun.

\- Partial-state recovery.

\- Conflicting-state rejection.

\- Rollback under forced failure.

\- Sandbox isolation verification.

\- Network negative tests.

\- Plugin and MCP functionality.

\- Clean Git state verification.

\- No unexpected files or pilot modification.

\- Explicit user review and approval.



\---



\# 14. HOW TO WORK WITH THE USER



This is important.



The user prefers:



\*\*ONE next action or ONE complete file at a time.\*\*



When supplying a BAT, PS1 or JSON replacement:



\- Provide the complete replacement contents.

\- State the exact destination path.

\- Avoid piecemeal manual edits.

\- Wait for the user to save it or provide the execution output.

\- Diagnose failures using the actual output.

\- Do not invent successful test results.

\- Do not ask the user to repeat information already provided in the conversation or handoff.



Keep communication compact, technical and direct.



Do not repeatedly congratulate the user for completing another offline review.



More importantly:



\*\*Stop making new review-only scaffolding the default next step.\*\*



Work toward finished executable functionality.



The user wants an installer that actually works on a clean Windows machine when its implementation is completed, tested and explicitly authorized.



The preferred approach is:



1\. Reuse existing modernized files.

2\. Implement actual missing functionality.

3\. Test with safe mocks first.

4\. Test against a disposable WSL environment only with separate approval.

5\. Preserve existing production/pilot state.

6\. Keep production apply disabled until the user independently approves that stage.



No silent WSL shutdowns.



No surprise downloads.



No implicit live model-provider calls.



No modifying the existing pilot because its paths happen to be convenient.



\---



\# 15. EXACT LAST COMPLETED STATE



The final user-tested action was running:



```bat

D:\\.coding\\.ai-jail\\modern-install\\000-run-all.bat

```



It passed with:



```text

PHASE 000 REVIEW: PASS



Installation phases discovered: 11

Requirements validation: PASS



INSTALLATION: DISABLED

PRODUCTION APPLY: DISABLED

WSL INVOCATION: NONE

DOWNLOADS: NONE

SYSTEM MODIFICATIONS: NONE



PHASE 000 EXIT CODE: 0

```



Afterward, the user provided the exact current contents of:



```text

modern-install\\000-run-all.bat

modern-install\\000-requirements.json

modern-install\\000-review.ps1

```



The assistant proposed a new `000-plan.ps1` but then acknowledged that this was not productive and withdrew that recommendation.



\*\*The user has not confirmed saving or running `000-plan.ps1`.\*\*



The user now wants to continue in a fresh conversation without repeating the completed discovery and review work.



\---



\# 16. IMMEDIATE NEXT DEVELOPMENT STEP



Do not begin by asking the user to rerun all eleven reviews.



Do not begin by generating another set of review-only requirements.



The first task in the new conversation is to establish the executable Phase 000 installation and approval contract, then begin implementing it using the existing files.



Start by acknowledging that the review layer has already passed.



Use the existing Phase 000 architecture as the foundation.



A sensible first deliverable is a complete, implementation-oriented replacement of the orchestration requirements and then its executable orchestration logic, with a safe mock/testing path that cannot invoke real production installation.



However, do not simply enable `/apply` in the current BAT: the downstream phase installation implementations do not yet exist.



Plan development in a way that produces real, testable executable functionality rather than another standalone PASS-only review.



\*\*Crucial:\*\* The existing working files should be extended, not repeatedly replaced for cosmetic or procedural reasons.



The project is at the transition between completed offline review scaffolding and actual executable fresh-machine installer implementation.



That is exactly where the next conversation must resume.



