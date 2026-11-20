include("darkstar_palette.tx.js")
// The Aether Vigil's hull plating (ART-001 §16.7, §14.8a; features/vigil): hammered brass with tarnish in the
// hollows, for a CanvasTexture (albedo + normal) lit by the skiff's own lantern. Build:
//   node .claude/skills/loom/bin/loom.js build art/src/vigil_textures.tx.js --out assets/art/generated/textures
// The brass colour itself stays AetherVigilLook's plate bands (BONE ramp; GAS is the lamp's alone, ART-001 §4):
// this albedo is a near-white luminance map the band colour multiplies, so the plate reads the same at a glance
// and only gains surface. Keep its contrast low: the silhouette and the 12 px hitbox read first (ART-001 §16.3).

const hammer = cells({ scale: 11, jitter: 0.9, seed: 41 }).as("hammer")
const peen = hammer.levels(0, 0.7).pow(0.5).blur(0.006)           // a soft round dish per blow, 0 at its centre
const fine = noise({ scale: 40, octaves: 3, seed: 42 }).as("fine")
const brassH = peen.mul(0.5).add(fine.mul(0.08)).as("height")
const tarnish = brassH.cavity(0.02, 10).max(peen.invert().mul(0.25)).mul(noise({ scale: 5, seed: 43 }).levels(0.3, 0.7)).as("tarnish")
const polish = brassH.convex(0.01, 12).as("polish")

material("ds_vigil_brass", { size: 256, depth: 0.035 }, {
  height: brassH,
  color: ramp(fine.mix(hammer.id, 0.3), ["bone3", "bone5"]).mix("bone1", tarnish.mul(0.9)).mix("bone5", polish.mul(0.5)),
  rough: fine.levels(0, 1, 0.3, 0.45).mix(0.75, tarnish).mix(0.18, polish),
  metal: 1,
})
