// DARKSTAR — the Aether (post-Pretence) ambience, as code (GDD-001 D-14, AUDIO-001 §12.12).
// Build:  node .claude/skills/chirp-game-audio/bin/chirp.js build audio/src/aether_beds.cx.js --out assets/audio/generated
// Direction: the Aether is a wet medium you can hear; the entity is the only dry thing; horror is
// subtraction, never a sting (AUDIO-001 §1.1, §1.4). Beds are stereo 16 s loops for BUS-AMB.
// Strata: Medium (fog), Glass (crystal spheres), Life (motes), Deep (sub swells), Wrong (detune).
// Per-tier detune comes from AUDIO-001 §3 (T1 6, T2 9, T3 14 cents ✱). UNAUDITIONED.

const LOOP = 16
const c = (f, cents) => f * Math.pow(2, cents / 1200)
// glass partials (A, Pale Marches 12-TET): never fast, never pure, never near the 1.2 kHz B06 chime
const GLASS = [110, 164.81, 220, 277.18]

// --- strata ----------------------------------------------------------------------------------

// Medium: slow pink-noise "tide" (tremolo period 8 s, two per loop, so the wrap is seamless)
const medium = (cut, vol) =>
  noise({ color: "pink", dur: LOOP, env: [3, 0, 1, 3], filter: { type: "bp", cutoff: cut, q: 0.6 },
    tremolo: { rate: 0.125, depth: 0.45 }, vol })

// Glass: each partial is a bowed, slightly inharmonic FM voice; the detuned twin beats slowly
const glass = (detune, vol, starts) => starts.map((t, i) => {
  const f = GLASS[i % GLASS.length]
  const pan = [-0.5, 0.4, -0.2, 0.6][i % 4]
  return at(t,
    tone({ wave: "fm", fm: { ratio: 2.41, index: 0.5 }, freq: f, dur: 5, env: [2.2, 1, 0.7, 3.5], vol, pan }),
    tone({ wave: "sine", freq: c(f, detune), dur: 5, env: [2.6, 1, 0.7, 3.5], vol: vol * 0.8, pan: -pan }))
})

// Life: sparse soft triangle glints, quiet, irregular, deterministic times
const life = (times, vol) => times.map((t, i) => at(t,
  tone({ wave: "triangle", freq: [1046.5, 1318.5, 880, 1568][i % 4], to: [990, 1250, 840, 1480][i % 4],
    slide: 0.08, dur: 0.03, env: [0.006, 0.03, 0, 0.12], vol, pan: ((i * 37) % 13) / 6.5 - 1 })))

// Deep: a sub swell with harmonics above 300 Hz so laptops still hear its shape (AUDIO-001 §7.1)
const deep = (t, f, vol) => at(t,
  tone({ wave: "sine", freq: f, dur: 4, env: [3, 1, 0.7, 4], vol }),
  tone({ wave: "sine", freq: f * 2, dur: 4, env: [3.2, 1, 0.6, 4], vol: vol * 0.4 }),
  tone({ wave: "triangle", freq: f * 8, dur: 4, env: [3.4, 1, 0.5, 4], vol: vol * 0.06 }))

const AIR = [reverb({ size: 0.95, damp: 0.5, mix: 0.55 }), chorus({ rate: 0.15, depth: 0.006, mix: 0.4 }), limiter({ ceiling: 0.5 })]

// --- beds --------------------------------------------------------------------------------------

// T1 Frayed: wonder with a hairline crack. Medium + Glass + Life, detune 6 cents.
sfx("aether_bed_t1", { loop: true, dur: LOOP, vol: 0.5, fx: AIR },
  medium(700, 0.25),
  glass(6, 0.07, [0, 4, 8, 12]),
  life([1.3, 3.9, 6.2, 9.7, 13.1], 0.03))

// T2 Bleeding: the medium gets heavy and close (wet cloth, the Shroud), life swarms. Detune 9.
sfx("aether_bed_t2", { loop: true, dur: LOOP, vol: 0.5, fx: AIR },
  medium(520, 0.25),
  noise({ color: "brown", dur: LOOP, env: [3, 0, 1, 3], filter: { type: "bp", cutoff: 340, q: 1.1 },
    tremolo: { rate: 0.5, depth: 0.6 }, vol: 0.18 }),
  glass(9, 0.06, [0, 5, 10]),
  life([0.7, 1.9, 2.4, 4.6, 5.1, 7.8, 8.3, 10.2, 11.9, 12.4, 14.7], 0.03))

// T3 Unbound: vast and vertical. + Deep swells, + a pre-echo that never lands. Detune 14.
sfx("aether_bed_t3", { loop: true, dur: LOOP, vol: 0.5, fx: AIR },
  medium(420, 0.22),
  glass(14, 0.055, [2, 9]),
  deep(0.5, 41.2, 0.05),
  deep(8.5, 38.9, 0.045),
  at(5, noise({ color: "pink", dur: 2.4, env: [2.3, 0, 1, 0.05], filter: { type: "bp", from: 900, to: 1600, q: 1.2 }, vol: 0.06 })),
  life([3.3, 11.6], 0.02))

// --- one-shots (BUS-AMB, no transient) ----------------------------------------------------------
// A Presence displacing the medium: a vast thing moving in the far fog (never the entity, which has no
// sound of its own). A sub swell cresting at ~5 s with no onset; never a hit (§1.1), ramp ≥ 0.35 s (§1.4).
// onset, the noise above it draining downward. Never a hit (§1.1); ramp far over 0.35 s (§1.4).
sfx("aether_swell", { vol: 0.12, fx: [reverb({ size: 0.8, damp: 0.7, mix: 0.3 }), limiter({ ceiling: 0.5 })] },
  tone({ wave: "sine", freq: 36.7, dur: 5.5, env: [5, 0, 1, 2.5], vol: 0.45 }),
  tone({ wave: "sine", freq: 73.4, dur: 5.5, env: [5, 0, 1, 2.5], vol: 0.18 }),
  tone({ wave: "triangle", freq: 330.3, dur: 5.5, env: [5, 0, 1, 2.5], vol: 0.025 }),
  noise({ color: "brown", dur: 5.5, env: [4, 0, 1, 2.5], filter: { type: "lp", from: 900, to: 90 }, vol: 0.2 }))

// Wrongness: a reverse swell into a near-unison (one voice +11 cents) that stops before it lands.
sfx("aether_wrong", { vol: 0.5, fx: [reverb({ size: 0.9, damp: 0.4, mix: 0.45 }), limiter({ ceiling: 0.5 })] },
  noise({ color: "pink", dur: 2.2, env: [2.1, 0, 1, 0.06], filter: { type: "bp", from: 400, to: 1400, q: 1.4 }, vol: 0.12 }),
  tone({ wave: "sine", freq: 311.1, dur: 2.2, env: [1.8, 0, 1, 0.06], vol: 0.06 }),
  tone({ wave: "sine", freq: c(311.1, 11), dur: 2.2, env: [1.8, 0, 1, 0.06], vol: 0.06, pan: 0.3 }))

// --- T4 and T5 (owner-approved follow-up, 2026-11-18; AUDIO-001 §12.12) ------------------------

// T4 Inverted: everything familiar faces the wrong way. Life plays backwards (slow swell, cut
// short); the register swaps: the Glass moves low, the Deep moves up into the low-mids. Detune 19.
const lifeBackwards = (times, vol) => times.map((t, i) => at(t,
  tone({ wave: "triangle", freq: [990, 1250, 840][i % 3], to: [1046.5, 1318.5, 880][i % 3], slide: 0.4,
    dur: 0.45, env: [0.42, 0, 1, 0.02], vol, pan: 1 - ((i * 37) % 13) / 6.5 })))
const glassLow = (detune, vol, starts) => starts.map((t, i) => {
  const f = GLASS[i % GLASS.length] / 2
  const pan = [0.5, -0.4, 0.2, -0.6][i % 4]
  return at(t,
    tone({ wave: "fm", fm: { ratio: 2.41, index: 0.7 }, freq: f, dur: 5, env: [2.2, 1, 0.7, 3.5], vol, pan }),
    tone({ wave: "sine", freq: c(f, detune), dur: 5, env: [2.6, 1, 0.7, 3.5], vol: vol * 0.8, pan: -pan }))
})
sfx("aether_bed_t4", { loop: true, dur: LOOP, vol: 0.4, fx: AIR },
  medium(380, 0.2),
  glassLow(19, 0.07, [1, 6, 11]),
  deep(4, 164.8, 0.035),
  deep(12, 155.6, 0.03),
  lifeBackwards([2.2, 5.7, 9.1, 13.6], 0.035))

// T5 Unmaking: not louder, only emptier. A thin medium and one detuned glass pair (22 cents) that
// fades out early in the loop; the rest is near-silence. No life (it has fled), no Deep.
sfx("aether_bed_t5", { loop: true, dur: LOOP, vol: 0.5, fx: [reverb({ size: 0.95, damp: 0.6, mix: 0.4 }), limiter({ ceiling: 0.5 })] },
  noise({ color: "pink", dur: LOOP, env: [4, 0, 1, 4], filter: { type: "bp", cutoff: 300, q: 0.5 },
    tremolo: { rate: 0.0625, depth: 0.6 }, vol: 0.14 }),
  at(1, tone({ wave: "sine", freq: 220, dur: 4, env: [2.5, 1, 0.5, 4], vol: 0.05, pan: -0.3 }),
    tone({ wave: "sine", freq: c(220, 22), dur: 4, env: [2.8, 1, 0.5, 4], vol: 0.05, pan: 0.3 })))
