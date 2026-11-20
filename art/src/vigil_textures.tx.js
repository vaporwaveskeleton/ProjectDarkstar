include("darkstar_palette.tx.js")
// The Aether Vigil's hull plating (ART-001 §16.7, §14.8a; features/vigil): hammered brass, dark tarnish in the
// hollows and seams, for a CanvasTexture (albedo + normal) the Plating shader lights with the skiff's lantern.
// Build:
//   node .claude/skills/loom/bin/loom.js build art/src/vigil_textures.tx.js --out assets/art/generated/textures
// The brass colour itself stays AetherVigilLook's plate bands (BONE ramp; GAS is the lamp's alone, ART-001 §4):
// this albedo is a luminance map the band colour multiplies (tarnish dark, polished crowns bright). Sized so one
// hammer blow is about 4 px of hull at 640×360 (owner 2026-11-19: dents must read at 1280×720).

const hammer = cells({ scale: 7, jitter: 0.85, seed: 41 }).as("hammer")
const dish = hammer.levels(0, 0.6).pow(1.6).blur(0.006).as("dish")       // a broad shallow bowl per blow, 0 at its centre
const fine = noise({ scale: 32, octaves: 3, seed: 42 }).as("fine")
const brassH = dish.mul(0.7).add(fine.mul(0.06)).as("height")
const seams = hammer.edge.levels(0, 0.06).invert().as("seams")             // the ridges between blows
const hollows = brassH.cavity(0.03, 8).as("hollows")
const tarnish = hollows.mul(1.6).max(dish.invert().pow(3).mul(0.45)).mul(noise({ scale: 4, seed: 43 }).levels(0.2, 0.6)).clamp(0, 1).as("tarnish")
const polish = brassH.convex(0.012, 10).max(seams.mul(0.6)).as("polish")

material("ds_vigil_brass", { size: 256, depth: 0.06 }, {
  height: brassH,
  color: ramp(fine.mix(hammer.id, 0.4), ["bone3", "bone5"]).mix("void1", tarnish.mul(0.85)).mix("bone5", polish.mul(0.6)),
  rough: fine.levels(0, 1, 0.25, 0.4).mix(0.85, tarnish.blur(0.004)).mix(0.12, polish.blur(0.004)),
  metal: 1,
})
