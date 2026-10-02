TASK 091.1A
INTEGRITY:
- Integration directory exists: .../gsd-generation-8c5c-20261002195447-33548/output/opencode (ls RC=0)
- output/opencode/opencode.json SHA-256 a2f07f6d83252ccd0cc1417410e04705b6234765130b392c1e18dfaf298ecbb1 — MATCH (RC=0)
- output/opencode/plugins/gsd-core.js SHA-256 f73b406011caf68b5af178706ac350c215f9d416c51b9de4c01d0580d14a2d97 — MATCH (RC=0)
- output/opencode/gsd-core/VERSION exists: content 1.15.0 (1 line, no trailing newline)
- output/opencode/gsd-core/.gsd-runtime exists: content opencode (1 line)
GENERATED CONFIGURATION:
output/opencode/opencode.json (RC=0):
     1	{
     2	  "permission": {
     3	    "read": {
     4	      "/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548/output/opencode/gsd-core/*": "allow"
     5	    },
     6	    "external_directory": {
     7	      "/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548/output/opencode/gsd-core/*": "allow"
     8	    }
     9	  },
    10	  "mcp": {
    11	    "gsd": {
    12	      "type": "local",
    13	      "command": [
    14	        "npx",
    15	        "-y",
    16	        "-p",
    17	        "@opengsd/gsd-core",
    18	        "gsd-mcp-server"
    19	      ],
    20	      "enabled": true
    21	    }
    22	  }
    23	}
output/opencode/plugins/package.json (RC=0):
     1	{"type":"commonjs"}
home/.gsd/defaults.json (RC=0):
     1	{
     2	  "resolve_model_ids": "omit",
     3	  "runtime": "opencode"
     4	}
No credential values present in any of the three files; nothing redacted.
GSD-NEW-PROJECT ENTRY POINTS:
- output/opencode/commands/gsd-new-project.md — EXISTS (1839 bytes)
- output/opencode/skills/gsd-new-project/SKILL.md — EXISTS (1707 bytes)
- Additional matches from search (fallback search was performed, both expected paths already existed):
- output/opencode/commands/gsd-new-project.md
- output/opencode/skills/gsd-new-project (directory)
commands/gsd-new-project.md — full file, 45 lines (≤80), RC=0:
     1	---
     2	description: Initialize a new project with deep context gathering and PROJECT.md
     3	argument-hint: "[--auto]"
     4	requires: [config, phase, plan-phase]
     5	tools:
     6	  read: true
     7	  bash: true
     8	  grep: true
     9	  write: true
    10	  agent: true
    11	  question: true
    12	---
    13	
    14	
    15	<context>
    16	**Flags:**
    17	- `--auto` — Automatic mode. After config questions, runs research → requirements → roadmap without further interaction. Expects idea document via @ reference.
    18	</context>
    19	
    20	<objective>
    21	Initialize a new project through unified flow: questioning → research (optional) → requirements → roadmap.
    22	
    23	**Creates:**
    24	- `.planning/PROJECT.md` — project context
    25	- `.planning/config.json` — workflow preferences
    26	- `.planning/research/` — domain research (optional)
    27	- `.planning/REQUIREMENTS.md` — scoped requirements
    28	- `.planning/ROADMAP.md` — phase structure
    29	- `.planning/STATE.md` — project memory
    30	
    31	**After this command:** Run `/gsd-plan-phase 1` to start execution.
    32	</objective>
    33	
    34	<execution_context>
    35	@/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548/output/opencode/gsd-core/workflows/new-project.md
    36	@/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548/output/opencode/gsd-core/references/questioning.md
    37	@/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548/output/opencode/gsd-core/references/ui-brand.md
    38	@/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548/output/opencode/gsd-core/templates/project.md
    39	@/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548/output/opencode/gsd-core/templates/requirements.md
    40	</execution_context>
    41	
    42	<process>
    43	Execute end-to-end.
    44	Preserve all workflow gates (validation, approvals, commits, routing).
    45	</process>
skills/gsd-new-project/SKILL.md — full file, 36 lines (≤80), RC=0:
     1	---
     2	name: gsd-new-project
     3	description: "Initialize a new project with deep context gathering and PROJECT.md"
     4	---
     5	
     6	<context>
     7	**Flags:**
     8	- `--auto` — Automatic mode. After config questions, runs research → requirements → roadmap without further interaction. Expects idea document via @ reference.
     9	</context>
    10	
    11	<objective>
    12	Initialize a new project through unified flow: questioning → research (optional) → requirements → roadmap.
    13	
    14	**Creates:**
    15	- `.planning/PROJECT.md` — project context
    16	- `.planning/config.json` — workflow preferences
    17	- `.planning/research/` — domain research (optional)
    18	- `.planning/REQUIREMENTS.md` — scoped requirements
    19	- `.planning/ROADMAP.md` — phase structure
    20	- `.planning/STATE.md` — project memory
    21	
    22	**After this command:** Run `/gsd-plan-phase 1` to start execution.
    23	</objective>
    24	
    25	<execution_context>
    26	@/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548/output/opencode/gsd-core/workflows/new-project.md
    27	@/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548/output/opencode/gsd-core/references/questioning.md
    28	@/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548/output/opencode/gsd-core/references/ui-brand.md
    29	@/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548/output/opencode/gsd-core/templates/project.md
    30	@/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548/output/opencode/gsd-core/templates/requirements.md
    31	</execution_context>
    32	
    33	<process>
    34	Execute end-to-end.
    35	Preserve all workflow gates (validation, approvals, commits, routing).
    36	</process>
No command or skill was executed.
COMMAND AND SKILL COUNTS:
- Direct command definitions (files, commands/, maxdepth 1): 72
- Direct skill directories (skills/, maxdepth 1): 72
PLUGIN PORTABILITY (static only, not loaded; 794 lines / 32877 bytes):
GSD payload/tools location resolution (numbered references):
    64	function resolveRepoRoot(startDir) {
    65	  let dir = startDir;
    66	  for (let i = 0; i < 6; i++) {
    67	    if (
    68	      fs.existsSync(path.join(dir, "hooks")) &&
    69	      fs.existsSync(path.join(dir, "gsd-core"))
    70	    ) {
    71	      return dir;
    72	    }
    73	    const parent = path.dirname(dir);
    74	    if (parent === dir) break; // filesystem root
    75	    dir = parent;
    76	  }
    77	  // No ancestor carried both markers (broken/partial layout — the plugin can't
    78	  // function regardless). Fall back to the package-tree assumption ("../.."),
    79	  // matching the historical fixed-depth behavior and the .opencode/plugins/
    80	  // source layout.
    81	  return path.resolve(startDir, "../..");
    82	}
    83	
    84	// CJS: __dirname is a global, no need to derive from import.meta.url
    85	const REPO_ROOT = resolveRepoRoot(__dirname);
    86	const HOOKS_DIR = path.join(REPO_ROOT, "hooks");
    87	const COMMANDS = path.join(REPO_ROOT, "commands", "gsd");
    88	const AGENTS = path.join(REPO_ROOT, "agents");
    89	const SKILLS = path.join(REPO_ROOT, "skills");
    90	const GSD_CORE = path.join(REPO_ROOT, "gsd-core");
Related refs: line 19 (header: REPO_ROOT = path.resolve(__dirname, "../..")), line 97 (const IS_PACKAGE_TREE = fs.existsSync(COMMANDS)), line 115 (path.join(REPO_ROOT, "scripts", "fix-slash-commands.cjs")), lines 380–383 (GSD_CORE workflows/references/templates/contexts).
Hook script location resolution:
   205	 * @param {string} [opts.cwd]         working directory for the child
   206	 * @returns {{ stdout: string, exitCode: number, timedOut: boolean }}
   207	 */
   208	const warnedMissingHooks = new Set();
   209	
   210	function runHook(hookFile, payload, opts = {}) {
   211	  const hookPath = path.join(HOOKS_DIR, hookFile);
   212	  if (!fs.existsSync(hookPath)) {
   213	    // A missing guard script means the guard is silently NOT enforced — the
   214	    // exact failure mode of #2305 (plugin staged, hooks bundle not). Never
   215	    // break the tool call (the adapter's design contract), but never be
   216	    // silent about it either: warn loudly, once per hook file.
(HOOKS_DIR defined at line 86 from REPO_ROOT.)
Skills-cache destination:
   425	const SKILLS_CACHE = path.join(
   426	  os.homedir(),
   427	  ".cache",
   428	  "opencode",
   429	  "gsd-skills",
   430	);
   431	
   432	function prepareSkillsCache() {
   433	  if (!fs.existsSync(SKILLS)) return null;
   434	  fs.mkdirSync(SKILLS_CACHE, { recursive: true });
   435	  for (const dir of fs.readdirSync(SKILLS)) {
   436	    const srcFile = path.join(SKILLS, dir, "SKILL.md");
   437	    if (!fs.existsSync(srcFile)) continue;
   438	    const raw = fs.readFileSync(srcFile, "utf8");
   439	    // Rewrite @-include paths only; namespace conversion is handled at
   440	    // Read-time via tool.execute.after for workflow/reference files.
   441	    const rewritten = raw
   442	      .replace(/@~\/\.claude\/gsd-core\//g, `@${GSD_CORE}/`)
   443	      .replace(/~\/\.claude\/gsd-core\//g, `${GSD_CORE}/`);
   444	    const destDir = path.join(SKILLS_CACHE, dir);
   445	    fs.mkdirSync(destDir, { recursive: true });
   446	    fs.writeFileSync(path.join(destDir, "SKILL.md"), rewritten);
   447	  }
   448	  return SKILLS_CACHE;
   449	}
Hardcoded absolute paths: none. grep -nE for /home/, /opt/, /usr/, /bin/, /tmp/, /etc/, /var/, /root/, /mnt/, C: → no matches (RC=1).
References to TEST_ROOT: none in plugin — grep -nE for TEST_ROOT, phase090, gsd-generation → no matches (RC=1).
References to the real WSL home: none hardcoded — /home/ → no matches (RC=1); home is obtained dynamically via os.homedir() at line 426 (SKILLS_CACHE). ~ occurrences are only comments/regex literals for ~/.claude/ and ~/.config/opencode (lines 58, 349, 353, 376, 398, 399, 403, 404, 418, 423, 442, 443, 520, 526).
OpenCode event registrations (numbered):
   463	    config: async (config) => {
   509	    "shell.env": async (_input, output) => {
   510	      output.env = output.env || {};
   511	      output.env.GSD_DIR = GSD_CORE;
   512	    },
   513	
   514	    // ── tool.execute.before — PreToolUse hooks ─────────────────────────
   515	    "tool.execute.before": async (input, output) => {
   516	      const claudeTool = mapToolName(input.tool);
   593	    // ── tool.execute.after — PostToolUse hooks ─────────────────────────
   594	    "tool.execute.after": async (input, output) => {
   595	      const claudeTool = mapToolName(input.tool);
   653	    "experimental.session.compacting": async (_input, output) => {
   654	      if (!currentSessionId) return;
   655	      const payload = {
   670	    // ── General event subscriptions ─────────────────────────────────────
   671	    event: async ({ event }) => {
   672	      // session.created → SessionStart hooks
   673	      if (event.type === "session.created") {
   674	        // Track session for context-monitor payloads.
   725	      // attach without a plugin change.
   726	      if (event.type === "session.idle") {
   727	        return;
   737	      // phase-scoped — ADR-1239 §OpenCode).
   738	      if (event.type === "permission.asked" || event.type === "permission.replied") {
   739	        return;
   745	      // future error-class hook can attach without a plugin change.
   746	      if (event.type === "session.error") {
   747	        return;
   794	module.exports = gsdCorePluginExport;
Event branches also observed by grep: file.edited (698), hook payload names PreToolUse (538), PostToolUse (622, 641), PreCompact (656), SessionStart (684, 690), FileChanged (707).
Comparison result: generated output/opencode/plugins/gsd-core.js vs TEST_ROOT/source/node_modules/@opengsd/gsd-core/.opencode/plugins/gsd-core.js:
- source SHA-256 f73b406011caf68b5af178706ac350c215f9d416c51b9de4c01d0580d14a2d97
- both 794 lines / 32877 bytes
- cmp exit code: 0 → BYTE-IDENTICAL
Total plugin excerpt lines shown: 94 (≤100).
PRESERVATION:
- TEST_ROOT/source/package-lock.json SHA-256: 0f849ce86faf92ee3d34aaefbb7ac3941a9a386f8d27aa4555b90c13eee59396 — MATCH (RC=0)
- ls -d /opt/ai-jail-tools → ls: cannot access '/opt/ai-jail-tools': No such file or directory (RC=2) — remains ABSENT
UNEXPECTED MODIFICATIONS:
None reported.
ERRORS:
- grep: Unmatched ( or \( (RC=2) — malformed event-registration grep pattern on first attempt; corrected with -F -e .on\(, results obtained.
- grep: (: No such file or directory (RC=2) — two -e async \(/-e function \( patterns split by shell; remaining patterns returned results.
- Early attempts at variable-expanded commands failed before escaping protocol was established: ls: cannot access '/output/opencode': No such file or directory; sha256sum: /output/opencode/opencode.json: No such file or directory — commands re-issued with literal paths, all succeeded.
- /opt/ai-jail-tools ls error shown above (expected preservation result).
INCOMPLETE ITEMS:
NONE.
STOP.