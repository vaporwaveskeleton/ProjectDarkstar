"""Preview-only mock-ups of three typographic directions for the "PROJECT: DARKSTAR" marquee title.

Run with the ComfyUI venv python. Draws with a system font so the owner can choose a direction; NOTHING here ships.
The shipped title is post-added in game (VectorLabel / PixelText or a bespoke stroke-glyph / pxl title) after the pick.
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ART = os.path.join(REPO, "assets", "art", "comfyui")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join("E:/GameDev/ProjectDarkstar", "research", "comfyui_out", "title_directions.png")
FONT = "C:/Windows/Fonts/impact.ttf"
W, H = 1344, 256


def mask(text, size, font=FONT, tracking=6):
    f = ImageFont.truetype(font, size)
    m = Image.new("L", (W, H), 0); d = ImageDraw.Draw(m)
    total = sum(d.textlength(c, font=f) + tracking for c in text) - tracking
    x = (W - total) / 2; y = (H - size) / 2 - size * 0.08
    for c in text:
        d.text((x, y), c, font=f, fill=255); x += d.textlength(c, font=f) + tracking
    return m


def grad(colors, vertical=True):
    a = np.zeros((H, W, 3), np.float32)
    n = len(colors) - 1
    for i in range(H):
        t = i / (H - 1) * n; k = min(int(t), n - 1); u = t - k
        a[i] = np.array(colors[k]) * (1 - u) + np.array(colors[k + 1]) * u
    return Image.fromarray(a.astype(np.uint8), "RGB")


def outline(m, r):
    return ImageChops.subtract(m.filter(ImageFilter.MaxFilter(r * 2 + 1)), m)


def a_chrome(bg):
    # chunky chrome: sky-to-horizon gradient fill, black key outline, hard drop shadow; the colon is two stacked chrome blocks
    m = mask("PROJECT: DARKSTAR", 150)
    out = bg.copy()
    sh = ImageChops.offset(m.filter(ImageFilter.MaxFilter(9)), 6, 8)
    out.paste((10, 6, 24), mask=sh)
    out.paste(grad([(250, 250, 255), (120, 170, 220), (30, 40, 90), (255, 140, 60), (255, 230, 170)]), mask=m)
    out.paste((8, 6, 20), mask=outline(m, 4))
    return out


def b_stripe(bg):
    # day-glo orange letters with the bezel's racing stripes (magenta, cyan) as a offset triple shadow and a cream keyline
    m = mask("PROJECT: DARKSTAR", 118, tracking=8)
    out = bg.copy()
    for dx, col in ((18, (30, 190, 240)), (12, (240, 60, 160)), (6, (255, 255, 255))):
        out.paste(col, mask=ImageChops.offset(m, dx, dx // 2))
    out.paste((255, 110, 20), mask=m)
    out.paste((12, 8, 28), mask=outline(m, 3))
    return out


def c_neon_pixel(bg):
    # stepped, scanlined sunset fill (pixel-art lineage), thick outline, glowing cyan edge
    m = mask("PROJECT: DARKSTAR", 116, tracking=10)
    small = m.resize((W // 4, H // 4), Image.NEAREST).resize((W, H), Image.NEAREST)
    out = bg.copy()
    glow = small.filter(ImageFilter.GaussianBlur(10))
    out.paste((40, 220, 255), mask=glow.point(lambda v: min(255, v * 2)))
    fill = grad([(255, 70, 160), (255, 140, 60), (255, 230, 90)])
    fa = np.asarray(fill).copy(); fa[::8] = (fa[::8] * 0.55).astype(np.uint8)
    out.paste(Image.fromarray(fa), mask=small)
    out.paste((10, 6, 30), mask=outline(small, 4))
    return out


def main():
    bgs = [Image.open(os.path.join(ART, f"marquee_{i}.png")).convert("RGB").resize((W, H)) for i in (1, 2, 3)]
    fns = [("A  chrome gradient, black key, hard shadow", a_chrome), ("B  day-glo with racing-stripe shadow", b_stripe), ("C  stepped scanline sunset, neon edge", c_neon_pixel)]
    sheet = Image.new("RGB", (W, 3 * (H + 28)), (60, 60, 60)); d = ImageDraw.Draw(sheet)
    for i, (label, fn) in enumerate(fns):
        y = i * (H + 28)
        d.text((8, y + 8), label + "   (preview only: system font; shipped title is built in game)", fill=(255, 255, 255))
        sheet.paste(fn(bgs[i]), (0, y + 28))
    sheet.save(OUT); print(OUT)


if __name__ == "__main__":
    main()
