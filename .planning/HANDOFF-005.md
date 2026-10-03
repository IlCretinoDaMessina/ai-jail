# AI Jail — Continuation Handoff 005

**As-of:** 2026-10-03, Europe/Vienna.  
**Read with:** [`RECAP-005.md`](RECAP-005.md), detailed history/hashes.  
**Mission:** Continue the AI Jail Phase 091 Windows reference comparison, finish GSD–OpenCode compatibility acceptance, then return to Phase 090 controlled production design. Preserve accepted Phase 080 isolation and the user's existing Windows OpenCode installation.

> **Immediate resume:** A prompt for **Task 091.1C.10 (read-only Windows GSD installer safety preflight)** has already been given to MiMo. The user has not yet returned its result. Ask for or interpret its raw results when supplied; **do not assume it passed, repeat work, or run the Windows GSD installer yet**.

## A. Roles and how to work

- ChatGPT = researcher, architect, code/command author, security reviewer, analysis and next-task decisions. User explicitly does **not** want MiMo creating analyses or reports.
- MiMo-V2.6-Flash Free in OpenCode Build mode = execution-only. Give one bounded exact copy/paste prompt per task, include preconditions, permitted paths/hosts, negative scope, full raw output and exit-code requirements. One operation/attempt where specified. On error STOP, no unsolicited repair/retry. Reuse previously verified evidence; re-read only changed/missing/exact-needed docs.
- Request **separate user approval** for new downloads/network access, write scopes, executing GSD installer, provider calls, production modification and live `--apply`. Past task approvals are not blanket permissions.
- User wants **MiMo permission requests visibly tagged in OpenCode's popup**. Prefix each **shell command's first line** with an actual comment such as:

  ```powershell
  # 🟢 [APPROVED] TASK 091.1C.10 — READ ONLY
  ```

  And require MiMo's chat notice before the permission call: `[APPROVED]`/`[DETAIL]`/`[EXTRA]`/`[UNCERTAIN]`, task step, exact action, authorisation source, modifications. `🟢 [APPROVED]` exact authorized, `🟡 [DETAIL]` implementation detail, `🔴 [EXTRA]` unapproved (do not invoke), `🟠 [UNCERTAIN]` stop. For any nonexact material operation obtain review; **Allow once** only, never Allow always. A displayed label is not proof of approval; actual command must match. OpenCode popup cannot be styled by prompt, emoji color only if rendered and first line not truncated.
- **Prompt discipline:** avoid code with PowerShell `$home` (read-only `$HOME`, case-insensitive); use `$testHome`. Avoid complex nested `powershell`→`node -e` or `wsl.exe`→`bash -c` quoting. For JS audit, STDIN `node -` worked; if a command fails, MiMo returns output rather than inventing alternative commands. Do not have MiMo write Markdown reports unless separately and explicitly authorised; existing GitHub reports were user uploaded.
- Keep user informed succinctly; do not ask previously answered questions. Present results as verified/reported, not stronger than evidence.

## B. Critical context and invariants

- Windows AI Jail project `D:\.coding\.ai-jail` **not** a Git repo. WSL distro `ai-jail`, user `aijail`. ai-jail pinned `v2.2.0`; Phase 080 accepted. Production `/opt/ai-jail-tools` was last reported absent. Phase 090 review-only `--apply` rejects; no production install/launcher integration has happened.
- Existing WSL experimental OpenCode `v1.18.34` and GSD `@opengsd/gsd-core@1.15.0` remain under user-writable `.phase090-staging`. Exact lock SHA `0f849ce86faf92ee3d34aaefbb7ac3941a9a386f8d27aa4555b90c13eee59396`. A single OpenCode Zen free-model `opencode/big-pickle` `OK`, exit 0 was successfully tested through jailed temporary launcher `--allow-host opencode.ai`, with process-local localhost `NO_PROXY` workaround. Final production negative-egress, auth, root ownership and config precedence acceptance **pending**.
- Linux GSD isolated generation test root:
  `/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548`
  Successful `bin/install.js --opencode --global --config-dir <TEST_ROOT>/output/opencode`, no network host, home redirected; installer exit 0, 1,036 regular files, 72 commands/72 skills, home `.gsd/defaults.json` under test root, no symlinks; warnings: **72 shadowed triggers**, **368 unreplaced `.claude` references in 118 files**.
- 091.1A/B found generated absolute staging refs (864 lines/331 files), broad `.claude` matches (959/325), narrower path matches (726/314; not comparable to installer warning counts), native plugin identical to source, `/gsd-new-project` generated in command and skill forms. Generated config has disposable absolute paths and unpinned `npx -y -p @opengsd/gsd-core gsd-mcp-server` which must not be promoted unchanged. No actual GSD workflow functional test yet. Avoid blanket replacing `.claude` or suppressing shadowing without functional evidence.
- Phase 091 `091-gsd-opencode-compatibility.md` was created to gate Phase 090 acceptance; Phase 200 `200-optimizations.md` is deferred until **after ComfyUI and all core integrations**, with no DCP/Sleev/Working Memory plugin now.

## C. User's non-negotiable Windows reference requirement

**Bare `opencode` in an ordinary Windows terminal MUST continue invoking the user's existing global OpenCode**; test version launches *only* by explicit absolute binary / future local launcher, not PATH. No global npm install, `npm link`, PATH, alias, registry, user profile or existing OpenCode/GSD configuration changes. The native reference folder is **not an OS sandbox**; process env redirection alone cannot constrain arbitrary filesystem writes. Do not run the GSD integration installer until Windows-specific side effects are reviewed and appropriately isolated.

Windows reference root: `D:\.coding\opencode-test-w11`. Created folder structure includes `bin`, `home` with `.config/.cache/.local/AppData`, `gsd/package`, `gsd/config`, `gsd/npm-cache`, `workspace`, `downloads`, `logs`. User confirmed it started empty, task .3 verified this before creating dirs.

**Existing global command baseline** (verified unchanged after all reference actions to date):

- Primary `Get-Command opencode` => `C:\Users\4l3x\AppData\Roaming\npm\opencode.ps1`.
- Same folder `opencode.ps1` SHA-256 `7dc7f9e963b88bbfb7a529a82d1922adf642d386f096fc250e891e374884ee8e`.
- `opencode.cmd` SHA-256 `b53b698473bfa46e09487e485a7f1ad5b4881f8a8b319d3619aa251f3be8ae10`.
- extensionless `opencode` SHA-256 `0f2f05dcd20bcaefd7c050e8d6505d58d4136e896ea38ae9efe561911f04af6c`.
- Exactly three `Get-Command opencode -All` entries. Global prefix `C:\Users\4l3x\AppData\Roaming\npm`; previously installed `opencode-ai@1.18.34`, `get-shit-done-cc@1.42.3`, `@gsd-build/sdk@0.1.0` (different GSD distribution from current maintained core). Never replace/test bare global installation as a proxy for the pinned maintained core.

## D. Current verified native Windows reference contents

| Artifact | Location | SHA-256 / outcome |
| --- | --- | --- |
| Official Windows OpenCode ZIP | `D:\.coding\opencode-test-w11\downloads\opencode-windows-x64-baseline-v1.18.34.zip` | `f89ab2720050780a450e3cf3e48ac3f0409235b46b6c548c69aa2b7051d716f4`, 62,158,547 bytes, contains exactly `opencode.exe` |
| Local CLI binary | `D:\.coding\opencode-test-w11\bin\opencode.exe` | `184f196ec97c843a64b2e1a2b49165f25e73a5d6993e2f842c9958c2b1f7a5b2`, 180,599,176 bytes; explicit child-only `--version` returned `1.18.34`, exit `0` |
| Reference package manifest | `D:\.coding\opencode-test-w11\gsd\package\package.json` | `01d48d8a115f66589cb6fd9083c722ffe08d767d9953aae9d66af6801cc4cd03`, direct exact `@opengsd/gsd-core:1.15.0` |
| Windows npm lock | `D:\.coding\opencode-test-w11\gsd\package\package-lock.json` | `2c7acee1c0860d604c6c5369fab25cc03efb3f8880fcd7c3e815266228525a3c`, v3, 119 non-root entries; independently verified by Node stdin (`node -`), all sources HTTPS `registry.npmjs.org`, 0 missing metadata |
| Pinned package | `D:\.coding\opencode-test-w11\gsd\package\node_modules\@opengsd\gsd-core\` | Installed by one locally scoped, scripts-disabled `npm ci`, exit `0`, stdout `added 105 packages in 5s`, manifest name/version `@opengsd/gsd-core 1.15.0` |

Native Windows Node `v24.15.0`, npm `11.13.0` from `C:\Program Files\nodejs`, meet upstream prerequisites. Windows lock differs from Linux lock legitimately; installed package counts differ with optional platform binaries (Linux 106, Windows 105). Package resolution/acquisition used isolated process env and dedicated cache, not global npm. Existing global launcher hashes and resolution rechecked after .9R and matched.

**NO native Windows GSD integration generation yet.** No `bin/install.js` execution on Windows; next task is only static preflight.

## E. Immediate pending Task 091.1C.10 — precise scope

Already given as a MiMo copy/paste prompt; wait for raw response with sections `PACKAGE IDENTITY`, `INSTALLER`, `WINDOWS-SPECIFIC REFERENCES`, `REFERENCE PATHS`, `GLOBAL OPENCODE`, `LOCKFILE`, `ERRORS`, `UNEXPECTED MODIFICATIONS`.

Preflight script (read-only): reads local GSD `package.json`, verifies name/version, records `bin/install.js` file path/size/hash; `Select-String -SimpleMatch` (first 8 numbered matches each) for these 12 tokens:

`USERPROFILE`, `APPDATA`, `LOCALAPPDATA`, `os.homedir`, `homedir()`, `process.env.HOME`, `XDG_CONFIG_HOME`, `OPENCODE_CONFIG_DIR`, `config-dir`, `defaults.json`, `process.platform`, `win32`.

Then checks six test-root dirs are actual directories and non-reparse, `Get-Command opencode` still global, and Windows lockfile hash `2c7ace...a3c`. **No execution of GSD installer or OpenCode**, no npm, network or writes. Prefix first shell line `# 🟢 [APPROVED] TASK 091.1C.10 — READ ONLY`; Allow once.

### After 091.1C.10 returns: ChatGPT analysis/decision

1. Determine whether native Windows GSD installer uses `os.homedir()` / `USERPROFILE` / `APPDATA` and how it creates `~/.gsd/defaults.json`, resolves `--config-dir`, performs migration/removal, and handles plugin cache. The Windows `ProcessStartInfo` child environment can redirect HOME/USERPROFILE/APPDATA/LOCALAPPDATA, but is **not guaranteed to be OS-enforced**; a child or Windows API could still address actual profile or other accessible paths. If static snippets insufficient, author one bounded read-only source-range inspection; *do not let MiMo explore freely*.
2. If reliable confinement to disposable paths cannot be established in native Win, **do not execute installer** there; recommend an actually isolated Windows Sandbox/VM reference rather than risking user's existing daily tools. User selected native Windows but protecting actual environment is higher priority; ask for explicit change of test isolation if needed.
3. If safe, design separately approved single-shot Windows generation: child-only env, no inherited provider secrets, explicit `--opencode --global --config-dir` to test folder, no `GSD_TEST_MODE`, no implicit npm/npx, no uncontrolled downloads, no migration of real user config, precise before/after file inventories and global launcher hashes. The user has not yet approved running `bin/install.js` on Windows.
4. Compare **same GSD core 1.15.0** Windows warnings to Linux's 72/368; assess OS-specific versus upstream behavior. Then perform targeted functional OpenCode command/skill and MCP tests in disposable env with separate approval, address only confirmed defects. Keep production `/opt` and live `--apply` blocked until Phase 091 091.4 acceptance and Phase 090 security gates.

## F. Active project documents and direct URLs

**Use direct links; do not assume a document's internal links are automatically read in the new window.**

- [ROADMAP-004.md](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/ROADMAP-004.md)
- [HANDOFF-004.md](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/HANDOFF-004.md)
- [STATUS-004.md](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/STATUS-004.md)
- [REQUIREMENTS-004-ADDENDUM.md](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/REQUIREMENTS-004-ADDENDUM.md)
- [Phase 090 Initial Inspection Report](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/Phase%20090%20Initial%20Inspection%20Report.md)
- [Phase 090 Architecture Proposal](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/Phase%20090%20Architecture%20Proposal.md)
- [PLAN-090.md](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/PLAN-090.md)
- [Phase 090 source report 8C.5A](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/TASK%20090-8C.5A-report.md)
- [Phase 090 source report 8C.5B](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/TASK%20090-8C.5B-report.md)
- [Phase 091 plan](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/091-gsd-opencode-compatibility.md)
- [Task 091.1A report](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/TASK%20091.1A-report.md)
- [Task 091.1B report](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/TASK%20091.1B-report.md)
- [Phase 200 optimization note](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/200-optimizations.md)
- Main maintained GSD upstream: https://github.com/open-gsd/gsd-core ; npm exact `@opengsd/gsd-core@1.15.0`.
- OpenCode pinned release: https://github.com/anomalyco/opencode/releases/tag/v1.18.34 .
- AI Jail pinned upstream: https://github.com/akitaonrails/ai-jail/tree/v2.2.0 .

## G. What not to do when resuming

- Do **not** ask MiMo to design or write reports, launch extra grep/inspection loops, install a different GSD distribution, regenerate successful lockfiles, rerun GSD installer generation in Linux, or redo LB-06G.
- Do **not** assume Windows `opencode` is the test binary: plain command is the user's existing global installation and must stay so.
- Do **not** use `$home` as a PowerShell local variable or inline complex `node -e` JS quoted through Windows PowerShell; earlier tasks failed on those exact issues. Use `$testHome`, Node stdin, simple preauthored commands.
- Do **not** trust local folder / child env redirection as OS sandbox; assess Windows-specific installer writes first.
- Do **not** treat GSD installer warning totals as proof of broken functions, or different grep counts as defect progression; verify workflow-critical uses.
- Do **not** promote `opencode.json` containing `npx -y -p @opengsd/gsd-core gsd-mcp-server`, disposable absolute paths or unreviewed `npx @latest` shims. Do not disable required GSD native plugin/hooks without evidence.
- Do **not** use real credentials, allow additional provider hosts, run global npm, change existing Phase 080/090 production scripts or launchers, or enable `--apply` by implication.

## H. Current stage summary for first reply in new continuation window

**Completed:** Phase 090 experimental OpenCode/connectivity, review-only candidate and synthetic transactions, pinned GSD Linux lock/cache/offline extraction, disposable Linux integration generation and audits 091.1A/B, Windows reference directories and OpenCode 1.18.34 CLI, Windows pinned GSD lock audited, local scripts-disabled Windows GSD dependencies successfully installed (Task 091.1C.9R). Existing global Windows `opencode` unchanged.

**Pending next:** Task 091.1C.10 result — read-only Windows GSD installer safety preflight. Then review whether native Windows installer can be run without touching actual Windows profile; request new approval before executing it. Ultimately compare warning behavior, test workflows, complete Phase 091 and only then consider Phase 090 live promotion. Phase 200 stays deferred after ComfyUI.
