\# AI Jail — OpenCode Plugin Installation Reference



\*\*Purpose:\*\* Permanent reference for installing, configuring, maintaining and troubleshooting OpenCode plugins inside AI Jail.



\*\*Applies to:\*\* All future OpenCode plugins, including server plugins, TUI plugins and plugins requiring both components.



\*\*Current environment:\*\* Windows 11 → WSL2 → AI Jail → Linux OpenCode.



\---



\## 1. Golden Rule: Follow the Developer's Instructions



\*\*Always follow the plugin developer's official installation instructions first.\*\*



This is the primary rule and takes precedence over assumptions, generic installation recipes and previous experience with other plugins.



Before installing any plugin:



1\. Locate its official repository and installation documentation.

2\. Read the complete installation instructions, including prerequisites and compatibility notes.

3\. Identify the instructions applicable to our exact OpenCode version.

4\. Follow the developer's prescribed installation method and configuration procedure.

5\. Check whether the plugin requires additional packages, environment variables, external services or configuration files.

6\. Record any changes necessary specifically because OpenCode runs inside AI Jail.



Do not substitute `npm install`, manually edit configuration files, copy modules or install additional dependencies merely because those methods seem equivalent.



If the developer provides an official OpenCode installation command, use it.



If instructions are ambiguous or incompatible with our environment, investigate the discrepancy before making changes.



\### Version policy



Prefer explicitly pinned, reviewed plugin versions.



If the developer documents `@latest`, determine an appropriate approved version and record the substitution. Do not silently claim that a modified command is identical to the original instructions.



\---



\## 2. Understand the Installation Environment



Our setup contains several distinct environments:



| Environment | Responsibility |

|---|---|

| Windows 11 | Host operating system and installation orchestration |

| WSL2 (`ai-jail`) | Linux environment containing OpenCode |

| OpenCode pilot | Installed Linux executable and related components |

| AI Jail | Additional restrictions applied when launching OpenCode |

| OpenCode configuration | Plugin registration and application settings |

| OpenCode package cache | Downloaded plugin packages and dependencies |



These environments must not be confused.



Installing a plugin into native Windows OpenCode does not install it into Linux OpenCode.



Likewise, successfully installing a plugin in WSL2 does not guarantee that the plugin will be accessible when OpenCode runs inside AI Jail.



\*\*Installation, configuration, runtime visibility and successful operation are separate requirements.\*\*



\---



\## 3. Permanent Installer Responsibilities



All approved OpenCode plugin installations must be maintained in:



`091-setup-opencode-plugins.bat`



This is the dedicated plugin installation phase.



Its responsibilities are to:



\- Maintain an explicit registry of approved plugins and versions.

\- Verify that the required OpenCode installation exists.

\- Execute each plugin developer's prescribed installation procedure.

\- Target the intended Linux OpenCode configuration.

\- Obtain explicit approval before installations or downloads.

\- Preserve existing plugin and GSD configurations.

\- Support safe, repeatable execution.

\- Verify essential installation results.

\- Return meaningful exit codes.



Do not create a separate permanent BAT for every plugin.



Do not install plugins automatically whenever OpenCode launches.



The installer and launcher must remain separate.



\---



\## 4. Follow the Correct OpenCode Installation Method



OpenCode plugins can have different installation mechanisms.



A developer may prescribe:



\- OpenCode's built-in plugin installer.

\- A package-manager command.

\- A local module or source file.

\- A specific configuration entry.

\- Additional setup for server or TUI integration.



\*\*There is no universal installation command suitable for every plugin.\*\*



Use the method documented by the developer.



When using OpenCode's built-in plugin installer, preserve its intended behaviour, including automatic target detection and configuration updates.



Do not manually recreate work that the official installer already performs unless the developer explicitly requires it.



\### Configuration scope



Ensure the installation targets the intended Linux OpenCode instance.



Our pilot currently uses:



```text

/home/aijail/projects/opencode-work/.phase092-runtime/opencode

```



When appropriate, configuration scope can be controlled using:



```text

XDG\_CONFIG\_HOME

OPENCODE\_CONFIG

OPENCODE\_CONFIG\_DIR

OPENCODE\_TUI\_CONFIG

```



Use only the variables supported by the installed OpenCode version and relevant to the plugin.



Installation and runtime launch must resolve to compatible configuration locations.



Do not accidentally install into native Windows OpenCode, an unrelated Linux user configuration or the production environment.



\---



\## 5. Critical AI Jail Finding: Plugin Cache Visibility



This is an important lesson discovered during the successful TPS Meter integration.



\### The problem



Some official OpenCode plugin installers download packages into OpenCode's normal Linux package cache rather than the application's configuration directory.



Our launcher uses:



```text

\--private-home

```



This provides OpenCode with an isolated home environment.



Consequently, a plugin can be:



\- Successfully downloaded.

\- Correctly registered.

\- Reported as installed by the official installer.

\- Present in the Linux filesystem.



Yet remain unavailable to OpenCode inside AI Jail because its package directory is hidden by the private-home isolation.



\*\*A successful installation message does not prove that the jailed runtime can access the installed package.\*\*



\### The verified solution



First, establish the actual installed package location.



For packages requiring access to a directory outside the jail's visible filesystem, evaluate an explicit, narrowly scoped read-only mount.



AI Jail supports read-only mapping using:



```text

\--map

```



Conceptual example:



```text

\--map "/verified/path/to/required/plugin/package"

```



Use the plugin's real, verified installation path. Never assume that all plugins share the same cache structure.



If the plugin requires access to external dependency directories, identify and review those dependencies as well.



\### Security requirements



\- Mount only the directories demonstrably required.

\- Prefer read-only access.

\- Never expose the entire Linux home directory merely to make a plugin work.

\- Never mount the entire package cache without a separate justification.

\- Do not grant additional network permissions without establishing that they are required.

\- Do not make production or security configuration writable merely to fix plugin-loading errors.

\- Treat plugin source code and its dependencies as executable third-party software, even when mounted read-only.



A read-only mount prevents modification of the mounted source; it does not make the plugin's code inherently trustworthy.



\---



\## 6. Plugin Configuration and Runtime Loading



Some plugins have separate server and TUI components.



For example, a plugin may require registration in both:



```text

opencode.json

tui.json

```



However, these requirements are plugin-dependent.



Follow the developer's documentation to determine which configuration files and entry points are required.



When an official installer manages registration, allow it to do so.



Avoid adding duplicate or conflicting entries manually.



\### Installation verification has three levels



| Level | What must be established |

|---|---|

| Package | Correct plugin version was installed |

| Configuration | The required components were registered correctly |

| Runtime | The plugin actually loads and performs its intended function inside AI Jail |



A plugin is not considered operational until the third level passes.



\---



\## 7. Dependency Management



Never assume that missing packages should automatically be installed.



Consult the plugin's official documentation and package manifest.



Distinguish between:



\- Required dependencies.

\- Peer dependencies.

\- Optional peer dependencies.

\- Dependencies supplied by OpenCode itself.

\- Packages needed only for development or building from source.



In particular, TUI plugins may rely on rendering and reactive libraries supplied by OpenCode.



Installing additional independent copies of those libraries can introduce compatibility or shared-runtime problems.



If dependency resolution fails:



1\. Identify the exact missing module and where resolution occurs.

2\. Check the plugin developer's documented requirements.

3\. Verify the installed OpenCode version and host-provided capabilities.

4\. Determine whether the problem is an absent dependency, configuration mismatch or filesystem visibility issue.

5\. Apply the smallest supported correction.



Do not install packages using `@latest` or use dependency-bypass flags without understanding their consequences.



\---



\## 8. Troubleshooting Procedure



When an installed plugin does not appear or function, investigate in this order.



\### A. Confirm the installation method



Was the plugin installed using its developer's documented procedure?



If not, reconcile the installation before introducing workarounds.



\### B. Confirm the installation target



Was it installed for the correct Linux OpenCode instance and configuration directory?



Check for accidental native Windows, unrelated Linux or project-local installation.



\### C. Inspect the official installer output



Determine whether the installer reported package installation, configuration updates and required component registration.



Do not infer successful runtime loading from those messages alone.



\### D. Locate the installed package



Identify the actual installation/cache directory.



Do not assume the package exists inside the configuration directory's `node\_modules`.



\### E. Review AI Jail visibility



Determine whether `--private-home`, filesystem mappings or other isolation settings hide the plugin's required files.



If necessary, add a narrow read-only mapping for the verified package directory.



\### F. Review dependencies and configuration



Check developer-documented dependencies, component registration, environment variables and OpenCode compatibility.



\### G. Inspect actual errors



If the plugin still fails, use application diagnostics to identify the real failure.



Avoid repeatedly changing configuration based only on hypotheses.



For terminal applications, capture verbose diagnostics separately rather than printing DEBUG logs over the interactive TUI.



\### H. Apply a targeted correction



Prefer correcting an identified installation, visibility or configuration problem over repeatedly uninstalling and reinstalling the same package.



Do not weaken AI Jail isolation merely to eliminate an unexplained error.



\---



\## 9. Repeatability and Idempotence



Phase 091 must support future system installation and safe reruns.



For every approved plugin:



\- Record the developer's official repository.

\- Record the selected plugin version.

\- Record the applicable OpenCode version or compatibility requirements.

\- Record the official installation procedure.

\- Record the intended configuration scope.

\- Record any package-cache visibility requirements.

\- Record required AI Jail runtime mappings.

\- Record the minimum functional verification.

\- Preserve unrelated configurations.

\- Refuse unexpected versions or conflicting installations.

\- Avoid unnecessary downloads or reinstalls when the desired state is already verified.



A failed installation should not be reported as successful merely because the package or configuration entry exists.



Back up existing configuration before modifying it when appropriate.



Production installation remains subject to separate review and approval.



\---



\## 10. Case Study: TPS Meter — Lessons Learned



\*\*Plugin:\*\* \[ChiR24/opencode-tps-meter](https://github.com/ChiR24/opencode-tps-meter)  

\*\*Verified version:\*\* `0.4.0`  

\*\*OpenCode version:\*\* `1.18.34`  

\*\*Result:\*\* Operational inside AI Jail.



This case is retained as an example of the general procedure, not as the installation instructions for every future plugin.



\### What initially went wrong



Our first attempts departed from the developer's documented installation method:



\- Manual npm installation.

\- Manual configuration edits.

\- Experimental local-module registration.

\- Unnecessary investigation of optional rendering dependencies.



These changes complicated the installation without establishing the actual source of the problem.



\### What worked



We removed the experimental installation and used OpenCode's official plugin installer, with the approved version pin and isolated Linux configuration scope.



The installer successfully detected and registered both server and TUI components.



However, the meter was still invisible inside AI Jail.



We then identified the actual package cache:



```text

/home/aijail/.cache/opencode/packages/opencode-tps-meter@0.4.0

```



Our private-home isolation prevented the jailed runtime from accessing that directory.



The decisive correction was a narrowly scoped read-only mapping in the existing launcher:



```bat

&#x20;   --map "/home/aijail/.cache/opencode/packages/opencode-tps-meter@0.4.0" ^

```



\*\*After that change, the meter appeared successfully.\*\*



\### General lesson



When a plugin works outside AI Jail but not inside it, investigate whether the sandbox can access its installed package and dependencies before assuming the installation is defective.



Always follow the developer's installation instructions first. Then make only the additional adaptations genuinely required by AI Jail.



\---



\## 11. Future Plugin Installation Checklist



Before approving a new plugin:



\- \[ ] Official developer documentation reviewed.

\- \[ ] Compatibility with our pinned OpenCode verified.

\- \[ ] Plugin version selected and recorded.

\- \[ ] Third-party code and permissions reviewed.

\- \[ ] Official installation method preserved.

\- \[ ] Correct Linux configuration scope established.

\- \[ ] Required components and dependencies identified.

\- \[ ] Actual package installation location identified.

\- \[ ] AI Jail visibility requirements reviewed.

\- \[ ] Only necessary filesystem/network permissions authorised.

\- \[ ] Installation integrated into Phase 091.

\- \[ ] Existing GSD and plugin configurations preserved.

\- \[ ] Actual functionality verified inside jailed OpenCode.

\- \[ ] Successful installation procedure documented for future rebuilds.



\---



\## 12. Guiding Principle



\*\*Developer instructions first. AI Jail compatibility second. Minimal verified changes always.\*\*



Do not modify how a plugin is installed unless the developer's instructions demonstrably require adaptation.



When AI Jail creates an additional runtime requirement, document it separately so the official installation procedure remains recognisable and maintainable.

