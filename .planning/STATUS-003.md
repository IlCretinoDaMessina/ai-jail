# Status handoff 003 — 2026-10-01

**Authoritative planning:** `.planning/ROADMAP-003.md`. Earlier roadmaps are retained as history.

- 000–070: completed according to previous operational evidence; must not rerun.
- 080: INCOMPLETE. Option C wrappers passed prior live individual tests; latest OpenCode report says 96/96 configuration/review and 64/64 simulated apply-path checks PASS. No live apply or live preflight result has yet been returned in this conversation.
- Latest reported SHA-256: `080.bat` ac083337e64258951522f0662fdfe3178af0853e0d6da2a739fbc575df31b4d7; `080-install.ps1` 75fa2c5b690ccc2b96f3bab169835cb939614b121b1ccd499a4cf0a1a801defc; `080-review-gates.md` 030c6ae7587713d932fff9dd659f585960b3bebc12a46afd2d155a26239ba8cf. Verify hashes locally before approving execution.
- Immediate next action: user-approved, read-only first live preflight for `ai-jail` only; capture check-level results, stdout/stderr and exit code; no automatic fixes or apply.
- 090: OpenCode + VS Code + GSD, not started; current `INSTALL_VSCODE=0` needs an explicit plan.
- 100: adapt user's existing 90-step Windows BAT ComfyUI system to Linux, not started.
- 110, 900, 999: not started.

**Safety:** do not touch other distros, `docker-desktop`, global WSL settings or completed phases; do not run `wsl --shutdown`, restore interop/automount, expose credentials or widen runtime allowlists. Historical Phase 080 report is evidence for wrappers, not installer acceptance.

**Documentation changes:** retain `.planning/REVIEW.md` as historical review unless its actual contents demonstrate it is a living status document; append this handoff rather than overwriting uninspected historical records. Merge `REQUIREMENTS-003-ADDENDUM.md` after reconciling original requirement IDs. Review/update `080-review-gates.md` only if its current contents conflict with this status; latest reported corrected version should be preserved.
