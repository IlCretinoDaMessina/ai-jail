TASK 090-8C.5A
PACKAGE IDENTITY:
{
  "name": "@opengsd/gsd-core",
  "version": "1.15.0",
  "description": "GSD Core is a meta-prompting, context engineering, and spec-driven development system for AI coding agents.",
  "bin": {
    "gsd-core": "bin/install.js",
    "gsd-tools": "gsd-core/bin/gsd-tools.cjs",
    "gsd_run": "gsd-core/bin/gsd_run",
    "gsd-mcp-server": "bin/gsd-mcp-server.js"
  },
  "main": ".opencode/plugins/gsd-core.js",
  "exports": null,
  "files": ["bin","commands","skills","gsd-core","assets","agents",".claude-plugin",".opencode","GEMINI.md","hooks","scripts","!scripts/gen-emitted-baseline.cjs","!scripts/qa-smell-ratchet.cjs","!scripts/live-config-guard.cjs","!scripts/run-tests.cjs","!scripts/affected-tests-lib.cjs","!scripts/run-affected-tests.cjs","!scripts/lint-no-adhoc-regex-escape.cjs","!scripts/lint-allow-test-rule-refs.cjs","pi","vscode"],
  "engines": { "node": ">=24.0.0", "npm": ">=10.0.0" },
  "dependencies": { "@anthropic-ai/claude-agent-sdk": "^0.2.84", "ws": "^8.21.0" },
  "optionalDependencies": { "fallow": "^2.70.0" }
}
scripts (verbatim): includes prepare: npm run build:lib, prepack: npm run build:lib, prepublishOnly: npm run build:lib && npm run build:hooks, build:lib: tsc -p tsconfig.build.json, version: node scripts/sync-manifest-versions.cjs --stage && node scripts/gen-capability-registry.cjs --write && git add gsd-core/bin/lib/capability-registry.cjs, plus build/gen/lint/test script families (npm run generate:identity, npm run build:hooks, node scripts/*.cjs, eslint, c8, stryker) — no preinstall/install/postinstall scripts exist.
- name @opengsd/gsd-core: MATCH; version 1.15.0: MATCH (identity exit 0)
PACKAGE CONTENTS:
- Total file count (excluding nested node_modules): 1088 (contents exit 0)
- Bounded directory listing (depth ≤3, node_modules excluded): ./, ./.claude-plugin, ./.opencode, ./.opencode/plugins, ./agents, ./assets, ./bin, ./commands, ./commands/gsd, ./gsd-core, ./gsd-core/bin, ./gsd-core/bin/lib, ./gsd-core/bin/shared, ./gsd-core/contexts, ./gsd-core/references (+ edge-probe-fixtures, few-shot-examples, prohibition-probe-fixtures), ./gsd-core/templates (+ codebase, research-project), ./gsd-core/workflows (+ autonomous, code-review, complete-milestone, discuss-phase, discuss-phase-assumptions, docs-update, execute-phase, help, new-milestone, new-project, plan-phase, progress, quick, quick-batch, review, transition, update, verify-work), ./hooks, ./hooks/dist, ./hooks/dist/lib, ./hooks/lib, ./pi, ./scripts, ./scripts/baselines, ./scripts/changeset, ./scripts/lib, ./scripts/release-notes, ./skills (92 gsd-* skill directories), ./vscode
- Top-level files: GEMINI.md, LICENSE, README.ja-JP.md, README.ko-KR.md, README.md, README.pt-BR.md, README.zh-CN.md, package.json
RELEVANT FILENAMES (case-insensitive match on opencode|install|integration|setup|config|plugin|adapter|README):
./.claude-plugin/marketplace.json
./.claude-plugin/plugin.json
./.opencode/plugins/gsd-core.js
./README.ja-JP.md ./README.ko-KR.md ./README.md ./README.pt-BR.md ./README.zh-CN.md
./agents/gsd-integration-checker.compact.md ./agents/gsd-integration-checker.md
./bin/install.js
./commands/gsd/ai-integration-phase.md ./commands/gsd/config.md
./gsd-core/bin/lib/adapter-declarative.cjs ./gsd-core/bin/lib/adapter-imperative.cjs
./gsd-core/bin/lib/agent-install-check.cjs ./gsd-core/bin/lib/cjs-command-router-adapter.cjs
./gsd-core/bin/lib/config-loader.cjs ./gsd-core/bin/lib/config-schema.cjs ./gsd-core/bin/lib/config-types.cjs
./gsd-core/bin/lib/config.cjs ./gsd-core/bin/lib/configuration.cjs ./gsd-core/bin/lib/embedding-adapter.cjs
./gsd-core/bin/lib/federated-config.cjs
./gsd-core/bin/lib/health-diagnostic-rules/agent-install.cjs ./gsd-core/bin/lib/health-diagnostic-rules/config-validation.cjs ./gsd-core/bin/lib/health-diagnostic-rules/install-surface-shadowing.cjs
./gsd-core/bin/lib/host-integration-adapters/cline-sdk-binding.cjs ./gsd-core/bin/lib/host-integration-adapters/imperative-hook-bus.cjs
./gsd-core/bin/lib/host-integration-sdk.cjs ./gsd-core/bin/lib/host-integration.cjs
./gsd-core/bin/lib/install-effort-resolver.cjs ./gsd-core/bin/lib/install-engine.cjs ./gsd-core/bin/lib/install-fs-adapter.cjs
./gsd-core/bin/lib/install-model-override-resolver.cjs ./gsd-core/bin/lib/install-profiles.cjs ./gsd-core/bin/lib/install-scope.cjs
./gsd-core/bin/lib/install-shadow-report.cjs ./gsd-core/bin/lib/installed-surface-resolver.cjs
./gsd-core/bin/lib/installer-migration-authoring.cjs ./gsd-core/bin/lib/installer-migration-report.cjs ./gsd-core/bin/lib/installer-migrations.cjs
./gsd-core/bin/lib/installer-migrations/000-first-time-baseline.cjs … 010-antigravity-retire-confighome-artifacts.cjs (incl. 005-opencode-baseline-commands-dir.cjs)
./gsd-core/bin/lib/model-adapter.cjs ./gsd-core/bin/lib/runtime-artifact-install-plan.cjs ./gsd-core/bin/lib/runtime-config-adapter-registry.cjs
./gsd-core/bin/lib/vendor/README.md
./gsd-core/bin/shared/config-defaults.manifest.json ./gsd-core/bin/shared/config-schema.manifest.json
./gsd-core/references/git-integration.md ./gsd-core/references/planning-config.md
./gsd-core/templates/README.md ./gsd-core/templates/config.json ./gsd-core/templates/user-setup.compact.md ./gsd-core/templates/user-setup.md
./gsd-core/workflows/ai-integration-phase.md ./gsd-core/workflows/new-project/steps/auto-mode-config.md ./gsd-core/workflows/settings-integrations.md
./hooks/dist/gsd-config-reload.js ./hooks/gsd-config-reload.js
./scripts/changeset/README.md ./scripts/gen-install-tree-fixtures.cjs ./scripts/gen-plugin-skills.cjs ./scripts/setup-branch-protection.sh ./scripts/slurm-adapter.cjs
./skills/gsd-ai-integration-phase/SKILL.md ./skills/gsd-config/SKILL.md
(match grep exit 0)
INTEGRATION DOCUMENTATION:
README.md (128 lines; 3 OpenCode hits — grep exit 0):
9: **A light-weight meta-prompting, context engineering, and spec-driven development system for Claude Code, OpenCode, Antigravity CLI, Kimi CLI, Kilo, Codex, Copilot, Cursor, Windsurf, and more.**
40: ## Quickstart
44: npx @opengsd/gsd-core@latest
46: The installer prompts for your runtime (Claude Code, OpenCode, Antigravity CLI, Kimi CLI, Kilo, Codex, Copilot, Cursor, Windsurf, and more) and whether to install globally or locally. The installer is required for cross-runtime compatibility — do not copy files from `agents/` or `commands/` directly.
48: On another runtime or without Node.js? See [Install on your runtime](docs/how-to/install-on-your-runtime.md).
101: | [gsd-opencode](https://github.com/rokicool/gsd-opencode) | Original OpenCode port |
Note (fact): referenced docs/how-to/install-on-your-runtime.md is not present in the extracted package (no docs/ directory in contents).
gsd-core/workflows/settings-integrations.md (grep exit 0):
50: … "${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}/gsd-core/bin/${_GSD_SHIM_NAME}" … (runtime-home resolution list)
168: `review.models.opencode`.
200:       { label: "OpenCode", description: "review.models.opencode — bare model id injected into --model, e.g. 'claude-sonnet-4'" }
No standalone OpenCode installation document (e.g. *opencode*.md) exists in the package: NO_EXPLICIT_OPENCODE_INTEGRATION_DOCUMENTATION_FOUND for a dedicated document; OpenCode-related instructions are limited to the README and workflow excerpts above.
INSTALLATION ENTRY POINTS (static only, nothing executed):
- Entry-point paths: bin/install.js (14922 lines, bin gsd-core), gsd-core/bin/gsd-tools.cjs (5596 lines, bin gsd-tools), gsd-core/bin/gsd_run (20 lines, bin gsd_run), bin/gsd-mcp-server.js (31 lines, bin gsd-mcp-server), .opencode/plugins/gsd-core.js (794 lines, main)
- References to OpenCode configuration directories:
- bin/install.js:9493 — const defaultConfigDir = path.join(os.homedir(), '.config', 'opencode');
- bin/install.js:1441-1448 — resolveOpencodeConfigPath(configDir) → opencode.jsonc else opencode.json
- bin/install.js:1463 — ATTRIBUTION_CONFIG_RESOLVERS = { opencode: resolveOpencodeConfigPath, kilo: resolveKiloConfigPath }
- bin/install.js:993-1001 — runtime selection includes 'opencode'; --opencode flag
- bin/install.js:1286 — help text: --opencode Install for OpenCode only; config-dir priority over OPENCODE_CONFIG_DIR
- bin/install.js:1297 — comment: "OpenCode always uses the absolute path (#2376 Windows, #2831 macOS/Linux)"
- bin/install.js:1627-1649 — "Convert Claude Code frontmatter to opencode format"; tool-name mapping to OpenCode
- bin/install.js:859-871 — _copyStaged, convertClaudeCommandToOpencodeSkill, installOpencodeFamilySkills
- Filesystem writes, copies, links, removals:
- bin/install.js — 161 matches of writeFileSync|mkdirSync|copyFileSync|rmSync|unlinkSync|symlinkSync|renameSync; examples: 4347 fs.rmSync(sidecarPath), 4394/4448 fs.rmSync(dirToRemove,{recursive:true,force:true}), 6818/6835/6841 fs.writeFileSync(...), 7048 fs.mkdirSync(gsdDir,{recursive:true}), 7111 fs.mkdirSync(agentsTomlDir,...), 7219 fs.writeFileSync(agentTomlPath,...), 7706 fs.writeFileSync(path.join(categoryDir,'DESCRIPTION.md'),...)
- .opencode/plugins/gsd-core.js — 3 write/mkdir matches: 434 fs.mkdirSync(SKILLS_CACHE,{recursive:true}), 445 fs.mkdirSync(destDir,{recursive:true}), 446 fs.writeFileSync(path.join(destDir,"SKILL.md"),rewritten); 230 spawnSync(process.execPath,[hookPath],{...})
- gsd-core/bin/gsd_run:11-20 — resolves symlink via readlink, then exec node "$dir/gsd-tools.cjs" "$@"
- Calls to package managers / network download commands (bin/install.js, 7 matches — all in strings/comments/help text, no executed invocation identified statically): 193/202 'Bash(npx gsd-core *)' permission-allowlist strings, 1151 curl -fsSL https://fnm.vercel.app/install | bash (advisory text), 1154 'Then re-run: npx ${pkg.name}@latest', 1286 help examples (npx ${pkg.name} …), 11342/11482 comments about npx … --codex / npx cache dirs
- User home, global configuration, permissions, installation paths:
- bin/install.js:1031 const home = os.homedir();
- bin/install.js:7044 const gsdDir = path.join(os.homedir(), '.gsd');
- bin/install.js:8643 const agentsPath = path.join(os.homedir(), '.agents', 'AGENTS.md');
- bin/install.js:10722/10726 try { fs.chmodSync(d, 0o755); } catch(_) { /* Windows */ }
- bin/install.js:9586 defaultConfigDir = path.join(os.homedir(), '.config', 'kilo'); 9629/8399/10774/10854 homedir path normalisation / ~ display
- bin/install.js:1286 --global (config directory) vs --local (cwd); --config-dir override env list incl. OPENCODE_CONFIG_DIR
- .opencode/plugins/gsd-core.js:426 os.homedir() (skills cache location), 434/445 cache mkdirSync
- Commands that would execute during package lifecycle scripts (from manifest): prepare → npm run build:lib → tsc -p tsconfig.build.json; prepack → npm run build:lib; prepublishOnly → npm run build:lib && npm run build:hooks; version → node scripts/sync-manifest-versions.cjs --stage && … && git add …. No preinstall/install/postinstall scripts present. (gsd_run:20 exec node gsd-tools.cjs, bin/gsd-mcp-server.js:24 runServer(...) are runtime entry points, not lifecycle hooks.)
- Inspection output kept within limit; no entry point invoked.
OPENCODE INTEGRATION ARTIFACTS:
- OpenCode plugins: ./.opencode/plugins/gsd-core.js
- OpenCode commands or agents: NONE FOUND (.opencode/ contains only plugins/gsd-core.js; no .opencode/commands or .opencode/agents; related code: gsd-core/bin/lib/installer-migrations/005-opencode-baseline-commands-dir.cjs)
- Skills: FOUND — skills/ (92 skill dirs, e.g. skills/gsd-config/SKILL.md, skills/gsd-ai-integration-phase/SKILL.md)
- MCP configuration: server files FOUND — bin/gsd-mcp-server.js, gsd-core/bin/lib/mcp-server.cjs, gsd-core/bin/lib/mcp-catalog.cjs; dedicated MCP configuration file: NONE FOUND
- opencode.json template: NONE FOUND (no file named opencode.json/opencode.jsonc; gsd-core/templates/config.json is GSD config — first lines {"mode":"interactive","granularity":"standard","workflow":{...}} — 0 opencode hits)
- Explicit integration installer: FOUND — bin/install.js
EXIT CODES:
- Identity read (node): 0
- Contents listing/file count: 0
- Directory re-listing: 0
- README grep: 0
- Documentation grep (md -l): 0
- Doc excerpt reads: 0
- Relevant filename match grep: 0
- Entry-point size listing: 0
- Small entry-point cats: 0
- install.js greps: 0 (one grep: warning: ? at start of expression from a look-ahead pattern in the count expression; counts still returned)
- Home/permission + plugin greps: last grep -c returned 0 matches → shell exit 1 (counts shown: plugin write matches 3, plugin network/package-manager matches 0)
- Step-5 file finds: find/grep -c returned 0 hits → exit 1 for grep -c opencode on templates/config.json (expected zero)
UNEXPECTED MODIFICATIONS:
None reported (all inspections read-only)
ERRORS:
grep: warning: ? at start of expression
(non-fatal; from the C-pattern count expression)
STOP.