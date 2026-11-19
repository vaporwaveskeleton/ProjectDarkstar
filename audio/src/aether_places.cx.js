// DARKSTAR — the golden path's places after the tear, as code (GDD-001 D-14, AUDIO-001 §2.2, §12.19).
// Build:  node .claude/skills/chirp-game-audio/bin/chirp.js build audio/src/aether_places.cx.js --out assets/audio/generated
// Stereo loops for BUS-AMB, played through AudioService.set_ambience (and the PM-01 threat stems
// through set_ambience_threat, locked to the bed's playhead, so they share the bed's 16 s length).
// NARR-001 tear rule: colour, fog and room tone only. Nothing here is a voice, a word or a sting.
// UNAUDITIONED until the owner listens.

const c = (f, cents) => f * Math.pow(2, cents / 1200)

// --- the Ruins of the Ninth Sky (AUDIO-001 §2.2 layer B) ----------------------------------------
// One pitch (D, the room's own air), a stone-and-brass hall, and the slow clock: 48 BPM (§2.2), so
// the loop is 15 s = 12 ticks exactly. Later visits hear the clock; the first visit does not.
const RL = 15
const HALL = [reverb({ size: 0.85, damp: 0.55, mix: 0.45 }), limiter({ ceiling: 0.45 })]

const roomAir = (vol) => [
  noise({ color: "brown", dur: RL, env: [3, 0, 1, 3], filter: { type: "lp", cutoff: 380 }, vol: vol,
    tremolo: { rate: 2 / RL, depth: 0.3 } }),
  noise({ color: "pink", dur: RL, env: [3, 0, 1, 3], filter: { type: "bp", cutoff: 860, q: 0.7 }, vol: vol * 0.25,
    tremolo: { rate: 1 / RL, depth: 0.5 } }),
]
// the anchoring drone: D2 with a 2nd and 3rd harmonic over 300 Hz (laptop rule, §7.1), and one
// voice 6 cents off (T1's crack, §3) beating slowly against it
const drone = (vol) => [
  tone({ wave: "sine", freq: 73.42, dur: RL, env: [3, 0, 1, 3], vol }),
  tone({ wave: "sine", freq: 146.83, dur: RL, env: [3, 0, 1, 3], vol: vol * 0.35 }),
  tone({ wave: "triangle", freq: c(440.0, 6), dur: RL, env: [3, 0, 1, 3], vol: vol * 0.05, tremolo: { rate: 2 / RL, depth: 0.7 } }),
]
// the clock: a brass escapement, tick and tock a hair apart in pitch, quiet and far
const clock = (vol) => Array.from({ length: 12 }, (_, i) => at(i * 1.25,
  noise({ color: "white", dur: 0.006, env: [0.001, 0.01, 0, 0.03], filter: { type: "bp", cutoff: i % 2 ? 2900 : 3300, q: 4 }, vol }),
  tone({ wave: "fm", fm: { ratio: 2.76, index: 1.2, decay: 0.05 }, freq: i % 2 ? 622 : 698, dur: 0.02, env: [0.001, 0.05, 0, 0.12], vol: vol * 0.25 })))

sfx("ruins_hall", { loop: true, dur: RL, vol: 0.5, fx: HALL },
  roomAir(0.3),
  drone(0.08),
  clock(0.1))

// First visit (the cold open after the black): the wreck still settling. No clock (it starts when
// the first loop does), wind through the broken dome, far brass groans as the hulk shifts, glass
// grit falling. The drone is the same pitch, so a later visit is the same room with time running.
const groan = (t, f, pan, vol) => at(t,
  tone({ wave: "saw", freq: f, to: f * 0.86, slide: 2.4, dur: 2.4, env: [0.9, 0.8, 0.5, 1.4], vol, pan,
    vibrato: { rate: 9, depth: 0.25 }, filter: { type: "bp", cutoff: f * 4, q: 3 } }))
const grit = (t, pan) => at(t, [0, 0.11, 0.19, 0.34].map((d, i) => at(d,
  noise({ color: "white", dur: 0.004, env: [0.001, 0.006, 0, 0.04], filter: { type: "bp", cutoff: 4200 + i * 500, q: 3 }, vol: 0.05, pan }))))
sfx("ruins_first_visit", { loop: true, dur: RL, vol: 0.5, fx: HALL },
  roomAir(0.32),
  drone(0.07),
  noise({ color: "pink", dur: RL, env: [3, 0, 1, 3], filter: { type: "bp", cutoff: 520, q: 4 }, vol: 0.14,
    tremolo: { rate: 1 / RL, depth: 0.8 }, pan: -0.4 }),
  noise({ color: "pink", dur: RL, env: [3, 0, 1, 3], filter: { type: "bp", cutoff: 780, q: 5 }, vol: 0.1,
    tremolo: { rate: 2 / RL, depth: 0.8 }, pan: 0.5 }),
  groan(2.2, 92, -0.5, 0.05),
  groan(9.4, 81, 0.6, 0.04),
  grit(5.6, 0.3),
  grit(12.8, -0.6))

// --- PM-01 "First Vigil" threat stems (Pale Marches T1; the bed itself is aether_bed_t1) ----------
// Threat adds layers, never level (AUDIO-001 §1.1, §12.12): AudioService lowers the bed as the stems
// rise, so the sum stays at the BUS-AMB target. 16 s, the bed's length, so they stay locked to it.
const BL = 16
// Stem 1 (unease): the Deep wakes under the Marches. A sub swell per half-loop with its harmonics
// over 300 Hz, and the Glass's low partner bowing a minor second under the T1 Glass (A2 against Bb).
sfx("pm01_threat_1", { loop: true, dur: BL, vol: 0.5, fx: [reverb({ size: 0.9, damp: 0.6, mix: 0.45 }), limiter({ ceiling: 0.45 })] },
  [0, 8].map((t, i) => at(t,
    tone({ wave: "sine", freq: i ? 38.9 : 41.2, dur: 5, env: [3.5, 1, 0.7, 3.5], vol: 0.11 }),
    tone({ wave: "sine", freq: (i ? 38.9 : 41.2) * 2, dur: 5, env: [3.7, 1, 0.6, 3.5], vol: 0.04 }),
    tone({ wave: "triangle", freq: (i ? 38.9 : 41.2) * 8, dur: 5, env: [3.9, 1, 0.5, 3.5], vol: 0.008 }))),
  [3, 11].map((t, i) => at(t,
    tone({ wave: "fm", fm: { ratio: 2.41, index: 0.6 }, freq: 116.54, dur: 4.5, env: [2.4, 1, 0.7, 3], vol: 0.05, pan: i ? 0.5 : -0.5 }),
    tone({ wave: "sine", freq: c(116.54, 9), dur: 4.5, env: [2.8, 1, 0.7, 3], vol: 0.04, pan: i ? -0.5 : 0.5 }))))
// Stem 2 (dread): the Wrong. A near-unison whose beat slows, a pre-echo that never lands, and the
// medium bending past (displacement, never a creature). Detune 9 (the next tier's crack, §3).
sfx("pm01_threat_2", { loop: true, dur: BL, vol: 0.5, fx: [reverb({ size: 0.95, damp: 0.45, mix: 0.5 }), limiter({ ceiling: 0.45 })] },
  tone({ wave: "sine", freq: 207.65, dur: 6, env: [2.5, 1, 0.8, 3], vol: 0.04, pan: -0.3 }),
  tone({ wave: "sine", freq: c(207.65, 9), to: c(207.65, 3), slide: 6, dur: 6, env: [2.5, 1, 0.8, 3], vol: 0.04, pan: 0.3 }),
  at(9, noise({ color: "pink", dur: 2.6, env: [2.5, 0, 1, 0.05], filter: { type: "bp", from: 500, to: 1500, q: 1.3 }, vol: 0.05 })),
  at(9, tone({ wave: "sine", freq: 311.1, dur: 2.6, env: [2.2, 0, 1, 0.05], vol: 0.025 })),
  at(4, noise({ color: "brown", dur: 7, env: [3, 1, 0.8, 3], filter: { type: "lp", from: 140, to: 600 }, vol: 0.25, pan: 0.2 })))
