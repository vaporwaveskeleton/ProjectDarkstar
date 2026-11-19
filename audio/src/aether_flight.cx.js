// DARKSTAR — the Aether Vigil in flight, as code (GDD-001 D-14, AUDIO-001 §11, §12.18).
// Build (mono: the ship is head-centred, never panned):
//   node .claude/skills/chirp-game-audio/bin/chirp.js build audio/src/aether_flight.cx.js --out assets/audio/generated --mono
// The Aether Vigil is a heavy Victorian brass ship: a two-cylinder steam engine, a boiler, rigging
// that sings in the current, a gas lantern and ballast tanks. Four loops are the runtime layers the
// AudioService flight mixer sweeps every control tick from speed, thrust, turn and brake
// (FlightMix, data/audio/flight_sound.tres); two one-shots fire on edges (hard turn, brake).
// Never near 1.2 kHz (the B06 glass chime stays unique, AUDIO-001 §6.4). Loops are 4 s so a
// pitch_scale sweep never exposes a seam. UNAUDITIONED until the owner listens.

const L = 4   // loop length (s): engine chuffs land on exact divisions

// --- loops -------------------------------------------------------------------------------------

// Engine: two cylinders, 3 chuffs/s at pitch 1.0 (12 per loop), strong-weak accents; a brass
// drone under it (FM ratio 1 = brass) so the shape survives laptops (content 300–900 Hz).
const ACCENT = [1, 0.55, 0.85, 0.5]
sfx("flight_engine", { loop: true, dur: L, vol: 0.55, fx: [reverb({ size: 0.25, damp: 0.6, mix: 0.12 }), limiter({ ceiling: 0.2 })] },
  tone({ wave: "fm", fm: { ratio: 1, index: 1.6 }, freq: 55, dur: L, env: [0.01, 0, 1, 0.01], vol: 0.16,
    tremolo: { rate: 3, depth: 0.35 } }),
  tone({ wave: "triangle", freq: 110, dur: L, env: [0.01, 0, 1, 0.01], vol: 0.05, tremolo: { rate: 3, depth: 0.5 } }),
  Array.from({ length: 12 }, (_, i) => at(i / 3,
    noise({ color: "pink", dur: 0.09, env: [0.012, 0.09, 0, 0.12], filter: { type: "bp", from: 720, to: 380, q: 1.3 },
      vol: 0.5 * ACCENT[i % 4] }),
    noise({ color: "brown", dur: 0.12, env: [0.015, 0.1, 0, 0.1], filter: { type: "lp", cutoff: 260 }, vol: 0.35 * ACCENT[i % 4] }))))

// Boiler: the firebox roar and steam breathing in the pipes. Thrust opens it.
sfx("flight_boiler", { loop: true, dur: L, vol: 0.5, fx: [limiter({ ceiling: 0.18 })] },
  noise({ color: "brown", dur: L, env: [0.01, 0, 1, 0.01], filter: { type: "lp", cutoff: 220 }, vol: 0.5,
    tremolo: { rate: 0.5, depth: 0.3 } }),
  noise({ color: "pink", dur: L, env: [0.01, 0, 1, 0.01], filter: { type: "bp", cutoff: 2600, q: 0.9 }, vol: 0.07,
    tremolo: { rate: 1.5, depth: 0.5 } }),
  tone({ wave: "sine", freq: 41.2, dur: L, env: [0.01, 0, 1, 0.01], vol: 0.12 }),
  tone({ wave: "sine", freq: 329.6, dur: L, env: [0.01, 0, 1, 0.01], vol: 0.008, tremolo: { rate: 0.75, depth: 0.6 } }))

// Rigging: the current singing through stays and shrouds while the Vigil drifts. Two narrow bands
// a fifth apart (640 / 960 Hz, clear of 1.2 kHz), each swelling once per loop, out of phase.
sfx("flight_rigging", { loop: true, dur: L, vol: 1.0, fx: [reverb({ size: 0.6, damp: 0.5, mix: 0.3 }), limiter({ ceiling: 0.18 })] },
  noise({ color: "pink", dur: L, env: [0.01, 0, 1, 0.01], filter: { type: "bp", cutoff: 640, q: 9 }, vol: 1.8,
    tremolo: { rate: 0.25, depth: 0.7 } }),
  noise({ color: "pink", dur: L, env: [0.01, 0, 1, 0.01], filter: { type: "bp", cutoff: 960, q: 11 }, vol: 1.4,
    tremolo: { rate: 0.5, depth: 0.6 }, pan: 0 }),
  noise({ color: "pink", dur: L, env: [0.01, 0, 1, 0.01], filter: { type: "bp", cutoff: 420, q: 2 }, vol: 0.3 }))

// Lantern: the gas mantle's hiss with a slow flicker. Always on while the ship lives (it is the
// ship's room tone, the sound the dark takes away first).
sfx("flight_lantern", { loop: true, dur: L, vol: 0.5, fx: [limiter({ ceiling: 0.1 })] },
  noise({ color: "white", dur: L, env: [0.01, 0, 1, 0.01], filter: { type: "bp", cutoff: 5200, q: 0.7 }, vol: 0.09,
    tremolo: { rate: 7, depth: 0.12 } }),
  noise({ color: "pink", dur: L, env: [0.01, 0, 1, 0.01], filter: { type: "bp", cutoff: 2200, q: 1.5 }, vol: 0.05,
    tremolo: { rate: 0.5, depth: 0.4 } }),
  [0.37, 1.61, 2.2, 3.43].map((t, i) => at(t,
    noise({ color: "white", dur: 0.006, env: [0.001, 0.006, 0, 0.01], filter: { type: "hp", cutoff: 3000 }, vol: 0.12 + 0.03 * (i % 2) }))))

// --- one-shots ----------------------------------------------------------------------------------

// Rigging creak on a hard turn: timber and brass taking the load, a rope groan sliding down.
sfx("flight_creak", { vol: 1.0, fx: [reverb({ size: 0.35, damp: 0.6, mix: 0.18 }), limiter({ ceiling: 0.22 })] },
  tone({ wave: "saw", freq: 168, to: 121, slide: 0.6, dur: 0.6, env: [0.06, 0.2, 0.6, 0.18], vol: 0.6,
    vibrato: { rate: 23, depth: 0.5 }, filter: { type: "bp", cutoff: 640, q: 3 } }),
  at(0.12, tone({ wave: "saw", freq: 241, to: 205, slide: 0.35, dur: 0.35, env: [0.04, 0.15, 0.4, 0.12], vol: 0.35,
    vibrato: { rate: 31, depth: 0.7 }, filter: { type: "bp", cutoff: 820, q: 4 } })),
  noise({ color: "pink", dur: 0.5, env: [0.08, 0.2, 0.3, 0.2], filter: { type: "bp", cutoff: 900, q: 2 }, vol: 0.2 }))

// Ballast on the brake: the tanks shift, water slams fore and settles, a chain takes up and rings.
// Soft-edged (attack >= 10 ms); player-caused, so it may be heard as a weight, never a hit.
sfx("flight_ballast", { vol: 0.6, fx: [reverb({ size: 0.5, damp: 0.5, mix: 0.2 }), limiter({ ceiling: 0.25 })] },
  tone({ wave: "sine", freq: 58, to: 39, slide: 0.7, dur: 0.5, env: [0.03, 0.4, 0.2, 0.5], vol: 0.6 }),
  tone({ wave: "triangle", freq: 174, to: 117, slide: 0.7, dur: 0.5, env: [0.03, 0.4, 0.2, 0.5], vol: 0.08 }),
  noise({ color: "brown", dur: 1.1, env: [0.04, 0.3, 0.5, 0.5], filter: { type: "lp", from: 900, to: 160 }, vol: 0.5,
    tremolo: { rate: 5.5, depth: 0.6 } }),
  at(0.18, tone({ wave: "fm", fm: { ratio: 3.51, index: 1.8, decay: 0.3 }, freq: 233, dur: 0.05, env: [0.012, 0.2, 0, 0.6], vol: 0.07 })),
  at(0.31, tone({ wave: "fm", fm: { ratio: 3.51, index: 1.5, decay: 0.3 }, freq: 311, dur: 0.05, env: [0.012, 0.2, 0, 0.5], vol: 0.04 })))

// The first Unmaking, beat 6 (AetherArrival): the last lamp starves. Dry: the first sound in the
// Aether with no air around it, because the medium has stopped (AUDIO-001 §12.12). The hiss narrows
// and falls, the mantle's crackle thins out, the glass chimney ticks as it cools, and everything
// ends in a 0.3 s fade (G04's room-tone fade) at the black: the protected silence that follows is
// the beat. No onset (0.4 s attack), no hit, peak far under the limiter (§1.1, §1.4).
const CRACKLE = [0.2, 0.45, 0.62, 0.9, 1.15, 1.32, 1.7, 2.05, 2.5, 3.1, 3.6, 4.4, 5.1]
sfx("unmaking_lamp_out", { dur: 6, vol: 0.85, fx: [limiter({ ceiling: 0.2 })] },
  noise({ color: "white", dur: 5.7, env: [0.4, 0, 1, 0.3], filter: { type: "bp", from: 5200, to: 700, q: 1.1 }, vol: 0.16,
    tremolo: { rate: 6, depth: 0.25 } }),
  noise({ color: "pink", dur: 5.7, env: [0.6, 3.5, 0.3, 0.3], filter: { type: "lp", from: 1800, to: 200 }, vol: 0.12 }),
  CRACKLE.map((t, i) => at(t,
    noise({ color: "white", dur: 0.008, env: [0.001, 0.008, 0, 0.012], filter: { type: "bp", cutoff: 3200 - i * 150, q: 2 },
      vol: 0.2 * (1 - t / 6) }))),
  at(3.9, tone({ wave: "triangle", freq: 2794, dur: 0.01, env: [0.002, 0.03, 0, 0.12], vol: 0.025 })),
  at(5.3, tone({ wave: "triangle", freq: 2489, dur: 0.01, env: [0.002, 0.03, 0, 0.1], vol: 0.015 })))
