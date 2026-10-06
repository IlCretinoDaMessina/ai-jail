# Trial intake — supply once; no secrets

Attach the ComfyUI workflow JSON. If available, also attach its API-format export, the working custom-node list/version information and any small required input media. Do not upload large model weights; give their local paths.

## Hardware and existing setup

```text
GPU model(s) and VRAM per GPU:
System RAM:
Windows NVIDIA/other GPU driver version, if known:
Current WSL memory limit / swap setting, if known:
Disk volume and free space available for scratch:
Existing working Windows ComfyUI? Version/path:
Existing Windows workflow runtime, if measured:
Other GPU/WSL jobs that must remain running:
```

## ComfyUI

```text
Workflow JSON filename:
API-format export available?:
Required image/video/audio input paths:
Expected output type, resolution, frames, batch and steps:
ComfyUI model root(s):
Custom-node repositories/versions, if known:
Any paid/API nodes or automatic downloads?:
Maximum acceptable full-job time:
```

The chat must return this dependency mapping before installation:

| Executed node class | Exact repository/version | Python/system dependency | Existing model/input path | Status |
| --- | --- | --- | --- | --- |
| To derive from JSON | Do not guess | To inspect | To match with user files | UNRESOLVED |

Identify GUI versus API JSON, subgraphs, loader filenames, muted/bypassed branches, custom install scripts, conflicting dependencies and outputs that could overwrite original files. Keep a hash of the original and any benchmark copy. An unresolved node is not permission to install arbitrary suggested packages.

## llama.cpp / OpenCode

```text
Exact local GGUF model path(s), including shards:
Model name, architecture and quantization:
Intended context length:
Desired CPU/RAM offload use:
Minimum acceptable generation speed / maximum first-token wait:
Does this model support tool calling, if known?:
OpenCode provider: local llama.cpp proposed / other explicit choice:
If remote comparison desired: provider and spending ceiling (no API key):
```

## Trial choices

```text
Scratch name: aij-trial-20261006 proposed; not yet verified free
Scratch path: C:\ai-jail-trials\aij-trial-20261006\wsl proposed
Report path: C:\ai-jail-trials\aij-trial-20261006\report proposed
Time budget: 240 minutes proposed
Maximum scratch disk use:
Minimum host free RAM / free disk reserve:
Models: read original paths; selected ext4 copies only if explicitly agreed
Cleanup: keep scratch by default
```

## Execution manifest to fill before benchmarks

```text
Ubuntu release/artifact/source/hash:
Scratch registered name + Windows account + storage path:
ComfyUI commit/release:
Python/PyTorch/CUDA versions:
Custom-node commits and frozen dependencies:
llama.cpp commit/binary hash/backend:
OpenCode version/installation identity:
Workflow/input/model identities:
Chosen contexts, seeds, sampling and GPU/offload settings:
Default and alternative launch commands:
Local service addresses/ports:
User acceptance thresholds:
Start time and deadline:
```

If an input is unknown, mark it UNKNOWN and collect it with a read-only command supplied for the correct shell. Do not substitute a guessed value or claim the execution manifest is finalized.
