"""Fit a ComfyUI-generated flat cabinet-face image to CabinetBezel's 640x360 rig space.

Run with the ComfyUI venv python (PIL + numpy):
  python tools/comfyui/make_bezel.py SRC.png OUT.png [--crop x0,y0,x1,y1] [--scale 2]

SRC is the raw flat face (no screen opening: the model cannot place a portrait cut-out exactly). The script
stretches it over the printed sheet (CabinetBezel.sheet_x(), x 40..600), paints a recessed key-black lip and
inner shadow round the screen hole, and makes the hole exactly transparent (alpha 0). Everything outside the
sheet is transparent so the ArcadeBackdrop shows. Keep HOLE/SHEET in step with data/cabinet/cabinet_screen.tres
(grid 256x304, centred in 640x360) and CabinetBezel.sheet_x(). Contains no lettering: text is drawn in-game.
"""
import argparse
import numpy as np
from PIL import Image, ImageFilter

REF = (640, 360)
GRID = (256, 304)
HOLE = ((REF[0] - GRID[0]) // 2, (REF[1] - GRID[1]) // 2, GRID[0], GRID[1])   # x, y, w, h = 192, 28, 256, 304
SHEET_X = (HOLE[0] - 152, HOLE[0] + HOLE[2] + 152)                               # 40 .. 600


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src"); ap.add_argument("out")
    ap.add_argument("--crop", default=None, help="x0,y0,x1,y1 in source px (trim borders/room)")
    ap.add_argument("--scale", type=int, default=2)
    a = ap.parse_args()
    k = a.scale
    W, H = REF[0] * k, REF[1] * k
    src = Image.open(a.src).convert("RGB")
    if a.crop:
        src = src.crop(tuple(int(v) for v in a.crop.split(",")))
    sx0, sx1 = SHEET_X[0] * k, SHEET_X[1] * k
    face = src.resize((sx1 - sx0, H), Image.LANCZOS)
    canvas = np.zeros((H, W, 4), np.float32)
    canvas[:, sx0:sx1, :3] = np.asarray(face, np.float32)
    canvas[:, sx0:sx1, 3] = 255
    hx, hy, hw, hh = (v * k for v in HOLE)
    yy, xx = np.mgrid[0:H, 0:W]
    # distance (px) outside the hole rectangle, 0 inside
    dx = np.maximum(np.maximum(hx - xx, xx - (hx + hw - 1)), 0)
    dy = np.maximum(np.maximum(hy - yy, yy - (hy + hh - 1)), 0)
    d = np.sqrt(dx * dx + dy * dy) / k            # in reference units
    # recessed key-black lip (2 units) then a soft inner-shadow falloff on the face (10 units)
    lip = d <= 3.0
    shade = np.clip(1.0 - (d - 3.0) / 10.0, 0.0, 1.0) ** 1.6 * 0.55
    for c in range(3):
        ch = canvas[..., c]
        ch *= (1.0 - shade)
        ch[lip] = 8.0
    # a thin light catch on the lip's outer edge (bottom/right of a lit-from-above cut-out)
    edge = (d > 3.0) & (d <= 4.0) & (yy > hy + hh // 2)
    canvas[edge, :3] = np.minimum(canvas[edge, :3] * 1.35 + 20, 255)
    # side edges of the sheet: a dark molding line, and a soft vignette towards the sheet's edges
    vx = np.minimum(xx - sx0, sx1 - 1 - xx).astype(np.float32) / k
    side = np.clip(1.0 - vx / 6.0, 0.0, 1.0) * 0.6
    ty = np.minimum(yy, H - 1 - yy).astype(np.float32) / k
    top = np.clip(1.0 - ty / 5.0, 0.0, 1.0) * 0.4
    inside = (xx >= sx0) & (xx < sx1)
    f = (1.0 - np.maximum(side, top))[..., None]
    canvas[..., :3] = np.where(inside[..., None], canvas[..., :3] * f, canvas[..., :3])
    # the exact cut-out
    canvas[hy:hy + hh, hx:hx + hw, :] = 0
    Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8), "RGBA").save(a.out, optimize=True)
    print(a.out, (W, H), "hole", HOLE)


if __name__ == "__main__":
    main()
