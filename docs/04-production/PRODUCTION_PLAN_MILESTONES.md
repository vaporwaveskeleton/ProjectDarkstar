# DARKSTAR — Production Plan & Milestones

**Doc ID:** PROD-001 · **Version:** 1.1 · **Date:** 2026-11-18 · **Owner:** producer · **Status:** M0 done; M1 in progress
**Upstream:** GDD-001 §2, §15, §16, §17; TECH-001 §9 (tests), §11 (open questions); ZONES-001 §3 (kits); WARP-001 §6.1 D-10/D-11 (slice tranche, warp lint); MARKET-001 §13 (beat calendar) · **Downstream:** every milestone review, MARKET-001 beat gating, CLAUDE.md §6 definition of done

**Number discipline.** Dates, team sizes, hour budgets and counts that are not GDD/SYS facts are **planning assumptions `✱`**. Game numbers stay in SYS-001. A milestone is "done" only when its exit criteria were *measured*; nothing here is claimed as measured unless its row says so.

---

## 0. How to read this doc

| If you are… | Read | Then |
|---|---|---|
| deciding what to build next | §3 (current milestone), §5 kit order | TECH-001 for the how |
| checking the vertical slice | §4 | GDD-001 §17 |
| cutting scope | §7 cut order | GDD-001 §16 R-03 |
| planning marketing beats | §3 gates | MARKET-001 §13 |
| running the week | §8 cadence | CLAUDE.md §6 |

---

## 1. Team assumptions ✱

| Role | Allocation ✱ | Notes |
|---|---|---|
| Lead (design, code, production) | 1.0 FTE | the owner; AI-assisted per CLAUDE.md §5 delegation |
| Technical artist / shader programmer | 0.5 FTE from M1, 1.0 FTE M3–M6 | D-13: every visual is a generator (ART-001 §14); one person who can draw *and* code part generators and shaders replaces the pixel-art contract |
| Sound programmer / synth designer | 0.3 FTE from M2, 0.6 FTE M4–M6 | D-14: every sound is synthesised (AUDIO-001 §11); no recording sessions, no voice actor |
| Writer (contract or lead) | 0.2 FTE M2–M6 | NARR-001 §7–§8 text volume: eat lines, death grammar, Codex |
| Community / creator manager | 0.3 FTE from M4 (store page live) | MARKET-001 §8–§9 |
| QA / playtest coordination | Discord volunteers + 2 paid test rounds ✱ (M2, M5) | GDD-001 §15 interview metrics need structured sessions |
| Localization | **none** — English only (owner decision 2026-11-17, L10N-001 §1) | revisit after 1.0 |

If the team is smaller than this table, §7's cut order fires earlier; dates never stretch silently.

---

## 2. Milestone overview

| ID | Name | Target window ✱ | Gate for marketing (MARKET-001 §13) | Status |
|---|---|---|---|---|
| **M0** | Architecture bootstrap | 2026-11-17 | — | **done** — 72 tests pass, boot smoke clean (TECH-001 §9) |
| **M1** | Feel prototype | 2027-01 | studio socials | **in progress** (§3 M1 Progress) |
| **M2** | Vertical slice | 2027-04 | **store page + announcement trailer** (2027-05) | planned |
| **M3** | Performance & platform gate | 2027-06 | — | planned |
| **M4** | Demo | 2027-09 | **public demo, Steam Next Fest** (2027-10 ✱) | planned |
| **M5** | Content alpha (Acts 1–2) | 2027-11 | — | planned |
| **M6** | Content beta (Acts 3–4, all endings) | 2027-12 | **release date announced** | planned |
| **M7** | Release candidate → 1.0 | 2028-02 ✱ | **launch** | planned |
| **M8** | "The Ninth Sky" free update | 2028-05 ✱ | update beat | planned |

### 2.1 North star (The Reviewer v1, adopted 2026-11-18)

An imagined 1.0 review scored the game 9/10, with sub-scores for graphics and art direction, sound design and music, moment-to-moment feel and controls, level and encounter design, narrative and world, progression and replayability, UI/HUD readability (incl. HUD lies), performance and technical polish, accessibility, and wow factor. It is the target to build toward. It is kept in `research/the_reviewer_v1.md` (local, git-ignored).

**Adopted goals (owner, 2026-11-18: "Adopt top 5").** Source: The Reviewer v1 §2.4. Status is as the source states it; it is not re-verified here.

| # | Goal id(s) | Goal | Done looks like (source) | Milestone | Status (source) |
|---|---|---|---|---|---|
| 1 | U-2 / U-5 | HUD lies are fair under combat load (WARP-001 §4.2 L3) | In the paid test round, testers identify each T3–T4 lie within the L3 window while fighting; lie-attributed deaths under a ceiling (**target to be set (owner)**); lint enforces the lie laws and the T5 zero budget | M5 | not started |
| 2 | G-2 / G-5 / W-5 | The Aether after the Pretence lives up to the reveal (ART-001 §15, §16.1; ART-004) | One continuous bezel-to-Aether move; cold viewers sort tier stills correctly; the entity's arrival is the only true black; ART-004 L1 readiness at a target (**target to be set (owner)**) from motion captures; the clip test passes (W-1) | M2 (T0–T2, G-5, W-5); M4 (G-5 demo); M6 (T3–T5) | G-2 partly (T0 built, L1 Aether not started); G-5 not started; W-5 not started |
| 3 | L-1 / L-2 | Variety that survives the thirtieth run (ZONES-001 §4.4, §4.6, Q-04) | Every kit passes the lint; the §4.4 rules are hard gates; kit permutations decided; "seen it" tags in late runs under a ceiling (**target to be set (owner)**); session-length and rage-quit targets at M5 (**target to be set (owner)**; the source's values are not owned by any doc) | M5 (L-2: M5 to M7) | not started |
| 4 | F-1 / F-4 / F-5 | The Vigil and the race feel right in human hands (§3 M1) | M1 exit criteria met with real testers; input latency measured; D-08 decided from A/B data; full M1 verb set playable (over-fire, magnet, Charges, Grub, Sepulchre in a sector) | M1 (F-1, F-5); M2 (F-4) | F-1 partly (Vigil and Arc-Lance base built, no human real-input check yet); F-4 partly (`--hull=1\|2` switch, CLI only); F-5 not started |
| 5 | R5 + P-5 + X-4 | The first two hours do not lose people (GDD §3 P5, §9.1, §15; WARP-001 §7.4) | Written diegetic onboarding spec for the first Ruins visit and Act 1; TEST-ONB-01/02 pass; time to understand the race meets the GDD §15 target; new players name every HUD resource after one Ruins visit; owner decides an assist set | M2 (P-5, R5); X-4: owner decision by M2, build M4 | not started |

**Review cycle (adopted).** A fresh "Reviewer" session re-reviews the build at every milestone exit, M1 to M7, in the same voice and against the same ten aspects. It scores only from captured evidence; anything not captured is "not evaluated"; after M2 it never scores from docs alone. Each aspect gets a build score (0 to 10) and a north-star progress share (goals verified done by test, playtest or capture, among those due). A spot review of one or two aspects runs mid-milestone whenever a top-5 goal lands. Each re-review publishes one table (aspect, north-star score, build score, progress, change since last review, top blocker), with the build's overall score shown next to 9/10. A sub-score that falls at a milestone exit is flagged for the PM to investigate. Any aspirational goal is "unmeasurable" until its owner-set threshold exists.

**Not adopted yet.** The source's other goals and its 12 proposed doc changes are NOT adopted. They await owner review.

---

## 3. Milestones in detail

### M0 — Architecture bootstrap ✅ (2026-11-17)
| | |
|---|---|
| Goal | a scalable Godot 4.7.2 project skeleton with services, base scenes, tests and docs |
| Exit criteria (measured) | boot → attract → sector with no errors; 72 GdUnit4 tests pass headless (TECH-001 §9) |
| Delivered | `SceneRouter`, `SaveService`, `SettingsService`; `Vigil`; Health/Hurtbox/Hitbox components; attract, settings, pause, confirm screens; theme; `en.po`; TECH-001 §2–§11, EVT-001, UI-001, L10N-001 |
| Carried forward | TECH-001 §11.1 open questions; the placeholder subsections in TECH-001 §4–§8 |

### M1 — Feel prototype (target 2027-01 ✱)
| | |
|---|---|
| Goal | prove the 30-second loop (GDD-001 §5) feels right before any content scale-up |
| Exit criteria | (1) 0 input-latency complaints in mouse aim from 5 ✱ testers (GDD-001 §17 criterion 3); (2) a tester describes the race unprompted within 90 s (GDD-001 §15 prototype target); (3) all SYS-001 §1.1–§1.4 rows implemented as `ds_` tunables and covered by tests; (4) the D-08 hull A/B switch is playable both ways |
| Code | Arc-Lance + over-fire; Mourning Glass + magnet; Null-Iron Charges with interception; Grub procession + Sepulchre deposits (phases 0–1); Ledger Compass stub; seeded RNG skeleton (TECH-001 §4.9); camera follow/shake (SYS-001 §9) |
| Art | Vigil kit, Grub kit, geode kit, Sepulchre seed parts (ART-002 §4) at slice quality for PM kits only |
| Audio | synthesised lance/mining/chime (AUDIO-001 §11); the glass chime (AUDIO-001 §6.4) final, because it carries the race |
| Narrative | none required |
| Progress | **Slice 1 done (2026-11-18):** Arc-Lance base + D-08 hull switch. **Slice 2 part A done (2026-11-18):** D-08 A/B playable by CLI (`--hull=1|2`, `HullMode`), so exit criterion 4 is met for CLI testers (no in-game setting yet). **Slice 2 part B done (2026-11-18):** `RunSeed` and `SeedCode` built in `core/rng/` (FNV-1a 64 + SplitMix64, CRC-5 checksum; owner ruling, TECH-001 §4.9); `ReplayVerifier` and wiring into features pending (needs a deterministic sim). Shard-count conflict needs an owner ruling (Q-T29). Remaining: over-fire, Mourning Glass magnet, Charges, Grub/Sepulchre, Ledger Compass stub, camera. **Not yet done by a human:** the slice 1 real-input mouse-fire check, and a real `--hull=2` launch |
| Docs | TECH-001 §4.3 (shard magnet), §4.9 (seed); SYS-001 rows for anything new |
| Risks | the race is invisible at 640×360 → fix with art/audio, not with UI text (GDD-001 P5) |

#### Status notes (2026-11-18)

**Work landed 2026-11-18 (not M1 scope).** Merged PRs; detail lives in the owning doc, not here.
- #1: arcade power-on, attract cards, taped coin slot (TECH-001 §2.10; UI-001).
- #2, #3, #6: the M1 slices (Progress row above; TECH-001 §4.9 for #6).
- #4: the seeded RNG spec; superseded by #6 and #9 (TECH-001 §4.9).
- #5: ART-004 visual quality rubric (`docs/02-art/VISUAL_QUALITY_RUBRIC.md`) and Act 0 quick wins.
- #7: Act 0 printed bezel art (ART-001 §12.7a).
- #10: the arcade screen in its own SubViewport, native-resolution root (TECH-001 §2.10).
- #11: Act 0 portrait grid 256×304, 40 px HUD strip, bezel fills the window (TECH-001 §2.10; Q-T31 resolved).
- #8: audio voice policy, mono renders, five M1 cues (AUDIO-001 §12; TECH-001 §2.7).
- #9: SeedCode checksum CRC-5 (TECH-001 §4.9).

**In flight (2026-11-18).** None of this is built or measured yet unless stated.
- Visual Design: Act 0 video limits (16 RGB332 colour registers; built 2026-11-18, TECH-001 §2.10), then PR C (VectorText and the full bezel art) and PR D (zoom destruction).
- Sizzle: in-game polish batch S0 effect tunables, S1 hit-stop, S7 credits service record, S3 last-Charge slow-mo, S4 Lance bite. Approved; values pending owner approval.
- Game audio: the sizzle sound cues.
- Workflow tools research.
- On hold: the web fix for `core/ui/input_labels.gd` (`keyboard_get_keycode_from_physical` is unsupported on Web), held until the Visual Design rework.

**Web build feasibility (2026-11-18).** A single localhost run, not a benchmark. The Godot 4.7.2 single-threaded Web export of the Cabinet boots with the CRT and mouse input. wasm 39.5 MB (10.1 MB gzip-9), pck 1.7 MB, 9 files, about 41.5 MB raw, first paint about 5.4 s on localhost. Unverified: audio audibility, keyboard play, Safari and Firefox. Recommendation: use Godot's Web export, not a three.js port. The full report is `research/threejs_port_feasibility.md` (local, git-ignored).

**Owner items still open** (rows in TECH-001 §11.1, checked 2026-11-18; Q-T31 is closed and omitted):
- Q-T29: detonation shard count (3-5 vs 4-6).
- Q-T30: Act 0 Acolyte engagement range value.
- Q-T32, Q-T33: marquee strip/logo size; spawn distance, scanner and other Act 0 values.
- Q-T34: attract pages hidden at 200 % text until they move to the bezel.
- Q-T35..Q-T43: audio and doc-consistency questions raised by PR #8.

### M2 — Vertical slice (target 2027-04 ✱)
| | |
|---|---|
| Goal | the GDD-001 §17 slice, polished enough to sell the game |
| Exit criteria | GDD-001 §17 criteria 1–6, all measured: (1) 10/10 testers understand "the boss is being built from the same ore I need" unprompted; (2) median tester dies ≥ 2 times to the Awakening and retries immediately; (3) 0 input-latency complaints in mouse aim; (4) the twist is named unprompted by 6/10; (5) 60 FPS at internal 640×360 on minimum spec with T2 shaders; (6) a 15-second clip gets a "what is this?" from 5/10 non-players |
| Code | full Waking lifecycle at T1–T2; Acolytes + Litany Ring; Deceiver; Matron gate; Ruins hub with a 30-node Tree stub; 12 Run Sigils; 6 warp effects; WarpComposer T0–T2 (TECH-001 §5.1); Steady Ledger HUD pinning (TECH-001 §5.3); save cadence wired to `SaveService` (TECH-001 §7.2); warp lint as a CI step or the WARP-001 §6.1 D-11 manual checklist |
| Art | PM and OB kits used by the slice (§5), Acolyte, Deceiver, Matron, Ruins hub first pass, Act 0 cabinet costume layer (ART-001 §7), Ledger/Litany/Cabinet bitmap faces (ART-001 typography) |
| Audio | Act 0 chiptune; T1 bed + Choir chant stems for one biome; entity voice from the formant synthesiser (AUDIO-001 §11.3); the 1.2 s Awakening silence (GDD-001 §12) |
| Narrative | Act 0 text; the first Ruins scene (states the anchor diegetically, GDD-001 §6.2); slice Codex entries (`cx_choir_`, `cx_glass_`); the H2/H4/H14 eat lines (WARP-001 §6.1 D-10 tranche; NARR-001 §7) |
| Docs | TECH-001 §5.1–§5.4, §8.1–§8.2; UI-001 HUD section |
| Marketing | store page assets (MARKET-001 §4), announcement trailer (MARKET-001 §4.7) cut from slice capture |
| Risks | slice polish eats the content schedule → the slice is the *only* polished content until M4 |

### M3 — Performance & platform gate (target 2027-06 ✱)
| | |
|---|---|
| Goal | prove the warp and the bullet layer fit budget on minimum spec and Steam Deck before content multiplies (GDD-001 R-06) |
| Exit criteria | (1) GDD-001 §15 median frame time ≤ 8 ms at T2 on minimum spec; (2) T3 warp shaders inside SYS-001 §9's 1.2 ms warp budget; (3) the slice runs at 60 FPS on Steam Deck at the ×2 / 40 px bars case (TECH-001 §1.3); (4) TECH-001 §8 FrameBudget table filled with **measured** numbers; (5) decision recorded on the bullet layer: Area2D/ShapeCast kept, or quadtree started (TECH-001 §2.6, ruling R-17) |
| Code | profiling harness; ContactBudget enforcement (SYS-001 §9 caps, ruling R-14); shader tier variants; Deck input glyphs |
| Art / audio | generator render tests and frame cost at the on-screen caps (ART-001 §14.7); audio voice budget and boot-time generation check (AUDIO-001 §7.5, §11.5) |
| Docs | TECH-001 §8.1–§8.4 with measurements; ASSET-003 import presets verified |
| Risks | the warp misses budget → WARP-001 §5.3 refusal ladder, never a silent quality drop |

### M4 — Demo (target 2027-09 ✱)
| | |
|---|---|
| Goal | the MARKET-001 §6 demo: Act 0 complete + one Act 1 run (2 biomes), Ruins capped at tier 1 |
| Exit criteria | (1) ≥ 70 % of private-beta players finish A0-3 (GDD-001 §15 1.0 target); (2) "hook moment" named unprompted by 8/10 interviewees; (3) time to first understanding of the race < 60 s; (4) zero crash-to-desktop in 20 ✱ beta hours; (5) demo saves migrate into the full build (TECH-001 §7.3) — tested; (6) ending 5 (The Pretence Kept) is reachable in the demo and tested |
| Code | demo build flag; opt-in telemetry with invariant IDs; demo end card; crash reporting to development logs only |
| Art | Act 0 complete; PM + OB biomes complete for the run; capsule art final (MARKET-001 §4.1) |
| Audio | Act 0 and the two demo biomes final; entity Act 0–1 lines recorded (AUDIO-001 §4.1, §4.5) |
| Narrative | Act 0, the Cabinet's message (NARR-001, ending 5), demo Codex pages |
| Marketing | public demo, gameplay trailer, Next Fest plan (MARKET-001 §7) |
| Risks | the demo spoils too much → the demo shows H1 and stops at the first darkened sky (MARKET-001 §6) |

### M5 — Content alpha: Acts 1–2 (target 2027-11 ✱)
| | |
|---|---|
| Goal | every system in, Acts 1–2 playable start to finish, all 6 biomes at alpha art |
| Exit criteria | (1) all 32 kits pass the solvability lint (ZONES-001 §4.6); (2) the full 90-node Lantern Tree, 24 Pacts, 18 Relics and Run Sigil pool are in data with tests (LOOP-001 §3–§7); (3) Iterations, Hourglass Clock and Hard Unmaking work end to end, saving only at the SYS-001 §8 cadence; (4) runs per session ≥ 2.0 in a paid test round (GDD-001 §15 prototype target); (5) rage-quit events < 15 % (GDD-001 §15) |
| Code | macro map, Corruption, Hollow sectors; Entropy ladder; Herald counters; eaten-rule registry H2–H8 |
| Art | all biomes alpha; Rite bosses alpha |
| Audio | all biome beds alpha; chant system complete (AUDIO-001 §5) |
| Narrative | Codex classes complete for Acts 1–2 (NARR-001 §8); Ruins cast scenes through Act 2 (NARR-001 §5) |
| Docs | LOOP-001 §8–§14 implemented and cross-checked |

### M6 — Content beta: Acts 3–4 and every ending (target 2027-12 ✱)
| | |
|---|---|
| Goal | the game is complete; text lock |
| Exit criteria | (1) all 5 endings reachable and tested (GDD-001 §9.3, LOOP-001 §11); (2) all H-rules authored with tells and Codex entries; `TEST-H14-01` is a build failure, not a warning (WARP-001 §6.1 D-08); (3) Unmaking Rehearsal works and rotates (WARP-001 §6.1 D-09); (4) text lock: `en.po` passes L10N-001 §6 validation; (5) achievements (30, GDD-001 §2) defined and wired |
| Marketing | release date announced (MARKET-001 §13); D-07 price signed off |
| Risks | Act 4 is late → §7 cut order item 1 |

### M7 — Release candidate → 1.0 (target 2028-02 ✱)
| | |
|---|---|
| Goal | ship |
| Exit criteria | (1) zero known crash bugs; (2) GDD-001 §15 1.0 targets met or consciously waived by the owner in writing; (3) Steam Deck review submitted (claim nothing until it returns, MARKET-001 §10); (4) localized languages shipped only if their `.po` passed validation (L10N-001 §7); (5) save migration tested from demo and from every beta schema (TECH-001 §7.3) |
| Marketing | creator keys at launch − 2 weeks; launch trailer; G6–G7 GIFs released in launch week |

### M8 — "The Ninth Sky" free update (target 2028-05 ✱)
| | |
|---|---|
| Goal | the retention drop: daily **Hollow Vigil** (ruling R-16) plus one content addition |
| Exit criteria | (1) daily seed produces identical warp state on every machine (SYS-001 §10 seed contract, `ReplayVerifier` TECH-001 §4.9); (2) H14 never fires in a daily (WARP-001 §6.1 D-06); (3) leaderboard keyed by invariant IDs |
| Scope | daily mode, leaderboard, weekly cursed seed in-game, one Rite or biome variant, Codex page set, streamer mode if not shipped (MARKET-001 §8.2) |

---

## 4. The vertical slice (GDD-001 §17, restated as a checklist)

| Item | Source | Milestone |
|---|---|---|
| Act 0: A0-1, A0-2, A0-3 + first Unmaking cinematic | GDD-001 §6.1 | M2 |
| A 5-Seam Act 1 run, 2 biomes | GDD-001 §6.3; §5 below | M2 |
| Grubs, Acolytes, Deceiver | GDD-001 §8.5 | M2 |
| 1 Matron gate | GDD-001 §9.2 | M2 |
| Full Waking lifecycle at T1–T2 | GDD-001 §8.4 | M2 |
| 30-node Lantern Tree stub in the Ruins | GDD-001 §17 | M2 |
| 12 Run Sigils | GDD-001 §17 | M2 |
| 6 warp effects | GDD-001 §17; WARP-001 §2 | M2 |
| Eat tranche H2, H4, H14 with PACT-01/PACT-04 | WARP-001 §6.1 D-10 | M2 |
| Entity voice (formant synthesiser, AUDIO-001 §11.3) | GDD-001 §17 | M2 |
| 60 s polished | GDD-001 §17 | M2 |

---

## 5. Kit build order (ZONES-001 §3)

Kits are built in the order the player meets them, so every finished kit is immediately playable in a real run.

| Wave | Kits | Why first | Milestone |
|---|---|---|---|
| 1 | PM-01 First Vigil, PM-02 Dark Throat, PM-03 Twin Drift, OB-01 Over-Fire Gallery, OB-04 Buried Lantern | every Seam-1 kit (ZONES-001 §3.7): the slice cannot start without them | M1–M2 |
| 2 | PM-04, PM-05, PM-06, OB-02, OB-03, OB-05 (gate), OB-06 | Seam 2–3 coverage for the two slice biomes, plus a gate kit | M2 |
| 3 | LT-01…LT-06 | The Litany starts at Iteration 2 (ZONES-001 §2.2); first Choir-strong biome | M4–M5 |
| 4 | GR-01…GR-05 | Shroud-heavy; needs the Shroud system (SYS-001 §9) | M5 |
| 5 | DO-01…DO-05 | gravity anchors and verticality (ZONES-001 §5.2, §5.5) | M5 |
| 6 | BK-01…BK-04 | the hardest biome; tier-gated contents (ZONES-001 §3.7) | M5–M6 |

---

## 6. Dependencies on open decisions

| Decision | Blocks | Needed by |
|---|---|---|
| GDD-001 D-07 price ($19.99 proposed) | release-date announcement, store price field | M6 |
| GDD-001 D-08 one-hit hull A/B | Lantern Tree HULL branch tuning, difficulty KPIs | M2 (decide from M1/M2 test data) |
| TECH-001 §11.1 rows still open after the 2026-11-17 rulings | the systems they name | per row |
| Studio name / publishing route (MARKET-001 MQ-01) | store page | M2 |

---

## 7. Cut order (GDD-001 §16 R-03, extended)

Fired in order, one item at a time, only by the owner, each recorded in GDD-001 §18.

| # | Cut | Saves | Protects |
|---|---|---|---|
| 1 | Act 4 variants (keep one Unraveling arena, no rotation) | Act 4 art and scripting | the true ending still ships |
| 2 | Two biomes (The Black and Green Rot become post-launch) | ~9 kits + Shroud polish | the race and the warp |
| 3 | Six Herald elites → two | elite AI and art | Entropy still escalates |
| 4 | Ending 3's Choir mode stays post-launch (already planned) | — | — |
| 5 | ~~Localization moves to +1 month~~ — removed: English only (L10N-001 §1) | — | — |
| 6 | Daily Hollow Vigil moves later than M8 | leaderboard work | the update still ships content |

Never cut: Act 0 and the floor-drop, the Waking race, Steady Ledger and the accessibility set (GDD-001 §10), the save cadence rule (SYS-001 §8), ending 5.

---

## 8. Weekly cadence and definition of done

| Day | Ritual |
|---|---|
| Monday | plan the week against the current milestone's exit criteria; publish the weekly cursed seed once the Discord is live (MARKET-001 §9) |
| Daily | the CLAUDE.md §6 definition of done for every task: tests pass headless, boot smoke reaches the gameplay scene with no errors, owning docs updated, final report lists files/commands/what was not verified |
| Wednesday | one playable build, played by someone who did not make it |
| Friday | milestone burn-down; risk table review; devlog GIF captured (MARKET-001 §9) |
| Milestone close | exit criteria measured and recorded in this doc's §2 status column; WARP-001 §7.3 manual lint checklist until `warp_lint` is in CI (WARP-001 §6.1 D-11) |

---

## 9. Risk register (production)

| ID | Risk | Mitigation |
|---|---|---|
| PR-01 | One-person bottleneck on code and design | CLAUDE.md §5 delegation; strict milestone scope; §7 cut order |
| PR-02 | Content volume (90 nodes, 120 Sigils, 32 kits) outruns art | modular kit (ART-002); Sigils reuse Tree node art (GDD-001 R-03); kits are geometry + slots, not new art |
| PR-03 | The warp misses budget on Deck | M3 gate before content scale-up (GDD-001 R-06) |
| PR-04 | Narrative text volume arrives late and blocks text lock | eat lines and death grammar in M2; Codex by class per milestone; text lock at M6 |
| PR-05 | Demo underperforms at Next Fest | MARKET-001 §13.1: move the date, do not fire into a weak funnel |
| PR-06 | Save schema churn breaks demo-to-full migration | SaveEnvelope migrations (TECH-001 §7.3) tested from M4 onward |
| PR-07 | Owner decisions stall (D-07, D-08) | §6 "needed by" column; the producer raises each a milestone early |

---

## 10. Open documentation debt (as of 2026-11-17)

| Doc | Debt | Needed by |
|---|---|---|
| TECH-001 | §4.3, §4.4, §4.9, §5.1–§5.4, §6.3, §8.1–§8.4 subsections: headings and content exist (checked 2026-11-18); §5.x is designed, not built; §8 measurements still owed | M1–M3 |
| NARR-001 | §2–§14: headings exist (checked 2026-11-18; content depth not reviewed) | M2 for §7 eat lines; M5 for the rest |
| LOOP-001 | §8–§14: headings exist (checked 2026-11-18; content depth not reviewed) | M5 |
| ASSET-003 | pipeline doc exists (`docs/02-art/ASSET_PIPELINE.md`; retired raster pipeline per D-13, TECH-001 §6) | M1 |
| ART-001 | typography (§11) and UI-state (§12) sections exist (checked 2026-11-18) | M2 |
| SYS-001 | `ds_` key column per table (ruling R-03), new §9 cap rows (R-14) | as each table is touched |
| UI-001 | HUD section (DiegeticHud), rebinding and audio-options screens | M2 |
| AUDIO-001 | ten open questions (§10) | M2–M4 |
