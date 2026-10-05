# Files to provide to the new chat

The continuation ZIP includes 76 current source/policy/report files under `modern-install/`, plus the new plan, handoff and source hashes. Upload the ZIP as one attachment. It is a reference snapshot, not a replacement package to install over the repository.

The new chat should inventory the bundle once and read the files below in order. It does not need to exhaustively reread every unchanged test or downstream phase before fixing 010. All are included so it can follow dependencies and perform the final compatibility checks without repeatedly requesting more files.

## 1. Read the new instructions first

- `NEW-CHAT-HANDOFF.md` — product scope, accepted state, user-operated workflow and exact next task.
- `PHASE-010-STRICT-PLAN.md` — three deliverables, implementation constraints and acceptance criteria.
- `SOURCE-SNAPSHOT-SHA256.json` — current copied file identities; not historical acceptance proof.

## 2. Read the supplied acceptance report and governing policy

- `modern-install/AI Jail Phase 000 — Exhaustive Implementation, Test, and Acceptance Report.md`
- `modern-install/AI JAIL — STRICT IMPLEMENTATION PLAN AND EXECUTION RULES.md`

The report supersedes the older plan's historical Phase 000 progress statements. The original plan's product requirements and test-discipline rules remain applicable.

## 3. Required current implementation inputs

Read the 010 implementation and requirements first. Read the relevant interfaces in the shared files before designing replacements. These files must be available, even if only the affected functions need detailed inspection.

- `modern-install/010-preflight.ps1`
- `modern-install/010-preflight.bat`
- `modern-install/010-requirements.json`
- `modern-install/config.env`
- `modern-install/000-config.ps1`
- `modern-install/000-config-export.ps1`
- `modern-install/_common.bat`
- `modern-install/000-engine.ps1`
- `modern-install/000-run-all.bat`
- `modern-install/000-requirements.json`
- `modern-install/000-review.ps1`
- `modern-install/000-dependencies.ps1`
- `modern-install/000-manifest.ps1`
- `modern-install/000-state.ps1`
- `modern-install/000-state-store.ps1`
- `modern-install/000-authorization.ps1`
- `modern-install/000-mock-control.ps1`
- `modern-install/000-orchestration.ps1`

## 4. Existing regression files

The consolidated accepted entry is `000-deliverable3.tests.ps1`. It invokes D2, which invokes D1 and the state-store concurrency suite. Include every current test so the new chat can trace this closure and selectively inspect additional parser/entry tests when changing their behavior. None were run while preparing this bundle.

- `modern-install/000-authorization.tests.ps1`
- `modern-install/000-config-encoding.tests.ps1`
- `modern-install/000-config-validation.tests.ps1`
- `modern-install/000-deliverable1.tests.ps1`
- `modern-install/000-deliverable2.tests.ps1`
- `modern-install/000-deliverable3.tests.ps1`
- `modern-install/000-dependencies.tests.ps1`
- `modern-install/000-dependency-denial-matrix.tests.ps1`
- `modern-install/000-dependency-denials.tests.ps1`
- `modern-install/000-engine-integration.tests.ps1`
- `modern-install/000-engine-modes.tests.ps1`
- `modern-install/000-entry-orchestration.tests.ps1`
- `modern-install/000-manifest-source-lock.tests.ps1`
- `modern-install/000-manifest.tests.ps1`
- `modern-install/000-orchestration.tests.ps1`
- `modern-install/000-plan-entry.tests.ps1`
- `modern-install/000-plan-state-entry.tests.ps1`
- `modern-install/000-review.tests.ps1`
- `modern-install/000-runtime-state.tests.ps1`
- `modern-install/000-state-binding.tests.ps1`
- `modern-install/000-state-store-binding.tests.ps1`
- `modern-install/000-state-store-concurrency.tests.ps1`
- `modern-install/000-state-store-focused.tests.ps1`
- `modern-install/000-state-store-reparse.tests.ps1`
- `modern-install/000-state-store.tests.ps1`
- `modern-install/000-state.tests.ps1`

## 5. Discovery and dependency inventory inputs

Keep these numbered BAT/requirements pairs available: Phase 000 discovery and source binding require the full inventory even though only 010 is being implemented. Copying them is not authority to execute them.

- `modern-install/020-requirements.json`
- `modern-install/020-wsl-check.bat`
- `modern-install/030-create-distro.bat`
- `modern-install/030-requirements.json`
- `modern-install/040-requirements.json`
- `modern-install/040-wsl-conf.bat`
- `modern-install/050-isolation-gate.bat`
- `modern-install/050-requirements.json`
- `modern-install/060-base-toolchain.bat`
- `modern-install/060-requirements.json`
- `modern-install/070-ai-jail.bat`
- `modern-install/070-requirements.json`
- `modern-install/080-requirements.json`
- `modern-install/080-setup-sandboxes.bat`
- `modern-install/090-requirements.json`
- `modern-install/090-setup-opencode.bat`
- `modern-install/091-requirements.json`
- `modern-install/091-setup-opencode-plugins.bat`
- `modern-install/092-check-gsd-source.bat`
- `modern-install/092-requirements.json`

## 6. Downstream PowerShell companions — context only

Included to make the source snapshot self-contained. Do not implement or execute these during the 010 milestone. Inspect only when a concrete existing review/import dependency requires it.

- `modern-install/020-wsl-check.ps1`
- `modern-install/030-create-distro.ps1`
- `modern-install/040-wsl-conf.ps1`
- `modern-install/050-isolation-gate.ps1`
- `modern-install/060-base-toolchain.ps1`
- `modern-install/070-ai-jail.ps1`
- `modern-install/080-setup-sandboxes.ps1`
- `modern-install/090-setup-opencode.ps1`
- `modern-install/091-setup-opencode-plugins.ps1`
- `modern-install/092-check-gsd-source.ps1`

## Intentionally not required

- The previous conversation or obsolete D2 replacement package.
- Historical extractors, inventory scripts, contract dumps and stale preparation hashes.
- The old installer, pilot installation, historical generated GSD files or cached packages.
- Temporary acceptance workspaces and machine logs. The supplied report records their historical role; request actual evidence only to resolve a specific ambiguity.
- Credentials, API keys, `.secrets`, SSH keys, full user profiles, virtual disks or installed applications.

No AGENTS.md was found at the inspected drive/repository/modern-install ancestor locations during preparation. A new chat with a different checkout must still check its applicable repository instructions.

If attachments cannot be extracted, provide sections 1–3 first, then the relevant tests and inventory inputs. Missing source files must be reported explicitly; do not fabricate their contents from filenames.
