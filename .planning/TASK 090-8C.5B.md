TASK 090-8C.5B

Scope of files inspected (read-only, via wsl -d ai-jail):

\- BASE = /home/aijail/projects/opencode-work/.phase090-staging/gsd-lock-5c0a1640/offline-confirm-4231a6b0/node\_modules/@opengsd/gsd-core

\- BASE/bin/install.js (14922 lines, 715117 bytes)

\- BASE/.opencode/plugins/gsd-core.js (794 lines, 32877 bytes)

\- BASE/gsd-core/bin/lib/runtime-homes.cjs

\- BASE/gsd-core/bin/lib/capability-registry.cjs

\- BASE/gsd-core/bin/lib/install-engine.cjs

\- BASE/gsd-core/bin/lib/user-artifact-staging.cjs

INSTALLER OPTIONS:

1\. install.js:932 — const args = process.argv.slice(2);

2\. install.js:933 — const hasGlobal = args.includes('--global') || args.includes('-g');

3\. install.js:934 — const hasLocal = args.includes('--local') || args.includes('-l');

4\. install.js:935 — --uninstall/-u; :936 --skills-root; :937 --portable-hooks (or GSD\_PORTABLE\_HOOKS='1'); :938 --minimal/--core-only; :939 --dry-run; :957 --relative-includes (or GSD\_RELATIVE\_INCLUDES='1'); :969 --reclaim-kimi-legacy; :970-976 --profile=<name>.

5\. --opencode: install.js:1001 — if (runtimeArgs.includes('--opencode')) selected.push('opencode'); inside function selectRuntimesFromArgs(runtimeArgs) at install.js:990-1019 (also --all at :992-994, --both → \['claude','opencode'] at :995-997).

6\. --config-dir: pure parser function parseConfigDirFromArgs(argsArray) install.js:1229-1249 (space form :1230-1237; --config-dir=/-c= form :1241-1246); wrapper function parseConfigDirArg() install.js:1257-1273 (exit 1 on missing value :1263-1265; exit 1 on empty :1268-1270); const explicitConfigDir = parseConfigDirArg(); install.js:1274.

7\. Help text listing all flags incl. --opencode, --global, --local, --config-dir <path>: install.js:1286; Notes stating --config-dir takes priority over CLAUDE\_CONFIG\_DIR / OPENCODE\_CONFIG\_DIR / ... / XDG... env vars: install.js:1286 (Notes block).

8\. Non-interactive behavior (no dedicated --non-interactive/--yes/-y/--auto installer flag found; --auto occurs only inside skill prose at install.js:3919):

\- install.js:14026-14030 — promptLocation: if (!process.stdin.isTTY) { console.log(...'Non-interactive terminal detected, defaulting to global install'); installAllRuntimes(runtimes, true, false); return; }

\- install.js:14914-14918 — no runtime+no location: if (!process.stdin.isTTY) { ...'defaulting to Claude Code global install' ... installAllRuntimes(\[DEFAULT\_RUNTIME], true, false); } else { promptRuntime(...) }

\- install.js:14902-14906 — runtime flags present with --global/--local → installAllRuntimes(selectedRuntimes, hasGlobal, false) (isInteractive=false).

\- install.js:14907-14909 — location flag only → installAllRuntimes(\[DEFAULT\_RUNTIME], hasGlobal, false).

\- Non-TTY guards in handleStatusline install.js:13789-13795 and handleUpdateBanner install.js:14001-14008 (if (!isInteractive) { callback(false) }).

\- GSD\_TEST\_MODE: install.js:14830 (if (require.main === module \&\& !process.env.GSD\_TEST\_MODE)), :13713 (skips configureOpencodePermissions), :7043 (skips writeNonClaudeDefaults).

9\. Invalid-combination exits: install.js:14886-14887 (--global + --local → exit 1); :14889-14891 (--config-dir + --local → exit 1); :14895-14897 (--uninstall without location → exit 1); :978-981 (--minimal + --profile → exit 1); :14857-14860 (--skills-root unknown runtime → exit 1).

OPENCODE INSTALLATION FLOW:

1\. installAllRuntimes(runtimes, isGlobal, isInteractive) — install.js:14525-14704. Migrations discovered :14527-14529; rollback closure :14531-14571; per-runtime install(isGlobal, runtime, { installerMigrations }) :14573; finalize()/finishInstall() :14581-14632; statusline/banner dispatch :14665-14678.

2\. install(isGlobal, runtime = DEFAULT\_RUNTIME, options = {}) — install.js:10625-13556 (approx; returns object near :13555). Target dir computed :10741-10747; foreign-dest warning :10749-10752; runInstallerMigrations({ configDir: targetDir, ... }) :11321-11327; legacy cleanup scoped :12313-12322; writeManifest :12334.

3\. finishInstall(settingsPath, settings, statuslineCommand, shouldInstallStatusline, runtime, isGlobal, configDir, bannerOpts) — install.js:13610-13760+. OpenCode permission writer call :13712-13715; writeNonClaudeDefaults(runtime) :13735.

4\. configureOpencodePermissions(isGlobal = true, configDir = null) — install.js:9453-9547. Destination :9456-9458; fs.mkdirSync :9460; reads/parse :9462-9477; skip-if-string-permission :9481-9483; permission.read :9499-9507; permission.external\_directory :9509-9517; config.mcp.gsd insertion :9532-9541; fs.writeFileSync(configPath, JSON.stringify(config,...)) :9545.

5\. resolveOpencodeConfigPath(configDir) — install.js:1443-1448 (opencode.jsonc if exists else opencode.json).

6\. OpenCode artifact writers (in BASE/gsd-core/bin/lib/install-engine.cjs): installOpencodeFamilyArtifacts(runtime, configDir, scope, ...) :1873-1930 (commandDir :1905, skills :1906, agents :1911, native plugin :1912); installOpencodeFamilySkills(...) :1401-1440+; installOpencodeFamilyCommands(...) :1657-1700; dispatch site :1147-1161 (behaviors.combinedFamilyInstall → installOpencodeFamilyArtifacts).

7\. Opencode descriptor capability-registry.cjs:2860-3005 (and duplicate :7096-7265): configHome {kind:"xdg", name:"opencode", env:\["OPENCODE\_CONFIG\_DIR","OPENCODE\_CONFIG","XDG\_CONFIG\_HOME"]} :2870-2879; localConfigDir:".opencode" :2881; hostBehaviors.nativePlugin {dir:"plugins", file:"gsd-core.js", source:".opencode/plugins/gsd-core.js"} :2984-2989; combinedFamilyInstall:true :2964; permissionWriter:"opencode" :2948; hooksSurface:"none" :2941; skipUpdateBannerCommand:true :2993.

8\. Opencode runtime flag id in interactive map: install.js:13844 ('13': 'opencode'); prompt text :13872; allRuntimes :13851.

DESTINATION AND CONFIG PRECEDENCE:

1\. install.js:10741-10747 — const targetDir = isGlobal ? getGlobalConfigDir(runtime, explicitConfigDir) : \_hostBehaviors(runtime).localTargetIsProjectRoot ? process.cwd() : path.join(process.cwd(), dirName);

2\. runtime-homes.cjs:458-482 — function getGlobalConfigDir(runtime, explicitDir): assertNotRetiredRuntime :460; if (explicitDir) return expandTilde(explicitDir); :461-462; grok branch :464-467; descriptor branch runtimeEntry?.runtime?.configHome → resolveDescriptorWithOptions(...) :469-472; claude fallback :474-476.

3\. runtime-homes.cjs:162-254 — resolveConfigHomeFromDescriptor; xdg case :208-230: env0 OPENCODE\_CONFIG\_DIR → expandTilde :210-213; env1 OPENCODE\_CONFIG (FILE path → path.dirname) :214-218; env2 XDG\_CONFIG\_HOME → join(..., name) :219-224; default path.join(home, '.config', configHome.name) :225.

4\. runtime-homes.cjs:84-90 — resolveDescriptorWithOptions passes process.env, os.homedir().

5\. install.js:1208 — return getGlobalConfigDir(runtime, explicitDir); (compat getGlobalDir).

6\. install.js:9456-9458 — OpenCode permission config dir: configDir || (isGlobal ? getGlobalConfigDir('opencode', explicitConfigDir) : path.join(process.cwd(), '.opencode')).

7\. install.js:14463 — cleanupLegacyGsdCc({ homeDir = os.homedir(), configDirs = null, ... }); scope override install.js:12315-12321 (legacyCleanupScope = (explicitConfigDir !== null \&\& isGlobal) ? \[targetDir] : undefined); per-package cache root install.js:14502-14506.

8\. Non-honoring site (reads, passes null instead of explicitConfigDir): install.js:1600 — readSettings(resolveConfigPath(getGlobalConfigDir(runtime, null))) inside getCommitAttribution.

9\. install.js:14427-14428 — legacy scan subdir names include '.opencode', '.config/opencode'.

REPLACEMENT, MIGRATIONS AND ROLLBACK:

1\. Existing-destination replacement: install.js:7887-7914 — copyWithPathReplacement(...); confinement check :7895-7905; if (fs.existsSync(destDir)) { fs.rmSync(destDir, { recursive: true }); } :7911-7913.

2\. User-artifact preserve/replace during install: install.js:11431-11442 — staging root :11433; stageUserArtifacts(skillDest, USER\_OWNED\_ARTIFACTS, ...) → copyWithPathReplacement → restoreStagedUserArtifacts → discardStagedUserArtifacts.

3\. Staging root confinement: user-artifact-staging.cjs:66-74 (\_resolveUserArtifactStagingRoot: <configDir>/.gsd-staging/user-artifacts); degrade wrapper \_tryResolveUserArtifactStagingRoot :76-90; import in install.js :885-893.

4\. Statusline replacement gate: install.js:1276 (const forceStatusline = args.includes('--force-statusline');); install.js:13637-13643 (local skip unless --force-statusline); install.js:13784-13795 (handleStatusline replace prompt).

5\. Non-clobber config writes: install.js:9471-9477 ("Cannot parse - DO NOT overwrite user's config"); :9481-9483; :9539-9541 (if (!modified) return;); :9545 write.

6\. Installer migrations: discovered install.js:14527-14529 (discoverInstallerMigrations({ migrationsDir: path.join(\_gsdLibDir, 'installer-migrations') })); applied install.js:11321-11327 (runInstallerMigrations({ configDir: targetDir, runtime, scope, migrations, baselineScan: true })); imports install.js:815-824.

7\. Rollback: rollbackInstallerMigrations defined install.js:10879-10885; null-stub :10685; batch rollback rollbackFinalizedInstallerMigrations install.js:14531-14571 (invoked :14576-14578, :14626); Codex-only pre-config rollback \_codexPreConfigRollback :11219-11227; rollback body :12512-12624; settings pre-write backups/restores :12855-12885, :12973.

8\. Patches backup: install.js:10399-10427 (fs.copyFileSync(installedPath, backupPath), backup-meta.json); read :10592.

9\. Uninstall-side preservation: install.js:8875-8915.

PLUGIN RUNTIME SIDE EFFECTS (.opencode/plugins/gsd-core.js):

1\. Skills-cache destination: gsd-core.js:425-430 — const SKILLS\_CACHE = path.join(os.homedir(), ".cache", "opencode", "gsd-skills");

2\. Writes outside package directory: yes — fs.mkdirSync(SKILLS\_CACHE, {recursive:true}) :434; per-skill fs.mkdirSync(destDir...) :445; fs.writeFileSync(path.join(destDir, "SKILL.md"), rewritten) :446. These are the only fs mutations in the file (grep of writeFileSync|mkdirSync|unlink|rmSync|renameSync|appendFile returned only lines 434, 445, 446). Guarded to package-tree mode: config: hook if (!IS\_PACKAGE\_TREE) return; :464-465; prepareSkillsCache() invoked :499; IS\_PACKAGE\_TREE = fs.existsSync(COMMANDS) :97.

3\. spawnSync location: gsd-core.js:230-237 inside function runHook(hookFile, payload, opts = {}) :210-245 — spawnSync(process.execPath, \[hookPath], { input: JSON.stringify(payload), encoding:"utf8", timeout, cwd: opts.cwd || currentCwd, windowsHide:true }). Missing-hook warning :216-225.

4\. Hook scripts launched (all via runHook): :555 gsd-prompt-guard.js; :561 gsd-read-guard.js; :567 gsd-worktree-path-guard.js; :574 gsd-write-guard.js; :581 gsd-workflow-guard.js; :588 gsd-secret-read-guard.js; :628 gsd-read-injection-scanner.js; :647 and :660 gsd-context-monitor.js; :683 gsd-ensure-canonical-path.js; :689 gsd-check-update.js; :712 gsd-config-reload.js.

5\. Locating GSD tools: resolveRepoRoot(startDir) gsd-core.js:61-82 — walks up to 6 ancestors for directories containing both hooks/ and gsd-core/, fallback path.resolve(startDir, "../..") :81; REPO\_ROOT = resolveRepoRoot(\_\_dirname) :76; HOOKS\_DIR = path.join(REPO\_ROOT,"hooks") :77; COMMANDS/AGENTS/SKILLS/GSD\_CORE :78-81. Namespace converter via require(path.join(REPO\_ROOT,"scripts","fix-slash-commands.cjs")) :114-117.

6\. Environment variables affecting destination paths: none read. Grep for process.env in the plugin returned no matches; grep for env|HOME|XDG returned only :508-511 (shell.env hook sets output.env.GSD\_DIR = GSD\_CORE) and :585 (.env string in a comment). Destination depends only on os.homedir() (:426).

7\. OpenCode configuration read/modify: no file-level read or write of opencode.json/opencode.jsonc (no matches for opencode.json in grep). It mutates the in-memory config object inside the config: hook only (gsd-core.js:463-506), gated by IS\_PACKAGE\_TREE. It reads project config path.join(cwd, '.planning', 'config.json') at :264-266 (contextWarningsDisabled). Sets output.env.GSD\_DIR :509-511.

DISPOSABLE CONFIG DIRECTORY SUPPORT:

Source evidence:

\- install.js:1229-1249 / :1257-1274 — --config-dir / -c parsed into explicitConfigDir.

\- runtime-homes.cjs:461-462 — if (explicitDir) return expandTilde(explicitDir); (overrides env and \~/.config/opencode default).

\- install.js:10741-10742 — OpenCode global targetDir = getGlobalConfigDir(runtime, explicitConfigDir).

\- install.js:14889-14891 — --config-dir with --local is rejected (exit 1).

\- install.js:9456-9458 — OpenCode permission config written under same explicit dir.

\- install-engine.cjs:1905-1912 — commands/skills/agents/native plugin destinations derive from configDir.

\- install.js:11321-11323 — runInstallerMigrations({ configDir: targetDir, ... }).

\- install.js:12315-12321 — legacy cleanup scoped to \[targetDir] when explicitConfigDir !== null \&\& isGlobal.

\- Writes observed targeting the real home irrespective of --config-dir:

\- install.js:7042-7090 — writeNonClaudeDefaults(runtime): const gsdDir = path.join(os.homedir(), '.gsd'); :7044; fs.mkdirSync(gsdDir,...) :7048; acquireInstallMigrationLock(gsdDir) :7055; atomicWriteFileSync(defaultsPath, ...) :7088-7089. Gate :7043 — if (\_hostBehaviors(runtime).nativeModelAliases || process.env.GSD\_TEST\_MODE) return;. Call site install.js:13735 in finishInstall. Opencode hostBehaviors block (capability-registry.cjs:2962-2994) contains no nativeModelAliases field (matches for nativeModelAliases were capability-registry.cjs:613 and :5854 only).

\- install.js:1600 — getCommitAttribution reads getGlobalConfigDir(runtime, null) (i.e. \~/.config/opencode) for the opencode attribution resolver — read, not write.

\- install.js:14463 default homeDir = os.homedir() for legacy scan, overridden by configDirs at :12315-12321; per-package cache root overridden at :14502-14506.

\- Plugin gsd-core.js:425-446 writes \~/.cache/opencode/gsd-skills (package-tree mode only).

\- GSD\_TEST\_MODE gates :14830, :13713, :7043.

INCOMPLETE INSPECTION ITEMS:

\- Plugin OpenCode event-hook registration names (the grep for ^    " event keys at gsd-core.js \~line 508-712) was rejected by permission denial; event names partially established from runHook call sites only.

\- Exact end line of install() return object not fully delimited (function starts install.js:10625; return object observed at :13555).

\- handleStatusline full body after :13800 not read.

\- finalize tail after install.js:14660 read; installAllRuntimes end boundary approximated at :14704.

EXIT CODES:

\- Get-ChildItem \\\\wsl.localhost\\... — exit code 1 (path not found error emitted).

\- Test-Path \\\\wsl$\\... — False.

\- wsl -d ai-jail -e grep -n -- '--opencode' ... — 0 (results returned).

\- wsl -d ai-jail -e grep -n -E "...includes('--local')..." | head -60 — PowerShell parse error, no execution.

\- wsl -d ai-jail -e bash -c '...grep...' — bash exit 127 per-pattern (hasLocal: command not found, etc.); no grep output.

\- wsl -d ai-jail -e grep ... "gsdDir|'\\.gsd'|updateCacheFileName|\\.cache/gsd" — grep exit 2, stderr: grep: Trailing backslash.

\- All other wsl sed/grep/ls/wc invocations — exit 0 with output.

\- Final tool call (grep for plugin event keys) — permission denied by user; not executed.

UNEXPECTED MODIFICATIONS:

\- None. Read-only commands only (ls, wc, grep, sed). No files written, no package JavaScript executed.

ERRORS:

\- Get-ChildItem : Cannot find path '\\\\wsl.localhost\\ai-jail\\home\\aijail\\projects\\opencode-work\\...' because it does not exist. ... ItemNotFound ... PathNotFound

\- head : The term 'head' is not recognized as the name of a cmdlet ... CommandNotFoundException

\- bash: line 1: hasLocal: command not found (and same for askForInstallLocation, InstallLocation, isGlobal)

\- grep: Trailing backslash

\- PowerShell parser errors on --force-statusline/--yes inside a double-quoted wsl ... sh -c string: Missing expression after unary operator '--', Unexpected token 'force-statusline\\' in expression or command.

\- User rejection: The user rejected permission to use this specific tool call.

