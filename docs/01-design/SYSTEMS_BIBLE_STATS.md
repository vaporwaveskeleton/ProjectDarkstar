# DARKSTAR — Systems Bible (Numbers)

**Doc ID:** SYS-001 · **Version:** 1.2 · **Status:** Authoritative for all numbers · **Last updated:** 2026-11-17
**Owner:** Design (systems) · **Upstream:** `GDD_DARKSTAR_v0.2.md` (GDD-001) · **Downstream:** every other doc in this set
**Data target:** `docs/04-production/TECH_ARCHITECTURE.md` §6 (data-driven tables) — every table below maps 1:1 to a `.tres`/JSON resource.
**Rev 1.1 (2026-11-17):** the Anchor field rows in §1.1 (owner decision D-11 of GDD-001 §18); **rev 1.2 (2026-11-17, owner-delegated rulings R-01, R-04, R-10, R-11, R-14):** §1.2 post-hit grace, §9 resolution closed to 640×360, hitbox diameter and entity exception, on-screen caps; §2.2 ninth-sky Hunger as one +2 row, §6 Hourglass budget/death cost/refund, §7.2 Codex stamp note, §7.5 Fragments and Threads (LOOP-001 LR-09…LR-13); the warp-owned numbers WARP-001 asked for in its §8 R-01 to R-05, added to §6, §9 and §10; and the §2.2 eaten-rule pointer corrected from WARP-001 §6 to §3. **No pre-existing number in this doc was changed by that revision.**

---

## 0. How this doc works

This is the **single source of truth for numbers**. If a number appears in another doc, it is a *reference* to a table here, not a second copy. When you need to tune, change it here first; the other docs never need to change, because they cite the row name.

Conventions used everywhere:

| Convention | Value |
|---|---|
| `px`, `px/s` | logical pixels and pixels/second (640×360 logical space, GDD §2; one logical px = display height / 360, owner 2026-11-18; the Act 0 arcade screen grid is 256×304 with a 40 px HUD strip, owner 2026-11-18, where one screen px = one logical px on 16:9; TECH-001 §1.1) |
| `dmg unit` | 1 unit = one unshielded hull hit. The Vigil's hull is **1 HP** (GDD §8.1); anything ≥1 kills it |
| `hit` | one Arc-Lance projectile impact, or one Unravel hit for the entity (§2) |
| Frames | 60 Hz. A "tell" of 21 frames = 0.35 s |
| `% mod` | additive percentage of the base value unless the row says *multiplicative* |
| `T` | Warp Tier (0–5), see `REALITY_WARP_ESCALATION.md` (WARP-001) |
| `E` | Entropy (0–10, player-selected) |
| `H` | Hunger (entity-side, unbounded, §10) |
| `I` | Iteration number (1–9) |

**Tunability marks.** `🔒` = locked by the GDD, do not change without changing the GDD. `⚙` = expected to move in playtest. `✱` = new here, my judgement call, first-pass value — verify in the slice.

---

## 1. The Vigil (player)

### 1.1 Movement ⚙ (GDD §4.2 values kept exactly)

| Field | Base | Scaling / source | Notes |
|---|---|---|---|
| `max_speed` | 340 px/s | 🔒 GDD | +8% per HULL tier-1 plating-style node is **not** allowed; speed nodes are `⚙` and capped at +12% total |
| `accel` | 2600 px/s² | 🔒 GDD | |
| `drag` | 3.4 /s | ⚙ | |
| `brake` (Space) | 5200 px/s² | ⚙ | Anchor nodes widen the "confirmed stop" window to 0.2 s |
| Full reversal | 0.28 s | 🔒 derived | Design identity: snappier than *Asteroids* |
| `snap_turn` | 720 °/s | ⚙ | |
| Surgelight impulse (Shift) | 200 px/s burst, 0.18 s | ⚙ | Cooldown 1.6 s base; costs **1 Composure** at T ≥ 2 (GDD §4.1) |
| Surgelight Shroud burn | clears a 56 px sphere, 0.4 s | ✱ | Shroud HP equivalent, §9 |
| `anchor` ring radius (HULL-9 chain) | 190 px | 256 px (HULL-10, +35%); 436 px ceiling (HULL-13) | ✱ first-pass. The ring deliberately out-reaches the 340 px lantern ceiling once paid for. |
| `anchor_freeze` duration | 6.0 s | 8.0 s (HULL-16) | ✱ Choir units inside stop moving, chanting and firing; elites and Heralds freeze for half duration. It never damages: a stall, not a kill, per GDD-001 §8.7. |
| `anchor_rearm` | 20 s | 14 s (HULL-12) | ✱ the timer starts when the freeze lands, not when the field is raised. |
| `anchor` exclusions and cap | Sepulchre and The Penitent are never frozen; max 6 units per cast | — | ✱ frozen units still count against §4 spawn budgets and the §9 contact budget (`Simultaneous hostile contacts`). Stopping a deposit is WARD-6's job, not the ring's. |

### 1.2 Hull, lantern and the dark

| Field | Base | Upgraded ceiling | Notes |
|---|---|---|---|
| Hull HP | 1 🔒 | 2 (plating node, HULL-4) | Default run stays one-hit; HP is the exception, not the curve |
| Post-hit grace | 0.75 s ✱ | — | applies only while Hull HP ≥ 2 (plating). The hit that removes plating grants it; at 1 HP it never matters. `ds_vigil.hull.invulnerable_after_hit_s` (TECH-001 §3.4). Owner-delegated ruling R-11, 2026-11-17 |
| Lantern radius (up) | 260 px | 340 px (LANTERN-3) | Light is the mining *and* stealth axis |
| Mining speed, lantern up | 100% | — | 🔒 baseline |
| Mining speed, lantern down | 65% (−35%) 🔒 | 85% (`Dark Lantern`, LANTERN-5) | Below T3, mining in the dark is disabled without the node |
| Choir detection, lantern up | +180% | — | 🔒 |
| Choir detection, lantern down | −60% | −75% (`Dark Lantern`) | |
| Entity acquisition cone | 62° half-angle, 520 px | — | ✱; breaking the cone or killing the lantern ends acquisition at T ≤ 2 |
| Acquisition loss timer | 2.2 s | — | ✱ the entity "remembers" you for this long |

### 1.3 Arc-Lance (one gun, two jobs) ⚙

| Field | Base | Ceiling | Notes |
|---|---|---|---|
| Fire rate | 6 /s | 9 /s (ORDNANCE capstone chain) | 🔒 base from GDD §8.2 |
| Projectile speed | 340 px/s | — | |
| Projectile visual length | 14 px | — | |
| Hits per projectile | 1 | 2 (pierce), 3 (`Shatter Shot` chain) | |
| Time to shatter a small geode face | 0.9 s 🔒 | 0.55 s | = 5 lance hits at base rate |
| Over-fire detonation | ≥ **9 hits in 1.2 s** on one geode ✱ | — | Sinistar's rule kept (RES-001): releases 4–6 shards at once, scattered (row "Shards per geode (detonated)"; Q-T29 resolved, PM under owner autonomy grant 2026-11-18) |
| Shards per geode (calm kill) | 3 🔒 range 3–5 | — | `+1` if the face was mined, not detonated |
| Shards per geode (detonated) | 4–6 ✱ | — | scatter radius 140 px — Grubs win that race. PM-approved 2026-11-18 (Q-T29) |
| Geode size classes | 3 ✱ | — | faces per class = class + 1 → **1 / 2 / 3** faces; the Cabinet values, so M1 matches Act 0. PM-approved 2026-11-18 |
| Geode radius per size class | **10 / 15 / 21 px** ✱ | — | small / medium / large; the Cabinet values. PM-approved 2026-11-18 |
| Recoil / pushback | none | — | intentional: mining precision |
| Damage per lance hit | 1 ✱ | — | derived: 0.9 s to shatter a small geode face = 5 hits at 6 /s. **Approved by owner (2026-11-18)** |
| Projectile lifetime | 0.9 s ✱ | — | **Approved by owner (2026-11-18)** |
| Projectile range | 306 px ✱ | — | = 0.9 s × 340 px/s. **Approved by owner (2026-11-18)** |

### 1.4 Mourning Glass and Null-Iron Charges

| Field | Base | Ceiling | Notes |
|---|---|---|---|
| Charge magazine | 5 pips 🔒 | 7 / 9 / 13 (tree + Run Sigils) | the HUD lantern magazine, GDD §8.3 |
| Charge cap gain per run | 1 Sigil pick max | 2 with the *Twin Vigil* chain | prevents pip-spam builds |
| Shard magnet radius | 96 px ⚙ | 190 px (`Hookline`) | |
| Shard magnet pull speed | 170 px/s ✱ | — | speed a shard inside the magnet radius moves toward the Vigil; the Cabinet value. PM-approved 2026-11-18 (Q-T29) |
| Shard drag | 1.2 /s ✱ | — | slows a scattered shard after a detonation; the Cabinet value. PM-approved 2026-11-18 (Q-T29) |
| Shard collection | 1 shard = 1 Charge, up to cap | — | overflow shards stay in the world, they do not vanish |
| Shard lifetime | never despawns ✱ | — | follows the row above; no timer. PM-approved 2026-11-18 |
| Charge life | 6.0 s ✱ | — | a fired Charge gutters (expires) after this; the Cabinet value. PM-approved 2026-11-18 (Q-T17 part) |
| Charge speed | 210 px/s 🔒 | 250 px/s (`Homing Song`) | |
| Turn authority | 1.6 s 🔒 | 2.6 s (`Homing Song`, +Composure cost) | |
| Charge HP (interceptable) | 1 dmg unit ✱ | — | Grub 1, Acolyte 1, Listener 2, geode contact 1, Shrine proximity destroys it (0.9 s fuse) |
| Charge → entity | 1 **Unravel hit** | — | 🔒 |
| Entity hits to unmake (complete) | 13 🔒 | — | fewer while incomplete: `hits_needed = 13 - 3 + ceil(segments/7)` ✱ → 3 at 0 segments, 13 at 20 |
| Charge loss feedback | glass chime + Choir half-note | — | 🔒 GDD; audio doc owns the sound |

### 1.5 Composure (0–10) — a lever, not a death clock

| Event | Δ Composure | Source |
|---|---|---|
| In the entity's gaze cone | −1.0 /s | 🔒 GDD §8.6 |
| Inside a chant radius | −0.5 /s | 🔒 |
| Warp Tier passive | −0.1 /s × T | 🔒 |
| Charge lost to an interceptor | −0.5 | 🔒 |
| Charge spent and detonated on target | 0 | ✱ spend is not punished |
| Death | −2 at run start, recovers after 60 s of play | 🔒 |
| Surgelight use at T ≥ 2 | −1 per use (max −2/s) | ✱ prevents boost-spam |
| Destroy a Shrine | +1 | 🔒 |
| Kill a Matron (silence) | +2 | 🔒 |
| 5 s in darkness, no firing | +0.5 /s, cap +2 | 🔒 ("flying in darkness for 5 s") |
| Read a Codex entry in the Ruins | full restore | 🔒 |
| *Clear Eyed* (MADNESS-5) | sets T-effect-off for 20 s, −1 | 🔒 GDD §7.2 |

**Bands** (GDD §8.6, magnitudes added here):

| Band | Range | Effects (magnitudes) |
|---|---|---|
| Clear | 10–7 | none |
| **Frayed** | 6–4 | false audio cues (1 per 40 s), phantom Grubs (see DEACON), chromatic edges ≤ 2 px |
| **Unmoored** | 3–1 | Ledger Compass shows one lie per sector; one control axis inverts in 4 s bursts every 25 s; phantom geometry (non-blocking) |
| **Hollowed** | 0 | +1 Warp Tier for the sector (forced, ends at sector end), 1 free death, Choir detection always full, **MADNESS branch effects ×2** |

A `Hollowed` sector is a **build choice**, tracked in telemetry as `hollow_sectors` and shown in the run summary as a stat, not a warning.

---

## 2. The Dark Star — Waking lifecycle numbers

Formal name **Nhael'Gharoth, the Waking Dark**; Choir names "the Hollow King", "the Star That Failed" (GDD §8.4). Never present at sector start 🔒.

| Phase | Threshold | Key numbers |
|---|---|---|
| 0 Seed / Cold Sepulchre | sector start | Sepulchre HP per segment **8** ✱; salt ward blocks 1 deposit for 30 s |
| 1 Procession | 1–11 segments | each deposited shard = **1 segment point**, segment costs **3 shards** ✱ → **60 shards** to complete a sector |
| 2 Guard | 6+ segments (Litany Ring) | 8 Acolyte ring nodes; +15% deposit speed per living node |
| 3 Quickening | ≥ 12 segments 🔒 | Compass starts lying; whisper line; charges can knock modules off |
| 4 AWAKENING | 20/20 🔒 | 3 s stagger window; stagger needs **3 hits** in it 🔒; the Awakening line (AUDIO-001) |
| 5 Rampage | after awakening | contact death 🔒 (no weapons); speed below; heals by eating |
| 6 Unravel | Act 3–4 only | 3 rule-threads; latch time 1.4 s each ✱; R key GDD §4.1 |

### 2.1 Entity stats

| Field | Base | Scaling | Notes |
|---|---|---|---|
| Unravel hits (complete) | 13 🔒 | +1 per 3 Hunger after H=6 | the player's count, not HP |
| Body geometry | 20 modules, 64×64 each | — | 20 × 64×64 = the assembled silhouette (ART-002 §3) |
| Contact hitbox | 16 px inset from sprite ✱ | — | fairness: the visible edge kills, never a hidden one |
| Rampage speed | 150 px/s | +12 px/s per Hunger, cap 260 | always **slower** than `max_speed` 340 🔒 — the danger is enclosure, not outrunning |
| Repair (eats a geode) | +2 segment-equivalents | — | takes 2.0 s |
| Eats a Choir unit | +1 Unravel hit restored | 1 restore per 6 s, cap 3 per rampage | ✱ keeps healing legible |
| Eats a Shrine | +1 Unravel hit restored, Corruption −1 | — | the entity does not share; this is a claw-back tool |
| Gaze cone | 62° half-angle, 520 px | +8° per T above 2 | |
| Module knock (charge on a piece) | knocks 1–3 modules off | — | 500 pts each, Sinistar's "piece" score kept (RES-001) |
| Post-failure | sector → **Hollow**, permanent entity patrol in that biome, Hunger +1 🔒 | — | GDD §8.4 failure state |

### 2.2 Hunger (entity-side escalation, automatic)

| Hunger | Change |
|---|---|
| +2 when the ninth sky closes = Hard Unmaking +1 🔒 (GDD §7.4) plus Iteration lost +1 (GDD §9.3 ending 1). One event, +2 total — never read as +3 (LOOP-001 LR-12) | speed, hits, counter-behaviour |
| +1 per sector eaten | |
| **Eaten rule** every 2 Hunger 🔒 | one rule removed/mutated; WARP-001 **§3** owns the list and order (pointer corrected 2026-11-17 — this line used to say §6, which is WARP-001's decisions section) |
| Counter-behaviour table (H ≥ 4) | H4: Grubs intercept charges on a line; H6: Acolyte turret lead-in +15%; H8: Deacon mimics your last Sigil; H10: Listener hunts your *lantern*, not your gun |

---

## 3. Choir units — stats and AI budgets

All units are assembled from the 64×64 modular part kit (ART-002), which is how the warp can re-key them at runtime. HP is in hits at base lance (6 dmg/s).

| Unit | HP | Speed | Attack | Tell (frames) | Threat pts | Notes |
|---|---|---|---|---|---|---|
| **Oubliette Grub** | 4 | 130 px/s (carry) / 190 (flee) | none 🔒 (never attacks at E<7) | n/a | 1 | flees your lantern; keening when a deposit dies 🔒; carries 1 shard |
| **Acolyte (Censer Knight)** | 6 | 150 px/s | censer shot, 1 dmg, 240 px/s, 1.8 s cycle | **21 f** tell + 15 f turret lag 🔒 (0.25 s) | 4 | mines geodes at 50% rate; leading its body beats the turret |
| **Deacon of Lies** | 10 | 110 px/s | no direct damage; casts **Phantom** every 6 s | 30 f cast | 5 | Phantom = harmless, drains 0.3 Composure on first sight, dispelled by Ward or 2 lance hits; mimics your Vigil at T ≥ 3 |
| **Grave-Tide Deceiver** | 8 | 220 px/s | **steals 1 Charge** per successful bait (decoy lantern, 2 s) | 18 f | 5 | flees to the Sepulchre and deposits 2 segment points; drops stolen charges on death |
| **The Penitent** | unkillable except by you | 60 px/s drift | none | n/a | 0 (toy) | 3 hits → **Vigil Boon** (one of: temp shield 8 s / +1 Charge / 20 s chant silence); −1 Composure for shooting it 🔒 risk/reward |
| **Choir Matron** *(mini-boss)* | 60 | 90 px/s | spawns 3 Grubs / 9 s; **Litany** +40% deposit within 400 px | n/a | 12 | **silence, do not kill**: killing stops the chant and *rains* the sector (Shroud bloom, +1 Corruption) — Seam-3 gate |
| **The Listener** | 12 | 90 (silent) / 380 (charge, 2.5 s) | contact 1 dmg | 8 f after your gunfire | 6 | blind; hunts gunfire within a 90° arc; **immune to a silent player** — it loses interest after 6 s without sound |
| **Herald of the Failed Star** *(elite, 6 named)* | 25–40 | unit-derived | hard-counter to your most-used tool | 24 f | 10–14 | Entropy-gated; see §5.2 |

Oubliette Grub AI numbers (the Cabinet values, so M1 matches Act 0; closes that part of TECH-001 Q-T17):

| Field | Value | Notes |
|---|---|---|
| Grub seek speed | 160 px/s ✱ | speed toward a free shard, before it carries one (carry and flee speeds are in the table above). PM-approved 2026-11-18 |
| Grub flee radius | 110 px ✱ | distance from the Vigil at which a Grub starts to flee. PM-approved 2026-11-18 |
| Grub respawn | 6.0 s ✱ | delay before a killed Grub is replaced. PM-approved 2026-11-18 |

### 3.1 Faction laws that are numbers, not mood 🔒

| Law | Value |
|---|---|
| Units hold fire within **120 px** of a Shrine | GDD §8.5 — shrines are cover, and shooting near one converts a geode |
| Chant audio is diegetic and positional | audible through geometry up to 420 px |
| Grub panic in darkness | detection radius −40% but deposit speed −25% |
| Acolyte turret lag | 0.25 s 🔒 — the teachable tell; `Homing Song` and Surgelight both exploit it |
| Litany Ring | 8 nodes; ring break = 4+ nodes down simultaneously → deposit halt 4 s |

---

## 4. Spawn budgets and encounter math

Runs are 5 Seams assembled from authored **Encounter Kits** (GDD §8.8, 32 kits — see ZONES-001). Each kit carries a threat budget; the generator may only re-key within it.

| Seam | Threat pts (T0–T1) | T2–T3 | T4–T5 | Contents |
|---|---|---|---|---|
| 1 | 8–12 | 14–18 | 18–24 | geode field, 4–8 Grubs, 0–1 Acolyte |
| 2 | 12–18 | 20–26 | 26–32 | + Deceiver or Listener |
| 3 | 16–22 | 24–30 | 30–38 | Sepulchre active, Litany Ring |
| 4 | 20–28 | 28–36 | 36–44 | Deacon + elite Herald at E ≥ 4 |
| 5 | Rite boss (§6) | + | + | mini-boss, budget is the boss |

**Solvability lint** (generator must pass, GDD §8.8): ≥ 24 shards of supply in-sector, ≥ 2 escape vectors from every point, ≥ 1 unlit corridor, Sepulchre not visible from the entry point at T ≤ 2.

**Entropy modifier table** (player-selected, GDD §7.4; reward multipliers in §7):

| E | Modifier added (cumulative) |
|---|---|
| 1 | Grub count +25% |
| 2 | Sepulchre deposit speed +20% |
| 3 | Acolytes lead your velocity by 20% |
| 4 | geode yields −1 shard |
| 5 | the entity repairs 50% faster |
| 6 | HUD reliability −1 (one persistent lie) |
| 7 | Grubs may attack (1 dmg contact) — a **rule** break, opt-in |
| 8 | Listener hunts your lantern instead of your gun |
| 9 | Deacon phantoms persist until Warded |
| 10 | the entity starts each sector at 6 segments ✱ |

---

## 5. Bosses and elites

### 5.1 Choir Rites (Seam-3/5 gates, all from the same part kit — cheap art, GDD §9.2)

| Rite | HP | Phases | Stat line | Weakness |
|---|---|---|---|---|
| **Matron of the Drowned Chorus** | 90 | 2 | Grub spawn 4/7 s; Litany +55% deposit in 480 px | Ward silences for 3 s; must be *silenced*, not killed (same rule as §3) |
| **The Censer Cardinal** | 140 | 3 turret-puzzle | 6 turrets, 1.4 s cycle, 24 f tell; body immune until 3 turrets are dark | destroy turrets by detonating geodes on them (over-fire rule, §1.3) |
| **The Unnumbered** | 100 (exists only off-screen) | continuous | deals contact damage only while off your screen centre ±20°; re-skins silhouette every 12 s | Ward Pulse freezes its re-skin 2 s; Unravel Focus (Act 3+) latches its seams |
| **Grave Tide** (wave event) | n/a | 4 waves | 24 Grubs + 6 Acolytes + 2 Deceivers over 150 s; the tide eats the arena floor's geodes | kill Deceivers first: each steal is 1 Charge you cannot get back this wave |
| **Your Own Vigil** | mirrors your build | 2 | same `max_speed`, same lance stats, 3 Sigils of your current run, 1 fewer Charge than you | your own tells are your weakness — the fight is a mirror of your habits; surgelight spam is punished by a 1.2 s counter-window ✱ |

### 5.2 Herald variants (Entropy-gated elites, 6 named)

| Herald | Counters | Counter-play |
|---|---|---|
| **Herald of the Ninth Sky** (flagship) | lantern: dims your light on hit, 3 stacks | fight dark, or LANTERN-5 |
| **Herald of the Salted Chord** | Ward: your Ward costs 1 Composure for 40 s | carry no Ward-dependent build |
| **Herald of the Long Vigil** | Surgelight: intercepts boosts | pure drag steering |
| **Herald of the Broken Censer** | charges: intercept radius 220 px | mine more, throw less |
| **Herald of the Quiet Pew** | silence: your chant-cues go mute, hiding processions | watch, don't listen |
| **Herald of the Ninth Reckoning** | everything, 10% | E10 only; the flex clip |

---

## 6. Sector and macro-map numbers

| Field | Value |
|---|---|
| Seams per run | 5 🔒 |
| Hourglass Clock budget | 120 loop-minutes per **Iteration** at Entropy 0 🔒 (GDD §6.2); a sky darkens each time one ninth is spent (13⅓ loop-min, derived); only the ninth ends the run (LOOP-001 §6.5) |
| Death clock cost | `10 + 2 × (Seam index − 1)` loop-minutes ✱ (Seam 1 = 10, Seam 5 = 18; GDD §6.2 range) |
| Run-won refund | +15 loop-minutes ✱, never above the 120 budget (LOOP-001 LR-09) |
| Run length target | 25–35 min 🔒 |
| Seam clear time | 4–6 min ✱ |
| Seam sealing under **H2** (a warp-eaten rule) | `seam_close_after` = **20 s** ✱ — the seam you crossed seals 20 s after your crossing. While sealed, the boundary refuses the crossing and the Vigil slides along the edge, with no input lock. Seams re-open at the sector boundary; a sealed seam is never a permanent wall. Requested by WARP-001 §8 R-01; the rule itself is WARP-001 §3.2 H2 |
| Sector size | 3–7 Encounter Kits stitched (1 screen cluster each, ~640×360 base unit) |
| Biomes | 6 (GDD §8.8; ZONES-001 §2 for the full table) |
| Corruption: geode → Shrine | 90 s of unattended Choir activity within 200 px ✱ |
| Corruption: Shrine → sector bruise | 4 Shrines ✱ |
| Corruption: sector → Hollow | 10 Shrines or a lost entity encounter |
| Shrine purge reward | +1 Composure, −1 Corruption, Ink 15 (first purge of a biome per iteration) |
| Ledger Compass | sector list + entity marker; **lies** at T ≥ 3 or Composure ≤ 3 (one lie per sector; the lie is always *legible* — WARP-001 §4) |

---

## 7. Score, economy and the difficulty ladder

### 7.1 Score (Act 0 = the 1983 table, kept exactly — RES-001 §3)

| Event | Act 0 | Act 1+ | Notes |
|---|---|---|---|
| Geode face struck | 5 | 5 | kept |
| Shard collected | 200 | 200 | kept |
| Grub | 150 | 150 | kept (a worker's worth of a life) |
| Acolyte | 500 | 500 | kept |
| Sepulchre module knocked off | 500 | 500 | Sinistar's "piece" |
| Piece of the entity (its own parts) | 500 | 500 | |
| Entity driven off | 15,000 | 15,000 | |
| Rite boss | 15,000 | 15,000 | ✱ same weight as the entity: the Choir's rites *are* its body |
| **Warp multiplier** | ×1.0 | **×1.0 (T0–T1), ×1.2 (T2–T3), ×1.5 (T4–T5)** | ✱ the horror pays better; score is diegetic telemetry, not reward |
| Chain bonus | none | +10% per 3 s of continuous fire, cap +50%, resets on hit-taken | ✱ arcade-feel hook for clips |

Score is **Ember's primary input**: `Ember = floor(score / 200)` plus milestone bonuses. The design note that matters: score never buys power *inside* a run (anti-pillar, GDD §3).

### 7.2 Per-run yields (expected, for pacing math)

| Source | Expected per run (T1, E0) |
|---|---|
| Score 40k–90k → Ember | 200–450 |
| Seam clears (4 × 40) | 160 |
| Choir elites / Heralds | 60–200 |
| Codex firsts (2–5 × 20 Ink) | 40–100 Ink — 20 Ink is per Codex **stamp** (first read of an entry); Ilse Marrow’s marginalia and `cx_vigil_` entries pay 0 (LOOP-001 §8, LR-13) |
| Run-Sigil picks | 3 (choose-1-of-3, 1 paid reroll each) |
| **Run total** | **~450–800 Ember, 40–100 Ink** |

### 7.3 Entropy rewards

| E | Ember × | Ink × | Notes |
|---|---|---|---|
| 0 | 1.00 | 1.00 | |
| 2 | 1.15 | 1.10 | |
| 4 | 1.35 | 1.25 | |
| 6 | 1.60 | 1.45 | |
| 8 | 1.90 | 1.70 | |
| 10 | 2.30 | 2.00 | plus one exclusive Codex entry per E-tier |

### 7.4 Hunger effects on the player's side of the ledger

Hunger raises the entity only. It never reduces player currency (GDD P4: progress is guaranteed).

### 7.5 Fragments of Unraveling and the Threads ✱ (LOOP-001 §9.4, LR-10)

| Fragment source | Fragments | Cap |
|---|---:|---|
| Waking unmade at Warp T ≥ 3 | 1 ✱ | once per run |
| … and at Warp T ≥ 4 | +1 (2 total) ✱ | once per run |
| Rite boss cleared at Warp T ≥ 4 | 1 ✱ | once per run |
| Named Herald, first defeat of each per Iteration | 1 ✱ | 6 per Iteration |
| Hard Unmaking | 3 for Hard Unmakings 1–4; 6 from the fifth on ✱ | per Iteration |
| Ending 2–5 seen for the first time | 2 ✱ | 4 lifetime |

| Thread | Fragment cost | Also requires |
|---|---:|---|
| I | 4 ✱ | 1 Hard Unmaking witnessed |
| II | 6 ✱ | 2 |
| III | 8 ✱ | 3 |
| IV | 10 ✱ | 4 |
| V | 12 ✱ | 5 — Act 4 opens when Thread V is bought |

**Ember overflow valve:** once every Ember node of the Lantern Tree is owned, banked Ember converts to Unwritten Ink at 20 : 1 ✱ (LOOP-001 LR-11), so Ember never becomes a dead currency.

---

## 8. Save, telemetry and forward-progress invariants 🔒

| Invariant | Rule |
|---|---|
| Banked currency, Lantern Tree, Codex, iteration count | persist through death **and** Hard Unmaking |
| Run power (Sigils, Charges, relics) | lost on death, always |
| Soft-lock | impossible: after 3 deaths in the same Seam, that kit is re-rolled and a Penitent is attached (invisible mercy, GDD §8.9) |
| Telemetry keys (entity dialogue inputs) | `glass_hunted`, `charges_thrown`, `charges_lost`, `shrine_purged`, `hollow_sectors`, `penitent_shot`, `seam_deaths`, `iterations`, `hunger`, `warp_max` |
| Death line generation | composed from the top 2 keys (AUDIO-001 §4.10 clauses; NARR-001 §7.2 printout) — "YOU HUNTED GLASS. YOU HUNTED GLASS AND DIED." |
| Save cadence | on Ruins entry, on Tree purchase, on iteration end. Never mid-run (no save-scumming of the entity's state) |

---

## 9. Feel and performance constants ⚙

| Constant | Value | Why |
|---|---|---|
| Internal resolution | 640×360 🔒 | pixel-perfect integer scale (512×288 fallback struck 2026-11-17, TECH-001 §1.1). **Amended (owner, 2026-11-18):** the pixel-perfect grid binds the Act 0 arcade screen only; the bezel and everything after Act 0 render at native resolution, 640×360 staying the logical space (root implemented, PR A). The Act 0 screen grid is **256×304 portrait** with a **40 px HUD strip** (owner, 2026-11-18, replacing the 240×320 approval; built in PR B); 640×360 🔒 holds as the logical space for the rest (TECH-001 §1.1, Q-T25). Frame budget not yet measured at native resolution (Q-T24) |
| Frame budget (min spec) | 1.2 ms/frame for warp effects | GDD §8.7 acceptance criterion 5 |
| Player agency loss | ≤ 1.5 s max, any warp effect | GDD §8.7 criterion 3 |
| Input latency budget | < 3 frames at 120 Hz | GDD §4.3 |
| Screen shake | ≤ 4 px, 0.25 s max | GDD §4.2 |
| Warp shake (sub-row under the row above) | ≤ 2 px, 0.20 s max ✱ | A warp effect never owns the biggest shake in the frame: warp motion reads as wrongness, not as impact (WARP-001 §8 R-02). Warp shake stacks *within* this ceiling, not on top of the 4 px row |
| UI safe area at 200 % text | Every HUD element keeps its anchor rectangle inside the safe area at 200 % text scale at 640×360 logical; warp may hide an element, never displace one | Accessibility floor (GDD-001 §10); the anchor set is WARP-001 §4.1 (its §8 R-03). `TEST-ACC-04` is the pass condition |
| Screen shake under Reduced Motion | off ✱ | Reduced Motion disables screen shake (the Cabinet behaviour). PM-approved 2026-11-18 |
| Camera follow | 0.12 s critically damped, 24 px deadzone, 1.5% aim lookahead | GDD §4.2. Accepted readings (PM under owner autonomy grant 2026-11-18, TECH-001 §11.1a): 1.5% lookahead = a fraction of the visible viewport **per axis** along the aim (Q-T55); 0.12 s = the smoothing time T of the critically damped spring, omega = 2/T (Q-T56); 24 px = the radius of a **circular** deadzone (Q-T57) |
| M1 sandbox arena | wrapping torus 1920×720 ✱ | Same source as the Cabinet's torus field (`CabinetStage.field_size`), so M1 matches Act 0; no clear colour shows (a repeating floor covers the view). Real kit bounds come from ZONES-001 later. TECH-001 Q-T58, PM under owner autonomy grant 2026-11-18 |
| Zoom | 1.0 (T0) → 1.06 (T3) → breathing ±2% over 11 s (T5) | GDD §4.2. Zoom 1.0 = the 640×360 logical frame, the fixed post-Act 0 camera scale (TECH-001 Q-T25 resolved Z1, PM under owner autonomy grant 2026-11-18) |
| Shroud (hazard terrain) | blocks movement, 1 Ward-slice / 1 Surgelight burn to clear, HP 3 | ✱ T2+ terrain |
| Hitbox policy | player hitbox = a circle of **12 px diameter** (6 px radius; smaller than the sprite); every enemy hitbox = sprite alpha ∩ 1 px inset, **except the entity**, whose contact hitbox is §2.1's 16 px inset from the composite silhouette | fairness over realism. Diameter reading and entity exception: owner-delegated rulings R-04, R-10 (2026-11-17) |
| On-screen Choir units | ≤ 32 ✱ | spawn budgets (§4) may never schedule past it; excess spawns queue off-screen. `ContactBudget` and pooling size from here (TECH-001 §8.2). Ruling R-14 |
| Entity modules on screen | ≤ 20 | = the 20 segments 🔒 (GDD §8.4); one physics shape per module (TECH-001 §2.4) |
| Geodes on screen | ≤ 24 ✱ | the solvability lint's 24-shard supply floor (§4) is met across a sector, not one screen |
| Simultaneous hostile contacts (ContactBudget) | ≤ 24 ✱ | units able to touch or shoot the Vigil this frame; over budget, the furthest units stand down (hold position, keep chanting) — never despawn on screen |
| Active shots, both sides | ≤ 180 ✱ | the bullet-layer ceiling TECH-001 §2.6 and §8 measure against; Run Sigils that multiply shots respect it (LOOP-001 §4.3 ceiling lint) |
| Colliders per sector | ≤ 96 ✱ | static + kinematic + area shapes, excluding shots; TECH-001 §8.3 profiles at this ceiling |
| Audio occlusion | chant audible through geometry ≤ 420 px | the Choir is a sound mechanic |
| Hit-stop, Charge hits the entity (`ds_cabinet.fx.hitstop_charge_hits_entity_frames`) | 3 frames ⚙ | 60 Hz sim frames; owner-approved 2026-11-18 (TECH-001 Q-T44) |
| Hit-stop, entity unmade (`ds_cabinet.fx.hitstop_entity_unmade_frames`) | 8 frames ⚙ | 60 Hz sim frames; owner-approved 2026-11-18 |
| Hit-stop, Vigil death (`ds_cabinet.fx.hitstop_vigil_death_frames`) | 6 frames ⚙ | 60 Hz sim frames; owner-approved 2026-11-18 |
| Hit-stop, "IT WAKES" (`ds_cabinet.fx.hitstop_it_wakes_frames`) | 4 frames ⚙ | 60 Hz sim frames; owner-approved 2026-11-18 |
| Hit-stop, modules knocked (`ds_cabinet.fx.hitstop_modules_knocked_frames`) | 2 frames ⚙ | 60 Hz sim frames; owner-approved 2026-11-18 |
| Hit-stop cap (`ds_cabinet.fx.hitstop_max_frames`) | 10 frames ⚙ | maximum for any single or stacked freeze; owner-approved 2026-11-18 |
| Hit-stop under Reduced Motion (`ds_cabinet.fx.hitstop_reduced_motion_scale`) | × 0.5 ⚙ | Reduced Motion multiplies the frames by this; 0 disables; owner-approved 2026-11-18 |
| Credits roll, full (stage 2) length (`ds_cabinet.fx.credits_full_seconds`) | 13.0 s ⚙ | the stage-2 roll with the four service-record lines; owner-approved 2026-11-18 (TECH-001 Q-T45) |
| Credits roll scroll speed (`ds_cabinet.fx.credits_scroll_px_per_s`) | 24 px/s ⚙ | the original literal; owner-approved 2026-11-18 |
| Last-Charge slow-mo trigger distance (`ds_cabinet.fx.slowmo_trigger_px`) | 130 px ⚙ | the lethal Charge this close to the entity starts slow-mo; measured 0.83-0.85 s of real time at 130 px (autopilot stage 2, seeds 9/11/13); owner-approved 2026-11-18 (TECH-001 Q-T46) |
| Last-Charge slow-mo scale (`ds_cabinet.fx.slowmo_scale`) | × 0.25 ⚙ | sim speed during the slow-mo; sim-only (the Vigil runs at real speed); off under Reduced Motion; owner-approved 2026-11-18 |
| Slow-mo ramp in (`ds_cabinet.fx.slowmo_ramp_in_s`) | 0.15 s ⚙ | real time, 1.0 to the slow-mo scale; owner-approved 2026-11-18 |
| Slow-mo ramp out (`ds_cabinet.fx.slowmo_ramp_out_s`) | 0.2 s ⚙ | real time, back to 1.0 when the lethal condition clears; owner-approved 2026-11-18 |
| Slow-mo failsafe (`ds_cabinet.fx.slowmo_max_real_s`) | 2.5 s ⚙ | real-time cap per episode; owner-approved 2026-11-18 |
| Lance bite, muzzle star size (`ds_cabinet.fx.muzzle_star_px`; M1 `ds_arc_lance.fx.muzzle_star_px`) | 3 px ⚙ | arm length of the muzzle plus; a few-pixel vector star is not a luminance flash (AUDIO-001 §8.3 ruling); owner-approved 2026-11-18 (TECH-001 Q-T50) |
| Lance bite, muzzle star duration (`ds_cabinet.fx.muzzle_star_frames`; M1 `ds_arc_lance.fx.muzzle_star_frames`) | 1 drawn frame ⚙ | owner-approved 2026-11-18 |
| Lance bite, recoil (`ds_cabinet.fx.recoil_px`; M1 `ds_arc_lance.fx.recoil_px`) | 1 px ⚙ | visual-only draw nudge opposite the aim; never moves position or velocity, so §1.3 "no recoil" holds; owner-approved 2026-11-18 |
| Lance bite, recoil duration (`ds_cabinet.fx.recoil_frames`; M1 `ds_arc_lance.fx.recoil_frames`) | 2 drawn frames ⚙ | owner-approved 2026-11-18 |
| Lance bite, impact fleck speed (`ds_cabinet.fx.fleck_speed_px_s`; M1 `ds_arc_lance.fx.fleck_speed_px_s`) | 60 px/s ⚙ | flecks leave perpendicular to the shot; owner-approved 2026-11-18 |
| Lance bite, impact fleck life (`ds_cabinet.fx.fleck_life_s`; M1 `ds_arc_lance.fx.fleck_life_s`) | 0.12 s ⚙ | owner-approved 2026-11-18 |
| Lance bite, chalk tick length (`ds_cabinet.fx.tick_len_px`; M1 `ds_arc_lance.fx.tick_len_px`) | 3 px ⚙ | the tick where the lance cannot bite (Sepulchre, entity; in M1 any hurtbox with `bites` off); owner-approved 2026-11-18 |
| Lance bite, chalk tick life (`ds_cabinet.fx.tick_life_s`; M1 `ds_arc_lance.fx.tick_life_s`) | 0.15 s ⚙ | owner-approved 2026-11-18 |
| Lance bite, `lance_dull` cue volume (`ds_cabinet.fx.lance_dull_db`; M1 `ds_arc_lance.fx.lance_dull_db`) | 0.0 dB ⚙ | offset on the cue's own level (AUDIO-001 §12.11); owner-approved 2026-11-18 |

Hit-stop does **not** count toward the 1.5 s "Player agency loss" budget above: it is a presentation freeze with input buffered, not a warp effect. The last-Charge slow-mo is likewise not a warp effect and is not counted in that budget: it slows the sim only and the player keeps control (the Vigil runs at real speed).

---

## 10. Tunables register (what we will move, and what will make us move it)

| Row | Trigger to change | Owner |
|---|---|---|
| Shard-per-segment = 3 | if a first-time player never sees phase 3 (Quickening) in Act 1 | design |
| Entity hits = 13 | 🔒 unless the 13-hit fight reads as a slog in the slice (then 11, and log it in the GDD) | design + producer |
| Composure drain rates | if Act 2 players sit in `Hollowed` unintentionally rather than by choice | design |
| Threat budgets per Seam | if any kit fails solvability lint at T ≥ 3 | level design |
| Score chain bonus | if clips read as "point noise" rather than skill | producer + design |
| Grub attack at E7 | 🔒 opt-in rule break; move only if the community reads it as a pillar break | design lead |
| `seam_close_after` = 20 s (§6) | if `TEST-H2-01` shows players treating the closed seam as an unfair wall rather than a consequence — the fix is the number, not the rule (WARP-001 §8 R-01) | design |
| Hourglass Clock rate | 🔒 **not warp-writable.** Hiding the clock is legal (WARP-001 §4.3); stopping, slowing, reversing or spending it is not. The only open question is whether it runs during exploration at all, which is an A/B flag (`clock_runs_during_exploration`), not a warp permission (WARP-001 §6.1 D-01, its §8 R-04) | design + engineering |
| Warp state seed contract | 🔒 the warp state must be derivable from the seed alone: world tier, Hunger preset and the WARP-001 §3.2 registry state are deterministic per seed ✱. No daily or weekly challenge mode exists without this row (WARP-001 §6.1 D-06, its §8 R-05) | engineering |

---

## 11. Coverage: every GDD number claim, and where it lives here

| GDD § | Claim | Here |
|---|---|---|
| 4.2 | movement model | §1.1 |
| 7.1 | four currencies | `ROGUELIKE_LOOP_AND_LANTERN_TREE.md` (LOOP-001) §3 |
| 8.1 | lantern states | §1.2 |
| 8.2 | lance stats, over-fire | §1.3 |
| 8.3 | charges, 13 hits | §1.4 |
| 8.4 | Waking phases | §2 |
| 8.5 | Choir units | §3 |
| 8.6 | Composure | §1.5 |
| 8.7 | Warp Tiers | WARP-001 §3 (+ §1.5 magnitudes). The warp numbers that belong to *this* doc, not to WARP-001: `seam_close_after` §6, warp shake and the 200 % safe area §9, clock lock and seed contract §10 |
| 8.8 | biomes, corruption, 32 kits | §6 + ZONES-001 |
| 8.9 | death and mercy | §8 |
| 9.3 | five endings | LOOP-001 §9 |
| 7.4 | Entropy / Hunger | §4, §7.3, §2.2 |

No GDD number is contradicted here. New numbers are marked `✱` and are all `⚙`.
