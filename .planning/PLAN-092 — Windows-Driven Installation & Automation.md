\# PLAN-092 — Windows-Driven Installation \& Automation



\*\*Project:\*\* AI Jail  

\*\*Phase:\*\* 092  

\*\*Status:\*\* PLANNED  

\*\*Execution environment:\*\* Windows 11 CMD → WSL2 `ai-jail`  

\*\*Primary objective:\*\* Build a reproducible installation system that can eventually configure the complete AI Jail environment through `000-run-all.bat`.



\---



\## 1. Purpose



Phase 092 establishes the development and installation methodology for all remaining AI Jail components.



Instead of installing software manually inside Linux and subsequently attempting to reproduce the process in Windows BAT files, all installation procedures will be developed and tested from Windows 11 using the same execution path intended for the final installer.



The project will progress through real installations rather than extensive speculative compatibility testing.



Every successfully installed component must become a reproducible, independently verifiable installation step.



\## 2. Core principle



\*\*Install → Execute → Diagnose → Fix → Verify → Automate → Integrate → Next component.\*\*



A component is not considered complete merely because its installer returns exit code zero.



It must:



1\. Install successfully.

2\. Pass its functional acceptance test.

3\. Produce a repeatable BAT/PowerShell installation procedure.

4\. Detect an existing valid installation without unnecessarily reinstalling it.

5\. Handle installation failures without damaging previously accepted components.

6\. Be ready for integration into `000-run-all.bat`.



\## 3. Division of responsibilities



\### ChatGPT



Acts as the project's researcher, architect, installation designer and security reviewer.



Responsibilities:



\- Research relevant upstream documentation before proposing technical changes.

\- Design installation commands and approval boundaries.

\- Provide exact commands intended for Windows CMD.

\- Analyze returned terminal output and identify installation failures.

\- Propose specific corrections.

\- Convert successful procedures into BAT/PowerShell installation scripts.

\- Maintain installation sequencing and technical documentation.



\### User



\- Runs the provided commands in Windows CMD.

\- Explicitly approves installation, download, write and execution boundaries.

\- Returns stdout, stderr and exit codes.

\- Approves proposed changes to existing BAT/PowerShell files.

\- Decides when completed components are promoted to the main installation chain.



\### MiMo / OpenCode



Optional execution assistance only.



When used, it executes explicitly approved, bounded tasks without independently expanding their scope, applying repairs or running additional commands.



\## 4. Standard execution interface



Windows CMD is the default entry point.



Example:



```bat

wsl.exe --distribution ai-jail --user aijail --exec /usr/bin/id

```



Linux commands will run in the dedicated WSL2 `ai-jail` distribution under the explicitly selected Linux user.



For complex installations, dedicated scripts will be invoked through the Windows orchestration layer rather than relying on fragile, deeply nested CMD/Bash one-liners.



Windows BAT/PowerShell handles orchestration; Linux-native scripts perform Linux installation operations.



\*\*Windows orchestration must not depend on enabling WSL automount or Linux-to-Windows interoperability.\*\* Installation payload transfer must use an explicitly approved mechanism.



The provisioning environment and the jailed runtime are separate security contexts. Installing a component into WSL does not automatically authorise running that component inside AI Jail.



\## 5. Implementation stages



\### 092.0 — Establish Windows CMD execution baseline



\- Verify invocation of the dedicated `ai-jail` distribution.

\- Confirm execution as Linux user `aijail`.

\- Establish consistent command output and exit-code reporting.

\- Confirm that the accepted Phase 080 configuration remains unchanged.



\*\*Acceptance:\*\* Windows CMD can reliably execute an approved Linux command without changing existing WSL isolation settings.



\### 092.1 — Reconcile existing installation scripts



Review the existing Phase 090 BAT/PowerShell implementation against all verified Phase 091 findings.



Preserve completed work, including:



\- Pinned OpenCode Linux v1.18.34.

\- Pinned GSD Core v1.15.0.

\- Verified offline dependency inputs.

\- OpenCode plugin dependency preparation.

\- Generated GSD commands, agents, skills and plugin.

\- Pinned local GSD MCP entry point.



Do not replace the accepted installation architecture or repeat previously completed investigations without a demonstrated need.



\*\*Acceptance:\*\* The remaining implementation gaps are identified and the next installation transaction is clearly defined.



\### 092.2 — Install OpenCode through Windows



Execute the approved OpenCode installation procedure using Windows CMD.



Verify the installed Linux version and artifact integrity.



Once functional, finalize its BAT/PowerShell installation step.



\*\*Acceptance:\*\* OpenCode installs, starts and can be detected by its installer on subsequent executions.



\### 092.3 — Install GSD Core



Install the pinned GSD Core release using the proven offline, runtime-aware installer.



Preserve its OpenCode-specific output transformations.



Verify generated commands, agents, skills and configuration.



\*\*Acceptance:\*\* The GSD installation is complete, repeatable and version-pinned.



\### 092.4 — Prepare plugin dependencies and MCP



Package the verified OpenCode plugin dependency installation procedure.



Configure the pinned local GSD MCP entry point.



Verify actual OpenCode startup and MCP connection rather than relying solely on configuration-file checks.



\*\*Acceptance:\*\* OpenCode discovers GSD commands and reports the local GSD MCP server as connected.



\### 092.5 — Integrate the secured runtime launcher



Establish an independent pilot workspace and Git boundary.



Apply narrowly scoped writable filesystem mappings and explicitly approved network permissions.



Do not reuse the experimental launcher that grants writable access to the entire parent `opencode-work` directory for autonomous workflow execution.



\*\*Acceptance:\*\* The managed OpenCode installation starts inside AI Jail with only the intended runtime access.



\### 092.6 — Functional workflow acceptance



With separate approval:



\- Configure the selected free model.

\- Execute a harmless disposable GSD project.

\- Test `/gsd-new-project`.

\- Verify generated planning files.

\- Verify the resulting filesystem changes remain within the approved writable scope.

\- Reopen the project and confirm GSD can continue using it.



\*\*Acceptance:\*\* A real GSD workflow completes successfully in the controlled environment.



\### 092.7 — BAT integration and reproducibility



After individual components work:



\- Finalize their BAT/PowerShell installation steps.

\- Validate review and apply behavior.

\- Validate pins, hashes and prerequisite checks.

\- Implement appropriate idempotence and recovery.

\- Integrate completed steps into `000-run-all.bat`.

\- Validate a repeat invocation without reinstalling healthy components.

\- Define the separately approved fresh-rebuild acceptance procedure.



\*\*Acceptance:\*\* The Windows installation chain can reproduce the verified Linux environment.



A fresh or destructive rebuild is not authorised merely by approving this plan.



\## 6. Installer requirements



Every component installer must provide:



| Requirement | Expected behavior |

|---|---|

| Review mode | Display intended changes without installing |

| Apply mode | Execute only the approved transaction |

| Version pinning | Install exact approved versions |

| Integrity | Validate expected artifact hashes |

| Idempotence | Detect and preserve valid existing installations |

| Failure handling | Stop and retain relevant evidence |

| Recovery | Preserve the previous accepted state where applicable |

| Logging | Record meaningful actions and failures |

| Exit codes | Follow the existing `0 / 1 / 3010` project convention |

| Scope | Avoid unrelated installation or configuration changes |



Existing Phase 090 production `--apply` restrictions remain active until their implementation is reviewed and separately approved.



\## 7. Troubleshooting policy



Troubleshooting will be driven by actual installation or execution failures.



When an operation fails:



1\. Preserve its error output.

2\. Identify the specific failed component.

3\. Research the relevant upstream behavior.

4\. Propose the smallest justified correction.

5\. Obtain approval for additional writes or execution.

6\. Repeat only the affected operation.

7\. Incorporate the verified correction into the corresponding installer.



Warnings that do not cause demonstrated functional failures will be documented and prioritized appropriately.



No silent retries, unpinned upgrades, unnecessary reinstalls or autonomous scope expansion.



\## 8. Security constraints



Phase 092 must preserve the accepted AI Jail security baseline.



In particular:



\- Do not modify the accepted 000–080 installation stages without explicit approval.

\- Do not enable WSL automount, interop or Windows PATH propagation for convenience.

\- Do not assume that Windows drives are mounted inside Linux.

\- Do not introduce unrestricted writable mappings.

\- Do not grant permanent tool approvals.

\- Do not use unpinned `latest` package installations in managed components.

\- Keep installation-time network permissions distinct from runtime network permissions.

\- Require separate approval for live model execution.

\- Preserve known-good installation versions until an approved replacement or cleanup.



Environment-variable redirection is not a substitute for operating-system-level confinement.



\## 9. Relationship to existing phases



| Phase | Relationship |

|---|---|

| 000–080 | Accepted foundation; preserve |

| 090 | Existing OpenCode/GSD installation architecture |

| 091 | Compatibility evidence and functional findings reused by Phase 092 |

| \*\*092\*\* | Windows-driven installation and automation methodology |

| 100 | ComfyUI installation using the same methodology |

| 110 | Maintenance and recovery |

| 200 | Deferred optional optimization |

| 900 | Full-system acceptance |



Phase 092 does not retroactively declare Phase 091 complete. The actual jailed GSD workflow remains an outstanding functional acceptance milestone.



\## 10. Deliverables



\- Verified Windows-to-WSL installation procedure.

\- Working component installation scripts.

\- Completed OpenCode/GSD BAT/PowerShell integration.

\- Documented dependency and configuration pins.

\- Secure runtime launcher.

\- Successful disposable GSD workflow evidence.

\- Updated `000-run-all.bat` installation chain.

\- Reproducibility and recovery instructions.



\## 11. Definition of phase completion



Phase 092 is complete when a user can execute the approved Windows installation chain and obtain a functioning OpenCode/GSD environment inside the dedicated AI Jail WSL2 distribution, without relying on undocumented manual Linux installation steps.



Individual component installers must also function independently.



The validated installation methodology then becomes the standard process for ComfyUI and all subsequent components.



\---



\*\*Phase guiding rule: Build the real installer while installing the real system. Every working installation becomes reproducible automation before moving to the next component.\*\*

