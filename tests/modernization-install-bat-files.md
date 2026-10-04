\# AI Jail — Installation BAT Files Modernization



\*\*Status:\*\* PLANNED — Not yet implemented  

\*\*Scope:\*\* Phases 000–092 and future installation phases  

\*\*Platform:\*\* Windows 11 + WSL2  

\*\*Primary objective:\*\* Reproducible, secure, Windows-driven installation and updates.



\---



\## 1. Objective



Modernize the entire AI Jail installation chain so a user can start with a clean Windows 11 machine, double-click `000-run-all.bat`, approve the proposed changes, and obtain a complete, verified AI Jail environment.



The system must:



\- Retrieve current stable software versions from official sources.

\- Install components using their official, documented installation methods.

\- Maintain one requirements JSON file per installation phase.

\- Record the exact versions and artifact hashes actually installed.

\- Detect incompatibilities and produce actionable error reports.

\- Support future updates without requiring manual script rewrites for every release.

\- Preserve the last verified installation when an update fails.

\- Never silently weaken the AI Jail security baseline.

\- Remain operable through Windows BAT launchers.



\*\*Latest available does not automatically mean compatible or approved.\*\* Version discovery, compatibility validation, installation approval, and activation are separate steps.



\---



\## 2. Installation Structure



The existing installation phases must be preserved and modernized rather than replaced with a competing installation system.



| Phase | Responsibility | Requirements file |

|---|---|---|

| 000 | Installation orchestrator | Reads phase requirements and coordinates execution |

| 010 | Windows preflight | `010-requirements.json` |

| 020 | WSL verification | `020-requirements.json` |

| 030 | Linux distribution creation | `030-requirements.json` |

| 040 | WSL configuration | `040-requirements.json` |

| 050 | Isolation and security gate | `050-requirements.json` |

| 060 | Base toolchain | `060-requirements.json` |

| 070 | AI Jail installation | `070-requirements.json` |

| 080 | Sandbox configuration | `080-requirements.json` |

| 090 | OpenCode installation | `090-requirements.json` |

| 091 | OpenCode plugin installation | `091-requirements.json` |

| 092 | GSD Core installation | `092-requirements.json` |



The same naming convention must extend to future phases, including ComfyUI.



Not every phase requires a software version. Security and configuration phases must define mandatory conditions and expected behavior instead.



\---



\## 3. Proposed File Organization



```text

D:\\.coding\\.ai-jail\\

│

├── 000-run-all.bat

├── \_common.bat

├── config.env

│

├── 010-preflight.bat

├── 010-requirements.json

│

├── 020-wsl-check.bat

├── 020-requirements.json

│

├── 030-create-distro.bat

├── 030-requirements.json

│

├── 040-wsl-conf.bat

├── 040-requirements.json

│

├── 050-isolation-gate.bat

├── 050-requirements.json

│

├── 060-base-toolchain.bat

├── 060-requirements.json

│

├── 070-ai-jail.bat

├── 070-requirements.json

│

├── 080-setup-sandboxes.bat

├── 080-setup-sandboxes.ps1

├── 080-requirements.json

│

├── 090-setup-opencode.bat

├── 090-setup-opencode.ps1

├── 090-requirements.json

│

├── 091-setup-opencode-plugins.bat

├── 091-requirements.json

│

├── 092-setup-gsd.bat

├── 092-requirements.json

│

├── .state\\

│   ├── installed-versions.json

│   ├── resolved-versions.json

│   └── reports\\

│

└── .planning\\

&#x20;   └── modernization-install-bat-files.md

```



This is the \*\*target structure\*\*, not a claim that all these files already exist. Existing working filenames should be retained until their replacements are approved and integrated.



\---



\## 4. Requirements JSON Architecture



Every installation phase must have its own requirements JSON.



A requirements file describes what the installation must achieve, rather than simply recording what was installed previously.



Example: `091-requirements.json`



```json

{

&#x20; "schema": 1,

&#x20; "phase": "091",

&#x20; "name": "OpenCode Plugins",

&#x20; "components": \[

&#x20;   {

&#x20;     "id": "opencode-tps-meter",

&#x20;     "source": "https://github.com/ChiR24/opencode-tps-meter",

&#x20;     "version\_policy": "latest-stable",

&#x20;     "installation\_method": "official-author",

&#x20;     "target": "jailed-opencode-only",

&#x20;     "requires\_approval": true

&#x20;   }

&#x20; ],

&#x20; "verification": {

&#x20;   "check\_package\_version": true,

&#x20;   "check\_configuration": true,

&#x20;   "check\_runtime\_visibility": true

&#x20; }

}

```



The format must eventually accommodate:



\- Component identity and official upstream source.

\- Version-selection policy.

\- Compatibility constraints.

\- Required dependencies.

\- Official installation method.

\- Installation target.

\- Security restrictions.

\- Verification criteria.

\- Required approvals.

\- Rollback or recovery strategy where applicable.



Requirements must be schema-validated before installation.



An invalid or unsupported requirements file must cause the phase to fail closed.



\---



\## 5. Version Management



The installation system should support the following policies:



| Policy | Meaning |

|---|---|

| `latest-stable` | Discover the newest official stable release |

| `pinned` | Install an explicitly specified version |

| `minimum` | Require at least a specified version |

| `system` | Use the supported operating-system component |

| `security-baseline` | Enforce mandatory security conditions |



Prerelease versions must not be selected automatically.



\### Version-resolution process



For components using `latest-stable`:



1\. Query the official release source.

2\. Determine the newest stable version.

3\. Verify compatibility with the declared requirements.

4\. Resolve dependency versions.

5\. Identify official download artifacts.

6\. Establish artifact integrity.

7\. Present the proposed installation for approval.

8\. Freeze the resolved versions for that installation run.



Once installation begins, versions must not change midway through the run because a newer upstream release appears.



Record the frozen results in `.state/resolved-versions.json`.



Record the successfully installed versions in `.state/installed-versions.json`.



For repeatability, the updater must support reproducing a previously verified installation using its recorded version and integrity information, rather than always resolving the latest version.



\---



\## 6. Installation Behavior



Every installation phase must be:



\*\*Repeatable:\*\* Running it again must not unnecessarily reinstall working components.



\*\*Idempotent:\*\* Existing verified installations should be recognized and preserved.



\*\*Explicitly approved:\*\* Software installation, downloads and security-relevant changes require authorization.



\*\*Failure-aware:\*\* Errors must produce a nonzero exit code and explain what failed.



\*\*Recoverable:\*\* A failed upgrade must not silently destroy the last working installation.



\*\*Scoped:\*\* Installation must affect only the intended environment.



\### BAT and PowerShell responsibilities



BAT files remain the Windows entry points.



Complex installation logic should reside in corresponding PowerShell scripts where appropriate.



Avoid unnecessarily complicated inline CMD, Python or shell expressions.



Use official installers when available, provided their behavior and security implications have been reviewed.



Do not manually recreate a plugin author's installation procedure when a supported official installer exists.



\---



\## 7. Orchestrator Integration



`000-run-all.bat` remains the single installation orchestrator.



It must:



1\. Discover the defined installation phases in their intended order.

2\. Load and validate their requirements.

3\. Resolve requested versions.

4\. Identify missing components and proposed changes.

5\. Request the appropriate approvals.

6\. Execute the approved installation sequence.

7\. Record results and installed versions.

8\. Stop on critical failures.

9\. Produce a final installation report.



The existing `\_common.bat` contract and shared `PHASE\_LOG` behavior must be preserved unless explicitly redesigned and approved.



An orchestrated phase must not unexpectedly display its own interactive prompt or begin an unapproved installation.



Double-click execution should remain convenient:



\- Automatically request administrator privileges only when necessary.

\- Display clear installation results.

\- Pause at the end when launched independently.

\- Avoid redundant pauses when launched through the orchestrator.



Production changes must remain gated independently from pilot installation and testing.



\---



\## 8. Security Requirements



Modernization must preserve the accepted AI Jail isolation baseline.



Mandatory protections include:



\- WSL isolation and verified configuration.

\- No unintended Windows filesystem exposure.

\- No unintended WSL interoperability.

\- Explicitly controlled networking.

\- Approved filesystem mappings.

\- Read-only installation components wherever feasible.

\- Narrow, justified writable runtime and workspace mappings.

\- Verified executable and dependency integrity.

\- No unattended security downgrades.

\- No automatic expansion of network or filesystem permissions to make an installation pass.



If a new release becomes incompatible with the existing sandbox, the system must report the incompatibility.



It must \*\*not\*\* automatically weaken AI Jail restrictions, disable security checks, or modify requirements to suppress the error.



\---



\## 9. Unified Update System



A dedicated update system will be developed after installation modernization.



Its responsibilities:



1\. Read all phase requirements.

2\. Read the installed-version records.

3\. Query official upstream sources.

4\. Compare installed and available versions.

5\. Identify potential compatibility issues.

6\. Produce a proposed update plan.

7\. Request approval.

8\. Apply updates using the appropriate phase installer.

9\. Run essential installation and functional verification.

10\. Record success or failure.



\### Failed updates



If an update fails:



\- Preserve the previous verified installation wherever possible.

\- Report the affected phase and component.

\- Record attempted and previously installed versions.

\- Capture the actual installation or verification error.

\- Identify which requirements may need revision.

\- Provide a structured failure report.



The updater may recommend changes to requirements, but \*\*must never modify security requirements automatically\*\*.



Requirements changes require review and explicit approval.



\---



\## 10. Current Working Baseline



The current experimental environment must be preserved during modernization.



The following integration has already been demonstrated:



| Component | Verified baseline |

|---|---|

| Windows host | Windows 11 |

| WSL distribution | `ai-jail` |

| AI Jail | 2.2.0 |

| OpenCode | 1.18.34 |

| GSD Core | 1.15.0 |

| TPS Meter | 0.4.0 |

| GSD commands | 72 generated commands |

| GSD MCP | Connected inside AI Jail |

| Windows Terminal | Dedicated jailed launcher |

| Visual distinction | AI Jail Astrodark |



Filesystem checks demonstrated that the installed pilot is read-only and writes made to the sandbox's disposable parent directory do not persist to the real WSL filesystem.



These versions are the \*\*known working reference\*\*, not permanent version pins for the modernized online installer.



\### Known limitations



The current installation chain is not yet capable of a complete clean-machine rebuild:



\- Phases 060 and 070 currently rely substantially on verifying existing installations.

\- Phase 080 remains subject to its existing approval restrictions.

\- The current Phase 090 pilot uses a preserved experimental source binary.

\- Phase 092 still relies on preserved Phase 091-generated source artifacts and offline dependencies.

\- The verified experimental pilot is not equivalent to an approved production installation.



These limitations must be addressed during modernization, not hidden by changing installation status labels.



\---



\## 11. Implementation Order



Modernize the system in dependency order.



\### Stage A — Preserve the current baseline



Document existing files, versions, integrity information and accepted security behavior.



Do not destroy or overwrite the working pilot.



\### Stage B — Phases 000–050



Modernize the orchestrator, Windows preflight, WSL setup and isolation verification.



Preserve established security requirements and approved behavior.



\### Stage C — Phases 060–080



Restore actual clean-installation capability for the toolchain, AI Jail and sandbox configuration.



These phases must do more than verify a previously configured machine.



\### Stage D — Phases 090–092



Modernize OpenCode, plugin and GSD installation.



Retrieve approved components directly from official upstream sources, resolve current stable versions, preserve official installation methods, and remove dependencies on temporary experimental staging directories.



Phase 091 must follow the project's \*AI Jail — OpenCode Plugin Installation Reference\*.



\### Stage E — Unified update system



Implement version discovery, compatibility reporting, approval, upgrades, installation-state tracking and recovery.



\### Stage F — End-to-end validation



Verify the complete installation process against a fresh, disposable environment before enabling production installation.



Confirm that subsequent runs recognize an existing verified installation and do not repeat unnecessary work.



\---



\## 12. Working Rules for Implementation



1\. Work on one installation phase at a time.

2\. Provide complete replacement BAT/PS1 files rather than fragmented edits.

3\. Preserve known-working components unless a reviewed change requires modification.

4\. Use temporary CMD commands for essential investigation rather than accumulating diagnostic BAT files.

5\. Reserve permanent BAT files for installation, setup, launch and update functionality.

6\. Investigate actual errors and correct their causes rather than adding speculative checks.

7\. Avoid repeating successful functional tests without a relevant change.

8\. Follow official developer installation instructions.

9\. Maintain explicit approval for downloads and installation changes.

10\. Never claim a clean-install capability until it has been demonstrated.

11\. Keep production installation disabled until the revised installation chain is reviewed and approved.

12\. Record meaningful changes and outcomes in the project's planning documentation.



\---



\## 13. Definition of Done



Installation modernization is complete when:



\- Every installation phase has a validated requirements file.

\- Every required component can be installed from a clean supported Windows 11 environment.

\- Version resolution uses official sources and approved policies.

\- Actual installed versions and artifact integrity information are recorded.

\- The entire installation can be orchestrated through `000-run-all.bat`.

\- Standalone phase execution remains supported.

\- Existing verified components are preserved on subsequent runs.

\- Failure handling and recovery are documented and tested.

\- OpenCode, GSD and approved plugins work inside AI Jail.

\- Filesystem and network restrictions remain enforced.

\- No installation depends on temporary Phase 091 staging directories.

\- The update system can identify newer versions and report compatibility issues.

\- Production activation remains subject to explicit approval.



\*\*Final objective:\*\* A maintainable, secure, reproducible AI Jail installation system that automatically discovers current software releases while keeping compatibility decisions, security requirements and installation approvals under explicit control.



