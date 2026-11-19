# DARKSTAR — Game Design Document

**Working title:** DARKSTAR *(alt: DARKSTAR: The Nine Hollow Skies)*
**Doc ID:** GDD-001 · **Version:** 0.2.5 · **Status:** Draft for prototype · **Last updated:** 2026-11-19 (PM rulings Q-T146–Q-T150 under the owner autonomy grant, TECH-001 §11.1a: §7.1 Act 0 bank floor and tickets = Ember; §6.3 Run Sigil picks after Seams 1–3; §7.3 prices cite SYS-001 §7.7; §17 slice Tree and Sigils; §20 Q1 clock pauses per Q-T138) (2026-11-18: Act 1 vertical slice, PM ruling 2026-11-18 (owner grant): §6.1 A0-3 first Unmaking cinematic is in-engine, ≤ 90 s, agency 0 except a look-only Aether reveal (amended after The Reviewer's notes); §6.2 first-visit Hourglass exception; §7.1 Act 0 score banks once as Ember; source `research/act1_vertical_slice.md`, decisions in TECH-001 §11.2) (same-day reconciliation: keys 1 / 2 / 3 are rare Sigil quick-slots, PM ruling Q-B, §4.1, §19; §20 Q4 carries the D-04 amendment, PM ruling Q-A; §10 Flame Bearing, Act 4 Hourglass and L12 keys; §9.1/§9.3 Wrong Ruins restored by Ending 4) (cosmic horror design rev 3, PM ruling 2026-11-18 (owner grant), D-15: entity distance and set pieces per act in §9.1; the Waking from Act 2 and the Listener in §8.4–§8.5; the HUD and lie laws in §10; Relics fold into rare Run Sigils and Unwritten Ink retires in §7, §8.9 and §19; earlier: D-13/D-14 all graphics and sound generated in code; resolution closed to 640×360; §13 collision approach; §19 adds *sector*; §20 closed)
**Engine:** Godot 4.7.2 (GDScript) · **Platforms:** Windows first (Steam), Linux/Mac after launch
**Genre:** Retro-arcade shooter that mutates into a reality-warping cosmic-horror roguelike
**Controls:** Keyboard + mouse (WASD move, mouse aim) with full gamepad parity

---

## 0. How to read this doc set

| Doc | Path | What it answers |
|---|---|---|
| **This GDD** | `docs/01-design/GDD_DARKSTAR_v0.2.md` | What the game is, every system, how it all fits |
| Systems bible (numbers) | `docs/01-design/SYSTEMS_BIBLE_STATS.md` | Exact stat tables, spawn budgets, tuning constants, formulas |
| Roguelike loop & upgrade tree | `docs/01-design/ROGUELIKE_LOOP_AND_LANTERN_TREE.md` | Iterations, run structure, all ~90 upgrade nodes, pacts, endings |
| Reality-warp escalation | `docs/01-design/REALITY_WARP_ESCALATION.md` | The trippy effects, Warp Tiers 0–5, rules the entity can eat |
| Zone & encounter design | `docs/01-design/ZONES_AND_ENCOUNTERS.md` | Act-by-act zones, biome tables, encounter templates, bosses |
| Narrative & lore | `docs/01-design/NARRATIVE_LORE_BIBLE.md` | Fiction, factions, entity, endings, voice script |
| Art bible | `docs/02-art/ART_BIBLE.md` | Look, mood, palette, silhouette language, Lovecraft rules |
| **Sprite modularity spec** | `docs/02-art/SPRITE_MODULARITY_SPEC.md` | The 64×64 modular assembly system, naming, atlases, runtime mutation |
| Asset pipeline (generators) | `docs/02-art/ASSET_PIPELINE.md` | How every visual and sound is generated in code (D-13, D-14); the retired raster pipeline |
| Audio design | `docs/03-audio/AUDIO_DESIGN.md` | Soundscapes, the entity's voice as a game system, music escalation |
| Tech architecture | `docs/04-production/TECH_ARCHITECTURE.md` | Godot scene/code structure, data-driven design, shaders, saves, Steam |
| Production plan | `docs/04-production/PRODUCTION_PLAN_MILESTONES.md` | Milestones, vertical slice definition, backlog, risks |
| Steam & market plan | `docs/04-production/STEAM_MARKET_PLAN.md` | Positioning, comps, store plan, KPIs, launch checklist |
| Source research | `docs/00-research/REFERENCE_SINISTAR_SOURCE_MATERIAL.md` | What the 1983 original did, and our IP guardrails |

---

## 1. High concept

> **You are the last Lampkeeper in a system the universe has forgotten. Every run you mine the bones of dead gods, forge them into ward-bombs, and hunt the thing that is coming — and every run it eats another sky.**

DARKSTAR **opens as a 1983-style arcade shooter**: black space, one ship, asteroids full of glass, and a boss your enemies are secretly building out of the same glass you need. That shell is a *lie*. By the end of the first play session the entity wakes for good, eats the universe, and the game reveals itself as a **deep roguelike about unmaking a god** — with a ~90-node upgrade tree anchored in a hub that exists outside the time loop, escalating reality-warp effects that mutate the game's rules, art, UI and geometry, and an endgame where you attack the entity at the level of *the game's own logic*.

### Logline ladder
- **One sentence:** Mine the bones of dead gods into bombs, kill the boss your enemies are building — and when it eats the universe, learn to unmake it over dozens of time loops.
- **One paragraph:** The first twenty minutes are an homage: WASD-and-mouse flying, mining asteroids for Mourning Glass, feeding it into Null-Iron Charges, and a boss assembled piece by piece by chitinous Choir servants while a digitized choir chants *"IT WAKES"*. Then the rules start rotting. Asteroids become teeth. Your HUD lies. The boss remembers what you did last loop. Between runs you tend the Lantern Tree in the Ruins — a substantial upgrade tree that makes you stronger while the loop makes the Dark Star stronger — and the final act asks you to unravel the entity by dismantling the reality it feeds on: the game's own rules.
- **Elevator:** *Sinistar* × *Hades* × *Outer Wilds' dread* × *Patrick's Paradox*.

### The fantasy, in three layers (this is the product's spine)
| Layer | What the player thinks | When | Delivery |
|---|---|---|---|
| **L1 — Retro arcade** | "This is a tough old-school shooter." | 0–45 min | CRT cabinet framing, 1UP HUD, score chimes, one-hit hull, zone names |
| **L2 — Roguelike depth** | "Wait — there's a meta-progression? A tree? An iteration counter?" | 45 min – 12 h | Ruins hub, Lantern Tree, iteration clock, run seeds, pacts, builds |
| **L3 — Immersive cosmic horror** | "This game is *doing something to itself*. And to me." | 3 h – 60 h | Warp Tiers mutate art, UI, sound, geometry, rules; diegetic haunting; endings |

**Design rule:** never tell the player a layer is arriving. The game just *changes*, and the player discovers it the way a person discovers a house has extra rooms.

---

## 2. Product facts

| Field | Value |
|---|---|
| Target length | First loop 20–40 min · first "real" run 25–35 min · campaign to first true ending 18–25 h · completionist 60–80 h |
| Sessions | Roguelike: one run = 25–35 min; iteration = 4–7 runs / 2–3 h |
| Replayability | Permadeath-lite loop, seeded runs, ~90 upgrade nodes, 24 pacts, 6 biomes, 9 iterations, 5 endings, Entropy difficulty ladder (0–10), daily "Hollow Vigil" challenge |
| Player count | 1 (campaign); **coop is post-launch stretch goal, not in scope** (see §19 risk R-07) |
| Monetization | Premium, single purchase, no F2P, no monetized progression. Target $19.99 USD (see `STEAM_MARKET_PLAN.md`) |
| Rating target | ESRB T / PEGI 12 (cosmic horror, no gore, mild occult themes) |
| Engine / language | Godot 4.7.2 stable, GDScript, 2D renderer, custom canvas-item shaders for warp effects |
| Resolution model | **640×360** logical space; pixel-perfect integer scale, nearest filtering and the CRT shader apply to the **Act 0 arcade screen only**, which is a **256×304 portrait** grid (4 bpp, the Williams video circuit rotated 90°; owner 2026-11-18, replacing the 240×320 approval; colour limits TECH-001 §1.1) inside a native-resolution cabinet with no black bars at any aspect; the bezel and everything after Act 0 render at the display's native resolution (owner, 2026-11-18; 512×288 fallback struck 2026-11-17; TECH-001 §1.1) |
| Steam features (launch) | Steamworks: achievements (30), cloud saves, statistics, full glyph/rebind support, remote play, Deck-verified target, local co-op *not* at launch |
| Language | **English only** (owner decision 2026-11-17). Other languages are deferred, not scheduled (L10N-001 §1) |

---

## 3. Design pillars

**P1 — The boss is a countdown, not an arena.** Dread = watching the enemy complete its own win condition while you complete yours. Every system in the game (ore economy, Choir AI, the iteration clock) feeds that race.

**P2 — The enemy faction is a religion, not a spawn list.** The Hollow Choir *believes* in the Dark Star. Their behaviour, art and audio are all liturgical: they build, chant, mourn, sacrifice and convert. Killing them is interrupting a service.

**P3 — Reality is a difficulty setting you can see.** The entity warps reality, and the warp is *legible*: tiers 0–5 change palette, silhouette language, geometry, UI honesty and rules. The player always knows "how warped" reality is — because the game stops pretending to be normal.

**P4 — Progress is guaranteed, mastery is optional.** Losing a run still teaches (Codex entries, fragment counts, lore). Losing an iteration still keeps the Lantern Tree. The player cannot be soft-locked; the entity always advances too, so escalation replaces gatekeeping.

**P5 — Read as arcade, play as simulation.** Controls, feedback and framing stay instant and arcade-crisp (no camera drift, no input latency, no menu bloat), even when the systems underneath are deep. If a mechanic needs a tooltip, it is a design bug.

**P6 — Steam-friendly by construction.** Short legible sessions, build variety for streamers/clips, one obvious "hook" sentence, and a visible 30-second loop in any clip. Every warp effect must read in a 15-second GIF with no context (this is an explicit art/VFX acceptance criterion).

### Anti-pillars (what we will not do)
- No crafting grind, no survival meters, no energy bars on the main gun, no XP levelling inside a run beyond the run-tier boons, no open world, no bloat quests, no multiplayer at launch, no loot-box/RNG-only progression without a pity/choice system, no "git gud" difficulty without an escalation ladder the player can steer.

---

## 4. Controls, feel and camera (locked decision)

### 4.1 Keyboard + mouse (primary, non-negotiable)
| Input | Action |
|---|---|
| **W A S D** | 8-directional thrust: the ship accelerates in the pressed direction, decelerates when keys release (arcade-tuned, see below) |
| **Mouse (free look)** | Aim. The ship's lance always points at the cursor; the hull rotates 60% toward aim for readability |
| **Left Mouse Button (hold)** | Fire the Arc-Lance (mining + combat, one weapon) |
| **Right Mouse Button** | Deploy **Null-Iron Charge** (homing boss bomb; requires charges) |
| **Shift** | **Surgelight**: short afterburner impulse; also burns away "Shroud" growths that block space; costs Composure at Warp ≥ 2 |
| **E** | **Lantern toggle** (Lantern Up/Down): lights the surroundings (mining needs light at Warp ≥ 3; the Choir hunts your light). Hiding = the stealth-lite layer |
| **Q** | **Ward Pulse** (defensive: repels Choir, purges phantom contacts, clears 1 tile of Shroud; long cooldown) |
| **R** | **Unravel Focus** (endgame act only: latch onto exposed "rules" seams; the Act 4 mechanic) |
| **Space** | **Brake / Anchor** (kill inertia; needed for precise mining and to stop drifting into the entity) |
| **Tab / Right-click-hold on Ruins** | Codex, run summary, Lantern Tree |
| **Esc** | Pause (and later: the entity can *eat the pause menu* — see `REALITY_WARP_ESCALATION.md`) |
| **1 / 2 / 3** | Rare Sigil quick-slots (rare Sigils from active former Relics; action ids stay `relic_1`–`relic_3`) |

### 4.2 Movement model (tuned for arcade snap)
- `max_speed` 340 px/s (internal res), `accel` 2600 px/s², `drag` 3.4/s, `brake` 5200 px/s². Terminal drift ≈ 1.4 body-lengths of slide. Tuned so a full reversal takes 0.28 s — deliberately snappier than a Newtonial *Asteroids* feel, matching Sinistar's "dramatically responsive" reputation.
- **Snap-turn:** the hull sprite rotates toward aim at 720°/s, so the ship never feels like it is steering into its own fire.
- **Wraparound play-space:** the Pale Marches torus-wraps at the edges (Warp Tier 0 = classic arcade wrap; higher tiers change what wrapping *means*).
- **Camera:** player-centred, 0.12 s critically-damped follow, 24 px deadzone, 1.5% lookahead toward aim, screen-shake budget 4 px. Zoom 1.0 in Act 0; +6% at Warp 3, then a slow breathing zoom at Warp 5 (the universe expanding/contracting).
- **Scope (ruled, PM under owner autonomy grant, 2026-11-19; TECH-001 Q-T164):** the numbers above are the **Cabinet profile**. They and their 🔒 stay exactly as they are, for Act 0 only. After THE PRETENCE the Vigil flies the Aether profile (§4.2a).

### 4.2a Aether handling profile (ruled, PM under owner autonomy grant, 2026-11-19)

> **Status: ruled, PM under owner autonomy grant, 2026-11-19** (TECH-001 Q-T164–Q-T172, §11.1a; queued for the owner's later review). The numbers are in SYS-001 §1.1a as ✱ first-pass values, retuned at playtest.

**Intent (owner direction, 2026-11-19).** After THE PRETENCE the Vigil is no longer an arcade blip. It is a lantern skiff in a medium: heavier, slower, with a keel, and the pilot has a few systems to manage. The Lantern Tree shapes what the ship can do (LOOP-001 §3.8). Act 0 keeps §4.2 exactly. The model is *Sunless Skies*-style piloting (momentum, deliberate turns, light as a resource), as inspiration only: no names, art or content are taken.

**Two profiles, one motor.**

| Profile | Where it applies | Numbers |
|---|---|---|
| **Cabinet** | Act 0 (A0-1 to A0-5), on the Cabinet screen | §4.2 and SYS-001 §1.1, unchanged 🔒 |
| **Aether** | all flight after THE PRETENCE: sectors, Seams, the Waking | SYS-001 §1.1a ✱ |

The cinematic and the Ruins have no flight (M2 slice beats 1–11). The Ruins pilot-lamp cursor is not covered by either profile.

**What the pilot feels in the Aether.**
- **Weight.** The top speed is about two-thirds of the Cabinet's, the ship takes longer to reach it, and it coasts a long way. A full reversal takes about three times as long as in the Cabinet. You plan a line instead of jinking.
- **A keel.** The hull has a heading. WASD still says where you want to go (D-01 unchanged). The hull swings toward that direction at a limited turn rate, and thrust is strongest along the keel and weaker sideways and backwards. A turn is something you commit to.
- **The gun stays precise.** The Arc-Lance sits on a turret at the lamp and still tracks the mouse at the §4.2 snap-turn rate. The ship is heavy, but the aim is not, and a hit never depends on the hull's heading.
- **Space is the anchor.** Braking is the pilot's main skill. It bleeds momentum hard but not instantly, and afterwards the ship has to spin up again.

**Systems the pilot manages.** There is no new resource and no new HUD meter. Each system is built from an existing noun:
1. **The keel** (heading and momentum). This is not a resource. It is a physical state, shown by the hull itself: its heading, the lantern's swing, and the wake in the fog.
2. **Lantern state as the drive's flame.** The lamp feeds the drive. Lantern Up gives full thrust. Lantern Down is running dark: weaker thrust and lower drag, so you glide quietly. E becomes a handling decision as well as a light decision, with no new input. It sits on top of the §8.1 trade (mining, detection) and matches the Passing counterplay: lantern down, stop firing, ride the drift.
3. **Surgelight as the escape valve.** With heavy handling, Surgelight is the one burst that beats momentum. Its stored charges and cooldown (LOOP-001 LANTERN-1, -6, -7, -16) become the system you watch. Its Composure cost at T ≥ 2 is unchanged.
4. **No change** to Composure, Null-Iron Charges or the Arc-Lance. There is no lance heat, fuel or ballast gauge: LOOP-001 §3.3 ORDNANCE rules out a lance fuel bar or reload meter. Ballast stays what it is, a Run Sigil (SIG-H-02), not a gauge.

**Readability at the slower pace (bullet-hell and *Returnal*-style clarity).**
- **The hitbox does not grow.** `ds_vigil.move.hitbox_circle_px` 🔒 (TECH-001 Q-T04) stays as it is, even though the Aether hull art is larger (ART-001 §16.7): a big brass ship with a small, honest core.
- **Threat speed scales with the ship.** In Aether sectors, Choir projectile speeds take a profile multiplier (SYS-001 §1.1a). Telegraph times are never shortened. The multiplier only partly closes the gap in the dodge window. Coasting (you are usually already moving) and Surgelight cover the rest. Playtest decides it (Q-T168).
- **The race still holds.** The Aether `max_speed` stays above the Grub flee speed (SYS-001 §3), so a Grub can still be run down, but it takes a planned line and often a Surgelight.
- **Momentum is always drawn.** The lantern swings on its gimbal against acceleration, the wake trails in the fog, and the brake throws HULL-3's chalk ring. The player sees where the ship *will* be, not only where it is.
- **The camera leads the velocity** as well as the aim, so a fast coast shows what is ahead (SYS-001 §1.1a, ✱).

**The change of feel lands as a beat.** The Cabinet's snap was the lie, and the weight is the truth. The cinematic and the Ruins have no flight, so the first Aether flight is the launch into PM-01 (M2 slice beat 12: the same layout as A0-1, now a place). The Vigil leaves the hangar already coasting, lamp swinging, with input live, and the first key press shows the weight. There is no text and no tutorial. The player's own hands tell them the ship was never a blip: first recognition (*I know this ship*), then difference (*it has weight now*). No engine sound is added (AUDIO-001 §12.4 forbids locomotion cues). The cue is visual (the lamp's swing, the wake), plus light controller rumble on thrust and braking (Q-T172).

**Controls.** No new input action is proposed. The §4.1/§4.3 bindings and `tests/test_input_map.gd` stay unchanged. What changes is what the keys mean. In the Aether, WASD sets the wanted heading and thrust instead of direct 8-way thrust, and the hull no longer "rotates 60% toward aim" (§4.1): it follows the keel, while the lance turret follows the aim. Ruled (Q-T166): the keel model, with this paragraph as the Aether reading of §4.1. Rotate-and-thrust controls (W thrusts, A/D turn) were rejected because they would change §4.1/§4.3 and the spirit of D-01.

**D-08 stays open and switchable.** The profile touches movement only, never `ds_vigil.hull.max_hp`. A heavier ship makes a one-hit death cost more, so the D-08 A/B should also be run on the Aether profile (Q-T171).


### 4.3 Gamepad parity (Steam Input + native)
- Left stick move, right stick aim (twin-stick), RT lance, LT charge, A surgelight, X lantern, B ward pulse, Y unravel focus, LSB brake.
- Mouse-vs-stick parity goal: aim latency < 3 frames at 120 Hz; auto-aim assist (aim snap to nearest 15° within a 40 px cone) for stick users, off for mouse.

---

## 5. The moment-to-moment loop (30-second core)

1. **Scan** the sector: which geodes hold Mourning Glass, where the Choir's processions are heading, where the **Sepulchre** (build altar) is.
2. **Mine:** shoot geodes to shatter them into **Mourning Glass shards**; collect them (auto-magnet at 96 px, or the ship's "Hookline" upgrade).
3. **Race:** Choir **Oubliette Grubs** steal the *same* shards to build the Dark Star. Every shard you take delays the god; every shard they take delays you.
4. **Fight or evade:** **Acolytes** (turret-bearing warriors) hunt you and *also* mine. Kill them for score/charges, or break line of sight.
5. **Convert:** shards become **Null-Iron Charges** in your magazine (max 5 base, 13 to kill a complete entity).
6. **Hunt the build:** fire charges at the *partially built* entity to knock pieces off (interrupt, damage, extend its build time) — or ambush the Grub procession to cut the supply.
7. **Manage the intangibles:** Composure drains near the Choir and near the truth; the Lantern is a beacon; Surgelight spends safety for speed.
8. **Bank:** kill the entity → **Unravel Fragments**, Codex entries, warp advance → warp to the next Seam (or the run's boss gate).

**Feel target:** the player should be doing 3–5 meaningful decisions every 10 seconds, and 1 decision every 1.5 seconds is *tactical* (dodge, shoot, mine, boost).

---

## 6. Session and meta structure — from arcade to roguelike

### 6.1 Act 0 — "The Last Normal Day" (the arcade on-ramp, a five-stage shift, ~9–11 min skilled, hand-authored)
Five hand-built levels in a fake cabinet frame (scanlines, "INSERT CREDIT" attract mode, 1UP/score HUD, chiptune). PM ruling 2026-11-19 (delegated owner authority; TECH-001 §11.1 Q-T104): the shift replaces the three-level plan; per-stage counts are SYS-001 §1.6. After GAME OVER the next coin offers CONTINUE?, which restarts the current stage (score 0, starting lives); the reveal is never gated on arcade skill. A mid-shift stage end (A0-1 to A0-4) shows only the stage banner, no credit roll (PM 2026-11-19, Q-T131; a per-stage tally card is planned in place of the banner); only the last stage rolls the credits and the service record, the first credits anyone sees, then THE PRETENCE.

| Level | Teaches | Twist |
|---|---|---|
| **A0-1 First Vigil** | WASD+mouse, mining, shards→charges, Grubs, one-hit death | The Sepulchre is *cold*: the entity never wakes; you win "easily" and the cabinet congratulates you |
| **A0-2 Second Vigil** (the Drift) | Acolytes/turrets, charge interception, Guard phase, mini-map (Ledger Compass); a Grub-heavy stage | Grubs start stealing your shards; the first chant line is heard under the music; still cold. Pressure: slow Acolyte reinforcements, geodes drifting in, Grubs that snatch loose glass. Look: dim dashed current lines drift across the sky |
| **A0-3 Third Vigil** (Censer Watch) | An Acolyte-heavy stage; the first full Waking (the entity wakes and must be unmade) | The Sepulchre is no longer cold. Pressure: slow Acolyte reinforcements (the censer bells stop once the Sepulchre wakes), and Acolytes escort laden Grubs. Look: censer chains hang from the top of the view |
| **A0-4 Fourth Vigil** (the Shoal) | A geode-rich stage; the Waking again, with more glass to mine | The cabinet is not getting easier. Pressure: the peak of the shift: geodes drift in fast, Acolyte bells ring often, Grubs keep coming after the wake. Look: schools of glass motes swim behind the stars |
| **A0-5 Last Normal Day** (Stillwater) | Warp to new zone, full Waking lifecycle, run the entity, kill a complete entity | Pressure: scarcity, not pressure: no bells ring and geodes only trickle in (slowly, and only while fewer than half remain), and Grubs keep stealing glass after the wake (SYS-001 §1.6 has the numbers). Look: a still horizon line with faint ripples below. You kill it… and the credits roll (the first anyone sees). Then, with no words, **the skin decays** (*the Decay*; owner direction 2026-11-19, design ruled by the PM under the owner autonomy grant 2026-11-19 (TECH-001 Q-T180–Q-T185) and built): the machine tries to go back to attract, but its phosphor tires, its colours drift, its music sags flat and its hum fails; its bezel bleaches and peels and its bulbs die, and where the print wears through there is light behind it, not wood; the picture collapses to a dot, and the tear opens from it (WARP-001 W0-07; ART-001 §12.7b; AUDIO-001 §12.18; SYS-001 §9 `ds_cabinet.decay.*`). **There is no title card.** The words *THAT WAS A PRETENCE.* are the last screen in the Cabinet's ROM; only ending 5 shows them (§9.3; NARR-001 §9.5). The entity arrives permanently — Act 0's "boss" was its *shadow*; the real Dark Star was already awake. **The universe is eaten: first Unmaking cinematic (in-engine, ≤ 90 s from the tear to black, agency 0 except look-only during the Aether reveal — the mouse tilts the parallax slightly, with no gameplay effect — unskippable once, skippable after).** (PM ruling 2026-11-18 (owner grant), Act 1 vertical slice, amended after The Reviewer's notes: in-engine, agency 0, look-only reveal. Look-only is not gameplay agency; WARP-001 W0-07 is unchanged.) |

**Purpose:** pure nostalgia bait, complete mastery of the base verbs, and then the emotional floor drops out. This is the hook that makes the Steam clip: "I beat the arcade game and then it ate the universe."

### 6.2 The Iteration (the time-loop macro layer)
- The system has **Nine Hollow Skies**. Each sky is a *layer of reality* the Dark Star swallows. The **Hourglass Clock** (a persistent, real-time budget of **120 loop-minutes per iteration** at Entropy 0 — each ninth of it spent darkens one sky mid-run, and only the ninth sky ends the run, LOOP-001 §6.5; it runs during runs and during the Ruins, but pauses while you read the Codex) is the visible countdown: when it hits zero, the next sky goes dark, the run ends, the Ruins shift, and the entity gains a permanent **Hunger** modifier.
- **Every time you "win" a run you buy time**, not permanent safety. Every time you die you *spend* time (10–18 min) — but you keep everything banked outside the loop (see §7).
- **The Eating of a Sky** (cosmic horror design rev 3): after Act 0, every ninth-sky close and every Hard Unmaking is a *playable sector*, not a cutscene. The entity eats the sky in order of beauty (the biome's Presence, the crystal sphere, the fog's colour, the stars, the Choir's lamps, the geodes), and the player's own light goes last. The player can't stop it; they can keep their lantern lit to the end. The first Unmaking cinematic (§6.1) stays as Act 0's (WARP-001 §1.7; LOOP-001 owns the Hard Unmaking beat).
- After **nine skies**, the universe ends: **Hard Unmaking** ends the iteration. You do not lose your Lantern Tree. You lose your run, the map changes forever (new biomes/boss aspects appear that could not exist before), and the entity is one **Revelation** closer to being unravelable. *This is the design trick that makes failure forward-moving:* losing to the clock is a story beat that unlocks content.
- The **Lantern Tree, the Ruins and your Codex are "anchored"**: they exist in a pocket that the loop cannot touch. That is the in-fiction justification for meta-progression, and it is stated diegetically in the first Ruins scene (no UI lecture).
- **Exception (first Ruins visit only):** the Hourglass Clock starts at the first launch, not on arrival; Sable's chalk says so ('The sand starts when you leave.'). (PM ruling 2026-11-18 (owner grant), Act 1 vertical slice; SYS-001 §6; NARR-001 §5.7.)

### 6.3 The run (roguelike body, 25–35 min)
- A run = **5 Seams** (procedurally assembled zones from authored encounter kits) + a **Hollow Vigil** gate encounter (mini-boss) at Seam 3 + the **Waking of Nhael'Gharoth** end encounter at Seam 5.
- Runs are **seeded** (daily/weekly seeds, plus "cursed seeds" shared as 12-character codes on the Steam community page).
- Inside a run you choose **1 of 3 Run Sigils** after Seams 1–3, and Seam 4 offers a rare Run Sigil instead (LOOP-001 §4.1; SYS-001 §7.2 `Run-Sigil picks`; TECH-001 §11.1a Q-T147) (the roguelike build layer: fire rate, ore magnetism, charge homing behaviour, ward radius, ghost-on-death, etc. ~120 pool entries). Seams 2, 3 and 4 may also offer **rare** Run Sigils: the 18 former Relic designs, folded in on 2026-11-18 (D-15; LOOP-001 §4).
- **Death:** you respawn in the Ruins with everything banked; the "cause of death" screen is diegetic — the entity narrates what it learned from you (it *remembers your most-used tool* and deploys counters next run: see P1, §8.5 Herald counters and AUDIO-001 §4.11).

### 6.4 The Ruins (hub between runs) — the upgrade home
The Ruins are the **Ruins of the Ninth Sky**, a half-eaten cathedral-observatory that exists in the scar left by the last universe. It is where the **Lantern Tree** grows, the **Codex** is read, and the **Chalk Desk** crafts one **Pact** per run.

**Escalation contract (design promise):** as the Dark Star grows stronger through the loop, the Lantern Tree grows taller through *you*. Every iteration adds visible new branches; the hub physically changes (ruins become a cathedral becomes a lattice becomes an unlit room). The player should always feel: *I am the only thing in this system that gets stronger.*

---

## 7. The Lantern Tree (between-run upgrade tree)

Full node list lives in `ROGUELIKE_LOOP_AND_LANTERN_TREE.md` (90 nodes + 24 pacts; the 18 former relics are now rare Run Sigils, §6.3). Summary:

### 7.1 Currencies
| Currency | Earned by | Spent on | Persists through |
|---|---|---|---|
| **Ember** (power) | score milestones, Seam clears, Choir elites, Shrine purges; the Run Sigils that paid Ink now pay Ember (amounts owed, LOOP-001) | Lantern Tree *branch tier* unlocks and nodes; respec. **After the tree:** relighting the Ruins (a fixed list of lamps and windows, one spend each at a rising price) or rekindling one chosen death-site Penitent (ZONES-001 §4.5; at most one per kit, it stays lit through Hard Unmakings). Cosmetic and memory, never power (prices owed, LOOP-001) | death, Hard Unmaking |
| **Fragments of Unraveling** (endgame) | entity kills at high Warp Tier, iteration completions | the 5 **Threads of Unraveling** that gate the final act | everything (even the loop) |
| **Mourning Glass / Charges** (run-only) | mining in-sector | nothing outside the run | never |

**The Act 0 bank.** The Act 0 Vigil Index banks once as Ember at the first Ruins visit, via SYS-001 §7.1's score→Ember formula with a floor, so a first tier-1 node is always affordable and the first launch can never soft-lock (one rule, no special cases; TECH-001 §11.1a Q-T146). The wall Cabinet pays out in tickets: a ticket is the physical form of Ember, 1 ticket = 1 Ember (Q-T148). PM ruling 2026-11-18 (owner grant), Act 1 vertical slice; floor PM 2026-11-19 (owner autonomy grant); SYS-001 §7.1 row "Act 0 bank"; NARR-001 §5.7.

**Rule nodes are known, not bought** (D-15, retiring Unwritten Ink). The 27 rule nodes once priced in Ink (changes to how the game plays: ore physics, charge homing, respawn rules) cost 0 Ember and unlock by *knowing* one Codex entry each (§8.9; the node → entry map is LOOP-001's, the entries NARR-001's). Every gating entry also has a deterministic backstop, whichever comes first: tier-1 entries are stamped after run 3 and tier-*t* entries at the start of Iteration *t*; and each death stamps the oldest pending gating entry, lowest tier first. The tier-unlock rule, nothing-rolled and the pity rule are unchanged.

### 7.2 Five branches (each 18 nodes, tiered 1–5)
1. **LANTERN (light/mobility):** surgelight charges, light radius, *Dark Lantern* (hide from Choir), *Blackout Dash*, *Phosphor Trail* (damage trail).
2. **HULL (survival):** plating (first hit absorbed), *Second Vigil* (one revive per run), drift control, brake radius, *Anchor* field that freezes nearby Choir briefly.
3. **ORDNANCE (weapon/charges):** lance rate/pierce, *Hookline* ore magnet, charge capacity, *Twin Vigil* (a second charge-capacity upgrade may stack in one run; paired Charge fire is the Run Sigil *Twin Flint*), *Homing Song* (charges curve harder, but Choir can hear them), *Shatter Shot* (shards ricochet).
4. **WARD (defence/utility):** Ward Pulse cooldown/radius, *Salt Glass* mines, *Silence the Choir* (interrupt Sepulchre building), *Deconsecrate* (collapse a converted Shrine; in Sepulchre phase 2 it destroys an outer Litany Ring node instead, §8.4, Q-T121), *False Lantern* decoy.
5. **MADNESS (risk/power, the "warped" branch):** spend Composure for power — *Clear Eyed* (spend 1 Composure to fully cancel a Warp Tier effect on yourself for 20 s), *Blessed Fracture* (+30% damage per Warp Tier), *Communion* (hear the entity's next move), *Unravel Focus* unlock. **This branch is how players "lean into" reality warp instead of resisting it — the intended endgame power curve.**

### 7.3 Node philosophy (roguelike best-practice baked in)
- Every node must be *legible in one line* and *visible in play*, not just in a stat sheet (e.g. not "+8% damage" but "lance shots now pierce the first Acolyte they hit").
- ~30% of nodes are **rules-bending** rather than numerical (this is the depth that makes the retro shell feel deceptively deep).
- **Pity/choice:** nodes are purchased, not rolled. Run Sigils are choose-1-of-3 with a reroll purchasable in-run. Node prices by tier and the reroll ladder are SYS-001 §7.7.
- **Respec costs 10% of banked Ember** (D-15; was Ink; never gates progress; it is a convenience tax).

### 7.4 Difficulty escalation (both directions)
- **Entropy ladder 0–10** (unlocked by iteration/ending progression, not grind): each level adds one named modifier (more Grubs, faster Sepulchre, Choir counters your tool, geode yields drop, entity repairs faster, HUD becomes unreliable…). Entropy is *player-selectable* and rewarded (Ember multipliers), giving Steam completionists something to chase and streamers something to flex.
- **Hunger (entity-side, automatic):** each Hard Unmaking permanently raises the entity's **Hunger** (speed, HP, counter-behaviour, and one new "eaten rule" per two levels). This is our version of Sinistar's own lore line — *"growing stronger with every destruction"* — made mechanical and *narratively honest*: the boss's resume is the story. Hunger is also *seen*: from the First Absence (§9.1) on, the stars lost across the Chronicle stay out, so each Iteration's sky has fewer.

---

## 8. Core systems

### 8.1 The Vigil (player ship)
- One-hit death at Warp Tier 0 (arcade integrity). Tree nodes and Run Sigils add survivability; **the default run stays one-hit**, so power comes as *avoidance and information*, not HP bloat. This keeps the Dread intact.
- **Lantern state (E):** Up = light radius 260 px, full mining speed, Choir detection range +180%. Down = dark, mining slowed 35% (impossible below Warp 3 without the *Dark Lantern* node), Choir detection −60%. The entity's Sepulchre only lights itself, so a dark player can steal shards from right under a Choir procession — the "hold your breath" moment.
- **Composure (sanity, 0–10):** see §8.6.
- Visual language: small brass-lantern skiff, 48×48 core inside 64×64 canvas; 4 module slots visible in art (bow, flanks, stern) so upgrades *appear on the sprite* (modularity spec §6).
- **Aether handling and look (ruled 2026-11-19, Q-T164–Q-T172):** after THE PRETENCE the Vigil flies the heavier Aether profile (§4.2a). Its art grows into a brass lantern skiff whose modules show Lantern Tree upgrades (ART-001 §16.7, ART-002 §4.1). The hitbox does not grow.

### 8.2 Arc-Lance (one gun, two jobs)
- Single weapon (no weapon-swap bloat): 6 shots/s base, 14 px projectile, 1 hit, 0.9 s to shatter a small geode face.
- Mining: geodes take damage; **over-firing detonates** them (Sinistar's rule) releasing 4–6 shards at once (SYS-001 §1.3; Q-T29, PM 2026-11-18) but scattering them (risk: Grubs get more of them). This is a *skill expression*: calm fire = controlled shard drop; panic fire = confetti for the Choir.
- Lance modes come from upgrades/pacts (ion beam, chalk-shot, glass shard shotgun), never from picking up guns.

### 8.3 Mourning Glass and Null-Iron Charges
- **Shards:** float with drift, magnet 96 px (upgradeable), each collected shard = 1 **Charge** up to magazine cap (5 base, 7/9/13 via tree+sigils). Score 200/shard (Act 0).
- **Null-Iron Charges (RMB):** fire-and-forget, home toward the entity (or its nearest completed piece) at 210 px/s, 1.6 s turn authority; **interceptable** by Grubs, Acolytes and geodes (Sinistar's rule, kept). Detonation does 1 **Unravel hit** to the entity; the entity needs **13 hits** when complete, fewer if pieces are still missing.
- **Charges are precious and visible:** a HUD "lantern magazine" of 5 glass-lamp pips. Losing a charge mid-flight to an interceptor is an *audible, felt* loss (glass chime + the Choir chants a half-note).

### 8.4 The Dark Star — the Waking lifecycle (the spine of every encounter)
Formal name **Nhael'Gharoth, the Waking Dark**; the Choir sings it as **"the Hollow King"** or **"the Star That Failed"**. It is *never* present at the start of a sector. Phases:

| Phase | Name | What happens | Player's job | Counterplay |
|---|---|---|---|---|
| 0 | **Seed / Cold Sepulchre** | A **Sepulchre** (altar of fused vertebrae) exists in-sector; the entity's *will* is a black punctum visible at the edge of the Ledger Compass | Locate it, decide whether to contest | *Salt the Sepulchre* (Pact/upgrade: place a ward that blocks one deposit) |
| 1 | **Procession** | Grubs carry shards to the Sepulchre. Each deposited shard = 1 segment point; **3 shards complete 1 of the 20 segments** (SYS-001 §2; see modular art: 20 × 64×64 modules). Chant rises | Kill processions, steal shards, hit deposits; a Charge hit on the Sepulchre knocks **1 segment** off (SYS-001 §2) | *Silence the Choir* (ward interrupts deposits for 4 s) |
| 2 | **Guard** | Acolytes form a **Litany Ring** around the Sepulchre; they mine too | Break the ring, ambush, use darkness. A Charge hit still knocks **1 segment** off; living ring nodes intercept Charges like Acolytes, but a broken ring (4+ nodes down) does not (SYS-001 §2, TECH-001 Q-T121) | *Deconsecrate* destroys an outer ring node (in phase 2 only; elsewhere it collapses a Shrine, LOOP-001 WARD-10) |
| 3 | **Quickening (≥12 segments)** | The structure *twitches*; ambient audio changes; the Ledger Compass begins to lie; a whisper line plays | Decide: pre-kill now (fewer hits, but weak guard) or wait | Charges damage pieces and can knock 1–3 modules off (500 pts each, Sinistar's "Sinistar piece" score). Before this, in phases 0–2, a Charge knocks 1 segment off per hit (SYS-001 §2; Q-T121) |
| 4 | **AWAKENING** | At 20/20 segments, the entity completes. **The Choir's chant cuts to silence, then the first line.** In Act 0 the line is the game's thesis: **"IT WAKES."** (see AUDIO doc for the full line set — original, not the 1983 lines) | Survive, buy time, protect charges | The Awakening is *staggerable* if you land 3 hits in the 3 s window (hard, high-skill, huge payoff) |
| 5 | **Rampage** | It **chases and kills on contact** (no weapons — Sinistar rule kept, and it is the right choice: contact death turns the boss into terrain). It **eats geodes, shrines and Choir units** to heal. Voice lines telegraph its state and target | Kite, break line of sight with its *gaze* (see 8.6), land the 13 hits | Its gaze tracking is a cone; hiding your lantern breaks acquisition at Warp ≤ 2 |
| 6 | **Unravel (Act 3–4 only)** | Exposed **rule-threads** appear on its body; **R: Unravel Focus** latches and pulls threads. 3 threads = the entity is *unmade*, not killed | Fight inside the warp itself | Pacts can pre-attach threads |

**Failure state of the encounter:** if you don't kill it, the sector goes **Hollow** — the entity eats the sector, the Ledger Compass loses it, and the run continues with a *permanent entity patrol* in that biome (Hunger +1). This is Sinistar's "repair" pressure generalized into a consequence.

**The Waking from Act 2: seen by subtraction** (cosmic horror design rev 3; Seam 5, Act 2+; Act 1 keeps the table above). The phases and numbers stay (SYS-001 §2: 20 segments, 13 Unravel hits). What changes is how it is seen and how it attacks. The entity is never fully seen (NARR-001 §3.4 N-rules; at most SYS-001 `Entity max on-screen silhouette` on screen).
- **Seen as missing Aether:** the assembled segments draw as Aether that isn't there, with fog lit from behind and stars cut out. The Boiling Rim (WARP-001 W2-07) is its only lit edge. The camera never frames it whole.
- **From T3, gaze:** its Unravel points (where Charges count) show only while the aim cursor rests inside its silhouette for SYS-001 `Gaze reveal time`. While it does, Composure drains at SYS-001 §1.5 `Gaze Composure drain`: looking at the god costs your nerve. Points stay marked for SYS-001 `Gaze mark hold` after you look away.
- **From T3, Glimpse:** each Charge that hits rim-lights a stretch of its edge (SYS-001 `Glimpse radius`) for at most SYS-001 `Glimpse duration max`: soft, silent, eased, inside the WARP-001 §4.5 flicker cap. A reveal the player caused, never a startle. Players piece the shape together across runs, never in one frame.
- **Subtraction attacks:** *lanes* (bands of absence that sweep the field slowly; short Passings that subtract what is lit, WARP-001 §2.7), *motes* (true-black projectiles with luminous rims, in tide patterns), and from Act 3 *recollection* (patterns built from the player's own movement telemetry, so it fires where you usually are). It moves like a tide, never like an animal.
- **Two clocks, read by light:** the Rite clock is the Litany Ring, its nodes (SYS-001 §2 `Litany Ring`) burning as lamps; the entity's build is how much Aether is missing. No new numbers on screen.

### 8.5 The Hollow Choir (enemy faction catalog)
Full AI state machines and HP/damage in `SYSTEMS_BIBLE_STATS.md`. Art: all built from the **modular 64×64 part kit** (see art docs), which is how the Choir can be *mutated by the warp at runtime*.

| Choir unit | Sinistar analogue | Behaviour (1-line) | Threat |
|---|---|---|---|
| **Oubliette Grub** | Worker | harmless chitinous larva; carries shards to the Sepulchre; panics in the dark; swarms your corpse | indirect (builds the boss) |
| **Acolyte (Censer Knight)** | Warrior | pale knight with a **rotating censer turret** that swings to face you; mines geodes; guards the build | high (accurate shots) |
| **Deacon of Lies** | *new* | casts "phantom" Grubs/Acolytes (harmless, drain Composure), mimics your own ship at Warp ≥ 3 | psychological |
| **Grave-Tide Deceiver** | (Devious) | steals **Charges** from your magazine by baiting you into firing at decoys; flees with them to feed the Sepulchre | economy attack |
| **The Penitent** | (Bonus ship) | a weeping, friendly apparition that drifts through danger; shooting it grants a **Vigil Boon** (temp shield / free charge / 10 s silence of Choir chant) | risk/reward toy |
| **Choir Matron** | *new* (mini-boss) | births Grubs in waves; her **Litany** accelerates deposits; must be silenced not killed (kill makes the chant *stop*, which enrains the sector) | Seam-3 gate |
| **Herald of the Failed Star** | *new* (elites, 6 named) | Entropy-gated variants with hard counters to your most-used tool | scripted duels |
| **The Listener** | *new* | blind, hunts by *your gunfire*; forces silent play (mine slowly, use ward). At T3+ it also hears the **Lantern hum**: a lit Lantern is audible to it as well as visible to the others | stealth pressure |

**Faction rules that make the Choir feel like a religion (cheap to build, huge identity win):**
- Grubs never attack; they *flee* your lantern, and they *mourn* (a small audible keening) when a deposit is destroyed.
- Choir units stop firing within 120 px of a **Shrine** (sacred space) — you can hide in a shrine, but using your weapon near one converts a geode to a shrine (Corruption).
- Acolyte turret physics: the turret lags 0.25 s behind the body's turn (visible in art: the censer swings), so leading your own movement beats them — a teachable, telegraphed tell.
- Chant audio is **diegetic and positional**: you can hear a procession around a corner. The Choir is a *sound design* mechanic.

### 8.6 Composure (the sanity layer, done as a *resource*, not a punishment)
0–10 meter. It is **not** a death clock — it is a lever the entity pulls.
- **Drain:** being seen by the entity's gaze (+1/s), standing in the chant radius (+0.5/s), Warp Tier passive (+0.1/s per tier), losing Charges (−0.5), dying (−2 next run), and from T3 your own gaze at the entity in the Waking (SYS-001 §1.5 `Gaze Composure drain`, §8.4).
- **Regain:** destroying a Shrine, killing a Matron, flying in darkness for 5 s (Lantern down, no fire), Codex reading in Ruins (full restore).
- **Effects by band:** 10–7 clear; 6–4 **Frayed** (minor: audio false-cues, phantom Grubs, chromatic edges); 3–1 **Unmoored** (moderate: mini-map lies, one control axis inverts for 4 s bursts, phantom geometry); 0 **Hollowed** (severe: forces a **Warp Tier +1** for the sector, one free death, and the Choir can see you always — but *MADNESS branch* effects double, so it is a **build choice**, not a punishment).
- **The design inversion:** at high Warp Tiers, **low Composure is a power source** (MADNESS branch scales with Fray). The endgame asks players to *choose* madness to unravel a god. This is our answer to "go nuts with trippy effects" while keeping it *mechanically honest*.

### 8.7 Reality Warp Tier system (the trippy layer — summary; full detail in `REALITY_WARP_ESCALATION.md`)
Six tiers, driven by (a) iteration count, (b) sector consumed, (c) player's Composure, (d) Entropy.

| Tier | Name | What the game looks like | New hazards / rules |
|---|---|---|---|
| **T0** | Pretence | Clean 1983 arcade: **neon** palette on a black vacuum (the lie: space is not empty, ART-001 §16), flat vector sprites, CRT, honest HUD, no lighting | none (Act 0 only) |
| **T1** | Frayed | palette desaturates + 3 "wrong" hues; sprites breathe; parallax layers arrive | phantom Grubs, geodes look like teeth, chant under music |
| **T2** | Bleeding | palette split (bioluminescent/bruise), Shroud growths tile the field, sprites gain extra limbs via **modular part swapping** | Shroud (hazard terrain), Choir conversions of geodes into Shrines |
| **T3** | Unbound | geometry mutates: non-Euclidean corridors (screen edges connect to *other* edges), camera drift, HUD elements migrate or lie | edge-warp roulette, false mini-map, gravity inversions |
| **T4** | Inverted | the arcade shell slips: the background is *inside your ship*; enemy sprites re-skin as mundane objects (a lamp, a face, a window); UI text corrupts | the entity can eat one UI element per sector; rules flip (e.g., Grubs can now hit you; your dark light hurts them) |
| **T5** | Unmaking | the game visibly deconstructs: chunked reality, sprite "ribs", the CRT curvature becomes the entity's iris, silence | the entity can eat a *rule* (wrap, magnetism, one weapon mode); Act 4 arena |

**Acceptance criteria for every warp effect (non-negotiable):** (1) visible in a 15-second clip without context; (2) reversible/recoverable (never permanently destroys a run in a way that feels unfair); (3) never removes player agency for more than 1.5 s; (4) always has a **counterplay upgrade or Pact**; (5) performance budget ≤ 1.2 ms/frame on minimum spec.

**Horror by subtraction** (cosmic horror design rev 3): the entity is never fully seen; it is seen by what it removes (NARR-001 §3.4 N-rules; WARP-001 §5.1 gives the horror reading per tier). Horror is an undertone at T1–T2 and overt from T3. Teen envelope, zero startle. **The Passing** is the signature: a front of absence crosses the sector and subtracts everything *lit* in its swath (Lantern up, or the lance or a Charge just fired); the counter is to go dark and drift. The biome's Presence flees first, then a drained, hard-edged front arrives. At T2 only its distant echo crosses the far parallax and kills nothing; from T3 it is live (WARP-001 W2-11, W3-11, §2.7).

### 8.8 World structure, biomes and Corruption
- **Biomes (6, unlocked/rotated by iteration):** Pale Marches (starter), Ossuary Belt (geode-rich), The Litany (Choir-strong), Green Rot (living coral, Shroud-heavy), The Drowned Observatory (vertical, dark), The Black (void, sparse — Sinistar's Void Zone, kept as the hardest).
- **Corruption:** unattended Choir activity converts geodes → **Shrines** → sectors → **Hollow**. Visible on the macro map as an advancing bruise. The player fights a *war*, not just an encounter: purging shrines is the "capture point" layer that lets a skilled player claw back an iteration.
- **Sector generation:** authored encounter kits (32 kits, each 1 screen-sized module cluster) assembled into 5-Seam runs; guarantees readability and performance while giving variety. Warp Tier ≥ 3 re-keys kit parameters (enemy mix, mirror, lighting) without breaking solvability (a "solvability lint" in the generator: minimum shard supply, sightlines, escape routes).

### 8.9 Death, failure and forward progress (the retention machine)
- Die → Ruins, keep all banked currency/Tree/Codex, lose run-only power, **spend 10–18 loop-minutes**.
- First death of a run: entity speaks a personalized line from your play data ("YOU HUNTED GLASS. YOU HUNTED GLASS AND DIED.") — death becomes dialogue, dialogue becomes telemetry.
- 3-run "Coma" mercy: if the player dies 3× in the same Seam, that Seam's encounter kit is re-rolled and a **Penitent** appears (assist, not a handout). Optional, invisible to the player, and it prevents churn at the worst possible moment.
- **Codex = knowledge progress:** a Codex stamp no longer pays a currency; it *gates*. Each of the 27 rule nodes unlocks by knowing its Codex entry (§7.1; D-15 retired Unwritten Ink), so lore-driven players still get power for engaging with the fiction. **Losing still teaches:** each death stamps the oldest pending gating entry, lowest tier first, and the tier floor stamps the rest on schedule (§7.1).

---

## 9. Progression, content and endgame

### 9.1 Act map (campaign shape)
| Act | Frame | Length | Warp | Player power | The reveal |
|---|---|---|---|---|---|
| **0 — Last Normal Day** | fake cabinet, 3 authored levels | 25 min | T0 | base | The boss you killed was a shadow; the real one wakes; universe is eaten |
| **1 — First Loops** | Ruins tutorial (diegetic, no pop-ups: LOOP-001 §10.5) + 5-Seam runs, generous | 3–6 h | T1 | Tier 1–2 tree | The loop is real; the entity remembers you; the HUD starts lying at night |
| **2 — The Nine Skies** | full biome rotation, Matrons, Entropy unlocks | 6–14 h | T2–T3 | Tier 2–4 + Pacts | You can *lean into* warp; the Choir's religion becomes sympathetic; the hub changes shape |
| **3 — Revelations** | entity now patrols the macro map, shown on the Ledger Compass as a *gap* where sectors should be, never an icon; a sector it crossed loads partly subtracted (fewer geodes, more dark); rule-eating begins | 14–22 h | T3–T4 | Tier 4–5 + MADNESS | The game's own rules are the boss's body; the retro shell is revealed as one of nine skins |
| **4 — Unraveling** | inside the entity's memory; T5 | 2–4 h | T5 | full tree + 5 Threads | Final choice; the player decides what to do with an unwritten universe |

**Where the entity is, and each act's set piece** (cosmic horror design rev 3). Dread climbs by *distance*: how close the absence is to the player. Horror is an undertone at T1–T2 and overt from T3 (late Act 2 on). Teen envelope, zero startle.

| Act | Where the entity is | Set piece |
|---|---|---|
| **1** | **beyond the frame**: only at the parallax edge | **The First Absence:** in the first won run's Waking, one far star goes out in silence and stays out; nothing comments. In the Ruins a Codex entry waits (`cx_chron_first_absence`). Stars lost across the Chronicle stay out, which is how Hunger becomes visible (§7.4) |
| **2** | **crossing the frame**: the Passing; part-silhouettes in the Waking | **The Passing** (§8.7; WARP-001 §2.7) and **the Procession**, a Choir funeral column the player can break or let pass with the Lantern down (ZONES-001, the Procession (CHD-10)) |
| **3** | **inside the rules**: it patrols the macro map as a gap, eats rules and wears your habits | **The Wrong Ruins:** one Ruins room is missing; its doorway opens onto Aether with a gap in it, and nobody mentions it. It comes back only after Ending 4, which always restores it; until then, Ending 3 keeps it gone (§9.3; LOOP-001 owns the Ruins shape). **Your Own Vigil, remembered:** the Rite boss also flies your most-flown routes in its kit, from per-Chronicle telemetry (ZONES-001 §7). At T3+ the Listener hears the Lantern hum (§8.5) |
| **4** | **around the player**: everything not lit is it | **The Recital:** the approach to the Unravel is a gauntlet of the kits you died in, in the order you died in them, drawn only where your past light reached; your best run's Arc-Lance fire comes back as patterns. The HUD stops lying, and no T5 effect may degrade readability. Each rule-thread is latched standing lit in the dark (WARP-001 §1.7) |
| every ninth-sky close and Hard Unmaking, after Act 0 | it eats the sky | **The Eating of a Sky** (§6.2) |

### 9.2 Bosses beyond the entity (so Act 2–3 are not one fight)
Each Seam-3 gate is a **Choir Rite** mini-boss built from the same modular kit (so art cost is low): **Matron of the Drowned Chorus**, **The Censer Cardinal** (turret-puzzle arena), **The Unnumbered** (impossible-shape boss that only exists when you *aren't* looking at it), **Grave Tide** (a wave-event), and **Your Own Vigil** (a warp-mirror boss using your exact build — the emotional and mechanical showcase of the run system).

### 9.3 Endings (5, all reachable; the "true" one needs the Threads)
1. **Nine Hollow Skies** (default loss): the last sky goes dark; the loop restarts with Hunger +2.
2. **The Lantern Extinguished:** you stop fighting; the game quietly becomes an idle-observatory eulogy for 3 minutes. (Met, divisive, memorable — clip bait.)
3. **The Choir Crowned:** accept a Pact of Ascension; you become the next Waking Dark. Unlocks NG+ "Choir mode" (play as a Grub procession; post-launch if scoped).
4. **The Unraveling (true):** pull the 5 Threads; the entity is unmade at the rule level; the credits sequence is the retro arcade shell being peeled away to reveal the last, clean sky.
5. **The Pretence Kept (secret):** complete Act 0 without ever using the Surgelight or Ward and you find the "cabinet's" creator's message — a meta-commentary that reframes the whole game and grants the *Archivist* ending variant. It is the only way to see the Cabinet's last screen, *THAT WAS A PRETENCE.*; every other clear goes straight to the wordless Decay (§6.1; NARR-001 §9.5; TECH-001 Q-T181, PM under owner autonomy grant, 2026-11-19; built).

The Wrong Ruins (Act 3, §9.1) answer to the endings: the missing Ruins room returns only after Ending 4. Until then, Ending 3 keeps it gone; Ending 4 always restores it, even if Ending 3 was seen first, because Ending 4 unwrites the loss (LOOP-001 §10.4).

### 9.4 Score (arcade layer, kept as flavor + a Steam stat layer)
Act 0 keeps a pure arcade score: geode 5 · Grub 150 · shard 200 · Acolyte 500 · entity segment 500 · entity kill 15,000 (all reskinned from the 1983 table — see RES-001 §3). From Act 1 on, score becomes the **Vigil Index** (a Choir-facing metric the entity comments on), feeding achievements and the daily-challenge leaderboard. Extra life at 10,000, at 30,000, then every 40,000 (cap 5) in Act 0 only (PM 2026-11-19, TECH-001 §11.1 Q-T107; SYS-001 §7.1).

---

## 10. UI / UX / accessibility

- **HUD (T0):** top strip = **Ledger Compass** (mini-map, the Sinistar homage); top-left = 1UP/lives + score; bottom-left = Charge pips; bottom-right = Composure (a thin oil-lamp wick, not a bar). Everything is 64×64-module art.
- **Diegetic-first:** as Warp rises, the HUD *moves, lies and gets eaten*; but **a "Steady Ledger" accessibility toggle** always pins an honest, non-lying HUD (accessibility is not the same as difficulty honesty — see below).
- **Default HUD in Acts 1–3** (cosmic horror design rev 3; WARP-001 §4.1): no constant Hourglass. It shows at Seam boundaries, on death and in the Ruins, and in-run as the sand vignette once SYS-001 `Hourglass in-run show threshold` is reached. In Act 4 the Hourglass shows constantly again, so its once-per-run Act 4 eat still has a readout to take (WARP-001 §4.3). The Warp Tier is never a number on the default HUD: the player reads it from the world (P3).
- **With Steady Ledger on, the Warp Tier and the Hourglass are always shown as honest numbers** in the `top-left` anchor (PM ruling 2026-11-18 (owner grant), non-negotiable; WARP-001 §4.4).
- **The hull never lies** (WARP-001 §4.2 L10): the Vigil carries up to SYS-001 `Hull Charge lamps max` phosphor Charge lamps, then a phosphor ring that fills for the Charges above that; the cockpit flame shows Composure by its *shape* (steady → flickering → guttering → hollow), never its brightness; and the Flame Bearing, which is never eaten, leans to the nearest Sepulchre as the honest twin of the Ledger Compass's Sepulchre bearing. The entity axis has no hull twin: the entity is read by subtraction. HUD elements may lie or be eaten; the ship may not.
- **HUD lies stay fair under fire** (WARP-001 §4.2): a lie never concerns a countdown that can kill you or the count of a resource you can spend in the next 3 s (L6); a lie may only *start* in a lull, with no threat close and nothing on an intercept course (L9); every lie onset plays an audio tell, one cue per tell family, and its tell is drawn in with a one-time stroke for players who can't hear it (L11); if a lie was live just before you died, the death screen names it in the Office register, e.g. COMPASS READING DISCREPANCY NOTED. (L12; wording NARR-001 §7.2, `tr()` keys `MSG_DEATH_LIE_*`; only the Compass line is live today, the Charge and Index lines are reserved). All of these hold with Steady Ledger on too.
- **Menus:** 3 clicks max to play. Attract mode → New Vigil → (auto) Sector 1. No mode select screen at first (the *fake* simplicity is part of Act 0's costume; the real menu unfolds later in fiction).
- **Accessibility (Steam requirement + market expectation):** full rebinding (KB/M + gamepad), mouse sensitivity + aim assist (gamepad), colorblind-safe palette variants (the palette already keeps value-contrast separation — see art bible §4), no-QTE cutscene skip (after first watch), photosensitivity mode (kills all flicker/warp strobing, and *this mode must not reduce damage or information*, only presentation), screen-reader-friendly text scaling (200%), reduced-motion presets, subtitles + visual chant indicators (the chant is audio-critical, so it must be visible).
- **Text:** English first; all UI copy ≤ 2 lines per screen; the entity's lines are always big-type, single-word-or-phrase (legible in a thumbnail).

---

## 11. Art direction (summary; see `ART_BIBLE.md`)

- **Look:** 2D, **generated at runtime** (D-13): vector geometry and canvas-item shaders, drawn with the 32-colour palette (on the Act 0 screen the pixel grid is 256×304 portrait and, at most 16 colours at once from RGB332 registers, TECH-001 §1.1; after Act 0 rendering is native resolution with 640×360 as the logical space, owner 2026-11-18), on a 64×64 **modular** grid of procedural parts (spec: `SPRITE_MODULARITY_SPEC.md`). No sprite or texture files. Light source = the player's lantern; everything else is bioluminescence or absence. Because every body is described by parameters, not pixels, the same Grub can be a clean 1983 vector outline at T0 and a breathing, many-limbed shader horror at T5 — the transition is a parameter sweep, not an asset swap.
- **Space is the aether (ART-001 §16):** DARKSTAR's cosmos is **retro-future Victorian**, steampunk in space: a luminous aether full of fog, currents, colour and drifting life, with the Nine Hollow Skies as nested **crystal spheres**, and brass, glass and gaslight machinery. Act 0's black vacuum is the Pretence; the reveal shows that space was never empty. From then on the only true black is the entity, and every victory it wins drains colour and fog out of the aether.
- **Fidelity grows with the reveal (ART-001 §15):** Act 0 is a minimal neon arcade cabinet, flat and unlit. After THE PRETENCE the graphics transcend arcade limits as the warp rises: real 2D lighting with the lantern as the key light, shadows, aether fog, bloom and complex particles. Gameplay stays top-down 2D.
- **Palette (32 colors, 5 ramps):** Void (blues/blacks) · Bone (off-whites/greys) · Choir (bruise magenta + pale chitin) · Phosphor (bioluminescent cyan/teal) · Gaslight (amber/brass for the player). **Rule: the player's palette (amber/brass) must never appear on Choir assets, and vice versa.** This is what keeps readability as the warp escalates.
- **Lovecraftian, but *legible*:** no gore, no tentacle-soup. Dread from scale, symmetry-breaking, wrong-count limbs, faces in the wrong place, cathedral geometry, and *the ordinary thing that is not ordinary* (a lamp that is a lamp is fine; a lamp that is also an eye is the horror).
- **Modularity as horror:** because units are assembled from a 64×64 kit of *generated* parts, **the warp can add/swap/grow limbs at runtime** (T2+) and morph any part continuously. Art cost is one set of generators; horror payoff is infinite.
- **UI:** modern game-UI structure and UX (clear hierarchy, primary vs secondary actions, focus, input glyphs, list/preview/detail information architecture) with chalk-and-brass as the skin. The arcade shell is a costume the game wears (CRT, 1UP type, a native-resolution printed bezel); at the end of Act 0 the camera zooms in to the screen while the bezel peels, cracks, decays and warps out of the frame (the game's main hook; ART-001 §12.7), revealing the real UI that was always underneath (owner, 2026-11-18; replaces the "torn away" peel).

## 12. Audio direction (summary; see `AUDIO_DESIGN.md`)

- **The voice is a system, not a quote.** Nhael'Gharoth speaks in original short lines ("IT WAKES." "COME CLOSER." "YOU BUILT ME." "THE DARK IS MINE." "RUN, LITTLE LANTERN.") and every line maps to a game state, so audio literacy becomes skill (Sinistar's lesson: "Beware, I live" as a state announcement).
- **All sound is generated by code** (D-14): no recorded music, voice or effects files. Square-wave arcade cues at T0; synthesised chant, drones, bells and textures for the horror. Synthesis parameters, not samples, carry the warp, so a sound can rot continuously from chiptune to liturgy.
- **Music:** 4 generated stems per biome (sequenced and synthesised at runtime); the arcade chiptune *decomposes* into the Choir's liturgy as Warp rises. Music tracks Warp Tier and Composure, not just combat state.
- **Silence is the scare chord:** Awakening begins with 1.2 s of total silence before the first line. Budgeted, protected, and it must never be used more than twice per run.
- **Foley/ambience:** the ship is a *place*: creaking brass, a guttering flame, chalk scratches, a ticking clock (the loop). First-person-feeling interludes (the cockpit) are the "immersive" beats at the seams of runs.

## 13. Tech (summary; see `TECH_ARCHITECTURE.md`)

Godot 4.7.2, GDScript-first, data-driven (JSON/Resource definitions for all stat tables so tuning is a data edit, not code), CanvasItem shader library for warp tiers, Godot `Area2D`/`ShapeCast2D` hit detection for the bullet-hell layer first, with a custom quadtree only if TECH-001 §8 profiling shows the SYS-001 §9 active-shot ceiling missing budget (owner decision 2026-11-17), deterministic seeded RNG (replay + daily seeds + clip reproducibility), save-on-checkpoint in the Ruins with a versioned schema, Steamworks via GodotSteam (achievements/statistics/cloud), target 60 FPS on a 2016 laptop iGPU at T0–T2 and 60 FPS at T3–T5 on a GTX 1060.

## 14. Market positioning (summary; see `STEAM_MARKET_PLAN.md`)

- **Genre shelf:** Action Roguelike + Shoot 'em Up; tags: *Roguelike, Precision Shooter, Bullet Hell, Cosmic Horror, Pixel Graphics, Difficult, Replay Value, Steam Achievements, Controller Support*.
- **Comps (positioning, not copying):** Hades (meta-loop upgrade clarity, 2019), Enter the Gungeon (bullet-hell roguelike economy, 2017), Brotato/Brotato-like economy clarity, Ikaruga/Pulstar-era arcade homages for shell, Patrick's Paradox / Eternal Return for reality-warp novelty, Signalis for cosmic-horror restraint.
- **The store-page hook (one image, one sentence):** *"You build the bomb from the same ore the boss is being built from."* → then: *"And when you fail, it eats another sky."*
- **Differentiators we can defend in a clip:** (1) the boss-build race, (2) the arcade→roguelike reveal, (3) reality-warp rule eating, (4) upgrade tree inside a dying time loop.
- **Business shape:** premium single purchase at **$19.99** (with regional price tiering), no DLC at announcement; one free major update ("The Ninth Sky") planned as the post-launch retention play.

---

## 15. Success metrics (measured, not felt)

| Metric | Target at prototype | Target at 1.0 |
|---|---|---|
| Act 0 completion rate | 60% of testers finish A0-3 | 70% |
| "Hook moment" recognition (player says the twist unprompted in interview) | 6/10 | 8/10 |
| Runs per session (Act 1+) | ≥ 2.0 | ≥ 3.0 |
| D1 retention (prototype survey) | 5/10 | 65% (demo→wishlist proxy) |
| Time-to-first-understanding of the boss race | < 90 s | < 60 s |
| Rage-quit events (3 deaths same Seam, no continue) | < 15% | < 8% |
| Median frame time @ minimum spec | ≤ 8 ms | ≤ 8 ms (T2), ≤ 14 ms (T5) |

## 16. Risks and mitigations

| ID | Risk | Mitigation |
|---|---|---|
| R-01 | The reveal lands too early/too late | Two reveal beats designed: the *first crack* at A0-2 and the *floor drop* at A0-3; playtest with a "when did you realize?" interview. |
| R-02 | Warp effects become noise, not design | The 5 acceptance criteria (§8.7) + a **Warp Effect Budget** per sector (max 3 novel effects/sector) + Steady Ledger accessibility mode. |
| R-03 | Scope explosion (90 nodes, 90 node art, 6 biomes) | Modular kit covers 80% of art; run Sigils reuse Tree node art; cut order defined (act 4 variants → 2 biomes → 6 elites). |
| R-04 | Bullet-hell difficulty churn | Coma mercy (§8.9) + Entropy (player-chosen) + Hunger (narrative) instead of static brutal difficulty. |
| R-05 | "Sinistar clone" legal/PR exposure | IP guardrails in RES-001 §5; original names/art/audio; no trademark term in any metadata. |
| R-06 | Reality-warp shader cost on Steam Deck | Tier-based shader variants + Deck-verified performance gate in milestone M3. |
| R-07 | Co-op demand at review time | Explicitly "single-player" on store page; co-op as post-launch stretch goal only. |
| R-08 | Prototype doesn't prove the feel | Prototype exit criteria are measurable (§17) and gate all further content work. |

## 17. Prototype definition and exit criteria (what we build first)

**Vertical slice (see `PRODUCTION_PLAN_MILESTONES.md`):** Act 0's A0-1+A0-2+A0-3 + first Unmaking cinematic + a 5-Seam Act 1 run with 2 biomes, Grubs/Acolytes/Deceiver, 1 Matron gate, the full Waking lifecycle at T1–T2 warp, a 30-node Lantern Tree stub in the Ruins (the slice shows tier 1 only, 20 nodes across the 5 branches, the rest as dark lamps), 12 Run Sigils (the Sigil list and the Tree stub are proposed in their PRs for PM approval; TECH-001 §11.1a Q-T150), the T1 warp set (standing W1-01, W1-02, W1-03, W1-05, W1-08; transient W1-07, W1-09, W1-10; W1-06 only on dropping to Frayed; amended from "6 warp effects", PM ruling 2026-11-19, TECH-001 Q-T100), the entity voice (synthesised, D-14), 60 s polished.
**Exit criteria (all measurable):** (1) 10/10 testers understand "the boss is being built from the same ore I need" unprompted; (2) median tester dies ≥ 2 times to the awakening and *retries immediately*; (3) 0 input-latency complaints in mouse aim; (4) the twist is named unprompted by 6/10; (5) 60 FPS at internal 640×360 on minimum spec with T2 shaders; (6) clip test: a 15-second clip gets a "what is this?" from 5/10 non-players.

## 18. Decision log (locked)
| # | Decision | Status |
|---|---|---|
| D-01 | WASD move + mouse aim; full gamepad parity | **Locked** (user directive) |
| D-02 | Arcade shell (Act 0) → roguelike with time loop | **Locked** (user directive) |
| D-03 | Substantial between-run upgrade tree in the Ruins, scaling with difficulty | **Locked** (user directive) |
| D-04 | Reality-warp escalation tiers as the visual/system signature | **Locked** (user directive) |
| D-05 | Modular 64×64 sprite system, runtime-mutable | **Locked** (user directive). **Amended 2026-11-18 by D-13:** the modules are generated parts (vector + shader), not pixel-art files |
| D-06 | Godot 4.7.2, GDScript, data-driven tuning | **Locked** |
| D-07 | Premium single-purchase, $19.99, no launch DLC | **Proposed** (owner sign-off) |
| D-08 | One-hit hull kept as default (power via avoidance/info) | **Open** — prototype test A/B |
| D-09 | Coop | **Out of scope for 1.0** |
| D-10 | *Twin Vigil* is the charge-capacity stacking chain, not paired fire; paired Charge fire lives in the Run Sigil *Twin Flint* | **Locked** (owner decision 2026-11-16) |
| D-11 | *Anchor* is a six-second freeze field with its own rows in the systems bible, not a sub-second pulse | **Locked** (owner decision 2026-11-16) |
| D-12 | Salt Glass stays as the WARD-2 Tree node and Pact placement; the *Salt Pouch* Run Sigil is cut | **Locked** (owner decision 2026-11-16) |
| D-13 | **All graphics are generated algorithmically at runtime** — vector geometry or shaders — including every enemy, the Vigil, the entity, terrain, VFX, UI and type. No raster sprites, textures or image files ship. Reason: the arcade-to-cosmic-horror transition becomes continuous (one parameter sweep per Warp Tier) instead of an asset swap. **Amended 2026-11-18 (user directive):** images may also be rendered at build time by **pxl** from committed `art/src/*.px.js` sources into `assets/art/generated/` (reproducible build output; base colours from the project palettes, effects per the fidelity ladder of ART-001 §15; never hand-painted; pxl's `image()` is forbidden). Such assets swap between tiers instead of morphing, so anything that must transform continuously stays runtime-generated (ART-001 §14.8) | **Locked** (user directive 2026-11-18) |
| D-14 | **All sound is generated by code** — the arcade cues, music, the Choir's chant, the entity's voice, ambience and the horror soundscape. No recorded audio, ever. **Amended 2026-11-18 (user directive):** sound may be generated at runtime *or* rendered at build time by **chirp** from committed `audio/src/*.cx.js` sources into `assets/audio/generated/` (reproducible build output, never hand-edited; chirp's `sample()` is forbidden). Anything that must morph continuously with the warp stays runtime-synthesised (AUDIO-001 §11.7) | **Locked** (user directive 2026-11-18) |
| D-15 | **Cosmic horror design rev 3** (CHD-01…CHD-17): the entity is never fully seen and horror works by subtraction (undertone T1–T2, overt from T3, zero startle); the Passing; HUD-lie laws L9–L12 with an honest hull; the default HUD drops the constant Hourglass, and Steady Ledger always shows the Warp Tier and Hourglass as honest numbers; the Waking from Act 2 seen by subtraction; an entity distance and set piece per act; **Relics fold into rare Run Sigils and Unwritten Ink retires** (rule nodes are gated by Codex entries; post-tree Ember relights the Ruins or rekindles a Penitent). Fragments, Hunger's naming and the Pact fiction are unchanged. Detail lives in the owning docs (WARP-001, LOOP-001, ZONES-001, NARR-001, SYS-001) | **Ruled** (PM ruling 2026-11-18 under the owner's grant; first-pass numbers retune at playtest) |

## 19. Glossary (canonical vocabulary — use these exact words in all docs, code and UI)
**Vigil** (player ship) · **Lampkeeper** (pilot) · **Arc-Lance** (gun) · **Surgelight** (dash) · **Lantern state** (light toggle) · **Ward Pulse** (defense) · **Unravel Focus** (Act 4 latch) · **Mourning Glass** (ore shards) · **Null-Iron Charge** (homing bomb) · **The Dark Star / Nhael'Gharoth** (entity) · **the Hollow Choir** (enemy faction) · **Oubliette Grub / Acolyte / Deacon of Lies / Grave-Tide Deceiver / The Penitent / Choir Matron / Herald / Listener** (units) · **Sepulchre** (build altar) · **Segment** (one 64×64 boss module) · **Composure** (sanity resource) · **Warp Tier** (reality state, T0–T5) · **Shroud** (grown hazard terrain) · **Shrine / Corruption / Hollow** (faction conversion chain) · **Seam** (a run level) · **sector** (the playfield a Seam presents; the unit the macro map tracks — ZONES-001 §1.2) · **Iteration** (a full time loop) · **Hourglass Clock** (loop timer) · **Nine Hollow Skies** (the loop's nine realities) · **Unmaking / Hard Unmaking** (loop enders) · **Ruins** (hub) · **Lantern Tree** (upgrade tree) · **Ember / Fragment of Unraveling** (currencies) · **Run Sigil** (in-run upgrade; *rare* Run Sigils carry the former Relic designs) · **Pact** (risky boon) · **Entropy** (difficulty ladder) · **Hunger** (entity escalation stat) · **Ledger Compass** (mini-map) · **Codex** (lore/knowledge system) · **Vigil Index** (score metric) · **Aether** (the luminous medium of space after THE PRETENCE; fog, colour, life and crystal spheres, never a black vacuum; ART-001 §16) · **THE PRETENCE** (Act 0's lie that space is an empty black vacuum, and the reveal that tears it open; GDD §6.1, ART-001 §15–§16) · **Drift / Censer Watch / Shoal / Stillwater** (the four Act 0 cabinet zone types, shown on the READY card; PM-approved original names 2026-11-19, Q-T106: **Drift** = Grub-heavy, **Censer Watch** = Acolyte-heavy, **Shoal** = geode-rich, **Stillwater** = geode-scarce, the last stage; the fourth zone was first named "Hollow" and renamed Stillwater the same day, TECH-001 §11.1 Q-T106).

**Retired from player use (D-15, 2026-11-18):** **Relic** (now rare Run Sigils; the keys 1 / 2 / 3 are the rare Sigil quick-slots, ruled 2026-11-18 by the PM under the owner's grant (Q-B), §4.1; the action ids stay `relic_1`–`relic_3` for now, and renaming them is a logged follow-up in TECH-001 §11.1) · **Unwritten Ink** (rule nodes are gated by Codex entries, §7.1). Use neither word in UI or new docs. **Noun count (P-5):** the distinction is not hidden. Rare Sigils from Relics with an active use are pressed on keys 1 / 2 / 3; every other Sigil is passive. So **"rare Sigil (active, keys 1–3)" counts as a player-facing noun** in the P-5 noun test, alongside Run Sigil.

**Doc terms** (canonical names for docs and code; never shown on screen unless noted): **the Decay** (the wordless wearing-out of the Cabinet's arcade skin after A0-5's credits, ending in the tear; replaces the old "THAT WAS A PRETENCE." title card; §6.1, WARP-001 W0-07; never shown on screen) · **the Passing** (a front of absence that subtracts what is lit; WARP-001 W2-11/W3-11; may appear in Codex text) · **Glimpse** (a soft, silent rim-light along part of the entity's edge, caused by the player's own light, §8.4) · **Presence** (the one vast, slow, glowing silhouette of a biome, never a hitbox, which flees the entity; The Black has none; ZONES-001 §2) · **Procession** (the Act 2 Choir funeral-column encounter, ZONES-001, the Procession (CHD-10); not the Waking's phase 1 *Procession* in §8.4) · **rumour** (a Codex entry in its title-only state, chalked up by Sable Vane at the Chalk Desk; the body is written on finding; NARR-001 §8) · **kit memory** (a kit's per-Chronicle visit stage: **Known / Worn / Remembered**; never shown on screen; ZONES-001, kit memory (CHD-11)).

## 20. Open questions

All four original questions are closed (2026-11-17). Kept here so the history reads.

| # | Question | Closed by | Answer |
|---|---|---|---|
| 1 | Is the Hourglass Clock a *hard* timer, or does it pause during exploration? | WARP-001 §6.1 D-01 | **Hard and diegetic**; runs through combat, mining, exploration and the Ruins (except the first Ruins visit, where it starts at the first launch, §6.2, 2026-11-18); pauses only for the pause screen, the Codex, scripted cinematics and attract mode, plus route curtains or loading and the Ruins menus (PM 2026-11-19, SYS-001 §6 `Hourglass Clock pauses`, TECH-001 Q-T138); slow-motion and hit-stop never pause it. The `clock_runs_during_exploration` A/B flag in SYS-001 §10 survives as a tuning experiment, not a warp permission |
| 2 | Does Act 4 keep the same controls, or is the "controls get eaten" moment one scripted sequence? | WARP-001 §6.1 D-02 | **One scripted sequence per run, never permanent** (the Unmaking Rehearsal, WARP-001 §6.2) |
| 3 | Daily challenge at 1.0 or first free update? | PROD-001 / MARKET-001 (owner-delegated ruling R-16) | The daily **Hollow Vigil** ships in the first free update, *The Ninth Sky*. The seed contract (SYS-001 §10, WARP-001 §6.1 D-06) ships at 1.0, so the daily is a content drop, not an engine change |
| 4 | How much of the entity is *seen* in Act 0? | WARP-001 §6.1 D-04 (amended 2026-11-18, PM ruling Q-A) | **A silhouette and nothing else** in Act 0: three signature frames, never centred, never lit. **Amended:** at the *first true Awakening* (the first time after THE PRETENCE that the true entity completes its segments, Act 1 or later; never A0-3, whose boss is the Act 0 costume, exempt from the N-rules) the entity's full body is present for the first time, every edge of it inside the sector, drawn as an outline of absence. This is its debut. The camera never frames more than the N1 maximum (NARR-001 §3.4) at once and pans along it. The single full-body view is kept for the first Unmaking cinematic (N8). This amends an earlier owner decision under the PM's grant (2026-11-18); the PM has flagged it to the owner for reconfirmation |

**Footnote to §3 / §7.3 (WARP-001 §9.2 C-04):** the Run Sigil choose-1-of-3 guarantee has exactly one exception, the eaten rule **H14** (WARP-001 §3.2, §6.1 D-08), which takes a single pick and is telegraphed a Seam early.

New open questions go to the owning doc's open-question section, not here.
