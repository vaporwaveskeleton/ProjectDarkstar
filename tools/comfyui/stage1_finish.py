"""Stage 1 finishing: raw ComfyUI renders -> assets/art/comfyui/ + manifest.json + contact sheet.

Run with the ComfyUI venv python:  python tools/comfyui/stage1_finish.py [RAW_ROOT]
RAW_ROOT defaults to research/comfyui_out (subfolders stage1, stage1b) in the main checkout (git-ignored). Every shipped image
gets a manifest entry (model, licence, prompt, seed, steps, size) taken from the render's .json sidecar
(ART-001 section 14.9). Post: bezels via make_bezel.py (exact screen cut-out), tape via a luminance key.
"""
import glob, json, os, subprocess, sys
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
    ("bezel_p4_a.png", "bezel", "stage1b", "p4", 401, "bezel", "P4 pristine print; the art's own dark opening is warped onto the exact 256x304 hole"),
    ("bezel_p4_b.png", "bezel", "stage1b", "p4", 402, "bezel", "P4 pristine print; opening warped onto the hole"),
    ("bezel_p4_c.png", "bezel", "stage1b", "p4", 403, "bezel", "P4 pristine print; opening warped onto the hole"),
    ("bezel_p2_a.png", "bezel", "stage1b", "p2", 404, "bezel", "P2 worn print (comparison cell; wear should come from the overlay shader); opening warped onto the hole"),
    ("bezel_p2_b.png", "bezel", "stage1b", "p2", 405, "bezel", "P2 worn print (comparison cell); opening warped onto the hole"),
    ("marquee_1.png", "cabinet_art", "stage1b", "marquee", 411, "", "lettering-free marquee art; the title is post-added"),
    ("marquee_2.png", "cabinet_art", "stage1b", "marquee", 412, "", "lettering-free marquee art; the title is post-added"),
    ("marquee_3.png", "cabinet_art", "stage1b", "marquee", 413, "", "lettering-free marquee art; the title is post-added"),
    ("tape_1.png", "tape", "stage1", "tape", 201, "tape", "alpha by luminance key"),
    ("tape_2.png", "tape", "stage1", "tape", 202, "tape", "alpha by luminance key"),
    ("tape_3.png", "tape", "stage1", "tape", 203, "tape", "alpha by luminance key"),
    ("tape_4.png", "tape", "stage1", "tape", 204, "tape", "alpha by luminance key"),
    ("backdrop_1.png", "backdrop", "stage1", "backdrop", 301, "", "unmodified; blurred bokeh, lettering unreadable"),
    ("backdrop_2.png", "backdrop", "stage1", "backdrop", 302, "", "unmodified; blurred bokeh, lettering unreadable"),
    ("backdrop_3.png", "backdrop", "stage1", "backdrop", 303, "", "unmodified; blurred bokeh, lettering unreadable"),
    ("backdrop_4.png", "backdrop", "stage1", "backdrop", 304, "", "unmodified; blurred bokeh, lettering unreadable"),
]
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
    Image.fromarray(rgba.astype(np.uint8), "RGBA").save(dst, optimize=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    manifest = {"_about": "ART-001 section 14.9: provenance for every ComfyUI image under assets/art/comfyui/. Rebuilt by tools/comfyui/stage1_finish.py.", "files": {}}
    for name, cat, sub, tag, seed, post, note in JOBS:
        global RAW
        RAW = os.path.join(RAW_ROOT, sub)
        raw = find(tag, seed, "png"); meta = json.load(open(find(tag, seed, "json")))
        dst = os.path.join(OUT, name)
        if post == "bezel":
            cmd = [sys.executable, os.path.join(HERE, "make_bezel.py"), raw, dst]
            cmd += ["--fit-opening"]
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
