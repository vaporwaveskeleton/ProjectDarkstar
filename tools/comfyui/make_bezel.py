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


def find_opening(src):
    """Bounding box (x0,y0,x1,y1) of the dark opening round the image centre, scanned along the centre row/column."""
    g = np.asarray(src.convert("L").filter(ImageFilter.MedianFilter(5)), np.float32)
    h, w = g.shape
    cx, cy = w // 2, h // 2
    dark = g < 75.0
    if not dark[cy, cx]:
        raise SystemExit("centre of the art is not dark: no opening found")
    def run(line, c):
        lo = c
        while lo > 0 and line[lo - 1]:
            lo -= 1
        hi = c
        while hi < len(line) - 1 and line[hi + 1]:
            hi += 1
        return lo, hi + 1
    # use the median of three scan lines so a scuff or a speck cannot cut the run short
    xs = [run(dark[cy + d], cx) for d in (-h // 8, 0, h // 8)]
    ys = [run(dark[:, cx + d], cy) for d in (-w // 8, 0, w // 8)]
    x0, x1 = sorted(v[0] for v in xs)[1], sorted(v[1] for v in xs)[1]
    y0, y1 = sorted(v[0] for v in ys)[1], sorted(v[1] for v in ys)[1]
    return x0, y0, x1, y1


def trim_background(src):
    """Crop to the bounding box of everything that differs from the corner colour (the photo backdrop)."""
    a = np.asarray(src, np.float32)
    corner = np.median(np.concatenate([a[:6, :6].reshape(-1, 3), a[:6, -6:].reshape(-1, 3), a[-6:, :6].reshape(-1, 3), a[-6:, -6:].reshape(-1, 3)]), axis=0)
    diff = np.abs(a - corner).max(axis=2) > 45
    ys, xs = np.where(diff)
    return src.crop((int(xs.min()) + 3, int(ys.min()) + 3, int(xs.max()) - 2, int(ys.max()) - 2))


def warp_opening(src, w_out, h_out, k):
    """Piecewise 3x3 stretch so the art's opening lands exactly on the hole (sheet-local), margins absorb the change."""
    src = trim_background(src)
    ox0, oy0, ox1, oy1 = find_opening(src)
    hx = (HOLE[0] - SHEET_X[0]) * k
    hy = HOLE[1] * k
    xs_in = [0, ox0, ox1, src.width]; ys_in = [0, oy0, oy1, src.height]
    xs_out = [0, hx, hx + HOLE[2] * k, w_out]; ys_out = [0, hy, hy + HOLE[3] * k, h_out]
    out = Image.new("RGB", (w_out, h_out))
    for j in range(3):
        for i in range(3):
            box = (xs_in[i], ys_in[j], xs_in[i + 1], ys_in[j + 1])
            size = (xs_out[i + 1] - xs_out[i], ys_out[j + 1] - ys_out[j])
            out.paste(src.crop(box).resize(size, Image.LANCZOS), (xs_out[i], ys_out[j]))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src"); ap.add_argument("out")
    ap.add_argument("--crop", default=None, help="x0,y0,x1,y1 in source px (trim borders/room)")
    ap.add_argument("--scale", type=int, default=2)
    ap.add_argument("--fit-opening", action="store_true", help="find the art's own dark screen opening and warp it onto the hole (piecewise stretch)")
    a = ap.parse_args()
    k = a.scale
    W, H = REF[0] * k, REF[1] * k
    src = Image.open(a.src).convert("RGB")
    if a.crop:
        src = src.crop(tuple(int(v) for v in a.crop.split(",")))
    sx0, sx1 = SHEET_X[0] * k, SHEET_X[1] * k
    if a.fit_opening:
        face = warp_opening(src, sx1 - sx0, H, k)
    else:
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
