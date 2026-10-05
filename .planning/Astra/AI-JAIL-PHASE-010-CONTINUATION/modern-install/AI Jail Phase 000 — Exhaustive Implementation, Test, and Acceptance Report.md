\# AI Jail Phase 000 — Exhaustive Implementation, Test, and Acceptance Report



\## 1. Executive status



Phase 000 has completed and passed its intended \*\*mock orchestration acceptance contract\*\*.



Final status:



| Deliverable | Status | Established result |

|---|---|---|

| Deliverable 1 | ACCEPTED | Durable state transitions, persistence, reboot-safe resume state, stale-state protection, serialized cooperating writers |

| Deliverable 2 | ACCEPTED | Mock-only approval/execution authorization, strict config bridge, one-use approvals, audit/evidence chain, recovery guards |

| Deliverable 3 | ACCEPTED | Dependency-ordered multi-phase mock orchestration, failure/3010/resume behavior, mock verification semantics, real BAT→engine entry-path mapping |

| Phase 000 mock orchestration | ACCEPTED | Full D1+D2+D3 regression passed after final engine/BAT changes |

| Production APPLY | BLOCKED | Not enabled |

| Production VERIFY | BLOCKED | Not enabled |

| Real installation handlers | UNPROVEN / BLOCKED | Not executed |

| WSL provisioning | UNPROVEN / BLOCKED | Not executed |

| Downloads / artifact acquisition | UNPROVEN / BLOCKED | Not executed |

| Real runtime verification | UNPROVEN | Mock verification deliberately does not count |

| Runtime isolation | UNPROVEN | No claim made |



The decisive final acceptance output was:



```text

DELIVERABLE\_3\_ACCEPTANCE\_OK

PHASE\_000\_MOCK\_ACCEPTANCE\_OK

DELIVERABLE\_3\_EXIT=0

```



This means Phase 000's orchestration machinery is accepted for controlled mock execution. It does \*\*not\*\* mean the product has yet proven a real install, WSL mutation, real downloaded artifacts, real runtime health, or isolation.



\---



\# 2. Test environment and execution model



The final acceptance run was performed on:



```text

Microsoft Windows \[Version 10.0.26300.9457]

```



Project root:



```text

D:\\.coding\\.ai-jail\\modern-install

```



Tests and orchestrator commands were invoked through:



```text

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass

```



The implementation was designed for Windows PowerShell 5.1 compatibility.



Testing was explicitly fail-closed. Negative cases were expected to produce exact diagnostics rather than merely "some failure."



Temporary mock workspaces were used for execution evidence. No production install target was prepared or changed by the D1–D3 acceptance tests.



The final accepted run produced, among others, these temporary evidence roots:



```text

D2:

C:\\Users\\4l3x\\AppData\\Local\\Temp\\aij-d2-tests-166baf10c653419d911d1788342aca4b



D3 focused orchestration:

C:\\Users\\4l3x\\AppData\\Local\\Temp\\AIJ-D3-f35ad9bb989748c3ba83de5a6ab92a26



D3 BAT/engine entry integration:

C:\\Users\\4l3x\\AppData\\Local\\Temp\\AIJ-D3-ENTRY-5f4345679de749c38b67c30af370e6ee

```



These are test evidence locations, not production state locations.



\---



\# 3. Files introduced, replaced, or materially established



The following inventory represents files created, introduced from the D2 package, or materially replaced during Phase 000 work.



\## 3.1 Core Phase 000 implementation



\### `000-config.ps1`



Purpose:



\- authoritative parser for `config.env`;

\- exactly controlled configuration schema;

\- rejects malformed, unknown, duplicate, and unsafe data;

\- handles BOM/encoding constraints;

\- permits valid empty allowlists;

\- permits numeric versions where allowed;

\- rejects unsafe/reserved Windows names.



Established as the only authoritative interpretation of the Phase 000 config.



\### `000-review.ps1`



Purpose:



\- performs Phase 000 offline structural review;

\- loads configuration through `Read-AijConfig`;

\- reviews discovered phases without executing their install behavior;

\- provides the REVIEW path used by the engine.



The Phase 000 engine requires this reviewer to pass before continuing.



\### `000-dependencies.ps1`



Purpose:



\- discovers the actual phase inventory;

\- validates phase requirements documents;

\- enforces phase mode/security/install-policy contracts;

\- defines and validates prerequisite relationships;

\- proves automatic execution authorization remains false.



The discovered prerequisite graph is discussed in section 7.



\### `000-manifest.ps1`



Purpose:



\- produces deterministic blocked PLAN snapshots;

\- binds configuration and source identities;

\- discovers phase candidates;

\- leaves execution authorization false;

\- has no selected production actions;

\- has no resolved production artifact lock;

\- never treats PLAN creation as execution authorization.



\### `000-state.ps1`



Purpose:



\- creates the Phase 000 state draft;

\- defines canonical wrapper/state validation;

\- represents phase evidence and progression;

\- maps result codes into state transitions;

\- consumes transient execution authorization;

\- implements `3010` as a same-phase reboot requirement;

\- creates resume directives;

\- never infers runtime verification from successful process exit.



\### `000-state-store.ps1`



Purpose:



\- durable state persistence;

\- strict UTF-8/canonical validation;

\- state fingerprint verification;

\- compatibility with the established draft APIs;

\- compare-and-replace state updates;

\- stale-state detection;

\- reparse protection;

\- durable flush;

\- cooperative writer serialization.



Its accepted synchronization model uses a shared named mutex derived from the normalized absolute state path.



The mutex covers the previous-state read/fingerprint check through durable temp write, pre-commit revalidation, commit, and readback.



This guarantees cooperating writers using the same store contract cannot both commit from the same previous SHA.



It is not claimed as protection against a fully hostile process that ignores the protocol.



\### `000-engine.ps1`



Initial behavior:



\- REVIEW implemented;

\- PLAN implemented but intentionally blocked;

\- APPLY blocked;

\- VERIFY blocked;

\- generic `/from` and `/skip` blocked.



D3 later replaced the engine with an integration that additionally accepts the explicit mock-only entry modes:



```text

/mock-execute

/mock-resume

```



Production `/apply` and `/verify` remain blocked.



\### `000-run-all.bat`



Initial behavior:



\- fixed mode dispatch;

\- REVIEW/PLAN/APPLY/VERIFY vocabulary;

\- normalizes PowerShell result to `0`, `1`, or `3010`;

\- blocked production APPLY/VERIFY through the engine.



D3 replaced it to additionally expose:



```text

/mock-execute <workspace> <approval-path>

/mock-resume  <workspace> <approval-path>

```



These are explicitly mock-only paths.



Generic production resume/skip remains disabled.



\### `\_common.bat`



Replaced during D2.



Old risk:



\- config values could be imported through raw CMD parsing;

\- legacy `:run\_phase` could serve as an execution bypass.



Accepted D2 behavior:



\- config is validated by the authoritative PowerShell parser before CMD receives values;

\- exactly the allowed configuration keys are exported;

\- empty allowlists survive;

\- rejected config does not leave dangerous partially imported values;

\- unknown config cannot be used to set `PATH`, approval variables, distro variables, or similar command environment state;

\- legacy arbitrary `:run\_phase` execution is blocked.



\---



\# 4. Deliverable 2 files introduced



The D2 preparation package introduced or supplied:



```text

000-authorization.ps1

000-authorization.tests.ps1

000-config-export.ps1

000-deliverable2.tests.ps1

000-mock-control.ps1

BASELINE-SHA256.json

DELIVERABLE-2-HANDOFF.md

PACKAGE-SHA256.txt

```



`\_common.bat` was intentionally replaced as part of this package.



The reference hash/handoff files were records, not executable installer logic.



\## `000-config-export.ps1`



Purpose:



\- bridge authoritative config parsing into CMD;

\- prevents `\_common.bat` from reparsing untrusted config syntax itself.



\## `000-authorization.ps1`



Purpose:



\- creates and verifies the D2 mock plan;

\- establishes target/source/config/artifact bindings;

\- creates explicit approval receipts;

\- writes and validates audit evidence;

\- consumes approval once;

\- invokes only the built-in mock effect;

\- persists result transitions.



D2 intentionally supports only phase `010`. `Assert-AijMockPlan` rejects any D2 mock PLAN whose phase is not `010`; it also revalidates locked config/source bytes before loading dependency-sensitive code.



\## `000-mock-control.ps1`



The contract extraction found no exported function definitions in the section selected by the extractor. D2 behavior was driven by the authorization/public mock functions in `000-authorization.ps1`.



This file remains source-bound and therefore part of plan identity even where the accepted tests do not invoke public functions from it.



\---



\# 5. Deliverable 3 files introduced



\## `000-orchestration.ps1`



New D3 mock orchestration layer.



Responsibilities:



\- build a complete multi-phase mock orchestration plan;

\- inherit source/config/target locking;

\- explicitly add the D3 orchestrator itself to the source lock;

\- preserve empty artifact acquisition;

\- bind the complete phase dependency graph;

\- create per-phase controlled exit sequences;

\- track mock verification results separately from production runtime verification;

\- require fresh approval for each phase attempt;

\- require explicit resume semantics after `3010`;

\- persist mock orchestration state across a new PowerShell process;

\- stop on failure, unknown exit, or mock verification failure.



The D3 source lock takes the existing D2/base lock and explicitly adds `000-orchestration.ps1`; source identities are sorted and hashed.



The D3 plan records an explicit empty artifact lock, disables network acquisition and downloaded-code execution, binds target/source/config identity, includes the per-phase plan, and keeps `ProductionExecutionAuthorized = false`.



\## `000-orchestration.tests.ps1`



Focused D3 orchestration acceptance suite.



Final result:



```text

D3\_ORCHESTRATION\_FOCUSED\_OK assertions=107

```



\## `000-entry-orchestration.tests.ps1`



Tests the actual:



```text

000-run-all.bat

&#x20;   ->

000-engine.ps1

&#x20;   ->

000-orchestration.ps1

```



entry route.



Final result:



```text

D3\_ENTRY\_INTEGRATION\_OK assertions=35

```



\## `000-deliverable3.tests.ps1`



Final consolidated regression runner.



Runs:



```text

000-deliverable2.tests.ps1

000-orchestration.tests.ps1

000-entry-orchestration.tests.ps1

```



and requires success markers plus child exit `0`.



It was corrected once because D2 deliberately emits the exact controlled diagnostic:



```text

D2\_FAILURE\_AUDIT\_UNAVAILABLE

```



twice during audit-unavailable negative coverage.



The first wrapper incorrectly treated all stderr as fatal.



The accepted wrapper now permits \*\*only that exact known D2 stderr line\*\* for the D2 suite. Any other stderr remains a failure.



Final D2 observation from the runner:



```text

EXPECTED\_STDERR: D2\_FAILURE\_AUDIT\_UNAVAILABLE count=2

SUITE\_OK: 000-deliverable2.tests.ps1

```



\---



\# 6. Diagnostic / inspection files used during development



\## `000-deliverable3-contract.extract.ps1`



Read-only contract extractor used before modifying the D3 entry path.



It gathered:



\- hashes of core files;

\- full `000-engine.ps1`;

\- full `000-run-all.bat`;

\- D2 authorization functions;

\- dependency functions;

\- relevant requirements lines.



It made no target/WSL/install changes.



\## `DELIVERABLE-3-CONTRACT.txt`



Generated extractor output.



The pre-D3-entry snapshot contained these hashes:



| File | SHA-256 at contract-extraction time |

|---|---|

| `000-engine.ps1` | `89A3372B19CBFD00422FCB38C83096754CA0DBBC50BFAA29DC4731B214A65DC1` |

| `000-run-all.bat` | `200D0A0E0441627FE3EB7F3ACBECA7B33BB483D47016CC498F05F898144B9347` |

| `000-authorization.ps1` | `58ABB461CCECA705E786C04FD20B3BEEE4BE0829622089613D1A011376197A35` |

| `000-mock-control.ps1` | `87ABB8E3DC2C7EF7F2F2F762AF784E5E748679CE20AB8717EE94105DC1489CA6` |

| `000-dependencies.ps1` | `2AC41C819E5DC132079EB32058C10398D83149BD03BE25AB02AD3B7C3B5313FE` |

| `000-state.ps1` | `907D0CB14AADC46141544737D4FE0C65EE63DAB05AB5475C4F84627D1AA6B7E1` |

| `000-state-store.ps1` | `A0D1E6611AB2B722546812DE98E8B9EB9B35EA322C25E74114985D08D321F34E` |

| `\_common.bat` | `E08BFAE777A7AB94A1D570C4BE268A3C11B2BFC691A2E6E4574691FABF554081` |



These identities were recorded by the extractor.



\*\*Important:\*\* the hashes for `000-engine.ps1` and `000-run-all.bat` above are historical. Both files were intentionally replaced during D3 entry integration and therefore those two hashes are now stale.



A next-phase baseline should regenerate hashes rather than reuse these two values.



\---



\# 7. Phase dependency graph established



The dependency engine currently establishes this graph:



| Phase | Required predecessor evidence |

|---|---|

| `010` | none |

| `020` | `010 RUNTIME\_PASS` |

| `030` | `010 RUNTIME\_PASS`, `020 RUNTIME\_PASS` |

| `040` | `030 RUNTIME\_PASS` |

| `050` | `030 RUNTIME\_PASS`, `040 APPLIED` |

| `060` | `030 RUNTIME\_PASS`, `040 APPLIED`, `050 RUNTIME\_PASS` |

| `070` | `030 RUNTIME\_PASS`, `040 APPLIED`, `050 RUNTIME\_PASS`, `060 RUNTIME\_PASS` |

| `080` | `030 RUNTIME\_PASS`, `040 APPLIED`, `050 RUNTIME\_PASS`, `060 RUNTIME\_PASS`, `070 RUNTIME\_PASS` |

| `090` | `030 RUNTIME\_PASS`, `040 APPLIED`, `050 RUNTIME\_PASS`, `060 RUNTIME\_PASS`, `070 RUNTIME\_PASS`, `080 APPLIED` |

| `091` | `050 RUNTIME\_PASS`, `070 RUNTIME\_PASS`, `080 APPLIED`, `090 RUNTIME\_PASS` |

| `092` | `050 RUNTIME\_PASS`, `060 RUNTIME\_PASS`, `070 RUNTIME\_PASS`, `080 APPLIED`, `090 RUNTIME\_PASS` |



This graph is explicitly defined by the accepted dependency library.



The distinction between `APPLIED` and `RUNTIME\_PASS` is important.



For D3 mock orchestration:



\- `APPLIED` requires successful persisted apply evidence;

\- `RUNTIME\_PASS` additionally requires a matching mock VERIFY audit record whose phase-evidence hash equals the prior apply evidence hash.



The D3 dependency check enforces that distinction.



A future \*\*real\*\* dependency evaluator must not allow D3 mock VERIFY evidence to satisfy real runtime prerequisites.



\---



\# 8. Phase inventory policy established



Phases `010` and `020` retain their legacy read-only execution contract.



The inventory requires their requirements document to contain:



```text

execution.read\_only = true

```



and rejects an unexpected modern `mode` field for those two phases.



They are classified internally as:



```text

LEGACY\_READ\_ONLY\_QUERY

```



Later phases must use the supported modern policy modes:



```text

REVIEW\_ONLY

OFFLINE\_REVIEW\_ONLY

```



The inventory also checks that installation policy fields such as:



```text

enabled

production\_apply\_authorized

```



are not enabled.



Security flags and dependency declarations are structurally validated before inventory acceptance.



No inventory entry is permitted to report automatic execution authorization.



\---



\# 9. Security-critical phase classification



The dependency/inventory layer designates these as security-critical:



```text

010

020

030

040

050

070

080

```



That classification already exists in the Phase 000 inventory and should be preserved when designing real phase execution/verification.



\---



\# 10. Deliverable 1 — what was tested and established



\## 10.1 Manifest/source binding



Final regression output:



```text

PASS: VALID\_PLAN\_BASELINE

PASS: STATE\_MODULES\_BOUND\_TO\_PLAN

PASS: SOURCE\_COUNT\_33

MANIFEST\_SOURCE\_LOCK\_REGRESSION\_OK

```



Established:



\- blocked PLAN generation succeeds;

\- state modules are source-bound;

\- the \*\*base Phase 000 production manifest currently binds 33 sources\*\*.



This count is important.



D3 did not silently change that base-manifest count. Instead, D3 creates its own orchestration source lock on top and explicitly binds `000-orchestration.ps1`.



If the next phase adds another production source directly to the base PLAN inventory, the expected source count may intentionally change and the D1 binding test must be updated only as part of that deliberate change.



\## 10.2 Manifest regression



Passed:



```text

KNOWN\_VALID\_BLOCKED\_SNAPSHOT

DETERMINISTIC\_REPEATED\_SNAPSHOT

READABLE\_BLOCKED\_SUMMARY

DISCOVERED\_MOCK\_BAT\_NOT\_EXECUTED

SOURCE\_CHANGE\_INVALIDATES\_SNAPSHOT

CONFIG\_CHANGE\_INVALIDATES\_SNAPSHOT

GUARD\_UNEXPECTED\_ACCEPTANCE

GUARD\_UNRELATED\_EXCEPTION

GUARD\_OPERATION\_NOT\_EXECUTED

UNKNOWN\_CONFIG\_REJECTED

UNSAFE\_DEPENDENCY\_REJECTED

MISSING\_MANIFEST\_SOURCE\_REJECTED

DISABLED\_APPROVAL\_REQUIREMENT\_REJECTED

```



Reported:



```text

MANIFEST\_REGRESSIONS\_OK positive=6 negative=4 guard=3

```



Established:



\- snapshots are deterministic;

\- mere discovery of a BAT file never executes it;

\- source changes make a plan stale;

\- config changes make a plan stale;

\- unsafe dependency declarations fail closed;

\- missing bound production sources fail;

\- required approval policy cannot silently be disabled.



\## 10.3 State validation regression



Passed:



```text

VALID\_STATE\_BASELINE

CORRUPTED\_PLAN\_FINGERPRINT\_REJECTED

MANIFEST\_JSON\_MISMATCH\_REJECTED

PLAN\_EXECUTION\_AUTHORIZED\_REJECTED

PLAN\_APPROVAL\_RECORDED\_REJECTED

PLAN\_READY\_FOR\_APPROVAL\_REJECTED

UNEXPECTED\_ARTIFACT\_LOCK\_REJECTED

UNEXPECTED\_SELECTED\_ACTION\_REJECTED

INVALID\_CONFIG\_IDENTITY\_REJECTED

PREVERIFIED\_TARGET\_REJECTED

DUPLICATE\_SOURCE\_IDENTITY\_REJECTED

INVALID\_SOURCE\_IDENTITY\_REJECTED

DUPLICATE\_PHASE\_CANDIDATE\_REJECTED

PHASE\_AUTHORIZATION\_REJECTED

INVALID\_PHASE\_IDENTITY\_REJECTED

EMPTY\_SOURCE\_INVENTORY\_REJECTED

EMPTY\_PHASE\_INVENTORY\_REJECTED

GUARD\_UNEXPECTED\_ACCEPTANCE

GUARD\_UNRELATED\_EXCEPTION

GUARD\_SKIPPED\_OPERATION

```



Reported:



```text

STATE\_REGRESSIONS\_OK positive=1 negative=16 guard=3

```



Established:



\- PLAN state cannot arrive pre-authorized;

\- PLAN state cannot arrive pre-approved;

\- PLAN cannot pretend to be ready for approval;

\- target cannot begin pre-verified;

\- artifact lock cannot unexpectedly appear;

\- selected production actions cannot unexpectedly appear;

\- malformed, duplicate or empty source/phase inventories are rejected.



\## 10.4 State/manifest binding



Passed:



```text

VALID\_BASELINE

MANIFEST\_JSON\_MISMATCH\_REJECTED

STATE\_BINDING\_REGRESSION\_OK

```



Established:



\- state fingerprinting binds to exact manifest content, not merely a superficially matching object.



\## 10.5 State-store API binding



Passed:



```text

VALID\_STATE\_PERSISTENCE\_BASELINE

UNSAFE\_PHASE\_EVIDENCE\_REJECTED

STATE\_STORE\_BINDING\_REGRESSION\_OK

```



Established:



\- valid state round-trips;

\- unsafe phase evidence cannot become durable through the store.



\## 10.6 State-store corruption tests



Passed coverage included:



```text

INVALID\_EXPECTED\_HASH\_REJECTED

MISSING\_STATE\_FILE\_REJECTED

EMPTY\_STATE\_FILE\_REJECTED

UTF8\_BOM\_REJECTED

MALFORMED\_UTF8\_REJECTED

MALFORMED\_ENVELOPE\_JSON\_REJECTED

EXTRA\_ENVELOPE\_FIELD\_REJECTED

UNSUPPORTED\_ENVELOPE\_SCHEMA\_REJECTED

WRONG\_EXPECTED\_BINDING\_REJECTED

STALE\_STATE\_FINGERPRINT\_REJECTED

MALFORMED\_INNER\_STATE\_JSON\_REJECTED

NONCANONICAL\_STATE\_JSON\_REJECTED

SELF\_CONSISTENT\_UNSAFE\_STATE\_REJECTED

PREEXISTING\_DESTINATION\_REJECTED

FAILED\_WRITE\_LEFT\_NO\_TEMPORARY\_RESIDUE

```



Guard controls also passed.



Established:



\- persisted state requires strict UTF-8;

\- BOM is not silently accepted;

\- wrapper and inner-state JSON are validated;

\- canonical representation matters;

\- self-consistent but unsafe state remains invalid;

\- stale fingerprints fail;

\- failed writes do not leave orphan temp material.



\## 10.7 Reparse protection



Passed:



```text

DIRECT\_DIRECTORY\_BASELINE

FINAL\_DIRECTORY\_JUNCTION\_REJECTED

ANCESTOR\_JUNCTION\_REJECTED

STATE\_STORE\_REPARSE\_REGRESSION\_OK

```



Established:



\- direct ordinary state directories are accepted;

\- final-directory junctions are rejected;

\- ancestor junctions are rejected.



\## 10.8 PLAN-state integration



Passed:



```text

ENGINE\_SYNTAX

PLAN\_EMITS\_BLOCKED\_STATE

MACHINE\_READABLE\_PLAN\_AND\_STATE

STATE\_BOUND\_TO\_EXACT\_PLAN

STATE\_FINGERPRINT

ALL\_PHASE\_EVIDENCE\_UNVERIFIED

PLAN\_STATE\_INTEGRATION\_OK

```



Established:



\- PLAN emits a machine-readable state draft;

\- the draft is tied to the exact snapshot;

\- no phase begins with runtime evidence.



\## 10.9 Runtime state transition regression



Passed:



```text

BLOCKED\_BASELINE

SUCCESS\_TRANSITION\_APPLIED

FAILURE\_TRANSITION\_APPLIED

UNKNOWN\_TRANSITION\_FAILS\_CLOSED

REBOOT\_TRANSITION\_APPLIED

BLOCKED\_STATE\_CANNOT\_EXECUTE

INITIAL\_STATE\_PERSISTED

ACTIVE\_AUTHORIZATION\_NOT\_PERSISTABLE

REBOOT\_STATE\_ATOMICALLY\_PERSISTED

STALE\_STATE\_UPDATE\_REJECTED

RESUME\_DIRECTIVE\_USES\_SAME\_PHASE

STALE\_PLAN\_RESUME\_REJECTED

REBOOT\_IS\_NOT\_COMPLETION

GUARD\_UNEXPECTED\_ACCEPTANCE

GUARD\_UNRELATED\_EXCEPTION

GUARD\_SKIPPED\_OPERATION

NO\_TEMPORARY\_RESIDUE

```



Established exact semantics:



\### Exit `0`



State can move to applied-but-unverified evidence.



It does \*\*not\*\* become runtime-verified merely because the phase process returned success.



\### Exit `1`



Execution failure becomes durable and progression stops.



\### Exit `3010`



State becomes:



```text

REBOOT\_PENDING

```



and the resume directive points to the \*\*same phase\*\*.



A `3010` attempt does not count as completion.



\### Unknown exit



Fails closed.



\### Authorization



The transient state:



```text

EXECUTION\_AUTHORIZED

```



is not persistable as durable active authority.



\### Resume



Resume requires:



\- matching persisted state;

\- matching plan SHA;

\- same phase;

\- fresh execution authorization.



\## 10.10 State writer concurrency



Passed:



```text

EXACTLY\_ONE\_COMPETING\_WRITER\_COMMITTED

LOSING\_WRITER\_REJECTED\_AS\_STALE

FINAL\_STATE\_IS\_ONE\_COMPLETE\_CANDIDATE

NO\_PARTIAL\_WRITE\_RESIDUE

STATE\_STORE\_CONCURRENCY\_REGRESSION\_OK

```



The test created two valid different next states from the same previous state and launched two competing PowerShell writers.



Established:



\- exactly one cooperative writer commits;

\- the other receives stale previous-state rejection;

\- final state is one whole candidate, never a blend;

\- no partial temp residue remains.



\---



\# 11. Deliverable 1 compatibility decisions



During D1 state-store hardening, compatibility with the already established API was explicitly preserved.



Important interfaces include:



```powershell

Write-AijStateDraftFile -StateDraft ... -Directory ...

```



with returned information containing:



```text

Path

Sha256

Json

Record

```



and draft-reader support for both established file semantics and directory-based semantics.



Generic runtime state operations use:



```powershell

Read-AijStateFile

Write-AijStateFile

```



with previous-SHA compare-and-replace support.



Exact pre-existing corruption diagnostics were preserved rather than replacing them with generic new messages.



This matters for the next phase: the state store should be treated as an accepted contract rather than redesigned casually.



\---



\# 12. Deliverable 2 — approval and execution gating



D2 created a mock-only execution boundary.



Its mock workspace identity contains:



```text

Kind = MOCK\_ONLY\_DIRECTORY

Path

Id

MarkerSha256

CreatedUtcTicks

```



The workspace is identified by a generated:



```text

aij-mock-<GUID>

```



directory and `workspace.json` marker.



The workspace contains at minimum:



```text

workspace.json

state\\

approvals\\

```



and execution may additionally create:



```text

audit.jsonl

pending.json

result-<approval-id>.json

<approval-id>.used

```



\---



\# 13. D2 PLAN binding



The D2 mock plan binds:



```text

configuration SHA

source-lock SHA

artifact-lock SHA

target SHA

phase

selected controlled exit sequence

```



and states:



```text

ProductionExecutionAuthorized = false

```



Artifact lock semantics are explicit:



```text

Artifacts = empty

NetworkAcquisitionAllowed = false

DownloadedCodeExecutionAllowed = false

```



D2 never downloads or executes plan-supplied code.



The exit-code sequence is interpreted only as data by the built-in mock body.



\---



\# 14. D2 explicit approval model



The D2 exact human approval text is:



```text

APPROVE MOCK <plan SHA> 010 <state SHA>

```



The approval receipt binds:



```text

PlanSha256

StateSha256

Phase

ConfigurationSha256

SourceLockSha256

ArtifactLockSha256

TargetSha256

Resume

ApprovedBy

ApprovedAtUtc

```



and is saved under the workspace approvals directory.



Approval creation requires the exact expected text. 



No environment variable or config key can silently grant this approval.



\---



\# 15. D2 one-use authorization



Before the mock effect, D2 checks:



\- plan still valid;

\- config still matches;

\- source bytes still match;

\- target identity still matches;

\- current state matches;

\- audit committed-state hash matches;

\- approval exists in the audit chain;

\- approval binds current plan/state/config/source/artifact/target;

\- approval owner is current Windows identity;

\- resume flag exactly matches persisted reboot state;

\- approval has not already been consumed.



The approval receives a `.used` record before the built-in mock effect.



A consumed approval cannot execute twice.



\---



\# 16. D2 uncertainty and recovery model



Before the mock effect, D2 creates:



```text

pending.json

```



If execution becomes uncertain after intent/authorization, pending evidence survives.



Subsequent execution detects it and blocks with:



```text

D2\_RECOVERY\_REQUIRED

```



The design intentionally prefers manual reconciliation to blindly rerunning a potentially already-performed effect.



This behavior was tested.



\---



\# 17. D2 audit model



D2 uses a JSONL append-only-at-runtime audit stream.



Each entry has:



```text

Sequence

PreviousSha256

Utc

Event

Phase

PlanSha256

StateSha256

ApprovalSha256

ExitCode

```



and a wrapper SHA.



Chain validation requires:



```text

Sequence = previous + 1

PreviousSha256 = previous entry SHA

```



Recognized events include:



```text

STATE\_INITIALIZED

APPROVAL\_RECORDED

PHASE\_STARTED

PHASE\_RESULT

STATE\_COMMITTED

EXECUTION\_DENIED

```



The writer performs a durable flush.



The schema deliberately excludes arbitrary:



\- config text;

\- target paths;

\- usernames in free-form diagnostics;

\- stdout/stderr;

\- exception text;

\- token-like arbitrary data.



The accepted implementation documents that allowlist directly.



The audit is an integrity/sequencing mechanism, not a cryptographic signature service.



\---



\# 18. Deliverable 2 tests executed



Final D2 acceptance:



```text

DELIVERABLE\_2\_FOCUSED\_OK assertions=83

DELIVERABLE\_2\_ACCEPTANCE\_OK

```



Negative and positive coverage included:



\## Approval absence and tampering



```text

NO\_IMPLICIT\_APPROVAL

NO\_APPROVAL\_NO\_EFFECT

MISSING\_APPROVAL\_BLOCKED

EDITED\_APPROVAL\_NOT\_VALIDATED\_BY\_ITS\_OWN\_HASH

TAMPERED\_APPROVAL\_NO\_EFFECT

DIFFERENT\_VALID\_PLAN\_BLOCKED

```



\## Production/dependency gates



```text

PRODUCTION\_BLOCKED

DEPENDENCY\_BLOCKED

```



\## Artifact/config/source/target binding



```text

MISSING\_ARTIFACT\_LOCK\_BLOCKED

CHANGED\_ARTIFACT\_LOCK\_BLOCKED

CONFIG\_CHANGE\_BLOCKED

SOURCE\_CHANGE\_BLOCKED

CHANGED\_SOURCE\_NOT\_LOADED

TARGET\_CHANGE\_BLOCKED

```



The changed-source negative specifically established that stale changed code is rejected before it is loaded.



\## Recovery and replay



```text

UNCERTAIN\_PREVIOUS\_ATTEMPT\_BLOCKED

ONE\_USE\_APPROVAL\_BLOCKED

STALE\_STATE\_APPROVAL\_BLOCKED

```



\## Audit failure



```text

DAMAGED\_AUDIT\_BLOCKED

UNAVAILABLE\_AUDIT\_SHARING\_VIOLATION

```



and associated no-effect/state-unchanged guards.



The deliberately unavailable-audit paths emit:



```text

D2\_FAILURE\_AUDIT\_UNAVAILABLE

```



This diagnostic is expected negative-test evidence rather than a D2 acceptance failure.



\## Result handling



Tested controlled mock exits:



```text

0

1

77

3010

```



For `0`, `1`, and `77`, tests checked:



```text

durable result

no inferred VERIFY

audit append

audit/state binding

completed attempt cannot repeat

exactly one effect

```



For `3010`:



```text

3010\_PRESERVED

OLD\_APPROVAL\_CANNOT\_RESUME

RESUME\_MUST\_BE\_EXPLICIT

FRESH\_APPROVAL\_SAME\_PHASE\_RESUME

```



\## CMD/config bridge



Passed:



```text

COMMON\_VALID\_AND\_EMPTY\_ALLOWLIST

COMMON\_REJECTS\_UNKNOWN\_KEY

COMMON\_REJECTS\_TARGET\_DRIVE

COMMON\_REJECTS\_PATH

COMMON\_REJECTS\_AIJAIL\_APPROVED

COMMON\_REJECTS\_DISTRO

LEGACY\_EXECUTION\_BYPASS\_BLOCKED

```



Established:



\- valid config passes;

\- empty allowlists survive;

\- unsafe injected CMD variables do not;

\- the old generic execution bypass remains disabled.



\---



\# 19. Deliverable 3 orchestration model



D3 does not weaken D2's deliberate phase-010-only boundary.



Instead, D3 adds a separate higher-level \*\*mock orchestration plan\*\* over the complete phase inventory.



Its plan contains:



```text

Kind = MOCK\_ORCHESTRATION\_PLAN

Scope = MOCK\_ONLY

BaseSnapshotSha256

ConfigurationSha256

SourceFiles

SourceLockSha256

ArtifactLock

ArtifactLockSha256

Target

TargetSha256

PhasePlans

ProductionExecutionAuthorized = false

```



The artifact lock remains empty and disallows network acquisition and downloaded-code execution.



\---



\# 20. D3 per-phase result sequencing



Each phase can receive a predetermined test sequence.



Rules:



\- at least one result;

\- at most eight attempts;

\- any result before the final result must be `3010`.



This permits fixtures such as:



```text

010: \[3010, 0]

```



but not arbitrary sequences such as:



```text

010: \[1, 0]

```



A failure is terminal rather than silently retried.



The sequence is data, not executable code.



\---



\# 21. D3 state progression



D3 determines the next phase as follows:



1\. if state is `REBOOT\_PENDING`, resume the exact persisted phase;

2\. if state is `EXECUTION\_FAILED` or `FAILED\_CLOSED`, refuse progression;

3\. otherwise choose the first still-`UNVERIFIED` phase in the bound phase plan;

4\. after all phase evidence has progressed, no next phase remains.



This preserves strict ordering and prevents skipping.



\---



\# 22. D3 dependency proof



Before approval/execution of each phase, D3 evaluates every prerequisite.



For an `APPLIED` dependency, it requires:



```text

prior.State = APPLIED\_UNVERIFIED

prior.ExitCode = 0

prior.EvidenceSha256 = valid SHA

```



For `RUNTIME\_PASS`, all of that is required plus:



```text

a VERIFY\_PASS record exists in the D3 audit

verified apply-evidence SHA == prior apply-evidence SHA

```



This prevents a random verification record from satisfying a different apply attempt.



\---



\# 23. D3 approval model



D3 approval text is:



```text

APPROVE ORCHESTRATION <plan SHA> <phase> <state SHA>

```



The next phase is derived from state rather than supplied freely by the user.



The approval still binds:



```text

plan

current state

phase

configuration

sources

artifacts

target

resume status

Windows identity

time

```



The exact D3 approval-text construction is present in the accepted orchestrator.



\---



\# 24. D3 workspace files



D3 adds these records to the existing mock workspace:



```text

orchestration-plan.json

orchestration-audit.jsonl

orchestration-pending.json

orchestration-approvals\\

orchestration-result-<approval-id>.json

orchestration-verify-<approval-id>.json

```



The state itself continues to use the accepted D1 state store under:



```text

state\\

```



This deliberately reuses D1 persistence rather than introducing a second state engine.



\---



\# 25. D3 audit model



Recognized orchestration events:



```text

ORCHESTRATION\_INITIALIZED

APPROVAL\_RECORDED

PHASE\_STARTED

PHASE\_RESULT

STATE\_COMMITTED

VERIFY\_PASS

VERIFY\_FAIL

EXECUTION\_DENIED

```



Each record includes:



```text

Schema

Kind

Sequence

PreviousSha256

Utc

Event

Phase

PlanSha256

StateSha256

ApprovalSha256

PhaseEvidenceSha256

EvidenceSha256

ExitCode

```



D3 validates:



\- exact schema/property set;

\- valid phase ID;

\- strict hash formats;

\- event allowlist;

\- chain order;

\- prior SHA binding;

\- valid UTF-8;

\- no BOM;

\- newline-complete JSONL.



The accepted audit parser and schema are implemented in the D3 orchestrator.



\---



\# 26. D3 mock VERIFY semantics



This is one of the most important Phase 000 boundaries.



After a controlled apply result `0`, D3 reads the persisted state back and requires:



```text

phase.State = APPLIED\_UNVERIFIED

phase.ExitCode = 0

phase.EvidenceSha256 = exact result SHA

target identity still matches plan

```



It then creates a separate record:



```text

Kind = MOCK\_ORCHESTRATION\_VERIFY\_RESULT

MockVerificationPassed = true/false

DependencyState = RUNTIME\_PASS or VERIFY\_FAILED

ProductionRuntimeVerified = false

```



Therefore mock verification can satisfy \*\*mock orchestration dependency progression\*\*, but it explicitly does \*\*not\*\* assert real production runtime verification.



This separation must be preserved in later phases.



\---



\# 27. D3 execution transaction



For each approved attempt, D3 performs the following sequence:



1\. load and revalidate plan;

2\. reject existing pending uncertainty;

3\. load current state;

4\. validate state/plan binding;

5\. validate audit/current-state agreement;

6\. reject prior mock VERIFY failure;

7\. compute exact next phase;

8\. prove dependencies;

9\. load approval from the dedicated approval directory;

10\. reject already-used approval;

11\. prove approval is recorded in audit;

12\. prove approval binds config/source/artifact/target/plan/state/phase;

13\. prove approver identity;

14\. prove normal-vs-resume mode;

15\. ensure result sequence still has an attempt;

16\. write `PHASE\_STARTED`;

17\. persist pending intent;

18\. consume approval;

19\. construct transient `EXECUTION\_AUTHORIZED` state in memory;

20\. revalidate plan again;

21\. CAS-read current state again immediately before effect;

22\. execute built-in mock result;

23\. save structured mock result;

24\. write `PHASE\_RESULT`;

25\. invoke D1 state transition;

26\. CAS-persist next state;

27\. write `STATE\_COMMITTED`;

28\. normalize exit;

29\. if exit is `0`, perform mock VERIFY;

30\. clear pending only after the controlled transaction reaches the appropriate end;

31\. return only normalized `0`, `1`, or `3010`.



The accepted implementation is visible in `Invoke-AijD3NextPhase`.



\---



\# 28. D3 focused tests — 107 assertions



Final result:



```text

D3\_ORCHESTRATION\_FOCUSED\_OK assertions=107

```



Coverage established:



\## Full sequential success



Every discovered phase progressed in strict inventory order.



All controlled successful phases produced:



```text

APPLIED\_UNVERIFIED

ExitCode = 0

RuntimeVerified = false

```



plus separately bound mock VERIFY evidence.



\## No production authorization



Test confirmed:



```text

ProductionExecutionAuthorized = false

```



\## No network/artifact execution



Test confirmed:



```text

ArtifactLock.Artifacts.Count = 0

NetworkAcquisitionAllowed = false

```



\## Dependency-state proof



A runtime prerequisite with apply evidence but no matching mock VERIFY evidence was rejected:



```text

D3\_DEPENDENCY\_UNSATISFIED

```



\## Failure stop



A controlled failure in phase `020` produced:



```text

EXECUTION\_FAILED

```



Later phase `030` remained:



```text

UNVERIFIED

```



and no progression was allowed.



\## Unknown exit



Controlled result `77` normalized to failure and persisted:



```text

FAILED\_CLOSED

```



\## `3010`



A controlled `010` sequence:



```text

3010

0

```



proved:



\- `3010` is preserved;

\- state becomes `REBOOT\_PENDING`;

\- resume phase remains `010`;

\- another call without explicit resume is rejected;

\- fresh approval is required.



\## New-process resume



A separate `powershell.exe` process loaded the persisted state and completed the resumed attempt.



Established that resume logic is not dependent only on in-process variables.



This is a process-boundary test, \*\*not a real Windows reboot test\*\*.



\## Approval replay



The resumed approval could not be reused.



\## Pending uncertainty



Presence of the D3 pending marker blocked retry with:



```text

D3\_RECOVERY\_REQUIRED

```



\## Audit truncation



A deliberately truncated orchestration audit was rejected.



\## Mock VERIFY failure



A controlled mock VERIFY failure:



\- returned failure;

\- was persisted/audited;

\- prevented later orchestration progression.



\---



\# 29. D3 real entry-path integration — 35 assertions



Final result:



```text

D3\_ENTRY\_INTEGRATION\_OK assertions=35

```



This suite exercised the actual BAT→PowerShell route rather than calling only orchestration functions.



\## REVIEW



Confirmed:



```text

000-run-all.bat /review

```



still exits `0` and emits:



```text

RESULT: REVIEW\_PASS

```



\## Production APPLY



Confirmed:



```text

000-run-all.bat /apply

```



fails.



Expected engine diagnostic remained:



```text

Mode APPLY is not implemented; no operation executed.

```



\## Production VERIFY



Confirmed:



```text

000-run-all.bat /verify

```



fails.



Expected diagnostic:



```text

Mode VERIFY is not implemented; no operation executed.

```



\## Generic skip



Generic skip remained blocked.



\## Mock success



Actual BAT→engine path returned:



```text

RESULT: MOCK\_PHASE\_EXIT\_0

PHASE 000 EXIT CODE: 0

```



and the process exit code was `0`.



\## Mock failure



Actual entry path returned:



```text

RESULT: MOCK\_PHASE\_EXIT\_1

PHASE 000 EXIT CODE: 1

```



and process exit was `1`.



\## Unknown exit



A controlled internal result `77` became:



```text

RESULT: MOCK\_PHASE\_EXIT\_1

```



while durable state became:



```text

FAILED\_CLOSED

```



\## Reboot-required result



Controlled `3010` propagated through PowerShell and BAT as:



```text

RESULT: MOCK\_PHASE\_EXIT\_3010

PHASE 000 EXIT CODE: 3010

```



The actual process exit code observed by the test was `3010`.



\## Resume



Trying the resume approval through `/mock-execute` failed.



Using:



```text

/mock-resume

```



succeeded.



After resume:



```text

Attempt = 2

State = APPLIED\_UNVERIFIED

RuntimeVerified = false

```



Therefore explicit resume semantics survive the actual Phase 000 entry route.



\---



\# 30. Final consolidated regression



The final acceptance runner reran D1/D2 after the D3 engine and BAT replacements.



This was necessary because changing those source-bound files invalidated earlier source identity assumptions.



Final consolidated sequence:



```text

=== Deliverable 1 and 2 regression ===

...

DELIVERABLE\_1\_ACCEPTANCE\_OK

...

DELIVERABLE\_2\_FOCUSED\_OK assertions=83

DELIVERABLE\_2\_ACCEPTANCE\_OK

EXPECTED\_STDERR: D2\_FAILURE\_AUDIT\_UNAVAILABLE count=2

SUITE\_OK: 000-deliverable2.tests.ps1



=== Deliverable 3 orchestration ===

D3\_ORCHESTRATION\_FOCUSED\_OK assertions=107

SUITE\_OK: 000-orchestration.tests.ps1



=== Deliverable 3 entry integration ===

D3\_ENTRY\_INTEGRATION\_OK assertions=35

SUITE\_OK: 000-entry-orchestration.tests.ps1



DELIVERABLE\_3\_ACCEPTANCE\_OK

PHASE\_000\_MOCK\_ACCEPTANCE\_OK

```



Final CMD result:



```text

DELIVERABLE\_3\_EXIT=0

```



Therefore the D1/D2 behavior is proven against the post-D3 source tree rather than relying only on results from before the engine/BAT replacements.



\---



\# 31. Final behavior statements proven by the acceptance runner



The final runner reported:



```text

Behavior: D1 persistence and reboot-safe state regressions preserved

Behavior: D2 approval, audit and strict-helper regressions preserved

Behavior: dependency-ordered multi-phase mock orchestration verified

Behavior: failure and unknown exits stop orchestration fail-closed

Behavior: 3010 stops and resumes the same phase with fresh approval

Behavior: resume works across a new PowerShell process

Behavior: BAT and engine preserve 0, 1 and 3010

Behavior: production APPLY and VERIFY remain blocked

Behavior: mock verification does not assert production runtime proof

```



All of those statements are now supported by the final accepted regression run.



\---



\# 32. What Phase 000 has NOT established



The following must remain explicitly unproven when planning the next phase.



\## No real WSL provisioning



Phase 000 did not:



\- create a distro;

\- import a distro;

\- terminate a distro;

\- modify WSL configuration;

\- install WSL features;

\- change actual runtime distributions.



\## No real target provisioning



Mock target identity is a controlled temporary directory.



It is not evidence that a real install drive, distro filesystem, sandbox, or application path is correct.



\## No downloads



The mock plan has an explicit empty artifact lock and network acquisition disabled.



No provider artifact was acquired.



\## No downloaded-code execution



No downloaded executable/script/package was executed.



\## No real installer handlers



Real phase BAT installer bodies were not used as production execution handlers.



Phase discovery itself was tested not to execute them.



\## No production APPLY



Still blocked.



\## No production VERIFY



Still blocked.



\## No real runtime-health proof



An exit code of `0` remains only apply evidence.



Mock VERIFY is deliberately labeled:



```text

ProductionRuntimeVerified = false

```



\## No runtime-isolation proof



Nothing in Phase 000 establishes that later application/runtime isolation properties actually hold.



\## No real Windows reboot test



The `3010` workflow survived persistence and a fresh PowerShell process.



It did not yet survive a real host reboot as part of the acceptance suite.



\## Hash-chain logs are not signatures



The audit chains detect corruption/reordering under the assumed trusted-code/operator model.



They are not digitally signed tamper-proof external logs.



\## Cooperative concurrency boundary



The named mutex protects writers that participate in the Phase 000 protocol.



It is not claimed to prevent a hostile process from directly replacing files while ignoring the protocol.



\---



\# 33. Current command surface



Supported top-level Phase 000 concepts now include:



```text

/review

/plan

/apply

/verify

/mock-execute <workspace> <approval-path>

/mock-resume <workspace> <approval-path>

```



Semantic status:



| Command | Current status |

|---|---|

| `/review` | implemented and accepted |

| `/plan` | implemented as blocked/draft planning |

| `/apply` | production blocked |

| `/verify` | production blocked |

| `/mock-execute` | D3 accepted |

| `/mock-resume` | D3 accepted |

| generic `/from` | blocked |

| generic `/skip` | blocked |



The mock routes are testing/orchestration infrastructure. They are not authorization for production installation.



\---



\# 34. Contracts the next phase should treat as frozen unless intentionally revised



The next phase should assume these are established contracts:



1\. authoritative config parsing remains in PowerShell, not raw CMD;

2\. source/config/target/artifact identities must be bound before execution;

3\. successful apply does not imply runtime verification;

4\. execution approval is explicit, exact, state-specific and one-use;

5\. active execution authorization is transient and non-durable;

6\. persisted state updates use previous-SHA compare-and-replace;

7\. `3010` means stop and resume the same phase;

8\. resume requires fresh authorization;

9\. unknown exit codes fail closed;

10\. no skipping unsatisfied dependencies;

11\. uncertainty leaves a durable recovery blocker;

12\. audit failure must never turn an operation into success;

13\. changed source bytes invalidate an existing plan;

14\. stale code must be rejected before being loaded when it is part of the execution trust path;

15\. mock VERIFY can never be silently promoted to production runtime proof;

16\. production APPLY/VERIFY stay blocked until a later phase explicitly implements and tests them.



A change to any of these should be treated as a deliberate Phase 000 contract revision requiring full D1+D2+D3 regression.



\---



\# 35. Data that should be regenerated before next-phase implementation



Before adding real behavior, generate a fresh baseline from the \*\*current\*\* source tree.



In particular:



\- current SHA-256 of `000-engine.ps1`;

\- current SHA-256 of `000-run-all.bat`;

\- current SHA-256 of `000-orchestration.ps1`;

\- current hash of all other Phase 000 trust-path files;

\- current deterministic PLAN SHA;

\- current production source-lock membership/count;

\- current phase requirements identities.



The contract-extraction hashes for engine/run-all are historical because those files were intentionally changed afterward.



Do not build a next-phase approval or artifact baseline from those stale two hashes.



\---



\# 36. Recommended next-phase starting point



If the next implementation step begins with real phase `010`, the existing inventory strongly constrains its design.



Phase `010` is a legacy read-only query phase.



Therefore the safest initial real-path milestone is \*\*not\*\* "turn on production APPLY."



It should instead prove a narrowly scoped real phase-010 execution/verification contract while retaining every Phase 000 gate.



A suitable progression is:



1\. freeze/tag the accepted Phase 000 source state;

2\. regenerate current SHA baseline;

3\. inspect `010-requirements.json` and the `010-\*.bat` implementation together;

4\. document exactly what 010 is allowed to read;

5\. document exactly what 010 must never write;

6\. define structured 010 execution evidence;

7\. define the real criteria for `010 RUNTIME\_PASS`;

8\. execute 010 through a controlled dedicated handler rather than the old arbitrary `:run\_phase`;

9\. preserve explicit approval if the operation crosses the agreed authorization boundary;

10\. persist result using the accepted D1 state store;

11\. perform a real verification step that is distinct from apply exit `0`;

12\. allow phase `020` to proceed only after genuine 010 runtime evidence satisfies the dependency engine;

13\. add success/failure/unknown/stale-source/stale-state/audit/replay/reparse/no-mutation tests;

14\. rerun the complete Phase 000 regression afterward.



The existing dependency graph makes `010 RUNTIME\_PASS` a prerequisite for `020`, and both `010` and `020` become prerequisites for `030`, so establishing the semantics of a \*\*real\*\* runtime pass at 010 is the key next design decision.



\---



\# 37. Recommended real-evidence separation for the next phase



Do not reuse the D3 mock VERIFY record as real evidence.



A future real evidence record should distinguish at least:



```text

execution scope

phase

plan SHA

previous state SHA

result/operation SHA

target identity

real verification method

verification observations

verification result

production runtime verified flag

timestamp

source/config/artifact identities

```



The exact schema can be designed in the next phase, but the key rule is:



```text

MockVerificationPassed = true

```



must never be interpreted as:



```text

ProductionRuntimeVerified = true

```



D3 currently enforces this separation.



\---



\# 38. Artifact/download planning for later phases



When a later phase introduces real artifacts, it must replace the current empty mock-artifact concept with a controlled production artifact lock.



That future lock should be planned to bind:



```text

artifact identity/name

provider/source

version

expected digest

actual digest

staging location

acquisition status

verification status

execution authorization

```



Phase 000 has not yet implemented this because D3 deliberately uses:



```text

Artifacts = @()

NetworkAcquisitionAllowed = false

DownloadedCodeExecutionAllowed = false

```



That boundary is proven and should remain until the artifact-acquisition phase explicitly takes ownership of it.



\---



\# 39. Real reboot planning



Current `3010` semantics are proven at the state/process level.



A later real-reboot acceptance should test:



```text

phase returns 3010

state is durably REBOOT\_PENDING

process ends

host reboots

new process starts

state is read from disk

exact plan/source/config identities still match

same phase is selected

old approval cannot execute

fresh resume approval is required

phase completes

attempt increments

later phase does not run before completion

```



Phase 000 already provides most of the state primitives required for that test.



The missing proof is the actual OS reboot boundary.



\---



\# 40. Test discipline to preserve



The next phase should continue the accepted style:



\- Windows PowerShell 5.1 compatibility;

\- `$ErrorActionPreference = 'Stop'`;

\- explicit exit `0`/`1` and `3010` where applicable;

\- exact diagnostic assertions;

\- valid positive fixtures;

\- negative fixtures;

\- guard controls proving the operation actually ran or did not run;

\- temporary fixtures for tests;

\- source/config/state identity binding;

\- no mutation in offline-review tests;

\- no silent fallback;

\- no broad stderr suppression;

\- fail closed on unexpected values.



The D3 final-runner incident is useful precedent: expected negative stderr should be allowlisted by exact value, not by disabling stderr validation globally.



\---



\# 41. Regression command to retain



The final Phase 000 regression entry point is:



```bat

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "D:\\.coding\\.ai-jail\\modern-install\\000-deliverable3.tests.ps1"



echo DELIVERABLE\_3\_EXIT=%ERRORLEVEL%

```



For the currently accepted source tree the required terminal condition is:



```text

DELIVERABLE\_3\_ACCEPTANCE\_OK

PHASE\_000\_MOCK\_ACCEPTANCE\_OK

DELIVERABLE\_3\_EXIT=0

```



Any later change to a Phase 000 trust-path file should cause this suite to be rerun before claiming the Phase 000 foundation remains intact.



\---



\# 42. Final planning state



Phase 000 can now be considered a stable orchestration foundation with these proven capabilities:



```text

strict configuration parsing

deterministic blocked planning

source/config identity binding

phase inventory validation

dependency graph validation

durable state

atomic compare-and-replace persistence

cooperative writer serialization

reparse protections

explicit one-use approval

transient execution authorization

hash-linked structured audit evidence

recovery blocking after uncertainty

fail-closed unknown-result handling

same-phase 3010 persistence

fresh-approval resume

cross-process resume

dependency-ordered multi-phase mock execution

separate mock VERIFY evidence

real BAT/engine 0/1/3010 propagation

full post-integration regression

```



The foundation does \*\*not\*\* yet provide:



```text

real production execution

real WSL provisioning

real artifact acquisition

real application installation

real runtime-health proof

real runtime-isolation proof

real reboot acceptance

```



Accordingly, the next phase should focus on turning \*\*one narrowly defined real phase\*\* into a proven production-quality execution/verification path while keeping the existing Phase 000 gates intact.



The strongest candidate is the first real dependency root, phase `010`, because it has no prior phase prerequisite and its accepted inventory contract is read-only.



Only after real 010 execution and real 010 verification produce genuine `RUNTIME\_PASS` evidence should the project allow phase `020` to consume that evidence.



That gives the project a controlled transition from:



```text

fully tested orchestration machinery

```



to:



```text

first genuinely proven real phase

```



without prematurely enabling the rest of production APPLY.

