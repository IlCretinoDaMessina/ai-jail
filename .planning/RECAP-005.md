# AI Jail — Detailed Recap 005

**Coverage:** continuation following the Phase 004 handoff, through **Task 091.1C.9R** and issuance of **Task 091.1C.10**.  
**As-of:** 2026-10-03 (Europe/Vienna).  
**Purpose:** detailed historical/evidence recap for the next ChatGPT continuation window. Read with [`HANDOFF-005.md`](HANDOFF-005.md); the handoff is the operative next-action guide.  
**Status caveat:** Unless stated otherwise, results below are raw outputs reported by the execution agent (MiMo), reviewed by ChatGPT; do not imply an independent forensic audit of the user's machines. Nothing in this recap authorises production installation.

## 1. Operating roles and durable boundaries

- User controls approvals for each scoped write, download, network access, executable test, and production gate.
- **ChatGPT:** sole researcher, architect, code/command author, security reviewer, interprets evidence and chooses next step.
- **OpenCode / MiMo-V2.6-Flash Free, Build mode:** *execution only*. Receive specific commands, execute once within scope, return raw stdout/stderr, exit codes, actual hashes, and unexpected modifications. No analysis, designs, reports, exploration, proactive troubleshooting or unapproved reruns.
- Do tasks incrementally. Reuse verified context; reread only changed, missing, or exact-verification-dependent material. In particular, don't redo completed LB tests, previous hashes, broad source greps, installer generation or npm resolution without a concrete reason.
- Windows AI Jail project: `D:\.coding\.ai-jail` (not itself a Git working tree). WSL2 distro `ai-jail`, ordinary user `aijail`; upstream ai-jail pinned `v2.2.0`. Accepted Phase 080 baseline remains unchanged.
- Existing production scripts, wrapper, credentials and sandbox policy may not be modified silently. `--apply` remains disabled; `/opt/ai-jail-tools` was most recently reported **absent** in WSL.
- Keep OpenCode provider hosts, npm installation hosts and local loopback exception separate. No blanket bypass, extra hosts, global npm installs, real-profile edits, silent updates or credential disclosure.

### 1.1 New MiMo permission-transparency protocol (adopted during this continuation)

The user wants a recognizable approval marker **inside the native OpenCode permission command preview, just above its choices**, not only in MiMo's preceding chat. ChatGPT cannot directly change native popup UI or guarantee colors. Starting with each future prompt, put an actual **first-line shell comment** in *each authorised submitted command*, e.g.:

```powershell
# 🟢 [APPROVED] TASK 091.1C.10 — Read-only installer preflight
```

The emoji may render in color; native popup text color and truncation cannot be guaranteed. Also instruct MiMo to display before invoking a permissioned tool: tag, exact task/step, proposed operation, quoted source of authorisation, write scope, and **ALLOW ONCE**. Classifications:

- `🟢 [APPROVED]`: exactly and explicitly authorised command/operation, verified against task text.
- `🟡 [DETAIL]`: necessary implementation detail not an exact prescribed command; disclose before action, do not pass it off as exact approval; obtain approval when materially different.
- `🔴 [EXTRA]`: unapproved inspection, retry, repair or command; **do not invoke the tool**; report and stop.
- `🟠 [UNCERTAIN]`: authorisation unclear; **stop without requesting tool permission**.

Never select/request **Allow always**. **A printed tag is not proof of authorisation**: inspect the whole actual command. If a command fails, return the raw error/exit and STOP, unless a new ChatGPT task explicitly authorises a correction. MiMo must not generate architecture analysis or Markdown reports. Put the tag at the start of each shell command, not only once in prose. The preceding chat classification is useful but may be visually separate from the permission popup.

## 2. Phase 090: experimental compatibility findings preserved

- Target maintained `open-gsd/gsd-core` / npm `@opengsd/gsd-core@1.15.0`, **not** archived `gsd-build/get-shit-done`, standalone `gsd-pi`, or the different Windows global `get-shit-done-cc` discussed below. OpenCode pin `v1.18.34`.
- Linux OpenCode archive official `https://github.com/anomalyco/opencode/releases/download/v1.18.34/opencode-linux-x64-baseline.tar.gz`, size `60,665,421`, SHA-256 `24b0d458d21ef548b2752166303defcf7f4945b049fb4876ab78dfaf86d81b27`; ELF size `185,632,896`, SHA-256 `9ca0b9953d49997601655e54f846a3efa464f237e47c6f1b04716d0f2e64c4c2`. Experimental user-writable staging binary only.
- AI Jail proxy is HTTP CONNECT-only; OpenCode's authenticated local server (`127.0.0.1`) would incorrectly proxy its own requests (`405`, or `403` for loopback CONNECT). Process-local `NO_PROXY=no_proxy=127.0.0.1,localhost` **inside the jail**, after sandbox entry, enabled OpenCode TUI. Negative network evidence under that temporary exception: direct external TCP and DNS failed; unauthorized and LAN CONNECT rejected; jailed namespace had no routes. These tests do not substitute for final production regression.
- Corrected experimental launcher `/home/aijail/projects/opencode-work/.phase090-staging/lb-test-launcher.sh`, SHA-256 `b8535ac09cde745e66654babf06eb76f17e8c03016b3a6915c57bc48cee17643`, first changes directory to `/home/aijail/projects/opencode-work`, then enters jail; **never promote user-writable script directly**.
- LB-06G: single `opencode/big-pickle` OpenCode Zen free model request returned `OK`, exit `0`, no leftover matching staging process; provider `opencode.ai` was temporarily allowed. Basic end-to-end connectivity proven at experimental level, not production approval.
- `PLAN-090.md` was prepared and uploaded to GitHub; architecture calls for root-owned versioned `/opt/ai-jail-tools`, transactional promotion/recovery, managed config, explicit host approvals, no VS Code integration (`INSTALL_VSCODE=0`), no nono (`ENABLE_NONO=0`), initial free models and no automatic `.planning` migration.

## 3. Phase 090 candidate creation and tests since 004

### 3.1 Tasks 8B.1 / 8B.2 / 8B.3 — review-only production candidate

- Authored ZIP `phase090-8B1-candidate.zip`, SHA-256 `a8df6b2f3288742d371f52260ca2e5f3ee580a9348c1da40a09fe53ced17846d`.
- Replaced only: `090-tool-manifest.json`, `090-review-gates.md`, `090-setup-opencode.bat`, `090-setup-opencode.ps1`. Added only: `assets/090/opencode-managed.json`, `assets/090/README.md`, `tests/verify-090-candidate.ps1`, `tests/verify-090-candidate-behavior.ps1`.
- Backup: `D:\.coding\.ai-jail\logs\090-8B2-backup-20261002-163508`; four previous copies verified byte-identical before replacement; all eight destination package hashes matched.
- Tests `verify-090-candidate.ps1` and `verify-090-candidate-behavior.ps1` exit `0`: review works; apply, empty/extra/unknown arguments rejected; accepted baseline unchanged. `--apply` remains a **rejection**, not functional live installation.

### 3.2 Task 8C.1 — Windows disposable transaction prototype

- ZIP `phase090-8C-candidate.zip`, SHA-256 `24471976d9ea2098da3feae8c82fbd373ddde745d5668b0086a6afc2c072fca3`; added `tests/090-transaction-prototype.ps1`, `tests/verify-090-transaction.ps1`, matching expected hashes.
- Offline test exit `0`: wrong hash, missing marker, injected interruption / explicit recovery, valid commit and occupied destination all behaved as tested. Synthetic disposable test only; not proof of production-grade atomicity.

### 3.3 Task 8C.2 — WSL synthetic hardening

- ZIP `phase090-8C2-candidate.zip`, SHA-256 `677571c75c9330cd0d779d4ab350275ee4e555d2a0f227f58e668324ec43907e`. Added `assets/090/PRODUCTION-INSTALLER-GATES.md`, `tests/090-linux-transaction-prototype.sh`, `tests/verify-090-linux-transaction.sh`. All checksums matched.
- WSL transfer (byte-for-byte via stdin, because Windows automount disabled) staging `/tmp/phase090-transfer-xEbzJg0p`; Bash syntax passed. Synthetic test exit `0`: wrong hash, marker, symlink directory, symlink source, interruption/recovery, commit/destination rejection. Early failed shell-quoting transfer created no files and successful run was separate. Staging preserved.

### 3.4 Task 8C.3 — GSD provenance specification

- ZIP `phase090-8C3-candidate.zip`, SHA-256 `ea4b795e624a8f20714ede3787952623a10b3b63c3e088b7e3dc11c4deb9d8cc`.
- Added `assets/090/GSD-DEPENDENCY-PROVENANCE.md`, `assets/090/gsd-acquisition-gate.json`, `tests/verify-090-gsd-gates.ps1`, all destination hashes matched; offline gate test exit `0`.
- GSD manifest requires Node `>=24`, npm `>=10`; declared dependency ranges are insufficient as a full lock; package lifecycle scripts must not execute automatically. Acquisition/production gates remain fail-closed.

## 4. Phase 090 GSD lock and offline reproducibility (WSL)

- 8C.4A prerequisite inventory: `/usr/bin/node` `v24.21.0`; `/usr/bin/npm` `11.19.0`; production `/opt/ai-jail-tools` absent.
- 8C.4B: one authorised registry-only (`registry.npmjs.org`) sandboxed `npm install --package-lock-only --ignore-scripts` in `/home/aijail/projects/opencode-work/.phase090-staging/gsd-lock-5c0a1640`; generated canonical files:
  - `package.json`: `f323f8dff1bda1ba30248682c73fb90d942455e0f1f8a05af21982c12b2d6822`
  - `package-lock.json`: `0f849ce86faf92ee3d34aaefbb7ac3941a9a386f8d27aa4555b90c13eee59396`
  - lock v3, 119 non-root entries, exact `@opengsd/gsd-core@1.15.0`, 119 HTTPS npm registry resolved URLs and sha512 integrity fields; no git/file/local/alternate acquisition. 16 optional platform-specific entries; no `hasInstallScript` flags observed in the lock entries. Source package integrity `sha512-GwdlJeupozyM22g2INdxiNfkpDm5hFS7G42leRqQwHb/0BclBG3TpgyGtWIkf47shjkfGRtrK5iK+pPZ61DvMA==`.
- 8C.4C.2 first offline `npm ci --offline --ignore-scripts` failed as expected `ENOTCACHED`, first missing tarball `zod-to-json-schema@3.25.2`; lockfile-only operation hadn't populated all artifacts. No network fallback.
- 8C.4D: separate authorised sandboxed online cache seeding through `registry.npmjs.org` only, `npm ci --ignore-scripts`; exit `0`, `added 106 packages in 7s`, cache count 450 files; `online-seed-2c2fba95` preserved. Original hashes unchanged. One auxiliary read-only Node quotation error corrected without rerunning acquisition.
- 8C.4E: brand-new offline test through AI Jail **with no allowed network hosts**, `npm ci --offline --ignore-scripts`; exit `0`, `added 106 packages in 5s`. GSD manifest confirms version `1.15.0`; original and copied hashes match. Fresh source for installer experiments: `.../gsd-lock-5c0a1640/offline-confirm-4231a6b0`.
- **What was established:** reproducible scripts-disabled dependency extraction on actual WSL platform using pinned lock/cache; no actual GSD workflow was run and production package provenance/installer review still require acceptance.

## 5. GSD source inspection and disposable Linux integration generation

### 5.1 8C.5A / 8C.5B source findings

Two reports were uploaded:

- [TASK 090-8C.5A-report.md](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/TASK%20090-8C.5A-report.md)
- [TASK 090-8C.5B-report.md](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/TASK%20090-8C.5B-report.md)

Pinned package has its own installer `bin/install.js`, native OpenCode plugin `.opencode/plugins/gsd-core.js`, hooks, commands/agents/skills, and local `bin/gsd-mcp-server.js`. Installer supports explicit OpenCode selection and `--global --config-dir`; `--local` cannot be combined with `--config-dir`. Installing into `--config-dir` does **not** contain all side effects: installer also writes `~/.gsd/defaults.json`. Plugin writes a skills cache under `os.homedir()` (e.g. `~/.cache/opencode/gsd-skills/`) and mutates passed in-memory OpenCode config; plugin itself did not appear to persist `opencode.json`. Installer DOES write the generated `opencode.json`. It performs copies, migration/replacement/deletions and other file operations; do not run against real home merely because config-dir is redirected. `GSD_TEST_MODE` skips code and is not a faithful substitute for filesystem isolation.

MiMo drifted into extra exploratory greps and PowerShell/WSL quoting errors; user rejected pending command, MiMo was instructed to STOP and return already gathered evidence. ChatGPT accepted the completed source review without repeating it.

### 5.2 8C.5C — isolated installer generation success

Single **installer execution** completed inside AI Jail, no allowed network hosts, with copied source, explicit disposable process home and explicit OpenCode config destination; original source retained.

`TEST_ROOT=/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548`

- `TEST_ROOT/source` = copy of verified package/dependencies; `TEST_ROOT/home`, `output/opencode`, `work` isolated; `os.homedir()` checked to resolve `TEST_ROOT/home`; no `GSD_TEST_MODE`.
- `node .../bin/install.js --opencode --global --config-dir TEST_ROOT/output/opencode` returned `0`. Landlock fully enforced; 72 skill dirs, 72 commands, plugin, hooks, config, manifests, state and defaults generated; full report: 1,036 regular files (1,035 output, 1 home), zero symbolic links, 1,199 inventory entries.
- `home/.gsd/defaults.json` was created under disposable home. No reported real-home, Phase 080, project or `/opt` changes. Some *setup* attempts had quoting errors and created nothing outside test root before successful installer execution. Do not rerun broad generation without new reason.
- **Two GSD warnings:** `72 triggers shadowed` (global skills win over same-named commands), and `368 unreplaced .claude path reference(s) in 118 file(s)`; warnings came from GSD installer, not AI Jail proxy. Not yet evidence that workflows fail. No automatic global search-and-replace.
- Generated `opencode.json` SHA-256 `a2f07f6d83252ccd0cc1417410e04705b6234765130b392c1e18dfaf298ecbb1`; generated plugin SHA-256 `f73b406011caf68b5af178706ac350c215f9d416c51b9de4c01d0580d14a2d97`. Generated config references disposable absolute paths and includes an **unversioned MCP launcher** `npx -y -p @opengsd/gsd-core gsd-mcp-server`; must not promote unchanged. Production should use a pinned local executable or verified strategy and separately review MCP side effects.

### 5.3 Upstream review and Phase 091 creation

ChatGPT researched current maintained GSD source, OpenCode docs and issues: native plugin/hook strategy is intentional; shadowing may be a diagnostic rather than broken workflows; some Claude path-conversion issues are real historical upstream issue classes, but neither all 368 warnings nor all matching `.claude` text establish faults. Check operational relevance and actual runtime. Watch ownership/manifest behaviour and CommonJS plugin directory compatibility for future add-ons. Do not remove plugin/hooks merely to suppress warnings.

New planning file [`091-gsd-opencode-compatibility.md`](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/091-gsd-opencode-compatibility.md) (local generated artifact SHA-256 `a2fe544938f3dcc2d3dae2b217d0061365569b94802778c7cba17a74c67a445e`) defines **Phase 091 — GSD–OpenCode Compatibility & Integration Acceptance** as prerequisite to Phase 090 production promotion. Work packages 091.1 audit, 091.2 disposable functional test, 091.3 confirmed fixes, 091.4 acceptance handoff. Verify GitHub upload/location in new window if exact current status matters; the user was asked to save this file, not all uploads independently reverified.

### 5.4 091.1A / 091.1B inspections completed

Reports:

- [TASK 091.1A-report.md](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/TASK%20091.1A-report.md)
- [TASK 091.1B-report.md](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/TASK%20091.1B-report.md)

091.1A: `/gsd-new-project` command and `gsd-new-project` skill both generated; 72 direct command definitions, 72 skill directories; plugin byte-identical to source, resolves hooks relative to installed tree, no hardcoded TEST_ROOT in plugin. **Some generated command/skill files contain absolute `TEST_ROOT` workflow paths** which will break if blindly relocated. Config also has absolute read permissions and unpinned `npx` MCP command.

091.1B: wide staging path search found **864 matching lines across 331 files**; broad `.claude` search **959 lines across 325 files**; specific `.claude` path search **726 lines across 314 files**. These are **different queries** from the installer warning of 368/118 and must not be compared as an increase in defect count. Content includes possible compatibility fallbacks, documentation and Claude-oriented nested assets; operational classification still needed. Some shim text contains `npx ... @latest` fallback; determine whether reachable rather than blind replacements. Local MCP `bin/gsd-mcp-server.js` is a stdio wrapper with relative package import; its actual implementation and side effects need review before use. Reports cover enough evidence; **do not repeat broad greps**.

## 6. Phase 200 deferred optimization note

User supplied a context/token-optimization finding (DCP, Sleev, OpenCode Working Memory; cache/quota claims). ChatGPT corrected unsupported assumptions: browser prompt caching is not free usage; OpenCode consumption depends on actual provider/auth; submitted DCP example settings were not established against current schema; quoted Sleev link duplicated DCP and true canonical URL must be independently checked. User explicitly deferred all optimizer work **until after ComfyUI and all core integrations work** and selected provisional **Phase 200**. Created [`200-optimizations.md`](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/200-optimizations.md) / local artifact SHA-256 `7e266ecafdcb0e9ca122b44dd98ff8f04db11013860b323516d7e5affea4a4ab`. No DCP/Sleev/Working Memory installed or allowed in Phase 090/091. Check roadmap number collision before formal integration.

## 7. Windows comparison: reason, isolation, and historical results

User asked whether GSD warnings are caused by AI Jail or differing Windows GSD. ChatGPT noted GSD emitted warnings itself and OS/runtime/version must be isolated before attributing. User chose an **isolated native Windows 11 reference**, specifically `D:\.coding\opencode-test-w11`, and strongly required that the usual bare `opencode` command, profiles, configuration and global packages remain unaffected.

**Windows local folder is not an OS security sandbox.** Redirect child HOME/USERPROFILE, APPDATA/LOCALAPPDATA, XDG and temp paths, and inspect GSD Windows installer behavior before executing it. Avoid any global install, `npm link`, PATH changes, aliases, registry changes or other writes to real home. Explicitly launch test binary by absolute path, never bare `opencode`.

### 7.1 Task 091.1C.1 — read-only Windows prerequisites

- OS reported `Microsoft Windows NT 10.0.26300.0`, x64, 64-bit OS/process.
- Windows Node `C:\Program Files\nodejs\node.exe` `v24.15.0`, npm `11.13.0` (`npm.ps1`/`npm.cmd` variants). Git and winget present.
- Existing global OpenCode from `C:\Users\4l3x\AppData\Roaming\npm\`; `gsd` command not found. Global packages: `@gsd-build/sdk@0.1.0`, `get-shit-done-cc@1.42.3`, `npm@11.13.0`, `opencode-ai@1.18.34`. **Windows global GSD is a different distribution/version from maintained `@opengsd/gsd-core@1.15.0`; do not treat as an equivalent control.**
- Existing real user profile dirs: `~/.config/opencode`, `~/.opencode`, `~/.gsd`, `~/.claude`; the selected reference folder already existed. User confirmed it was empty; task 091.1C.3 verified empty, ordinary non-reparse directory.

### 7.2 Task 091.1C.3 — reference structure

Created only 14 dirs under `D:\.coding\opencode-test-w11`: `bin`, `home`, `home/.config`, `home/.cache`, `home/.local`, `home/AppData/Roaming`, `home/AppData/Local`, `gsd`, `gsd/package`, `gsd/config`, `gsd/npm-cache`, `workspace`, `downloads`, `logs`. All verified. No global edits.

### 7.3 Task 091.1C.4 — **protected existing global OpenCode baseline**

Bare `Get-Command opencode` primary MUST remain:

`C:\Users\4l3x\AppData\Roaming\npm\opencode.ps1`

Exactly three `Get-Command opencode -All` entries, with these unchanged SHA-256s:

| Launcher | Expected SHA-256 |
| --- | --- |
| `C:\Users\4l3x\AppData\Roaming\npm\opencode.ps1` | `7dc7f9e963b88bbfb7a529a82d1922adf642d386f096fc250e891e374884ee8e` |
| `C:\Users\4l3x\AppData\Roaming\npm\opencode.cmd` | `b53b698473bfa46e09487e485a7f1ad5b4881f8a8b319d3619aa251f3be8ae10` |
| `C:\Users\4l3x\AppData\Roaming\npm\opencode` | `0f2f05dcd20bcaefd7c050e8d6505d58d4136e896ea38ae9efe561911f04af6c` |

Global npm prefix `C:\Users\4l3x\AppData\Roaming\npm`. Before and after subsequent reference tests all three file hashes and primary resolution reported unchanged.

### 7.4 Tasks 091.1C.5–.7 — isolated Windows OpenCode binary

- Official asset `https://github.com/anomalyco/opencode/releases/download/v1.18.34/opencode-windows-x64-baseline.zip`; successful HTTP 200. Archive path `D:\.coding\opencode-test-w11\downloads\opencode-windows-x64-baseline-v1.18.34.zip`, size `62,158,547`, SHA-256 `f89ab2720050780a450e3cf3e48ac3f0409235b46b6c548c69aa2b7051d716f4`; exactly one ZIP entry `opencode.exe`, uncompressed `180,599,176`, no traversal.
- Extracted only `D:\.coding\opencode-test-w11\bin\opencode.exe`, size `180,599,176`, SHA-256 `184f196ec97c843a64b2e1a2b49165f25e73a5d6993e2f842c9958c2b1f7a5b2`, ordinary non-reparse file.
- Ran explicit absolute executable `--version` once in cleared, child-only redirected environment, returned `1.18.34`, exit `0`, blank stderr. Bare global `opencode` never executed. Original three launcher hashes/primary path unchanged.
- First attempt to fetch with PowerShell IWR NonInteractive failed before successful one download with `-UseBasicParsing`; do not re-fetch.

### 7.5 Tasks 091.1C.8 / .8A / .8B — Windows GSD lockfile

- Target `D:\.coding\opencode-test-w11\gsd\package`; cache under `gsd\npm-cache`; exactly `@opengsd/gsd-core@1.15.0`; child-only redirected HOME, USERPROFILE, APPDATA, LOCALAPPDATA, TEMP, TMP, npm user/global config; no inherited provider secrets; no global npm operation.
- Manifest `package.json` SHA-256 `01d48d8a115f66589cb6fd9083c722ffe08d767d9953aae9d66af6801cc4cd03` (UTF-8 no BOM, exact dependency). Initial write had stray trailing space, corrected on same authorised file *before* npm resolution; later hash stable.
- Lock `package-lock.json` SHA-256 `2c7acee1c0860d604c6c5369fab25cc03efb3f8880fcd7c3e815266228525a3c`, generated by one `npm install --package-lock-only --ignore-scripts --no-audit --no-fund --save-exact` to npm registry; npm exit `0`; no node_modules at this stage.
- Windows PowerShell 5.1 `ConvertFrom-Json` failed to parse lockfile; a fallback regex was not accepted as sufficiently reliable. The first independent `node -e` read-only audit failed because PowerShell stripped JS quote characters. MiMo properly stopped and did not repair. Revised Task .8B passed a JS program through Node standard input (`node -`): lock v3, 119 non-root entries, root and manifest pin exactly `1.15.0`, zero missing resolved/integrity, zero URL sources outside HTTPS `registry.npmjs.org`, GSD entry version/integrity match; exit 0; source hashes unchanged. Avoid inline nested PowerShell/Node quoting; use stdin or carefully pre-authored files only when specifically authorised.

### 7.6 Tasks 091.1C.9 / .9R — **CURRENT COMPLETED STATE**

- User explicitly approved **local locked dependency acquisition** in separate Windows reference folder, no global changes and no GSD integration-installer execution.
- First Task .9 failed **before preflight**: `$home` conflicts with read-only built-in PowerShell `$HOME` (case-insensitive). No npm started or files modified. Corrected prompt .9R changed it to `$testHome`.
- .9R success: package, lock and Windows binary preflight hashes matched; three global launcher hashes matched; one scoped, child-only `npm ci --ignore-scripts --no-audit --no-fund --registry=https://registry.npmjs.org/ --cache=D:\.coding\opencode-test-w11\gsd\npm-cache --fetch-retries=0 --loglevel=error`; stdout `added 105 packages in 5s`, stderr empty, exit `0`.
- Installed package manifest at `D:\.coding\opencode-test-w11\gsd\package\node_modules\@opengsd\gsd-core\package.json`: name `@opengsd/gsd-core`, version `1.15.0`.
- Manifest, lockfile, reference binary hashes unchanged; original global launchers unchanged, primary bare command still original `opencode.ps1`; no unexpected modifications reported.
- 105 packages on Windows vs 106 on Linux is compatible with OS-dependent optional dependencies, not itself a failure. Do not insist on identical installed package counts across OSs; compare same source version, relevant generated warnings and function.
- **GSD's integration installer has NOT been run on native Windows; no Windows OpenCode/GSD integration has yet been generated.**

## 8. Current decision and next task (important for continuation)

ChatGPT already issued **Task 091.1C.10 — Windows GSD Installer Safety Preflight** to MiMo. **Await its raw result**; do not mark complete or issue a duplicate unless needed. This is read-only and inspects:

1. Windows pinned package identity (`@opengsd/gsd-core@1.15.0`) and `bin/install.js` path, size and SHA-256.
2. Numbered matches within installer for `USERPROFILE`, `APPDATA`, `LOCALAPPDATA`, `os.homedir`, `homedir()`, `process.env.HOME`, `XDG_CONFIG_HOME`, `OPENCODE_CONFIG_DIR`, `config-dir`, `defaults.json`, `process.platform`, `win32`.
3. Reference path directory/reparse status for isolated `home`, `home/AppData/Roaming`, `home/AppData/Local`, `gsd/config`, `gsd/package`, `workspace`.
4. Protected global `Get-Command opencode` primary and existing Windows lock SHA-256.

The prompt starts the PowerShell tool command with `# 🟢 [APPROVED] TASK 091.1C.10 — READ ONLY` and uses Allow Once. No GSD installer execution yet.

**After reading output:** assess Windows home resolution including Node `os.homedir()` behavior, GSD source logic for `~/.gsd/defaults.json`, real-profile fallbacks, Windows `APPDATA`/`LOCALAPPDATA` and config precedence. A non-OS-enforced native Windows directory/child env **does not prove confinement**; if safety cannot be established, prefer a Windows Sandbox/VM or other genuine OS isolation instead of running a risky native installer. If safe, separately request scope/approval for exactly **one** isolated Windows integration generation targeting disposable directories; no real user home, no production/Phase 080 edits, no global command replacement. Capture stdout/stderr, warnings, complete artifact inventory and compare to Linux's `72 shadowed` / `368 unreplaced` (same version, runtime OpenCode). Functional test only after static audit and separate approval.

## 9. Full project URLs / artifacts

- Phase 004 docs:
  - https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/ROADMAP-004.md
  - https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/HANDOFF-004.md
  - https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/STATUS-004.md
  - https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/REQUIREMENTS-004-ADDENDUM.md
  - https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/Phase%20090%20Initial%20Inspection%20Report.md
  - https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/Phase%20090%20Architecture%20Proposal.md
- Phase 090 plan and evidence:
  - https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/PLAN-090.md
  - https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/TASK%20090-8C.5A-report.md
  - https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/TASK%20090-8C.5B-report.md
- Phase 091 and evidence:
  - https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/091-gsd-opencode-compatibility.md
  - https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/TASK%20091.1A-report.md
  - https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/TASK%20091.1B-report.md
- Deferred Phase 200: https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/200-optimizations.md
- Official external references: https://github.com/akitaonrails/ai-jail/tree/v2.2.0 ; https://github.com/anomalyco/opencode/releases/tag/v1.18.34 ; https://github.com/open-gsd/gsd-core ; https://www.npmjs.com/package/@opengsd/gsd-core

## 10. Accepted Phase 080 baseline hashes (never change without separate approval)

| Windows project relative path | SHA-256 |
| --- | --- |
| `000-run-all.bat` | `2c188e0e3d95465f44b87b623e991a1723c97ad6615fbe0ff3ba33d5fb399775` |
| `080-setup-sandboxes.bat` | `1122dc891bfddf0259d41d792ad3a6f2da15df9230a41aedbab1f358639ad1b9` |
| `080-setup-sandboxes.ps1` | `84d0f8f4ea1983cfb4f6bf6f151ae2f3262b898391dfe5fd2e6ff15946e05245` |
| `config.env` | `affc004de57e1dfedc5c12d850957904e1f2b9356b82de856e33effe5fd4c0d5` |
| `_common.bat` | `f32827ecbb861a7ae1df9dd280b9ab6cc3a804849761ad8491318b4288214e8b` |
| `080-review-gates.md` | `0086ccabf95029b5090f4202a43fa5c052b8ec05ef689926445e35d9fc5144dd` |
| `.planning/phase-080-validation-report.md` | `bd6295ba04d6514fe70ae3f59f3a867305b7aebe9435679e757ae5085e2343d1` |

These hashes were matched at earlier baseline inspection and reported unchanged by subsequent relevant test runs; a final production regression is still outstanding.

## 11. Lessons and conclusions

1. AI Jail was not shown to cause GSD's installer compatibility warnings; the warnings originate in GSD-generated OpenCode assets. Native Windows control using the *same* pinned package helps separate upstream/OS behavior from AI Jail effects. Different global Windows `get-shit-done-cc@1.42.3` is not a like-for-like control.
2. A successful installer exit and offline dependency installation do **not** prove a functional GSD workflow. Before promotion: resolve destination-bound paths, assess operational `.claude` references, replace or disable implicit unpinned `npx` MCP, check command/skill discovery, plugin/hook behavior, persistence and rollback.
3. Root-owned production artifacts must be generated for their **final destination**, or correctly regenerated with evidence; never blindly copy disposable generated files with embedded absolute paths.
4. Windows process-environment redirection is a test hygiene mechanism, **not an OS sandbox**. Inspect platform-specific GSD installer behavior before executing it against native Windows, or use actual OS isolation.
5. Broad, self-directed MiMo exploration increased command quotation errors and repetition. Use bounded, pre-authored commands, stdin for nested JavaScript, read-only inspections before writes, and stop on errors. The `🟢 [APPROVED]` first-command-line marker serves permission transparency; it does not delegate design approval to MiMo.
6. Phase 200 context/token optimization stays deferred until after ComfyUI and other core integrations; current focus remains Phase 091 compatibility to unblock Phase 090 production acceptance.
