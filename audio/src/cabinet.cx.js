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

// The chant bed (AUDIO-001 §5.1, Q-T85): the litany is written in nine syllables and SUNG IN EIGHT,
// always one short (NARR-001 §2.1). Three feet of three over an 8 s loop: foot 1 on the drone's fifth,
// foot 2 on its third, foot 3 on the unison, and the ninth slot left empty (only ending 3 sings it).
// Detuned saw "voices" through vowel band-passes over a quiet D drone. Seamless loop; AudioService
// sets its level from distance and the build. UNAUDITIONED (re-rendered 2026-11-18).
const SLOT = 8 / 9
const FOOT = [[220, 220, 220], [174.61, 174.61, 174.61], [146.83, 146.83, null]]   // A3, F3, D3
const VOWEL = [700, 1100, 900, 650, 1000, 800, 700, 1100, 0]
const syllable = (n, i) => n && at(i * SLOT,
  tone({ wave: "saw", freq: n, dur: SLOT * 0.8, env: [0.12, 0.2, 0.7, 0.3], vol: 0.2, vibrato: { rate: 5, depth: 0.08, delay: 0.2 }, filter: { type: "bp", cutoff: VOWEL[i], q: 3 } }),
  tone({ wave: "saw", freq: n * 1.0058, dur: SLOT * 0.8, env: [0.15, 0.2, 0.6, 0.3], vol: 0.12, pan: 0.3, filter: { type: "bp", cutoff: VOWEL[i] * 1.45, q: 4 } }),
  tone({ wave: "saw", freq: n * 0.9954, dur: SLOT * 0.8, env: [0.18, 0.2, 0.6, 0.3], vol: 0.12, pan: -0.3, filter: { type: "bp", cutoff: VOWEL[i] * 0.8, q: 3 } }))
sfx("chant", { dur: 8, loop: true, vol: 0.55, fx: [reverb({ size: 0.8, damp: 0.5, mix: 0.35 }), limiter()] },
  FOOT.flat().map(syllable),
  tone({ wave: "triangle", freq: "D2", dur: 8, env: [0.8, 0, 1, 0.5], vol: 0.25 }),
  tone({ wave: "saw", freq: "D3", dur: 8, env: [0.5, 0, 1, 0.5], vol: 0.06, filter: { type: "bp", cutoff: 700, q: 2 } }),
  noise({ color: "pink", dur: 8, env: [0.5, 0, 1, 0.5], vol: 0.04, filter: { type: "bp", cutoff: 2500, q: 1 }, tremolo: { rate: 0.375, depth: 0.5 } }))
