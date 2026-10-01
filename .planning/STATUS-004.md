# Status 004 — accepted Phase 080

**As of 2026-10-01. Authoritative roadmap:** `.planning/ROADMAP-004.md` (supersedes 003 for planning; retain 003 historically). Evidence below was reported by OpenCode/user and not independently rerun in this document.

**COMPLETE:** Phases 000–070 (previously accepted; do not rerun), **080 (closure approved after successful live apply and final acceptance)**. **NOT STARTED:** 090, 100, 110, 900, 999.

Phase 080 evidence: 96/96 config, 64/64 static apply, 3/3 `set -e`, 13/13 disposable behavioral cases, 52/52 final live preflight, live apply exit 0, idempotent second apply exit 0 with unchanged managed state, functional isolation/Option C tests, corrected network matrix 22/22 PASS. The initial six `/dev/tcp` failures were **invalid positive tests**, retained as historical evidence; ai-jail filtered mode uses local HTTP CONNECT proxy and intentionally has no direct sandbox DNS/TCP. Rename and mock orchestrator regression tests passed. No Phase 090 install took place.

| Current file | Reported SHA-256 |
|---|---|
| `000-run-all.bat` | `2c188e0e3d95465f44b87b623e991a1723c97ad6615fbe0ff3ba33d5fb399775` |
| `080-setup-sandboxes.bat` | `1122dc891bfddf0259d41d792ad3a6f2da15df9230a41aedbab1f358639ad1b9` |
| `080-setup-sandboxes.ps1` | `84d0f8f4ea1983cfb4f6bf6f151ae2f3262b898391dfe5fd2e6ff15946e05245` |
| `config.env` | `affc004de57e1dfedc5c12d850957904e1f2b9356b82de856e33effe5fd4c0d5` |
| `_common.bat` | `f32827ecbb861a7ae1df9dd280b9ab6cc3a804849761ad8491318b4288214e8b` |
| `080-review-gates.md` | `0086ccabf95029b5090f4202a43fa5c052b8ec05ef689926445e35d9fc5144dd` |
| `phase-080-validation-report.md` | `bd6295ba04d6514fe70ae3f59f3a867305b7aebe9435679e757ae5085e2343d1` |

Installed wrapper hashes: `jail-shell` 46b3b6671e1f68ddec4b4714eb986c418a8d36343e150b659201ec1590c23e8e; `jail-opencode` 580f4200fca25b10c2887341053fe8f5c91ec368261c04a9af165e874226b11d; `jail-comfyui` 698774b3d5373699a2ce60052b7ce9bb7f6ca9ac0c9f5aeffdd18bc6f02ce118. Reported all owned `aijail:aijail`, mode 0700. Preserve historical hashes as history, not production baselines.

**Next action:** Design/review **090 = OpenCode + VS Code + GSD**, not installation yet. Explicitly resolve `INSTALL_VSCODE=0` and safe editor integration; confirm actual applications' CONNECT proxy compatibility. Then **100 = Linux adaptation of the user's 90-step Windows BAT ComfyUI workflow**. Original 90 steps must be inventoried before implementation.

**Safety:** no rerun of 000–070, other-distro or `docker-desktop` operations, global WSL changes, `wsl --shutdown`, auto-mount/interop re-enablement, secret exposure or network weakening. `ENABLE_NONO=0`. Read `HANDOFF.md` for next-session operational context.
