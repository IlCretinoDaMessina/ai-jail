# AI Jail — detailed recap since the warning-completion handoff

Prepared 6 October 2026. This recap distinguishes local source inspection, previously reported executed results and open decisions. It is not a new test report.

## Project purpose and working method

The project is a reproducible fresh-start installer, currently for Windows/WSL2, building a dedicated Linux environment for AI Jail isolation, network controls and intended applications/tooling. The old D:-backed `ai-jail` is preserved reference state, not an implicit installation dependency. Successful manual corrections must become maintained installer behavior. Final acceptance ultimately includes a clean rebuild and application/isolation checks, not merely a successful development-machine install.

The user operates the machine. This chat supplies files, commands and reviews. No tests or live installation were run while preparing this recap. Prior overall estimates such as “20–30% complete” or “70–80% remaining” were explicitly withdrawn as unsupported; do not repeat them.

## 1. Phase 000 and the Phase 010 engine defect

The Phase 000 D1/D2/D3 mock baseline was reported accepted. During real Phase 010 work, approval failed with a missing Sha256 property. Several investigations had focused on approval persistence, but the concrete defect was earlier: `Assert-Aij010EngineBootstrapSources` assigned a source collection to `$matches`, then a regex operation overwrote the case-insensitive automatic `$Matches` variable. A later `.Sha256` dereference read the wrong object.

The engine fix renamed the local collection to `$sourceEntries` at four references. The engine replacement SHA-256 is `BC253AD228C44DEB0E616961EDA7C4C9E57A356A2C7C1063EE1F8F1C6FB15E44`. It preserves validation logic but necessarily changes source identity. Old bound plans were not reusable. A later engine-bootstrap fixture suite reportedly passed 28 assertions through the real script entry context.

Lesson retained: locate the actual failing statement and entry path before patching. In-memory tests or preloaded functions alone can miss cold engine behavior. Do not spend successive turns guessing at constructors or unrelated persistence functions.

## 2. Pending-reboot detour and policy correction

Live Phase 010 observed CBS=false, Windows Update reboot-required=false and PendingFileRenameOperations=true. Two displayed source entries were a Gaming Services proxy DLL and a WRP temporary path, each paired with an empty destination. Their relationship and effect on WSL were not established.

The other chat proposed Gaming Services repair/removal/reinstallation. This was stopped as unrelated scope: AI Jail does not require Gaming Services, and a generic pending-file indicator does not prove WSL cannot work. No assumption that WRP was harmless was authorized. Do not resume Gaming Services remediation or delete registry/WindowsApps state.

The original core failed local eligibility for every selected reboot indicator. Connectivity then did not run. Merely renaming FAIL to WARN would not change that gate, and withholding all completion evidence would leave downstream read-only progression blocked.

## 3. Discarded patch and replacement package

An earlier patch was rejected before use. It contained literal backtick-newline replacements, an incomplete real evidence-consumption path, weak isolated document checks, inadequate workflow tests and incomplete patch-write recovery. It also changed Phase 000 mock dependency rules without establishing real progression.

The replacement package was created from verified full local files. It supplied:

- `010-preflight-core.ps1`: classify complete pending-file-only observations as WARN, preserve counts/aggregate SHA-256 instead of raw paths, and permit bounded online observation without manufacturing clean eligibility.
- `010-boundary.ps1`: allow stable warning completion through fresh verification and durable receipt creation; introduce a full on-disk completion consumer.
- `010-warning-completion.tests.ps1`: exercise real PLAN, approval, execution, persistence and consumer functions in a temporary fixture with external observations mocked, including negative cases.
- `020-verified-wsl-check.ps1`: explicitly consume valid Phase 010 evidence and, when separately invoked without EvidenceOnly, run the reviewed original Phase 020 version check.

The package leaves Phase 000 generic dependency rules and original Phase 020 source/requirements unchanged. It is an explicit read-only route, not integration of every future production phase. Production installation remains blocked.

Warning semantics: verified warning-only evidence emits `010 PREFLIGHT_COMPLETE`, never `010 RUNTIME_PASS`; installation authorization remains false. The consumer rechecks source/config/requirements/host/volume/boot/PLAN identities, recomputed decisions, freshness, consumed approval, receipt and audit chain. Both passes must preserve the same warning observation. Clean results retain `010 RUNTIME_PASS`.

## 4. Reported verification and real sessions

The user-provided recap states all installed replacement hashes matched and these offline results passed:

| Evidence | Reported result |
| --- | --- |
| Warning-completion fixtures | 36 assertions, pass |
| Engine-bootstrap fixtures | 28 assertions, pass |
| Phase 010 A fixtures | 100 assertions, pass |
| Phase 010 B fixtures | 103 assertions, pass |
| Phase 000 retained full regression | DELIVERABLE_3_ACCEPTANCE_OK, PHASE_000_MOCK_ACCEPTANCE_OK, exit 0 |

These are prior user-reported executions, not reruns by this chat.

Preserve every historical session, especially:

- -002 and -003: early failed-approval/source-baseline history; do not reuse their plans.
- -005: approval consumed, pending marker present, collection persisted, no completed verification/receipt. Original interruption remains unexplained. A diagnostic process search matched its own command line, which was not evidence of a still-running installer. No source change was justified solely by that incident.
- -006: reported real warning collection/verification/receipt completed with exit 0, two authorized network observations, no pending marker, `010 PREFLIGHT_COMPLETE`, and successful EvidenceOnly consumer admission.
- -007: preserve; exact outcome is not established in this handoff.
- -008: clean runtime-pass reference. Directly read operator transcript at `D:\.coding\.ai-jail\phase010-session-online-008.operator-execution.txt` records capture 2026-10-06 14:24:20Z–14:24:28Z, `010 RUNTIME_PASS`, `PRE010_EXECUTE_EXIT=0` and APPLY blocked. Its operation identifier is `ec7701560e8b404bbc09619412b23290`.

The -008 collection, verification and receipt filenames exist under its evidence directory. This recap did not revalidate those artifacts against current state or freshness. Historical success remains useful even when the five-minute admission window has expired; expired evidence is not fresh authorization.

## 5. Phase 020 reached the real WSL query

User-provided output summary reports the separately gated check completed with installed WSL 2.7.14.0 versus minimum 2.4.4, requirements/admin/version checks PASS, and `PHASE_020_WSL_CHECK_EXIT=0`. No distro access, installation, update or shutdown was reported.

The local -008 operator transcript named above stops at Phase 010; it does not contain this Phase 020 output. Retain the separate console evidence once if available. Do not restart all previous work because it is not embedded in that file.

What is established: a successful version query on this host was reported. What is not established: distro startup, app performance, isolation correctness, durable bound Phase 020 prerequisite state for Phase 030, or authorization to create a new distro.

## 6. Current Phase 030 state — directly inspected

Full local `030-create-distro.ps1`, `.bat`, requirements and config were read for this handoff. Phase 030 remains review-only; installation and production modification flags are false. Current code inspects current-user registry registration, destination/VHDX state and, on the existing-registration branch, executes `wsl.exe --list --verbose`. Its BAT wrapper can auto-elevate standalone. Its configuration parser is separate from the authoritative Phase 000 parser.

The new intended REVIEW contract is stricter: offline local inspection, no WSL invocation or automatic elevation. These are concrete implementation changes to specify, not behaviors already present.

Current config says C: plus `DISTRO=ai-jail`, deriving `C:\ai-jail\wsl`. This still collides with the known existing per-user registration regardless of where a new folder is placed. The user-supplied design is `ai-jail-fresh` at `C:\ai-jail-fresh\wsl`; no configuration edit or creation was performed here. Respect prior human approval if available, otherwise settle that pair once.

The current install-command text resolves a distro by name. The agreed creation contract instead requires consumption of an exact verified staged artifact, so requirements and command selection must change together. No actual Phase 030 replacement has been produced in this documentation turn.

## 7. Artifact and prerequisite corrections

A proposed Canonical dated Noble image at `https://cdimage.ubuntu.com/ubuntu-wsl/noble/daily-live/20260908/` was verified to be labeled Daily Build. It must not be called a stable release or treated as approved just because a dated URL and checksum exist. The stable-release requirement remains unless the human explicitly approves an exception. Do not silently move to another Ubuntu major/LTS series either.

Official Ubuntu documentation checked in the prior exchange describes `.wsl` support as requiring WSL 2.4.10 or higher. Verify this and exact option support again when choosing the final command/artifact; do not assume the old global minimum 2.4.4 is sufficient. Pin source identity and verified content; preserve/reacquire the same bytes for rebuilds. A dated remote URL is not a permanent archival guarantee.

Reference: https://ubuntu.com/wsl/docs/latest/howto/install-ubuntu-wsl2/

The provided source set on GitHub was reportedly mixed: some engine/BAT copies lacked the working live routes. Prefer complete current local files and hashes, including `_common.bat` and `010-boundary.ps1`. Do not reconstruct from the old ZIP or guessed raw URLs.

## 8. WSL workload feasibility question

The user raised ComfyUI, llama.cpp RAM offload and Strata concerns before further investment. Prior research confirmed ComfyUI's pinned-memory CUDA calls and flags; NVIDIA documents WSL pinned-memory limitations. A ComfyUI report describes a workaround using --disable-pinned-memory. The early DynamicVRAM announcement's WSL warning is not the whole current story: later code/report history describes re-enabling DynamicVRAM on WSL.

Strata's multi-GPU guide documents its own WDDM/WSL pinning cap and staging behavior; do not present that project-specific cap as a universal CUDA limit. Some detailed figures/comments in the quoted ComfyUI report were not independently verified. Individual reports are not a prediction for this user's hardware.

Sources reviewed previously:

- https://docs.nvidia.com/cuda/wsl-user-guide/index.html
- https://github.com/Comfy-Org/ComfyUI/blob/master/comfy/pinned_memory.py
- https://github.com/Comfy-Org/ComfyUI/blob/master/comfy/cli_args.py
- https://github.com/Comfy-Org/ComfyUI/discussions/12699
- https://github.com/Comfy-Org/ComfyUI/issues/11531
- https://github.com/Comfy-Org/ComfyUI/issues/15679
- https://github.com/Niko1221/Strata/blob/main/docs/MULTI_GPU.md

A small separate scratch trial was recommended, not executed or authorized. Necessary missing data include the user's GPU/VRAM/RAM, exact workloads and available model files, plus the selected scratch name/path. Avoid guessing these from a cited GitHub reporter's 4090/64-GB machine.

Native Linux can reuse Linux-side design and application work but cannot run the Windows/WSL installer unchanged. A separate Linux partition gives native execution only when booted into Linux. No credible porting-time estimate was established. Keep deployment-specific code narrow, without promising a cheap automatic port.

## Next outcome sought

Choose whether to do the bounded feasibility trial first. Otherwise finalize the current-source-grounded Phase 030 contract and deliver the smallest implementation that safely creates and verifies the intended fresh distro. Retain one-use exact approval, source/artifact/account/path checks and explicit interruption handling, without turning them into another broad framework. Progress toward real creation after relevant tests, then later application/isolation verification and a clean rebuild.
