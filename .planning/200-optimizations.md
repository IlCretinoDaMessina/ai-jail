# Phase 200 — Context & Token Optimization

**Status:** Deferred / planning note only  
**Proposed roadmap position:** After the ComfyUI phase and after all core AI Jail integrations are working and accepted. Confirm that phase number `200` is unoccupied when updating the authoritative roadmap.  
**Implementation authorization:** None. No plugin installation, network-policy modification, or production configuration change is authorized by this note.

## Purpose

Measure and, if justified by evidence, reduce context consumption, unnecessary token usage, and repeated work in the completed AI Jail developer environment. Preserve the sandbox's security model, the reliability of OpenCode + GSD, and human-controlled approval gates. Optimization must not be a prerequisite for Phase 090 or ComfyUI.

## Origin of the finding

A review raised the possibility that coding-agent workflows use substantially more context than ordinary browser chat because they may include tool definitions, workspace state, file excerpts, diagnostics, and accumulated tool output. Such overhead is workload- and configuration-dependent; it must be measured rather than assumed. Browser prompt caching does not make messages free, and OpenCode usage cannot automatically be attributed to a particular ChatGPT/Codex/Work quota: billing and usage depend on the actual provider and authentication route. Phase 090's initial free-model test used `opencode/big-pickle` through OpenCode Zen.

### Technologies to evaluate — not approved dependencies

| Candidate | Potential role | Specific review questions |
| --- | --- | --- |
| Dynamic Context Pruning (DCP) | Reduce obsolete or duplicated context/tool output | Current maintainer, release and config schema; pruning behaviour; compatibility with OpenCode version; preservation of important GSD instructions and audit records; prefix-cache trade-offs |
| Sleev | Cross-agent context-management proxy | Current upstream identity and maintenance; whether an extra API-routing proxy creates unacceptable interception, credential, network, or trust boundaries; fit with AI Jail's CONNECT-only proxy |
| OpenCode Working Memory | Maintain durable workspace/session context across compaction | Writes and persistence locations; data retention; model/API-call claims; collision or duplication with GSD memory; protection against untrusted repository content |

**Research links (recheck at implementation time):**

- DCP: https://github.com/Tarquinen/opencode-dynamic-context-pruning
- Working Memory: https://github.com/sdwolf4103/opencode-working-memory
- OpenCode: https://opencode.ai/
- Sleev: identify and independently verify its canonical project URL; the link supplied in the original recap pointed back to DCP and must not be treated as a separate verified repository.

The example DCP settings from the initial finding (`pruningStrategy`, `enableAutoPruning`, `maxContextTokens`, `preserveRecentTurns`) are **not an approved configuration**. Check the exact schema for the pinned release before writing a managed config. Likewise, claims such as a guaranteed 65% cache reuse or zero additional API calls are hypotheses/product claims to validate, not acceptance criteria or established outcomes.

## Entry gates

1. ComfyUI and all earlier core phases have completed their acceptance tests.
2. Phase 090 OpenCode + GSD is stable in its production configuration, with documented rollback.
3. Existing Phase 080 isolation and subsequent security baselines have been recorded and can be rerun.
4. The authoritative roadmap has no conflicting use of Phase 200; add this phase only through the normal documentation approval process.
5. The user separately approves each source acquisition, sandbox host addition, experimental installation, and production promotion.

## Proposed work packages

### 200.1 — Baseline and attribution

- Record the exact OpenCode, GSD, model, provider, authentication route, platform, and context-window details for each benchmark.
- Compare representative small edits, medium development tasks, repeated diagnostics, long sessions, and GSD plan/execution workflows.
- Where exposed by the provider, measure input/output tokens, cached-input tokens, latency, tool-result volume, compactions, and usage/billing counters. Mark unavailable measurements as unavailable; do not infer them from a UI meter.
- Establish correctness, continuity, and reproducibility criteria before changing prompt construction.

### 200.2 — Static security and compatibility audit

- Pin candidate repositories, versions, source hashes, complete dependencies, and licenses; inspect install and runtime side effects.
- Inspect hooks into OpenCode, GSD, model calls, tool output, compaction and persistent state.
- Check filesystem writes, secret exposure, prompt injection surfaces, external calls, localhost behaviour, and possible proxy bypass.
- Reject undeclared hosts or changes to accepted sandbox/proxy semantics. Any host change needs separate approval and negative egress tests.

### 200.3 — Isolated experimentation

- Test **one candidate at a time** in disposable, non-production workspaces with bounded synthetic data.
- Compare against the same baseline tasks and model/provider path, tracking both savings and correctness regressions.
- Test failures: missing or corrupt cache, malformed config, plugin crash, session restart, stale memory, malicious tool output, GSD conflict, rollback, and network rejection.
- Validate prompt-prefix cache effects rather than presuming that more pruning always reduces billed tokens or latency.

### 200.4 — Decision and optional deployment

- Present measured results and the residual security risks to the user; do not auto-enable an optimizer.
- If approved, produce a pinned, managed config and transactional install/uninstall path with explicit state locations and clean rollback.
- Repeat production acceptance, including Phase 080 network/isolation checks and OpenCode/GSD/ComfyUI regressions.
- Record a no-plugin baseline and a documented disable switch.

## Non-negotiable boundaries

- No third-party optimization plugin or extra model-routing proxy is part of Phase 090.
- No hidden provider requests, silent plugin updates, additional credential forwarding, or broadened network access.
- Do not delete or summarize security-critical instructions, user approvals, provenance records, rollback state, or indispensable project decisions merely to save tokens.
- Do not let persistent memory silently override the authoritative project documents (`.planning/`) or executable configuration.
- Preserve the operating model: ChatGPT performs research, architecture and reviews; MiMo/OpenCode receives bounded execution tasks and returns raw evidence. Avoid repeatedly injecting irrelevant histories and huge diagnostic output by design.

## Phase 200 exit criteria

A reproducible benchmark and security review demonstrates either (a) an approved improvement that preserves task correctness, GSD continuity, sandbox isolation and rollback, or (b) a documented decision to retain the unoptimized baseline. Completion does **not** require installing any third-party optimizer.

## Relationship to current work

Continue Phase 090 Task 090-8C.5B and the already-approved OpenCode/GSD integration sequence unchanged. This file is a future-phase planning note, not authorization to change implementation scope.
