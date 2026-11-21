"""Text-to-image via a local ComfyUI server (stdlib only, no secrets).

Usage (run with the ComfyUI venv python):
  E:\\Tools\\ComfyUI\\venv\\Scripts\\python.exe tools\\comfyui\\gen.py --prompt "..." [--negative "..."]
      [--seed N] [--steps 30] [--cfg 7] [--width 1024] [--height 1024] [--tag name]
      [--out DIR] [--server http://127.0.0.1:8188] [--ckpt sd_xl_base_1.0.safetensors]

Writes <out>/<timestamp>_<tag>_<seed>.png and a matching .json (prompt, seed, steps, size, seconds).
Output is concept/reference art only (D-13/D-14); never write under assets/.
"""
import argparse, json, os, random, sys, time, urllib.request, urllib.parse

DEFAULT_OUT = r"E:\GameDev\ProjectDarkstar\research\comfyui_out"


def call(url, data=None):
    req = urllib.request.Request(url, data=json.dumps(data).encode() if data else None,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return r.read()


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--prompt", required=True)
    p.add_argument("--negative", default="blurry, low quality, text, watermark, photo")
    p.add_argument("--seed", type=int, default=None)
    p.add_argument("--steps", type=int, default=30)
    p.add_argument("--cfg", type=float, default=7.0)
    p.add_argument("--width", type=int, default=1024)
    p.add_argument("--height", type=int, default=1024)
    p.add_argument("--ckpt", default="sd_xl_base_1.0.safetensors")
    p.add_argument("--tag", default="img")
    p.add_argument("--out", default=DEFAULT_OUT)
    p.add_argument("--server", default="http://127.0.0.1:8188")
    a = p.parse_args()
    seed = a.seed if a.seed is not None else random.randrange(2**32)
    wf = {
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
    t0 = time.time()
    pid = json.loads(call(a.server + "/prompt", {"prompt": wf}))["prompt_id"]
    while True:
        h = json.loads(call(f"{a.server}/history/{pid}"))
        if pid in h:
            break
        time.sleep(0.5)
    secs = time.time() - t0
    entry = h[pid]
    if entry.get("status", {}).get("status_str") == "error":
        sys.exit("ComfyUI error: " + json.dumps(entry["status"])[:800])
    img = entry["outputs"]["7"]["images"][0]
    q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"], "type": img["type"]})
    data = call(f"{a.server}/view?{q}")
    os.makedirs(a.out, exist_ok=True)
    base = os.path.join(a.out, f"{time.strftime('%Y%m%d_%H%M%S')}_{a.tag}_{seed}")
    open(base + ".png", "wb").write(data)
    meta = dict(prompt=a.prompt, negative=a.negative, seed=seed, steps=a.steps, cfg=a.cfg,
                width=a.width, height=a.height, ckpt=a.ckpt, seconds=round(secs, 1))
    json.dump(meta, open(base + ".json", "w"), indent=2)
    print(base + ".png")
    print(json.dumps(meta))


if __name__ == "__main__":
    main()
