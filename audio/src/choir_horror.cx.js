// DARKSTAR — Choir fire families and the Passing (Cosmic horror design handoffs, AUDIO-001 §12.14).
// Build:  node .claude/skills/chirp-game-audio/bin/chirp.js build audio/src/choir_horror.cx.js --out assets/audio/generated
// Choir cues use Choir instrument families only (saw voices through vowel band-passes, censer
// metal); never a player-feedback instrument (AUDIO-001 §3 palette rule). No stings (§1.1); every
// cue here that is not player-caused ramps in over at least 0.35 s or stays under the bed (§1.4).
// The entity has no sound (Cosmic horror N9, proposed). UNAUDITIONED.

include("cabinet.cx.js")

const voice = (f, to, t, dur, vowel, vol, pan = 0) => at(t,
  tone({ wave: "saw", freq: f, ...(to ? { to } : {}), dur, env: [0.04, 0.1, 0.7, 0.12], filter: { type: "bp", cutoff: vowel, q: 3 }, vol, pan }),
  tone({ wave: "saw", freq: f * 1.003, ...(to ? { to: to * 1.003 } : {}), dur, env: [0.05, 0.1, 0.6, 0.12], filter: { type: "bp", cutoff: vowel * 1.45, q: 4 }, vol: vol * 0.5, pan: -pan }))

// --- Choir fire families (NARR-001 §2.1 ranks) --------------------------------------------------

// The Comforters (Deacon of Lies): a phantom's shot is the real Acolyte shot made hollow (body
// removed, a short comb ring). It must sound like something, never exactly like a real shot.
sfx("phantom_fire", { vol: 0.6, fx: [filter({ type: "hp", cutoff: 700 }), delay({ time: 0.006, feedback: 0.55, mix: 0.5 })] },
  play("acolyte_fire", { vol: 0.9 }))

// F03 The Confessors (Listener): "heard you", not a shot. A slow inhale turning toward the sound,
// no teeth; attack 0.4 s so it menaces without a jump.
sfx("listener_heard", { vol: 1.6, fx: [reverb({ size: 0.5, mix: 0.25 })] },
  noise({ color: "pink", dur: 0.6, env: [0.4, 0.1, 0.6, 0.2], filter: { type: "bp", from: 500, to: 1400, q: 2 } }),
  voice(196, 233, 0.2, 0.4, 700, 0.12))

// F13 The Mothers (Choir Matron) birth Grubs (SYS-001 §3: spawns 3 Grubs every 9 s; the Matron
// never fires). A low two-voice Choir swell opening, then three soft wet births. No sting: 0.35 s rise.
sfx("matron_birth", { vol: 1.3, fx: [reverb({ size: 0.6, mix: 0.25 })] },
  at(0, tone({ wave: "saw", freq: 147, to: 165, slide: 0.5, dur: 0.6, env: [0.35, 0.1, 0.7, 0.3], filter: { type: "bp", cutoff: 600, q: 3 }, vol: 0.3 })),
  at(0, tone({ wave: "saw", freq: 220, to: 247, slide: 0.5, dur: 0.6, env: [0.4, 0.1, 0.6, 0.3], filter: { type: "bp", cutoff: 850, q: 4 }, vol: 0.2 })),
  [0.45, 0.6, 0.78].map((t2) => at(t2, tone({ wave: "sine", freq: 420, to: 260, slide: 0.06, dur: 0.06, env: [0.005, 0.05, 0, 0.05], vol: 0.18 }),
    noise({ color: "pink", dur: 0.05, env: [0.005, 0.04, 0, 0.03], filter: { type: "bp", cutoff: 700, q: 2 }, vol: 0.12 }))))

// F07 Matron silenced: one beat of raggedness, then quiet.
sfx("matron_silenced", { vol: 1.6, fx: [reverb({ size: 0.7, mix: 0.3 })] },
  at(0, tone({ wave: "saw", freq: 147, dur: 0.5, env: [0.05, 0.1, 0.7, 0.05], filter: { type: "bp", cutoff: 600, q: 3 }, tremolo: { rate: 13, depth: 0.9 }, vol: 0.4 })),
  at(0, tone({ wave: "saw", freq: 156, dur: 0.45, env: [0.05, 0.1, 0.6, 0.05], filter: { type: "bp", cutoff: 850, q: 4 }, tremolo: { rate: 11, depth: 0.9 }, vol: 0.25 })))

// B07 The Tithe-Takers (Grave-Tide Deceiver) steal a Charge: the glass chime pulled upward out of
// tune (AUDIO-001 §6.2 B07). Slower attack than B06 so the two never read as the same event.
sfx("deceiver_steal", { vol: 0.3 },
  tone({ wave: "sine", freq: 1200, to: 1420, slide: 0.5, dur: 0.5, env: [0.03, 0.2, 0.4, 0.3], vibrato: { rate: 5, depth: 0.3, delay: 0.1 } }),
  tone({ wave: "saw", freq: 300, to: 360, slide: 0.5, dur: 0.4, env: [0.08, 0.1, 0.5, 0.2], filter: { type: "bp", cutoff: 900, q: 3 }, vol: 0.2 }))

// --- The Passing (proposed; Cosmic horror design §2.1, §7.2) -------------------------------------

// The biome's Presence leaving in a hurry: a vast sub-and-air body receding (pitch sinking, the
// top closing). No onset transient: a 1 s rise, then a long fall (zero startle).
sfx("presence_flee", { vol: 0.08, fx: [reverb({ size: 0.95, damp: 0.6, mix: 0.5 }), limiter({ ceiling: 0.5 })] },
  tone({ wave: "sine", freq: 55, to: 36, slide: 6, dur: 6, env: [1, 0.5, 0.8, 1.5], vol: 0.5 }),
  tone({ wave: "triangle", freq: 330, to: 196, slide: 6, dur: 6, env: [1.2, 0.5, 0.6, 1.5], vol: 0.06 }),
  noise({ color: "brown", dur: 6, env: [1, 0.5, 0.8, 1.5], filter: { type: "lp", from: 1600, to: 120 }, vol: 0.35 }))

// The Comforters' murmur at the Passing's leading edge: wordless, three short phrases of three
// syllables and a falling fourth ("Let it pass" ×3, "over"); the words are subtitles only.
const syl = (t, f, v) => voice(f, null, t, 0.16, v, 0.09)
sfx("comforters_murmur", { vol: 3.0, fx: [reverb({ size: 0.8, damp: 0.5, mix: 0.45 }), chorus({ rate: 0.3, mix: 0.4 })] },
  [0, 1.1, 2.2].map((p) => [syl(p, 196, 700), syl(p + 0.22, 196, 1000), syl(p + 0.44, 175, 650)]),
  voice(175, 147, 3.3, 0.6, 600, 0.08))

// --- Lie-tell ticks (Cosmic horror L11, PM-approved 2026-11-18; WARP-001 §4.2 tell families) --------
// One short cue per tell family at a lie's onset: information, never an alarm. Each ≤ 0.25 s ✱,
// quiet, no low end, distinct by timbre so the family reads by ear. Visual twin: the tell's stroke.

// Chalk: a dry stroke on slate.
sfx("lie_tell_chalk", { vol: 0.75 },
  noise({ color: "white", dur: 0.09, env: [0.005, 0.06, 0.2, 0.03], filter: { type: "bp", from: 2400, to: 3600, q: 2 }, tremolo: { rate: 60, depth: 0.7 } }))

// Glyph: a small glass mark turning (an inharmonic glint, rising a fourth).
sfx("lie_tell_glyph", { vol: 0.22 },
  tone({ wave: "fm", fm: { ratio: 2.41, index: 1.2, decay: 0.08 }, freq: 880, to: 1175, slide: 0.08, dur: 0.08, env: [0.004, 0.06, 0.2, 0.08] }))

// Mirror: a tick and its reflection, the echo a little out of tune and on the other side.
sfx("lie_tell_mirror", { vol: 0.3 },
  tone({ wave: "triangle", freq: 1320, dur: 0.03, env: [0.002, 0.025, 0, 0.03], pan: -0.4 }),
  at(0.09, tone({ wave: "triangle", freq: 1320 * Math.pow(2, 35 / 1200), dur: 0.03, env: [0.002, 0.025, 0, 0.04], vol: 0.8, pan: 0.4 })))

// Smear: a soft tick dragged downward.
sfx("lie_tell_smear", { vol: 0.2 },
  tone({ wave: "triangle", freq: 990, to: 620, slide: 0.16, curve: "lin", dur: 0.16, env: [0.004, 0.05, 0.5, 0.06], filter: { type: "lp", from: 4000, to: 1200 } }))

// Absence: a short soft tone that stops too early, then a breath of nothing.
sfx("lie_tell_absence", { vol: 0.1 },
  tone({ wave: "sine", freq: 740, dur: 0.07, env: [0.01, 0, 1, 0.004] }),
  tone({ wave: "triangle", freq: 1480, dur: 0.07, env: [0.01, 0, 1, 0.004], vol: 0.25 }))

// --- Choir tells and phantoms (AUDIO-001 §6.2 F01, F04, F05; PM-directed 2026-11-18) -----------------

// F01 Acolyte tell: the censer chain arriving late. Four small metal clinks spread over 0.25 s (the
// turret lag 🔒 in SYS-001 §3 is the caller's timing; this cue only carries the sound).
sfx("acolyte_tell", { vol: 0.9 },
  [0, 0.06, 0.13, 0.22].map((t, i) => at(t,
    tone({ wave: "fm", fm: { ratio: 3.7, index: 2.2, decay: 0.04 }, freq: [1900, 2150, 1780, 2050][i], dur: 0.015, env: [0.001, 0.02, 0, 0.05], vol: 0.25 - i * 0.03, pan: -0.2 + i * 0.12 }))))

// F04 Deacon phantom materialises: the litany's rhythm in three feet, the middle foot one syllable
// short (§5.2). Wordless Choir voices, quiet, ramping in (no startle).
const pv = (t, f, vowel, vol) => at(t,
  tone({ wave: "saw", freq: f, dur: 0.15, env: [0.05, 0.05, 0.6, 0.12], filter: { type: "bp", cutoff: vowel, q: 3 }, vol }),
  tone({ wave: "saw", freq: f * 1.004, dur: 0.15, env: [0.06, 0.05, 0.5, 0.12], filter: { type: "bp", cutoff: vowel * 1.45, q: 4 }, vol: vol * 0.5 }))
sfx("phantom_appear", { vol: 4.5, fx: [reverb({ size: 0.8, mix: 0.45 })] },
  pv(0, 220, 700, 0.06), pv(0.2, 220, 1000, 0.07), pv(0.4, 196, 650, 0.07),
  pv(0.75, 175, 700, 0.07), pv(0.95, 175, 1000, 0.07),
  pv(1.5, 147, 650, 0.06), pv(1.7, 147, 700, 0.06), pv(1.9, 147, 1000, 0.05))

// F05 Deacon phantom dispelled: the missing syllable arrives late, then nothing (reverb cut dry).
sfx("phantom_dispel", { vol: 3.5 },
  pv(0, 175, 650, 0.08))

// --- The Six: Heralds of the Failed Star (SYS-001 §5.2; elite variants) ---------------------------

// A Herald arrives: a full Choir chord with a cracked bell inside it (the failed star). Not
// player-caused, so it rises over 0.5 s (§1.4); menace by register and layer, never by level.
const heraldChord = (root) => [0, 3, 7, 10].map((s, i) =>
  tone({ wave: "saw", freq: root * Math.pow(2, s / 12), dur: 1.4, env: [0.5, 0.3, 0.7, 0.6], filter: { type: "bp", cutoff: [600, 850, 1100, 1400][i], q: 3 }, vol: 0.09, pan: [-0.4, 0.3, -0.1, 0.5][i] }))
sfx("herald_arrive", { vol: 1.3, fx: [reverb({ size: 0.9, damp: 0.5, mix: 0.4 }), limiter({ ceiling: 0.6 })] },
  heraldChord(98),
  at(0.55, tone({ wave: "fm", fm: { ratio: 2.76, index: 3, decay: 0.6 }, freq: 233, to: 220, slide: 1, dur: 0.1, env: [0.002, 0.4, 0.2, 1.2], vol: 0.12 })))

// The Ninth Reckoning (E10 only, every counter at 10%): the same arrival a fourth lower, longer.
sfx("herald_reckoning", { vol: 1.0, fx: [reverb({ size: 0.95, damp: 0.5, mix: 0.45 }), limiter({ ceiling: 0.6 })] },
  heraldChord(73.4),
  at(0.6, tone({ wave: "fm", fm: { ratio: 2.76, index: 3, decay: 0.8 }, freq: 175, to: 160, slide: 1.4, dur: 0.1, env: [0.002, 0.5, 0.2, 1.6], vol: 0.12 })))

// Herald of the Ninth Sky dims the lantern (one cue per stack): a warm glass tone closing down.
sfx("herald_dim", { vol: 0.18 },
  tone({ wave: "triangle", freq: 660, to: 494, slide: 0.6, dur: 0.6, env: [0.06, 0.2, 0.5, 0.25], filter: { type: "lp", from: 5000, to: 600 } }),
  tone({ wave: "sine", freq: 330, to: 247, slide: 0.6, dur: 0.6, env: [0.08, 0.2, 0.5, 0.25], vol: 0.5 }))

// Herald of the Salted Chord taxes the Ward: a salted cluster (a minor second) laid over it.
sfx("herald_salt", { vol: 1.4, fx: [reverb({ size: 0.5, mix: 0.2 })] },
  tone({ wave: "saw", freq: 311, dur: 0.5, env: [0.08, 0.1, 0.6, 0.2], filter: { type: "bp", cutoff: 900, q: 3 }, vol: 0.25 }),
  tone({ wave: "saw", freq: 330, dur: 0.5, env: [0.09, 0.1, 0.6, 0.2], filter: { type: "bp", cutoff: 1300, q: 3 }, vol: 0.2 }),
  noise({ color: "white", dur: 0.4, env: [0.08, 0.1, 0.3, 0.1], filter: { type: "hp", cutoff: 5000 }, vol: 0.08 }))

// Herald of the Long Vigil intercepts a Surgelight boost: the C04 rising note dragged back down.
sfx("herald_intercept", { vol: 0.18, fx: [crush({ bits: 10 })] },
  tone({ wave: "saw", freq: 1100, to: 520, slide: 0.3, dur: 0.3, env: [0.02, 0.1, 0.5, 0.1], filter: { type: "lp", from: 5000, to: 1200 } }),
  tone({ wave: "saw", freq: 1104, to: 515, slide: 0.3, dur: 0.3, env: [0.03, 0.1, 0.4, 0.1], vol: 0.6, filter: { type: "lp", from: 5000, to: 1200 } }))

// B08 Charge intercepted (Herald of the Broken Censer, and any intercept): a hard bell stop, the
// tail choked. Unlike B06: no clean 1.2 kHz, no Choir half-note.
sfx("charge_intercepted", { vol: 0.22 },
  tone({ wave: "fm", fm: { ratio: 3.5, index: 3, decay: 0.05 }, freq: 784, dur: 0.06, env: [0.001, 0.05, 0.3, 0.02] }),
  noise({ color: "pink", dur: 0.04, env: [0.001, 0.03, 0, 0.02], filter: { type: "bp", cutoff: 1500, q: 1.5 }, vol: 0.4 }))

// Herald of the Quiet Pew lays its silence: a breath drawn in, then the room goes still. The chant
// mute itself is the caller's (SYS-001 §5.2); §5.5's visual chant indicator keeps it fair (L3).
sfx("herald_hush", { vol: 1.5, fx: [reverb({ size: 0.7, mix: 0.3 })] },
  noise({ color: "pink", dur: 0.9, env: [0.85, 0, 1, 0.03], filter: { type: "bp", from: 300, to: 1200, q: 1.2 }, vol: 0.15 }),
  tone({ wave: "sine", freq: 196, dur: 0.9, env: [0.8, 0, 1, 0.03], vol: 0.05 }))
