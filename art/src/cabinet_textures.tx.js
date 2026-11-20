include("darkstar_palette.tx.js")
// Act 0 cabinet surfaces (ART-001 §12.7a, §14.8a, §15.1 T0 bezel row): loom textures for the bezel hardware
// round the screen, never the screen itself. Build:
//   node .claude/skills/loom/bin/loom.js build art/src/cabinet_textures.tx.js --out assets/art/generated/textures
// The cabinet's real-object colours live in CabinetSurface (outside the Neon Cabinet palette, never Look.c), so
// ds_cab_laminate and ds_cab_steel are NEUTRAL detail maps: their albedo is read as luminance around its mean
// and multiplies the CabinetSurface colour in the shader; their normal map perturbs the shader's own normal.
// ds_cab_side is the side panel's full albedo (black paint chipped back to plywood), Pal roles only.

// ---- worn laminate on the control panel: fibrous grain, mottling, fine scratches, grime packed in them
const fibre = noise({ scale: [5, 40], octaves: 5, seed: 11 }).as("fibre")
const mottle = noise({ scale: 4, octaves: 3, seed: 12 }).as("mottle")
const scratchWarp = noise({ scale: 3, seed: 14 })
const scratches = ridged({ scale: [2, 22], octaves: 2, seed: 13 }).warp(scratchWarp, 0.04).threshold(0.9, 0.04)
  .mul(noise({ scale: 3, seed: 16 }).levels(0.35, 0.65)).as("scratches")
const lamH = fibre.mul(0.18).add(mottle.mul(0.12)).sub(scratches.mul(0.3)).add(0.5)
const lamGrime = lamH.cavity(0.008, 14).mul(noise({ scale: 6, seed: 15 }).levels(0.3, 0.8)).as("grime")

material("ds_cab_laminate", { size: 256, depth: 0.01 }, {
  height: lamH,
  color: ramp(fibre.mix(mottle, 0.45), ["bone3", "bone4", "bone5"]).mix("bone5", scratches.mul(0.5)).mix("bone1", lamGrime.mul(0.8)),
  rough: fibre.levels(0, 1, 0.55, 0.72).mix(0.92, lamGrime),
})

// ---- the side panel: black-painted plywood, paint chipped back to the wood at random, grime in the chips
const ply = planks({ rows: 2, per: 1, gap: 0.003, bevel: 0.004, vary: 0.1, grain: 46, seed: 21 })
const chips = noise({ scale: 5, octaves: 5, seed: 22 }).warp(noise({ scale: 9, seed: 24 }), 0.05).threshold(0.7, 0.03).as("chips")
const peel = noise({ scale: 18, octaves: 3, seed: 23 })
const sideH = peel.mul(0.04).add(0.62).mix(ply.grain.mul(0.1).add(0.38), chips)
const sideGrime = sideH.cavity(0.01, 12).max(chips.blur(0.01).sub(chips).mul(2)).as("side_grime")

material("ds_cab_side", { size: 256, depth: 0.02 }, {
  height: sideH,
  color: ramp(peel, ["null", "void0", "bone0"]).mix(ramp(ply.grain.mix(ply.id, 0.3), ["gas0", "gas1", "gas2"]), chips).mix("null", sideGrime.mul(0.7)),
  rough: peel.levels(0, 1, 0.5, 0.65).mix(0.85, chips),
})

// ---- satin-painted sheet steel (coin door): orange-peel, dents, rubbed-through scuffs, grime in the low spots
const peelS = noise({ scale: 22, octaves: 3, seed: 31 }).as("orange_peel")
const dents = cells({ scale: 7, jitter: 1, seed: 32 }).levels(0, 0.35).invert().mul(noise({ scale: 4, seed: 33 }).levels(0.5, 0.8)).as("dents")
const scuffs = ridged({ scale: [3, 14], octaves: 3, seed: 34 }).warp(noise({ scale: 5, seed: 35 }), 0.06).threshold(0.86, 0.06)
  .mul(noise({ scale: 3, seed: 36 }).levels(0.4, 0.7)).as("scuffs")
const steelH = peelS.mul(0.06).sub(dents.mul(0.12)).sub(scuffs.mul(0.05)).add(0.5)
const steelGrime = steelH.cavity(0.012, 12).mul(noise({ scale: 5, seed: 37 }).levels(0.25, 0.75)).as("steel_grime")

material("ds_cab_steel", { size: 256, depth: 0.03 }, {
  height: steelH,
  color: ramp(peelS, ["bone3", "bone4"]).mix("bone5", scuffs.mul(0.7)).mix("bone1", steelGrime.mul(0.85)),
  rough: peelS.levels(0, 1, 0.5, 0.6).mix(0.3, scuffs).mix(0.9, steelGrime),
})

// ---- brushed, scratched metal trim (coin-door entry plate, control-panel lip): long brush lines, cross scratches
const brushLines = noise({ scale: [1, 160], octaves: 3, seed: 61 }).as("brush")
const brushBands = noise({ scale: [2, 24], octaves: 2, seed: 62 })
const crossScratch = ridged({ scale: [4, 6], octaves: 2, seed: 63 }).warp(noise({ scale: 6, seed: 64 }), 0.08).threshold(0.93, 0.03)
  .mul(noise({ scale: 3, seed: 65 }).levels(0.35, 0.65)).as("cross_scratches")
const brushH = brushLines.mul(0.08).add(brushBands.mul(0.04)).sub(crossScratch.mul(0.12)).add(0.5)

material("ds_cab_brushed", { size: 256, depth: 0.015 }, {
  height: brushH,
  color: ramp(brushLines.mix(brushBands, 0.35), ["bone2", "bone4", "bone5"]).mix("bone5", crossScratch.mul(0.8)),
  rough: brushLines.levels(0, 1, 0.3, 0.45).mix(0.2, crossScratch),
})

// ---- fingerprint grease on the bezel glass: whorled prints and palm smears. A mask (NULL = clean glass, BONE-5 =
// heavy grease) the glass shader turns into a lit, hazy sheen in the places hands go (wear_k).
const printSpots = dots({ scale: 6, radius: 0.34, jitter: 0.9, soft: 0.7, seed: 51 }).as("print_spots")
const film = noise({ scale: 24, octaves: 2, seed: 52 }).levels(0.3, 0.8).as("film")   // greasy film breaking up, no ridge lines
const prints = printSpots.mul(film.mul(0.5).add(0.5)).as("prints")
const smear = noise({ scale: [2, 4], octaves: 4, seed: 53 }).warp(noise({ scale: 3, seed: 54 }), 0.12).levels(0.55, 0.9).blur(0.01).as("smear")
const grease = prints.max(smear.mul(0.5)).clamp(0, 1)

material("ds_cab_glass_smudge", { size: 256, depth: 0.004 }, {
  height: grease.mul(0.2).add(0.4),
  color: ramp(grease, ["null", "bone3", "bone5"]),
  rough: grease.levels(0, 1, 0.05, 0.6),
})
