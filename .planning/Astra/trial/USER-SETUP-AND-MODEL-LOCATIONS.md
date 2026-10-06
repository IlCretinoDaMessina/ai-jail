# Time-limited trial — user setup and model locations

Updated: 6 October 2026.

## Hardware and current setup

- CPU: AMD Ryzen 5600X.
- GPU: NVIDIA RTX 3080 Ti. Available VRAM and driver version have not been measured for this trial.
- System RAM: 64 GB.
- Existing ComfyUI installation on Windows 11 is available for comparison. Its installation directory and exact software versions have not been supplied.

## ComfyUI models

Use the existing model root:

```text
D:\Stable-Diffusion\.models
```

The user reports that the models are already available. Match workflow selections to actual files during setup; do not download replacements by default. Do not move, rename or modify the originals.

## Selected workflows

```text
D:\.coding\.ai-jail\flux + redux + pulid.json
D:\.coding\.ai-jail\video animation wan2.2.json
```

Both JSON files have been read without executing them. Flux contains 133 top-level nodes; Wan contains 24. These counts do not establish which branches execute or that their dependencies are installed in Linux.

The user wrote `ThrottledCLIPLoader`. The user will supply its source/dependencies and required workflow inputs when needed. Do not substitute another loader, search for an assumed replacement package, or block planning by demanding every input in advance.

Use copies for trial-specific path adaptations. Preserve the original workflows and working Windows ComfyUI installation.

## Existing language model for llama.cpp

User-supplied location:

```text
C:\Users\4l3x\Documents\Portables\generelSchwerz\Qwen3.8-Flash-Next-GenerelSchwerz\Qwen3.8-Flash-Next-IQ3_XXS
```

This location has been recorded, but its contents have not been inspected. At the llama.cpp setup step, identify the actual model file(s), format, shard set, size, architecture and compatibility. Do not infer these from the folder name. Do not ask for this location again or download a replacement by default.

The Wan GGUF diffusion weights are separate from this language model. OpenCode's local-provider and tool-use compatibility must be checked with the actual language model; availability alone does not establish compatibility.

## Operator arrangement and restrictions

- The user operates the machine and executes supplied commands. The assistant supplies the plan, files, commands and analysis.
- Nothing in this information sheet authorizes installation, test execution, deletion, global WSL configuration changes or modifications to the production installer.
- Preserve the existing `ai-jail` distro, installer files, historical evidence sessions, model originals and Windows ComfyUI setup.
- Keep the trial separate from production installation and retain the proposed four-hour stop-and-report checkpoint. An incomplete trial is not automatically a WSL failure.
- Request missing details only when required by the current step. Do not repeatedly request already supplied information.
- No installation, workflow execution or model compatibility test was performed to create this document.

## Companion documents

- `WSL-WORKLOAD-TRIAL-PLAN.md`: full trial procedure, budget and acceptance criteria.
- `HARDWARE-AND-WORKFLOW-ADDENDUM.md`: static workflow inventory and execution refinements.
- `TRIAL-INPUTS-AND-WORKFLOW-CHECKLIST.md`: generic intake checklist; the confirmed details in this sheet supersede its unanswered placeholders.

Provide this sheet alongside the plan when continuing in another chat.
