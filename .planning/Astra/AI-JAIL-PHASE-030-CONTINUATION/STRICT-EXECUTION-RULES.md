# AI Jail — strict execution rules and restrictions

Consolidated 6 October 2026 from the user's supplied rules plus lessons in the subsequent discussion. These govern continuation; new explicit human instructions can change scope. They do not grant installation, scratch creation, testing or deletion authority to the chat.

## Operator and deliverables

1. The human operates. Provide complete source files, commands, review and analysis; the human saves files and runs Windows/WSL/test/download/install commands. Do not run those operations yourself. Reading available files and preparing documents/code is permitted.
2. No claim of test success, creation, verification or acceptance without actual user output. Separate source inspection and syntax parsing from executed behavior.
3. No ZIP deliverables. Supply complete individual implementation files, exact destinations, baseline SHA-256 for replacements and replacement SHA-256. Mark new files NEW rather than inventing a baseline hash.
4. Before replacement, compare current baselines and retain byte-for-byte backups outside the installation source directory. On mismatch, inspect the actual current file; do not force hashes or reconstruct from fragments.
5. Give commands for the correct shell, working directory, elevation requirement, side effects and expected exit semantics. Capture full output and exit status. CMD and PowerShell quoting are not interchangeable. Avoid enormous nested one-liners when a short script is clearer.
6. No plugins, account connections, CI/publication workflows or cross-chat messages are necessary to read supplied files. Do not request them merely because GitHub browsing failed.

## Scope and efficiency

7. Work from complete current scripts, requirements, config, tests and the dependency closure actually used. Read each version once; re-read only changed sections or unresolved interfaces. Collect missing-file requests into one list.
8. State the concrete current-behavior → intended-behavior gap before coding. Deliver one compact contract and cohesive implementation. Avoid another speculative diagnostics subsystem.
9. Reuse authoritative config parsing and applicable existing approval, hashing, evidence, locking, logging and exit patterns. Reuse does not mean executing mock-only mechanisms against live targets or claiming an absent production interface exists.
10. No unrelated Windows repair, Gaming Services work, registry cleanup, WindowsApps permission changes, cosmetic redesign or new general orchestration framework.
11. Keep accepted Phase 000 behavior stable. Shared changes require an explicit reason and relevant regression; do not rewrite the foundation to accommodate a single new status.
12. Stop at the first actual verification failure. Locate its function, statement and real entry path before proposing a fix. No speculative chains of patches or relaxing assertions until they pass.
13. Test meaningful changed behavior and failure boundaries. No assertion quotas or repeated unchanged regressions without a concrete contract requirement or new risk. Once required checks pass, proceed to the next authorized real step.
14. Do not state overall completion percentages or completion-time promises without a defensible remaining-work inventory. Timebox optional diagnostics with a decision/output, not endless investigation.

## REVIEW, PLAN and prerequisite evidence

15. REVIEW is strictly offline/local and non-mutating. No remote metadata, downloads, WSL execution, automatic elevation or installer-target writes. Locally available registry/path evidence can be inspected with appropriately limited claims. A lack of permission is UNKNOWN, never absence.
16. Remote metadata and approved staging belong to PLAN. A separately specified fresh read-only WSL prerequisite observation belongs to PLAN, not REVIEW. Staging never executes downloaded code.
17. Phase 010/020 success is prerequisite information, not authorization for creation or APPLY. A warning completion is not a clean runtime PASS or proof of harmless pending operations.
18. Historical Phase 020 console success is not a durable bound prerequisite artifact. Capture real fresh observations and bind the result to Phase 030 rather than synthesizing evidence or inventing an interface.
19. Reuse accepted Phase 020 logic where possible. The chosen artifact/method must enforce its actual WSL minimum; the host having 2.7.14.0 does not validate a lower fresh-host minimum. Verify CLI option availability.
20. Do not reuse expired plans, consumed approvals or historical evidence as fresh authorization. Do not disable freshness merely to save a new properly approved cycle. Preserve history; avoid unnecessary fresh cycles where no live action is being attempted.

## Name, account and storage protection

21. Preserve the existing per-user `ai-jail` registration and D: storage. No implicit unregister, overwrite, move, adoption, repurpose, deletion or distro execution.
22. Registration identity is per Windows user. A C: destination does not free a name registered by that same account. Bind SID and readable identity appropriately, and recheck the effective account immediately before CREATE.
23. Under `TARGET_DRIVE\DISTRO\wsl`, name and destination form one decision. The supplied design is `ai-jail-fresh` at `C:\ai-jail-fresh\wsl`; current config still differs. Respect recorded human choice, resolve missing approval once, and never confuse design approval with real CREATE permission.
24. Bind applicable host, boot, source, config and target-volume identity. Reject changes, registration conflicts, existing destinations, reparse ambiguity and ambiguous state. Do not resolve a conflict by selecting a new name/path silently.
25. No global .wslconfig changes, WSL-wide shutdowns, automatic reboots or default-distro changes as an incidental setup step. Any necessary broader change needs a concrete explanation and explicit human instruction.

## Reproducible artifact and creation

26. Use an explicitly selected official stable distribution compatible with the agreed project. Do not replace “stable” with “daily” to fit the first convenient download. A daily build exception needs explicit approval.
27. Record version, architecture, exact source, integrity/authenticity method, hash, staged artifact identity, destination, creation command and expected result. Avoid mutable-current semantics in the approved content identity.
28. Enforce the acquisition host policy, including redirects. If official acquisition needs additional hosts, propose the exact policy change; no unrestricted fallback.
29. CREATE consumes the exact verified local artifact. It must not independently select/download another release. Recheck content immediately before use and consider source/artifact changes during staging or use.
30. One explicit one-use approval binds exact PLAN, artifact, account, name, path and operation. Earlier phase approval does not carry over. No actual CREATE until the human approves that concrete operation.
31. Establish pre-state and pending/consumed state before mutation, using applicable existing patterns. Serialize competing operations where needed. Keep recovery behavior proportional but explicit.
32. Preserve native status information, including reboot-required and unknown outcomes. Do not turn an interrupted or ambiguous result into success or automatically replay it.

## VERIFY and recovery

33. Report separately: source supplied/saved; fixture results; live command result; registration/storage result; distro runtime result; application readiness; isolation proof; rebuild proof.
34. Creation alone is not distro startup, security/isolation, CUDA compatibility or application acceptance. A version query alone proves none of those.
35. Define any distro runtime verification command and permission in advance. Keep it minimal and bounded; no incidental package installation, arbitrary downloaded script or application launch.
36. On interruption, inspect the named registration and storage without mutation. No blind retry, automatic unregister, partial-storage deletion, import/adoption or ownership repair. Present a concrete recovery action for separate authorization.
37. Preserve -002 through -008 and other historical evidence. Unknown -005 interruption need not be investigated indefinitely after later success; reopen it if it recurs or becomes relevant.
38. Logs must preserve useful failure stage/exit information without secrets or unnecessary personal paths. Hashes are consistency evidence, not cryptographic signatures of who performed an operation. Redaction must not turn unreadable/unknown into a fabricated clean result.

## Optional feasibility trial and future Linux portability

39. Trial discussion does not authorize scratch creation. Obtain the exact scratch name/path and bounded test scope once, then guide user execution. Keep the production installer and preserved distro out of that experiment.
40. Prefer stock scratch setup unless the user chooses export/import. Verify official export consistency/stopping behavior before suggesting cloning; do not stop/export the preserved distro implicitly.
41. Use actual user workloads and fixed versions/settings. Ask for GPU/VRAM/RAM and missing model/workflow details together. Define success, runtime/memory measures and time limit before running.
42. A pinned-memory probe must have a deliberate safe ceiling, not allocate until host failure. A synthetic pass is not ComfyUI/llama.cpp acceptance. Compare real workflows and diagnose specific failures.
43. .wslconfig applies globally; scratch trials share GPU/RAM/disk resources with other workloads. Do not promise complete host isolation or zero impact from a disposable distro.
44. No automatic scratch cleanup. Unregister only an explicitly identified and approved throwaway target, never a computed or guessed preserved target.
45. Keep WSL-specific behavior separate from reusable Linux application/isolation logic when practical. Do not broaden this phase into a native Linux port or promise that changing a partition makes the existing installer portable.

## Required handoff at each milestone

State the exact baseline, changed files/hashes, actual user-run results, unresolved risks/decisions, preserved session identifiers and the next authorized action. Do not replay conversational detours or imply acceptance from an expected-output example. Keep all real modifications and tests under the operator arrangement above.
