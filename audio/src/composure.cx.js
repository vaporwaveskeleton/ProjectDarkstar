// DARKSTAR — the Composure wick (AUDIO-001 §6.2 E01–E04, §6.5; requested by the M1 chat 2026-11-19).
// Build:  node .claude/skills/chirp-game-audio/bin/chirp.js build audio/src/composure.cx.js --out assets/audio/generated --mono
// The wick is the player's internal state made hearable. These are band-CHANGE one-shots (M1 plays
// one per band change); the continuous wick layer of §6.5 (level tracking composure_band, hiss
// position from chant_proximity) is a runtime layer, not built yet. No transient (§1.4, L4). UNAUDITIONED.

const hiss = (dur, env, cut, vol) => noise({ color: "white", dur, env, filter: { type: "bp", cutoff: cut, q: 0.9 }, vol })

// E01 Frayed entered: the wick hiss gains a second, beating layer (two close tones, a slow beat).
sfx("wick_frayed", { vol: 0.5 },
  hiss(1.4, [0.4, 0.2, 0.7, 0.5], 3200, 0.12),
  tone({ wave: "sine", freq: 440, dur: 1.4, env: [0.5, 0.2, 0.7, 0.5], vol: 0.08 }),
  tone({ wave: "sine", freq: 441.5, dur: 1.4, env: [0.5, 0.2, 0.7, 0.5], vol: 0.08 }))

// E02 Unmoored entered: the beat speeds and a second detuned partial joins; still no transient.
sfx("wick_unmoored", { vol: 0.5 },
  hiss(1.4, [0.35, 0.2, 0.75, 0.5], 3400, 0.13),
  tone({ wave: "sine", freq: 440, dur: 1.4, env: [0.4, 0.2, 0.7, 0.5], vol: 0.08 }),
  tone({ wave: "sine", freq: 444, dur: 1.4, env: [0.4, 0.2, 0.7, 0.5], vol: 0.08 }),
  tone({ wave: "sine", freq: 662, dur: 1.4, env: [0.5, 0.2, 0.6, 0.5], vol: 0.05 }))

// E03 Hollowed entered: the hiss stops dead and the field goes dry (a build state, not a
// punishment, §1.1: it must sound capable). A short swell of the hiss, cut clean, then nothing.
sfx("wick_hollowed", { vol: 0.5 },
  hiss(0.6, [0.35, 0, 1, 0.01], 3400, 0.14),
  tone({ wave: "sine", freq: 440, dur: 0.6, env: [0.35, 0, 1, 0.01], vol: 0.07 }),
  tone({ wave: "sine", freq: 444, dur: 0.6, env: [0.35, 0, 1, 0.01], vol: 0.07 }))

// E04 Wick recovery: the hiss thinning upward over 2 s ✱ (the band filter rising, the level falling).
sfx("wick_recovery", { vol: 1.0 },
  noise({ color: "white", dur: 2.0, env: [0.2, 0.3, 0.6, 0.4], filter: { type: "bp", from: 2400, to: 9000, q: 1.2 }, vol: 0.13 }),
  tone({ wave: "sine", freq: 440, to: 880, slide: 2.0, dur: 2.0, env: [0.2, 0.3, 0.4, 0.4], vol: 0.04 }))
