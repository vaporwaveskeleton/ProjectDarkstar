"""Stage 1 finishing: raw ComfyUI renders -> assets/art/comfyui/ + manifest.json + contact sheet.

Run with the ComfyUI venv python:  python tools/comfyui/stage1_finish.py [RAW_ROOT]
RAW_ROOT defaults to research/comfyui_out (subfolders stage1, stage1b) in the main checkout (git-ignored). Every shipped image
gets a manifest entry (model, licence, prompt, seed, steps, size) taken from the render's .json sidecar
(ART-001 section 14.9). Post: tape via a luminance key. Kept after owner picks (2026-11-20): tape_3 and backdrop_2 only.
"""
import glob, json, os, sys
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
RAW_ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.environ.get("DARKSTAR_MAIN", "E:/GameDev/ProjectDarkstar"), "research", "comfyui_out")
RAW = RAW_ROOT
OUT = os.path.join(REPO, "assets", "art", "comfyui")
MODELS = {
    "zimage": ("Z-Image-Turbo (z_image_turbo_int8_convrot.safetensors, Tongyi-MAI/Z-Image-Turbo)", "Apache-2.0"),
    "klein": ("FLUX.2 klein 4B (flux-2-klein-4b.safetensors, black-forest-labs/FLUX.2-klein-4B)", "Apache-2.0"),
}
# (output name, category, tag, seed, post, note)
JOBS = [
    # (output name, category, subdir of RAW_ROOT, tag, seed, post, note)
    ("tape_3.png", "tape", "stage1", "tape", 203, "tape", "alpha by luminance key, cropped to the strip, downscaled to 640 px wide"),
    ("backdrop_2.png", "backdrop", "stage1", "backdrop", 302, "", "unmodified; blurred bokeh, lettering unreadable"),
]
REF_NOTE = "Third-party reference images were looked at only to write better prompts; none was used as an image input."
REF_NOTE = "Third-party reference bezels and photos were looked at only to write better prompts; none was used as an image input (no img2img, no edit input)."
REF_NOTE = "Third-party reference bezels and photos were looked at only to write better prompts; none was used as an image input (no img2img, no edit input)."


def find(tag, seed, ext):
    m = glob.glob(os.path.join(RAW, f"*_{tag}_{seed}.{ext}"))
    if not m:
        sys.exit(f"missing render {tag} {seed}")
    return sorted(m)[-1]


def key_tape(path, dst):
    im = np.asarray(Image.open(path).convert("RGB"), np.float32)
    lum = im.mean(axis=2)
    alpha = np.clip((lum - 22.0) / 40.0, 0.0, 1.0)
    ys, xs = np.where(alpha > 0.5)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    rgba = np.dstack([im, alpha * 255.0])[y0:y1, x0:x1]
    im = Image.fromarray(rgba.astype(np.uint8), "RGBA")
    im.resize((640, round(im.height * 640 / im.width)), Image.LANCZOS).save(dst, optimize=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    manifest = {"_about": "ART-001 section 14.9: provenance for every ComfyUI image under assets/art/comfyui/. Rebuilt by tools/comfyui/stage1_finish.py.", "files": {}}
    for name, cat, sub, tag, seed, post, note in JOBS:
        global RAW
        RAW = os.path.join(RAW_ROOT, sub)
        raw = find(tag, seed, "png"); meta = json.load(open(find(tag, seed, "json")))
        dst = os.path.join(OUT, name)
        if post == "tape":
            key_tape(raw, dst)
        else:
            Image.open(raw).convert("RGB").save(dst, optimize=True)
        w, h = Image.open(dst).size
        model, lic = MODELS[meta["arch"]]
        manifest["files"][name] = dict(category=cat, model=model, licence=lic, prompt=meta["prompt"], seed=meta["seed"],
            steps=meta["steps"], cfg=meta["cfg"], generated_size=[meta["width"], meta["height"]], size=[w, h],
            sampler="euler/simple" if meta["arch"] == "klein" else "res_multistep/simple", post=note, no_lettering=True,
            raw=os.path.basename(raw), reference_use=REF_NOTE)
    json.dump(manifest, open(os.path.join(OUT, "manifest.json"), "w"), indent=2)
    # contact sheet
    cell = (480, 270); names = [j[0] for j in JOBS]
    cols = 4; rows = (len(names) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell[0], rows * (cell[1] + 18)), (70, 70, 70, 255))
    d = ImageDraw.Draw(sheet)
    for i, n in enumerate(names):
        im = Image.open(os.path.join(OUT, n)).convert("RGBA"); im.thumbnail(cell)
        x, y = (i % cols) * cell[0], (i // cols) * (cell[1] + 18)
        sheet.alpha_composite(im, (x, y + 18)); d.text((x + 4, y + 3), n, fill=(255, 255, 255, 255))
    sheet.convert("RGB").save(os.path.join(RAW_ROOT, "contact_sheet_stage1.png"))
    print("done", len(names))


if __name__ == "__main__":
    main()
