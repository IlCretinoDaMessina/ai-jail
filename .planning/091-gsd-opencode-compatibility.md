# Phase 091 — GSD–OpenCode Compatibility & Integration Acceptance

**Status:** Planned / blocked on completion of Phase 090 disposable-generation evidence  
**Placement:** Security and compatibility gate before promotion of the Phase 090 OpenCode + GSD integration to production. It is not a post-deployment cleanup phase.  
**Scope:** Pinned OpenCode `v1.18.34`, maintained `@opengsd/gsd-core@1.15.0`, AI Jail `v2.2.0`.  
**Later work:** Phase 200 — Context & Token Optimization remains deferred until after ComfyUI and core integrations.

## Purpose

Resolve and document the compatibility findings from the disposable GSD installer run, validate native OpenCode discovery and runtime paths, and establish defensible acceptance criteria before production promotion. Keep this distinct from dependency acquisition, transaction development, and optimization-plugin experiments.

## Starting evidence (do not repeat completed work)

- Phase 090 Tasks 8C.4B–8C.4E produced and audited a lockfile for exactly `@opengsd/gsd-core@1.15.0`, populated the dedicated cache, and reproduced `npm ci --offline --ignore-scripts` inside AI Jail. Canonical lockfile SHA-256: `0f849ce86faf92ee3d34aaefbb7ac3941a9a386f8d27aa4555b90c13eee59396`.
- Task 8C.5B identified installer-selected `--opencode --global --config-dir` output, additional `~/.gsd` defaults writes, and plugin `~/.cache/opencode/gsd-skills` runtime writes. Installer config writes and plugin in-memory config-hook mutation must not be conflated.
- Task 8C.5C ran the pinned GSD installer once in a disposable, isolated AI Jail environment, with no allowed network hosts and a disposable HOME. It exited 0, generated an `opencode.json`, plugin, hooks and other assets; 1,036 regular generated files and zero symbolic links were reported. The original artifacts remained unchanged and `/opt/ai-jail-tools` was absent.
- The installer warned: **72 shadowed triggers** and **368 unreplaced `.claude` references across 118 files**. Neither warning has yet been accepted as harmless.
- Preserved generation root:
  `/home/aijail/projects/opencode-work/.phase090-staging/gsd-generation-8c5c-20261002195447-33548`
- Earlier inspection reports:
  - [Task 090-8C.5A](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/TASK%20090-8C.5A-report.md)
  - [Task 090-8C.5B](https://github.com/IlCretinoDaMessina/ai-jail/blob/main/.planning/TASK%20090-8C.5B-report.md)
- Upstream research starting points (verify status against the pinned release; a historical issue is not proof of a present defect):
  - [Maintained GSD Core](https://github.com/open-gsd/gsd-core)
  - [GSD issue #4738](https://github.com/open-gsd/gsd-core/issues/4738) — installed-file ownership/manifest tracking
  - [GSD issue #570](https://github.com/open-gsd/gsd-core/issues/570) — earlier Claude-path warning case
  - [GSD issue #983](https://github.com/open-gsd/gsd-core/issues/983) — runtime path-conversion edge cases
  - [GSD issue #1821](https://github.com/open-gsd/gsd-core/issues/1821) — historical OpenCode hook integration issue

## Work packages

### 091.1 — Generated-artifact acceptance audit (read-only)

Inspect only the preserved, generated artifacts; do not rerun the installer. Verify:

1. `opencode.json`, `settings.json`, plugin `package.json`, and disposable `home/.gsd/defaults.json` have expected paths and no embedded staging-only paths or credentials.
2. `/gsd-new-project` is discoverable through the intended OpenCode command or skill surface and points to an existing workflow target. Inventory overlapping command/skill names, including the 72 shadowed-trigger diagnostic. Distinguish an upstream precedence rule from a broken workflow by evidence, not inference.
3. Classify the 368 `.claude` references by exact filename and line: prose/history, cross-runtime fallback, executable path, hook/script, agent or workflow instruction, and undetermined. Do not blanket-replace references. Prioritize operational references.
4. Compare generated plugin with its pinned package source; verify hooks and tool paths resolve after relocation, not merely inside the generation directory. Confirm the plugin's CommonJS boundary and skills-cache destination.
5. Inspect ownership/manifest and migration behavior for implications to transactional upgrade/rollback. Report hashes of critical artifacts and preserve raw evidence.

### 091.2 — Minimal disposable functional compatibility test

After 091.1 review and a separately approved bounded execution plan, run OpenCode with the generated integration inside AI Jail using disposable config, HOME, workspace and cache. Establish command/skill discovery, plugin initialization, hook path resolution and absence of unintended filesystem writes. Begin with offline/non-provider tests. Any real model request or new network permission requires separate explicit approval. No global/home installation.

### 091.3 — Targeted remediation, if required

For verified defects, prefer an upstream-compatible fix or versioned managed adapter over editing hundreds of generated files. Record the exact patch, source hash, affected commands, rollback and regression tests. Do not silently modify the pinned vendor tree or permit unreviewed lifecycle scripts. If a blocker is unresolved, mark production promotion blocked.

### 091.4 — Production acceptance handoff

Deliver a compatibility evidence summary, expected generated-file inventory and hashes, config precedence and persistence map, required paths and ownership, OpenCode plugin/hook tests, migration/rollback implications and residual risks. The Phase 090 production installer must consume these acceptance criteria; passing Phase 091 does not itself authorise production installation.

## Security invariants and exclusions

- ChatGPT is responsible for research, architecture, code design and review. MiMo executes only exact approved commands and returns raw outputs/exit codes, without independent exploration or fixes.
- Keep AI Jail `v2.2.0` isolation and the accepted Phase 080 baseline unchanged; no proxy-source modifications.
- No network allowlist expansion, provider access, secrets access, root/sudo, real-home writes or production promotion without separately scoped approval.
- Keep OpenCode's required loopback proxy exception confined to the eventual jailed process; rerun final negative-egress and filesystem isolation tests before production acceptance.
- Respect version and lockfile integrity; do not enable package lifecycle scripts as a convenience workaround.
- No DCP, Sleev, OpenCode Working Memory, or other context-optimization plugins here. Those belong in Phase 200.
- No ComfyUI scope changes.

## Exit criteria

Phase 091 is complete only when all three acceptance questions are answered with reproducible evidence: **(a)** core GSD commands/skills, including `/gsd-new-project`, are accessible as intended; **(b)** no unresolved operational `.claude` paths impair the OpenCode workflow or escape managed paths; and **(c)** the generated plugin, hooks and persistent state resolve correctly within confined production-equivalent paths. All critical regressions and rollback implications must be documented. Unresolved issues remain explicit production blockers.

## Next authorised action

Resume with **091.1**, adapting the planned read-only Task 090-8C.5D to these focused acceptance questions. Do not run the installer again, install to `/opt`, invoke a model, change production launchers, or enable `--apply` on the strength of this document alone.
