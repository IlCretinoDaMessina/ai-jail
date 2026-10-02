# AI Jail — PLAN-090

**Phase:** 090 — OpenCode + maintained GSD Core integration  
**Status:** Implementation planning; production apply **NOT APPROVED**  
**Baseline:** Accepted Phase 080; ai-jail **2.2.0**; preserve all recorded production hashes unless a separately approved, explicitly documented change supersedes them.  
**Control:** User authorises each write/live gate; ChatGPT owns design, code and reviews; MiMo is execution-only and reports raw outputs, exit codes and diffs.

## 1. Objective and scope

Install and integrate a pinned Linux OpenCode CLI and the maintained `open-gsd/gsd-core` OpenCode workflow in the existing `ai-jail` WSL distro, without weakening accepted project separation, private-home, hidden-secret or external-network controls. Use OpenCode Zen free models initially and permit later provider additions only through reviewed configuration, credential provisioning and exact runtime host approval. Preserve existing `.planning/` history without automatic migration. Do not install archived `gsd-build/get-shit-done` or standalone `open-gsd/gsd-pi` in this phase. `INSTALL_VSCODE=0`; `ENABLE_NONO=0`.

## 2. Verified evidence: completed, do not repeat without change

- Seven documented Phase 080 Windows production file SHA-256 values matched `ROADMAP-004.md`. Three installed wrapper hashes and project Git heads matched the earlier Phase 090 Initial Inspection Report. Local `D:\.coding\.ai-jail` itself is **not** a Git working tree; do not run `git init` there.
- Phase 090 review-only scaffold and its manifest/static/argument tests passed; `--apply` rejects with exit 1. These tests validate the **review-only scaffold**, not a future installer.
- Verified OpenCode `v1.18.34` Linux x64 baseline archive: `60,665,421` bytes, SHA-256 `24b0d458d21ef548b2752166303defcf7f4945b049fb4876ab78dfaf86d81b27`. Verified extracted ELF: `185,632,896` bytes, SHA-256 `9ca0b9953d49997601655e54f846a3efa464f237e47c6f1b04716d0f2e64c4c2` (Windows and WSL staging match). Archive and extracted binary are experimental inputs, **not a production install**.
- Existing `jail-opencode` supports `-- COMMAND [ARG...]`. It uses `--clean --no-save-config --private-home --hide-dotdir .secrets`, only own-project writable mapping, secret env file, and runtime CONNECT proxy. Existing production runtime hosts are installation-shaped and must not be reused unchanged for provider runtime.
- LB-01: normal WSL network namespace `4026531833`, jailed namespace `4026532232`; jailed route table empty. Netlink inspection denied (`Operation not permitted`) and requires no repair.
- OpenCode `--help`, `run --help`, `serve --help`, `attach --help` and version executed through the jail. Authenticated loopback server starts at `127.0.0.1:4096`. Without loopback proxy bypass, ordinary proxied HTTP yielded 405, and proxied CONNECT to loopback yielded 403. OpenCode's own `attach` failed with `/provider` GET returning 405.
- LB-03: authenticated direct curl with **request-local** `--noproxy 127.0.0.1` returned HTTP 200. LB-04: with **temporary process-local** `NO_PROXY=no_proxy=127.0.0.1,localhost`, OpenCode TUI appeared, but harness timeout made cleanup inconclusive; subsequent process inspection found no matching process.
- LB-05: under the temporary exception, direct external TCP failed, unapproved CONNECT returned 403, private-address CONNECT returned 403, route table remained empty; namespace stayed isolated. LB-06A: direct DNS failed; WSL automount, interop and Windows PATH injection disabled; no drvfs mounts or Windows executables on Linux PATH.
- Experimental launcher `lb-test-launcher.sh`, SHA-256 `b8535ac09cde745e66654babf06eb76f17e8c03016b3a6915c57bc48cee17643`, corrects working directory with `cd /home/aijail/projects/opencode-work` before ai-jail. The launcher is **user-writable staging only; do not promote verbatim into production**.
- LB-06D/E/F: version `1.18.34` and OpenCode TUI successfully started through corrected temporary launcher; process check found no leftover staging process. LB-06G: **one** minimal `opencode/big-pickle` model request through temporary runtime `--allow-host opencode.ai` returned `OK`, exit 0; no leftover matching process. This demonstrates basic connectivity only, not full production acceptance or audit of every network request.
- No reported Phase 080 production modifications during the experiments. Existing experimental files live under `/home/aijail/projects/opencode-work/.phase090-staging/`; any later cleanup requires its own reviewed scope.

## 3. Architecture and security invariants

1. Secured entry: trusted Windows launcher → explicit WSL `ai-jail` distro/user → root-owned managed launcher/wrapper → ai-jail 2.2.0 → pinned, root-owned Linux OpenCode binary. No Windows OpenCode fallback and no PATH-based security-sensitive resolution.
2. Sandbox retains `--clean --no-save-config --private-home --hide-dotdir .secrets`, own-project writable mapping only, and a controlled env-from-file. All generated tooling and policy outside project writable space, read-only from the jailed process. Do not expose secret values or hashes in logs. Approved provider variables are intentionally visible to OpenCode and its approved subprocesses; do not claim otherwise.
3. Runtime external networking remains HTTP CONNECT-only with exact host approval. Initial proposed external runtime hostname: `opencode.ai` **only**; do not keep npm/GitHub install hosts. No automatic wildcard, private/LAN, direct-IP, direct DNS/TCP, `--network`, unrestricted bypass, WSL automount, interop or global `.wslconfig` change.
4. Localhost compatibility: keep ai-jail's forced-empty proxy-exception environment on entry; apply **process-local** `NO_PROXY` and `no_proxy` values `127.0.0.1,localhost` only after entering the isolated namespace in the reviewed OpenCode launcher. This is a **proposed production exception**, not yet authorised. Confirm it cannot be overridden by project-local config and that external traffic remains proxied.
5. OpenCode local server bound to `127.0.0.1` only, with temporary/managed authentication; no LAN binding, mDNS, Windows port proxy or firewall exception. Do not leak server password in process arguments, logs or project files.
6. OpenCode autoupdate and sharing disabled; prohibit runtime npm/npx installs and uncontrolled plugin/update traffic. OpenCode/GSD update is a new reviewed pinned transaction.
7. Keep `INSTALL_VSCODE=0`, `ENABLE_NONO=0`. VS Code is a trusted host-side editor only; Remote-WSL terminals are not automatically jailed.

## 4. Pinned inputs and unverified dependencies

- OpenCode: proposed and experimentally verified binary `v1.18.34`, Linux x64 **baseline** archive; preserve manifest archive size/hash and extracted hash. Revalidate provenance and CPU prerequisites before production apply.
- GSD: **maintained** repository `https://github.com/open-gsd/gsd-core`; proposed npm package `@opengsd/gsd-core@1.15.0`, proposed commit `b10ab3fdeb6274b373859ccd6e99b7e1cf17388e`, proposed npm integrity `sha512-GwdlJeupozyM22g2INdxiNfkpDm5hFS7G42leRqQwHb/0BclBG3TpgyGtWIkf47shjkfGRtrK5iK+pPZ61DvMA==`. A reviewed complete transitive lockfile, provenance, lifecycle-script audit and generated OpenCode file manifest remain **UNVERIFIED**.
- Existing Node `v24.21.0`, npm `11.19.0`, Git `2.43.0` were recorded in inspection; recheck only if changed or needed at apply gate.
- Installation hosts are separate: approved asset URL/redirect and locked npm registry dependencies only. Proposed `github.com`, `release-assets.githubusercontent.com` (actual redirect must be verified), `registry.npmjs.org`; do not silently expand existing `ALLOW_HOSTS_INSTALL` across other phases. Design a dedicated `ALLOW_HOSTS_INSTALL_OPENCODE` or present alternative for approval.
- Free models: tested `opencode/big-pickle` using `opencode.ai`; models may change. Other providers (e.g. OpenRouter) are future explicit configuration/credential/runtime-host approval, not automatic access.

## 5. Implementation tasks and gates

### 090-8A — Specification and approvals (ChatGPT; no writes to production)
- Integrate confirmed free-provider choice and loopback test evidence into manifest and review gates. Resolve A1–A12 from Architecture Proposal, marking A4 OpenCode Zen free models instead of OpenAI API, and A12 live apply still blocked. Present proposed production loopback exception and its threat analysis for explicit user approval.
- Define precedence of managed/root-owned config vs project `opencode.json`/`.opencode`, plugin commands, server password handling, persistence scope, and phase-specific installation hosts.
- **Gate:** user approves exact file write scope and test plan, not production apply.

### 090-8B — Generate Phase 090 production candidate (ChatGPT authors; MiMo places exact files)
Candidate file inventory:
- `090-tool-manifest.json` (verified inputs, immutable paths, explicit gates)
- `090-review-gates.md` (decisions and evidence)
- `090-setup-opencode.bat` and `.ps1` (exact `--review`/`--apply`, transaction journal, fail-closed validation and redacted logs; apply must stay blocked until later user approval)
- `assets/090/opencode-managed.json` and generated read-only GSD config specification
- secured `start-opencode.bat` replacement **as a proposed diff, not yet applied**
- `config.env`, `000-run-all.bat`, and any generated `jail-opencode` wrapper change **as separately reviewed diffs, not silent writes**
- `tests/verify-090-static.ps1`, `tests/verify-090-install.ps1`, `tests/verify-090-runtime.ps1`, `tests/verify-090-run-all-integration.cmd`
- complete GSD lockfile and generated tree manifest after isolated preparation and audit.
Production destinations: proposed root-owned, versioned `/opt/ai-jail-tools/opencode/1.18.34/`, `/opt/ai-jail-tools/gsd-core/1.15.0/`, and read-only GSD OpenCode config. No mutable `latest`, user-writable production launcher or unknown-file overwrite.
- **Gate:** review actual diffs, checksum, syntax; no real orchestrator or install.

### 090-8C — Static/mock and failure testing
- Parse exact config keys; duplicate/unknown handling per existing project convention, strict host validation, artifact hashes, env-name-only redaction; validate generated shell syntax and path boundaries.
- Mock orchestrator forwarding of `--apply` for exact Phase 090 stem, preserving Phase 080 forwarding semantics; do **not** execute real `000-run-all.bat`.
- Disposable/mock installation: wrong hash/size, unexpected redirects, bad lockfile, unexpected lifecycle scripts, symlink escape, malformed config, missing prerequisites, occupied managed destination, interrupted journal, promotion rollback and idempotence. Test failure codes (`0`, `1`, `3010` per orchestrator contract).
- Re-review **revised** production files; previous scaffold passes are not transferable to newly written installer code.
- **Gate:** all negative tests and mock tests pass; ChatGPT reviews evidence; user separately approves live steps.

### 090-8D — Isolated staging, apply and recovery (only after explicit user authorisation)
1. Revalidate accepted baseline and distro identity; verify no unresolved prior transaction.
2. Restrictive transaction directory, private installer home, one writable staging location; no runtime credential injection, no project mapping for installer.
3. Download exact pinned inputs through phase-specific install-only hosts; verify size, SHA-256/integrities before extraction/execution; lock and audit every transitive dependency and script.
4. Run pinned GSD OpenCode installer with staged `OPENCODE_CONFIG_DIR`, inspect transformed `commands/`, `agents/`, `skills/`, `plugins/` and generated CommonJS marker; reject unexpected paths/symlinks/overwrites.
5. Independently rehash staged tree; promote root-owned versioned destinations transactionally; retain prior immutable version until runtime acceptance. Apply launcher/config/wrapper/orchestrator changes only after their separate approval and backup.
6. Idempotent same-manifest apply must return success without downloads or rewrites. On failure, rollback recorded pointers/files; do not blindly delete unknown/user content. No Phase 999/uninstall/cleanup automation.

### 090-8E — Production runtime acceptance
- Verify absolute entry chain, owner/mode/hash of tools, credentials metadata only, root-owned managed config precedence, GSD workflow compatibility and unchanged `.planning/` history.
- Confirm authenticated local server/client works under strictly process-local loopback exception; no `--auto`, external plugins only when approved, no unexpected update/share traffic.
- Confirm `opencode.ai`-only model request, record permitted/denied proxy hostnames without sensitive URL/query contents; prove direct DNS/TCP and unapproved/private/LAN CONNECT blocked. Validate cross-project paths, private home and hidden `.secrets`.
- Run approved Phase 080 regression tests and exact Phase 090 acceptance suite **only after confirming they cannot rerun setup unexpectedly**. Compare newly accepted production hashes/metadata and document any authorised supersession.
- **Gate:** user accepts evidence, signs off Phase 090, updates `STATUS-004.md`, `ROADMAP-004.md`, `HANDOFF-004.md` and tests documentation; phase remains incomplete if any gate fails.

## 6. Explicit current blockers

- Production `NO_PROXY` exception threat analysis and precise wrapper placement still require user approval. Experimental success is not blanket permission to relax networking.
- Complete verified GSD lockfile and generated-file manifest do not yet exist.
- Installer host redirect(s) and provenance/lifecycle audit not yet finalised.
- Root-owned OpenCode managed config and project override precedence not proven in final production configuration.
- Session persistence and production server authentication design need explicit acceptance.
- Production `--apply`, launcher replacement, `config.env` and orchestrator changes, downloads and provider/live regression operations **NOT AUTHORISED**.

## 7. Operating procedure

ChatGPT produces complete, bounded instructions and candidate code. MiMo executes exactly those commands in Build mode, reports raw output, exit codes, observed file changes and errors, and stops. Do not delegate analysis, research, architectural choices, planning or autonomous repair to MiMo. Reuse verified context; reread only changed documents or exact lines needed to validate a new change. Unexpected permission requests are denied and returned to ChatGPT. Avoid exposing credentials or running completed installation phases. Preserve all historical review and validation evidence.
