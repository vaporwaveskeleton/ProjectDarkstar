# DARKSTAR — Systems Bible (Numbers)

**Doc ID:** SYS-001 · **Version:** 1.7 · **Status:** Authoritative for all numbers · **Last updated:** 2026-11-19
**Owner:** Design (systems) · **Upstream:** `GDD_DARKSTAR_v0.2.md` (GDD-001) · **Downstream:** every other doc in this set
**Data target:** `docs/04-production/TECH_ARCHITECTURE.md` §6 (data-driven tables) — every table below maps 1:1 to a `.tres`/JSON resource.
**Rev 1.1 (2026-11-17):** the Anchor field rows in §1.1 (owner decision D-11 of GDD-001 §18); **rev 1.2 (2026-11-17, owner-delegated rulings R-01, R-04, R-10, R-11, R-14):** §1.2 post-hit grace, §9 resolution closed to 640×360, hitbox diameter and entity exception, on-screen caps; §2.2 ninth-sky Hunger as one +2 row, §6 Hourglass budget/death cost/refund, §7.2 Codex stamp note, §7.5 Fragments and Threads (LOOP-001 LR-09…LR-13); the warp-owned numbers WARP-001 asked for in its §8 R-01 to R-05, added to §6, §9 and §10; and the §2.2 eaten-rule pointer corrected from WARP-001 §6 to §3. **No pre-existing number in this doc was changed by that revision.**
**Rev 1.3 (2026-11-18, cosmic horror design rev 3; PM ruling 2026-11-18 (owner grant), GDD-001 §18 D-15, CHD-17):** first-pass rows for the Passing, the Glimpse, gaze and the entity's on-screen silhouette (new §2.3); gaze drain and the Procession let-pass gain (§1.5); hull Charge lamps (§1.4); kit memory, reserve kits, the Procession and the death-site Penitent cap (new §4.1); the Hourglass in-run show threshold (§6); the lie-law rows and the tear silence (§9); Codex gating, the respec row and the post-tree Ember sink (new §7.6). **Retired (CHD-15, Unwritten Ink):** the §7.2 `Codex firsts` Ink row, the §7.3 Ink multiplier column, the §6 Shrine purge Ink payout and the §7.5 20 : 1 overflow valve. Every new game-visible row is marked **PM-approved 2026-11-18 under owner grant; retune at playtest** (not `✱`). Rows with no ruled value say "value owed" and are listed in TECH-001 §11.1 (Q-T66).
**Rev 1.4 (2026-11-18, Act 1 vertical slice; PM ruling 2026-11-18 (owner grant)):** §7.1 new row "Act 0 bank (first Ruins visit, once)" (the existing Ember formula applied once; PM-approved 2026-11-18 under owner grant; retune at playtest); §6 Hourglass Clock budget row notes the first-visit start at the first launch (GDD §6.2 exception). **No pre-existing number was changed.** Open: the bank's save reason (TECH-001 §11.1 Q-T101).
**Rev 1.5 (2026-11-19, M1 slice 3 PR 4; PM under owner autonomy grant 2026-11-19):** §1.4 turn-authority reading (time for a 180° turn), Charge contact radius, trail and hits on target; §2 phase-0 row: "Sepulchre HP per segment 8 ✱" **dropped for phases 0–1** (1 Charge hit = 1 segment; TECH-001 Q-T110), new Sepulchre and sandbox procession rows; §3 Grub flee-while-carrying (never, Q-T112), body/steering and idle-orbit rows. All new values are the Cabinet's or M1 engineering values, ✱.
**Rev 1.6 (2026-11-19, Act 0 arcade expansion P1, "the shift"; PM (delegated owner authority)):** new §1.6 Act 0 stage table (five stages); §7.1 rows for lives at start, lives cap and the extra-life schedule (schedule approved, built in P2). No Vigil number was changed.
**Rev 1.7 (2026-11-19, M2 RunSession; PM under owner autonomy grant 2026-11-19, TECH-001 §11.1a Q-T136, Q-T138, Q-T144–Q-T147, Q-T149):** §6 new rows Hourglass Clock rate (1:1), Hourglass Clock pauses, Abandon (costs the death clock cost); §7.1 `Act 0 bank` gains a floor of 40 Ember (`max(floor(VI / 200), 40)`); §7.2 Seam clears pay 40 each **including Seam 5** (won-run row 160 → 200) and in-run Ember banks on a win and on a death; §7.2 Run-Sigil picks timing stated (after Seams 1–3); new §7.7 Lantern Tree node prices by tier and the Run Sigil reroll ladder, moved from LOOP-001 with no value change.

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

**Tunability marks.** `🔒` = locked by the GDD, do not change without changing the GDD. `⚙` = expected to move in playtest. `✱` = new here, my judgement call, first-pass value — verify in the slice. **PM-approved 2026-11-18 under owner grant; retune at playtest** = a first-pass game-visible value ruled by the PM under the owner's grant (cosmic horror design rev 3); treat it as `⚙`. "Value owed" = the row exists, the number does not yet; never fill it without a ruling.

---

## 1. The Vigil (player)

### 1.1 Movement ⚙ (GDD §4.2 values kept exactly)

This is the **Cabinet profile** (Act 0). Its 🔒 rows are locked for Act 0 only (Q-T164, PM under owner autonomy grant, 2026-11-19). Everything after THE PRETENCE flies the Aether profile, §1.1a.

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

### 1.1a Aether handling profile ✱ (GDD §4.2a; ruled, PM under owner autonomy grant, 2026-11-19)

> **Status: ruled, PM under owner autonomy grant, 2026-11-19** (TECH-001 Q-T164, Q-T165; queued for the owner's later review). Every value here is ✱: first-pass, retuned at playtest. §1.1 stays the **Cabinet profile** for Act 0.

The Aether profile replaces §1.1 for all flight after THE PRETENCE. The motor is the same as in §1.1 (`VigilMotor.step_velocity`): thrust adds `accel` along the input, capped at `max_speed`; coasting decays by `exp(-drag·t)`; braking removes `brake` per second. The derived figures below come from that model and still have to be checked by a motor test once the numbers are approved.

| Field | Cabinet (§1.1) | Aether ✱ | `ds_` key | Notes |
|---|---|---|---|---|
| Profile switch | — | `true` | `ds_vigil.aether_move.enabled` | `false` = sectors fly the Cabinet profile. Keeps the change data-switchable for A/B, like D-08 |
| `max_speed` | 340 px/s 🔒 | **220 px/s** | `ds_vigil.aether_move.max_speed` | ≈ 65% of the Cabinet. Must stay above the Grub flee speed (§3, 190 px/s) so the race still holds |
| `accel` | 2600 px/s² 🔒 | **560 px/s²** | `ds_vigil.aether_move.accel` | top speed from rest in ≈ 0.39 s (Cabinet ≈ 0.13 s) |
| `drag` (coast) | 3.4 /s | **0.9 /s** | `ds_vigil.aether_move.drag` | coasts ≈ 245 px from top speed (v / drag), ≈ 5 body-lengths of 48 px (Cabinet ≈ 100 px) |
| `brake` (Space) | 5200 px/s² | **700 px/s²** | `ds_vigil.aether_move.brake` | stops from top speed in ≈ 0.31 s over ≈ 35 px. Strong, but not instant |
| Full reversal | 0.28 s 🔒 | **≈ 0.79 s** (derived, straight line) | — | 2 × 220 / 560. The Cabinet identity is untouched; this becomes the Aether identity (Q-T164) |
| `hull_turn` (keel) | — (the body never rotates) | **180 °/s** | `ds_vigil.aether_move.hull_turn` | a 180° swing takes 1.0 s. The hull turns toward the WASD direction |
| `thrust_lateral` | — | **0.45 × `accel`** | `ds_vigil.aether_move.thrust_lateral` | thrust at 90° to the keel |
| `thrust_reverse` | — | **0.6 × `accel`** | `ds_vigil.aether_move.thrust_reverse` | thrust at 180° to the keel. Between the angles, interpolate on the cosine ✱ |
| `snap_turn` (lance turret aim) | 720 °/s | **720 °/s (unchanged)** | `ds_vigil.move.snap_turn` | the aim stays arcade-precise. In the Aether it turns the turret, not the hull |
| Lantern Down thrust | — | **× 0.7** | `ds_vigil.aether_move.lantern_down_thrust` | running dark: a weaker drive (top speed from rest ≈ 0.56 s) |
| Lantern Down drag | — | **× 0.6** | `ds_vigil.aether_move.lantern_down_drag` | the glide is longer in the dark (coast ≈ 405 px) |
| Surgelight impulse | 200 px/s, 0.18 s | **240 px/s, 0.22 s** | `ds_vigil.aether_move.surge_impulse`, `ds_vigil.aether_move.surge_time` | may exceed `max_speed` while it lasts; drag then brings the ship back ✱ |
| Surgelight cooldown | 1.6 s | **2.0 s** | `ds_vigil.aether_move.surge_cooldown` | LANTERN-7 / LANTERN-16 cuts apply as percentages; the 0.55 s floor is unchanged. The Composure cost at T ≥ 2 (§1.5) is unchanged |
| Choir projectile speed, Aether sectors | × 1.0 | **× 0.75** | `ds_sector.aether.projectile_speed_mul` | telegraph times are never shortened. Dodge check: moving one body-length (48 px) from rest takes ≈ 0.19 s in the Cabinet and ≈ 0.41 s in the Aether, so × 0.75 closes only part of the gap. Coasting and Surgelight cover the rest; playtest decides (Q-T168) |
| Camera velocity lead | — (aim lookahead 1.5% only, GDD §4.2) | **0.25 s of velocity, capped at 48 px** ✱ | `ds_camera.aether.velocity_lead_s`, `ds_camera.aether.velocity_lead_max_px` | engineering; shows what is ahead of a long coast |
| Hitbox | `ds_vigil.move.hitbox_circle_px` 🔒 | **unchanged** | — | the Aether art grows (ART-001 §16.7), the hitbox does not |
| Hull HP | 1 🔒 | **unchanged** | `ds_vigil.hull.max_hp` | D-08 stays open and switchable. The profile never touches the hull |

**Speed budget per profile.** The +12% cap on speed nodes (§1.1, LOOP-001 §3.3) applies to whichever profile is active, so the Aether ceiling is ≈ 246 px/s. LANTERN-10 and LANTERN-13 still scale `accel` and `brake` by the same percentage, so each profile keeps its own full-reversal time. Even with every node, a fully upgraded Aether Vigil never reaches the Cabinet's snap: the weight is part of who the ship is, not a penalty to grind away (LOOP-001 §3.8).

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
| Over-fire detonation | ≥ **7 hits in 1.2 s** on one geode ✱ (warn at 5) | — | Sinistar's rule kept (RES-001): releases 4–6 shards at once, scattered (row "Shards per geode (detonated)"; Q-T29 resolved, PM under owner autonomy grant 2026-11-18) |
| Shards per geode (calm kill) | 3 🔒 range 3–5 | — | `+1` if the face was mined, not detonated. As built (Cabinet and M1): each shattered face frees 1 shard; the last face frees the rest of the calm total, at least 1 |
| Shards per geode (detonated) | 4–6 ✱ | — | scatter radius 140 px — Grubs win that race. PM-approved 2026-11-18 (Q-T29). The 4–6 is the geode's total: glass already freed by calm mining counts toward it, and a detonation always frees at least 1 more. Detonated shards come to rest within the scatter radius |
| Geode size classes | 3 ✱ | — | faces per class = class + 1 → **1 / 2 / 3** faces; the Cabinet values, so M1 matches Act 0. PM-approved 2026-11-18 |
| Geode radius per size class | **10 / 15 / 21 px** ✱ | — | small / medium / large; the Cabinet values. PM-approved 2026-11-18 |
| Geode shard release (engineering) | face: ring radius + 6 px, 30 px/s; calm kill: radius + 10 px, 40 px/s; offset at least 4 px; offset fraction 0.3, slowest speed fraction 0.4, detonation inner fraction 0.35 ✱ | — | how freed shards leave the rock; the Cabinet's literals, mirrored in M1 (`ds_charges.geode.*`, TECH-001 §3.4). PM-accepted 2026-11-18 (PM under owner autonomy grant 2026-11-18) |
| Geode shape (presentation) | 8 + 2 per size class vertices; radius jitter down to 0.72; 2 + 2 per size class glints ✱ | — | drawing only, never collision (the hurtbox is the radius row above). The Cabinet's literals. PM-accepted 2026-11-18 (PM under owner autonomy grant 2026-11-18) |
| M1 sandbox geode layout | 10 geodes; none within 160 px ✱ of the Vigil spawn; sandbox run seed 146 ✱ | — | 10 is the PM's M1 slice 3 count. 160 px is the Cabinet's spawn-clear value. Seed 146 was chosen so a size-0 geode sits 175 px along the aim-right ray from spawn (the scenarios rely on it). Replaced by kit assembly later (ZONES-001). PM-accepted 2026-11-18 (PM under owner autonomy grant 2026-11-18) |
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
| Shard magnet steer | 6 /s ✱ | — | how fast a shard's velocity turns toward the pull (per second); the Cabinet value. PM-accepted 2026-11-18 (PM under owner autonomy grant 2026-11-18) |
| Shard drag | 1.2 /s ✱ | — | slows a scattered shard after a detonation; the Cabinet value. PM-approved 2026-11-18 (Q-T29). Applies only **outside** the magnet radius: inside it there is no drag, so a latched shard reaches full pull speed (PM-accepted 2026-11-18, M1 and Cabinet) |
| Shard radius | 4 px ✱ | — | pickup size of one shard; the Cabinet value. PM-accepted 2026-11-18 (PM under owner autonomy grant 2026-11-18) |
| Shard pickup margin | 2 px ✱ | — | a shard is collected within Vigil hitbox radius + shard radius + this; the Cabinet value. PM-accepted 2026-11-18 (PM under owner autonomy grant 2026-11-18) |
| Shard collection | 1 shard = 1 Charge, up to cap | — | overflow shards stay in the world, they do not vanish. As built (M1): with the magazine full the magnet is off, so overflow glass is not pulled |
| Shard lifetime | never despawns ✱ | — | follows the row above; no timer. PM-approved 2026-11-18 |
| Charge life | 6.0 s ✱ | — | a fired Charge gutters (expires) after this; the Cabinet value. PM-approved 2026-11-18 (Q-T17 part) |
| Charge speed | 210 px/s 🔒 | 250 px/s (`Homing Song`) | |
| Turn authority | 1.6 s 🔒 | 2.6 s (`Homing Song`, +Composure cost) | read as the time a Charge needs to turn through 180°, so the steering limit is π / turn authority rad/s (the Cabinet's reading, `glass_field.gd`; M1 uses the same). PM-accepted 2026-11-19 (PM under owner autonomy grant 2026-11-19) |
| Charge HP (interceptable) | 1 dmg unit ✱ | — | Grub 1, Acolyte 1, Listener 2, geode contact 1, Shrine proximity destroys it (0.9 s fuse). Phase 2: living Litany Ring nodes intercept it like Acolytes (1) unless the ring is broken (§3.1; Q-T121). As built (M1): Grub and geode contact intercept it; Acolyte, Listener, Shrine and the Litany Ring are not built |
| Charge contact radius | 4 px ✱ | — | the Charge's hit and interception circle; the Cabinet value. PM-accepted 2026-11-19 (PM under owner autonomy grant 2026-11-19) |
| Charge trail (presentation) | 10 points ✱ | — | drawing only; the Cabinet value. PM-accepted 2026-11-19 (PM under owner autonomy grant 2026-11-19) |
| Charge hits on its target (phases 0–2) | 1 ✱ | — | in phases 0–2 (phase 2 per Q-T121) the Charge's target is the Sepulchre and one hit knocks 1 segment off (§2 row 0). PM ruling C4, M1 slice 3 (PM under owner autonomy grant 2026-11-18; TECH-001 Q-T110) |
| Charge → entity | 1 **Unravel hit** | — | 🔒 |
| Entity hits to unmake (complete) | 13 🔒 | — | fewer while incomplete: `hits_needed = 13 - 3 + ceil(segments/7)` ✱ → 3 at 0 segments, 13 at 20 |
| Charge loss feedback | glass chime + Choir half-note | — | 🔒 GDD; audio doc owns the sound |
| Hull Charge lamps max | 5 lamps | — | Charges above 5 fill one phosphor ring around the hull instead (up to the `Charge magazine` ceiling). The hull's honest Charge read, WARP-001 §4.2 L10. PM-approved 2026-11-18 under owner grant; retune at playtest |

### 1.5 Composure (0–10) — a lever, not a death clock

| Event | Δ Composure | Source |
|---|---|---|
| In the entity's gaze cone | −1.0 /s | 🔒 GDD §8.6 |
| Gaze Composure drain (aim cursor resting inside the entity's silhouette, T3+) | −0.5 /s | GDD-001 §8.4 (the Waking rebuilt, CHD-06); timing rows in §2.3. PM-approved 2026-11-18 under owner grant; retune at playtest |
| Inside a chant radius | −0.5 /s | 🔒 |
| Warp Tier passive | −0.1 /s × T | 🔒 |
| Charge lost to an interceptor | −0.5 | 🔒 |
| Charge spent and detonated on target | 0 | ✱ spend is not punished |
| Death | −2 at run start, recovers after 60 s of play | 🔒 |
| Surgelight use at T ≥ 2 | −1 per use (max −2/s) | ✱ prevents boost-spam |
| Destroy a Shrine | +1 | 🔒 |
| Kill a Matron (silence) | +2 | 🔒 |
| Procession let pass (Lantern down) | +2 | ZONES-001 §6.6 (CHD-10); the other let-pass and break rows are §4.1. PM-approved 2026-11-18 under owner grant; retune at playtest |
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

**Start 10 (Q-T118).** A run starts at 10 (Clear). There is no passive regeneration: Composure moves only through the event rows above, clamped to 0–10. Between whole numbers the bands read Clear ≥ 7, Frayed ≥ 4, Unmoored > 0, Hollowed = 0 (PM under owner autonomy grant 2026-11-19, TECH-001 §11.1a).

**The wick steps by band (Q-T119).** The HUD Composure wick shows the band only: its flame takes one of four heights (✱ TECH-001 §3.4 `ds_hud.wick.*`), never a readable value.

A `Hollowed` sector is a **build choice**, tracked in telemetry as `hollow_sectors` and shown in the run summary as a stat, not a warning.

### 1.6 Act 0 stage table (the shift)

Act 0 is a five-stage shift (~9–11 min skilled; GDD §6.1; TECH-001 §2.10). One `CabinetStage` per row (`data/cabinet/stage_*.tres`, played in the order of `stage_roster.tres`). Field size is the Cabinet torus, 1920×720 ✱ (unchanged; §9). Zone names are the GDD §19 glossary words. Source for every row: **PM 2026-11-19 (arcade layer study); retune at playtest** (`⚙`). `wakes` = the Sepulchre can wake the entity (false = cold, the stage ends when the Sepulchre is cleared); `goal` is the stage's end condition (0 = clear the Sepulchre, 1 = unmake the entity; `CabinetStage.goal`).

| Id | Name / zone | Geodes | Grubs | Acolytes | Guard Acolytes | Sepulchre start segments | Wakes | Goal |
|---|---|---|---|---|---|---|---|---|
| `a0_1` | First Vigil (cold) | 12 | 2 | 0 | 0 | 8 | no | 0 |
| `a0_2` | Second Vigil / Drift (cold, Grub-heavy) | 16 | 7 | 1 | 1 | 10 | no | 0 |
| `a0_3` | Third Vigil / Censer Watch (Acolyte-heavy, first full Waking) | 18 | 4 | 3 | 2 | 0 | yes | 1 |
| `a0_4` | Fourth Vigil / Shoal (geode-rich) | 26 | 6 | 2 | 1 | 4 | yes | 1 |
| `a0_5` | The Last Normal Day / Stillwater (geode-scarce, last stage) | 8 | 4 | 2 | 1 | 0 | yes | 1 |

**Pressure switches (P2, built; PM 2026-11-19, TECH-001 §11.1 Q-T105; retune at playtest `⚙`).** Per-stage `CabinetStage` fields; each default reproduces the pre-P2 game, and `a0_1` keeps every default. Vigil rows are untouched. TECH-001 §2.10 holds the behaviour.

| Id | Bell interval (`acolyte_reinforce_s`) | Acolyte cap (`acolyte_cap`) | Geode drift (`geode_drift_s`) | Grubs after wake | Grub pilfer | Acolyte escort | Carry Charges in |
|---|---|---|---|---|---|---|---|
| default | 0 (off) | 0 | 0 (off) | no | no | no | no |
| `a0_1` | default | default | default | no | no | no | no |
| `a0_2` | 40 s | 2 | 20 s | no (cold) | yes | no | yes |
| `a0_3` | 25 s | 6 | 20 s | no | yes | yes | yes |
| `a0_4` | 35 s | 4 | 12 s | yes | yes | no | yes |
| `a0_5` | 30 s | 5 | default (off) | yes | yes | no | yes |

Meaning: a bell (every interval, while the Vigil is alive and under control) warns, then brings one Acolyte from just off view if fewer than the cap live (guard ring counted). Drift-in adds a geode every `geode_drift_s` while live geodes sit below half the stage count. "Grubs after wake" keeps the Sepulchre birthing replacement Grubs after the entity wakes (§3 Grub respawn). Pilfer: Grubs prefer loose glass the Vigil's magnet is not pulling. Escort: idle non-guard Acolytes trail a laden Grub. Carry: the next stage starts with the Charges held at the last stage's end (cap: magazine 5).

Engineering rows (✱, `CabinetTuning`, `ds_cabinet.tuning.*`; PM-accepted 2026-11-19 under delegated owner authority, Q-T105; retune at playtest):

| Field | Value | Notes |
|---|---|---|
| Bell warning (`reinforce_tell_s`) | 1.0 s ✱ | censer bell rings at its start, then the Acolyte arrives |
| Arrival offset (`reinforce_entry_px`) | 24 px ✱ | outside the current view edge |
| Drift floor (`geode_drift_floor`) | 0.5 ✱ | drift-in runs while live geodes < floor(stage geodes × this) |
| Drift clearance (`geode_drift_clear_px`) | 160 px ✱ | a drift-in geode is off view and at least this far from the Vigil |
| Pilfer radius (`grub_pilfer_radius`) | 160 px ✱ | how far a pilfering Grub looks for loose glass |
| Escort distance (`escort_distance`) | 60 px ✱ | an escorting Acolyte trails its Grub at this distance |

`a0_5` margin (PM 2026-11-19, TECH-001 §11.1 Q-T130): Grubs 5 → 4 and Guard Acolytes 2 → 1; **retune at playtest (Reviewer: a0_5 sits on the 24-shard floor)**. `a0_1` is the old A0-1 stage and `a0_5` the old A0-3 stage (The Last Normal Day); `a0_2`–`a0_4` are new. Vigil rows (§1.1–§1.5) are not touched by the shift (the 340 px/s lock stays).

---

## 2. The Dark Star — Waking lifecycle numbers

Formal name **Nhael'Gharoth, the Waking Dark**; Choir names "the Hollow King", "the Star That Failed" (GDD §8.4). Never present at sector start 🔒.

| Phase | Threshold | Key numbers |
|---|---|---|
| 0 Seed / Cold Sepulchre | sector start | no Sepulchre HP: in phases 0–1 one Null-Iron Charge hit knocks **1 segment** off (500 pts, §7.1); the former "Sepulchre HP per segment 8 ✱" is dropped for phases 0–1 (PM ruling C4, M1 slice 3; recorded as TECH-001 Q-T110, PM under owner autonomy grant 2026-11-19); salt ward blocks 1 deposit for 30 s |
| 1 Procession | 1–11 segments | each deposited shard = **1 segment point**, segment costs **3 shards** ✱ → **60 shards** to complete a sector (GDD §8.4 follows this, TECH-001 Q-T111) |
| 2 Guard | 6+ segments (Litany Ring) | 8 Acolyte ring nodes; +15% deposit speed per living node. **Charge rule (phase 2, TECH-001 Q-T121):** same as phases 0–1, one Charge hit on the Sepulchre knocks **1 segment** off; living ring nodes intercept Charges like Acolytes (§1.4 `Charge HP`, −0.5 Composure per §1.5); a **broken** ring (4+ nodes down, §3.1) is the window: while broken, nodes do not intercept. *Deconsecrate* in phase 2 destroys an outer ring node (GDD §8.4) |
| 3 Quickening | ≥ 12 segments 🔒 | Compass starts lying; whisper line; charges can knock modules off (§2.1 `Module knock`; phases 0–2 use 1 segment per hit, Q-T121) |
| 4 AWAKENING | 20/20 🔒 | 3 s stagger window; stagger needs **3 hits** in it 🔒; the Awakening line (AUDIO-001) |
| 5 Rampage | after awakening | contact death 🔒 (no weapons); speed below; heals by eating |
| 6 Unravel | Act 3–4 only | 3 rule-threads; latch time 1.4 s each ✱; R key GDD §4.1 |

Sepulchre numbers for phases 0–1 as built in M1 (`ds_sepulchre.*`, TECH-001 §3.4):

| Field | Value | Notes |
|---|---|---|
| Sepulchre deposit radius | 26 px ✱ | a carrying Grub deposits inside this distance; the Cabinet value. PM-accepted 2026-11-19 (PM under owner autonomy grant 2026-11-19) |
| Sepulchre hurt radius | 26 px ✱ | Charges hit it inside this radius; the lance leaves a chalk tick and does no damage; the Cabinet value. PM-accepted 2026-11-19 (PM under owner autonomy grant 2026-11-19) |
| Deposit pulse (presentation) | 0.3 s ✱ | how long the deposit ring shows. PM-accepted 2026-11-19 (PM under owner autonomy grant 2026-11-19) |
| M1 sandbox procession layout | Sepulchre at (1100, 560); one route (760, 440) → (900, 520) → (1010, 580); Grubs start on a 60 px ring round the Sepulchre ✱ | torus positions in the 1920×720 sandbox (TECH-001 Q-T58); 4 Grubs (§4, the PM's M1 count); the ring is the Cabinet's 60. Replaced by kit anchors later (ZONES-001 §6.1). PM-accepted 2026-11-19 (PM under owner autonomy grant 2026-11-19) |

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
| Module knock (charge on a piece) | knocks 1–3 modules off | — | 500 pts each, Sinistar's "piece" score kept (RES-001). In phases 0–2 a Charge hit on the Sepulchre knocks exactly 1 segment (§2 row 0, TECH-001 Q-T110; phase 2 per Q-T121); the 1–3 module knock starts at phase 3 |
| Post-failure | sector → **Hollow**, permanent entity patrol in that biome, Hunger +1 🔒 | — | GDD §8.4 failure state |

### 2.2 Hunger (entity-side escalation, automatic)

| Hunger | Change |
|---|---|
| +2 when the ninth sky closes = Hard Unmaking +1 🔒 (GDD §7.4) plus Iteration lost +1 (GDD §9.3 ending 1). One event, +2 total — never read as +3 (LOOP-001 LR-12) | speed, hits, counter-behaviour |
| +1 per sector eaten | |
| **Eaten rule** every 2 Hunger 🔒 | one rule removed/mutated; WARP-001 **§3** owns the list and order (pointer corrected 2026-11-17 — this line used to say §6, which is WARP-001's decisions section) |
| Counter-behaviour table (H ≥ 4) | H4: Grubs intercept charges on a line; H6: Acolyte turret lead-in +15%; H8: Deacon mimics your last Sigil; H10: Listener hunts your *lantern*, not your gun |

### 2.3 The entity by subtraction: the Passing, the Glimpse and gaze (CHD-01, CHD-02, CHD-06)

Cosmic horror design rev 3 (PM ruling 2026-11-18 (owner grant); GDD-001 §18 D-15). The rules are WARP-001 §2.7 (the Passing, W2-11 / W3-11), GDD-001 §8.4 (the Waking rebuilt) and NARR-001 §3.4 (the N-rules); this table holds only their numbers. §2 and §2.1 are unchanged (20 segments, 13 Unravel hits). Every row: **PM-approved 2026-11-18 under owner grant; retune at playtest.**

| Field | Value | Status | Notes |
|---|---|---|---|
| Passing min tier | T3 (lethal W3-11); W2-11 Distant Passing echo at T2, far parallax only, never lethal | PM-approved 2026-11-18 under owner grant; retune at playtest | The first lethal Passing of a Chronicle needs a prior witnessed echo: TECH-001 engineering flag `first_lethal_requires_echo` (`✱`) |
| Passing max per sector | 1 | PM-approved 2026-11-18 under owner grant; retune at playtest | the W2-11 echo and the live W3-11 count together (WARP-001 §2.7). Never in Seam 5, never during a Rite, never while a HUD lie is live (rules, not numbers: WARP-001 §2.7, ZONES-001 §4.2) |
| Passing telegraph (leading edge) | 3.0 s | PM-approved 2026-11-18 under owner grant; retune at playtest | the colour drain plus the greyscale-safe luminance and shape cue, after the biome's Presence has fled |
| Passing duration | 9.0 s | PM-approved 2026-11-18 under owner grant; retune at playtest | lethal to the lit at T3+ (W3-11) |
| Passing swath width | 0.35 of the playfield | PM-approved 2026-11-18 under owner grant; retune at playtest | fraction of the sector's playfield the swath covers as it crosses |
| Passing "lit" window after firing | 1.0 s | PM-approved 2026-11-18 under owner grant; retune at playtest | the Vigil counts as lit for this long after the Arc-Lance or a Charge fires (WARP-001 §1.1 `Lit`); Lantern up is always lit |
| Passing warp budget cost (first per sector) | 1.0 unit | PM-approved 2026-11-18 under owner grant; retune at playtest | spent the first time a Passing occurs in a sector, against the sector's warp effect budget (GDD-001 §16 R-02; enforced as TECH-001 §5.1's novelty cap). SYS-001 holds no row for that budget itself |
| Entity max on-screen silhouette | 40% | PM-approved 2026-11-18 under owner grant; retune at playtest | of the entity's silhouette visible on screen at once (NARR-001 §3.4 N1); the full body is shown only in the first Unmaking cinematic (N8) |
| Gaze reveal time | 1.0 s | PM-approved 2026-11-18 under owner grant; retune at playtest | T3+: Unravel points show only after the aim cursor rests inside the silhouette this long. The drain while gazing is §1.5 `Gaze Composure drain` |
| Gaze mark hold | 2.0 s | PM-approved 2026-11-18 under owner grant; retune at playtest | revealed points stay marked this long after the cursor leaves |
| Glimpse duration max | 0.3 s | PM-approved 2026-11-18 under owner grant; retune at playtest | a Charge hit rim-lights the entity's edge; soft, silent, eased, inside the WARP-001 §4.5 flicker cap |
| Glimpse radius | 180 px | PM-approved 2026-11-18 under owner grant; retune at playtest | radius of edge the Glimpse rim-lights around the hit |

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
| Grub respawn | 6.0 s ✱ | delay before a killed Grub is replaced. PM-approved 2026-11-18. In the Cabinet it stops at the wake unless the stage sets `grubs_after_wake` (§1.6, P2) |
| Grub flee while carrying | never ✱ | a Grub carrying glass does not flee the lantern ("devotion beats fear", the Cabinet rule). PM under owner autonomy grant 2026-11-19 (TECH-001 Q-T112) |
| Grub body and steering (engineering) | radius 6 px; pickup margin 4 px; steer 5 /s; arrive 2 px; flee step 80 px; waypoint reach 12 px; a dying carrier drops its shard with 0.3 of its velocity ✱ | the Cabinet's literals, mirrored in M1 (`ds_choir.grub.*`, TECH-001 §3.4); waypoint reach is new in M1. PM-accepted 2026-11-19 (PM under owner autonomy grant 2026-11-19) |
| Grub idle orbit (no free glass) | 90 px round the Sepulchre at 70 px/s, orbit point turning 0.3 rad/s ✱ | the Cabinet's literals. PM-accepted 2026-11-19 (PM under owner autonomy grant 2026-11-19) |

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

### 4.1 Level memory and set pieces (CHD-09, CHD-10, CHD-11)

Cosmic horror design rev 3 (PM ruling 2026-11-18 (owner grant)). The rules are ZONES-001 §3.8 (reserve kits), §4.5 (death-site Penitents), §4.8 (kit memory) and §6.6 (the Procession); persistence is LOOP-001 §2. Rows with a value: **PM-approved 2026-11-18 under owner grant; retune at playtest.**

| Field | Value | Notes |
|---|---|---|
| Kit memory: Known | 3 visits | per-Chronicle visit count of one kit. Thresholds simulated with `tools/design_sims/kit_memory_sim.js` (model output, not a playtest measurement; ZONES-001 §4.8). PM-approved 2026-11-18 under owner grant; retune at playtest |
| Kit memory: Worn | 6 visits | PM-approved 2026-11-18 under owner grant; retune at playtest |
| Kit memory: Remembered | 10 visits | PM-approved 2026-11-18 under owner grant; retune at playtest |
| Reserve kits: count | 4 | part of the existing 32 kits; the ids are ZONES-001 §3.8's. PM-approved 2026-11-18 under owner grant; retune at playtest |
| Reserve kits: unlock | Act 2 entry | held out of the draw pool until then; they arrive as Codex rumours (NARR-001 §8). PM-approved 2026-11-18 under owner grant; retune at playtest |
| Death-site Penitent cap | 1 per sector, shared with the Coma Penitent | one Penitent slot per sector for the Coma Penitent, rekindled Penitents (§7.6) and other death-site Penitents; precedence is ZONES-001 §4.5's. PM-approved 2026-11-18 under owner grant; retune at playtest |
| Procession: shards when broken | 12 | the Mourning Glass body drops this many shards; the sector's Choir go to full detection. PM-approved 2026-11-18 under owner grant; retune at playtest |
| Procession: Sepulchre segments when let pass | +1 segment | the column consecrates the Sepulchre (Lantern down). The Composure gain is §1.5 `Procession let pass (Lantern down)`. PM-approved 2026-11-18 under owner grant; retune at playtest |
| Procession: Deacon count | **value owed** | Deacons leading the column (ZONES-001 §6.6); with its draw frequency, host Seams and let-pass test in TECH-001 §11.1 Q-T70 |

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
| Hourglass Clock budget | 120 loop-minutes per **Iteration** at Entropy 0 🔒 (GDD §6.2); a sky darkens each time one ninth is spent (13⅓ loop-min, derived); only the ninth ends the run (LOOP-001 §6.5). Starts at the first launch on the first Ruins visit (GDD §6.2 exception; PM ruling 2026-11-18 (owner grant), Act 1 vertical slice) |
| Hourglass in-run show threshold | ≤ 15 loop-minutes remaining in the Iteration's budget. The default HUD drops the constant Hourglass; in-run it shows as the sand vignette from this point (it also shows at Seam boundaries, on death and in the Ruins). In Act 4 it shows constantly; with Steady Ledger on it is always an honest number (WARP-001 §4.1, §4.4). PM-approved 2026-11-18 under owner grant; retune at playtest |
| Hourglass Clock rate (loop-minute to real time) | 1 loop-minute = 1 real minute (1:1). PM under owner grant 2026-11-19 (TECH-001 §11.1a Q-T136) |
| Hourglass Clock pauses | the clock stops only for: the Codex, scripted cinematics, attract mode, a route curtain or loading, the pause menu, and the Ruins menus (Lantern Tree, Chalk Desk). Slow-motion and hit-stop do **not** pause it. Route curtains/loading and the Ruins menus were added to the GDD §20 Q1 list the same day. PM under owner grant 2026-11-19 (TECH-001 §11.1a Q-T138) |
| Death clock cost | `10 + 2 × (Seam index − 1)` loop-minutes ✱ (Seam 1 = 10, Seam 5 = 18; GDD §6.2 range) |
| Abandon | allowed only in the Ruins or at a Seam boundary; costs the `Death clock cost` row. PM under owner grant 2026-11-19 (TECH-001 §11.1a Q-T144) |
| Run-won refund | +15 loop-minutes ✱, never above the 120 budget (LOOP-001 LR-09) |
| Run length target | 25–35 min 🔒 |
| Seam clear time | 4–6 min ✱ |
| Seam sealing under **H2** (a warp-eaten rule) | `seam_close_after` = **20 s** ✱ — the seam you crossed seals 20 s after your crossing. While sealed, the boundary refuses the crossing and the Vigil slides along the edge, with no input lock. Seams re-open at the sector boundary; a sealed seam is never a permanent wall. Requested by WARP-001 §8 R-01; the rule itself is WARP-001 §3.2 H2 |
| Sector size | 3–7 Encounter Kits stitched (1 screen cluster each, ~640×360 base unit) |
| Biomes | 6 (GDD §8.8; ZONES-001 §2 for the full table) |
| Corruption: geode → Shrine | 90 s of unattended Choir activity within 200 px ✱ |
| Corruption: Shrine → sector bruise | 4 Shrines ✱ |
| Corruption: sector → Hollow | 10 Shrines or a lost entity encounter |
| Shrine purge reward | +1 Composure, −1 Corruption, ~~Ink 15~~ (first purge of a biome per iteration). **Ink payout retired 2026-11-18, CHD-15:** it pays Ember instead, amount **value owed** (TECH-001 §11.1 Q-T66) |
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
| Lives at start (Act 0) | 3 ✱ | — | arcade convention; `CabinetTuning.lives_start` 3. PM-approved 2026-11-19 (Q-T107); built |
| Lives cap (Act 0) | 5 ✱ | — | `CabinetTuning.lives_cap` 5. PM-approved 2026-11-19 (Q-T107); built |
| Extra life (Act 0) | at 10,000, then 30,000, then every +40,000 | — | PM-approved 2026-11-19 (Q-T107); **built (P2)**: `extra_life_first` 10,000, `extra_life_second` 30,000, `extra_life_every` 40,000, cap `lives_cap`. GDD §9.4 owns the rule |
| Act 0 bank (first Ruins visit, once) | Ember = `max(floor(Act 0 Vigil Index / 200), 40)` | — | the existing Ember formula below, applied once, at the first Ruins visit, with a **floor of 40** = the tier-1 node price (§7.7), so a first T1 node is always affordable and the first launch cannot soft-lock; one rule, no special cases (PM under owner autonomy grant 2026-11-19, TECH-001 §11.1a Q-T146). The wall Cabinet pays it out in tickets, 1 ticket = 1 Ember (GDD §7.1; NARR-001 §5.7; Q-T148). A Cabinet replay never banks again (LOOP-001 §11.6; save reason open, TECH-001 §11.1 Q-T101). PM-approved 2026-11-18 under owner grant; retune at playtest |

Score is **Ember's primary input**: `Ember = floor(score / 200)` plus milestone bonuses. The design note that matters: score never buys power *inside* a run (anti-pillar, GDD §3).

### 7.2 Per-run yields (expected, for pacing math)

| Source | Expected per run (T1, E0) |
|---|---|
| Score 40k–90k → Ember | 200–450 |
| Seam clears (5 × 40 on a won run; 40 per Seam cleared, Seam 5 included) | 200 (was 4 × 40 = 160; Seam 5's clear pays on top of the win refund, PM under owner grant 2026-11-19, TECH-001 §11.1a Q-T145) |
| In-run Ember at the run's end | banks in full on a win **and** on a death (PM under owner grant 2026-11-19, Q-T145) |
| Choir elites / Heralds | 60–200 |
| ~~Codex firsts (2–5 × 20 Ink)~~ | ~~40–100 Ink — 20 Ink is per Codex **stamp** (first read of an entry); Ilse Marrow’s marginalia and `cx_vigil_` entries pay 0 (LOOP-001 §8, LR-13)~~ **Retired 2026-11-18, CHD-15:** a Codex stamp pays no currency; it gates a Lantern Tree node (§7.6; LOOP-001 §3.7) |
| Run-Sigil picks | 3 (choose-1-of-3, 1 paid reroll each), after Seams 1–3; Seam 4 offers a rare Run Sigil instead (LOOP-001 §4.1; this row and LOOP-001 win over GDD §6.3's old "after each Seam", Q-T147). Reroll prices: §7.7 |
| Former-Ink Ember (SIG-S-04, SIG-S-08, SIG-S-18, SIG-W-20; Shrine purge, §6) | **value owed**: the rows are in §7.6 (TECH-001 §11.1 Q-T66) |
| **Run total** | **~450–800 Ember**, plus the former-Ink Ember above once valued. ~~40–100 Ink~~ (retired 2026-11-18, CHD-15). The LOOP-001 §9.5 economy model is to be re-run without Ink (LR-14); no new totals until then. The +40 from the Seam 5 clear (Q-T145, 2026-11-19) is not yet in this total either |

### 7.3 Entropy rewards

| E | Ember × | ~~Ink ×~~ (retired 2026-11-18, CHD-15) | Notes |
|---|---|---|---|
| 0 | 1.00 | ~~1.00~~ | |
| 2 | 1.15 | ~~1.10~~ | |
| 4 | 1.35 | ~~1.25~~ | |
| 6 | 1.60 | ~~1.45~~ | |
| 8 | 1.90 | ~~1.70~~ | |
| 10 | 2.30 | ~~2.00~~ | plus one exclusive Codex entry per E-tier |

The Ink column is kept struck through as the record of the old model; Unwritten Ink no longer exists (CHD-15, LOOP-001 LR-13). The Ember column is unchanged.

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

~~**Ember overflow valve:** once every Ember node of the Lantern Tree is owned, banked Ember converts to Unwritten Ink at 20 : 1 ✱ (LOOP-001 LR-11), so Ember never becomes a dead currency.~~ **Retired 2026-11-18, CHD-15:** Unwritten Ink no longer exists. The post-tree Ember sink in §7.6 (LOOP-001 §9.6) replaces the valve.

### 7.6 Codex gating, respec and the post-tree Ember sink (CHD-15)

Cosmic horror design rev 3 (PM ruling 2026-11-18 (owner grant)). Unwritten Ink retires. The 27 Lantern Tree nodes formerly priced in Ink are each unlocked by knowing one Codex entry; the gating map, the backstop order (within a tier, table order) and the pity rule are LOOP-001 §3.7; the sink is LOOP-001 §9.6. Rows with a value: **PM-approved 2026-11-18 under owner grant; retune at playtest.**

| Field | Value | Notes |
|---|---|---|
| Ink-node Ember price | 0 Ember | the node is still bought at the Lantern Tree; it needs its gating entry stamped. PM-approved 2026-11-18 under owner grant; retune at playtest |
| Gating backstop: tier-1 entries | stamped after run 3 of the Chronicle | backstop (a), tier floor for tier 1. PM-approved 2026-11-18 under owner grant; retune at playtest |
| Gating backstop: tier-t entries | stamped at the start of Iteration t | backstop (a), tier floor. PM-approved 2026-11-18 under owner grant; retune at playtest |
| Gating backstop: per death | 1 entry: the oldest pending gating entry, lowest tier first | backstop (b), "death teaches". PM-approved 2026-11-18 under owner grant; retune at playtest |
| Gating discovery: dark flight seconds (LANTERN-4) | 5 s | first sustained dark flight (Lantern down, no fire) this long stamps `cx_rule_lantern_dark`. PM-approved 2026-11-18 under owner grant; retune at playtest |
| Gating discovery: Acolytes struck (ORDNANCE-5) | 25 Acolytes | a counter of Acolytes struck down. PM-approved 2026-11-18 under owner grant; retune at playtest |
| Gating discovery: full-magazine hold seconds (ORDNANCE-9) | 10 s | first full magazine held this long. PM-approved 2026-11-18 under owner grant; retune at playtest |
| Gating discovery: Glimpses witnessed (MADNESS-18) | 13 Glimpses | counted across the Chronicle (Glimpse: §2.3). PM-approved 2026-11-18 under owner grant; retune at playtest |
| Respec cost | 10% of banked Ember | replaces "10% of banked Ink" (GDD-001 §7.3 as amended). One free respec per Iteration and the free respec after a Hard Unmaking are unchanged (LOOP-001 §3.5). PM-approved 2026-11-18 under owner grant; retune at playtest |
| Former-Ink Ember: SIG-S-04 *Salver* (first kill of each Choir variant) | **value owed** | LOOP-001 §4.2 |
| Former-Ink Ember: SIG-S-08 *Nine Coins* (per Charge left at run's end) | **value owed** | LOOP-001 §4.2 |
| Former-Ink Ember: SIG-S-18 *Archive Seal* (per eaten rule read) | **value owed** | LOOP-001 §4.2 |
| Former-Ink Ember: SIG-W-20 *Heresy* (per Ward cast, and the per-run cap) | **value owed** | LOOP-001 §4.2 |
| Former-Ink Ember: Shrine purge | **value owed** | §6 `Shrine purge reward` |
| Ember sink A: Ruins relight prices | **value owed** | a fixed authored list of Ruins lamps and windows, each lit by one spend at a rising price (LOOP-001 §9.6) |
| Ember sink B: rekindle price | **value owed** | rekindles one chosen death-site Penitent (LOOP-001 §9.6) |
| Rekindled Penitents | at most 1 per kit | a rekindled Penitent stays lit through Hard Unmakings; same Penitent behaviour, no power. It takes the shared per-sector slot (§4.1 `Death-site Penitent cap`). PM-approved 2026-11-18 under owner grant; retune at playtest |

All owed values, and the LOOP-001 §9.5 economy re-run without Ink (LR-14), are one open question: TECH-001 §11.1 Q-T66. Both sinks are cosmetic plus memory and never buy power (GDD-001 §3).

### 7.7 Lantern Tree node prices and Run Sigil rerolls

Moved here from LOOP-001 §3.3 (per-node Cost column) and §4.1 (Reroll row) on 2026-11-19 (PM under owner autonomy grant, TECH-001 §11.1a Q-T149) so SYS-001 is the source; **no value changed**. LOOP-001 carried these values with no tunability marker; they are carried here as they were (treat as first-pass, retune at playtest through this table only). LOOP-001 now cites these rows.

| Field | Value | Notes |
|---|---|---|
| Lantern Tree node price, tier 1 (nodes 1–4) | 40 Ember | every Ember-priced T1 node; also the floor of the §7.1 `Act 0 bank` row |
| Lantern Tree node price, tier 2 (nodes 5–8) | 120 Ember | every Ember-priced T2 node |
| Lantern Tree node price, tier 3 (nodes 9–12) | 260 Ember | every Ember-priced T3 node |
| Lantern Tree node price, tier 4 (nodes 13–16) | 520 Ember | every Ember-priced T4 node |
| Lantern Tree node price, tier 5 (capstones 17–18) | 900 Ember | every Ember-priced capstone |
| Codex-gated nodes (27) | 0 Ember at every tier | the §7.6 `Ink-node Ember price` row; the gate is the stamped entry (LOOP-001 §3.7) |
| Run Sigil reroll, by choice number | 40 / 90 / 160 / 240 Ember | bought in-run (GDD §7.3; LOOP-001 §4.1). SIG-M-07 *Second Thought* halves it; SIG-S-14 lets banked Ember pay (LOOP-001 §4.2) |

The tree totals (LOOP-001 §3.3 node rollup, 17,480 Ember over 63 Ember nodes) are derived from these rows and the node tiers.

---

## 8. Save, telemetry and forward-progress invariants 🔒

| Invariant | Rule |
|---|---|
| Banked currency, Lantern Tree, Codex, iteration count | persist through death **and** Hard Unmaking |
| Run power (Sigils, Charges, rare Sigils — the former Relics, CHD-14) | lost on death, always |
| Chronicle memory (CHD-09, CHD-11, CHD-15) | the death-site list (kit plus position per death), per-kit visit counts, rekindled sites and Ruins relights persist through death **and** Hard Unmaking (Anchored state, LOOP-001 §2) |
| Soft-lock | impossible: after 3 deaths in the same Seam, that kit is re-rolled and a Penitent is attached (invisible mercy, GDD §8.9) |
| Telemetry keys (entity dialogue inputs) | `glass_hunted`, `charges_thrown`, `charges_lost`, `shrine_purged`, `hollow_sectors`, `penitent_shot`, `seam_deaths`, `iterations`, `hunger`, `warp_max` |
| Per-kit route telemetry key (CHD-07, CHD-11) | **value owed**: per-Chronicle, per-kit route data (entry points, most-flown lanes) read by kit-memory dressing (ZONES-001 §4.8) and Your Own Vigil's route mimicry (ZONES-001 §7.1). Key name and shape owed (TECH-001 §11.1 Q-T71) |
| Death line generation | composed from the top 2 keys (AUDIO-001 §4.10 clauses; NARR-001 §7.2 printout) — "YOU HUNTED GLASS. YOU HUNTED GLASS AND DIED." |
| STILL ON DUTY trigger death | **value owed**: which death in a Chronicle plays the entity's borrowed Cabinet line "STILL ON DUTY." (NARR-001 §3.2 samples; TECH-001 §11.1 Q-T66) |
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
| Race framing reach (`ds_camera.race_reach_px`) | 900 px ⚙ **proposed** | Race points (Charges in flight, Grubs carrying glass, the Sepulchre while either happens) farther than this from the Vigil are ignored by the camera lean. PM under owner autonomy grant 2026-11-19 (sector slice look); retune at playtest |
| Race framing max lean (`ds_camera.race_lean_max_frac`) | 0.7 of the half view per axis ⚙ **proposed** | Caps the lean so the Vigil never leaves the screen; zoom stays fixed (Z1). PM under owner autonomy grant 2026-11-19; retune at playtest |
| Race framing lean time (`ds_camera.race_lean_time_s`) | 0.6 s ⚙ **proposed** | Smoothing time of the lean (same critically damped spring as follow). PM under owner autonomy grant 2026-11-19; retune at playtest |
| Race pull-out zoom (`ds_camera.race_pull_zoom`) | 0.8 ⚙ **proposed** | Zoom the camera eases to (same spring and time as the lean) while the Sepulchre is a race target off the zoom-1 frame (TECH-001 Q-T211). The one context exception to Zoom 1.0; 0 = off. PM under owner autonomy grant 2026-11-19; retune at playtest |
| Race pull-out max (`ds_camera.race_pull_max_s`) | 2.5 s ⚙ **proposed** | Longest one pull-out lasts; then zoom 1 until the Sepulchre stops being a race target. PM under owner autonomy grant 2026-11-19; retune at playtest |
| M1 sandbox arena | wrapping torus 1920×720 ✱ | Same source as the Cabinet's torus field (`CabinetStage.field_size`), so M1 matches Act 0; no clear colour shows (a repeating floor covers the view). Real kit bounds come from ZONES-001 later. TECH-001 Q-T58, PM under owner autonomy grant 2026-11-18 |
| Zoom | 1.0 (T0) → 1.06 (T3) → breathing ±2% over 11 s (T5) | GDD §4.2. Zoom 1.0 = the 640×360 logical frame, the fixed post-Act 0 camera scale (TECH-001 Q-T25 resolved Z1, PM under owner autonomy grant 2026-11-18) |
| Lie spend window (L6) | 3 s | a HUD lie never concerns the count of a resource the player can spend within this window (WARP-001 §4.2 L6, widened). PM-approved 2026-11-18 under owner grant; retune at playtest |
| Lie lull radius | 220 px | L9: a lie may start only with no hostile hitbox (any Choir body, contact hazard or the entity) this close to the Vigil; a Deacon phantom never spawns inside it while a HUD lie is live (WARP-001 §4.2). PM-approved 2026-11-18 under owner grant; retune at playtest |
| Lie lull intercept window | 1.5 s | L9: a lie may start only with no hostile projectile on course to intercept the Vigil within this time. PM-approved 2026-11-18 under owner grant; retune at playtest |
| Lie audio tell length | 0.25 s | L11: each lie onset cue, one per tell family (AUDIO-001 owns the cues). PM-approved 2026-11-18 under owner grant; retune at playtest |
| Warp entry quiet (`ds_warp.t1.entry_quiet_s`) | 2.0 s | WARP-001 §1.4 (no effect within the first 2 s of a Seam), copied here as data. PM under owner autonomy grant, 2026-11-19 |
| Warp T1 seam depth (`ds_warp.t1.seam_depth`) | 0.6 / 0.7 / 0.8 / 0.9 / 1.0 for Seams 1–5 | **Proposed.** Strength of the T1 standing set (mote light, teeth, breath, chant bed) through a run: Act 1 is pinned at T1 (WARP-001 §1.3), so the run escalates inside the tier. PM under owner autonomy grant, 2026-11-19; retune at playtest |
| Warp T1 breath (`ds_warp.t1.breath_px`, `.breath_period_s`, `.breath_wave_px_s`) | ±1 px, 6.5 s, 240 px/s | **Proposed** (±1 px is WARP-001 W1-02). The breath travels outward from the Vigil as one wave. Views only, never hitboxes. PM under owner autonomy grant, 2026-11-19; retune at playtest |
| Warp T1 teeth (`ds_warp.t1.teeth_count`, `.teeth_len_px`) | 11 teeth, 5 px | **Proposed.** W1-05 ring per geode (one missing, one doubled). PM under owner autonomy grant, 2026-11-19; retune at playtest |
| Warp T1 false chant (`ds_warp.t1.false_chant_s`, `.false_chant_distance_px`) | 4.0 s, 400 px | **Proposed.** W1-07 cue length and source distance (inside the 420 px chant audibility row). The rate is SYS-001 §1.5 Frayed (1 per 40 s). PM under owner autonomy grant, 2026-11-19; retune at playtest |
| Warp T1 HUD deviations (`ds_warp.t1.transient_earliest_s`, `.transient_latest_s`, `.blip_lag_s`, `.blip_smear_s`, `.glyph_s`) | start window 20–90 s; blip lag 0.8 s, smear 8 s; glyph 6 s | **Proposed.** W1-09 / W1-10, one each per sector (WARP-001 §2.2), seeded from the `warp` stream. Steady Ledger on (default) pins both off. PM under owner autonomy grant, 2026-11-19; retune at playtest |
| Lie death-attribution window | 2.0 s | L12: a lie live this close before the Vigil's death is named on the death screen (WARP-001 §4.2; wording NARR-001). PM-approved 2026-11-18 under owner grant; retune at playtest |
| Tear silence (no text) | 20 s | after the Decay and the tear (GDD-001 §6.1; was "after THAT WAS A PRETENCE", retired as a title card 2026-11-19, PROPOSED Q-T181), no text of any kind for this long at the opening of the Aether (NARR-001 §4.5). The Decay before it adds no text either (NARR-001 §4.5 *The Decay*). PM-approved 2026-11-18 under owner grant; retune at playtest |
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
| Readable death, dashed ring gap (`ds_cabinet.fx.death_ring_pad_px`) | 6 px ⚙ | chalk gap beyond the drawn silhouette of the Acolyte that fired the killing shot (the shooter, not the shot); PM-approved 2026-11-18 (owner authority; TECH-001 Q-T65) |
| Readable death, arrow length (`ds_cabinet.fx.death_arrow_px`) | 30 px ⚙ | = hull length 15 × outline scale; PM-approved 2026-11-18 (owner authority) |
| Readable death, outline scale (`ds_cabinet.fx.death_outline_scale`) | 2.0 × ⚙ | the coroner outline (and arrow) is this many times the hull size; PM-approved 2026-11-18 (owner authority) |
| Readable death, outline draw-on time (`ds_cabinet.fx.death_outline_draw_s`) | 0.15 s ⚙ | PM-approved 2026-11-18 (owner authority) |
| Readable death, arrow draw-on time (`ds_cabinet.fx.death_arrow_draw_s`) | 0.12 s ⚙ | PM-approved 2026-11-18 (owner authority) |
| Readable death, chalk delay (`ds_cabinet.fx.death_chalk_delay_s`) | 0.5 s ⚙ | no chalk until the death burst ring has faded; effective delay = max(this, the death burst ring's life); PM-approved 2026-11-18 (owner authority) |
| Readable death, edge tick length (`ds_cabinet.fx.death_edge_tick_px`) | 5 px ⚙ | chalk tick on the view edge pointing at an off-view killer; PM-approved 2026-11-18 (owner authority) |
| Surge afterimage, ghost count (`ds_cabinet.fx.ghost_count`) | 3 ⚙ | hull-outline ghosts trailing a Surgelight burst; PM-approved 2026-11-18 (owner authority) |
| Surge afterimage, ghost spacing (`ds_cabinet.fx.ghost_spacing_ticks`) | 3 ticks ⚙ | base spacing; ghost k sits spacing × k(k+1)/2 ticks back = 3, 9, 18; PM-approved 2026-11-18 (owner authority) |
| Surge afterimage, ghost hold (`ds_cabinet.fx.ghost_hold_s`) | 0.1 s ⚙ | ghosts linger this long after the surge ends; PM-approved 2026-11-18 (owner authority) |
| Surge afterimage, bracket length, nearest ghost (`ds_cabinet.fx.ghost_bracket_frac_1`) | 0.6 × edge ⚙ | PM-approved 2026-11-18 (owner authority) |
| Surge afterimage, bracket length, middle ghost (`ds_cabinet.fx.ghost_bracket_frac_2`) | 0.32 × edge ⚙ | PM-approved 2026-11-18 (owner authority) |
| Surge afterimage, bracket length, farthest ghost (`ds_cabinet.fx.ghost_bracket_frac_3`) | 0.2 × edge ⚙ | PM-approved 2026-11-18 (owner authority) |
| Thrust wake, dot count (`ds_cabinet.fx.wake_dots`) | 6 ⚙ | 1 px dots trailing a thrusting Vigil; PM-approved 2026-11-18 (owner authority) |
| Thrust wake, dot spacing (`ds_cabinet.fx.wake_spacing_ticks`) | 2 ticks ⚙ | PM-approved 2026-11-18 (owner authority) |
| True-body frame, duration (`ds_cabinet.fx.true_frame_frames`) | 1 drawn frame ⚙ | a Charge hit on the costume entity shows its true silhouette (silhouette only, GDD §20) for this many drawn frames; PM-approved 2026-11-19 (owner authority; TECH-001 Q-T95) |
| Star spine, hold (`ds_cabinet.fx.spine_hold_pull`) | 0.02 `Starfield.pull` ⚙ | the A0-3 spine stars brighten and hold below this pull (about 1.1 s into the reveal's 8 s ease-in); PM-approved 2026-11-19 (owner authority) |
| Star spine, travel span (`ds_cabinet.fx.spine_pull_span`) | 0.07 `Starfield.pull` ⚙ | pull range over which the stars travel to the vertebrae; arrives at pull 0.09 (about 2.4 s), before the vertebrae show at 2.5 s; PM-approved 2026-11-19 (owner authority) |
| Decay D1, back to attract (`ds_cabinet.decay.attract_s`) | 2.0 s | the Decay (GDD-001 §6.1 A0-5; WARP-001 W0-07; ART-001 §12.7b): after the last credits line clears, the machine shows its attract honour roll as if nothing happened; d = 0 is the frame the last credits line clears (in ending 5, after the line hold below); **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay D2, tired phosphor (`ds_cabinet.decay.phosphor_s`) | 4.0 s | persistence ghosts, register drift, the INSERT CREDIT blink slows and loses glyphs, the shell sags flat; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay D3, the skin fails (`ds_cabinet.decay.skin_s`) | 5.0 s | bezel bleach and peel, bulbs die, light through the worn print, bloom bleed, the raster shrinks; the hum fails; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay D4, collapse (`ds_cabinet.decay.collapse_s`) | 2.0 s | the picture collapses to a line (0.4 s ✱) and a dot (0.4 s ✱); the dot holds for the rest; the tear opens from the dot at the end. D1 to D4 total 13.0 s (derived), all before the tear, so outside the first Unmaking's 90 s budget; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay collapse silence (`ds_cabinet.decay.collapse_silence_s`) | 1.2 s | total silence while the dot holds, before the tear; the same length as the Awakening silence (GDD-001 §12) but it does not draw on that per-run budget (Act 0 is not a run); **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay phosphor persistence, peak (`ds_cabinet.decay.persistence_max`) | 0.6 | alpha of the previous frame kept by the CRT pass at the end of D2 (0 = none); a ghost trail, never a flash; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay bloom bleed, peak (`ds_cabinet.decay.bloom_bleed_px_max`) | 2 grid px | CRT-pass bleed radius at the end of D3; the CRT pass is the one T0 place soft light is allowed (ART-001 §15.1); **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay raster shrink, peak (`ds_cabinet.decay.raster_shrink_max`) | 0.15 | fraction of the picture height lost to a sagging raster by the end of D3, before D4's collapse; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay register drift, step (`ds_cabinet.decay.register_drift_steps`) | 1 RGB332 step | per drifting register, on one channel; **registers 1–6 only** (VOID and BONE, ART-001 §15.2a); register 0 and every role register (CHOIR, PHOS, GAS, SIGNAL: 7–15) never drift, so the role laws hold; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay register drift, interval (`ds_cabinet.decay.register_drift_interval_s`) | 0.8 s | one register write per interval across D2–D3, round-robin over registers 1–6; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay blink period, end (`ds_cabinet.decay.blink_period_end_s`) | 2.4 s | INSERT CREDIT's blink period slows from ART-001 §12.7's 1.0 s to this by the end of D2; steady (no blink) under photosensitivity, as now; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay glyph loss per blink (`ds_cabinet.decay.glyph_drop_per_blink`) | 1 glyph | attract copy and the honour roll lose glyphs (never gain, never re-form a word; NARR-001 §4.5); under photosensitivity, one glyph per D2 interval of 1.0 s ✱ instead; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay bulb death interval (`ds_cabinet.decay.bulb_die_interval_s`) | 0.5 s | one bulb (the attract card's chasing bulbs, then the coin-door lamp last) goes dark per interval in D3; a dim-out of 0.2 s ✱, never a flicker; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay print bleach, peak (`ds_cabinet.decay.print_bleach_max`) | 0.7 | fraction of bezel ink saturation lost by the end of D3, worst at the edges; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay light through the print, peak (`ds_cabinet.decay.worn_through_light_max`) | 0.35 | alpha of the Aether behind the bezel (TECH-001 §11.2 PR D hand-off: Aether drawn behind the bezel) where the print has worn through, end of D3; it is pearl fog light, not a flash (WARP-001 §4.5); **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay shell detune, end (`ds_cabinet.decay.shell_detune_cents_end`) | −40 cents | the attract shell (AUDIO-001 §2.1) sags flat across D2–D3 as a tape or failing supply would; AUDIO-001 §12.18; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Decay hum, end frequency (`ds_cabinet.decay.hum_hz_end`) | 47 Hz | the cabinet hum (AUDIO-001 §2.1, 50 Hz ✱) sags to this across D2–D3, then stops at the end of D3; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Ending 5 line hold (`ds_cabinet.decay.ending5_line_hold_s`) | 4.0 s | ending 5 only: the Cabinet's last screen THAT WAS A PRETENCE. holds this long after Theodora's screen 10 (NARR-001 §9.5), then the Decay starts at D1; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Wear level by stage (W0-11, only if Q-T180 option B) (`ds_cabinet.wear.level_by_stage`) | [0, 0, 1, 2, 3] for a0_1…a0_5 | applied at each stage start, never mid-play (WARP-001 W0-11); **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Wear detune per level (W0-11) (`ds_cabinet.wear.detune_cents_per_level`) | −2 cents | the stage chiptune runs this many cents flat per wear level (−6 at a0_5); amends AUDIO-001 §3 "`detune_cents = 0` at T0" for Act 0 stages only; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |
| Wear dead bulbs per level (W0-11) (`ds_cabinet.wear.dead_bulbs_per_level`) | 1 | bulbs already dark on the attract card and READY card at that level; **PROPOSED, owner approval needed** (reveal decay, 2026-11-19; TECH-001 Q-T184) |

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
| Cosmic horror first-pass rows (§1.4 hull lamps, §1.5 gaze and Procession, §2.3, §4.1, §6 Hourglass threshold, §7.6, §9 lie and tear rows) | PM-approved 2026-11-18 under owner grant; retune at playtest. Move one if `TEST-PASS-01` or `TEST-LIE-02` (WARP-001) shows a Passing or a lie reading as unfair, or if kit memory stages arrive far from the simulated runs 4 / 11 / 25 for the first kit (ZONES-001 §4.8) | design |
| Aether handling profile (§1.1a) | PM under owner autonomy grant, 2026-11-19 (TECH-001 Q-T164–Q-T169). Move a row if a first-flight playtest shows the weight reading as broken controls rather than as a heavier ship (players pressing harder, fighting the keel), or if Aether deaths cluster on bullets that could not be dodged at the slower pace. Fix the numbers, and do not switch the profile off | design |

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
| 7.1, 7.3 | Unwritten Ink retired; Codex-gated nodes; respec in Ember (D-15) | §7.2, §7.3, §7.5 (retired rows), §7.6 |
| 8.4 | the Waking rebuilt: gaze, Glimpse, silhouette cap | §2.3, §1.5 |
| 8.7, 9.1 | the Passing (W2-11, W3-11) | §2.3 |
| 10 | HUD lie laws, hull lamps, Hourglass show threshold | §9, §1.4, §6 |

No GDD number is contradicted here. New numbers are marked `✱` and are all `⚙`. The rev 1.3 rows (cosmic horror design rev 3) are marked "PM-approved 2026-11-18 under owner grant; retune at playtest" instead, and are `⚙` too.
