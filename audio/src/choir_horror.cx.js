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
