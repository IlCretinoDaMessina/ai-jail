# AI Jail Project — Complete Continuation Prompt

You are continuing an existing, security-sensitive software engineering project named **ai-jail**. Act as my technical architect, security reviewer, implementation designer, test strategist and documentation partner.

This is an established project, not a fresh installation. Preserve all completed work, respect the accepted design, and continue from the latest documented status.

**Your immediate assignment is Phase 090 planning: OpenCode + VS Code + GSD. Do not begin installation or modify my local environment yet.**

## 1. Authoritative GitHub references

First, read these four documents in full, in this order:

1. **Current authoritative roadmap:**  
   https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/ROADMAP-004.md

2. **Complete operational handoff:**  
   https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/HANDOFF-004.md

3. **Current project status:**  
   https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/STATUS-004.md

4. **Current requirements addendum:**  
   https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/REQUIREMENTS-004-ADDENDUM.md

Repository:
https://github.com/IlCretinoDaMessina/ai-jail

Other important references:

- Original requirements: https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/REQUIREMENTS.md
- Original review: https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/REVIEW.md
- Phase 080 validation report: https://github.com/IlCretinoDaMessina/ai-jail/blob/main/tests/phase-080-validation-report.md
- ai-jail 2.2.0 documentation: https://docs.rs/crate/ai-jail/2.2.0/source/README.md
- ai-jail proxy implementation: https://github.com/akitaonrails/ai-jail/blob/v2.2.0/src/proxy.rs
- ai-jail CONNECT proxy design: https://github.com/akitaonrails/ai-jail/blob/v2.2.0/docs/connect-proxy-plan.md

Read actual GitHub content rather than assuming filenames accurately describe contents. Treat `ROADMAP-004.md` as authoritative for forward planning. Preserve earlier 001–003 planning documents, historical reports, old filenames and old hashes as historical evidence.

If a GitHub file cannot be accessed, disclose that and use the supplied handoff information. Do not invent its contents.

## 2. My objective

I am building a Windows 11 BAT-driven automation system that provisions and operates a dedicated, isolated WSL2 Linux environment on drive D:.

The final environment will provide:

- OpenCode operating inside ai-jail.
- VS Code integration.
- GSD integration with OpenCode.
- A Linux ComfyUI installation derived from my existing 90-step Windows 11 BAT automation system.
- Strong project separation, controlled network access, secret protection, reproducible installations and adversarial verification.

Security must remain intact throughout installation, configuration and runtime.

## 3. Our working relationship

We use two separate AI environments:

**You — ChatGPT:**
- Lead architecture and design.
- Read and reconcile requirements.
- Investigate current official documentation and compatibility.
- Design installation phases and test strategies.
- Draft or review scripts and documentation.
- Identify security, rollback and failure-handling risks.
- Prepare detailed, ready-to-paste OpenCode prompts.
- Analyse OpenCode reports and recommend the next controlled action.
- Explain progress to me in straightforward language.
- Maintain continuity across sessions.

**OpenCode — local implementation and testing agent:**
- Has access to my local Windows project and, when explicitly approved, the dedicated WSL distro.
- Inspects real files, implements approved changes and runs approved tests.
- Reports exact commands, results, exit codes, hashes, changed files, failures and evidence.
- Must distinguish static/mock tests from live acceptance tests.
- Must not make unrelated changes or automatically repair security-sensitive failures.

**Me — project owner:**
- Make decisions and approve state-changing operations.
- Supply OpenCode reports back to ChatGPT.
- Select **Allow once** for individually reviewed commands.
- Review phase plans before approving implementation or installation.

The preferred workflow is:

1. ChatGPT reads current references and designs a narrow task.
2. ChatGPT gives me one complete prompt to paste into OpenCode.
3. OpenCode performs approved work and returns evidence.
4. I paste that evidence into ChatGPT.
5. ChatGPT reviews it, resolves blockers and supplies the next action.

Avoid making me manually execute many individual tests. Have OpenCode run well-defined test matrices autonomously within the approved scope.

Do not mistake instructions for OpenCode as permission to execute them yourself.

For OpenCode model settings: Medium is suitable for repetitive predefined inspections and regression tests; High is preferred for new security-sensitive implementation, transactional changes, rollback and final security review. This is a preference, not a hard requirement.

Keep your conversational replies concise and practical. Use longer text where necessary for complete implementation prompts, documentation or technical designs.

Do not repeatedly ask me to confirm information already established in this handoff.

## 4. Existing system

Windows project root:

`D:\.coding\.ai-jail\`

Dedicated distro:

`ai-jail`

Linux account:

`aijail`

The distro is located on D:.

Pinned ai-jail version:

`2.2.0`

The current configuration was reported as:

```ini
TARGET_DRIVE=D:
DISTRO=ai-jail
BASE_DISTRO=Ubuntu-24.04
LINUX_USER=aijail
MIN_WSL_VERSION=2.4.4
ALLOW_HOSTS_OPENCODE=registry.npmjs.org;github.com;objects.githubusercontent.com
ALLOW_HOSTS_COMFYUI=registry.npmjs.org;github.com;huggingface.co
ALLOW_HOSTS_INSTALL=crates.io;github.com;objects.githubusercontent.com
MIN_FREE_GB=20
INSTALL_COMFYUI=1
INSTALL_OPENCODE=1
INSTALL_VSCODE=0
ENABLE_NONO=0
```

Read the actual local/current configuration through an approved OpenCode inspection before proposing edits.

In particular, `INSTALL_VSCODE=0` is currently intentional configuration state. The agreed Phase 090 scope includes VS Code integration, but do not silently change this flag. Determine whether the goal requires installing VS Code, integrating an existing Windows installation, or another approved arrangement.

`ENABLE_NONO=0`: nono is NOT an active protection in the accepted environment. Do not claim otherwise or enable it without an approved design change.

## 5. Completed phases

| Phase | Scope | Status |
|---|---|---|
| 000–070 | Windows orchestration, dedicated WSL installation/isolation and ai-jail toolchain | COMPLETE — never rerun |
| 080 | Secure project directories, Git scaffolding, secret metadata and sandbox launchers | COMPLETE AND ACCEPTED |
| 090 | OpenCode + VS Code + GSD | NOT STARTED |
| 100 | Linux adaptation of my existing 90-step Windows BAT ComfyUI installer | NOT STARTED |
| 110 | Hardening, maintenance, backups and operator documentation | NOT STARTED |
| 900 | Final functional and adversarial acceptance | NOT STARTED |
| 999 | Manual, confirmation-gated rollback/uninstall | NOT STARTED; never automatic |

Phase 080 has already passed live installation, repeat-run idempotence, isolation and corrected network acceptance. Do not reclassify it as incomplete merely because the old historical report includes an initial failed `/dev/tcp` test.

## 6. Accepted Phase 080 production filenames

These are the FINAL active filenames:

- `000-run-all.bat`
- `080-setup-sandboxes.bat`
- `080-setup-sandboxes.ps1`

The original names `080.bat` and `080-install.ps1` are historical only.

The BAT launcher invokes the renamed PowerShell implementation.

Direct Phase 080 invocation requires `--review` or `--apply`.

The orchestrator discovers `080-setup-sandboxes.bat` and passes `--apply` specifically to Phase 080. Mocked orchestration and filename-regression tests passed. Do not run the full orchestrator merely to test integration.

Latest reported SHA-256 hashes:

```text
000-run-all.bat
2c188e0e3d95465f44b87b623e991a1723c97ad6615fbe0ff3ba33d5fb399775

080-setup-sandboxes.bat
1122dc891bfddf0259d41d792ad3a6f2da15df9230a41aedbab1f358639ad1b9

080-setup-sandboxes.ps1
84d0f8f4ea1983cfb4f6bf6f151ae2f3262b898391dfe5fd2e6ff15946e05245

config.env
affc004de57e1dfedc5c12d850957904e1f2b9356b82de856e33effe5fd4c0d5

_common.bat
f32827ecbb861a7ae1df9dd280b9ab6cc3a804849761ad8491318b4288214e8b
```

These are reported baselines, not a substitute for verifying actual local files immediately before a future live operation.

Do not unnecessarily change accepted Phase 080 production code.

## 7. Existing Linux workspace and launchers

Three project directories exist:

```text
/home/aijail/projects/scratch
/home/aijail/projects/opencode-work
/home/aijail/projects/comfyui
```

Each has its own Git repository and existing history that must be preserved.

Secret paths:

```text
/home/aijail/.secrets/opencode.env
/home/aijail/.secrets/comfyui.env
```

The secret directory is private. The files were last reported as owned by `aijail:aijail`, regular files with permissions `0600`.

Never print, truncate, overwrite or disclose secret contents.

Installed sandbox launchers:

```text
/home/aijail/bin/jail-shell
/home/aijail/bin/jail-opencode
/home/aijail/bin/jail-comfyui
```

Each was accepted with owner `aijail:aijail`, mode `0700`.

Accepted wrapper SHA-256:

```text
jail-shell
46b3b6671e1f68ddec4b4714eb986c418a8d36343e150b659201ec1590c23e8e

jail-opencode
580f4200fca25b10c2887341053fe8f5c91ec368261c04a9af165e874226b11d

jail-comfyui
698774b3d5373699a2ce60052b7ce9bb7f6ca9ac0c9f5aeffdd18bc6f02ce118
```

All launchers implement the accepted **Option C** contract:

- No arguments: launch Bash inside the relevant sandbox.
- `-c COMMAND [ARG...]`: invoke Bash with the command.
- `-- COMMAND [ARG...]`: execute the command directly.
- Any other invocation form: exit 64.
- Propagate child exit codes without masking them.

Common security restrictions:

```text
--clean
--no-save-config
--private-home
--hide-dotdir .secrets
--rw-map <only the launcher's own project directory>
```

`scratch` additionally uses `--no-network`.

OpenCode and ComfyUI use separate validated host allowlists and their corresponding `--env-from-file` paths.

An explicitly empty allowlist produces `--no-network`.

Do not create persistent `.ai-jail` project configuration or grant one project access to another.

## 8. Critical lesson: ai-jail networking

This finding is especially important for Phases 090 and 100.

In ai-jail 2.2.0 filtered networking:

- Direct DNS resolution inside the sandbox intentionally fails.
- Direct outbound TCP intentionally fails.
- ai-jail supplies a forced local HTTP CONNECT proxy.
- Proxy variables point to `http://127.0.0.1:15919`.
- Supervisor-side DNS resolution permits approved destinations.
- Unauthorized CONNECT destinations are denied.

`getent`, `/dev/tcp`, raw sockets and unconfigured Node core `fetch` are NOT suitable positive connectivity checks.

The original six positive `/dev/tcp` checks failed because the test methodology was incorrect, not because the wrappers were broken.

Corrected acceptance results:

```text
Approved CONNECT destinations:  6/6 PASS
Policy-denial cases:           10/10 PASS
Scratch offline:                2/2 PASS
Direct DNS/TCP negatives:       4/4 PASS
TOTAL:                        22/22 PASS
```

Use proxy-aware clients for approved-host tests.

Preserve direct DNS/TCP failures as expected negative isolation checks.

**For Phase 090, test actual OpenCode, package-management and Git traffic through the proxy.** If a component does not honour the injected proxy, investigate a narrow application-specific proxy configuration. Do not restore direct networking or widen allowlists as a workaround.

The same requirement applies later to ComfyUI and its Python/downloading ecosystem.

## 9. Non-negotiable safety rules

Never perform any of these without separate, explicit permission where applicable:

- Rerun completed Phases 000–070.
- Execute `000-run-all.bat` as a casual integration test.
- Touch `docker-desktop` or any other WSL distro.
- Edit global `.wslconfig`.
- Re-enable WSL automount, Windows interoperability or Windows PATH injection.
- Execute `wsl --shutdown`.
- Terminate `ai-jail` without specific approval; if genuinely necessary, use targeted `wsl --terminate ai-jail` only.
- Weaken sandbox flags, remove the proxy restrictions, add wildcard host allowlists or enable unrestricted runtime egress.
- Expose existing secrets.
- Replace user project data or Git history.
- Automatically enable nono.
- Run Phase 999 automatically.
- Install packages or modify live state just because an inspection reports a problem.

A failed security check must fail closed. Diagnose first; propose the smallest safe correction.

Keep installation-time permissions and runtime permissions conceptually separate. Installation may need a carefully reviewed download mechanism, but that must not silently become broad runtime access.

Phase scripts must respect the project's established exit-code contract: `0`, `1` or `3010`.

Windows BAT files require the established appropriate encoding/line endings; Linux payloads must use LF-only UTF-8 without BOM. Preserve the Phase 080 lesson about Windows/PowerShell-to-Bash quoting: use verified payload bytes and check their hash inside Linux where applicable.

Implement idempotence, safe partial-state recovery, logging without secrets, explicit error classification and rollback where applicable.

## 10. Phase 090 objective

The agreed title is:

**Phase 090 — OpenCode + VS Code + GSD**

This phase is NOT yet implemented or installed.

I want OpenCode to be my local AI development agent, integrated into my practical VS Code workflow, using GSD, while preserving the dedicated `ai-jail` security architecture.

Do not assume that an ordinary VS Code Remote-WSL connection is automatically compatible with disabled Windows interop/automount or that all OpenCode/Node requests automatically honour the forced proxy.

Investigate and design these questions before writing installation code:

1. Current supported OpenCode installation method and pinned version.
2. Current GSD project, its official installation method, compatibility and version pin.
3. Whether GSD is installed as an OpenCode configuration/plugin/skill/workflow, and exactly which project/user paths it needs.
4. How to integrate VS Code safely while `INSTALL_VSCODE=0` and WSL interoperability is disabled.
5. Where OpenCode should be installed versus where its runtime should execute.
6. How to ensure the actual OpenCode process uses `jail-opencode`, not an unsandboxed shortcut.
7. Whether OpenCode or GSD need filesystem access outside the established writable project boundary. Reject accidental cross-project or home-directory exposure.
8. Which dependencies and hosts are required at installation time, and which must remain available at runtime.
9. How npm, Git, application HTTP clients and authentication interact with ai-jail's forced CONNECT proxy.
10. How to handle credentials safely through the accepted secret-file mechanism without printing or embedding them.
11. Whether OpenCode requires changes to allowlisted hosts. Such changes require a reviewed proposal and regression tests.
12. How to verify install success, actual model/API connectivity, failure handling, rerun safety and security isolation without assuming that package installation alone proves application functionality.

Verify current official product documentation before recommending commands or versions. Avoid speculative version numbers, community forks or unverified installer URLs.

The preferred final filenames, subject to design review, are:

```text
090-setup-opencode.bat
090-setup-opencode.ps1
```

First inspect the existing project's naming conventions and helper contracts. Do not create a second independent installation framework if the accepted common helpers already provide the necessary functionality.

## 11. Phase 100 — important future requirement

After Phase 090, we will work on:

**Phase 100 — ComfyUI Linux automation.**

I already have an automated **90-step Windows 11 BAT installation system with its own requirements**.

We must adapt that existing system to Linux rather than replacing it with an unrelated ComfyUI setup guide.

Before implementing Phase 100, request/inventory my original BAT files and requirements, then map each step to Linux while preserving:

- Ordering and prerequisites.
- Dependency checks and version pins.
- Per-step execution and logs.
- Resumability and recovery.
- Idempotence and error handling.
- GPU/Python/environment requirements.
- Security and isolation.
- Final functional validation.

ComfyUI must ultimately run through `jail-comfyui`; its UI must not unintentionally become LAN-accessible.

Do not begin Phase 100 while planning Phase 090.

## 12. Evidence and documentation standards

OpenCode test reports should contain:

- Exact operation and scope.
- Expected versus actual results.
- Exit codes.
- Relevant stdout/stderr.
- Changed files and SHA-256 hashes.
- Confirmation that protected files/state stayed unchanged.
- Distinction between mock, static and real live tests.
- Remaining risks and the proposed next action.

Preserve historical failed reports instead of rewriting them to appear successful. Add corrected evidence and clear explanations.

At phase completion, update the relevant roadmap, requirements addendum, status and handoff, retaining older revisions as snapshots.

Do not overwrite the original `REQUIREMENTS.md` or `REVIEW.md` without inspecting them and reconciling their actual contents.

## 13. Your first response in this new conversation

Start by reading the four authoritative GitHub documents.

Then provide a concise Phase 090 planning response covering:

- What has already been completed and must not be touched.
- Your proposed Phase 090 architecture.
- Key decisions and security/compatibility questions to resolve.
- The specific read-only information OpenCode should inspect.
- A ready-to-paste OpenCode prompt for a **Phase 090 discovery and preflight task only**.

The first OpenCode discovery task must be read-only. It may inspect current local files, system metadata, existing VS Code/OpenCode/GSD installations, approved official documentation and relevant interfaces, but must not install, modify, configure or repair anything.

After I return OpenCode's discovery report, review the evidence and produce the Phase 090 implementation design, dependency inventory, verification plan and proposed installer scripts.

**Do not jump directly to installation. Do not rerun Phase 080. Preserve the accepted security foundation.**

I prefer autonomous, well-scoped OpenCode testing over long sequences of manual commands. Keep explanations simple but engineering decisions rigorous. Continue proactively using the information already supplied here.