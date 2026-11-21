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

// B04 Charge on the entity (and, quietly, on the Sepulchre): a struck bell, detuned downward, no impact thud.
// Owner playtest F-8 (2026-11-20): was too loud and sharp (peak -4.4 dBFS, 1 ms attack, FM index 5); #124 took it
// to peak -7.9. F-10 (round 3, same day): STILL too loud. Softened again: vol 0.4 -> 0.3, FM index 3 -> 2,
// 6 -> 16 ms attack, 3.2 kHz -> 2.2 kHz lowpass, reverb mix 0.2 -> 0.12, a shorter 0.7 s ring and a softer sub.
sfx("charge_hit", { vol: 0.3, fx: [reverb({ size: 0.5, mix: 0.12 })] },
  tone({ wave: "fm", fm: { ratio: 3.5, index: 2, decay: 0.5 }, freq: "D4", to: "C#4", slide: 1.0, dur: 0.7, env: [0.016, 0.6, 0.2, 0.4], filter: { type: "lp", cutoff: 2200 } }),
  tone({ wave: "sine", freq: 73, to: 55, dur: 0.5, env: [0.008, 0.4, 0.2, 0.25], vol: 0.35 }))

// --- The Sepulchre and the build (AUDIO-001 G-family) -------------------------------------------

// a deposit: a dull thud as a vertebra seats
sfx("segment_deposit", { vol: 0.55 },
  tone({ wave: "sine", freq: 70, to: 40, dur: 0.3, env: [0.002, 0.2, 0.2, 0.15] }),
  noise({ color: "brown", dur: 0.08, env: [0.001, 0.06, 0, 0.04], filter: { type: "lp", cutoff: 400 }, vol: 0.5 }))

// a module knocked off: bone cracking away. Plays together with charge_hit when a Charge lands on the
// Sepulchre (ritual _knock_modules: -3 dB and -9 dB). F-8 took it to peak -10.9 dBFS; F-10 (2026-11-20, round 3):
// still too loud and sharp. Now vol 0.34 -> 0.22, a 6 ms attack, the square lowpassed at 1.6 kHz, the noise lowpass
// 2400 -> 1500 Hz start, the crush eased to 10 bits, and 0.25 s long (was 0.35).
sfx("segment_knocked", { vol: 0.22, fx: [crush({ bits: 10 })] },
  tone({ wave: "square", freq: 330, to: 110, dur: 0.22, duty: 0.4, env: [0.006, 0.13, 0.2, 0.08], filter: { type: "lp", cutoff: 1600 } }),
  noise({ color: "white", dur: 0.15, env: [0.006, 0.08, 0.1, 0.06], filter: { type: "lp", from: 1500, to: 500 }, vol: 0.4 }))

// the last module falls (Sepulchre down, the stage ends): a soft bone chime that sags a fifth, over a low
// breath-out. Same family and level as the quieter impact cues (peak target <= -13 dBFS: the owner found the
// Charge hit too loud): vol 0.22, 12 ms attack, 1.8 kHz lowpass, no noise burst, 0.9 s. Plays at the instant of
// the fall (SepulchreRitual._knock_modules), after the last segment_knocked (stage hand-off, Q-T457).
sfx("sepulchre_down", { vol: 0.22, fx: [reverb({ size: 0.5, mix: 0.1 })] },
  tone({ wave: "sine", freq: "A4", to: "E4", slide: 0.6, dur: 0.8, env: [0.012, 0.5, 0.2, 0.45], filter: { type: "lp", cutoff: 1800 } }),
  at(0.06, tone({ wave: "sine", freq: "E3", to: "A2", slide: 0.7, dur: 0.8, env: [0.02, 0.4, 0.2, 0.4], vol: 0.6 })))

// --- The Choir (AUDIO-001 F-family, §5)-------------------------------------------------------

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

// --- Power-on and the coin door (attract, owner request 2026-11-18) -----------------------------

// the cabinet switching on: a relay thump, the degauss shudder, and the faint whine of the tube
sfx("power_on", { vol: 0.5, fx: [crush({ bits: 10 })] },
  tone({ wave: "sine", freq: 70, to: 40, dur: 0.5, env: [0.001, 0.2, 0.2, 0.25] }),
  noise({ color: "brown", dur: 0.9, env: [0.005, 0.3, 0.4, 0.4], filter: { type: "lp", cutoff: 300 }, tremolo: { rate: 50, depth: 0.7 }, vol: 0.5 }),
  at(0.2, tone({ wave: "sine", freq: 5200, dur: 1.2, env: [0.3, 0.2, 0.5, 0.5], vol: 0.04 })))

// tape torn off the coin door: a rising crackle
sfx("tape_peel", { vol: 0.35 },
  noise({ color: "white", dur: 0.35, env: [0.01, 0.1, 0.6, 0.1], filter: { type: "bp", from: 1500, to: 4200, q: 1.5 }, tremolo: { rate: 38, depth: 0.8 } }))

// a coin clinks into the mech, rattles down, and the credit lamp beeps twice
sfx("coin", { vol: 0.4 },
  tone({ wave: "triangle", freq: "E7", dur: 0.08, env: [0.001, 0.06, 0, 0.02] }),
  at(0.05, tone({ wave: "triangle", freq: "G7", dur: 0.14, env: [0.001, 0.1, 0, 0.04], vol: 0.7 })),
  at(0.16, noise({ color: "white", dur: 0.12, env: [0.001, 0.05, 0.2, 0.05], filter: { type: "hp", cutoff: 3000 }, tremolo: { rate: 30, depth: 0.9 }, vol: 0.3 })),
  at(0.35, tone({ wave: "square", freq: "A5", dur: 0.07, duty: 0.25, env: [0.001, 0.04, 0.4, 0.02], vol: 0.5 })),
  at(0.45, tone({ wave: "square", freq: "E6", dur: 0.16, duty: 0.25, env: [0.001, 0.08, 0.4, 0.06], vol: 0.5 })))

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

// --- M1 additions (AUDIO-001 §12.7 C4; ids match §6.2) ------------------------------------------

// A03 lance on Choir armour: the sound of not biting. A short, dull inharmonic tick (FM, ratio
// 2.76, fast decay) with a muffled noise knock; nothing rings, so it cannot be mistaken for glass.
sfx("lance_armour", { vol: 0.4, fx: [crush({ bits: 9 })] },
  tone({ wave: "fm", fm: { ratio: 2.76, index: 2.5, decay: 0.05 }, freq: 620, to: 540, slide: 0.05, dur: 0.05, env: [0.001, 0.05, 0, 0.03] }),
  noise({ color: "brown", dur: 0.04, env: [0.001, 0.03, 0, 0.02], filter: { type: "bp", cutoff: 900, q: 1.5 }, vol: 0.5 }))

// A04 geode crack: a dry chalk line tearing, rising in texture before geode_break
sfx("geode_crack", { vol: 0.4 },
  noise({ color: "white", dur: 0.14, env: [0.001, 0.08, 0.2, 0.04], filter: { type: "bp", from: 2200, to: 5500, q: 1.8 }, tremolo: { rate: 70, depth: 0.85 } }),
  noise({ color: "white", dur: 0.012, env: [0.001, 0.01, 0, 0.005], filter: { type: "hp", cutoff: 3500 }, vol: 0.7 }))

// A09 dry fire: one dull chalk tick, the lowest priority cue (quiet, tiny, no pitch to follow)
sfx("dry_fire", { vol: 0.5 },
  noise({ color: "pink", dur: 0.02, env: [0.001, 0.015, 0, 0.01], filter: { type: "bp", cutoff: 1600, q: 1.2 } }),
  tone({ wave: "triangle", freq: 700, to: 500, dur: 0.02, env: [0.001, 0.015, 0, 0.01], vol: 0.4 }))

// C07 hull hit: a hard thump with grit and the hull ringing on it. Damage, not a sweep: short,
// all body, no falling filter (that belongs to vigil_die, C08). Identity sits above 300 Hz.
sfx("hull_hit", { vol: 0.4, fx: [crush({ bits: 8, rate: 16000 }), drive({ amount: 1.4 })] },
  tone({ wave: "square", freq: 320, to: 110, slide: 0.08, dur: 0.12, duty: 0.5, env: [0.001, 0.08, 0.3, 0.06] }),
  tone({ wave: "sine", freq: 90, to: 50, dur: 0.2, env: [0.001, 0.12, 0.2, 0.1], vol: 0.6 }),
  noise({ color: "white", dur: 0.1, env: [0.001, 0.06, 0.1, 0.04], filter: { type: "lp", from: 5000, to: 800 }, vol: 0.6 }),
  at(0.03, tone({ wave: "fm", fm: { ratio: 2.1, index: 3, decay: 0.2 }, freq: 440, to: 400, dur: 0.25, env: [0.002, 0.2, 0.1, 0.15], vol: 0.35 })))

// C04 Surgelight: a brass fanfare cut to one bright rising note. Saw voices through a rising
// filter (never a pure sine, so it cannot be mistaken for the B06 glass chime).
sfx("surgelight", { vol: 0.35, fx: [crush({ bits: 10 })] },
  tone({ wave: "saw", freq: 700, to: 1500, slide: 0.18, dur: 0.2, env: [0.04, 0.08, 0.6, 0.06], filter: { type: "lp", from: 1800, to: 5000 } }),
  tone({ wave: "saw", freq: 703, to: 1510, slide: 0.18, dur: 0.2, env: [0.05, 0.08, 0.5, 0.06], vol: 0.6, filter: { type: "lp", from: 1800, to: 5000 } }),
  noise({ color: "white", dur: 0.18, env: [0.08, 0.08, 0.2, 0.05], filter: { type: "hp", from: 3000, to: 6000 }, vol: 0.1 }))

// --- Sizzle sounds (AUDIO-001 §12.11; owner-approved 2026-11-18) ---------------------------------

// S4 lance on the Sepulchre or the entity: "does not bite". Lower and flatter than lance_armour
// (A03): a chalk tick, no tone to follow, no ring. Player-caused, so the §1.4 onset exception applies.
sfx("lance_dull", { vol: 0.4 },
  noise({ color: "pink", dur: 0.035, env: [0.001, 0.025, 0, 0.015], filter: { type: "bp", cutoff: 700, q: 1.0 } }),
  tone({ wave: "triangle", freq: 330, to: 240, slide: 0.03, dur: 0.035, env: [0.001, 0.025, 0, 0.015], vol: 0.35 }))

// S7 service record tally: one bright cabinet blip per stat line. A short square step, quiet,
// no tail, so a seven-line roll never builds into a phrase.
sfx("tally_blip", { vol: 0.22, fx: [crush({ bits: 10 })] },
  tone({ wave: "square", freq: 1320, dur: 0.05, duty: 0.25, env: [0.001, 0.03, 0.2, 0.015] }))

// --- M1 slice 3 (AUDIO-001 §6.2 A07, A08, A13, B10–B12, F11; requested by the M1 chat 2026-11-18) ----

// A07 over-fire warning: a sine-ish rise, pitch only, never level (§1.4). Called once at 6 hits.
// Triangle 520 → 980 Hz, below the B06 chime's 1.2 kHz and never pure.
sfx("overfire_warn", { vol: 0.2 },
  tone({ wave: "triangle", freq: 520, to: 980, slide: 0.5, curve: "lin", dur: 0.55, env: [0.06, 0.1, 0.8, 0.08], vibrato: { rate: 9, depth: 0.15 } }))

// A08 over-fire detonation: a glass chord struck from inside, then a 0.4 s vacuum decay (the air
// pulled out: low-pass sweeping down). Player-owned cause, so it may be loud (§1.4).
sfx("overfire_burst", { vol: 0.45, fx: [drive({ amount: 1.3 }), limiter()] },
  tone({ wave: "fm", fm: { ratio: 3.5, index: 4, decay: 0.3 }, freq: "A4", dur: 0.08, env: [0.001, 0.15, 0.3, 0.4], vol: 0.6 }),
  tone({ wave: "fm", fm: { ratio: 3.5, index: 4, decay: 0.3 }, freq: "D#5", dur: 0.08, env: [0.001, 0.15, 0.3, 0.4], vol: 0.45 }),
  noise({ color: "white", dur: 0.06, env: [0.001, 0.05, 0, 0.03], filter: { type: "hp", cutoff: 2500 }, vol: 0.5 }),
  at(0.05, noise({ color: "pink", dur: 0.4, env: [0.01, 0.3, 0.2, 0.1], filter: { type: "lp", from: 4000, to: 150 }, vol: 0.6 })),
  at(0.12, ["E6", "A5", "C#6"].map((n, i) => at(i * 0.07, tone({ wave: "fm", fm: { ratio: 2.76, index: 1.5, decay: 0.1 }, freq: n, dur: 0.03, env: [0.001, 0.05, 0, 0.1], vol: 0.25 })))))

// A13 magnet latch: a shard enters the magnet radius. Tiny and quiet, many per second.
sfx("magnet_latch", { vol: 0.2 },
  tone({ wave: "triangle", freq: 1500, to: 2100, slide: 0.04, dur: 0.04, env: [0.003, 0.03, 0, 0.03] }))

// B10 Charge armed: the magazine gains a pip. A short wet glass ring, lower than the A06 ladder.
sfx("charge_armed", { vol: 0.2 },
  tone({ wave: "fm", fm: { ratio: 1.4, index: 1.2, decay: 0.15 }, freq: 660, dur: 0.05, env: [0.003, 0.1, 0.2, 0.2] }),
  tone({ wave: "sine", freq: 330, dur: 0.05, env: [0.003, 0.08, 0.1, 0.15], vol: 0.4 }))

// B11 magazine full: a shard collected at cap stays in the world. Two muted notes down, not an alarm.
sfx("magazine_full", { vol: 0.22 },
  tone({ wave: "square", freq: 440, dur: 0.04, duty: 0.5, env: [0.002, 0.03, 0.3, 0.03], filter: { type: "lp", cutoff: 1500 } }),
  at(0.07, tone({ wave: "square", freq: 370, dur: 0.05, duty: 0.5, env: [0.002, 0.03, 0.3, 0.04], filter: { type: "lp", cutoff: 1200 } })))

// B12 Charge gutters out (6 s, no hit): the glass ring dying, slow attack, muffled and falling.
// Deliberately unlike B06 (no fast attack, no clean 1.2 kHz): this loss is the player's, not the Choir's.
sfx("charge_gutter", { vol: 0.18 },
  tone({ wave: "fm", fm: { ratio: 1.5, index: 0.8 }, freq: 880, to: 620, slide: 0.6, dur: 0.6, env: [0.08, 0.2, 0.5, 0.3], filter: { type: "lp", from: 3000, to: 500 } }),
  noise({ color: "pink", dur: 0.5, env: [0.1, 0.2, 0.3, 0.2], filter: { type: "bp", from: 1500, to: 400, q: 1.5 }, vol: 0.2 }))

// F11 Grub steals a shard: a short sliding Choir voice rising (keening's family, but brief and
// pleased). Choir timbre only (saw through a vowel band-pass); never a player-feedback instrument.
sfx("grub_steal", { vol: 0.3 },
  tone({ wave: "saw", freq: 300, to: 460, slide: 0.22, dur: 0.25, env: [0.03, 0.08, 0.6, 0.1], filter: { type: "bp", cutoff: 900, q: 3 }, vibrato: { rate: 6, depth: 0.2 } }),
  tone({ wave: "saw", freq: 302, to: 463, slide: 0.22, dur: 0.25, env: [0.04, 0.08, 0.5, 0.1], filter: { type: "bp", cutoff: 1300, q: 4 }, vol: 0.5 }))

// --- The Act 0 shift (Arcade layer chat, PM-directed 2026-11-19; AUDIO-001 §12.16) ----------------
// Cabinet chiptune voice: square and triangle, short envelopes, a little crush. No stings (§1.1):
// zone cards get short jingles, never hits. Each ≤ 2.5 s (the READY card). UNAUDITIONED.

// Censer bell: one bell 1 s before an Acolyte reinforcement enters (acolyte_squad.gd). A warning
// tell, kept quiet (under the §1.4 −18 LUFS-S onset line): a crushed FM bell, short ring.
sfx("censer_bell", { vol: 0.22, fx: [crush({ bits: 9 })] },
  tone({ wave: "fm", fm: { ratio: 3.5, index: 3, decay: 0.3 }, freq: "A5", dur: 0.05, env: [0.004, 0.25, 0.2, 0.5] }),
  tone({ wave: "triangle", freq: "A4", dur: 0.05, env: [0.004, 0.2, 0.1, 0.3], vol: 0.4 }))

// Zone cards: one shared three-note motif (the litany's foot), re-voiced per zone.
const zoneNote = (t, n, wave = "square", vol = 0.5) =>
  at(t, tone({ wave, freq: n, dur: 0.14, duty: 0.25, env: [0.004, 0.06, 0.6, 0.08], vol }))

// Drift: calm, open, major, unhurried.
sfx("zone_drift", { vol: 0.3, fx: [crush({ bits: 10 })] },
  zoneNote(0, "C5"), zoneNote(0.22, "E5"), zoneNote(0.44, "G5"),
  at(0.66, tone({ wave: "triangle", freq: "C6", dur: 0.5, env: [0.01, 0.2, 0.5, 0.3], vol: 0.5 })),
  at(0, tone({ wave: "triangle", freq: "C4", dur: 1.0, env: [0.01, 0.3, 0.4, 0.3], vol: 0.35 })))

// Censer Watch: minor, with the censer bell answering the motif.
sfx("zone_censer_watch", { vol: 0.3, fx: [crush({ bits: 10 })] },
  zoneNote(0, "A4"), zoneNote(0.22, "C5"), zoneNote(0.44, "E5"),
  at(0.7, play("censer_bell", { vol: 1.4 })),
  at(0, tone({ wave: "triangle", freq: "A3", dur: 1.0, env: [0.01, 0.3, 0.4, 0.3], vol: 0.35 })))

// Shoal: the motif rippling (fast arpeggio, gentle vibrato), like light through water.
sfx("zone_shoal", { vol: 0.3, fx: [crush({ bits: 10 }), delay({ time: 0.11, feedback: 0.3, mix: 0.25 })] },
  at(0, tone({ wave: "square", freq: "D5", dur: 0.5, duty: 0.25, arp: { notes: [0, 3, 7, 12], rate: 0.05 }, env: [0.005, 0.1, 0.6, 0.15], vol: 0.45 })),
  at(0.6, tone({ wave: "triangle", freq: "A5", dur: 0.45, vibrato: { rate: 6, depth: 0.2 }, env: [0.01, 0.15, 0.5, 0.3], vol: 0.5 })),
  at(0, tone({ wave: "triangle", freq: "D4", dur: 1.1, env: [0.01, 0.3, 0.4, 0.3], vol: 0.35 })))

// Stillwater (was "Hollow", renamed by PM ruling 2026-11-19): the motif falling, its last note missing (always one short).
sfx("zone_stillwater", { vol: 0.3, fx: [crush({ bits: 9 })] },
  zoneNote(0, "E5"), zoneNote(0.26, "C5"),
  at(0, tone({ wave: "triangle", freq: "E3", dur: 1.2, env: [0.01, 0.4, 0.3, 0.5], vol: 0.4 })))

// CONTINUE?: a countdown tick (Visual Design owns the count and its timing; one call per step).
sfx("continue_tick", { vol: 0.22 },
  tone({ wave: "square", freq: 988, dur: 0.04, duty: 0.5, env: [0.002, 0.03, 0.3, 0.02] }))

// Continue taken: a coin's worth of hope, two bright steps up (CabinetGame.on_route_entered).
sfx("continue_taken", { vol: 0.3, fx: [crush({ bits: 10 })] },
  zoneNote(0, "G5"), zoneNote(0.12, "C6"),
  at(0.24, tone({ wave: "square", freq: "E6", dur: 0.25, duty: 0.25, env: [0.004, 0.08, 0.5, 0.15], vol: 0.45 })))
