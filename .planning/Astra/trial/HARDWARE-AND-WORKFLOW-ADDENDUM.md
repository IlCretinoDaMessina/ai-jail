# Trial addendum — actual hardware and workflows

This supplements WSL-WORKLOAD-TRIAL-PLAN.md. Inspection was read-only; no workflows, tests or installation commands were executed. Original JSON files remain untouched.

## Confirmed by operator

- Ryzen 5600X; RTX 3080 Ti; 64 GB system RAM.
- Models on D:; exact model directories and llama.cpp language-model GGUF still needed.
- Existing Windows 11 ComfyUI available for comparison; installed path, versions and successful runtimes not yet confirmed.
- Flux workflow: `D:\.coding\.ai-jail\flux + redux + pulid.json`.
- Wan workflow: `D:\.coding\.ai-jail\video animation wan2.2.json`.
- Query actual available VRAM, driver, host free RAM and WSL memory limits before selecting allocations. Hardware names do not establish available memory.

## Flux static inventory

133 top-level nodes. The following package identities are recorded in node metadata, not independently verified installation locks:

| Package identity | Repository hint in JSON |
| --- | --- |
| comfyui_pulid_flux_ll | PaoloC68/ComfyUI-PuLID-Flux-Chroma |
| comfyui_essentials | cubiq/ComfyUI_essentials |
| rgthree-comfy | rgthree/rgthree-comfy |
| masquerade | BadCafeCode/masquerade-nodes-comfyui |
| comfyui-mxtoolkit | Smirnov75/ComfyUI-mxToolkit |
| comfyui-detail-daemon | Jonseed/ComfyUI-Detail-Daemon |
| comfyui-kjnodes | kijai/ComfyUI-KJNodes |
| comfyui-easy-use | yolain/ComfyUI-Easy-Use |
| comfyui-various | jamesWalker55/comfyui-various |
| was-ns | Unresolved from metadata; Latent Noise Injection |
| comfyui_ultimatesdupscale | ssitu/ComfyUI_UltimateSDUpscale |

Selected loader values include Flux/flux1-dev-fp16.safetensors, t5xxl_fp16.safetensors, clip_l.safetensors, ae.safetensors, flux1-redux-dev.safetensors, sigclip_vision_patch14_384.safetensors, pulid_flux_v0.9.1.safetensors and Flux/Flux.1-dev-Controlnet-Upscaler.safetensors. Upscaler selections include 4x-UltraSharp.pth and 4x_foolhardy_Remacri.pth, on different branches. Preserve exact filename case when mapping paths.

PuLID selects CPU InsightFace. Locate its existing auxiliary face-analysis and EVA-CLIP assets; do not assume the named PuLID weight is its only dependency or permit an implicit download.

There are numerous bypassed nodes, disabled LoRAs, reference images and interactive image-selection nodes. Determine the actual output branch from the working UI/API export. Do not install every historical dependency or require every bypassed image. Do not silently remove a required stage to obtain a pass. Record human selection time separately if the workflow pauses for selection.

## Wan static inventory

24 top-level nodes. Package metadata identifies comfyui-gguf, rgthree-comfy, comfyui-videohelpersuite and comfyui-frame-interpolation. Verify their sources/installed versions from the working Windows environment before pinning Linux equivalents.

`ThrottledCLIPLoader` has no package identity in this JSON. Obtain its actual source from the Windows custom_nodes directory; do not replace it with CLIPLoader without separately documenting and approving a changed benchmark. Its selected weight is umt5_xxl_fp8_e4m3fn_scaled.safetensors. A separate metadata model hint mentions Qwen; that hint is not proof that Qwen is required and must not trigger a download.

Other selected assets:

- Wan2.2-I2V-A14B-HighNoise-Q3_K_S.gguf
- Wan2.2-I2V-A14B-LowNoise-Q4_0.gguf
- Wan2.1_VAE.pth
- clip_vision_h.safetensors
- rife47.pth
- Enabled high/low noise Seko 4-step LoRAs and wugong high/low LoRAs, as selected in the JSON.

These Wan GGUF files are diffusion weights, not the language model needed by llama.cpp/OpenCode.

Saved Wan settings: 688 × 1024, 81 source frames, batch 1; two sampler stages with an eight-step schedule split at step four. RIFE interpolation is selected at 2×. Video outputs select H.264 MP4 at 16 and 32 fps. Confirm graph execution and resulting frame counts rather than assuming the final count from the multiplier. Preserve the full interpolation/encoding path for the full-workflow acceptance result.

Some images are bypassed. An active input references pasted/image (314).png. Resolve actual required input files from the Windows ComfyUI input directory. Saved output preview paths are historical metadata, not paths to write in the trial.

## Execution refinements

1. Obtain the Windows installation path, model roots and chosen language-model GGUF. Read the working versions and resolve the unidentified node before installation.
2. Use copies of both workflows. Map Windows separators to Linux paths only where necessary; retain original hashes and log adaptations. Do not rewrite the originals.
3. Run workloads sequentially. Close the Windows GPU workload before WSL measurements; stop ComfyUI before llama.cpp/OpenCode measurements. Preserve unrelated running work.
4. Start with Flux dependency validation and one full run, then Wan dependency validation and one full run. Compare with the same Windows branches, inputs, seeds, settings and output stages.
5. Use the remaining budget for repeated runs and defaults versus fast-disk comparison. Keep per-workflow results separate. One successful workflow does not accept the other.
6. The original repeat-count acceptance criteria remain unchanged. Insufficient time produces INCONCLUSIVE for that criterion. Reduced resolution/frame-count runs may be diagnostic only, never substituted for the requested full workload.
7. Four hours remains a proposed stop-and-report checkpoint, not a promise that both large custom workflows and the language-model tests will finish. No automatic extension.
8. Do not assume fast-disk changes every GGUF/custom-node memory path. Record the actual loader behavior and qualify conclusions accordingly.
9. Keep models on D: initially and disclose mounted-Windows storage as part of the measured configuration. Any selected ext4 copy is a separate recorded comparison, not an automatic migration.
10. No global WSL memory adjustment, model download, Windows ComfyUI update or production installer modification is authorized by this addendum.

## Remaining input needed once

- Exact Windows ComfyUI installation directory (including custom_nodes and input).
- Exact ComfyUI model directory/directories on D:.
- Exact language-model GGUF path, including shards if applicable.
- Which saved workflow output branches currently succeed on Windows and their approximate durations, if known.

API-format exports are useful if available, especially for the Flux interactive/bypassed branches. The supplied GUI JSON files have already been read; do not ask for them again.
