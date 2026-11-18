// DARKSTAR — Act 0 (the Cabinet) sound set, as code (GDD-001 D-14, AUDIO-001 §11.7).
// Build:  node .claude/skills/chirp-game-audio/bin/chirp.js build audio/src/cabinet.cx.js --out assets/audio/generated
// Every sound id below matches a cue AudioService plays. T0 = a 1983 arcade machine: square and
// triangle voices, short envelopes, a little crush. No sample() — D-14 forbids recordings.

// --- The Vigil and its Arc-Lance (AUDIO-001 A01–A10) -------------------------------------------

// A01 lance: a short brass snap, the ship's own voice
sfx("lance", { vol: 0.32, fx: [crush({ bits: 10 })] },
  tone({ wave: "square", freq: 1400, to: 520, slide: 0.06, dur: 0.06, duty: 0.25, env: [0.001, 0.03, 0.3, 0.02] }))

// A02 geode face struck: one grain of glass under pressure
sfx("geode_hit", { vol: 0.3 },
  noise({ color: "white", dur: 0.03, env: [0.001, 0.02, 0.0, 0.01], filter: { type: "hp", cutoff: 2500 } }),
  tone({ wave: "triangle", freq: "C7", to: "G6", dur: 0.04, env: [0.001, 0.03, 0.0, 0.02], vol: 0.5 }))

// A05 geode shatter: glass falling in three pieces, one of them late
sfx("geode_break", { vol: 0.55, fx: [crush({ bits: 8, rate: 16000 })] },
  noise({ color: "brown", dur: 0.35, env: [0.001, 0.15, 0.3, 0.3], filter: { type: "lp", from: 3000, to: 200 } }),
  tone({ wave: "square", freq: 180, to: 50, dur: 0.3, duty: 0.5, env: [0.001, 0.2, 0.2, 0.2], vol: 0.6 }),
  at(0.06, tone({ wave: "triangle", freq: "E6", dur: 0.05, env: [0.001, 0.04, 0, 0.05], vol: 0.35 })),
  at(0.11, tone({ wave: "triangle", freq: "B5", dur: 0.05, env: [0.001, 0.04, 0, 0.05], vol: 0.3 })),
  at(0.31, tone({ wave: "triangle", freq: "F#6", dur: 0.05, env: [0.001, 0.05, 0, 0.08], vol: 0.25 })))

// A06 shard pickup: one bright step of the ladder
sfx("shard_chime", { vol: 0.35 },
  tone({ wave: "triangle", freq: "G6", dur: 0.08, env: [0.001, 0.06, 0.4, 0.12] }),
  at(0.035, tone({ wave: "triangle", freq: "D7", dur: 0.1, env: [0.001, 0.08, 0.3, 0.15], vol: 0.6 })))

// --- Null-Iron Charges (AUDIO-001 B01–B09) -----------------------------------------------------

// B02 throw: chalk snap plus a short glass tail
sfx("charge_fire", { vol: 0.4 },
  noise({ color: "white", dur: 0.025, env: [0.001, 0.02, 0, 0.01], filter: { type: "bp", cutoff: 3000, q: 1.2 } }),
  tone({ wave: "saw", freq: 220, to: 880, slide: 0.2, dur: 0.22, env: [0.005, 0.1, 0.4, 0.08], vol: 0.5, filter: { type: "lp", cutoff: 3000 } }))

// B06 Charge lost — THE glass chime: clean 1.2 kHz, fast attack, 0.5 s decay, then the Choir's
// half-note a semitone down. The only bright, short, pure tone in the game.
sfx("charge_lost", { vol: 0.42 },
  tone({ wave: "sine", freq: 1200, dur: 0.05, env: [0.001, 0.5, 0, 0.3] }),
  tone({ wave: "sine", freq: 2400, dur: 0.03, env: [0.001, 0.2, 0, 0.1], vol: 0.25 }),
  at(0.12, tone({ wave: "triangle", freq: "C#4", to: "C4", slide: 0.3, dur: 0.35, env: [0.04, 0.1, 0.5, 0.2], vol: 0.35, vibrato: { rate: 5, depth: 0.2 } })))

// B04 Charge on the entity: a struck bell, detuned downward, no impact thud
sfx("charge_hit", { vol: 0.6, fx: [reverb({ size: 0.5, mix: 0.2 })] },
  tone({ wave: "fm", fm: { ratio: 3.5, index: 5, decay: 0.6 }, freq: "D4", to: "C#4", slide: 1.0, dur: 0.9, env: [0.001, 0.8, 0.2, 0.6] }),
  tone({ wave: "sine", freq: 73, to: 55, dur: 0.6, env: [0.001, 0.5, 0.2, 0.3], vol: 0.5 }))

// --- The Sepulchre and the build (AUDIO-001 G-family) -------------------------------------------

// a deposit: a dull thud as a vertebra seats
sfx("segment_deposit", { vol: 0.55 },
  tone({ wave: "sine", freq: 70, to: 40, dur: 0.3, env: [0.002, 0.2, 0.2, 0.15] }),
  noise({ color: "brown", dur: 0.08, env: [0.001, 0.06, 0, 0.04], filter: { type: "lp", cutoff: 400 }, vol: 0.5 }))

// a module knocked off: bone cracking away
sfx("segment_knocked", { vol: 0.5, fx: [crush({ bits: 9 })] },
  tone({ wave: "square", freq: 330, to: 110, dur: 0.25, duty: 0.4, env: [0.001, 0.15, 0.2, 0.1] }),
  noise({ color: "white", dur: 0.18, env: [0.001, 0.1, 0.1, 0.08], filter: { type: "lp", from: 4000, to: 600 }, vol: 0.5 }))

// --- The Choir (AUDIO-001 F-family, §5) -------------------------------------------------------

// F06 keening: a Grub mourns a lost deposit
sfx("grub_keen", { vol: 0.28 },
  tone({ wave: "sine", freq: "A5", to: "E5", slide: 0.5, dur: 0.5, env: [0.05, 0.1, 0.7, 0.2], vibrato: { rate: 7, depth: 0.4 } }),
  tone({ wave: "sine", freq: "A5", to: "D#5", slide: 0.5, dur: 0.45, env: [0.08, 0.1, 0.6, 0.2], vol: 0.5, vibrato: { rate: 6.3, depth: 0.4 } }))

sfx("grub_die", { vol: 0.35 },
  tone({ wave: "square", freq: 660, to: 120, dur: 0.18, duty: 0.3, env: [0.001, 0.1, 0.3, 0.05] }))

sfx("acolyte_fire", { vol: 0.28 },
  tone({ wave: "square", freq: 300, to: 180, dur: 0.1, duty: 0.4, env: [0.001, 0.06, 0.3, 0.04] }))

sfx("acolyte_die", { vol: 0.5, fx: [crush({ bits: 8 })] },
  noise({ color: "pink", dur: 0.45, env: [0.001, 0.25, 0.3, 0.2], filter: { type: "lp", from: 3000, to: 200 } }),
  tone({ wave: "square", freq: 220, to: 55, dur: 0.45, duty: 0.5, env: [0.001, 0.3, 0.2, 0.15], vol: 0.6 }))

// The chant bed (AUDIO-001 §5): the litany's minor chord sung by detuned saw "voices" through
// vowel-ish band-passes. Seamless loop; AudioService sets its level from distance and the build.
sfx("chant", { dur: 8, loop: true, vol: 0.55, fx: [reverb({ size: 0.8, damp: 0.5, mix: 0.35 }), limiter()] },
  tone({ wave: "saw", freq: "D3", dur: 8, env: [0.5, 0, 1, 0.5], vol: 0.25, vibrato: { rate: 0.23, depth: 0.08 }, filter: { type: "bp", cutoff: 700, q: 2 } }),
  tone({ wave: "saw", freq: "F3", dur: 8, env: [0.6, 0, 1, 0.5], vol: 0.2, vibrato: { rate: 0.31, depth: 0.1 }, filter: { type: "bp", cutoff: 1100, q: 2 } }),
  tone({ wave: "saw", freq: "A3", dur: 8, env: [0.7, 0, 1, 0.5], vol: 0.18, vibrato: { rate: 0.19, depth: 0.09 }, filter: { type: "bp", cutoff: 900, q: 2 } }),
  tone({ wave: "triangle", freq: "D2", dur: 8, env: [0.8, 0, 1, 0.5], vol: 0.3 }),
  noise({ color: "pink", dur: 8, env: [0.5, 0, 1, 0.5], vol: 0.05, filter: { type: "bp", cutoff: 2500, q: 1 }, tremolo: { rate: 0.4, depth: 0.5 } }))

// --- The Vigil's death and the cabinet's furniture (AUDIO-001 C08, I-family, §2.1) -------------

// C08 hull lost: the filter sweep, not an impact
sfx("vigil_die", { vol: 0.6, fx: [crush({ bits: 8, rate: 12000 })] },
  noise({ color: "white", dur: 1.2, env: [0.001, 0.6, 0.3, 0.5], filter: { type: "lp", from: 6000, to: 80 } }),
  tone({ wave: "saw", freq: 440, to: 30, dur: 1.1, env: [0.001, 0.5, 0.4, 0.4], vol: 0.45 }))

sfx("extra_life", { vol: 0.35 },
  tone({ wave: "square", freq: "C5", dur: 0.08, duty: 0.25, env: [0.001, 0.05, 0.6, 0.03] }),
  at(0.09, tone({ wave: "square", freq: "G5", dur: 0.08, duty: 0.25, env: [0.001, 0.05, 0.6, 0.03] })),
  at(0.18, tone({ wave: "square", freq: "C6", dur: 0.2, duty: 0.25, env: [0.001, 0.08, 0.6, 0.12] })))

// the quota jingle: the Office congratulates you (VIGIL COMPLETE)
sfx("quota", { vol: 0.35 },
  tone({ wave: "square", freq: "C5", dur: 0.1, duty: 0.5, env: [0.001, 0.05, 0.6, 0.03] }),
  at(0.1, tone({ wave: "square", freq: "E5", dur: 0.1, duty: 0.5, env: [0.001, 0.05, 0.6, 0.03] })),
  at(0.2, tone({ wave: "square", freq: "G5", dur: 0.1, duty: 0.5, env: [0.001, 0.05, 0.6, 0.03] })),
  at(0.3, tone({ wave: "square", freq: "C6", dur: 0.4, duty: 0.5, env: [0.001, 0.1, 0.6, 0.2], vibrato: { rate: 6, depth: 0.1, delay: 0.15 } })),
  at(0.3, tone({ wave: "triangle", freq: "C4", dur: 0.4, env: [0.001, 0.1, 0.6, 0.2], vol: 0.6 })))

sfx("menu_move", { vol: 0.15 }, tone({ wave: "square", freq: 880, dur: 0.025, duty: 0.25, env: [0.001, 0.02, 0, 0.01] }))
sfx("menu_accept", { vol: 0.2 }, tone({ wave: "square", freq: 660, to: 990, slide: 0.06, dur: 0.07, duty: 0.25, env: [0.001, 0.04, 0.3, 0.03] }))

// --- The entity (AUDIO-001 §4) ------------------------------------------------------------------

// the Awakening hit that lands with "IT WAKES.": a sub drop, a torn noise and a falling saw
sfx("wake_hit", { vol: 0.85, fx: [drive({ amount: 1.3 }), reverb({ size: 0.9, mix: 0.3 }), limiter()] },
  tone({ wave: "sine", freq: 55, to: 22, dur: 2.2, env: [0.001, 1.5, 0.3, 0.8] }),
  noise({ color: "brown", dur: 1.6, env: [0.001, 1.0, 0.2, 0.6], filter: { type: "lp", from: 600, to: 40 }, vol: 0.6 }),
  tone({ wave: "saw", freq: 110, to: 27.5, dur: 2.0, env: [0.001, 1.2, 0.2, 0.6], vol: 0.3, filter: { type: "lp", cutoff: 900 } }))

// the entity unmade: everything falls into the hole, and one bell rings on alone
sfx("entity_unmade", { vol: 0.85, fx: [reverb({ size: 0.95, damp: 0.3, mix: 0.4 }), limiter()] },
  tone({ wave: "sine", freq: 40, to: 20, dur: 3.0, env: [0.001, 2.0, 0.3, 1.0] }),
  noise({ color: "white", dur: 2.6, env: [0.001, 1.5, 0.2, 1.0], filter: { type: "lp", from: 5000, to: 30 }, vol: 0.5 }),
  at(0.3, tone({ wave: "fm", fm: { ratio: 2.76, index: 3, decay: 1.5 }, freq: "C6", to: "C4", slide: 2.8, dur: 2.8, env: [0.001, 2.0, 0.2, 1.0], vol: 0.35 })))
