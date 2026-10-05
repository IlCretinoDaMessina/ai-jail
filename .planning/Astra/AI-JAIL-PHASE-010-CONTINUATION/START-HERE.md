# Start a new AI Jail implementation chat

Attach the entire `AI-JAIL-PHASE-010-CONTINUATION.zip` to the new chat. It contains the plan, self-contained handoff, exact file inventory and current source snapshot. It is a reference bundle, not an installer or a patch to apply.

Paste this message:

```text
Continue my AI Jail installer project using the attached bundle.

Read NEW-CHAT-HANDOFF.md and PHASE-010-STRICT-PLAN.md first, then the Phase 000 acceptance report and the relevant current source files listed in FILES-TO-PROVIDE.md. The attached local snapshot may be newer than GitHub.

Phase 000 is accepted for mock orchestration. Your next task is to implement real, read-only Phase 010 Windows preflight under the supplied plan. Do not restart Phase 000 or enable production APPLY.

I operate the computer. Provide complete replacement/new files with exact destination paths, then separate copyable Windows CMD verification commands. State elevation, writes, network effects and expected results. Do not run tests or live operations yourself. Wait for my actual output before claiming acceptance or advancing dependent work.

Work in the three consolidated deliverables in the plan. Preserve the accepted state-store interfaces, mock/real separation and fresh-install independence. No WSL invocation, installation, downloads of software, pilot changes or provider calls. Only a specifically described and authorized connectivity probe may use the network during real preflight.

Start by identifying genuinely missing essential inputs, if any. Otherwise give the compact contract delta and the first complete implementation deliverable. Do not respond with another general plan or a promise to continue.
```

If the chat cannot extract the ZIP, give it the two named Markdown documents first and then the first-reading source files in `FILES-TO-PROVIDE.md`. Do not assume that posting a local Windows path gives a cloud chat access to the file.
