# WSL workload feasibility trial: ComfyUI, llama.cpp and OpenCode

Prepared 6 October 2026. Status: planning only. No installation, benchmark, download, WSL command or configuration change has been performed for this trial.

## 1. Decision and scope

Determine whether one disposable WSL2 Ubuntu environment can run the user's actual ComfyUI workflow and existing llama.cpp-compatible model at acceptable speed and memory use, and whether OpenCode can use the local llama.cpp server for a small coding task.

This is a deliberate, time-limited deviation before Phase 030. It is not Phase 030 implementation, security acceptance, a native-Linux comparison, or permission to modify the preserved `ai-jail` distro. Keep `modern-install`, its config, its approved source baselines and historical sessions untouched. Continue the main installer only after the trial report identifies which applications are suitable for WSL and with which settings.

The human executes all commands and saves files. The chat researches, prepares exact commands/configurations, reads supplied results and diagnoses bounded failures. Planning this trial does not authorize unspecified host changes, deletion, paid services or unrelated installations.

## 2. Questions the trial must answer

1. Does the selected GPU work with the selected stable PyTorch build under this WSL environment?
2. Does the real ComfyUI workflow complete repeatedly, with acceptable output, without an OOM/crash or sustained host memory pressure?
3. Is default ComfyUI or `--fast-disk` better for this workload and its actual model storage? Does one targeted fallback help if needed?
4. Can the selected GGUF model run with the intended CPU/RAM offload, and are prompt processing, generation and latency acceptable?
5. Can OpenCode connect to that local server, read/edit only a disposable project and complete a bounded coding task using working tool calls?
6. What parts remain inconclusive because of missing dependencies, model compatibility, storage placement or the time limit?

Do not turn startup success into a workload PASS. Do not turn one failed flag/model combination into a claim that WSL is unusable.

## 3. Required intake before executable commands

Use TRIAL-INPUTS-AND-WORKFLOW-CHECKLIST.md. Collect missing answers together, and reuse information already supplied.

- Actual GPU model(s), VRAM per GPU, system RAM, driver version, WSL version and available disk space.
- The ComfyUI workflow JSON; an API-format export as well if available. GUI workflow JSON is useful even without an API export.
- Input images/video/audio, expected dimensions/frame count, batch, steps, seed policy and expected output.
- Existing ComfyUI version, custom-node list/versions and Python environment if a working installation exists. Do not modify that installation.
- Exact local model paths, filenames, file sizes and any existing authoritative hashes. Include every loader dependency: diffusion/UNet, text encoder, VAE, LoRA, ControlNet, upscaler, motion/video model, tokenizer and auxiliary assets as applicable.
- For llama.cpp: exact GGUF, quantization, architecture, split/shard files, intended context length and whether it supports instruction following/tool calls. Having a model in another format does not establish llama.cpp compatibility; no conversion or new huge model download is implicit.
- Whether OpenCode should use local llama.cpp only (default proposal) or an explicitly selected remote provider. No API keys in chat, reports or manifests.
- Agreed scratch name/path, storage allowance, time budget and acceptance thresholds.

Missing workflow/hardware prevents final dependency selection, not preparation of this plan. Never guess a custom-node repository from a similar display name. Do not assume the hardware from a cited issue report is the user's hardware.

## 4. Four-hour budget and stop rules

Default planning budget: 240 minutes of active operator/setup/test time after inputs and targets are ready. Track wall-clock time too; do not hide long downloads behind the active-time figure. This is a cap, not a promise that every workload completes in four hours.

| Stage | Budget | Required outcome |
| --- | ---: | --- |
| A. Workflow/dependency review, targets and manifest | 25 min | Exact minimal installation list and fixed benchmark parameters |
| B. Scratch Ubuntu creation and CUDA/PyTorch smoke check | 30 min | GPU available; no change to preserved distro |
| C. ComfyUI installation and workflow resolution | 40 min | Workflow loads; required nodes/models resolved |
| D. ComfyUI measured comparisons | 65 min | Default and fast-disk evidence, or explicit incomplete result |
| E. llama.cpp installation and measured inference | 40 min | Real offload test and server response |
| F. OpenCode installation and local integration | 25 min | Small disposable-project tool-use task |
| G. Report, evidence export and disposition | 15 min | Go / conditional go / no-go-for-configuration / inconclusive |

Use one dependency-resolution pass and at most one targeted repair per distinct blocker within its stage. Do not spend more than 20 minutes on a blocker without reporting it and offering the next useful independent stage. Unused time can move between stages; expanding the total requires the human's decision.

Before starting a heavy workflow, compare expected runtime with the remaining budget. If one run takes 30 minutes, six runs cannot fit into 65 minutes. Offer a longer explicit budget or report a smaller sample as preliminary; never lower resolution/frames/steps silently and call it the same workload. Reserve 15 minutes for the report even if setup fails.

Stop the current test if Windows becomes unresponsive, the GPU driver resets, free-space reserve is breached, or the agreed host-memory reserve is breached. First stop the foreground workload or its exact process. Do not issue global `wsl --shutdown` or kill unrelated processes. Inspect allocation errors instead of repeatedly allocating to failure.

## 5. Scratch layout and permissions

Proposed, not yet approved:

```text
Windows WSL registration: aij-trial-20261006
Windows distro storage:  C:\ai-jail-trials\aij-trial-20261006\wsl
Windows retained report: C:\ai-jail-trials\aij-trial-20261006\report
Linux workspace:         ~/aij-trial
  sources/ComfyUI
  sources/llama.cpp
  venvs/comfy
  bin/
  config/
  workflows/
  inputs/
  outputs/
  logs/
  results/
  opencode-project/
```

Use a name distinct from `ai-jail` AND from the intended production `ai-jail-fresh`. Refuse existing registration/storage; do not select another path silently. Check the effective Windows account and registration under that account. Use a stable official stock Ubuntu release compatible with selected software. Prefer the existing Ubuntu 24.04 project intent if the chosen versions support it; do not use an arbitrary daily build.

The command supplier must verify the exact local-artifact installation/import method, options, minimum WSL version, artifact format and nonlaunch behavior before giving the human the creation command. Record the actual stable artifact and checksum. Use one creation step, then check registration/storage. Do not build the production approval/state framework for this throwaway trial.

Default to stock scratch setup, not export of `ai-jail`. Cloning is an optional human-selected branch requiring verification of Microsoft's current export consistency/stopping behavior first. No source-distro shutdown/export is implicit.

Run apps as a normal Linux user with a separate ComfyUI virtual environment. Use sudo only for specifically listed scratch system dependencies. Scratch means disposable, not secure isolation: WSL may expose Windows drives, host executables and network resources. Keep existing models read-only in intent, never run destructive commands against their folders, and do not claim a path alias/config file enforces filesystem write protection.

No default .wslconfig edit. It applies globally to WSL2; its memory settings and restart requirements can affect preserved/running distros. Inspect existing settings and effective Linux memory first. If insufficient, present the exact proposed change, host reserve and effect on other workloads for separate approval. Preserve the original bytes. [Microsoft WSL configuration](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)

## 6. Storage and reproducibility controls

Do not redownload existing models. Map Windows paths to Linux paths explicitly. Use ComfyUI extra_model_paths.yaml for shared model discovery; put inputs, outputs and caches in the scratch environment. Do not point output/cache folders at model originals. [ComfyUI installation and model paths](https://docs.comfy.org/installation/manual_install)

Windows-mounted model storage and Linux ext4 storage are different benchmark conditions. Default to reading existing files where they are for feasibility, recording that location. A slow --fast-disk result from /mnt/c or /mnt/d is not a clean measurement of native Linux filesystem performance. If storage appears causal and disk space/time permit, copy only the workflow's selected model files into scratch ext4, verify copies and rerun one relevant case. No bulk copy of the whole model library.

Record commits/releases and exact installation commands before benchmarking. Freeze Python dependency versions after a successful resolution, CUDA/PyTorch versions, llama.cpp binary/build identity, OpenCode version, custom-node commits and workflow JSON hash. Do not update software between A/B runs. Model size/mtime can be an initial inventory shortcut, but do not describe them as content-integrity proof. Reuse known hashes or compute hashes for the selected files as time permits, separately accounting for that I/O.

Estimate disk before setup: distro/packages/build + selected optional model copies + maximum generated outputs + free-space reserve. Default reserve proposal: leave at least 20 GiB and 10% of the hosting volume free; adjust explicitly for the actual disk/workload. Do not derive a giant copy size merely from total model-library size.

## 7. Stage A — workflow inspection and installation manifest

Read the supplied JSON as data, never as trusted commands. Distinguish GUI graph nodes from executable API class_type entries; inspect nested subgraphs and active/muted/bypassed branches. Expand dependency resolution only to the submitted test workflow. Some nodes may require installation to deserialize a graph even if not executed; record that distinction.

Produce a table: node class → repository/package → pinned compatible version/commit → system/Python dependencies → license/download/source → required model/input → reason required. Use the working user's node/version metadata when available and verify exact mappings against the publisher. Unknown nodes are unresolved until mapped; no broad install-all manager action.

Inspect loader parameters, case-sensitive filenames, encoder/VAE pairings, optional downloads, node install scripts, external service/API calls and output destinations. Workflows can embed private prompts or filenames; redact report copies where needed. If a node needs an external paid API, exclude it only through an explicitly agreed changed workflow, or obtain permission; do not silently call it or substitute a different computation.

Freeze a benchmark copy of the workflow. Preserve the original. Define a fixed seed sequence (for example 101, 102, 103), fixed settings and common input files for both variants. Record any required compatibility edits and resulting workflow hash.

Stage exit: one minimal dependency manifest, exact selected models, complete inputs and reproducible run parameters. If these remain unresolved at the stage cap, report dependency-blocked and continue another independent app if useful.

## 8. Stage B — scratch and GPU smoke checks

The human receives one labelled command block at a time: Windows inspection; exact scratch creation; registration/path check; Linux package preparation; GPU smoke test. No combined create-and-unregister chain.

Before package selection, inspect actual GPU vendor/architecture, Windows driver, WSL/Linux versions, /dev/dxg for the NVIDIA WSL route, effective RAM and free disk. This plan's CUDA branch is conditional on NVIDIA hardware. AMD/Intel need a separately verified supported backend; do not install NVIDIA CUDA speculatively.

On NVIDIA WSL, use the Windows-provided GPU driver interface. Do not install a Linux NVIDIA driver inside WSL. PyTorch wheels and a toolkit required for compiling llama.cpp are different dependencies; a working Torch CUDA runtime does not prove nvcc exists. If a toolkit is required, select the supported toolkit-only route, not driver-installing CUDA metapackages. [NVIDIA WSL guide](https://docs.nvidia.com/cuda/wsl-user-guide/index.html)

In the Comfy virtual environment, the smoke test must record torch/Python/CUDA versions, cuda availability, device name/count and perform a small GPU tensor operation followed by synchronization. A successful nvidia-smi/version query alone is insufficient. If it fails, diagnose driver/wheel/architecture mismatch once, then stop the GPU workload branch within budget.

## 9. Stage C — install ComfyUI for this workflow

Use a fixed upstream ComfyUI release/commit and isolated Python environment. Select a stable PyTorch wheel supported by the driver/GPU and the chosen ComfyUI/custom-node versions, then install pinned requirements and only the mapped custom nodes. Run dependency consistency checks and capture the resulting package list. Do not globally upgrade an existing Python setup or run nightly builds as the first attempt. [ComfyUI manual setup](https://docs.comfy.org/installation/manual_install)

Manager is optional, not a reason to install every suggested node. If necessary for exact node resolution, record the installs and versions and disable auto-update behavior during measurements. Never share live custom_nodes directories with the existing working installation.

Prepare scratch-only output/temp/input paths and extra model paths. Start on an unused loopback port (8188 proposed) and verify Windows-browser access without first exposing 0.0.0.0 or opening a firewall. If loopback forwarding does not work, diagnose it before changing network exposure. Capture startup logs, GPU/backend selection and missing-model/node diagnostics.

Load the exact workflow; do a low-cost loading/validation check where possible. A reduced smoke job is allowed if clearly named as such and never counted as acceptance of the full workload.

## 10. Stage D — ComfyUI benchmark protocol

Run only one GPU-heavy app at a time. Stop the llama server before ComfyUI measurements. Keep browser previews, precision, attention backend and other flags identical across comparisons.

Required variants:

| ID | Configuration | Runs |
| --- | --- | --- |
| C-A | Selected version defaults, workflow-required options only | First-use run plus two genuinely executed warm runs |
| C-B | Same version/options plus --fast-disk | Fresh process; same seed sequence and run count |
| C-C | One diagnostic fallback, usually --disable-pinned-memory | Only if A/B fail or reveal material pressure; record as additional profile |

Confirm flags exist in the selected pinned version's help. Do not change multiple flags simultaneously. `--disable-dynamic-vram` is a separate fallback only if justified; do not blend it into B/C and attribute results to one flag. Current upstream documents these memory options, but selected-release behavior must be checked. [ComfyUI options](https://github.com/Comfy-Org/ComfyUI/blob/master/comfy/cli_args.py)

Important cache rule: queuing identical deterministic inputs may return cached node results. Use the agreed different seed per repetition, the SAME seed sequence across A/B, and inspect logs to confirm expensive sampler/model nodes ran. If the graph has no seed-driven invalidation, define a documented rerun/cache policy applicable to both variants. Do not count a cache hit as a fast inference run.

Restart ComfyUI between variants; allow VRAM/RAM to settle. Do not clear global Windows/Linux caches or stop other distros to manufacture a cold test. Label the first job “first-use/process-cold”; the OS model-file cache may still be warm.

Capture each run: variant, seed, workflow/model identities, full runtime, model-loading time if available, stage timings, peak GPU dedicated memory, host available RAM, WSL memory and swap, successful output filename/dimensions/frames, visual validity and errors. Windows shared-GPU-memory counters are contextual and not synonymous with VRAM use or proof of a leak. NVIDIA's WSL pinned-memory limits motivate this test; they do not predict an exact universal cap. [NVIDIA WSL limitations](https://docs.nvidia.com/cuda/wsl-user-guide/index.html)

Compare warm-run median with sample size clearly stated, and keep first-use latency separate. Record output quality/correctness; identical pixels across platforms are not assumed. A video workflow must complete all intended frames and decoding/output stages. An OOM after sampling still fails the run.

If a working Windows baseline exists, use the same application/node/model versions and workflow settings when practical. Record unavoidable differences. If no comparable baseline exists, judge functional feasibility and absolute user targets only; do not claim WSL overhead from unrelated published benchmarks.

## 11. Optional bounded pinned-memory diagnostic

This is optional and does not delay real workloads that already pass. Use at most ten minutes taken from Stage D/E, and run separately after stopping GPU-heavy apps.

Select a cumulative live allocation ceiling BEFORE the run from actual host/guest available memory and the user's reserve. Conservative proposal: minimum of 2 GiB, 10% of effective guest available RAM and 10% of Windows available RAM. Keep at least max(8 GiB, 20% of physical RAM) available on the host if feasible; on smaller machines agree a suitable reserve instead of blindly applying this proposal.

Allocate pinned CPU tensors in small measured increments, touch their pages, retain references only up to the cumulative ceiling, optionally verify one small CPU-to-GPU transfer and synchronization, then release memory/exit the process. Do not double allocations indefinitely or accidentally free every previous buffer while claiming a cumulative test. Catch and log the first allocation error and stop. No mlock/ulimit/kernel/pagefile/global-memory changes to force a pass.

`torch.empty(..., pin_memory=True)` tests that allocation path; it is not identical to ComfyUI's host-registration strategy and cannot prove that a large workflow or Strata works. Report “bounded probe completed to X”, not “maximum pinning capacity is X”.

## 12. Stage E — llama.cpp installation and RAM-offload test

Prefer a compatible official pinned binary when available; otherwise use the official build instructions at a pinned commit. NVIDIA source builds require the CUDA backend and a compatible compiler/toolkit. Bound build parallelism for this machine; do not use every CPU blindly under memory pressure. Verify loaded backend and model GPU placement from actual logs. [llama.cpp build instructions](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md)

Use existing GGUF/shards. Record architecture, quantization, file identity, context length, threads, batch/microbatch, GPU-layer/offload policy, KV placement, mmap setting, sampling and model/template settings. Do not use a download shortcut such as a remote model identifier when local files already exist.

Cases:

- L-A: small smoke prompt with conservative context and known-safe offload, only to establish loading/backend operation.
- L-B: intended large model and actual RAM-offload policy at the user's intended context, using fixed prompt text and bounded output tokens. Repeat three measured requests if budget permits. Confirm from logs that the intended CPU/GPU placement occurred; a fully GPU-resident model does not test the stated RAM-offload concern.
- L-C: one adjusted offload/context setting only if B fails. Clearly label any reduced context or smaller workload; it is conditional feasibility, not a pass for the original requirement.

Use llama-bench and/or server request timing as appropriate, preserving command/help/version. Record model load time, prompt tokens/second, generation tokens/second, time to first token, context/output token counts, process/host RAM, VRAM, swap and errors. Control prompt caching: disable reuse through the selected supported option or use fixed different prompts across repetitions with the same set in comparisons. Do not claim prompt ingestion speed from a cache hit. [llama-bench](https://github.com/ggml-org/llama.cpp/blob/master/tools/llama-bench/README.md)

Start llama-server on 127.0.0.1 and an unused port (8080 proposed), with one slot/concurrent request for initial measurements. Verify health, model listing, chat response and streaming. Set a bounded context appropriate for the model and real available memory; do not copy a 128k example blindly. Tool calling needs a compatible model and template; configure it using the selected server release rather than assuming text generation proves tool support. [llama-server documentation](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md)

## 13. Stage F — OpenCode and local llama.cpp integration

Install a pinned official OpenCode release inside scratch, with user-local configuration. Verify its version and prerequisites from current official instructions. Prefer a reviewed/versioned installation method; no unreviewed remote shell pipeline or unnecessary cloud signup. [OpenCode installation](https://opencode.ai/docs/)

Use local llama-server by default. OpenCode documents an OpenAI-compatible provider with a local /v1 base URL. Match the configured model identifier to the server alias/model listing. Set context/output limits to the actual server/model budget. Provider adapter packages may require a setup download; record that separately from inference traffic. [OpenCode llama.cpp provider](https://opencode.ai/docs/providers/#llamacpp)

Prepare a tiny disposable Git project, not the AI Jail repository or a personal directory. Suggested fixture: a Python function with a small deterministic bug and a stdlib unittest suite. No dependencies, private code or credentials. Make a local baseline commit with fixture-only identity if needed; no remotes, pushes, publishing or account integration.

Start with all tools requiring human approval and outside-directory access denied. Inspect effective permissions; no auto-approve mode. First request a plain answer, then reading the fixture, then a proposed change, then approve a specific edit and the exact local test command. Permissions are application controls, not an OS sandbox; never claim they protect all host files against arbitrary approved shell commands. [OpenCode permissions](https://opencode.ai/docs/permissions/)

Required sequence:

1. Local provider connects and completes a streaming response.
2. The model requests/uses the appropriate read tool to inspect the fixture.
3. A tool call executes successfully, its result returns to the model, and the conversation continues coherently.
4. The human approves the proposed fixture-only edit and exact unittest command. The test runs inside this OpenCode experiment under that explicit approval; the supervising chat still does not execute commands itself.
5. Check actual diff/test output. No outside files changed, no unsolicited network calls approved, no provider fallback to paid/remote inference.

Distinguish CLI startup, provider protocol, tool-call parsing, model coding quality and test execution. A model that chats but cannot call tools is not an OpenCode integration PASS. One failed small model task is not automatically a WSL fault. A remote-provider comparison is optional only with explicit provider/cost/data permission and cannot establish local GPU performance.

Keep ComfyUI stopped while llama-server serves OpenCode. Concurrent ComfyUI + local LLM GPU use is out of scope unless separately selected; passing sequential tests does not establish simultaneous capacity.

## 14. Acceptance and decision matrix

Freeze user thresholds before measurements. Suggested starting thresholds are proposals, not automatic requirements:

- Full intended ComfyUI workflow completes all three genuinely executed runs under at least one documented configuration; no crash/OOM and valid outputs.
- If comparable Windows measurements exist, acceptable median warm slowdown might be <=25%; the user chooses the real tolerance. Without them, use an explicit maximum minutes/job or label performance acceptance pending.
- llama.cpp completes intended context/offload tests repeatedly within the agreed first-token and generation-speed targets. Do not impose an arbitrary universal tokens/second threshold.
- OpenCode completes provider + tool-use + fixture-edit/test sequence using the intended local model. Model quality limitations may yield conditional acceptance separately from transport success.
- Host remains usable and agreed memory/disk reserves are respected. No protected target or baseline was changed.

| Outcome | Interpretation and next step |
| --- | --- |
| GO | All required intended cases meet agreed criteria; resume Phase 030 with proven versions/settings. |
| CONDITIONAL GO | Workloads work only with documented flags/offload/storage tradeoffs the user accepts; carry these into app requirements. |
| MIXED | Some applications suit WSL and others do not meet targets; decide placement separately instead of forcing one answer for all apps. |
| NO-GO FOR TESTED CONFIGURATION | Reproducible workload failure or unacceptable measured performance after bounded diagnosis; record exact scope and consider a focused Windows/native-Linux comparison. |
| INCONCLUSIVE | Time limit, missing inputs/dependencies or insufficient samples; no general platform conclusion. |

Do not create production acceptance records from trial results. Keep a version/settings compatibility note for the installer; later isolation and clean-rebuild tests remain necessary.

## 15. Evidence, recovery and finish

Retain a minimal manifest, workflow/node/model mapping, config/version records, exact commands with secrets redacted, per-run CSV, complete failure logs, sample outputs and final decision. Export only these selected files to the agreed Windows report directory before any scratch cleanup. Do not export OpenCode credentials or its entire home directory.

Use the supplied RESULTS.csv header as a starting point. Include units in metrics and unknown values as blank/UNKNOWN, never zero. Record skipped stages and sample sizes honestly. Log the first failing statement and the single targeted repair attempted.

If scratch creation or an install is interrupted, inspect that exact scratch state. Do not rerun creation against a possibly occupied destination. Preserve logs and choose one explicit repair/recreate action. Avoid building production-grade rollback machinery for this bounded trial.

At time expiry, stop trial processes specifically, preserve evidence and report. Keep the scratch distro by default. Cleanup is a separate human instruction naming the exact disposable registration; unregister permanently deletes its distro data. Never clean `ai-jail`, `ai-jail-fresh`, original models or shared storage. [Microsoft WSL commands](https://learn.microsoft.com/en-us/windows/wsl/basic-commands)

## 16. Instructions for the next chat

Read this plan and the intake sheet. Accept that the user chose to PLAN the trial; do not infer unknown scratch/hardware/settings choices. Ask only for remaining inputs, together. Inspect the actual workflow JSON and produce its dependency map before generating package commands.

Next deliverable: a filled manifest and the first exact Windows/scratch setup block, with shell/directory/privileges/side effects, expected success and stop conditions. Continue in short stages from actual output. No automatic production edits, global WSL changes, huge model downloads, security-framework redesign or connector installation. Keep the elapsed-time ledger and stop at the agreed cap.

This plan is complete as a procedure but intentionally not a blindly executable installer: scratch identity, hardware-compatible versions, workflow dependencies, model paths and acceptance targets must be filled from the user before commands are finalized.
