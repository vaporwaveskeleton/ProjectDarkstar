# COMFYUI_WORKFLOW (COMFY-001): local concept-art generation

**Rule (D-13/D-14):** ComfyUI output is **concept/reference art only**. It is never imported by Godot, never committed, never shipped, and never written under `assets/`. Shipped visuals stay runtime vector/shader, pxl renders or loom textures (CLAUDE.md §3), unless the owner rules otherwise in writing.

## Setup (done once on the owner's machine)
- ComfyUI (git clone of `comfyanonymous/ComfyUI`) at `E:\Tools\ComfyUI`, own venv (`venv\`, Python 3.12, torch cu128). Outside the repo.
- Checkpoint: `models\checkpoints\sd_xl_base_1.0.safetensors` (stabilityai/stable-diffusion-xl-base-1.0, 6.94 GB, CreativeML OpenRAIL++-M: use-based restrictions, commercial use allowed). Hardware: RTX 4070, 12 GB.
- Why this route: ComfyUI's own HTTP API (`/prompt`, `/history`, `/view`) plus a 90-line stdlib script is the smallest thing a chat can call; no third-party MCP server or extra dependency to trust. Existing MCP servers (Comfy-Org/comfy-mcp, artokun/comfyui-mcp) were found but not installed; revisit if chats need workflow editing.

## Start the server
```powershell
powershell -File tools\comfyui\start_server.ps1      # http://127.0.0.1:8188, loopback only
```
Check it is up: `curl http://127.0.0.1:8188/system_stats`. First generation after start loads the model (~20 s).

## Hand-off from a chat
```powershell
E:\Tools\ComfyUI\venv\Scripts\python.exe tools\comfyui\gen.py --prompt "<prompt>" --tag <short_name> [--seed N] [--steps 30] [--cfg 7] [--width 1024] [--height 1024] [--negative "..."]
```
Prints the PNG path and a JSON line. Default output folder: `E:\GameDev\ProjectDarkstar\research\comfyui_out\` (main checkout, git-ignored; override with `--out`). View the PNG with the Read tool.

## Logging convention
Each image gets a sidecar `<name>.json` (prompt, negative, seed, steps, cfg, size, checkpoint, seconds) next to `<timestamp>_<tag>_<seed>.png`. Always state seed and prompt when reporting an image so it can be reproduced. Do not describe an image as a game asset; call it reference.

## Smoke test (2026-11-20)
Prompt "vintage 1983 arcade cabinet flyer illustration ... neon magenta and cyan on deep black", seed 1983, 30 steps, cfg 7, 1024x1024, dpmpp_2m/karras: 16.2 s warm on the RTX 4070. Output: `research\comfyui_out\20261120_192406_cabinet_flyer_1983.png`.
