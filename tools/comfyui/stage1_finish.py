"""Stage 1 finishing: raw ComfyUI renders -> assets/art/comfyui/ + manifest.json + contact sheet.

Run with the ComfyUI venv python:  python tools/comfyui/stage1_finish.py [RAW_DIR]
RAW_DIR defaults to research/comfyui_out/stage1 in the main checkout (git-ignored). Every shipped image
gets a manifest entry (model, licence, prompt, seed, steps, size) taken from the render's .json sidecar
(ART-001 section 14.9). Post: bezels via make_bezel.py (exact screen cut-out), tape via a luminance key.
"""
import glob, json, os, subprocess, sys
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
RAW = sys.argv[1] if len(sys.argv) > 1 else r"E:\GameDev\ProjectDarkstar\research\comfyui_out\stage1"
OUT = os.path.join(REPO, "assets", "art", "comfyui")
MODELS = {
    "zimage": ("Z-Image-Turbo (z_image_turbo_int8_convrot.safetensors, Tongyi-MAI/Z-Image-Turbo)", "Apache-2.0"),
    "klein": ("FLUX.2 klein 4B (flux-2-klein-4b.safetensors, black-forest-labs/FLUX.2-klein-4B)", "Apache-2.0"),
}
# (output name, category, tag, seed, post, note)
JOBS = [
    ("bezel_navy.png", "bezel", "face_navy", 101, "bezel:40,40,1300,715", "flat face, exact 256x304 cut-out"),
    ("bezel_oxblood.png", "bezel", "face2_oxblood", 105, "bezel:", "flat face, exact 256x304 cut-out"),
    ("bezel_black.png", "bezel", "face2_black", 106, "bezel:", "flat face, exact 256x304 cut-out"),
    ("tape_1.png", "tape", "tape", 201, "tape", "alpha by luminance key"),
    ("tape_2.png", "tape", "tape", 202, "tape", "alpha by luminance key"),
    ("tape_3.png", "tape", "tape", 203, "tape", "alpha by luminance key"),
    ("tape_4.png", "tape", "tape", 204, "tape", "alpha by luminance key"),
    ("backdrop_1.png", "backdrop", "backdrop", 301, "", "unmodified; blurred bokeh, lettering unreadable"),
    ("backdrop_2.png", "backdrop", "backdrop", 302, "", "unmodified; blurred bokeh, lettering unreadable"),
    ("backdrop_3.png", "backdrop", "backdrop", 303, "", "unmodified; blurred bokeh, lettering unreadable"),
    ("backdrop_4.png", "backdrop", "backdrop", 304, "", "unmodified; blurred bokeh, lettering unreadable"),
]


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
    Image.fromarray(rgba.astype(np.uint8), "RGBA").save(dst, optimize=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    manifest = {"_about": "ART-001 section 14.9: provenance for every ComfyUI image under assets/art/comfyui/. Rebuilt by tools/comfyui/stage1_finish.py.", "files": {}}
    for name, cat, tag, seed, post, note in JOBS:
        raw = find(tag, seed, "png"); meta = json.load(open(find(tag, seed, "json")))
        dst = os.path.join(OUT, name)
        if post.startswith("bezel"):
            cmd = [sys.executable, os.path.join(HERE, "make_bezel.py"), raw, dst]
            if ":" in post and post.split(":", 1)[1]:
                cmd += ["--crop", post.split(":", 1)[1]]
            subprocess.check_call(cmd)
        elif post == "tape":
            key_tape(raw, dst)
        else:
            Image.open(raw).convert("RGB").save(dst, optimize=True)
        w, h = Image.open(dst).size
        model, lic = MODELS[meta["arch"]]
        manifest["files"][name] = dict(category=cat, model=model, licence=lic, prompt=meta["prompt"], seed=meta["seed"],
            steps=meta["steps"], cfg=meta["cfg"], generated_size=[meta["width"], meta["height"]], size=[w, h],
            sampler="euler/simple" if meta["arch"] == "klein" else "res_multistep/simple", post=note, no_lettering=True,
            raw=os.path.basename(raw))
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
    sheet.convert("RGB").save(os.path.join(RAW, "contact_sheet_stage1.png"))
    print("done", len(names))


if __name__ == "__main__":
    main()
