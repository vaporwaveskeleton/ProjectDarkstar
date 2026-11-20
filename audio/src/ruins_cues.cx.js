// DARKSTAR — the Ruins first visit, one-shot foley, as code (GDD-001 D-14; AUDIO-001 §12.19; hook names
// fixed by the Ruins onboarding, TECH-001 Q-T194, `scenes/ruins/ruins.gd` CUES).
// Build (mono: diegetic foley, never panned):
//   node .claude/skills/chirp-game-audio/bin/chirp.js build audio/src/ruins_cues.cx.js --out assets/audio/generated --mono
// The hall is stone and brass; every cue carries a little of its air (the hall bed `ruins_hall` is the
// rest). Chalk here is a soft, low, grainy stroke on slate: it must never be mistaken for the lie-tell
// tick `lie_tell_chalk` (a dry 2.4–3.6 kHz white-noise flick at 60 Hz tremolo). No 1.2 kHz partials
// (the B06 glass chime stays unique). Peaks stay at or under -12 dBFS. UNAUDITIONED.

const HALL = (mix) => [reverb({ size: 0.7, damp: 0.55, mix }), limiter({ ceiling: 0.25 })]

// Chalk on slate, one stroke: pink grain low in the band (700–1600 Hz), a slow scrape, and the soft
// knock of the chalk touching down. Fires per stroke, so policy jitters it.
sfx("ruins_chalk_write", { vol: 1.3, fx: HALL(0.12) },
  tone({ wave: "sine", freq: 210, to: 160, slide: 0.03, dur: 0.02, env: [0.002, 0.03, 0, 0.04], vol: 0.25 }),
  noise({ color: "pink", freq: 5200, dur: 0.17, env: [0.01, 0.05, 0.7, 0.06], filter: { type: "bp", from: 1600, to: 900, q: 1.6 },
    tremolo: { rate: 23, depth: 0.45 }, vol: 0.5 }))

// The Cabinet pays out: the ticket feed motor and its ratchet clicking each ticket through, slowing
// as the stack runs out.
const FEED = Array.from({ length: 18 }, (_, i) => 0.05 + i * 0.055 + i * i * 0.0012)
sfx("ruins_ticket_payout", { vol: 0.8, fx: HALL(0.15) },
  tone({ wave: "saw", freq: 96, to: 82, slide: 1.3, dur: 1.3, env: [0.05, 0.1, 0.7, 0.15], vol: 0.12, filter: { type: "lp", cutoff: 700 } }),
  FEED.map((t, i) => at(t,
    noise({ color: "white", dur: 0.006, env: [0.001, 0.008, 0, 0.02], filter: { type: "bp", cutoff: 2600 + (i % 3) * 300, q: 3 }, vol: 0.32 }),
    noise({ color: "pink", dur: 0.03, env: [0.003, 0.03, 0, 0.03], filter: { type: "bp", cutoff: 1500, q: 1.5 }, vol: 0.1 }))))

// The tickets land on the brass tray and settle: paper flutter, a few soft slaps.
sfx("ruins_tickets_land", { vol: 2.6, fx: HALL(0.18) },
  [0, 0.07, 0.16, 0.22, 0.35].map((t, i) => at(t,
    noise({ color: "pink", dur: 0.05, env: [0.004, 0.05, 0, 0.06], filter: { type: "bp", cutoff: 1800 - i * 150, q: 1.2 }, vol: 0.35 - i * 0.04 }))),
  noise({ color: "pink", dur: 0.5, env: [0.05, 0.2, 0.3, 0.2], filter: { type: "bp", from: 2400, to: 900, q: 0.8 }, tremolo: { rate: 17, depth: 0.6 }, vol: 0.12 }))

// The pilot lamp goes down: the gas hiss falls and narrows, the mantle ticks as it cools. A cousin of
// the Unmaking's `unmaking_lamp_out`, but short and with the hall around it (this dark is chosen).
sfx("ruins_lamp_gutter", { vol: 1.3, fx: HALL(0.25) },
  noise({ color: "white", dur: 1.1, env: [0.15, 0.6, 0.3, 0.3], filter: { type: "bp", from: 4800, to: 900, q: 1.1 }, tremolo: { rate: 7, depth: 0.3 }, vol: 0.2 }),
  [0.12, 0.3, 0.55, 0.9].map((t, i) => at(t,
    noise({ color: "white", dur: 0.007, env: [0.001, 0.008, 0, 0.015], filter: { type: "bp", cutoff: 3000 - i * 300, q: 2 }, vol: 0.22 - i * 0.04 }))),
  at(1.2, tone({ wave: "triangle", freq: 2489, dur: 0.01, env: [0.002, 0.03, 0, 0.12], vol: 0.03 })))

// A Tree lamp catches: the soft whump of gas taking, then a warm brass-and-glass bloom (G4 and D5, a
// fifth: clear of 1.2 kHz) that grows, never strikes.
sfx("ruins_tree_lamp", { vol: 0.8, fx: HALL(0.35) },
  noise({ color: "brown", dur: 0.25, env: [0.02, 0.2, 0, 0.2], filter: { type: "lp", from: 900, to: 200 }, vol: 0.5 }),
  noise({ color: "pink", dur: 0.6, env: [0.08, 0.3, 0.4, 0.3], filter: { type: "bp", cutoff: 3600, q: 0.8 }, vol: 0.06 }),
  at(0.08, tone({ wave: "fm", fm: { ratio: 2, index: 0.8, decay: 0.6 }, freq: 392, dur: 0.8, env: [0.12, 0.4, 0.5, 0.8], vol: 0.12 })),
  at(0.18, tone({ wave: "sine", freq: 587.3, dur: 0.7, env: [0.2, 0.4, 0.4, 0.8], vol: 0.07 })))

// A Codex page turns: the lift, the swish across, the soft lay-down.
sfx("ruins_codex_page", { vol: 1.4, fx: HALL(0.1) },
  noise({ color: "pink", dur: 0.08, env: [0.01, 0.06, 0, 0.04], filter: { type: "bp", cutoff: 2200, q: 1.5 }, vol: 0.15 }),
  at(0.06, noise({ color: "pink", dur: 0.22, env: [0.05, 0.1, 0.5, 0.08], filter: { type: "bp", from: 900, to: 3200, q: 0.9 }, vol: 0.3 })),
  at(0.3, noise({ color: "brown", dur: 0.05, env: [0.005, 0.05, 0, 0.06], filter: { type: "lp", cutoff: 700 }, vol: 0.35 })))

// The hidden chalk shows in the dark: a phosphor bloom, slow and low (a glass swell from nothing, the
// faint chalk grain under it). Information, so it has a voice; never a sting (0.5 s onset, §1.1).
sfx("ruins_dark_chalk", { vol: 0.8, fx: HALL(0.4) },
  tone({ wave: "sine", freq: 329.6, dur: 1.2, env: [0.5, 0.3, 0.6, 0.7], vol: 0.12 }),
  tone({ wave: "sine", freq: 329.6 * Math.pow(2, 7 / 1200), dur: 1.2, env: [0.6, 0.3, 0.6, 0.7], vol: 0.1 }),
  tone({ wave: "fm", fm: { ratio: 2.41, index: 0.4 }, freq: 164.8, dur: 1.2, env: [0.7, 0.3, 0.5, 0.7], vol: 0.06 }),
  noise({ color: "pink", dur: 1.0, env: [0.4, 0.3, 0.4, 0.4], filter: { type: "bp", cutoff: 1100, q: 2 }, tremolo: { rate: 11, depth: 0.5 }, vol: 0.08 }))

// A station comes into reach: two small brass taps a fifth apart (C5, G5), quiet and close.
sfx("ruins_station_near", { vol: 1.1, fx: HALL(0.2) },
  tone({ wave: "fm", fm: { ratio: 3.51, index: 1.2, decay: 0.08 }, freq: 523.3, dur: 0.03, env: [0.003, 0.15, 0, 0.3], vol: 0.12 }),
  at(0.09, tone({ wave: "fm", fm: { ratio: 3.51, index: 1.0, decay: 0.08 }, freq: 784, dur: 0.03, env: [0.003, 0.15, 0, 0.35], vol: 0.09 })))
