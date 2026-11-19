// DARKSTAR — the Composure wick (AUDIO-001 §6.2 E01–E04, §6.5; requested by the M1 chat, re-voiced
// for the Aether by PM direction 2026-11-19).
// Build:  node .claude/skills/chirp-game-audio/bin/chirp.js build audio/src/composure.cx.js --out assets/audio/generated --mono
// The wick is the post-Pretence Vigil's internal state made hearable, in the Aether's voice (§12.12):
// wet, slow onsets, air in every layer; never a sting (§1.1), no transient (§1.4, L4). Band-down
// cues grow more unsettling by tuning and register (the beat widens, a partial sours), never by
// level; recovery is a soft relief. These are band-CHANGE one-shots (M1 plays one per change); the
// continuous wick layer of §6.5 is a runtime layer, not built yet. UNAUDITIONED.

const c = (f, cents) => f * Math.pow(2, cents / 1200)
const AIR = [reverb({ size: 0.85, damp: 0.5, mix: 0.45 }), chorus({ rate: 0.2, depth: 0.004, mix: 0.3 }), limiter({ ceiling: 0.5 })]
const hiss = (dur, env, cut, vol) => noise({ color: "pink", dur, env, filter: { type: "bp", cutoff: cut, q: 0.8 }, vol })
const glass = (f, dur, env, vol) => tone({ wave: "fm", fm: { ratio: 2.41, index: 0.5 }, freq: f, dur, env, vol })

// E01 Frayed entered: the wick hiss gains a second, beating layer (a slow beat, 1.5 Hz).
sfx("wick_frayed", { vol: 0.9, fx: AIR },
  hiss(1.6, [0.5, 0.3, 0.7, 0.6], 2800, 0.12),
  glass(330, 1.6, [0.6, 0.3, 0.7, 0.6], 0.07),
  tone({ wave: "sine", freq: 331.5, dur: 1.6, env: [0.7, 0.3, 0.7, 0.6], vol: 0.06 }))

// E02 Unmoored entered: the beat speeds (5 Hz) and a soured partial joins (+11 cents off a fifth).
sfx("wick_unmoored", { vol: 0.9, fx: AIR },
  hiss(1.6, [0.45, 0.3, 0.75, 0.6], 2600, 0.12),
  glass(330, 1.6, [0.5, 0.3, 0.7, 0.6], 0.07),
  tone({ wave: "sine", freq: 335, dur: 1.6, env: [0.6, 0.3, 0.7, 0.6], vol: 0.06 }),
  tone({ wave: "sine", freq: c(495, 11), dur: 1.4, env: [0.7, 0.3, 0.6, 0.6], vol: 0.04 }))

// E03 Hollowed entered: the hiss stops dead and the field goes dry and wide (a build state, not a
// punishment, §1.1). The beating swells, then everything cuts at once; only a dry low breath remains.
sfx("wick_hollowed", { vol: 0.9 },
  hiss(0.7, [0.4, 0, 1, 0.01], 2400, 0.12),
  glass(330, 0.7, [0.4, 0, 1, 0.01], 0.06),
  tone({ wave: "sine", freq: 338, dur: 0.7, env: [0.45, 0, 1, 0.01], vol: 0.05 }),
  at(0.72, noise({ color: "brown", dur: 0.6, env: [0.05, 0.3, 0.3, 0.3], filter: { type: "lp", cutoff: 300 }, vol: 0.05 })))

// E04 Wick recovery: a soft relief. The hiss thins upward over 2 s ✱ while the beating pair
// settles onto one clean unison and a warm glass fifth opens above it.
sfx("wick_recovery", { vol: 1.0, fx: AIR },
  noise({ color: "pink", dur: 2.0, env: [0.2, 0.4, 0.5, 0.5], filter: { type: "bp", from: 2400, to: 8000, q: 1.0 }, vol: 0.1 }),
  glass(330, 2.0, [0.3, 0.4, 0.6, 0.8], 0.06),
  tone({ wave: "sine", freq: 333, to: 330, slide: 1.5, dur: 2.0, env: [0.3, 0.4, 0.6, 0.8], vol: 0.05 }),
  at(0.8, tone({ wave: "triangle", freq: 495, dur: 1.4, env: [0.6, 0.3, 0.5, 0.8], vol: 0.04 })))
