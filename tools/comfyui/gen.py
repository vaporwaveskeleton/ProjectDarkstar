"""Text-to-image via a local ComfyUI server (stdlib only, no secrets).

Usage (run with the ComfyUI venv python):
  E:\\Tools\\ComfyUI\\venv\\Scripts\\python.exe tools\\comfyui\\gen.py --prompt "..." [--negative "..."]
      [--seed N] [--steps 30] [--cfg 7] [--width 1024] [--height 1024] [--tag name]
      [--out DIR] [--server http://127.0.0.1:8188] [--arch sdxl|klein|zimage] [--ckpt sd_xl_base_1.0.safetensors]

Writes <out>/<timestamp>_<tag>_<seed>.png and a matching .json (prompt, seed, steps, size, seconds).
Output is concept/reference art only (D-13/D-14); never write under assets/.
"""
import argparse, json, os, random, subprocess, sys, threading, time, urllib.request, urllib.parse

DEFAULT_OUT = r"E:\GameDev\ProjectDarkstar\research\comfyui_out"


def call(url, data=None):
    req = urllib.request.Request(url, data=json.dumps(data).encode() if data else None,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return r.read()


def vram_mb():
    try:
        return int(subprocess.check_output(["nvidia-smi", "--query-gpu=memory.used", "--format=csv,noheader,nounits"]).split()[0])
    except Exception:
        return 0


def build(a, seed):
    if a.arch == "sdxl":
        return {
            "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": a.ckpt}},
            "2": {"class_type": "CLIPTextEncode", "inputs": {"text": a.prompt, "clip": ["1", 1]}},
            "3": {"class_type": "CLIPTextEncode", "inputs": {"text": a.negative, "clip": ["1", 1]}},
            "4": {"class_type": "EmptyLatentImage", "inputs": {"width": a.width, "height": a.height, "batch_size": 1}},
            "5": {"class_type": "KSampler", "inputs": {"model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0],
                  "latent_image": ["4", 0], "seed": seed, "steps": a.steps, "cfg": a.cfg,
                  "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0}},
            "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
            "7": {"class_type": "SaveImage", "inputs": {"images": ["6", 0], "filename_prefix": "darkstar"}},
        }
    # split-file models (klein, zimage): UNET + CLIP + VAE; distilled, so cfg 1 and an empty negative
    if a.arch == "klein":
        unet, weight, clip, ctype, vae = a.unet or "flux-2-klein-4b.safetensors", "fp8_e4m3fn", "qwen_3_4b.safetensors", "flux2", "flux2-vae.safetensors"
        lat = {"class_type": "EmptyFlux2LatentImage", "inputs": {"width": a.width, "height": a.height, "batch_size": 1}}
        sampler, sched = "euler", "simple"
    else:
        unet, weight, clip, ctype, vae = a.unet or "z_image_turbo_int8_convrot.safetensors", "default", "qwen_3_4b_fp8_mixed.safetensors", "lumina2", "ae.safetensors"
        lat = {"class_type": "EmptySD3LatentImage", "inputs": {"width": a.width, "height": a.height, "batch_size": 1}}
        sampler, sched = "res_multistep", "simple"
    wf = {
        "1": {"class_type": "UNETLoader", "inputs": {"unet_name": unet, "weight_dtype": weight}},
        "2": {"class_type": "CLIPLoader", "inputs": {"clip_name": clip, "type": ctype, "device": "default"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": vae}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": a.prompt, "clip": ["2", 0]}},
        "5": {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["4", 0]}},
        "6": lat,
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["9", 0], "vae": ["3", 0]}},
        "7": {"class_type": "SaveImage", "inputs": {"images": ["8", 0], "filename_prefix": "darkstar"}},
    }
    model_ref = ["1", 0]
    if a.arch == "zimage":
        wf["10"] = {"class_type": "ModelSamplingAuraFlow", "inputs": {"model": ["1", 0], "shift": 3.0}}
        model_ref = ["10", 0]
    wf["9"] = {"class_type": "KSampler", "inputs": {"model": model_ref, "positive": ["4", 0], "negative": ["5", 0],
               "latent_image": ["6", 0], "seed": seed, "steps": a.steps, "cfg": 1.0,
               "sampler_name": sampler, "scheduler": sched, "denoise": 1.0}}
    return wf


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--prompt", required=True)
    p.add_argument("--negative", default="blurry, low quality, text, watermark, photo")
    p.add_argument("--seed", type=int, default=None)
    p.add_argument("--steps", type=int, default=None)
    p.add_argument("--cfg", type=float, default=7.0)
    p.add_argument("--width", type=int, default=1024)
    p.add_argument("--height", type=int, default=1024)
    p.add_argument("--arch", default="sdxl", choices=["sdxl", "klein", "zimage"])
    p.add_argument("--unet", default=None)
    p.add_argument("--ckpt", default="sd_xl_base_1.0.safetensors")
    p.add_argument("--tag", default="img")
    p.add_argument("--out", default=DEFAULT_OUT)
    p.add_argument("--server", default="http://127.0.0.1:8188")
    a = p.parse_args()
    if a.steps is None:
        a.steps = {"sdxl": 30, "klein": 4, "zimage": 8}[a.arch]
    seed = a.seed if a.seed is not None else random.randrange(2**32)
    wf = build(a, seed)
    peak = [0]; stop = threading.Event()
    def poll():
        while not stop.is_set():
            peak[0] = max(peak[0], vram_mb()); time.sleep(0.25)
    base_vram = vram_mb(); threading.Thread(target=poll, daemon=True).start()
    t0 = time.time()
    pid = json.loads(call(a.server + "/prompt", {"prompt": wf}))["prompt_id"]
    while True:
        h = json.loads(call(f"{a.server}/history/{pid}"))
        if pid in h:
            break
        time.sleep(0.5)
    secs = time.time() - t0
    stop.set()
    entry = h[pid]
    if entry.get("status", {}).get("status_str") == "error":
        sys.exit("ComfyUI error: " + json.dumps(entry["status"])[:800])
    img = entry["outputs"]["7"]["images"][0]
    q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"], "type": img["type"]})
    data = call(f"{a.server}/view?{q}")
    os.makedirs(a.out, exist_ok=True)
    base = os.path.join(a.out, f"{time.strftime('%Y%m%d_%H%M%S')}_{a.tag}_{seed}")
    open(base + ".png", "wb").write(data)
    meta = dict(prompt=a.prompt, negative=a.negative, seed=seed, steps=a.steps, cfg=a.cfg if a.arch == "sdxl" else 1.0,
                width=a.width, height=a.height, ckpt=a.ckpt if a.arch == "sdxl" else (a.unet or a.arch), arch=a.arch, seconds=round(secs, 1),
                vram_peak_mb=peak[0], vram_before_mb=base_vram)
    json.dump(meta, open(base + ".json", "w"), indent=2)
    print(base + ".png")
    print(json.dumps(meta))


if __name__ == "__main__":
    main()
