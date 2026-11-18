// DARKSTAR — reference sprites rendered with pxl (GDD-001 D-13 amended, ART-001 §14.8).
// Build: node .claude/skills/pxl/bin/pxl.js build art/src/reference.px.js --out assets/art/generated
include("darkstar_palette.px.js")

// The 32-colour palette as a swatch card: 8 columns × 4 rows of 4×4 cells, in palette-index order.
sprite("ds_ui_paletteSwatch", { w: 32, h: 16 }, (c) => {
  const keys = "0123456789abcdefghijklmnopqrstuv"
  for (let i = 0; i < 32; i++) {
    c.rect((i % 8) * 4, Math.floor(i / 8) * 4, 4, 4, keys[i])
  }
})
