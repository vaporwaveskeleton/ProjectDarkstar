// DARKSTAR — the haunted Cabinet (W0-12 Hauntings, the cursed turn; AUDIO-001 §12.20; TECH-001 Q-T264–Q-T266).
// Build:  node .claude/skills/chirp-game-audio/bin/chirp.js build audio/src/cabinet_haunt.cx.js --out assets/audio/generated
// PM under owner direction, 2026-11-19 overnight push. UNAUDITIONED. Generated only (D-14): no sample().
// The Cabinet's own furniture sounds, slightly wrong: a mains hum that can breathe, a coin that comes back,
// a tune from a machine that has no tune, and the minimal stage loop a0_4 / a0_5 run (Q-T188), which W0-11
// Wear detunes and the Decay sags. No stings, no risers, no hits (AUDIO-001 §1.4; D-15 zero startle).

// --- The cabinet hum (AUDIO-001 §2.1 "extra" row) --------------------------------------------------
// 50 Hz mains through an old transformer: the fundamental, its 2nd and 3rd harmonics, and a faint
// buzzing band where the laminations rattle. 4 s, whole cycles: loops clean. CabinetHum plays it quietly
// under attract and the shift; a Haunting swells it into one breath.
sfx("cabinet_hum", { dur: 4, loop: true, vol: 0.5, fx: [limiter()] },
  tone({ wave: "sine", freq: 50, dur: 4, env: [0, 0, 1, 0], vol: 0.55 }),
  tone({ wave: "sine", freq: 100, dur: 4, env: [0, 0, 1, 0], vol: 0.3 }),
  tone({ wave: "sine", freq: 150, dur: 4, env: [0, 0, 1, 0], vol: 0.14 }),
  noise({ color: "pink", dur: 4, env: [0, 0, 1, 0], filter: { type: "bp", cutoff: 120, q: 6 }, tremolo: { rate: 0.5, depth: 0.3 }, vol: 0.12 }))

// --- The breathing transformer (W0-12 breath; the Decay's D2–D3 breaths) ---------------------------
// One breath, 4.5 s: the hum's buzz opens up as if drawing air (a 50 Hz saw through a low-pass rising),
// holds, and lets it out (the filter falling); under it an octave below, felt more than heard, and a
// little air. No onset: every voice fades in over ≥ 1 s.
sfx("haunt_breath", { vol: 0.38, fx: [reverb({ size: 0.5, damp: 0.6, mix: 0.15 }), limiter()] },
  tone({ wave: "saw", freq: 50, dur: 2.0, env: [1.4, 0.2, 0.9, 0.4], filter: { type: "lp", from: 140, to: 760, q: 2 }, vol: 0.5 }),
  at(2.0, tone({ wave: "saw", freq: 49.2, dur: 1.6, env: [0.3, 0.2, 0.8, 0.9], filter: { type: "lp", from: 760, to: 110, q: 2 }, vol: 0.5 })),
  tone({ wave: "sine", freq: 25, dur: 3.6, env: [1.6, 0.4, 0.8, 0.9], vol: 0.45 }),
  noise({ color: "pink", dur: 3.4, env: [1.5, 0.4, 0.5, 1.0], filter: { type: "bp", from: 350, to: 1100, q: 1.2 }, vol: 0.12 }))

// --- A coin that comes back warm (W0-12 warm_coin) ------------------------------------------------
// After the credit has counted: a second coin, from nowhere, rolls down and drops into the return cup.
// Two dull clinks on steel, a little roll, then it settles. Quieter than the credit, lower, no beep.
sfx("haunt_coin_return", { vol: 0.3 },
  at(0.0, noise({ color: "white", dur: 0.28, env: [0.02, 0.1, 0.5, 0.08], filter: { type: "bp", from: 2400, to: 1300, q: 2 }, tremolo: { rate: 22, depth: 0.8 }, vol: 0.25 })),
  at(0.32, tone({ wave: "fm", fm: { ratio: 3.1, index: 2.2, decay: 0.08 }, freq: "C#6", dur: 0.05, env: [0.001, 0.12, 0, 0.12] })),
  at(0.47, tone({ wave: "fm", fm: { ratio: 3.1, index: 1.6, decay: 0.06 }, freq: "B5", dur: 0.04, env: [0.001, 0.09, 0, 0.1], vol: 0.6 })),
  at(0.56, tone({ wave: "fm", fm: { ratio: 3.1, index: 1.2, decay: 0.05 }, freq: "B5", dur: 0.03, env: [0.001, 0.06, 0, 0.08], vol: 0.35 })))

// --- A tune from a machine with no tune (W0-12 sour_jingle) ---------------------------------------
// The Cabinet has never played an attract tune. Once, it does: the litany's foot (the zone cards' three
// notes) as a little coin-op fanfare, every voice ~60 cents flat and sagging, the lead a hair flatter than
// the bass so they beat, and the last note never comes (always one short, NARR-001 §2.1).
const sourNote = (t, n, d = 0.16, vol = 0.5) =>
  at(t, tone({ wave: "square", freq: n, dur: d, duty: 0.25, vibrato: { rate: 4.5, depth: 0.08, delay: 0.05 },
    env: [0.006, 0.07, 0.6, 0.09], vol }))
sfx("haunt_jingle", { vol: 0.24, pitch: -0.6, fx: [crush({ bits: 9, rate: 14000 }), delay({ time: 0.19, feedback: 0.25, mix: 0.18 })] },
  sourNote(0.0, "D5"), sourNote(0.2, "F5"), sourNote(0.4, "A5"),
  sourNote(0.75, "D5"), sourNote(0.95, "F5"), sourNote(1.15, "A5"),
  sourNote(1.5, "A5", 0.12), sourNote(1.68, "F5", 0.3, 0.45),
  // the bass walks under it, a touch sharper than the lead, so the two beat
  at(0.0, tone({ wave: "triangle", freq: 73.9, dur: 0.7, env: [0.01, 0.2, 0.6, 0.15], vol: 0.45 })),
  at(0.75, tone({ wave: "triangle", freq: 87.9, dur: 0.7, env: [0.01, 0.2, 0.6, 0.15], vol: 0.45 })),
  at(1.5, tone({ wave: "triangle", freq: 110.4, to: 104, slide: 0.9, dur: 0.9, env: [0.01, 0.3, 0.5, 0.6], vol: 0.45 })))

// --- The a0_4 / a0_5 stage loop (Q-T188) ----------------------------------------------------------
// Minimal cabinet chiptune: a triangle bass pulse in D minor and a sparse square figure on the litany's
// foot (A, F, D), quiet, so the chant (D drone, AUDIO-001 §5.1) sits on top. 8 s = 4 bars at 120 BPM,
// eighths. CabinetStageMusic plays it on BUS-MUS at a0_4 and a0_5 and detunes it by W0-11 Wear.
const E8 = 0.25
const BASS = ["D2", "D2", null, "D2", "D2", null, "C2", "D2",
              "D2", "D2", null, "D2", "F2", null, "E2", "D2",
              "Bb1", "Bb1", null, "Bb1", "Bb1", null, "A1", "Bb1",
              "A1", "A1", null, "A1", "C2", null, "C#2", "A1"]
const LEAD = [["A4", 0], ["F4", 2], ["D4", 4],
              ["A4", 8], ["F4", 10], ["D4", 12], ["E4", 14],
              ["F4", 16], ["D4", 18], ["Bb3", 20],
              ["A3", 24], ["C#4", 27], ["E4", 30]]
sfx("a0_stage_loop", { dur: 8, loop: true, vol: 0.42, fx: [crush({ bits: 10 }), limiter()] },
  BASS.map((n, i) => n && at(i * E8, tone({ wave: "triangle", freq: n, dur: 0.16, env: [0.004, 0.06, 0.55, 0.05], vol: 0.6 }))),
  LEAD.map(([n, s]) => at(s * E8, tone({ wave: "square", freq: n, dur: 0.12, duty: 0.125, env: [0.004, 0.05, 0.35, 0.06], vol: 0.22 }))),
  // a closed hat on the off-beats, very quiet: the machine's own tick
  Array.from({ length: 16 }, (_, i) => at(i * 0.5 + 0.25, noise({ color: "white", freq: 9000, dur: 0.02, env: [0.001, 0.015, 0, 0.01], filter: { type: "hp", cutoff: 6000 }, vol: 0.08 }))))
