Phase 090 Initial Inspection Report
No files were modified, no packages installed, no setup phase or test suite executed, no WSL restart performed, and no secret contents inspected. Windows npm paths remained inaccessible.
Current State
- Phases 000–070 are accepted and must not be rerun.
- Phase 080 is accepted and complete.
- Phase 090 has no implementation files and is not started.
- The validation report’s initial INCOMPLETE status is historical. Its post-apply addendum records final acceptance at .planning/phase-080-validation-report.md:887-983.
- .planning/REVIEW.md is a historical Phase 1 review, not a Phase 080/090 review. Its nine findings were fixed; deferred issue D1 remains relevant because _common.bat :load can inherit ambient variables when config keys are absent (.planning/REVIEW.md:24-33).
- Current flags remain:
- INSTALL_OPENCODE=1
- INSTALL_VSCODE=0
- INSTALL_COMFYUI=1
- ENABLE_NONO=0
Evidence: config.env:26-30.
The 004 documents supersede the old future-phase allocation in REQUIREMENTS.md: Phase 090 now owns OpenCode, GSD and VS Code integration; ComfyUI belongs to Phase 100 (.planning/REQUIREMENTS-004-ADDENDUM.md:7-13).
Baseline Verification
All documented Windows SHA-256 values match the current files byte-for-byte:
File
000-run-all.bat
080-setup-sandboxes.bat
080-setup-sandboxes.ps1
config.env
_common.bat
080-review-gates.md
.planning/phase-080-validation-report.md
The last digest applies to the report under .planning. No root or tests copy exists. Documentary baseline: .planning/ROADMAP-004.md:28-38.
All three installed Linux wrapper baselines also match:
Wrapper	Verified SHA-256
jail-shell	46b3b6671e1f68ddec4b4714eb986c418a8d36343e150b659201ec1590c23e8e
jail-opencode	580f4200fca25b10c2887341053fe8f5c91ec368261c04a9af165e874226b11d
jail-comfyui	698774b3d5373699a2ce60052b7ce9bb7f6ca9ac0c9f5aeffdd18bc6f02ce118
Additional live verification:
- ai-jail reports exactly 2.2.0.
- All three project directories remain 0755 aijail:aijail.
- All three project Git HEADs remain b128d2a03c0dede852982196c0819cb810d45e24.
- No secret file was read or hashed.
These match .planning/ROADMAP-004.md:44-50.
Technical Inventory
Orchestrator
000-run-all.bat:
- Discovers root NNN-*.bat files dynamically (000-run-all.bat:87-107).
- Excludes phases 000 and 999.
- Enforces exit statuses 0, 1, and 3010 (000-run-all.bat:134-156).
- Passes --apply only to the exact 080-setup-sandboxes stem (000-run-all.bat:123-129).
- A future Phase 090 currently receives no arguments.
- Since no 090+ scripts exist, a present-day orchestrator run could report success after 080 even though the project is incomplete.
The real orchestrator was not run.
Phase 080
Phase 080 provides:
- Exact config schema validation, rejecting missing, duplicate and unknown keys (080-setup-sandboxes.ps1:10-32).
- Strict hostname validation with wildcard, IP-literal and duplicate rejection (080-setup-sandboxes.ps1:34-52).
- Empty allowlist conversion to --no-network (080-setup-sandboxes.ps1:70-73).
- LF-only, SHA-256-verified WSL payload transport (080-setup-sandboxes.ps1:74-135).
- Transactional wrapper generation and promotion.
- Option C wrapper parsing and own-project mapping (080-setup-sandboxes.ps1:439-460).
ALLOW_HOSTS_INSTALL is parsed at line 436 but is otherwise unused. It currently provides no installation policy.
All install flags are validated but do not gate wrapper generation. They are future-facing configuration inputs, not active feature switches.
Runtime Boundary
jail-opencode currently:
- Changes to /home/aijail/projects/opencode-work.
- Uses --clean --no-save-config --private-home.
- Hides .secrets.
- Maps only opencode-work writable.
- Injects only /home/aijail/.secrets/opencode.env.
- Allows registry.npmjs.org, github.com, and objects.githubusercontent.com.
- Requires -- COMMAND ... for direct execution; invoking it without arguments opens Bash.
Evidence: 080-setup-sandboxes.ps1:439-460 and .planning/ROADMAP-004.md:52-54.
No production launcher currently invokes an OpenCode binary through this wrapper.
Current Tool State
Inside ai-jail:
- which opencode exited 1.
- which gsd exited 1.
- Node: v24.21.0.
- npm: 11.19.0.
- Git: 2.43.0.
Therefore OpenCode and GSD are not available on the distro PATH. No repair or broader filesystem search was attempted.
Windows command resolution previously identified an OpenCode npm shim and a VS Code command, but:
- Windows-host OpenCode package identity: unverified.
- Windows-host OpenCode version: unverified.
- VS Code version and WSL extension state: unverified.
- No Windows npm file or package metadata was inspected.
WSL Isolation
The current /etc/wsl.conf was read and contains:
[boot]
systemd=true

[automount]
enabled=false
mountFsTab=false

[interop]
enabled=false
appendWindowsPath=false

[user]
default=aijail
Additional checks:
- findmnt -rn -t drvfs exited 1: no drvfs mount was found.
- which cmd.exe exited 1.
- which powershell.exe exited 1.
- test ! -e /mnt/c exited 1.
- test ! -e /mnt/d exited 1.
Thus /mnt/c and /mnt/d currently exist as paths, but there is no evidence they are mounted as Windows drives. The approved commands did not establish whether those directories are empty. The production gate tests mount status and drvfs, not mere path existence (040-wsl-conf.bat:105-135).
No global .wslconfig, other distro, restart, shutdown or termination operation was performed.
Security Finding: start-opencode.bat
start-opencode.bat is currently an unsecured bypass:
cd /d "D:\.coding\.ai-jail"
opencode -m openai/gpt-5.6-sol
Evidence: start-opencode.bat:2-7.
It:
- Executes Windows OpenCode directly.
- Does not enter the ai-jail distro.
- Does not invoke jail-opencode.
- Has ordinary Windows filesystem and network access.
- Opens the Windows project rather than /home/aijail/projects/opencode-work.
opencode.json:3-10 adds OpenCode permission prompts, but those are application-level controls, not OS confinement.
No modification was made. Phase 090 must not represent this launcher as secure. It should eventually be replaced, deprecated, or accompanied by an unambiguous secured launcher only after explicit approval.
Networking Findings
ai-jail 2.2.0 filtered mode:
- Creates a network namespace without direct DNS or ordinary outbound routing.
- Forces HTTP/HTTPS/ALL proxy variables to http://127.0.0.1:15919.
- Forces NO_PROXY empty.
- Resolves CONNECT hostnames in the supervisor.
- Rejects direct IP, loopback, LAN and unsafe resolved addresses.
- Fails closed for proxy-unaware clients.
Evidence: .planning/phase-080-validation-report.md:903-916.
The persistent network harness correctly distinguishes:
- Proxy-aware positive controls (tests/verify-080-network.ps1:32-49).
- Denied CONNECT targets (tests/verify-080-network.ps1:78-88).
- Scratch-offline checks (tests/verify-080-network.ps1:90-92).
- Direct DNS/TCP negative controls (tests/verify-080-network.ps1:94-98).
The accepted result was 22/22 PASS (.planning/phase-080-validation-report.md:918-970). This proves curl-level policy, not actual OpenCode compatibility.
Installation-Time Network
Installation must use a separate temporary policy derived only from ALLOW_HOSTS_INSTALL. It must not reuse or widen the permanent runtime wrapper.
Current ALLOW_HOSTS_INSTALL is:
crates.io;github.com;objects.githubusercontent.com
It is inadequate for a normal npm installation because it omits registry.npmjs.org. Additional GSD hosts are unknown and must be derived from its selected official distribution method. No host should be added speculatively.
Runtime Network
The current OpenCode runtime list has no evident model-provider endpoint. The existing Windows launcher selects an OpenAI model, but api.openai.com is not allowed.
Required runtime hosts must be determined from the selected OpenCode authentication/provider mode and then separately reviewed. Installation hosts must never leak into runtime merely for convenience.
Proposed Phase 090 Architecture
Installer
Proposed files:
- 090-setup-opencode.bat
- 090-setup-opencode.ps1
- tests/verify-090-static.ps1
- tests/verify-090-install.ps1
- tests/verify-090-runtime.ps1
- tests/verify-090-run-all-integration.cmd
Recommended behavior:
 1. Use Phase 080-style exact PowerShell config parsing, not permissive _common.bat :load.
 2. Require explicit --review or --apply.
 3. Add mocked orchestrator forwarding before changing 000-run-all.bat.
 4. Build installation network arguments exclusively from ALLOW_HOSTS_INSTALL.
 5. Run download/package execution inside ai-jail without injecting runtime credentials.
 6. Stage into a dedicated writable directory with private home and no persistent .ai-jail.
 7. Pin exact OpenCode and GSD versions plus package integrity/checksums.
 8. Verify staged versions and integrity before promotion.
 9. Promote tools to an installer-managed, runtime-read-only versioned location, preferably outside the agent-writable project.
10. Preserve all Phase 080 wrappers and projects unless an approved runtime-host change requires a documented new jail-opencode hash.
Avoid floating latest, npx -y, mutable branches and curl | shell.
Runtime
The secured Windows entry point should invoke an absolute Linux binary path:
wsl.exe -d ai-jail -u aijail -e \
  /home/aijail/bin/jail-opencode -- \
  /opt/ai-jail-tools/opencode/<pinned-version>/opencode
The exact path remains a design decision. The important properties are:
- Actual execution always crosses jail-opencode.
- No reliance on Windows OpenCode or Windows PATH.
- No ordinary WSL shell fallback.
- No PATH-based binary substitution.
- OpenCode autoupdate disabled.
- Persistent state deliberately mapped into opencode-work; private-home state is otherwise disposable.
- Real OpenCode model traffic tested through CONNECT.
GSD
GSD requires:
- Official project identity.
- Exact release or commit pin.
- Integrity evidence.
- Supported OpenCode integration mechanism.
- A clear distinction between read-only GSD workflow code and writable .planning output.
A preferred design is read-only, versioned GSD content under the managed tool directory, referenced through OpenCode’s supported skills/config mechanism. Writable planning output remains in opencode-work.
The Windows-host GSD/OpenCode configuration cannot be reused automatically: Windows drives are not mounted, and private home hides normal Linux user configuration.
VS Code
With INSTALL_VSCODE=0:
- Phase 090 must not install or update VS Code.
- Existing Windows VS Code may be treated only as a trusted Layer-1 editor.
- Windows may initiate WSL access; Linux-to-Windows interop must remain disabled.
- OpenCode must not run as an ordinary Remote-WSL terminal process.
- A VS Code task may later call the secured Windows launcher, subject to approval.
- A Remote-WSL server runs outside ai-jail as aijail; it can potentially access the wider Linux home, secrets and unrestricted WSL networking. It must not be described as sandboxed.
- If Remote-WSL cannot connect with the current isolation, document the limitation rather than enabling interop, automount or Windows PATH injection.
Required Verification
Phase 090 acceptance should cover:
- Exact OpenCode and GSD version/integrity.
- Clean install, repeat install and interrupted-state recovery.
- Bad checksum and failed-download rollback.
- Existing Git/project/secret preservation.
- npm and Git installation traffic through CONNECT.
- Actual OpenCode startup and model/API request through CONNECT.
- Actual GSD loading and project-local planning output.
- Denied hostname through the same application client.
- Direct IP, LAN, loopback, DNS, raw TCP and proxy-bypass negatives.
- Correct project directory and own-project-only writes.
- Cross-project read/write denial.
- Hidden .secrets and no secret-value logging.
- Private-home and read-only system behavior.
- No project .ai-jail.
- No installation hosts retained at runtime.
- No use of --network.
- Exact 0/1/3010 phase status behavior.
- Phase 080 wrapper/hash regression, documenting any explicitly approved jail-opencode policy change.
Do not run tests/verify-all.cmd casually: tests/verify-preflight.cmd:217 invokes the real root orchestrator and could execute production phases on an elevated shell.
Risks
- High: start-opencode.bat bypasses all WSL and ai-jail controls.
- High: no actual OpenCode or GSD runtime exists inside the distro.
- High: runtime provider endpoints are absent from the current allowlist.
- High: actual OpenCode proxy compatibility remains unproved.
- High: a Remote-WSL VS Code server would run outside ai-jail.
- Medium: forced-empty NO_PROXY may interfere with an OpenCode local client/server loop.
- Medium: installing tools into the writable project would let the agent modify its own executable or GSD workflow.
- Medium: credentials injected into the jail environment are readable by OpenCode and its subprocesses.
- Medium: hostname policy permits subdomains and is not path/content scoped.
- Medium: ALLOW_HOSTS_INSTALL is validated but currently unused and incomplete.
- Medium: Node was installed through an earlier unpinned “LTS” mechanism; compatibility with the selected OpenCode pin must be checked without rerunning Phase 060.
- Low: /mnt/c and /mnt/d exist as paths, although no drvfs mount was found; emptiness was not checked.
- Low: original requirements and traceability remain stale relative to the 004 phase split.
Unresolved Decisions
 1. Exact OpenCode version, npm package identity and integrity pin.
 2. Exact GSD project, version and supported OpenCode integration.
 3. Required installation host inventory.
 4. Required model-provider runtime hosts.
 5. Whether OpenCode works with forced CONNECT and empty NO_PROXY.
 6. Managed tool installation/promotion path.
 7. Persistent OpenCode config, cache and session locations.
 8. Whether jail-opencode needs a reviewed allowlist change.
 9. Whether to replace start-opencode.bat or add a distinct secure launcher.
10. Whether existing Windows VS Code integration is desired while installation remains disabled.
11. Whether the orchestrator should explicitly forward --apply to Phase 090, which would change the verified 000-run-all.bat baseline.
12. How ALLOW_HOSTS_INSTALL should be reconciled with Phase 100 now that ComfyUI installation moved out of Phase 090.
Inspection complete. Stopping for review.