# AI Jail — Phase 090
## Programme 090-LB: OpenCode Loopback Compatibility

### Objective

Resolve OpenCode v1.18.34's internal client/server communication problem without compromising the accepted Phase 080 security baseline.

### Established findings

- OpenCode binary verified and staged in WSL.
- OpenCode executes successfully through jail-opencode.
- Authenticated OpenCode server starts successfully.
- Local client/server communication currently fails with HTTP 405.
- CONNECT requests to 127.0.0.1 are rejected with HTTP 403.
- ai-jail v2.2.0 deliberately forces NO_PROXY empty.
- No production changes or installation are authorised.

### LB-01 — Local environment evidence

MiMo performs narrowly scoped, read-only checks requested by ChatGPT.

Output: Raw command results only.

### LB-02 — Compatibility solution design

Owner: ChatGPT.

- Analyse existing network namespace and proxy implementation.
- Determine the smallest feasible compatibility solution.
- Assess security implications.
- Preserve external CONNECT-only networking.
- Identify any required changes.

No implementation.

### LB-03 — Security review

Owner: ChatGPT.

Prepare acceptance criteria covering:

- Sandbox-local loopback isolation.
- No external networking bypass.
- No host or LAN access.
- No cross-project access.
- Credential protection.
- Existing Phase 080 regression requirements.

User approval required before implementation.

### LB-04 — Controlled implementation

ChatGPT prepares exact code changes.

MiMo applies only the authorised changes.

No independent redesign, repairs or additional modifications.

### LB-05 — Compatibility testing

MiMo executes tests supplied by ChatGPT.

Validate actual OpenCode client/server communication and the unchanged external network restrictions.

ChatGPT interprets results.

### LB-06 — Integration continuation

After compatibility acceptance:

1. Complete Phase 090 installer.
2. Integrate maintained GSD Core.
3. Configure OpenCode free models.
4. Implement secured launcher.
5. Run static, mocked, live and regression tests.
6. Update project documentation.

### Permanent restrictions

- Preserve ai-jail v2.2.0 unless separately approved.
- No unrestricted network access.
- No changes to other WSL distributions.
- No automatic modification of Phase 080.
- No unauthorised installation.
- No autonomous progression.
- Reuse previously verified context.
- Stop at every approval gate.