# Phase 090 Architecture Proposal - OpenCode, GSD, and optional VS Code integration

**Date:** 2026-10-02  
**Status:** PROPOSED FOR REVIEW; no Phase 090 implementation or installation is authorized by this document.  
**Authority:** Read with `ROADMAP-004.md`, `REQUIREMENTS-004-ADDENDUM.md`, `STATUS-004.md`, `HANDOFF-004.md`, and `Phase 090 Initial Inspection Report.md`.

## Classification

| Label | Meaning |
|---|---|
| **VERIFIED** | Established from the accepted local baseline, a read-only local inspection, or cited authoritative upstream metadata. |
| **PROPOSED** | Recommended design that requires review and implementation approval. |
| **UNVERIFIED** | Cannot be established without an approved implementation or live test. It is not an accepted capability. |

## 1. Baseline and source references

### Accepted local baseline

- **VERIFIED:** Phases 000-070 are complete and must not be rerun. Phase 080 is complete and accepted. Phase 090 is not started (`ROADMAP-004.md:12-22`, `STATUS-004.md:3-7`).
- **VERIFIED:** Phase 090 owns OpenCode, GSD, and editor integration. Phase 100 separately owns the Linux adaptation of the user's existing ComfyUI workflow (`REQUIREMENTS-004-ADDENDUM.md:7-13`).
- **VERIFIED:** Installation-time privileges and hosts must be reviewed separately from runtime policy (`REQUIREMENTS-004-ADDENDUM.md:15-24`).
- **VERIFIED:** `INSTALL_OPENCODE=1`, `INSTALL_VSCODE=0`, `INSTALL_COMFYUI=1`, and `ENABLE_NONO=0` (`config.env:24-30`). This proposal does not change those values.
- **VERIFIED:** ai-jail 2.2.0 filtered networking injects an HTTP CONNECT proxy at `127.0.0.1:15919`, forces `NO_PROXY` empty, and intentionally denies direct DNS and direct outbound TCP (`ROADMAP-004.md:40-42`, `HANDOFF-004.md:32-34`).
- **VERIFIED:** The accepted `jail-opencode` wrapper maps only `/home/aijail/projects/opencode-work` writable, uses a private home, hides `.secrets`, and injects `/home/aijail/.secrets/opencode.env` (`ROADMAP-004.md:52-54`; initial inspection report lines 58-67).
- **VERIFIED:** OpenCode and GSD are absent from the distro PATH. Node `v24.21.0`, npm `11.19.0`, and Git `2.43.0` are present (initial inspection report lines 69-76).
- **VERIFIED:** `start-opencode.bat` currently runs the Windows `opencode` command directly and bypasses the WSL/ai-jail boundary (`start-opencode.bat:1-8`; initial inspection report lines 105-117).
- **VERIFIED:** `000-run-all.bat` dynamically discovers phases but forwards `--apply` only to `080-setup-sandboxes` (`000-run-all.bat:87-129`).
- **VERIFIED:** Windows automount, Linux-to-Windows interop, and Windows PATH propagation are disabled. They are immutable security boundaries for this phase (`ROADMAP-004.md:6-10`; initial inspection report lines 82-104).

### Accepted hashes that Phase 090 must preserve or explicitly supersede

| Item | Accepted SHA-256 |
|---|---|
| `000-run-all.bat` | `2c188e0e3d95465f44b87b623e991a1723c97ad6615fbe0ff3ba33d5fb399775` |
| `080-setup-sandboxes.bat` | `1122dc891bfddf0259d41d792ad3a6f2da15df9230a41aedbab1f358639ad1b9` |
| `080-setup-sandboxes.ps1` | `84d0f8f4ea1983cfb4f6bf6f151ae2f3262b898391dfe5fd2e6ff15946e05245` |
| `config.env` | `affc004de57e1dfedc5c12d850957904e1f2b9356b82de856e33effe5fd4c0d5` |
| `_common.bat` | `f32827ecbb861a7ae1df9dd280b9ab6cc3a804849761ad8491318b4288214e8b` |
| `/home/aijail/bin/jail-shell` | `46b3b6671e1f68ddec4b4714eb986c418a8d36343e150b659201ec1590c23e8e` |
| `/home/aijail/bin/jail-opencode` | `580f4200fca25b10c2887341053fe8f5c91ec368261c04a9af165e874226b11d` |
| `/home/aijail/bin/jail-comfyui` | `698774b3d5373699a2ce60052b7ce9bb7f6ca9ac0c9f5aeffdd18bc6f02ce118` |

Source: `ROADMAP-004.md:28-50`. Any approved change to `000-run-all.bat`, `config.env`, or `jail-opencode` must record old and new hashes; unchanged Phase 080 files and wrappers must remain byte-identical.

### Authoritative upstream sources

- OpenCode repository: <https://github.com/anomalyco/opencode>
- OpenCode `v1.18.34` release: <https://github.com/anomalyco/opencode/releases/tag/v1.18.34>
- OpenCode release API: <https://api.github.com/repos/anomalyco/opencode/releases/tags/v1.18.34>
- OpenCode package metadata: <https://registry.npmjs.org/opencode-ai/1.18.34>
- OpenCode network documentation: <https://opencode.ai/docs/network/>
- OpenCode configuration documentation: <https://opencode.ai/docs/config/>
- OpenCode server documentation: <https://opencode.ai/docs/server/>
- GSD repository: <https://github.com/open-gsd/gsd-core>
- GSD tag reference: <https://api.github.com/repos/open-gsd/gsd-core/git/ref/tags/v1.15.0>
- GSD package metadata: <https://registry.npmjs.org/@opengsd%2Fgsd-core/1.15.0>
- GSD OpenCode capability: <https://raw.githubusercontent.com/open-gsd/gsd-core/v1.15.0/capabilities/opencode/capability.json>
- GSD runtime installation guide: <https://raw.githubusercontent.com/open-gsd/gsd-core/v1.15.0/docs/how-to/install-on-your-runtime.md>
- Reported ai-jail/OpenCode standalone issue: <https://github.com/akitaonrails/ai-jail/issues/137>
- VS Code WSL documentation: <https://code.visualstudio.com/docs/remote/wsl>

## 2. Version and dependency matrix

| Component | Proposed immutable pin | Integrity / identity | Decision |
|---|---|---|---|
| ai-jail | Existing `2.2.0` | Accepted Phase 080 installation | **VERIFIED:** preserve; do not update in Phase 090. |
| OpenCode CLI | `v1.18.34` | Tag commit `aec0b9a6d8898f68f923aaf08b7306d931fd9d76` | **PROPOSED:** pin this exact release, not `latest`. |
| OpenCode Linux x64 baseline archive | `opencode-linux-x64-baseline.tar.gz` | SHA-256 `24b0d458d21ef548b2752166303defcf7f4945b049fb4876ab78dfaf86d81b27`; 60,665,421 bytes | **PROPOSED:** preferred artifact because the baseline build has the widest x64 CPU compatibility. |
| OpenCode standard Linux x64 archive | `opencode-linux-x64.tar.gz` | SHA-256 `0f22479647226d1d2dd99595d20082ee7bda3870b62dc6a90b41efc1a71d7e9a`; 60,665,582 bytes | **VERIFIED alternative:** do not select unless CPU compatibility is explicitly established. |
| OpenCode npm wrapper | `opencode-ai@1.18.34` | npm integrity `sha512-9WUS2T0t4HHDVzXvuwTHF0nvhXvZ9mQ0r+ozCvKdJu0LVoQpOzqAW4qWTC3ygNc5Oedcc7j+Oct24JYlQYnySA==` | **REJECTED for installation:** package has a postinstall script and platform optional-dependency selection; the direct immutable release asset has a smaller dependency and execution surface. Metadata remains corroborating evidence. |
| GSD Core | `@opengsd/gsd-core@1.15.0` | Tag/package commit `b10ab3fdeb6274b373859ccd6e99b7e1cf17388e`; npm integrity `sha512-GwdlJeupozyM22g2INdxiNfkpDm5hFS7G42leRqQwHb/0BclBG3TpgyGtWIkf47shjkfGRtrK5iK+pPZ61DvMA==` | **PROPOSED:** exact package pin. The old `gsd-build/get-shit-done` repository is not the selected source. |
| Node.js | Existing `v24.21.0` | Read-only local version check | **VERIFIED:** satisfies GSD package requirement `>=24.0.0`; do not reinstall. |
| npm | Existing `11.19.0` | Read-only local version check | **VERIFIED:** satisfies GSD package requirement `>=10.0.0`; do not reinstall. |
| Git | Existing `2.43.0` | Read-only local version check | **VERIFIED:** preserve; no Phase 090 update. |
| VS Code | Existing Windows installation, version unknown | Not inspected | **UNVERIFIED / optional:** Phase 090 must not install or update it while `INSTALL_VSCODE=0`. |

OpenCode's release API reports an immutable `v1.18.34` release. The API's `target_commitish` is not the immutable tag object and must not be used as the source pin. The exact tag object is the pin above.

The OpenCode documentation announces a v2 line while the researched stable GitHub release/package is `1.18.34`. **PROPOSED:** select `1.18.34` for this phase because its immutable artifact is established and the reported ai-jail issue specifically raises v2 compatibility concerns. A later v2 migration is a separate reviewed change, not an implicit update.

GSD declares runtime dependencies `@anthropic-ai/claude-agent-sdk:^0.2.84`, `ws:^8.21.0`, and optional `fallow:^2.70.0`. **PROPOSED:** implementation must generate and review a lockfile that resolves every transitive package to an exact version and integrity. Installing directly from the package's floating ranges without a reviewed lock is not acceptable.

## 3. Installation-host inventory

Installation traffic must run only in a temporary installation sandbox. It must never reuse the permanent `jail-opencode` runtime policy.

| Host | Purpose | State |
|---|---|---|
| `github.com` | Exact OpenCode release URL and redirects | **PROPOSED.** Already present in `ALLOW_HOSTS_INSTALL`. |
| `release-assets.githubusercontent.com` | Expected GitHub release-asset data host | **PROPOSED / must be confirmed from the actual approved download redirect before apply.** It is not currently configured. |
| `registry.npmjs.org` | Exact GSD tarball and locked npm dependencies | **PROPOSED.** It is not currently in `ALLOW_HOSTS_INSTALL`. |
| `objects.githubusercontent.com` | Existing configured GitHub object host | **UNVERIFIED as necessary for this design.** Keep only if a recorded approved request proves it is used. |
| `crates.io` | Existing Phase 100-oriented install host | **Not needed by Phase 090.** Do not infer Phase 090 permission from its current presence. |

**PROPOSED:** split phase-specific installation policy rather than broadening one permanent list for unrelated phases. The minimal change is to add a dedicated `ALLOW_HOSTS_INSTALL_OPENCODE` key and leave `ALLOW_HOSTS_INSTALL` untouched for later reconciliation. If the project requires one shared installation list, approval must explicitly accept its cross-phase scope.

No CDN, telemetry, update, model-provider, package mirror, or wildcard host may be added speculatively. Redirects must be logged as hostnames only, with URL query strings and credentials redacted.

## 4. Runtime-host inventory

The current `ALLOW_HOSTS_OPENCODE=registry.npmjs.org;github.com;objects.githubusercontent.com` is an installation-shaped list and has no model-provider endpoint (`config.env:17-22`). It must not become the production runtime policy by accident.

| Host | Purpose | State |
|---|---|---|
| `api.openai.com` | OpenAI model API selected by the current launcher model `openai/gpt-5.6-sol` | **PROPOSED, pending provider approval and a credential-name-only preflight.** |
| `registry.npmjs.org` | Package installation/update | **PROPOSED removal from runtime.** |
| `github.com` | Release/update checks | **PROPOSED removal from runtime.** |
| `objects.githubusercontent.com` | Release content | **PROPOSED removal from runtime.** |

**PROPOSED default runtime allowlist:** `api.openai.com` only. If another provider or gateway is selected, replace it with the exact documented endpoint set after review. Do not combine alternatives.

OpenCode configuration must set `autoupdate: false`, `share: "disabled"`, `enabled_providers: ["openai"]`, and the approved model. GSD's OpenCode capability records `skipUpdateBannerCommand: true`, but the absence of background update traffic remains **UNVERIFIED** until a runtime network test proves it.

## 5. Component architecture

### Trust and execution path

```text
Windows trusted operator layer
  start-opencode.bat
    -> %SystemRoot%\System32\wsl.exe -d ai-jail -u aijail -e
      -> /home/aijail/bin/jail-opencode --
        -> /opt/ai-jail-tools/opencode/1.18.34/opencode [approved flags]
          -> read-only managed OpenCode/GSD configuration
          -> writable /home/aijail/projects/opencode-work only
          -> credentials from hidden /home/aijail/.secrets/opencode.env
          -> CONNECT proxy -> exact runtime host allowlist
```

Properties:

- **PROPOSED:** use absolute paths at every security-relevant hop. Do not resolve Windows `opencode`, Linux `opencode`, GSD, or the jail wrapper through ambient PATH.
- **PROPOSED:** install immutable tool payloads under `/opt/ai-jail-tools/`, root-owned and not writable by `aijail` or the jailed process.
- **PROPOSED:** use `/opt/ai-jail-tools/opencode/1.18.34/` for the OpenCode archive and `/opt/ai-jail-tools/gsd-core/1.15.0/` for the locked GSD npm tree.
- **PROPOSED:** expose the GSD-generated OpenCode surface through a versioned read-only directory such as `/opt/ai-jail-tools/opencode-config/gsd-1.15.0/`, selected with `OPENCODE_CONFIG_DIR`.
- **PROPOSED:** install a root-owned managed OpenCode policy at `/etc/opencode/opencode.json` if pinned `1.18.34` confirms support for the documented Linux managed-config path. If it does not, inject a root-owned config through `OPENCODE_CONFIG` and explicitly test project-config precedence. This is an implementation gate.
- **PROPOSED:** keep writable source and `.planning/` output in `/home/aijail/projects/opencode-work` only. GSD workflow code, plugin code, and executables remain read-only.
- **PROPOSED:** place OpenCode data/cache beneath the writable project only if persistence is required, for example `.opencode-state/data` and `.opencode-state/cache`, using explicit XDG variables. Do not persist credentials there. Session persistence is opt-in and must be included in the acceptance test.
- **PROPOSED:** disable OpenCode autoupdate and prohibit package installation at runtime. Updates rerun Phase 090 with new reviewed pins.

### GSD integration

- **VERIFIED:** GSD `1.15.0` has an explicit OpenCode capability at support tier 2 and requires installer transformations. Directly copying upstream `agents/` or `commands/` is unsupported.
- **VERIFIED:** the installer writes flat `commands/`, converted `agents/`, on-demand `skills/`, and `plugins/gsd-core.js`; it also writes a managed CommonJS marker in the plugin directory.
- **PROPOSED:** run the exact pinned installer from the locked staging tree with `--opencode --global` and `OPENCODE_CONFIG_DIR` pointing at a staging config directory. Never use `npx ...@latest`.
- **PROPOSED:** review the complete generated file manifest before promotion. Promotion must reject paths outside the staging root, symlinks that escape it, unexpected package scripts, and changes to pre-existing non-GSD files.
- **PROPOSED:** no user-authored plugins share GSD's generated `plugins/` directory. This avoids the documented CommonJS marker conflict with ESM `.js` plugins.

### Proxy compatibility gate

OpenCode's authoritative network documentation says the TUI uses a local HTTP server and requires `NO_PROXY=localhost,127.0.0.1`. ai-jail intentionally forces `NO_PROXY` empty. These facts conflict.

- **UNVERIFIED:** OpenCode `1.18.34` can start and complete a model request in the accepted jail unchanged.
- **PROPOSED first path:** verify whether pinned `1.18.34` exposes and successfully uses a standalone mode that avoids the local client/server proxy loop. The reported ai-jail issue suggests this as a compatibility path, but an issue report is not acceptance evidence.
- **BLOCKING RULE:** if standalone mode is absent or fails, stop Phase 090. Do not add localhost to `NO_PROXY`, enable direct networking, change ai-jail, restore WSL interop, or add `--network` as an automatic workaround. Any exception needs a separate threat analysis and explicit approval.

## 6. File-by-file proposed changes

| File | Proposed purpose |
|---|---|
| `090-setup-opencode.bat` | Require exactly `--review` or `--apply`; establish the Phase 090 log; invoke the PowerShell implementation; normalize outcomes to `0`, `1`, or `3010`. |
| `090-setup-opencode.ps1` | Exact config parsing; preflight; temporary installation sandbox generation; pinned download/integrity verification; lockfile-enforced GSD install; staging, promotion, rollback, recovery, and redacted reporting. |
| `090-tool-manifest.json` | Machine-readable immutable versions, URLs, tag commits, archive sizes, SHA-256/npm integrity, expected executable paths, and generated-tree manifest version. No secrets. |
| `090-review-gates.md` | Human approval record for versions, install hosts, runtime provider/hosts, launcher replacement, root-owned destinations, persistence, and live operations. |
| `assets/090/opencode-managed.json` | Reviewed OpenCode policy with autoupdate/share disabled, approved provider/model, loopback-only server settings, and permission defaults. |
| `start-opencode.bat` | Replace the direct Windows execution with the absolute secured WSL -> `jail-opencode` -> pinned Linux binary path. No insecure fallback. |
| `config.env` | Add the separately approved Phase 090 install hosts and replace the OpenCode runtime list with provider-only hosts. Keep all install flags and `ENABLE_NONO=0` unchanged. |
| `000-run-all.bat` | Forward `--apply` to the exact `090-setup-opencode` stem after a mocked integration test proves 080 behavior is unchanged. |
| `tests/verify-090-static.ps1` | Validate pins, integrity syntax, strict config behavior, command construction, absolute paths, redaction, forbidden flags, and immutable-boundary rules without WSL changes. |
| `tests/verify-090-install.ps1` | Disposable/mock install, idempotence, lock enforcement, checksum failure, interrupted-state recovery, rollback, ownership/mode, and manifest verification. Live mode must be separately gated. |
| `tests/verify-090-runtime.ps1` | Real jailed OpenCode/GSD positive and negative tests after approved installation. Never read secret values. |
| `tests/verify-090-run-all-integration.cmd` | Mock phase discovery and prove `--apply` forwarding for 080 and 090 without running the real orchestrator. |

No VS Code file is proposed by default because `INSTALL_VSCODE=0`. A later approved convenience task may invoke `start-opencode.bat`; it must not invoke Windows OpenCode or claim that the VS Code process is jailed.

## 7. Installation, rollback, and recovery

### Review mode

`090-setup-opencode.bat --review` must be read-only. It must print:

- Exact selected pins, artifact names, hashes/integrities, install roots, and expected final paths.
- Exact temporary installation and permanent runtime hosts.
- Current versus proposed `config.env`, launcher, orchestrator, and wrapper changes.
- Whether CPU/OS prerequisites, Node/npm versions, free space, and baseline hashes pass.
- Whether required credential variable names are present, without values or lengths.
- Every remaining **UNVERIFIED** live gate.

### Apply mode

**PROPOSED transaction:**

1. Revalidate exact config schema, accepted baseline hashes, distro identity, WSL isolation, user identity, tool prerequisites, and no unresolved prior transaction.
2. Create a transaction directory with restrictive permissions and a journal. Do not stage in the project or in a normal private-home path used by OpenCode.
3. Create a temporary ai-jail installation launcher from the Phase 090 install-host list only. Give it one staging directory writable, no secret env file, a private home, and no project write mapping.
4. Download the exact OpenCode baseline archive and exact npm tarballs through CONNECT. Verify size and integrity before extraction or execution.
5. Install GSD and all dependencies from the reviewed lock. Disable npm audit, funding, update notifier, and unapproved lifecycle scripts. Any package that requires an allowed script must be separately listed and reviewed.
6. Run the pinned GSD installer against a staging `OPENCODE_CONFIG_DIR`; capture a generated-file manifest and scan for escaping symlinks or unexpected paths.
7. Verify staged OpenCode/GSD versions and offline command discovery. Do not make a provider request during staging.
8. Promote with a root-owned same-filesystem rename where possible. The promoter must independently re-hash the staged inputs/tree and must not receive runtime credentials.
9. Atomically update the secured launcher/config/wrapper only after tool promotion succeeds. Preserve backups inside the transaction area until all post-promotion checks pass.
10. Run non-provider smoke tests. Run provider/live tests only under the separately approved live gate.
11. Mark the journal complete and remove staging. Preserve a redacted manifest and log.

### Idempotence

- Exact installed manifest match: return `0` without rewriting files, changing timestamps, or downloading.
- Missing or corrupt managed file: fail closed in review; apply may repair only managed Phase 090 files from verified inputs.
- Different installed version: treat as an explicit upgrade transaction, never an in-place mutation.
- Existing unknown file in a managed destination: stop; do not overwrite it.

### Rollback and recovery

- Pre-promotion failure: remove only the current transaction staging directory; leave active tools/config/launcher untouched.
- Promotion failure: restore the prior versioned pointer/config/launcher atomically and verify its recorded manifest.
- Interrupted run: the next review identifies the journal state and proposes either resume-before-promotion or rollback-after-promotion. It must not guess.
- Successful upgrade: retain the immediately previous immutable tool version until the new runtime acceptance passes; deletion is a later explicit cleanup.
- Uninstall remains Phase 999/manual-only. Phase 090 must not add automatic destructive removal.

## 8. Runtime isolation and credentials

- The only supported production entry point is the secured Windows launcher through `jail-opencode` and the absolute pinned Linux binary.
- The jailed process may write only its own project mapping. Tool payloads, GSD workflows/plugins, managed policy, wrappers, other projects, Linux system paths, and secret files must be non-writable or hidden.
- `/home/aijail/.secrets/opencode.env` remains mode `0600`, owned by `aijail:aijail`; tests may inspect metadata and environment variable names only. Values, lengths, hashes, and prefixes must never be logged.
- OpenCode and its subprocesses necessarily receive approved credential variables. This is an explicit trust boundary, not secret isolation from OpenCode.
- Provider selection must be constrained both by OpenCode configuration and network allowlisting. Application permission prompts do not replace OS confinement.
- Runtime must not retain installation hosts, invoke npm/npx, update OpenCode/GSD, use mutable branches, or execute `curl | shell`.
- `--clean`, `--no-save-config`, `--private-home`, `--hide-dotdir .secrets`, and own-project-only mapping remain mandatory. `--network`, direct DNS, direct-IP exceptions, LAN access, automount, and interop remain forbidden.
- The managed OpenCode server must bind only to loopback. No LAN bind, mDNS, port proxy, or Windows firewall exception is part of Phase 090.
- Project-local `.ai-jail` remains forbidden. A writable `.opencode` directory may also shadow commands/plugins, so the acceptance suite must determine and document precedence; managed configuration must remain authoritative for security-sensitive settings.

## 9. VS Code options

### Option A - no Phase 090 VS Code integration (recommended)

- Keep `INSTALL_VSCODE=0`.
- Do not install/update VS Code or extensions.
- Launch jailed OpenCode from `start-opencode.bat` or a normal Windows terminal.
- Treat editor integration as deferred.

This is the smallest design and does not introduce a process outside ai-jail with access to the Linux project.

### Option B - trusted Windows VS Code convenience task

- Keep `INSTALL_VSCODE=0`.
- Add a task only after explicit approval; it may call the secured `start-opencode.bat` and nothing else.
- The task does not make Windows VS Code, its extensions, or its terminal part of the ai-jail boundary.
- Because Windows drives are not mounted in the distro, Windows VS Code cannot directly edit `/home/aijail/projects/opencode-work` through the normal local workspace path.

### Option C - existing Remote WSL extension

- **UNVERIFIED:** current VS Code version, extension state, and connectivity with the accepted WSL restrictions.
- A Remote WSL server would run as `aijail` outside the `jail-opencode` process. It could access the broader Linux home, secret path, and ordinary distro network context.
- Therefore it is a trusted administration/editor layer, not a confined workload. OpenCode launched from its ordinary remote terminal would be an unsupported bypass.
- If connection fails, document the limitation. Do not enable Linux-to-Windows interop, automount, Windows PATH injection, global `.wslconfig` changes, or distro restarts to make it work.

**PROPOSED decision:** approve Option A for Phase 090. Consider B or C only as a separately threat-modeled convenience feature.

## 10. Acceptance-test matrix

| Category | Test | Expected result |
|---|---|---|
| Static | Exact OpenCode/GSD versions, commits, URLs, sizes, SHA-256/npm integrity, and lockfile values | Match `090-tool-manifest.json`; no `latest`, ranges, mutable branches, or unpinned URL. |
| Static | Script syntax and exact config parser cases | Valid input passes; missing, duplicate, unknown, malformed, wildcard, IP-literal, or duplicate host input fails closed. |
| Static | Security command construction | Absolute binary paths; no Windows OpenCode, `--network`, automount, interop, PATH fallback, `curl | shell`, or secret echo. |
| Mocked | `090-setup-opencode.bat` mode and exit contract | Missing/extra/unknown args fail; `--review` and `--apply` forward exactly; only `0/1/3010` escape. |
| Mocked | Orchestrator discovery/forwarding | 080 and 090 receive `--apply`; other phases do not; stop-on-failure and `3010` behavior remain unchanged. Do not run the real orchestrator for this test. |
| Mocked | Download/checksum/package-lock failures | Wrong size/hash/integrity, redirect to an unapproved host, unresolved package range, or package-script drift fails before promotion. |
| Mocked | Transaction failures | Failures at each stage leave the previous active version intact; interrupted journals recover deterministically. |
| Disposable install | Clean install | Exact root-owned versioned trees and manifests are produced; no project, secret, Git, or Phase 080 wrapper mutation. |
| Disposable install | Repeat install | Exit `0`; no download or managed-file metadata change. |
| Live preflight | Accepted baseline | Distro/user/ai-jail versions, no drvfs mounts, no `cmd.exe`/`powershell.exe`, wrapper/project/Git/secret metadata, and Phase 080 hashes remain accepted. |
| Live install | Actual clients through CONNECT | OpenCode release client and npm/GSD dependency client succeed only for approved install hosts. A denied hostname through the same client fails. |
| Live runtime | Secured launcher path | Process chain is Windows launcher -> WSL distro/user -> `jail-opencode` -> exact `/opt` binary; working directory is `opencode-work`. |
| Live runtime | OpenCode startup/local transport | TUI starts without proxy loop under forced-empty `NO_PROXY`; standalone behavior and actual flags are recorded. Failure blocks acceptance. |
| Live runtime | Provider request | A minimal real request reaches only the approved provider through CONNECT and returns a valid response. No secret value appears in output/logs. |
| Live runtime | Runtime host separation | Provider succeeds; npm/GitHub/release hosts and an arbitrary denied hostname fail through the actual application/runtime client. |
| Live runtime | GSD discovery | Installed `/gsd-*` command, skill, agent, and plugin surfaces load from the read-only managed tree. |
| Live runtime | GSD output | A harmless GSD operation writes expected `.planning` output only inside `opencode-work`; GSD code/config remains unchanged. |
| Negative isolation | Direct DNS/TCP/IP/LAN/loopback bypass | Direct DNS, raw TCP, direct public IP, LAN/private IP, and unapproved loopback access fail as defined by the accepted ai-jail policy. Proxy-aware approved traffic is the positive control. |
| Negative isolation | Filesystem boundaries | Cross-project read/write, secret-path access, system/tool/config writes, escaping symlinks, and persistent project `.ai-jail` fail. |
| Negative isolation | Launcher bypass | Renamed/missing wrapper or pinned binary fails closed; no fallback to Bash, Windows OpenCode, Linux PATH, or an older version. |
| Regression | Phase 080 | Unchanged files/wrappers retain hashes. An approved `jail-opencode` host-policy change records its new hash while shell/comfyui remain byte-identical. |
| Optional VS Code | Selected option only | Option A confirms no changes. Option B calls only secured launcher. Option C documents that the editor server is trusted/outside jail and cannot launch unsupported OpenCode. |

`tests/verify-all.cmd` must not be used casually because its preflight may invoke the real root orchestrator. Every live installation, provider call, wrapper replacement, WSL termination, or editor experiment requires the approval specified by the applicable review gate.

## 11. Risks and unresolved assumptions

| Severity | Risk / assumption | Required treatment |
|---|---|---|
| High | OpenCode requires localhost in `NO_PROXY`; ai-jail forces it empty. | Blocking standalone/live compatibility test. No automatic network weakening. |
| High | `start-opencode.bat` currently bypasses all confinement. | Replace it with the secured launcher; no insecure fallback. |
| High | Current runtime allowlist lacks a model endpoint and retains installation hosts. | Approve one provider and exact host list before implementation. |
| High | GSD package dependencies use semver ranges. | Generate, review, and enforce a complete integrity-bearing lockfile. |
| High | OpenCode v2 is advertised but has unresolved ai-jail compatibility evidence. | Stay on pinned `1.18.34`; treat v2 as a future migration. |
| Medium | GSD's OpenCode integration is support tier 2 and its plugin executes hooks as subprocesses. | Verify every installed surface and actual hook behavior; keep code read-only. |
| Medium | Project `opencode.json` or `.opencode` artifacts may override or shadow policy/artifacts. | Establish precedence using pinned-version tests and enforce security settings through a non-writable highest-priority mechanism. |
| Medium | Runtime credentials are visible to OpenCode and approved subprocesses. | Minimize variables, disable unrelated providers, prevent logging, and accept this trust boundary explicitly. |
| Medium | GitHub release downloads may redirect to a host not currently allowed. | Record the exact redirect hostname before apply; reject unapproved redirects. |
| Medium | A VS Code Remote WSL server is outside ai-jail. | Default to no integration; never represent Remote WSL as confined. |
| Medium | GSD/OpenCode update checks could create denied traffic or delays. | Disable documented autoupdate, retain no update hosts, and observe runtime requests. |
| Low | Existing `/mnt/c` and `/mnt/d` path names are present although no drvfs mount was found. | Continue testing mount type, not mere path existence. |
| Low | Existing Node was originally installed through a historical LTS path. | Do not reinstall; verify exact current version and behavior in preflight. |

Remaining **UNVERIFIED** items before acceptance:

1. Exact x64 CPU compatibility and execution of the selected baseline OpenCode artifact.
2. Exact final GitHub redirect hostname under the approved CONNECT proxy.
3. OpenCode `1.18.34` standalone flag availability and forced-empty `NO_PROXY` behavior.
4. Provider credential variable-name presence and successful real provider traffic.
5. Managed-config and project-artifact precedence in pinned `1.18.34`.
6. Complete GSD lockfile, generated output manifest, plugin behavior, and absence of unwanted update traffic.
7. Whether any OpenCode session/data persistence is operationally required.
8. Existing VS Code version/extension state, only if Option B or C is selected.

## 12. Approval decisions

Implementation must not begin until the user explicitly decides each item:

| ID | Decision | Recommended selection |
|---|---|---|
| A1 | OpenCode pin/artifact | Approve `v1.18.34` Linux x64 baseline archive and recorded SHA-256. |
| A2 | GSD pin/method | Approve `@opengsd/gsd-core@1.15.0`, full lockfile, and pinned installer transformation. |
| A3 | Install hosts | Approve only `github.com`, confirmed GitHub release-asset redirect host, and `registry.npmjs.org`; require evidence for any addition. |
| A4 | Runtime provider | Approve OpenAI with `api.openai.com` only, or supply one alternative provider/gateway for separate design. |
| A5 | Runtime host cleanup | Remove npm/GitHub/object hosts from `ALLOW_HOSTS_OPENCODE`. |
| A6 | Managed paths | Approve root-owned versioned `/opt/ai-jail-tools/...` and read-only managed OpenCode policy/config. |
| A7 | Launcher | Replace `start-opencode.bat`; do not retain an insecure fallback. |
| A8 | Wrapper/config baseline change | Approve the minimal `jail-opencode`/`config.env` changes needed for provider-only runtime and absolute managed environment paths, with new hashes. |
| A9 | Orchestrator | Approve mocked-test-first `--apply` forwarding for exact Phase 090 stem. |
| A10 | Persistence | Default to no durable sessions/cache until a need is demonstrated; alternatively approve bounded project-local `.opencode-state`. |
| A11 | VS Code | Select Option A (no Phase 090 integration); keep `INSTALL_VSCODE=0`. |
| A12 | Live operations | Separately approve Phase 090 apply, actual downloads, provider call, and any targeted distro termination if later proven necessary. |

## Recommendation

Approve A1-A12 using the recommended selections, with A4 confirming OpenAI only if that is the intended credential/provider. Implementation should stop after static and mocked tests for a second review before any live apply. The forced-empty `NO_PROXY` compatibility test remains a hard acceptance gate: inability to run pinned OpenCode inside the unchanged jail means Phase 090 is blocked, not permission to weaken the isolation baseline.
