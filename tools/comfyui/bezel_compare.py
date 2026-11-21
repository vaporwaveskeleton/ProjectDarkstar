"""Bezel look comparison: prompts P0..P3 x models (klein, zimage), fixed seed, one labelled contact sheet + CSV log.

Run with the ComfyUI venv python while the server is up:
  E:\\Tools\\ComfyUI\\venv\\Scripts\\python.exe tools\\comfyui\\bezel_compare.py [--seed 1983]
Output (local-only, git-ignored): research\\comfyui_out\\bezel_compare\\ (cells, bezel_compare_sheet.png, bezel_compare_log.csv)
P0 is quoted from ART-001 (docs/02-art/ART_BIBLE.md) §12.7, §12.7a and §12.7a surround/Fable passes, joined with " | ".
"""
import argparse, csv, json, os, subprocess, sys
from PIL import Image, ImageDraw

OUT = r"E:\GameDev\ProjectDarkstar\research\comfyui_out\bezel_compare"
HERE = os.path.dirname(os.path.abspath(__file__))

P0 = (
    "a real-world object rendered at native resolution as full-colour printed cabinet art, like a real 1980s bezel "
    "(illustrated, saturated, with instruction panels) | "
    "printed 1983 marketing art for the Pretence, a real-world object | "
    "flat inks; key-black outlines; halftone shadow dots on a 3 px grid; a faint diagonal plexi glare. "
    "Saturated inks only inside illustrations; the fields are navy or black | "
    "the Vigil as a heroic yellow-and-red rocket-skiff diving toward the screen with a cyan lance bolt, and a small magenta-ringed planet. "
    "Magenta Choir monks carry glass | "
    "Printed art may stay comic-book (real cabinets had printed comic art) but must read as printed on a worn surface: fading, scuffs, peeling edges | "
    "As if you are really infront of an old arcade cabinet. You should feel as if you could reach out and touch it's grimy surface | "
    "a defocused late-70s / early-80s arcade floor: two rows of fictional cabinets as soft silhouettes with lit marquees, glowing screens and a control-panel ledge, "
    "their light pooling on the carpet; warm tungsten ceiling cans and stray neon as bokeh; an amber drop ceiling across the top, an oxblood carpet band across the bottom"
)
VARIANTS = [
    ("P0", "ART-001 text, verbatim excerpts", P0),
    ("P1", "more screenprint/ink: spot-colour print, coarse halftone, misregistration, key-black keylines",
     P0 + " | 1983 spot-colour screenprint, six flat inks plus key black, coarse Ben-Day halftone dots, ink slightly off register, thick key-black keylines, no airbrush, no glow"),
    ("P2", "more worn/grimy: scuffs, peeling print, grime in recesses, fingerprints on glass",
     P0 + " | heavily worn: scratched paint, peeling and flaking print, grime packed into recesses, fingerprints and smudges on the glass, chipped edges, faded reds"),
    ("P3", "warmer lighting: tungsten and amber room light, warm highlights, oxblood shadows",
     P0 + " | lit by warm tungsten and amber room light, warm highlights on the glass and metal, deep oxblood shadows, nostalgic golden glow"),
]
MODELS = [("klein", "FLUX.2 klein 4B"), ("zimage", "Z-Image-Turbo")]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", type=int, default=1983)
    ap.add_argument("--width", type=int, default=1344)
    ap.add_argument("--height", type=int, default=768)  # ~16:9, the 640x360 reference space
    a = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    rows = []
    for pid, change, prompt in VARIANTS:
        for arch, mname in MODELS:
            cmd = [sys.executable, os.path.join(HERE, "gen.py"), "--arch", arch, "--seed", str(a.seed),
                   "--width", str(a.width), "--height", str(a.height), "--tag", f"bezel_{pid}_{arch}",
                   "--out", OUT, "--prompt", prompt]
            lines = subprocess.check_output(cmd, text=True).strip().splitlines()
            meta = json.loads(lines[-1])
            rows.append(dict(prompt_id=pid, change=change, model=mname, arch=arch, file=lines[-2], seed=meta["seed"],
                             steps=meta["steps"], cfg=meta["cfg"], width=meta["width"], height=meta["height"],
                             seconds=meta["seconds"], vram_peak_mb=meta["vram_peak_mb"], prompt=prompt))
            print(pid, arch, meta["seconds"], "s")
    with open(os.path.join(OUT, "bezel_compare_log.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader(); w.writerows(rows)
    cw, ch, lab = 672, 384, 40
    sheet = Image.new("RGB", (cw * len(MODELS) + 220, (ch + lab) * len(VARIANTS) + 30), (20, 20, 20))
    d = ImageDraw.Draw(sheet)
    for j, (_, mname) in enumerate(MODELS):
        d.text((220 + j * cw + 8, 8), mname, fill=(255, 255, 255))
    for r in rows:
        i = [v[0] for v in VARIANTS].index(r["prompt_id"]); j = [m[0] for m in MODELS].index(r["arch"])
        x, y = 220 + j * cw, 30 + i * (ch + lab)
        sheet.paste(Image.open(r["file"]).convert("RGB").resize((cw, ch)), (x, y))
        d.text((x + 4, y + ch + 6), f"{r['prompt_id']} seed {r['seed']} steps {r['steps']} cfg {r['cfg']} {r['width']}x{r['height']} {r['seconds']}s", fill=(220, 220, 220))
    for i, (pid, change, _) in enumerate(VARIANTS):
        y = 30 + i * (ch + lab)
        d.text((8, y + 8), pid, fill=(255, 255, 0))
        words, line, yy = change.split(), "", y + 28
        for wd in words:
            if len(line) + len(wd) > 30:
                d.text((8, yy), line, fill=(200, 200, 200)); yy += 14; line = ""
            line += wd + " "
        d.text((8, yy), line, fill=(200, 200, 200))
    sheet.save(os.path.join(OUT, "bezel_compare_sheet.png"))
    print(os.path.join(OUT, "bezel_compare_sheet.png"))


if __name__ == "__main__":
    main()
