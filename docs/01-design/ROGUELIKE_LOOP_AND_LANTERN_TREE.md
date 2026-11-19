# DARKSTAR — Roguelike Loop, Run Sigils, Pacts and the Lantern Tree

**Doc ID:** LOOP-001 · **Version:** 1.4 · **Date:** 2026-11-19 · **Owner:** Design (systems / progression) · **Status:** §0–§14 authored (complete draft, pending review). Numbers marked "requested SYS-001 row" are proposals until SYS-001 adopts them.

Rev 1.1 (2026-11-17): §5 Relics, §6 run shape and the two escalators, §7 Pacts written out in full; the §4.1 Run-Sigil pick count corrected to SYS-001 §7.2's three; HULL-17's "Anchor ring" renamed to the **Anchor field** to match SYS-001 §1.1 and GDD-001 D-11. The 90 / 24 / 18 counts GDD-001 §7 promises are now all on disk. Requests **LR-01…LR-08** are open against SYS-001 and GDD-001 and are listed in §5.5, §6.5 and §7.5.

Rev 1.2 (2026-11-17): §8 Codex, §9 economy flow, §10 Iteration unlocks, §11 endings, §12 content cost, §13 coverage and §14 open questions written. Three in-file corrections made while doing the arithmetic: **§6.5 LR-04 is reversed** — the Hourglass Clock is read per Iteration (GDD-001 §6.2 and §2), because the per-sky reading put 18 loop-hours in an Iteration and contradicted §6.5's own 3.5–6 h; §6.3's E10 gate now says "ending 2–5 seen", because ending 1 is shown at every Hard Unmaking and would have opened E10 after the first Iteration; §6.4's Hunger pacing budget is replaced by §10.3's cadence, which matches WARP-001 §3.2's act gates. The §2 Anchored row now follows ruling R-05 (accessibility settings are device-level).

Rev 1.3 (2026-11-18, cosmic horror design rev 3; PM ruling 2026-11-18 (owner grant)): **Unwritten Ink retires** (CHD-15): the 27 Ink nodes cost 0 Ember and are gated by one Codex entry each (§3.3, new §3.7 gating map and backstops); respec is 10% of banked Ember (§3.5); the Codex stamp gates instead of paying (§8); Ink-paying Sigils pay Ember, SIG-S-14 and MADNESS-7 get new effects (§3.3, §4.2); the post-tree Ember sink (relighting the Ruins, rekindling a death-site Penitent) replaces the 20:1 overflow valve (§9.6); the §9.5 economy table is marked to re-run without Ink. **Relics fold into rare Run Sigils** offered at Seams 2/3/4 (CHD-14; §4.1, §5, §6.1); the noun "Relic" retires from player use. **Anchored state** gains the death-site list, per-kit visit counts and rekindled Penitents (CHD-09, CHD-11; §2). **The Eating of a Sky** makes the ninth-sky close playable, and **the Wrong Ruins** take one room away in Act 3 (CHD-08; §10.4, §11.2, §11.7). Ember amounts and sink prices are **value owed** (listed in §9.7 LR-14). Fragments and Threads are unchanged. **Same-day reconciliation (2026-11-18):** gating ids folded onto NARR-001's samples and the §8.2 classes widened (taught `cx_rule_`, Chronicle milestones, authored `cx_vigil_` pages, the Choir's sacred things), recount 144 (§3.3, §3.7, §8.2, §8.5, §12); the four gating discovery counts cite SYS-001 rows; within-tier death-backstop order is table order; SIG-S-14 and SIG-M-04 adopted, Q-03 closed (§4.2, §14); rekindled Penitents share the Penitent cap with Coma → rekindled → other precedence (§9.6); ending 4 always restores the Wrong Ruins room (§10.4, §11).

Rev 1.4 (2026-11-19, PM under owner autonomy grant 2026-11-19, TECH-001 §11.1a Q-T145, Q-T146, Q-T148, Q-T149): the Lantern Tree tier prices and the Run Sigil reroll ladder moved to **SYS-001 §7.7** with no value change; §3.1 Cost, §3.3 rollup note, §3.6, §4.1 Reroll and §9.1–§9.2 now cite it, and the §3.3 Cost columns are marked as a derived view. §9.1 lists the Act 0 bank (SYS-001 §7.1, with its floor), tickets as the physical form of Ember (1 ticket = 1 Ember), and the Seam 5 clear paying Seam Ember.

This is the progression contract. GDD-001 §6–§7 promises a run structure, a between-run tree, **90 nodes + 24 Pacts + 18 Relics** and "~120 Run Sigil pool entries". All of it is here, written out (the 18 Relic designs now ship as rare Run Sigils, §5). Numbers do not live in this doc: every stat, cost floor, yield and multiplier is in **SYS-001** (`SYSTEMS_BIBLE_STATS.md`), and where this doc needs a number it points at a SYS-001 row instead of inventing one. If a number here and a number in SYS-001 disagree, SYS-001 wins and this doc is a bug.

## 0. How to read this doc

| If you are… | Read | Then |
|---|---|---|
| new to the project | GDD-001 §1–§3, §6, then §1–§2 here | §3 (Lantern Tree), §7 (Pacts) |
| designing or tuning a node | §3 conventions, then SYS-001 §1, §7 | the branch table for your node |
| building the save/persistence layer | §2 save layers, §9 economy flow | SYS-001 §8 invariants |
| authoring content (kits, rites) | §6.1 run anatomy, §10 iteration unlocks | ZONES-001 |
| writing fiction or UI copy | §11 endings, §8 Codex | NARR-001 |
| planning the build | §12 content cost, §13 coverage | PROD-001 |
| deciding what is still open | §14 open questions, then the LR requests in §5.5, §7.5 and §9.7 | SYS-001 §10 |

Cross-doc IDs used here: GDD-001, SYS-001, ZONES-001, WARP-001, NARR-001, AUDIO-001, ART-001, ART-002, ASSET-003, TECH-001, PROD-001, MARKET-001.

Vocabulary is GDD-001 §19 only. The 1983 arcade original is never named in this doc (RES-001 §5).

## 1. The loop in one page

Four nested layers, from tightest to loosest. A player is always inside exactly one of the outer three and always inside the innermost.

| Layer | Length | What the player is doing | What persists when it ends | Ends when |
|---|---|---|---|---|
| **Seam** | 4–6 min (SYS-001 §6) | mine, shoot, run one encounter kit | nothing except the run's state | kit cleared or the Vigil is destroyed |
| **Run** (5 Seams) | 25–35 min | build a Vigil from Run Sigils, reach the Waking at Seam 5, bank | Ember, Fragments, Codex, tree | Seam 5 ends, or death, or the clock |
| **Iteration** | ~120 loop-minutes (GDD-001 §6.2) | spend the Hourglass Clock across runs and the Ruins; the Nine Skies go dark one by one | Lantern Tree, Ruins, Codex (anchored) | the ninth sky goes dark → **Hard Unmaking** |
| **Chronicle** | 20–40 h | the whole saved game: acts, endings, Vigil Index, Hunger | everything except the run | credits, or you stop playing |

**Forward progress is a law, not a feature.** Every terminal state produces banked currency, a Codex entry and an iteration modifier. There is no state in this game in which the player loses the run and also gains nothing. GDD-001 §18 locks it; §8.9 implements it; SYS-001 §7.4 forbids Hunger from reducing player currency.

## 2. Save layers and the three persistence classes

| Class | Contents | Survives death | Survives Hard Unmaking | Survives "New Iteration" from the menu | Where in TECH-001 |
|---|---|---|---|---|---|
| **Run state** | Seam index, seed, Run Sigils (card picks and the rare boundary Sigils, §5), active Pact, Charges, Composure, in-run Ember | no | no | no | run slot, written between Seams only |
| **Iteration state** | Hourglass Clock, sky count, sector corruption map, Hollow sector list, entity memory (telemetry counters) | yes | **consumed** by Hard Unmaking, which raises Chronicle Hunger and rewrites the map | reset deliberately | iteration slot |
| **Anchored state** | Lantern Tree purchases, Threads of Unraveling, banked Ember/Fragments, Codex, Ruins shape (§10.4 hub shape, the lamps and windows relit with Ember (§9.6), the Wrong Ruins room state (§10.4)), endings seen and ending flags (§11.7), Chalk Desk ledger, Vigil Index bests, Chronicle Hunger (it carries across Iterations and only rises, §10.3), Chronicle run count (the §3.7 tier-1 backstop counts it), **the death-site list** (kit id + position of every death this Chronicle; a later visit to that kit spawns a Penitent at the site, ZONES-001 §4.5 and the SYS-001 death-site Penitent cap row; CHD-09), **rekindled Penitents** (at most one per kit, chosen from the death-site list, §9.6), **per-kit visit counts** (one counter per kit id, read against the SYS-001 kit memory Known / Worn / Remembered rows; ZONES-001, kit memory (CHD-11)) | yes | yes | yes | profile slot |
| **Device settings** | accessibility (Steady Ledger, photosensitivity, text scale, reduced motion), audio and input bindings | yes | yes | yes | **device-level, not a save slot** — `user://settings.cfg`, loaded before any profile so it works from the attract screen (TECH-001 §7.3; ruling R-05, 2026-11-17). Never reset by a run, an Iteration or a new Chronicle |

**Memory of the player (CHD-09, CHD-11; PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3).** The death-site list, the rekindled Penitents and the per-kit visit counts are Chronicle-long: they survive death, Hard Unmaking and New Iteration, and only a new Chronicle starts them empty. They store ids and numbers only (kit id, a position, a count; TECH-001 §7). The death-site Penitent uses the existing Penitent behaviour (GDD-001 §8.5) and shares the per-sector Penitent cap with the Coma Penitent (SYS-001 death-site Penitent cap row); a rekindled Penitent is the same Penitent with its lamp kept lit (§9.6). Visit counts drive kit dressing only and are never named on screen (ZONES-001, kit memory (CHD-11)).

The diegetic reason is GDD-001 §6.2: the Lantern Tree, the Ruins and the Codex sit in a pocket the loop cannot touch. It is stated once, in the first Ruins scene, and never in a menu.

**Save cadence is a SYS-001 §8 invariant: never mid-run.** A run writes at Seam boundaries only, so a crash costs at most one Seam.

## 3. The Lantern Tree — 90 nodes

The tree grows in the Ruins (GDD-001 §6.4). Five branches, 18 nodes each, tiers 1–5, purchased with Ember; 27 of them cost 0 Ember and are unlocked by *knowing* one Codex entry instead (§3.7; Unwritten Ink retired 2026-11-18, CHD-15). Nothing is rolled. Capstones are named in GDD-001 §7.2 and are honoured below.

### 3.1 Node conventions

| Convention | Rule |
|---|---|
| ID | `<BRANCH>-<1..18>` where BRANCH ∈ LANTERN, HULL, ORDNANCE, WARD, MADNESS |
| Tier | nodes 1–4 = T1, 5–8 = T2, 9–12 = T3, 13–16 = T4, 17–18 = T5 (capstones) |
| Cost | Ember, one price per tier: SYS-001 §7.7 `Lantern Tree node price, tier 1…5` rows are the source (moved there 2026-11-19, TECH-001 §11.1a Q-T149). The Cost column of the §3.3 tables is a derived per-node view of those rows; if they disagree, SYS-001 wins and the column is a bug. The 27 nodes formerly priced in Unwritten Ink cost **0 Ember** (SYS-001 Ink-node Ember price row; §7.7 `Codex-gated nodes`) and are **Codex-gated**: each needs its gating entry stamped (§3.7). Cost floors roll up in the node rollup below; the respec tax is 10% of banked Ember (§3.5; GDD-001 §7.3 as amended by CHD-15) |
| Requires | at least one node of a lower tier in the same branch; capstones require both T4 nodes of the branch. Cross-branch prerequisites are used **exactly twice in 90 nodes**, both in MADNESS, and both exist to make leaning into warp feel like a commitment. A Codex-gated node also lists its gating entry (`Codex cx_…`) in this column |
| Legibility | GDD-001 §7.3: one line, and the effect must be observable in play. A node whose effect you cannot see in a 15-second clip does not ship |
| Rules-bending share | 30 of 90 (33%), matching the "roughly 30%" of GDD-001 §7.3 |
| Pity | a branch tier unlocks when any `n` nodes of the tier below are bought (`n` = 2 for T2, 3 for T3, 4 for T4, 6 for T5). You can never be hard-walled out of a branch by a bad early purchase |

### 3.2 What the five branches are *for*

Each branch owns a question the player asks themselves. If a node does not belong to its branch's question, it is in the wrong branch.

The two named nodes per branch below are the ones GDD-001 §7.2 names. They sit at tiers 2–4 of §3.3, not at the top: tier 5 carries two capstones per branch of its own, and those ten are listed in §3.6.

| Branch | The question it answers | Fantasy | Named in GDD-001 §7.2 | Named in GDD-001 §7.2 |
|---|---|---|---|---|
| **LANTERN** | *Where do I shine, and where do I hide?* | light as both tool and tell | **Dark Lantern** — the Choir cannot see you in your own light | **Blackout Dash** |
| **HULL** | *How much mistake can I afford?* | the hull as a budget you spend on purpose | **Second Vigil** — one revival per run | **Anchor** |
| **ORDNANCE** | *How do my Charges and my lance behave?* | one gun, many personalities | **Twin Vigil** — a second charge-capacity upgrade may stack | **Homing Song** |
| **WARD** | *How do I answer the Choir without killing it?* | defence that reads as ritual | **Silence the Choir** — four seconds of held breath | **Deconsecrate** |
| **MADNESS** | *What will I pay in Composure for what I want?* | power that is visibly costing you | **Blessed Fracture** — damage scales with the warp you are enduring | **Communion** |

MADNESS is the intended endgame curve (GDD-001 §7.2). It is the only branch whose nodes can be *sold back* mid-run, because its costs are partly Composure; the respec rules for it are in §3.5.

### 3.3 The 90 nodes

Branch tables follow. "Rules-bending?" marks the 30 nodes that change a rule rather than a value. The "Visible in play" column is the acceptance criterion for the node, not flavour text — it is what QA screenshots.

[^tier]: **Tier gate.** A tier-2 node needs any 2 nodes in tier 1 of the same branch; tier 3 needs any 2 in tier 2; and so on. The `Requires` column lists only *hard* named prerequisites on top of that gate, plus, for the 27 Codex-gated nodes, the gating entry (`Codex cx_…`, §3.7). Tier 1 = nodes 1–4, tier 2 = 5–8, tier 3 = 9–12, tier 4 = 13–16, tier 5 (capstones) = 17–18.

[^speed]: **Speed budget.** SYS-001 §1.1 locks `max_speed` 340 px/s as the base and `Full reversal` 0.28 s as design identity; speed nodes are capped at **+12% total across the whole tree** (SYS-001 §1.1). LANTERN-10 (+6%) and LANTERN-13 (+6%) are the entire budget — no other node in this file adds speed, drift or brake in a way that raises it. Both scale `accel` and `brake` by the same percentage so the 0.28 s reversal is unchanged. `accel` itself is 🔒 GDD and is never a node target.

[^gap]: **Rows SYS-001 still owes us** (all `✱`, first-pass, none contradicting an existing row): Ward Pulse base cooldown (proposed 8 s) and base radius (proposed 180 px) plus cooldown/radius ceilings; damage-vs-Choir scaling for Blessed Fracture (GDD-001 §7.2 states +30% per Warp Tier); Shroud-clear-per-second from lamplight; lantern toggle fade time; a shard-yield ceiling now that three nodes raise yield; a drift floor (1.0 body-lengths) and a brake ceiling; a `Surgelight` cooldown floor (0.55 s); a Communion Composure-per-second cost. Each flagged node says which row it needs.

#### LANTERN (branch L) — light, mining, movement

| ID | Node | Tier | Cost (derived: SYS-001 §7.7 by tier) | Currency | Effect (numbers reference SYS-001) | Rules-bending? | Requires | Visible in play |
|---|---|---|---:|---|---|---|---|---|
| LANTERN-1 | Surgelight Charges | 1 | 40 | Ember | SYS-001 §1.1 `Surgelight impulse` becomes a stored charge: 2 held, spent at the row's 1.6 s cooldown. | yes | — | Two wick pips on the HUD; the stern brass vent stands open with a second flare |
| LANTERN-2 | Wide Bellows | 1 | 40 | Ember | SYS-001 §1.1 `Surgelight Shroud burn` radius +25%. | no | — | Each dash opens a shoulder-wide smoking gap in Shroud |
| LANTERN-3 | Full Wick | 1 | 40 | Ember | SYS-001 §1.2 `Lantern radius` 260 → 340 px (that row's stated ceiling). | no | — | The amber pool spans a whole Encounter Kit; rim geodes pop into view |
| LANTERN-4 | Wick Ledger | 1 | 0 | Ember | The Ledger Compass draws your true light ring and marks the nearest unlit corridor (SYS-001 §6 solvability lint). Does not replace the Steady Ledger toggle (GDD-001 §10). | no | Codex `cx_rule_lantern_dark` | An honest amber ring on the compass strip with one chalk tick |
| LANTERN-5 | Dark Lantern | 2 | 120 | Ember | SYS-001 §1.2: `Mining speed, lantern down` 65% → 85% and `Choir detection, lantern down` −60% → −75%; mining dark becomes legal below T3 (row 🔒). | yes | LANTERN-3 | A shuttered cowl module on the bow; your flame shrinks to a coin |
| LANTERN-6 | Long Burn | 2 | 120 | Ember | SYS-001 §1.1 `Surgelight impulse` +20% (⚙). | no | LANTERN-1 | One dash clears a whole kit corridor in a stretched amber smear |
| LANTERN-7 | Brass Bellows | 2 | 120 | Ember | SYS-001 §1.1 `Surgelight` cooldown −25%. | no | LANTERN-1 | Three boosts inside one Acolyte duel |
| LANTERN-8 | Spare Wick | 2 | 120 | Ember | Toggling the lantern down fades the pool over 2 s instead of cutting it (new SYS-001 row `✱`). | no | LANTERN-3 | The light lingers like an afterimage; Choir heads turn a beat late |
| LANTERN-9 | Long Glide | 3 | 260 | Ember | SYS-001 §1.1 `drag` −20% (⚙); `max_speed` and `Full reversal` untouched [^speed]. | no | — | The skiff slides two body-lengths past the geode before settling |
| LANTERN-10 | Keel Light | 3 | 0 | Ember | +6% on SYS-001 §1.1 `max_speed`, with `accel` and `brake` scaled by the same 6% so `Full reversal` stays 0.28 s 🔒. Half of the +12% budget [^speed]. | no | LANTERN-9; Codex `cx_place_the_drowned_observatory` | The bow module leans forward; your wake thread lengthens |
| LANTERN-11 | Blackout Dash | 3 | 0 | Ember | A Surgelight that ends inside a Choir sweep puts your lantern out at the far end for 2 s and the Choir loses acquisition — you are buying back against SYS-001 §1.2 `Acquisition loss timer`. | yes | LANTERN-1, LANTERN-5; Codex `cx_rule_the_passing` | You arrive dark, the flame gutters, Choir heads swing through where you were |
| LANTERN-12 | Hot Lantern | 3 | 260 | Ember | Your light pool eats Shroud at 1 HP / 6 s (SYS-001 §9 `Shroud` HP 3; row needed [^gap]). | no | LANTERN-3 | Shroud curls back from your lamplight, steaming at the rim |
| LANTERN-13 | Keel Deep | 4 | 520 | Ember | +6% on SYS-001 §1.1 `max_speed`, same scaling rule as LANTERN-10; with it this node is the whole +12% budget [^speed]. | no | LANTERN-10 | The stern grows a second vent; a chase now closes visibly slower |
| LANTERN-14 | Phosphor Trail | 4 | 520 | Ember | Each Surgelight leaves a phosphor lane for 3 s; Choir crossing it take one lance hit (SYS-001 §3 unit HP: Grub 4, Acolyte 6, Listener 12) and the Listener's arc resets. | yes | LANTERN-1 | A bruise-cyan road behind you; Grubs that touch it light up and pop |
| LANTERN-15 | Lantern Inferno | 4 | 520 | Ember | Light-pool Shroud clear rate 1 HP / 6 s → 2 HP / 6 s (SYS-001 §9 `Shroud`). | no | LANTERN-12 | A corridor of bone-pale ground opens behind you in one pass |
| LANTERN-16 | Oiler's Chain | 4 | 520 | Ember | SYS-001 §1.1 `Surgelight` cooldown a further −20%, to a 0.55 s floor (`✱` ceiling row [^gap]). | no | LANTERN-7 | You boost three times inside one Grave-Tide wave |
| LANTERN-17 | The Ninth Lantern | 5 | 900 | Ember | Capstone: inside your light pool the HUD cannot lie (WARP-001 §4 `HUD lies` row, SYS-001 §6 `Ledger Compass`), Deacon of Lies phantoms break apart, and Choir units hold fire at the pool's rim (SYS-001 §3.1 `Shrine hold-fire` extended to the lamp). | yes | LANTERN-3, LANTERN-5 | A clean circle of honest gaslight cut into a T4 sky; the chant stops at the rim |
| LANTERN-18 | Lamp of the Failed Sky | 5 | 0 | Ember | Capstone: at full radius the Waking Dark treats your lantern as a Shrine and holds for 3 s, once per sector (extends SYS-001 §3.1 hold-fire law to the entity; new `✱` row). | yes | LANTERN-17; Codex `cx_glass_ninth_light` | The Dark Star turns its face away from one small lamp, and the sector goes quiet |

#### HULL (branch H) — plating, drift, braking, survival

| ID | Node | Tier | Cost (derived: SYS-001 §7.7 by tier) | Currency | Effect (numbers reference SYS-001) | Rules-bending? | Requires | Visible in play |
|---|---|---|---:|---|---|---|---|---|
| HULL-1 | Drift Control | 1 | 40 | Ember | SYS-001 §1.1 `drag` +25% (⚙): terminal drift falls from the ≈1.4 body-lengths of GDD-001 §4.2 to ≈1.1. | no | — | The skiff stops where you let go instead of sliding past the geode |
| HULL-2 | Dead Reckoning | 1 | 40 | Ember | The Compass lie (SYS-001 §6 `Ledger Compass`, lies at T ≥ 3 or Composure ≤ 3) now carries a chalk strike, so you can see that it is a lie. | yes | — | A barred scratch across one compass blip; you learn to distrust it |
| HULL-3 | Brake Radius | 1 | 40 | Ember | SYS-001 §1.1 `brake` +25%, and the same row's 0.2 s confirmed-stop window is drawn as a chalk ring. | no | — | A chalk circle blooms under the ship whenever Space is held |
| HULL-4 | Plating | 1 | 40 | Ember | SYS-001 §1.2 `Hull HP` 1 → 2 (that row names HULL-4); the first hit of a run shears the plate instead of killing you. | no | — | A brass plate module bolts to the flank (ART-002); the first hit rings off it like a bell |
| HULL-5 | Deep Anchor | 2 | 120 | Ember | SYS-001 §1.1 `brake` a further +15%; the confirmed-stop window 0.2 → 0.3 s (⚙). | no | HULL-3 | You park dead still on a geode face and mine without drifting |
| HULL-6 | Second Vigil | 2 | 120 | Ember | One revive per run: the first lethal hit puts you back in the same Seam at full lantern. The SYS-001 §1.5 `Death` Composure penalty and §1.2 `Acquisition loss timer` both still apply. | yes | HULL-4 | The screen cracks, one bell, and the skiff re-forms out of brass dust |
| HULL-7 | Drift Baffles | 2 | 120 | Ember | SYS-001 §1.1 `drag` +30% more, to a drift floor of 1.0 body-lengths (floor row needed [^gap]). | no | HULL-1 | The ship lands on a geode and stays there; no bounce-off |
| HULL-8 | Long Watch | 2 | 0 | Ember | SYS-001 §1.2 `Acquisition loss timer` 2.2 → 3.0 s, so a dark break shakes the Dark Star sooner. Meaningless at Hunger ≥ 6 (SYS-001 §2.2: it never loses you). | no | Codex `cx_vigil_still_lit` | The Dark Star's face turns away a full second after your light dies |
| HULL-9 | Anchor Field | 3 | 0 | Ember | Holding Space plants the skiff and drops the Anchor field: SYS-001 §1.1 `anchor` rows, ring 190 px, freezing nearby Choir for 6.0 s on a 20 s rearm. Hangs off the SYS-001 §1.1 `brake` note about Anchor nodes widening the confirmed-stop window. | yes | HULL-3; Codex `cx_choir_grave_tide` | A chalk circle blooms; Grubs stop mid-carry and the censer swings and halts |
| HULL-10 | Anchor Ring | 3 | 260 | Ember | The Anchor field ring radius +35% (same row as HULL-9). | no | HULL-9 | The chalk ring is wide enough to cover a whole geode cluster |
| HULL-11 | Unshakeable | 3 | 260 | Ember | While Frayed, the SYS-001 §1.5 Frayed-band magnitudes (all `✱`) are halved. | no | — | The chromatic edge and the sliding HUD numbers settle while your wick is low |
| HULL-12 | Chalkfast | 3 | 260 | Ember | The Anchor field's rearm 20 → 14 s (SYS-001 §1.1 `anchor` rows). | no | HULL-9 | The ring chimes again before the Grub procession can re-form |
| HULL-13 | Wide Anchor | 4 | 520 | Ember | Anchor ring radius +70% over HULL-10; ring ceiling flagged in [^gap]. | no | HULL-10 | The ring covers a whole Encounter Kit and every Grub in it |
| HULL-14 | Plate Remembers | 4 | 520 | Ember | Plating re-arms at the start of each Seam instead of once per run; the SYS-001 §1.2 `Hull HP` ceiling of 2 is unchanged. | yes | HULL-4 | A fresh plate welds itself on at every Seam with a shower of sparks |
| HULL-15 | Hard Vigil | 4 | 520 | Ember | SYS-001 §1.1 `brake` a further +25%; confirmed-stop window 0.3 → 0.4 s (brake ceiling needed [^gap]). | no | HULL-5 | Braking throws visible chalk dust and the ship plants like a stake |
| HULL-16 | Anchor Overdrive | 4 | 0 | Ember | The Anchor field's freeze 6.0 → 8.0 s, with the ring at its 436 px ceiling (SYS-001 §1.1 `anchor` rows). | no | HULL-9, HULL-13; Codex `cx_choir_unnumbered` | Choir units stand frozen while their chant frays at the edges |
| HULL-17 | Anchor Against God | 5 | 900 | Ember | Capstone: the Anchor field suspends the Waking Dark's contact death for you for 1.5 s, once per rampage (extends SYS-001 §2 phase 4 and the §1.1 Anchor note to the entity; new `✱` row). Stays inside the agency-loss budget of GDD-001 §8.7 criterion 3. | yes | HULL-9, HULL-13 | The Dark Star stops dead on a chalk circle drawn by a lamp |
| HULL-18 | Hollow Hull | 5 | 0 | Ember | Capstone: while Frayed or worse your silhouette reads to the Choir as one of its own (SYS-001 §3.1 `Targeting law`, §3 `Deacon of Lies` phantoms); units will not fire first, and mining or lance fire breaks it. | yes | HULL-6; Codex `cx_rule_hollow_sector` | Grubs walk past you mid-carry — but the Ledger Compass still reads you as you, and that is the tell |

#### ORDNANCE (branch O) — Arc-Lance and Null-Iron Charges

No node here adds a lance fuel bar, a reload meter or an in-run upgrade roll (GDD-001 §3 anti-pillars 1, 2, 8). Charges stay fire-and-forget (GDD-001 §8.3) and the 13-hits-to-unmake requirement (GDD-001 §8.3) is never lowered.

| ID | Node | Tier | Cost (derived: SYS-001 §7.7 by tier) | Currency | Effect (numbers reference SYS-001) | Rules-bending? | Requires | Visible in play |
|---|---|---|---:|---|---|---|---|---|
| ORDNANCE-1 | Hookline | 1 | 40 | Ember | SYS-001 §1.4 `Shard magnet radius` 96 → 190 px. | no | — | A brass line trails from the bow and shards hook themselves onto it |
| ORDNANCE-2 | First Sermon | 1 | 40 | Ember | The first Charge of each sector cannot be intercepted (SYS-001 §1.4 `Charge HP (interceptable)`; the §2.2 Hunger-4 interception rule does not apply to it). | yes | — | It flies through a wall of Grubs untouched, one chime on the way out |
| ORDNANCE-3 | Lance Rate I | 1 | 40 | Ember | SYS-001 §1.3 `Fire rate` 6/s → 7/s (base 🔒; the 9/s ceiling is the capstone chain). | no | — | The muzzle glow runs continuous and a small geode face gives way inside the 0.9 s row |
| ORDNANCE-4 | Charge Capacity I | 1 | 40 | Ember | SYS-001 §1.4 `Charge magazine` 5 → 6 (ceiling chain 7 / 9 / 13; the row's per-run Sigil cap is untouched). | no | — | Two more lamp pips along the ship's spine |
| ORDNANCE-5 | Pierce | 2 | 0 | Ember | SYS-001 §1.3 `Hits per projectile` 1 → 2: lance shots now pass through the first Acolyte they hit. | no | Codex `cx_choir_acolyte` | The bolt exits the far side trailing a thread of glass |
| ORDNANCE-6 | Twin Vigil | 2 | 120 | Ember | SYS-001 §1.4 `Charge cap gain per run` 1 → 2 — the chain that row names: two capacity upgrades may stack inside one run. | yes | — | Two spare charge racks bolt onto the hull at every Seam |
| ORDNANCE-7 | Lance Rate II | 2 | 120 | Ember | SYS-001 §1.3 `Fire rate` 7/s → 8/s. | no | ORDNANCE-3 | The flame-pipe barrel runs amber-hot and audibly hisses |
| ORDNANCE-8 | Fourth Shard | 2 | 120 | Ember | SYS-001 §1.3 `Shards per geode (calm kill)` base 3 → 4 (yield ceiling flagged in [^gap]). | no | — | Every shattered geode coughs out one more shard |
| ORDNANCE-9 | Charge Capacity II | 3 | 0 | Ember | SYS-001 §1.4 `Charge magazine` 6 → 7 — that row's tree ceiling, opened by the Codex's record of the charge-rites. | no | ORDNANCE-4; Codex `cx_glass_null_iron` | The spine rail fills with a third rack of glass bells |
| ORDNANCE-10 | Bomb Casing | 3 | 260 | Ember | SYS-001 §1.4 `Charge HP (interceptable)` 1 → 2 dmg unit; Listener shots on it 2 → 3 (`✱`). | no | — | Grub jaws clang off the casing instead of popping it |
| ORDNANCE-11 | Homing Song | 3 | 0 | Ember | SYS-001 §1.4: `Charge speed` 210 → 250 px/s and `Turn authority` 1.6 → 2.6 s, at the Composure cost that row already carries. | yes | ORDNANCE-4; Codex `cx_choir_listener` | Charges curve wide around geodes humming a choir note, and the Choir turns toward the sound |
| ORDNANCE-12 | Detonation Discipline | 3 | 260 | Ember | SYS-001 §1.3 `Over-fire detonation` threshold 9 hits in 1.2 s → 12 hits, and `Shards per geode (detonated)` scatter 140 px → 90 px (⚙/`✱`). | no | — | Panic fire no longer scatters glass to the Grubs; the shards drop at your feet |
| ORDNANCE-13 | Nine-Syllable Lance | 4 | 0 | Ember | SYS-001 §1.3 `Fire rate` 8/s → 9/s — that row's ceiling, opened by the Choir's own firing litany transcribed into the Codex. | no | ORDNANCE-7; Codex `cx_choir_litany_ring` | Every muzzle flash leaves a nine-petal flower of light on the glass |
| ORDNANCE-14 | Charge Capacity III | 4 | 520 | Ember | SYS-001 §1.4 `Charge magazine` 7 → 9 (the chain's next step; 13 stays with ORDNANCE-18 and Run Sigils). | no | ORDNANCE-4, ORDNANCE-6 | Nine pips, the spine rail full; the HUD strip spans half the ship |
| ORDNANCE-15 | Shatter Shot | 4 | 520 | Ember | SYS-001 §1.3 `Hits per projectile` 2 → 3 — the `Shatter Shot` chain that row names. | yes | ORDNANCE-5 | The bolt bursts on impact into three splinters that each find a body |
| ORDNANCE-16 | Fifth Shard | 4 | 520 | Ember | SYS-001 §1.3 `Shards per geode (calm kill)` base 4 → 5; the combined-yield ceiling is flagged in [^gap]. | no | ORDNANCE-8 | A geode breaks into a fistful and the Grubs get nothing extra from it |
| ORDNANCE-17 | Null-Iron Hymn | 5 | 0 | Ember | Capstone: Charges also home on Sepulchre processions and knock 1 segment point off the deposit they intercept (SYS-001 §2 phase 1 and the §2.1 module row). A race-mechanic win, not a kill-mechanic discount. | yes | ORDNANCE-11; Codex `cx_chron_unmade_at_t3` | Charges swerve off the entity and slam into the choir line; a censer goes dark |
| ORDNANCE-18 | Thirteen Bells | 5 | 900 | Ember | Capstone: SYS-001 §1.4 `Charge magazine` ceiling 13 — the row's top step, with the ORDNANCE-6 chain intact. You can enter a Seam carrying a full unmake-load; the 13 hits needed for a complete entity (GDD-001 §8.3) are unchanged. | yes | ORDNANCE-14, ORDNANCE-17 | Thirteen lamp pips along the spine, and one pass is now enough to empty them into the Dark Star |

#### WARD (branch W) — rites, salt, silencing the litany

| ID | Node | Tier | Cost (derived: SYS-001 §7.7 by tier) | Currency | Effect (numbers reference SYS-001) | Rules-bending? | Requires | Visible in play |
|---|---|---|---:|---|---|---|---|---|
| WARD-1 | Short Rite | 1 | 0 | Ember | Ward Pulse cooldown −25% against the proposed base row (SYS-001 owes this row [^gap]). | no | Codex `cx_choir_shrine` | The pulse chime comes sooner and the chalk sigil on the hull blinks faster |
| WARD-2 | Salt Glass Mines | 1 | 40 | Ember | SYS-001 §2 phase 0 carries the number: a salt ward blocks 1 deposit for 30 s. You now place them from the Tree instead of only via Pact. | yes | — | A jar of salt-glass at the Sepulchre's foot; the Grub walks in and the keening starts |
| WARD-3 | Ward Reach | 1 | 40 | Ember | Ward Pulse radius +30% (proposed base 180 px [^gap]). | no | — | The pulse ring crosses the whole kit and lifts phantoms off the floor |
| WARD-4 | Salt the Wound | 1 | 40 | Ember | Each pulse removes 2 of a Shroud cell's 3 HP (SYS-001 §9 `Shroud`, baseline 1 Ward-slice). | no | — | Shroud peels back in a ring and the floor beneath it is bone-pale |
| WARD-5 | Ward Reach II | 2 | 120 | Ember | Ward Pulse radius +30% more (ceiling flagged [^gap]). | no | WARD-3 | The ring now covers a whole geode cluster and every Grub working it |
| WARD-6 | Silence the Choir | 2 | 0 | Ember | A Ward Pulse on the Sepulchre halts deposits for 4 s — the SYS-001 §3.1 `Litany Ring` deposit-halt number, aimed straight at the phase-0 timer (GDD-001 §13 P1). | yes | WARD-2; Codex `cx_choir_matron` | The chant cuts out mid-syllable; every Grub in the procession drops and the deposit bar stops |
| WARD-7 | Deacon Bane | 2 | 120 | Ember | Phantoms dispelled by Ward (SYS-001 §3 `Deacon of Lies`, `Phantom`) refund the 0.3 Composure they drain on first sight (new `✱` row). | no | — | The false Grub bursts and your vision clears with a bell |
| WARD-8 | Ward Rite Fast | 2 | 120 | Ember | Ward Pulse cooldown −20% more. | no | WARD-1 | Two pulses inside one Acolyte duel |
| WARD-9 | Choir's Own Bell | 3 | 0 | Ember | The Ward's silence on Rite bosses 3 → 6 s; the base 3 s lives in the SYS-001 §5.1 `Ash Matron` row and the §5.1 `Unnumbered` re-skin row. | no | WARD-8; Codex `cx_place_litany_pew` | The Matron hangs mid-hymn, its mouth working with no sound in it |
| WARD-10 | Deconsecrate | 3 | 260 | Ember | Warding a Shrine collapses it: you collect the SYS-001 §6 `Shrine purge reward` (+1 Composure, −1 Corruption, and Ember in place of the retired Ink: value owed, CHD-15 — that row, not ours) and the §3.1 120 px hold-fire law stops applying to that spot. **Phase-2 case (TECH-001 Q-T121, GDD §8.4):** warding a Litany Ring node of a phase-2 (Guard) Sepulchre destroys that outer ring node instead; Shrines elsewhere collapse as above. | yes | WARD-3 | The shrine's chalk floor caves in; the Choir around it turns and fires |
| WARD-11 | Salt Lantern | 3 | 260 | Ember | The pulse reveals phantoms and the Grave-Tide Deceiver's decoy lantern (SYS-001 §3, base decoy 2 s) for 3 s. | no | WARD-3 | Decoy lanterns look visibly wrong in pulse-light; yours casts a shadow |
| WARD-12 | Long Silence | 3 | 260 | Ember | Ward Pulse cooldown a further −15%, to a 3 s floor (floor row needed [^gap]). | no | WARD-1, WARD-8 | You answer two processions in one crossing |
| WARD-13 | False Lantern | 4 | 0 | Ember | You drop a decoy lamp — the Grave-Tide Deceiver's own trick (SYS-001 §3): Choir units acquire it instead of you for 3 s, and for that time your light reads to them as a Shrine under the §3.1 law. | yes | WARD-11; Codex `cx_choir_deacon` | A second lamp of your own burns on the ground and the whole Choir turns to it |
| WARD-14 | Ringbreaker | 4 | 520 | Ember | The Litany Ring break threshold drops from 4 nodes down to 3 (SYS-001 §3.1 `Litany Ring`: 8 nodes at the Sepulchre; the row's halt duration is untouched). | no | WARD-6 | Three dark censers and the whole procession kneels |
| WARD-15 | Wide Reach III | 4 | 520 | Ember | Ward Pulse radius +40% more (radius ceiling flagged [^gap]). | no | WARD-5 | The pulse reaches the next Encounter Kit through the corridor |
| WARD-16 | Salt Hoard | 4 | 520 | Ember | The salt ward's duration 30 → 45 s (extends the SYS-001 §2 phase 0 row; `✱`). | no | WARD-2 | You carry two jars and the keening lasts a whole crossing |
| WARD-17 | The Quiet Ninth | 5 | 900 | Ember | Capstone: the Ward may be *held*. While held, Choir inside the radius stop chanting, mining and depositing until you take any action (extends the §3.1 `Litany Ring` halt and the §5.1 silence rows; new `✱` row). | yes | WARD-6, WARD-10 | Total silence: the censer frozen mid-swing, your own flame stretched thin |
| WARD-18 | Unconsecrated Sky | 5 | 0 | Ember | Capstone: Ward a Shrine and carry it — the §3.1 120 px hold-fire law follows the carried shrine for one Seam, and the §6 purge reward applies when you set it down. | yes | WARD-10; Codex `cx_choir_saint` | You walk with a broken altar on your back, and the Choir will not shoot near it |

#### MADNESS (branch M) — Composure, Warp Tiers, the voice that answers

MADNESS is the Codex branch: 9 of its 18 nodes are Codex-gated (0 Ember, unlocked by knowing one entry each, §3.7), more than any other branch, because its power comes from what you have *learned* about the entity (GDD-001 §7.1). It buys power with dread, never with a survival meter — no node here adds HP, a hunger bar or a second life beyond HULL-6 and the SYS-001 §1.5 Hollowed free death, and none of them stack.

| ID | Node | Tier | Cost (derived: SYS-001 §7.7 by tier) | Currency | Effect (numbers reference SYS-001) | Rules-bending? | Requires | Visible in play |
|---|---|---|---:|---|---|---|---|---|
| MADNESS-1 | Fray Reading | 1 | 40 | Ember | SYS-001 §1.5 Frayed-band `false audio cues` (1 per 40 s) halves to 1 per 80 s, and each cue instead points at the nearest real procession (new `✱` row). | no | — | The false chant arrives from the direction of the true Sepulchre |
| MADNESS-2 | Look Away | 1 | 0 | Ember | While you sit inside the entity's acquisition cone and are not firing, the §1.5 `-1.0/s in gaze cone` drain stops: the stare becomes readable instead of expensive. | yes | Codex `cx_rule_gaze` | The great eye holds on you and your wick stops guttering |
| MADNESS-3 | Tremor Hand | 1 | 0 | Ember | The Unmoored-band inverted-axis bursts (SYS-001 §1.5, `✱` magnitudes) shorten from 4 s to 2 s. | no | Codex `cx_rule_frayed` | Your hands stop fighting the wheel for two seconds instead of four |
| MADNESS-4 | Bitter Candy | 1 | 40 | Ember | While Frayed or worse, SYS-001 §7.1 `Chain bonus` caps at +80% instead of +50% (`✱` row) — madness pays in Ember, not in score-only pride. | no | — | The Vigil Index strip runs red and keeps climbing while the screen shakes |
| MADNESS-5 | Clear Eyed | 2 | 0 | Ember | SYS-001 §1.5 `MADNESS-5` row exactly as written: spend 1 Composure to set your own Warp Tier effect off for 20 s. | yes | MADNESS-2; Codex `cx_rule_unmoored` | The palette snaps back to honest gaslight, phantoms fall apart, the HUD stops moving |
| MADNESS-6 | One-Syllable Truth | 2 | 120 | Ember | Phantoms die to 1 lance hit while you are Frayed or worse (SYS-001 §3 `Deacon of Lies`, `Phantom`: base 2 hits or a Ward). | no | — | The false Grub bursts from one shot, and the real ones now look wrong to you |
| MADNESS-7 | Hollow Ledger | 2 | 0 | Ember | While Frayed or worse, a first kill stamps its Codex entry **at the kill, mid-run**, instead of queuing it for the run summary (§8.6); no page opens mid-fight. The branch feeds on what it learns (rewritten 2026-11-18, CHD-15: the former +5 Ink per first kill retired with Ink). | no | Codex `cx_rule_bleeding` | The Codex stamp glows bruise-magenta on a first kill |
| MADNESS-8 | Cheap Ecstasy | 2 | 120 | Ember | `Clear Eyed` costs 0.5 Composure instead of 1 (adjusts the cost half of the SYS-001 §1.5 `MADNESS-5` row; ⚙). | no | MADNESS-5 | The snap-back costs half a wick and leaves no ring of pain behind it |
| MADNESS-9 | Warp Bounty | 3 | 260 | Ember | While Frayed or worse, the SYS-001 §7.1 `Warp multiplier` (⚙ rows: ×1.2 at T2–T3, ×1.5 at T4–T5) steps up one band. | no | — | The score strip bruises purple and runs hotter than the sky above it |
| MADNESS-10 | Deep Fracture | 3 | 260 | Ember | The SYS-001 §1.5 Hollowed rule `MADNESS branch effects ×2` also applies at Warp T ≥ 3 while you are Unmoored. | no | — | A bruise-coloured ring brightens along your own hull |
| MADNESS-11 | Communion | 3 | 0 | Ember | The entity speaks its next action 2 s before it acts — the voice-as-state channel of GDD-001 §12 and SYS-001 §2.2, pushed one step further; costs 0.5 Composure/s while up (row needed [^gap]). | yes | MADNESS-5; Codex `cx_choir_procession` | One big word arrives before the lunge, and you were already leaving |
| MADNESS-12 | Hollow Chain | 3 | 0 | Ember | While Hollowed, the SYS-001 §7.1 `Chain bonus` never resets on hit-taken (`✱`) — a hit still kills you, which is the point. | no | Codex `cx_rule_hollowed` | The Index keeps climbing while the screen cracks around it |
| MADNESS-13 | Long Clear | 4 | 520 | Ember | `Clear Eyed` runs 30 s instead of the 20 s of the SYS-001 §1.5 `MADNESS-5` row (extends that row; `✱`). | no | MADNESS-5, MADNESS-8 | Half a minute of honest HUD inside a warped sky |
| MADNESS-14 | Blessed Fracture | 4 | 0 | Ember | GDD-001 §7.2: damage +30% per Warp Tier. SYS-001 has no damage-vs-Choir row to hang this on yet, so the scaling is ours to place ([^gap]). | yes | MADNESS-10; Codex `cx_rule_inverted` | Each Warp Tier adds another bruise ring on the lance muzzle, and your shots leave the hull trailing glass |
| MADNESS-15 | Communion Held | 4 | 520 | Ember | `Communion` costs 0.25 Composure/s instead of 0.5 (same row as MADNESS-11). | no | MADNESS-11 | You can keep listening to the Dark Star without paying for it in wick |
| MADNESS-16 | Hunger Feast | 4 | 520 | Ember | While Frayed or worse, SYS-001 §1.3 calm-kill shard yield gains +1; the combined-yield ceiling with ORDNANCE-8 and ORDNANCE-16 is flagged in [^gap]. | no | — | Geodes burst fat when your wick is low, and the Grubs scramble too late |
| MADNESS-17 | Unravel Focus | 5 | 0 | Ember | Capstone: GDD-001 §4.1's R key becomes available from the first Seam of Act 3 instead of Act 4 only, and the SYS-001 §2 phase 6 `latch time` 1.4 → 1.0 s (⚙). | yes | MADNESS-11, MADNESS-14; Codex `cx_chron_thread_iv` | The white reticle opens on a lunge and you push the world back a hand's width |
| MADNESS-18 | The Ninth Sky Looks Back | 5 | 0 | Ember | Capstone: once per run you speak in the entity's own voice-channel (GDD-001 §12; SYS-001 §2.2): one Choir unit stands down for 6 s and the nearest Sepulchre's current procession is spent (SYS-001 §2 phase 1, §3.1 `Litany Ring`). | yes | MADNESS-11; Codex `cx_rule_the_glimpse` | Your HUD types in the entity's big type, and a censer goes out mid-hymn |

#### Node rollup

| Branch | Nodes | Ember total | Codex-gated nodes (0 Ember) | Rules-bending nodes |
|---|---:|---:|---:|---:|
| LANTERN | 18 | 4,100 | 4 | 6 |
| HULL | 18 | 3,760 | 4 | 6 |
| ORDNANCE | 18 | 3,500 | 5 | 6 |
| WARD | 18 | 3,720 | 5 | 6 |
| MADNESS | 18 | 2,400 | 9 | 6 |
| **Total** | **90** | **17,480** | **27** | **30** |

Counts by price: 63 nodes bought with Ember, 27 Codex-gated at 0 Ember (12 numeric + 15 rules-bending; these are the nodes priced in Unwritten Ink before Rev 1.3, CHD-15). 30 of 90 nodes (33%) are rules-bending, against the ~30% target in GDD-001 §7.3. All 10 tier-5 capstones are rules-bending: the cost model prices tier 5 only at the SYS-001 §7.7 tier-5 price or Codex-gated, so a purely numeric capstone has no legal price — a judgement call worth confirming. The Ember totals are unchanged by the retirement, because the 27 gated nodes never carried an Ember price.

Pacing against the ~450–800 Ember per run in SYS-001 §7.2. Ember is the binding currency in four branches: LANTERN 6–10 runs, HULL 5–9, ORDNANCE 5–8, WARD 5–9 to full-clear; MADNESS needs only 3–6 runs of Ember, and its other 9 nodes wait on what the player *knows*, so **MADNESS is gated by the Codex, not by Ember** — endgame power comes from engaging the game (first kills, revelations, WARP-001 conditions) rather than from farming, and the §3.7 backstops guarantee every gate by Iteration *t* at the latest. The whole tree costs 17,480 Ember: 22–39 runs at Entropy 0 on Ember alone. The Rev 1.2 Ink-side pacing (and the combined completionist estimate built on it) is **to re-run without Ink** with §9.5.


### 3.4 The named nodes GDD-001 §7.2 requires

These ten are named by the GDD and must exist as written. They are not the tier-5 capstones (§3.6); a capstone is not a bigger number, it is a second verb, and each of these earns its own row in the game's tutorial-free onboarding: the first time you buy one, the Codex gets an entry and the entity says one line about it (AUDIO-001 §6).

| Named node | Node ID | Tier | What it actually changes | Counterplay it removes / adds | Test that proves it works |
|---|---|---:|---|---|---|
| **Dark Lantern** | LANTERN-5 | 2 | lighting up no longer raises Choir detection; instead it *repels* Grubs from the lit area | removes the lantern trade-off in Act 2, adds the Deacon's lie as the new threat | a player walks a lit corridor past a procession undetected |
| **Blackout Dash** | LANTERN-11 | 3 | a Surgelight ending inside a Choir sweep puts your lantern out for the node row's 2 s and breaks acquisition | you can now escape a Rampage, but you arrive blind | dash into a Waking and still land the first Unravel hit |
| **Second Vigil** | HULL-6 | 2 | one revival per run, at the place you died, with the §1.5 death penalty and §1.2 acquisition timer still running | removes one death from the run's budget; the entity remembers and adjusts | die in Seam 2 twice and confirm the second death is final |
| **Anchor** | HULL-9 (`Anchor Field`) | 3 | holding the brake key plants the skiff and drops a six-second freeze field (SYS-001 §1.1 `anchor` rows) | removes escape-by-momentum; adds the Deceiver's bait as the answer | Anchor during a deposit and break the ring |
| **Twin Vigil** | ORDNANCE-6 | 2 | a second Charge capacity upgrade may stack inside one run, so the magazine builds further per run | halves your margin for interception while raising what you can carry | two capacity Sigils in one run and confirm the magazine stacks |
| **Homing Song** | ORDNANCE-11 | 3 | Charges curve hard — and Choir units home toward Charges in flight | converts interception from a threat into a lure you can aim | use a Charge to pull a Deacon out of cover |
| **Silence the Choir** | WARD-6 | 2 | Sepulchre deposits halt for 4 s when you Ward | removes the free 4 s; adds a cooldown tell | interrupt at phase 3 and hold phase 3 for 40 s |
| **Deconsecrate** | WARD-10 | 3 | a converted Shrine can be broken instead of avoided, and its hold-fire law dies with it | removes the "Shrines are terrain" assumption | purge a bruised sector's Shrine before it hits 10 |
| **Blessed Fracture** | MADNESS-14 | 4 | +30% damage per Warp Tier you are currently under (GDD-001 §7.2) | the punishment *is* the build | a T4 run kills a Rite boss 1.9× faster than a T1 run |
| **Communion** | MADNESS-11 | 3 | you hear the entity's next move as a voice line, 2 s early, paid in Composure | removes surprise, adds Composure drain | call a Rampage 3 s before it starts |

Two of these disagreed with their own node row in §3.3 and went to the owner as questions, tracked here rather than papered over: **Twin Vigil** is named as "Charges fire in pairs" but §3.3 ORDNANCE-6 buys a second stacking capacity upgrade rather than double-counting Unravel hits; **Anchor** is described above as a field, while the node is a 0.8 s freeze on a 6 s cycle. SYS-001 §1.4 governs the capacity chain either way, and the GDD's name stays on both nodes. Both disagreements are resolved by owner decision on 2026-11-16, recorded in GDD-001 §18 as D-10 and D-11: Twin Vigil is the capacity chain and paired Charge fire belongs to SIG-O-15 *Twin Flint*; Anchor is the six-second freeze field, and its numbers are now rows in SYS-001 §1.1.

### 3.5 Respec and node economy rules

- Respec costs **10% of banked Ember** (SYS-001 respec cost row; GDD-001 §7.3 as amended by CHD-15, PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3 — it replaced "10% of banked Ink"). It is a convenience tax and never gates progress.
- A respec refunds Ember in full for everything below the highest purchased tier. Codex-gated nodes refund nothing because they cost nothing, and their gate stays met: a stamped entry is never un-stamped (§8.1), so a respecced gated node can be re-bought at once; MADNESS nodes bought with Composure refund the Composure only if you are currently **Clear** (SYS-001 §1.5 band), otherwise the Composure is gone — that is the branch's price.
- **One respec per iteration, free after Hard Unmaking.** The loop's reset is a build-reset, which is the roguelike convention the GDD's macro layer is built on.
- No node is ever sold by the game. No node is randomly removed. GDD-001 §7.3: purchased, not rolled.

### 3.6 The ten tier-5 capstones

Tier 5 is the top of a branch (two capstones per branch, 17th and 18th node). All ten are rules-bending, all ten are priced at the SYS-001 §7.7 tier-5 price or Codex-gated at 0 Ember (§3.7), and each one has a named counterplay so it never becomes a win button.

| Node ID | Capstone | Branch | What it opens | Counterplay it adds / costs |
|---|---|---|---|---|
| LANTERN-17 | The Ninth Lantern | LANTERN | inside your light pool the HUD cannot lie, Deacon phantoms break apart, and Choir units hold fire at the pool's rim | the pool is a fixed radius: stay lit, stay predictable, and the Deacon's lie is answered — so the Choir's answer is to fight outside the ring |
| LANTERN-18 | Lamp of the Failed Sky | LANTERN | once per sector, at full radius, the Waking Dark treats your lantern as a Shrine and holds for 3 s | one use per sector, and it costs the light you would have spent mining that sector |
| HULL-17 | Anchor Against God | HULL | the Anchor field suspends the entity's contact death for 1.5 s, once per rampage | within the agency-loss budget and cannot be used to stand inside the Dark Star: it buys an exit, not a stay |
| HULL-18 | Hollow Hull | HULL | while Frayed or worse your silhouette reads to the Choir as one of its own, and units will not fire first | mining or lance fire breaks it instantly, and the Ledger Compass still reads you as you — the tell is on your own screen |
| ORDNANCE-17 | Null-Iron Hymn | ORDNANCE | Charges home on Sepulchre processions and knock a segment point off the deposit they intercept | a race mechanic, not a kill discount: the Charges you spend on the line are Charges not spent on the entity |
| ORDNANCE-18 | Thirteen Bells | ORDNANCE | the Charge magazine ceiling of 13, so one pass can carry a full unmake-load | carrying 13 through a Seam is the risk: interception and Grub jaws now cost you a real Unravel load |
| WARD-17 | The Quiet Ninth | WARD | the Ward may be held: Choir inside the radius stop chanting, mining and depositing until you act | your own flame stretches thin while held, and any action of yours ends it — including firing |
| WARD-18 | Unconsecrated Sky | WARD | Ward a Shrine and carry it: the 120 px hold-fire law follows it for one Seam, and the purge reward pays when you set it down | you are slower and larger while carrying, and the Choir's answer is to shoot the ground you walk over |
| MADNESS-17 | Unravel Focus | MADNESS | the Unravel key is live from the first Seam of Act 3 instead of Act 4, and latch time drops 1.4 → 1.0 s | it is Codex-gated (`cx_chron_thread_iv`), not bought with Ember, so it arrives only once the Codex knows the fourth Thread — or when the §3.7 backstop stamps it |
| MADNESS-18 | The Ninth Sky Looks Back | MADNESS | once per run you speak in the entity's own voice-channel: one Choir unit stands down for 6 s and the nearest Sepulchre's procession is spent | once per run only, and it speaks with the entity's voice — the Composure band you are in is visible in the tell |

### 3.7 Codex-gated nodes: the gating map and the backstops

Unwritten Ink is retired (CHD-15; PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, design §10.2). Ink was already a knowledge currency in disguise — nearly all of it came from Codex stamps — so the 27 nodes it priced now ask for the knowledge directly. The shape of the economy does not change; one noun leaves the game.

| Rule | Statement |
|---|---|
| Price | **0 Ember** (SYS-001 Ink-node Ember price row). The node is bought, not granted: the player still chooses it at the Lantern Tree, and nothing is rolled (GDD-001 §7.3) |
| Gate | the node's gating Codex entry must be **stamped** (§8). The tier gate ([^tier], §3.1 Pity) and any named prerequisite in `Requires` still apply on top |
| Two sources per entry | every gating entry has a **discovery** source (play, below) and a **deterministic backstop**, so GDD-001's "progress is guaranteed" (P4) and the §3.1 pity rule hold for a player who never finds it |
| Backstop (a): tier floor | every gating entry of node tier *t* is stamped automatically at the start of Iteration *t*; tier-1 entries are stamped after the Chronicle's third run (SYS-001 gating backstop rows: tier-t entries, tier-1 entries) |
| Backstop (b): death teaches | each death stamps the oldest still-pending gating entry, lowest tier first (SYS-001 gating backstop per-death row). Within one tier, the order is this table's order (confirmed 2026-11-18; cosmic horror design call within CHD-15, flagged in the Phase 2 PR). "Losing still teaches" (P4), literally |
| Whichever comes first | discovery, tier floor or death: the first to fire stamps the entry; the others then have nothing to do. A backstop stamp is a real stamp: the entry opens in the Codex and is shown at the next run summary or Ruins visit like any other (§8.6) |
| Pity holds | every gating entry is guaranteed by Iteration *t* at the latest and earlier with every death. Both backstops are branch-blind, so no branch can be walled. The §9.5 model completes the tree in Iteration 5; the backstops make every gated node *available* by Iteration 5, the same point, so pacing holds at the slow end; at the fast end, discovery plus Ember is the limiter, as before |
| On the node | the Lantern Tree shows a gated node's entry as *what you must understand*: the entry title once it is known, a chalk blank before. NARR-001 §8 writes the 27 entries (prose owed) |

The gating map (design §10.2). Entry ids are reconciled with NARR-001 §8's samples (2026-11-18): where a gate named the same subject as an existing sample, it uses the sample's id (`cx_choir_acolyte`, `cx_choir_deacon`, `cx_place_the_drowned_observatory`, `cx_rule_the_glimpse`). Where a discovery source needs a count or a duration, the value is a named SYS-001 row (the four "Gating discovery" rows, PM-approved 2026-11-18 under owner grant).

| Node | Tier | Gating entry | Discovery source | Backstop |
|---|---:|---|---|---|
| WARD-1 Short Rite | 1 | `cx_choir_shrine` | first Shrine destroyed | after run 3 / death |
| MADNESS-2 Look Away | 1 | `cx_rule_gaze` | first time caught in a gaze cone | after run 3 / death |
| MADNESS-3 Tremor Hand | 1 | `cx_rule_frayed` | first time Composure reaches Frayed | after run 3 / death |
| LANTERN-4 Wick Ledger | 1 | `cx_rule_lantern_dark` | first sustained dark flight (Lantern down, no fire) for SYS-001 "Gating discovery: dark flight seconds (LANTERN-4)" | after run 3 / death |
| HULL-8 Long Watch | 2 | `cx_vigil_still_lit` | first death-site Penitent met (§2; CHD-09) | Iteration 2 / death |
| ORDNANCE-5 Pierce | 2 | `cx_choir_acolyte` | a count of Acolytes struck down (a counter, also deterministic): SYS-001 "Gating discovery: Acolytes struck (ORDNANCE-5)" | Iteration 2 / death |
| WARD-6 Silence the Choir | 2 | `cx_choir_matron` | first Matron silenced | Iteration 2 / death |
| MADNESS-5 Clear Eyed | 2 | `cx_rule_unmoored` | first time Unmoored | Iteration 2 / death |
| MADNESS-7 Hollow Ledger | 2 | `cx_rule_bleeding` | first T2 sector entered (deterministic by act) | Iteration 2 / death |
| LANTERN-10 Keel Light | 3 | `cx_place_the_drowned_observatory` | first Drowned Observatory Seam | Iteration 3 / death |
| LANTERN-11 Blackout Dash | 3 | `cx_rule_the_passing` | first W2-11 Distant Passing witnessed (WARP-001, The Passing (CHD-02)) | Iteration 3 / death |
| HULL-9 Anchor Field | 3 | `cx_choir_grave_tide` | survive a Grave Tide | Iteration 3 / death |
| ORDNANCE-9 Charge Capacity II | 3 | `cx_glass_null_iron` | first full magazine held for SYS-001 "Gating discovery: full-magazine hold seconds (ORDNANCE-9)" | Iteration 3 / death |
| ORDNANCE-11 Homing Song | 3 | `cx_choir_listener` | first Listener encounter | Iteration 3 / death |
| WARD-9 Choir's Own Bell | 3 | `cx_place_litany_pew` | find the Litany's lit pew (the Litany's grief story, ZONES-001 §2; CHD-16) | Iteration 3 / death |
| MADNESS-11 Communion | 3 | `cx_choir_procession` | let a Procession pass (ZONES-001, The Procession (CHD-10)) | Iteration 3 / death |
| MADNESS-12 Hollow Chain | 3 | `cx_rule_hollowed` | first time Hollowed | Iteration 3 / death |
| HULL-16 Anchor Overdrive | 4 | `cx_choir_unnumbered` | defeat The Unnumbered | Iteration 4 / death |
| ORDNANCE-13 Nine-Syllable Lance | 4 | `cx_choir_litany_ring` | silence a full Litany Ring | Iteration 4 / death |
| WARD-13 False Lantern | 4 | `cx_choir_deacon` | first Deacon phantom shot through | Iteration 4 / death |
| MADNESS-14 Blessed Fracture | 4 | `cx_rule_inverted` | first T4 sector (deterministic by act) | Iteration 4 / death |
| LANTERN-18 Lamp of the Failed Sky | 5 | `cx_glass_ninth_light` | first ninth-sky close (deterministic by clock) | Iteration 5 / death |
| HULL-18 Hollow Hull | 5 | `cx_rule_hollow_sector` | first sector lost to Hollow | Iteration 5 / death |
| ORDNANCE-17 Null-Iron Hymn | 5 | `cx_chron_unmade_at_t3` | first Waking unmade at T ≥ 3 | Iteration 5 / death |
| WARD-18 Unconsecrated Sky | 5 | `cx_choir_saint` | the Salt Mother's entry (NARR-001 §2.1) | Iteration 5 / death |
| MADNESS-17 Unravel Focus | 5 | `cx_chron_thread_iv` | fourth Thread spun (deterministic by Fragments, §9.4) | Iteration 5 / death |
| MADNESS-18 The Ninth Sky Looks Back | 5 | `cx_rule_the_glimpse` | a count of Glimpses witnessed across the Chronicle (GDD-001, the Waking rebuilt (CHD-06)): SYS-001 "Gating discovery: Glimpses witnessed (MADNESS-18)" | Iteration 5 / death |

Per branch, the gated nodes sit at: LANTERN tiers 1, 3, 3, 5; HULL 2, 3, 4, 5; ORDNANCE 2, 3, 3, 4, 5; WARD 1–5; MADNESS 1, 1, 2, 2, 3, 3, 4, 5, 5. Not every branch has a gated node at every tier: LANTERN has none at tiers 2 and 4, and HULL and ORDNANCE have none at tier 1. So a branch can wait on a gate for a tier step (HULL tier 3, where HULL-10 and HULL-12 both require HULL-9, is the tightest case). That wait was already there under Ink, and the tier floor bounds it at Iteration *t*. The pity rule does not depend on per-tier coverage: it holds through the two branch-blind backstops above, which reach every gating entry whatever branch it sits in.

## 4. Run Sigils — the in-run build layer (120-entry pool)

GDD-001 §6.3 promises "~120 pool entries". Here they are. A Run Sigil is stamped onto the Vigil for the rest of the run and **shows up on the sprite** in one of the four module slots (ART-002 §6). A Sigil you cannot see on the ship is a Sigil that does not ship.

### 4.1 Selection rules

| Rule | Value |
|---|---|
| Choices | **3 per run**, after Seams 1–3 (SYS-001 §7.2 `Run-Sigil picks`). Seam 4 offers a **rare Run Sigil** instead (§5, the former Relic slot 3), and Seam 5 is the Waking, which offers neither. This row used to say "one after each of Seams 1–4", which disagreed with the SYS row above it: SYS-001 wins, and the fourth boundary belongs to the rare boundary offer rather than being a choice that does not exist |
| Rare boundary offers | **3 per run**, at Seams 2, 3 (the gate) and 4 — where the Relic slots were (CHD-14; PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3). They draw only from the 18 rare Sigils of §5 (the former Relics), follow §5.2's boundary rules, and are separate from the three card picks above |
| Slots | 4. The choice is always 1-of-3; a fourth option appears only when the entity is offering a **Cursed** Sigil, drawn in a visibly different frame |
| Reroll | bought in-run with Ember, priced by choice number: SYS-001 §7.7 `Run Sigil reroll` row (moved there 2026-11-19, Q-T149; GDD-001 §7.3) |
| No duplicates | anything you already hold is removed from later pools |
| Rarity | card pool: Common 60 · Uncommon 40 · Rare 16 · **Cursed 4** = 120. Plus the **18 rare boundary Sigils** of §5 (the former Relics), offered only at the Seam 2/3/4 boundaries and never in the card fan: 138 Run Sigils in all |
| Cursed | offered only at Warp ≥ 3 or Entropy ≥ 5, or forced at Seam 1 on a **cursed seed** (GDD-001 §6.3). The price is printed on the card in one line. We never hide what a Cursed Sigil costs |
| Stacking | never stacks with itself. Two Sigils touching the same SYS-001 row compose additively and are linted against the ceiling (§4.3) |
| Death | all Sigils are lost. There is no "keep one" rule outside SIG-H-12 |

### 4.2 The pool

Effects cite a SYS-001 row instead of restating a base value. **Tell / catch** is what the player sees — and for Uncommon and above, what they pay. **RB** marks Sigils that bend a rule rather than move a number; the count is 36 of 120, matching the ~30% share GDD-001 §7.3 asks for.

#### LANTERN family (20) — light, sight, mining, mobility

| ID | Sigil | Rarity | Effect | Tell / catch | RB |
|---|---|---|---|---|---|
| SIG-L-01 | Emberlight | Common | Light radius +15% (SYS-001 §1.2) | The pool reaches one more corridor | |
| SIG-L-02 | Wick Trimmer | Common | Lit mining speed +10% (SYS-001 §1.2) | Faces shatter in fewer shots | |
| SIG-L-03 | Dark Habit | Common | Dark mining penalty −10 points (SYS-001 §1.2) | You mine in the black at near-full speed | |
| SIG-L-04 | Chalk Line | Common | Your route is drawn on the Ledger Compass for the run (SYS-001 §6) | The map fills in behind you | |
| SIG-L-05 | Steady Hand | Common | The lance converges on one geode face after 1.5 s of continuous fire (SYS-001 §1.3) | The shots stop spraying | |
| SIG-L-06 | Second Wick | Common | Lantern relight time −50% (SYS-001 §1.2) | Up and down, up and down, no pause | |
| SIG-L-07 | Oil Purse | Common | Shard magnet +20 px (SYS-001 §1.4 ceiling applies) | Shards leave the floor early | |
| SIG-L-08 | Ember Trail | Common | Surgelight leaves an ember line that Grubs refuse to cross for 2 s | A scar of light behind you | |
| SIG-L-09 | Watchful | Common | At run start, the compass marks every geode face in the Seam for 10 s | The map shows its ore once | |
| SIG-L-10 | Lampblack | Common | Shroud contact costs no Composure (SYS-001 §1.5) | You wade through grey veils unbothered | |
| SIG-L-11 | Deep Dark | Uncommon | Dark light radius +40%, and dark mining carries no penalty for this run | You can see the room you are hiding in | ✔ |
| SIG-L-12 | Ghost Lantern | Uncommon | Your light pool sits 60 px *behind* the hull | Choir aim lands where you were | ✔ |
| SIG-L-13 | Cold Coil | Uncommon | Surgelight cooldown −25%; it costs 1 Composure at any Warp (SYS-001 §1.1, §1.5) | You blink twice, then it hurts | ✔ |
| SIG-L-14 | Tallow Eater | Uncommon | Over-fire scatters shards in a tighter radius (SYS-001 §1.3) | The confetti comes home to you | |
| SIG-L-15 | Snuffer | Uncommon | Lantern-down makes Grubs lose you after 1.5 s (SYS-001 §3.1) | They turn and drift off | |
| SIG-L-16 | Cold Watch | Uncommon | In the dark, processions read as sound-rings instead of dots | The compass gains ribs of sound | |
| SIG-L-17 | Nine Wicks | Rare | Light +25% and lit mining +20%; **Shrines inside your light convert 40% faster** (SYS-001 §6) | The same flame that feeds you feeds them | ✔ |
| SIG-L-18 | Black Mirror | Rare | Lighting up blinds Choir units that have just detected you, once per 12 s | A negative flash, then dark | ✔ |
| SIG-L-19 | Miner's Psalm | Rare | Mining a face sounds one chant note: +1 shard per face, and Grubs converge | Ore for company | ✔ |
| SIG-L-20 | Ashlight | Cursed | Light radius tracks Composure: +40% at 10, −40% at 3 (SYS-001 §1.5) | The lamp dims as you come apart | ✔ |

#### HULL family (20) — survivability, mass, the one-hit question

| ID | Sigil | Rarity | Effect | Tell / catch | RB |
|---|---|---|---|---|---|
| SIG-H-01 | Trim Bow | Common | Acceleration +10% (SYS-001 §1.1) | The skiff answers sooner | |
| SIG-H-02 | Ballast | Common | Brake distance −15% (SYS-001 §1.1) | You stop inside a corridor | |
| SIG-H-03 | Light Frame | Common | Player hitbox radius −2 px (SYS-001 §9) | You slide through gaps | |
| SIG-H-04 | Drift Seat | Common | Reversal time −0.04 s (SYS-001 §1.1) | The stern kicks out | |
| SIG-H-05 | Slow Teeth | Common | Top speed −10%, snap-turn +30% (SYS-001 §1.1) | Slower, and far more precise | |
| SIG-H-06 | Lampbrace | Common | Surgelight costs no Composure below Warp 2 (SYS-001 §1.5) | Blinking stops hurting | |
| SIG-H-07 | Shroud Cutter | Common | Your lance clears Shroud 40% faster (SYS-001 §9) | Grey veils tear like wet paper | |
| SIG-H-08 | Quiet Keel | Common | You make no noise for 1 s after a Surgelight (SYS-001 §3) | The Listener turns away | |
| SIG-H-09 | Anchor Plate | Common | Immune to Grub latch pull for 0.4 s after throwing a Charge (SYS-001 §3) | The latch slides off | |
| SIG-H-10 | Chalked Ribs | Common | The first Shroud pass per Seam costs nothing | Chalk dust on the hull | |
| SIG-H-11 | Tin Saint | Uncommon | Grubs will not latch while you are within 200 px of a lit geode | They circle the light and wait | |
| SIG-H-12 | Second Seal | Uncommon | **On death, keep one Sigil into the next run** | The stamp survives the Ruins | ✔ |
| SIG-H-13 | Weighted Hull | Uncommon | Your collisions push Grubs aside; the extra mass costs 8% top speed | You plough a furrow through a procession | ✔ |
| SIG-H-14 | Ghostwake | Uncommon | On death, your last 10 s of movement replay as a decoy before the respawn | It dies in your place, once | ✔ |
| SIG-H-15 | Lampstand | Uncommon | You may not Surgelight all run; you take one extra hit | The hull is heavier without the flash | ✔ |
| SIG-H-16 | Shoulder of Glass | Uncommon | A missed Charge becomes a 1-hit shield at the impact point, 3 s | The glass stands where it fell | ✔ |
| SIG-H-17 | Ballast Choir | Uncommon | Three Grubs follow you as a shield — and they eat your shards | Your own escort is your thief | ✔ |
| SIG-H-18 | Counterweight | Rare | Hitting a geode above 240 px/s shatters it for its shards (SYS-001 §1.3) | Mining becomes a collision | ✔ |
| SIG-H-19 | Vigil's Wake | Rare | After any hit you take, Choir units cannot detect you for 2 s | You vanish in the moment of your worst luck | ✔ |
| SIG-H-20 | Hollow Coat | Cursed | At Composure ≤ 3 Grubs cannot detect you at all — and you cannot restore Composure above 3 for the run | You are safe because you are already gone | ✔ |

#### ORDNANCE family (20) — the lance and the Charge

| ID | Sigil | Rarity | Effect | Tell / catch | RB |
|---|---|---|---|---|---|
| SIG-O-01 | Quick Hands | Common | Lance rate +10% (SYS-001 §1.3 ceiling applies) | The spark line thickens | |
| SIG-O-02 | Long Barrel | Common | Lance projectile speed +20% ✱ | The shot arrives before you have aimed | |
| SIG-O-03 | Split Flint | Common | Lance pierces one extra geode face (SYS-001 §1.3 pierce ceiling) | One shot opens two faces | |
| SIG-O-04 | Calm Fire | Common | Over-fire threshold +2 shots (SYS-001 §1.3) | Panic fire stays controlled | |
| SIG-O-05 | Wide Spark | Common | Long-range spread −20% | You can shoot down a corridor | |
| SIG-O-06 | Glass Cutter | Common | Mining a face you have lit is 15% faster (SYS-001 §1.2) | The lit side splinters clean | |
| SIG-O-07 | Deep Pockets | Common | Charge magazine +1 (SYS-001 §1.4 cap applies) | Another lamp on the belt | |
| SIG-O-08 | Hard Toss | Common | Charge launch speed +20% | The glass leaves fast and flat | |
| SIG-O-09 | Slow Fuse | Common | A Charge detonates 0.3 s later after impact | You can bait an interception | |
| SIG-O-10 | Stone Hook | Common | Magnet +25 px (SYS-001 §1.4, 96 px base) | The ore leans toward you | |
| SIG-O-11 | Chalk Shot | Uncommon | Lance shots mark the surface they hit in chalk for 6 s | You can read where your shots went | |
| SIG-O-12 | Chained Song | Uncommon | Charges curve harder (SYS-001 §1.4 turn authority +0.4 s) and are audible to the Choir | The hymn follows your glass | ✔ |
| SIG-O-13 | Salt Shot | Uncommon | Lance shots deal one extra hit to any unit carrying shards (SYS-001 §3) | The thief smokes when shot | |
| SIG-O-14 | Iron Taste | Uncommon | A Charge intercepted mid-flight drops 3 shards you can reclaim | Losing a Charge is a mining method | ✔ |
| SIG-O-15 | Twin Flint | Uncommon | Charges fire in pairs; magazine cap −2 | Two blooms, fewer lamps | ✔ |
| SIG-O-16 | Salvo | Uncommon | The 5th Charge thrown in a Seam detonates every Charge still in flight | One throw ends the volley | ✔ |
| SIG-O-17 | Glass Eater | Rare | A Charge may consume shards within 60 px to count as 2 Unravel hits, once per run | You feed the glass to break the god | ✔ |
| SIG-O-18 | Shatterbound | Rare | Over-fired shards ricochet once off geode faces | The ore takes corners | ✔ |
| SIG-O-19 | Ninth Bell | Rare | A Charge may hang un-detonated until the entity completes its next segment, then it lands two hits | You aim at the thing's *future* | ✔ |
| SIG-O-20 | Ninepenny Gun | Cursed | The lance cannot damage Choir units at all: all harm to them comes from Charges and Ward, and you start each Seam with +2 Charges | **You are a miner who only throws glass** | ✔ |

#### WARD family (20) — answering the Choir without killing it

| ID | Sigil | Rarity | Effect | Tell / catch | RB |
|---|---|---|---|---|---|
| SIG-W-01 | Wider Ring | Common | Ward Pulse radius +20% | The bell ring takes in a doorway | |
| SIG-W-02 | Faster Bell | Common | Ward cooldown −20% | You can answer twice in a phase | |
| SIG-W-03 | Penitent's Distance | Common | A Penitent in the sector will not raise its censer within 200 px of you unless you fire first (SYS-001 §3 `The Penitent`, §1.3) | The robed figure lowers its censer and walks a wider circle around your lamp | |
| SIG-W-04 | Quiet Ward | Common | Ward Pulse does not attract a Grave-Tide Deceiver | The bait ignores you | |
| SIG-W-05 | Candle Circle | Common | Ward leaves a lit circle for 4 s; light rules apply inside it | The floor holds the light | |
| SIG-W-06 | Shrine Lens | Common | The compass marks Shrines and their corruption step (SYS-001 §6) | The map gains black nails | |
| SIG-W-07 | Deacon's Bane | Common | Ward strips a Deacon of Lies illusion on contact (SYS-001 §3) | The false thing comes apart | |
| SIG-W-08 | Tithe | Common | Purging a Shrine node pays +3 Ember (SYS-001 §6) | The purge pays | |
| SIG-W-09 | Ash Ward | Common | Ward Pulse deals one hit to Acolytes (SYS-001 §3) | The veiled ones flinch | |
| SIG-W-10 | Deacon's Ear | Common | Ward interrupts a Listener's charge (SYS-001 §3, 2.5 s wind-up) | The big head snaps back | |
| SIG-W-11 | Toll | Uncommon | Each Ward you cast lowers local sector corruption by 0.5 (SYS-001 §6) | The bruise shrinks | ✔ |
| SIG-W-12 | Silence | Uncommon | Ward mutes a chant for 3 s; nearby Choir loses coordination (SYS-001 §3.1) | The units stop moving together | ✔ |
| SIG-W-13 | Glass Veil | Uncommon | You are unseen for 1.5 s after your Ward breaks | You leave the ring invisible | ✔ |
| SIG-W-14 | Grave Gate | Uncommon | Warding a Sepulchre segment slides it 60 px, once per Seam | The segment craws | ✔ |
| SIG-W-15 | Bell Rope | Uncommon | Ward radius scales +10% per Composure point above 5 | The ring is wide when you are steady | |
| SIG-W-16 | Censer | Uncommon | Ward leaves a cloud Grubs will not cross for 8 s | The procession parts | ✔ |
| SIG-W-17 | Unnumbered Ward | Rare | Ward reveals a Rite boss's true shape for 10 s (SYS-001 §5.1) | The room stops pretending | ✔ |
| SIG-W-18 | Ninth Name | Rare | Warding a converted Shrine *restores* it instead of destroying it: no Ember, +2 Composure | You undo instead of break | ✔ |
| SIG-W-19 | Held Bell | Rare | Ward may be held for 2 s at double radius; releasing early refunds nothing | The bell bends before it rings | ✔ |
| SIG-W-20 | Heresy | Cursed | Ward stops protecting you entirely; each cast banks Ember immediately, up to a per-run cap (SYS-001 §7.1; the per-cast Ember and the cap are value owed — CHD-15 replaced "+1 Ink, to 10 per run") | **You trade the bell for the book** | ✔ |

#### MADNESS family (20) — paying in Composure

| ID | Sigil | Rarity | Effect | Tell / catch | RB |
|---|---|---|---|---|---|
| SIG-M-01 | Steady Gaze | Common | Warp Composure drain −15% (SYS-001 §1.5) | The wick burns slower | |
| SIG-M-02 | Borrowed Calm | Common | At Composure ≤ 3, lance damage +25% (SYS-001 §1.5) | The shots bite when you are bad at this | |
| SIG-M-03 | Chalk Saint | Common | At Warp ≥ 2, warped geometry and phantom units show a bone outline first (SYS-001 §4) | The room sketches itself before it lies | |
| SIG-M-04 | Nightglass Mind | Common | This run's summary stamps every queued entry, ignoring the §8.6 per-summary cap. (**Adopted** 2026-11-18, cosmic horror design call within CHD-15, flagged in the Phase 2 PR; it replaces "+50% Ink from reading", which CHD-15 left without a target) | The pages come out darker | |
| SIG-M-05 | Small Kindnesses | Common | Killing a Grub carrying shards restores 1 Composure, once per Seam (SYS-001 §1.5) | Something in you settles | |
| SIG-M-06 | Salt in the Teeth | Common | Chant Composure cost halved (SYS-001 §1.5) | The hymn slides off you | |
| SIG-M-07 | Second Thought | Common | Sigil rerolls cost −50% (SYS-001 §7.3) | The chalk desk is cheaper | |
| SIG-M-08 | Fracture Diet | Common | While Frayed, mining speed +15% (SYS-001 §1.5 band) | You work better unhinged | |
| SIG-M-09 | Small Mercies | Common | The first Warp Tier rise in a run costs no Composure | One free fall | |
| SIG-M-10 | Ninth Whisper | Common | The entity tells you one true thing per Seam (AUDIO-001 §4) | You hear it coming | |
| SIG-M-11 | Clear Eyed | Common | Your Composure bands sit one band gentler than the numbers say (SYS-001 §1.5) | You read worse than you are, on purpose | ✔ |
| SIG-M-12 | Blessed Hairline | Uncommon | +15% damage per Warp Tier you are under (GDD-001 §7.2) | Your shots bend with the room | ✔ |
| SIG-M-13 | Communion Hint | Uncommon | You hear the next Unravel thread snap before it does (SYS-001 §2) | You count down in your teeth | ✔ |
| SIG-M-14 | Unmaking Appetite | Uncommon | You may eat a shard to regain 1 Composure, three times per run | Glass for calm | ✔ |
| SIG-M-15 | Hollow Tithe | Uncommon | While Hollowed, Grubs cannot kill you — and Warp Tier is +1 while it lasts (SYS-001 §1.5) | Safety bought with more warp | ✔ |
| SIG-M-16 | Glass Eye | Uncommon | The compass renders geode faces through geometry within 200 px | The rock goes translucent near you | ✔ |
| SIG-M-17 | Penitent's Debt | Uncommon | Shooting a Penitent costs no Composure, but one must be shot per run or you lose 2 (SYS-001 §3) | You made a habit of it | ✔ |
| SIG-M-18 | The Long Blink | Rare | Composure cannot fall below 1 for the run, and the first Hard Unmaking in the run is cancelled | You should have died | ✔ |
| SIG-M-19 | Ninth Circle | Rare | At Warp ≥ 4 the Choir treats you as Choir: no unit fires first — and the Ledger Compass lies 100% of the time | They let you walk, and they never let you see | ✔ |
| SIG-M-20 | Communion Debt | Cursed | Every ability costs 1 Composure; each point spent grants +5% damage for the run, cap +50% (SYS-001 §1.5) | Each miracle is a piece of you | ✔ |

#### SEAM family (20) — economy, clock, compass

| ID | Sigil | Rarity | Effect | Tell / catch | RB |
|---|---|---|---|---|---|
| SIG-S-01 | Ledger Mark | Common | Banked Ember +10% at Seam end (SYS-001 §7.2) | The tally is longer | |
| SIG-S-02 | Small Change | Common | Score chain window +1 s (SYS-001 §7.1) | The chain holds through a bad corner | |
| SIG-S-03 | Cartographer | Common | The compass marks the exit vectors at Seam start (SYS-001 §4 lint) | You always have a way out | |
| SIG-S-04 | Salver | Common | The first kill of each Choir variant also banks Ember (SYS-001 §7.1; amount value owed — CHD-15 replaced "+1 first-kill Ink") | The book thickens as you learn | |
| SIG-S-05 | Chalk Ledger | Common | One free respec at the Desk this run (SYS-001 §7.3) | The desk has your name on it | |
| SIG-S-06 | Miner's Tithe | Common | A geode face already cracked scores +50% (SYS-001 §7.1) | Finishing pays better than starting | |
| SIG-S-07 | Quiet Victory | Common | Clearing a Seam without killing a Choir unit grants +1 Composure (SYS-001 §1.5) | Nothing followed you out | |
| SIG-S-08 | Nine Coins | Common | Charges left in the magazine at run's end convert to Ember (rate per Charge value owed — CHD-15 replaced "to Ink, 1 each") | The lamps you did not throw become pages | |
| SIG-S-09 | Threnody | Common | The Vigil Index is shown, and grants +5% score per 1000 Index (SYS-001 §7.1) | The Choir reads your numbers aloud | |
| SIG-S-10 | Small Hours | Common | Death spends 10% less clock time (GDD-001 §6.2) | The sand forgives a little | |
| SIG-S-11 | Hourglass Mercy | Uncommon | The Hourglass Clock pauses for 60 s once per run | The sand stops for a breath | ✔ |
| SIG-S-12 | Seed Whisperer | Uncommon | Re-key one kit in the run to its Warp-3 version (ZONES-001 §3) | You ask the map for worse, and mean it | ✔ |
| SIG-S-13 | Ledger Thief | Uncommon | The compass shows the entity at all times; the score readout is corrupted (SYS-001 §6) | You know where it is, and not what you are worth | ✔ |
| SIG-S-14 | Ink Eater | Uncommon | Your Sigil rerolls this run (§4.1) may be paid from **banked** Ember as well as the run's own — the one in-run purchase the §9.1 law allows, reaching outside the loop to pay for it. (**Adopted** 2026-11-18, cosmic horror design call within CHD-15, flagged in the Phase 2 PR; it replaces the old effect, which spent banked Ink.) The name "Ink Eater" stays for now, keeping "Ink" as a plain word; NARR-001 may rename it later | **You are reaching outside the loop for power** | ✔ |
| SIG-S-15 | Hollow Broker | Uncommon | One Hollow sector in this run escorts you instead of hunting you; its geodes yield +30% (SYS-001 §6) | You made a deal with a dead sky | ✔ |
| SIG-S-16 | Chained Run | Uncommon | The run is 6 Seams at +1 Entropy and pays the higher table (SYS-001 §4, §6) | One more room, one worse world | ✔ |
| SIG-S-17 | Long Vigil | Rare | The run's final Seam is the same kit every run, and grants +1 Sigil choice there | You learn one room perfectly | ✔ |
| SIG-S-18 | Archive Seal | Rare | The Codex records every rule eaten this iteration, and reading one banks Ember (SYS-001 §7.2; amount value owed — CHD-15 replaced "3 Ink") | Grief with a footnote | ✔ |
| SIG-S-19 | Threnody Lost | Cursed | No Ledger Compass all run; everything banked is ×1.5 (SYS-001 §7.2) | You navigate by the chant | ✔ |
| SIG-S-20 | Unwritten | Cursed | You do not choose Sigils: the game picks four, each one rarity higher | It is building something out of your run | ✔ |

### 4.3 Ceiling lint (a build gate, not a wish)

Sigils compose additively and can silently break the game. TECH-001 §6 ships a **stack lint**: a unit test that builds the 20 worst-case Sigil combinations against the Lantern Tree's capstone loadout and fails the build if any combination crosses a SYS-001 §1 ceiling — speed, fire rate, pierce, magnet, magazine cap, light radius. The ceilings exist so the run's power curve stays inside the playtest envelope (SYS-001 §10 tunables register). A Sigil that would break a ceiling is authored *with* its own ceiling clause instead of being vetoed late, which is why rows such as SIG-O-01, SIG-O-07 and SIG-O-10 name the SYS-001 row inside the effect line.

**Sigil rollup.** Card pool: Common 60, Uncommon 40, Rare 16, Cursed 4 = **120**, plus the 18 rare boundary Sigils of §5 (all rules-bending; rolled up in §5.5). Card-pool rules-bending **36** (30%). Family totals: LANTERN 20 (10 Common / 6 Uncommon / 3 Rare / 1 Cursed), HULL 20 (10/6/3/1), ORDNANCE 20 (10/6/3/1), WARD 20 (10/6/3/1), MADNESS 20 (11/6/2/1), SEAM 20 (10/6/2/2).

## 5. Rare boundary Sigils — the former Relics, what the run *is* (18-entry pool)

**Relics fold into Run Sigils** (CHD-14; PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, design §3.3). The 18 Relic designs survive as content and become **rare Run Sigils offered at Seams 2, 3 and 4**, where the Relic slots were. The noun "Relic" retires from player use: on screen they are Run Sigils, with the Rare frame. In this doc, "rare boundary Sigil" is a doc term for them (not a new noun on screen), and their ids stay `REL-01`…`REL-18` as invariant content ids, as do the `TEST-REL-` tests in §5.4. Everything else in this section is unchanged: the designs, their prices and the boundary rules below.

A card Sigil is what your Vigil does. A rare boundary Sigil is what the run is. The distinction is why both exist: card Sigils are chosen cards that move numbers and small rules (§4); boundary Sigils are *objects the world hands you* at fixed boundaries, each one a verb you did not have, each one with a price printed on it. GDD-001 §7 promises **18 Relics**; all eighteen are below, with their prices. None is a percentage. If a candidate only moves a number, it is a card Sigil that was written in the wrong file.

### 5.1 The three choice-layers, side by side

| | **Run Sigil, card pick** (§4) | **Run Sigil, rare boundary offer** (§5, former Relic) | **Pact** (§7) |
|---|---|---|---|
| Where it comes from | the Chalk Desk's card fan at a Seam boundary | the world: a kit's authored reward, or a gate boss | you, once per run, at the Chalk Desk in the Ruins — before the run starts |
| When | after Seams 1–3 | after Seam 2, at the Seam-3 gate, after Seam 4 | chosen once, at the start |
| Chosen or given | chosen 1-of-3, rerollable for Ember | **given**, 1-of-2, never rerolled | chosen outright, one from 24 |
| Bends | numbers mostly (84 of 120 are numeric) | rules only (18 of 18) | the run's win condition and its shape |
| Lost on death | yes | yes | the Pact is re-chosen next run; its *cost* is remembered by the entity |
| Eaten by the warp | **H14 takes one** (WARP-001 §3.2) | **never** — see §5.2 | never mid-run; a Pact's *restore* is what the warp answers to (WARP-001 §3.3) |

### 5.2 Boundary rules for the rare Sigils

| Rule | Value |
|---|---|
| Slots | **3**, one per boundary, separate from the card picks of §4.1. A slot is never empty at the moment its boundary is passed: you always take one of the two. How the three show on the Vigil next to ART-002 §6's four module slots is owed to ART-002 |
| Boundaries | Slot 1 after Seam 2 · Slot 2 on clearing the Seam-3 gate (SYS-001 §5.1, GDD-001 §6.3) · Slot 3 after Seam 4, immediately before the Waking |
| Presentation | 1-of-2, shown as two physical objects on the ground where the kill happened, in the Rare Sigil frame. No chest, no glow, no loot pop — the Choir's leftovers are the loot box |
| No reroll | a boundary Sigil is not bought and not re-rolled. There is no Ember price for a second look: the offer is what the world chose, which is the whole point of the layer |
| Rarity | all 18 are **Rare**. Their slot groups keep their doc names — **Found** (8, slot 1) · **Consecrated** (6, slot 2) · **Struck** (4, slot 3) — as internal tiers: heavier objects arrive later, and the Struck four are the ones that shape the boss fight |
| Pool hygiene | a seed cannot offer the same one twice in one run, and one offered in slot 1 is removed from slot 2's pair. They never appear in the §4 card fan, and card Sigils never appear at a boundary offer |
| Death | all three are lost with the run (SYS-001 §2 class: run state). The Codex records every one you held, so the knowledge is anchored (§8) |
| The warp never eats one | 🔒 a boundary Sigil is a thing the world already gave you; the warp takes *choices* and *rules*, not gifts. **H14 takes a card-picked Run Sigil and nothing else** (WARP-001 §3.2, §3.4; §7.4 here lists the exclusion). REL-18 pays you when the warp takes a Sigil, and it is explicitly **not** a restore — H14 stays `no_restore = true` and lint L-06 is unaffected. WARP-001 §3.2's H14 row carries the same exclusion ("never a rare boundary Sigil", 2026-11-18) |
| Ceilings | boundary Sigils enter §4.3's stack lint alongside card Sigils: the 20 worst-case combinations are built against the capstone loadout, and any that could push a SYS-001 §1 ceiling is authored *with* its own ceiling clause |
| Rules-bending share | 18 of 18. The 30% discipline in GDD-001 §7.3 governs nodes and card Sigils; this layer was always a rules budget, and a boundary Sigil that is only a number has failed its own layer |

### 5.3 The pool

Column three states what the run now *does*, column four is the price, printed on the object's one-line description in the UI. Every row names the SYS-001 row or cross-doc clause it leans on. `✱` marks a number this doc is proposing for SYS-001 to own; those are gathered as requests in §5.5.

#### Found (8) — slot 1, after Seam 2

| ID | Rare Sigil | What the run now does | The price | Anchor |
|---|---|---|---|---|
| REL-01 | Wick Left Burning | your light pool keeps 60% of its radius for 3 s after you stop mining ✱ | the lit ground keeps advertising where you have been; the procession route you just walked is legible to a Deacon | SYS-001 §1.2 |
| REL-02 | Chalked Threshold | every boundary you have crossed stays drawn on the Ledger Compass, and the compass **cannot lie about that line** | the drawn line is also the map the Choir reads; it shortens the distance a hunt has to learn | SYS-001 §6; WARP-001 §4.7 never-lies channels |
| REL-03 | Grub Bell | a Grub that dies inside your light dies silently, and its panic does not spread | you lose the keening that warned you a deposit had died — silence is now also blind | SYS-001 §3, §3.1 (Grub panic) |
| REL-04 | Borrowed Pew | the 120 px hold-fire ring reads as 90 px around *you*, so Choir fire resumes closer | purging a Shrine pays +1 Composure every time, not only the first purge of a biome | SYS-001 §3.1, §6 (Shrine purge) |
| REL-05 | Tallow Hand | a Charge that strikes a geode face splits the face into two smaller faces carrying the same total shards | both faces must be finished, and the Choir mines while you do; more faces means more corruption clocks | SYS-001 §1.3, §6 (geode → Shrine, 90 s) |
| REL-06 | Name Written Small | the entity cannot turn your most-used tool against you for one Seam | at that Seam's end the counter arrives **doubled**, and the run's Herald comes one Seam early | SYS-001 §2.2 counter table, §4 (Herald at Seam 4) |
| REL-07 | Lantern of Other Days | when your lantern goes out, the dark reads as a Choir unit to one Listener for 4 s ✱ | it reads as a Choir unit to the Deacon's mimic as well — the same lie, two audiences | SYS-001 §3 (Listener), §3 (Deacon Phantom) |
| REL-08 | Two Minutes of Bells | a Ward Pulse that interrupts a chant pays +0.2 Composure, capped at +1.0 per sector ✱ | the Composure is bought with silence the Choir notices: a Herald of the Quiet Pew hunts you while that Composure stands | SYS-001 §1.5, §5.2 |

#### Consecrated (6) — slot 2, on clearing the Seam-3 gate

| ID | Rare Sigil | What the run now does | The price | Anchor |
|---|---|---|---|---|
| REL-09 | The Unnumbered Bell | one Choir unit per sector stops rejoining its procession for the rest of the run | a thinner procession is a *faster* deposit tell: 6 frames shorter on the Sepulchre's cycle | SYS-001 §2, §3 (tell frames) |
| REL-10 | Censer of the Long Fast | an Acolyte mining a face gives that face up the moment you take it | taking a face from an Acolyte counts as Choir activity: the sector's corruption clock runs 25% faster ✱ | SYS-001 §3, §6 |
| REL-11 | Glass Tithe | at each Seam's end, 1 Charge becomes 1 Shard | the Tithe also takes the last Charge before the Waking: the boss begins with one fewer than your magazine says | SYS-001 §1.4 |
| REL-12 | The Vigil's Own Chalk | you may draw a ward on a seam boundary; it fires once when a Choir unit crosses it | drawing costs 1 Composure and 2 s of standing still | SYS-001 §1.5, §2 phase 0 (salt), §1.1 (brake) |
| REL-13 | Second Name | the first death you would take is survived at 1 hull, once per run | the entity learns your name: it swaps one counter-behaviour for this run, and the swap is shown to you before it acts | SYS-001 §2.2, §7.4 (the price is knowledge, never currency) |
| REL-14 | Hourglass in the Pocket | the Hourglass Clock stops while you stand inside your own Ward radius, **60 s per run** ✱ | the Ward is doing nothing else while it holds time, and the paused seconds do not raise Hunger — you are buying room inside the sky that is already going dark | GDD-001 §6.2; SYS-001 §10 clock lock (see request **LR-01**) |

#### Struck (4) — slot 3, after Seam 4, before the Waking

| ID | Rare Sigil | What the run now does | The price | Anchor |
|---|---|---|---|---|
| REL-15 | The Unmake-Load | you may carry 2 extra Charges into Seam 5 only | the Waking spends its remaining processions on interceptors and opens with +2 units: everything you carry is announced | SYS-001 §1.4 (and the §4.3 ceiling lint), §2 phases |
| REL-16 | Wound That Remembers | the Waking opens carrying the segment damage you dealt it in your **previous run's** Waking, for the first 20 s ✱ | it also opens carrying your previous run's most-used tool as its counter: the mirror improves for both of you | SYS-001 §2.1, §2.2 |
| REL-17 | Choir Broken Open | Unravel Focus is live in this run without MADNESS-17 | every latch costs 1 Composure and 40 Ember, and the Act 3 gate in GDD-001 §7.2 still holds — this Sigil buys the node's mechanic, never the campaign's permission | SYS-001 §1.5, §7.2 |
| REL-18 | Mourning Ledger | when the warp takes a Run Sigil, this pays 1 Composure and 60 Ember at the run's end, and the Codex records the Sigil's name | it does not give the Sigil back. Grief is monetised once per iteration, and the slot stays empty until the next Seam's card | WARP-001 §3.2 H14, §3.4 (the ruling that there is no restore), lint L-06 |

### 5.4 Four loadouts the build matrix must clear

These are not recommendations, they are the QA matrix: four sets of three rare boundary Sigils at named Entropy levels, each one a build the game must be able to finish and be able to beat. They run in the same test pass as §4.3's stack lint and are named in GDD-001 §8.7.

| Loadout | E | Rare boundary Sigils (slots 1/2/3) | What it must prove | Test |
|---|---:|---|---|---|
| **Salt Procession** | 6 | REL-04 / REL-09 / REL-15 | the Ward path is a real boss answer: hold-fire cover, thinned processions, and a full unmake-load land the Waking inside 90 s at E6 payouts | `TEST-REL-01` |
| **Tithe and Bell** | 8 | REL-08 / REL-11 / REL-17 | a Composure economy survives a T3 run while paying Charges away: the player stays in the Clear band through a ×1.2 warp score multiplier (SYS-001 §7.1) | `TEST-REL-02` |
| **Glass Name** | 8 | REL-14 / REL-13 / REL-16 | time and death are spendable and *bounded*: the 60 s clock cap cannot be looped, and a survived death hands the entity a visible counter the player can read back | `TEST-REL-03` |
| **Ledger Nine** | 10 | REL-02 / REL-18 / REL-15 | a lie-proof channel exists at E10, where the warp lies every sector (WARP-001 §4.2) and H14 is live: the run still finishes, and this is the clip build for the flex run | `TEST-REL-04` |

### 5.5 Rollup and requests

**Rare boundary Sigil rollup** (the former Relics). 18 total = Found 8 + Consecrated 6 + Struck 4, all Rare. Rules-bending 18 (100%). Slots 3 per run, boundaries Seams 2–4. `✱` numbers proposed for SYS-001: REL-01 (3 s at 60%), REL-07 (4 s), REL-08 (+0.2/+1.0 caps), REL-10 (+25%), REL-14 (60 s), REL-15 (2 Charges, Seam 5 only), REL-16 (20 s), REL-18 (1 Composure / 60 Ember, once per iteration).

| Request | Ask | Why it needs a SYS row, not a LOOP line |
|---|---|---|
| **LR-01** | Does anything other than the warp get to touch the Hourglass Clock rate? REL-14 asks for a pause permission with a 60 s per-run cap | SYS-001 §10 locks the clock rate as *not warp-writable* and names `clock_runs_during_exploration` as an A/B flag. A Sigil is not the warp, so the lock does not decide this. Left unruled, REL-14 ships by default, and a clock-affecting item is exactly the kind of number that must be in the bible with a trigger attached |
| **LR-02** | A per-run shard-yield ceiling that includes REL-05's face-splitting | §3.3's footnote already asks SYS-001 for a shard-yield ceiling because three nodes raise yield; REL-05 is a fourth input to the same row, so the ceiling should be written once, not per item |
| **LR-03** | Confirm that a rare boundary Sigil (former Relic) may never be counted as "player currency" for the purposes of SYS-001 §7.4 | REL-13 and REL-18 both pay in Composure and Ember. §7.4 protects currency from Hunger; it should say out loud that such a Sigil's payout is not a Hunger credit and not a Hunger debt, so the two systems cannot argue in code |

## 6. The shape of a run, and the two escalators

SYS-001 owns every number in this section's tables. What this section owns is the *shape*: what a run is made of, what a seed fixes, which escalators the player can pull and which pull themselves.

### 6.1 Run anatomy

Five Seams, two gates, three cards, three rare boundary Sigils, one clock (SYS-001 §6 `Seams per run` 5 🔒, GDD-001 §6.3). The rare boundary Sigils are the former Relics (CHD-14, §5).

| Boundary | Threat budget (SYS-001 §4) | What you are given | What the player should feel |
|---|---|---|---|
| Seam 1 | 8–12 / 14–18 / 18–24 by Warp Tier | Run Sigil 1-of-3 | *I know this ship.* Act 0's vocabulary still works |
| Seam 2 | 12–18 / 20–26 / 26–32 | Run Sigil **and** a rare Run Sigil, slot 1 (Found) | *the world started handing me things* |
| Seam 3 — gate | Sepulchre active, Litany Ring; Rite boss from SYS-001 §5.1 | Run Sigil **and** a rare Run Sigil, slot 2 (Consecrated) | *this run has a shape now, and I chose it on purpose* |
| Seam 4 | 20–28 / 28–36 / 36–44, Herald at E ≥ 4 | a rare Run Sigil, slot 3 (Struck) — the boss-shaping slot | *the last thing I chose is the answer I am carrying into the Waking* |
| Seam 5 — the Waking | budget is the boss | nothing; the run ends and banks | *what I built is what I get to find out about* |

- A run is 25–35 min 🔒 and a Seam is 4–6 min ✱ (SYS-001 §6). SIG-S-16 *Chained Run* is the one legal way to make it six Seams, and it pays the Entropy table one step up (SYS-001 §4, §7.3).
- Score never buys power inside a run (GDD-001 §3 anti-pillar). Ember is banked at the run's end: `Ember = floor(score / 200)` plus milestone bonuses (SYS-001 §7.1). The run's whole economy is *spend on the build now, bank the rest later*.
- Death inside a run is not the run's end unless it is final: Second Vigil (HULL-6) and REL-13 both spend a survival, and the entity's memory of your most-used tool survives either way (SYS-001 §2.2, GDD-001 §6.3).

### 6.2 Seeds, and what a seed fixes

| Seed kind | Who sets it | Fixed by the seed | Notes |
|---|---|---|---|
| Open run | the player | world layout, kit order, geode and Shrine placement, Sigil card pools, the rare boundary Sigil pools and which half of each 1-of-2 pair is offered, warp state, the entity's counter-behaviour order | the default; a run with no seed is still seeded, just from a rolling number |
| Daily / weekly | the clock | same list, identical for every player | the only comparison layer the game ships at 1.0 (GDD-001 §18 D-06, bounded by WARP-001 §6.1 D-06) |
| Cursed | a shared 12-character code (GDD-001 §6.3) | same list, plus one forced Cursed Sigil at Seam 1 (§4.1) | the code is the community's joke channel; the price is printed, never hidden |

- The **warp state must be derivable from the seed alone** — SYS-001 §10 locks this as a seed contract, and it is the precondition for any comparison mode: two players on one seed must see the same eaten rules in the same order. TECH-001 implements it; WARP-001 §8 R-05 is the request that closed it.
- A seed never fixes the Lantern Tree, the Codex, the Ruins or banked currency: those are anchored state (§2), and two players on one seed are expected to arrive with different trees. That is the difference between a seed and a puzzle.

### 6.3 Entropy — the escalator the player pulls

Entropy 0–10 is set at the Vigil Index board in the Ruins, before the run, and it is **cumulative** (SYS-001 §4 modifier table; payouts SYS-001 §7.3). GDD-001 §7.4 requires it be unlocked by progression rather than grind, so the ladder is gated by story facts, not by hours:

| E | Unlocked when | What the run becomes |
|---:|---|---|
| 0–1 | from the first Iteration | the game as authored |
| 2–3 | first Rite boss cleared | the Choir's tempo rises; nothing new walks in |
| 4–5 | Act 1 cleared once | Heralds enter the pool (SYS-001 §4, §5.2); the entity repairs while you breathe |
| 6–7 | Act 2 cleared once | the HUD is now part of the difficulty (SYS-001 §4 at E6: one persistent lie) — the run is played against WARP-001 §4, not just against the Choir |
| 8–9 | Act 3 cleared once | the Choir's laws bend: Grubs may attack, phantoms persist — these are **rule breaks the player opted into**, which is why they are Entropy and not Warp |
| 10 | any of endings 2–5 seen (ending 1 is shown at every Hard Unmaking and does not count; §11) | the entity opens each sector at 6 segments ✱ (SYS-001 §4); the flex tier, and the tier the four loadouts in §5.4 are stress-tested against |

- **Entropy is the only difficulty the game lets the player choose**, and the only one that pays (SYS-001 §7.3 Ember ×1.15→2.30; the Ink multiplier retired with Ink, CHD-15). It never touches the player's side of the ledger in any other direction.
- E7 and above deliberately break faction laws (Grubs attacking, SYS-001 §3; phantoms persisting, §4). We put opt-in rule breaks on the *player's* escalator and keep the entity's escalator (Hunger, §6.4) to what it would do anyway. That is the honesty line: the game never takes a rule without being asked, except by the warp, which tells you in the Codex the same run.

### 6.4 Hunger — the escalator that pulls itself

Hunger is entity-side, automatic, and never shown as a number (SYS-001 §2.2 🔒: +1 per Hard Unmaking, +1 per sector eaten, +1 per iteration lost to the clock, ending 1 costs +2). GDD-001 §7.4 promises one new eaten rule every two Hunger; **WARP-001 §3.2 owns the list and its order**, and its H-IDs are Hunger levels, so the mapping is not a metaphor:

| Hunger | Loop consequence | Rule taken |
|---:|---|---|
| 2 | the run's geography becomes a cost | **H2** — the seam you crossed seals behind you (`seam_close_after` 20 s, SYS-001 §6) |
| 4 | your own light becomes a tell you cannot trust | **H4** |
| 6 | the Ledger Compass starts holding its own opinions | **H6** |
| 8 | the Choir behaves like it has met you before | **H8** (counter-behaviour table, SYS-001 §2.2) |
| 10 | the entity stops being a boss and starts being an editor | **H10** |
| 12 | your build is no longer safe to finish | **H12** |
| 14 | a chosen Run Sigil is struck out mid-run | **H14** — no restore, by ruling (WARP-001 §3.4; LOOP owes pick logic and `no_restore = true`, and no Pact: WARP-001 §6.1 D-10). REL-18 pays grief, it does not undo it |
| 16, 18 | the last things a player assumes about the game | **H16**, **H18** |

**The two-axis law.** *Warp Tier* is per-run and rises with that run's violence (WARP-001 §1). *Hunger* is iteration-long and rises with that iteration's failures. They are the same aesthetic and opposite clocks: a clean run at high Hunger still opens at T0, and a filthy run at Hunger 0 still opens at T5. Every escalation claim in every doc is a claim about one of these two axes, and the docs must say which.

**Pacing budget ✱** (the loop's own arithmetic, not SYS-001's, and the first thing to move when playtest data arrives): the cadence is §10.3's — roughly **+3–4 Hunger per Iteration** (the ninth-sky close is +2, GDD-001 §9.3 ending 1, plus a typical one or two Hollow sectors), which crosses H2–H8 inside Act 2 and leaves H10–H18 for Act 3, exactly the earliest-legal-act column of WARP-001 §3.2. Nine eaten rules on an even-numbered ladder is an 18-level runway; at ~1 rule per Iteration in Act 2 and ~2 in Act 3 a 20–40 h Chronicle consumes the whole registry exactly once, and Act 4 plays at a full registry. If playtest says the registry spends too fast, the fix is the *cadence* in SYS-001 §2.2 — the +1-per-sector-eaten source is the one to stretch — and not a new eaten rule.

### 6.5 The Hourglass Clock, and what spends it

| Fact | Value | Consequence for the loop |
|---|---|---|
| Clock per **Iteration** | 120 loop-minutes at Entropy 0 🔒 (GDD-001 §6.2) | the budget for all nine skies; a sky darkens each time one ninth of it is spent (every 13⅓ loop-minutes, derived) — see the ruling below |
| What spends it | real time in runs and in the Ruins (WARP-001 §6.1 D-01: never during pause, Codex, cinematics or attract mode); a **death** spends a lump on top (GDD-001 §6.2: 10–18 min — **requested SYS-001 §6 row ✱**: `10 + 2 × (Seam index − 1)` loop-minutes, so Seam 1 costs 10 and Seam 5 costs 18) | dying deep is expensive; dying early is a cheap lesson |
| What buys it back | **a run won** (the Waking unmade at Seam 5) refunds time (GDD-001 §6.2 "every time you win a run you buy time") — **requested SYS-001 §6 row ✱**: +15 loop-minutes, never above the 120 ceiling | a clean run nets about 15 loop-minutes of a 30-minute run, so skill is literally more sky |
| Runs per Iteration | **≈4–7** (GDD-001 §2), ≈2–3.5 real hours | Act-1 player, 2 wins / 3 deaths: 2 × 15 + 3 × ~29 + Ruins ≈ 130 → five runs. Expert, 6 wins / 1 death: ≈ seven runs. §9.4 builds the Chronicle on these numbers |
| Skies per Iteration | 9 🔒 | a 20–40 h Chronicle is **4–8 Iterations** (§10), so Hard Unmaking lands 4–8 times: enough unlock beats to be a retention machine and few enough to stay sacred |
| Reading the Codex | pauses the clock 🔒 (GDD-001 §6.2) | the Codex is free, and §8 makes sure of it: lore is never taxed |
| A sky going dark mid-run | **the run continues**: the Ledger Compass loses that sky's row, the chant drops a voice, the Ruins have changed when you return. Only the **ninth** sky ends the run, and it banks what it earned | forward progress is a law (§1). The Seam in progress is lost only at the ninth sky, never more — the same ceiling SYS-001 §8 sets for a crash |
| Hunger from skies | none from the eight intermediate skies | the star grows from the sectors it eats (SYS-001 §2.2) and from the ninth sky's close (§10.3), not from each darkening |

**Ruling (LR-04, reversed in Rev 1.2).** Rev 1.1 read the clock as **per sky** to keep a sky from closing mid-run. Doing the arithmetic killed it: nine skies × 120 loop-minutes is an 18-hour Iteration, which contradicted this table's own "3.5–6 loop-hours", GDD-001 §2's "4–7 runs / 2–3 h" Iteration, and the 18–25 h first-true-ending target. The clock is therefore **per Iteration** (GDD-001 §6.2's first line, as written), and the mid-run problem is solved by the row above instead: an intermediate sky darkening is an in-run event, not a run end. GDD-001 §6.2's phrase "the next sky goes dark, the run ends" must be read as "the ninth sky" — requested footnote in §14 Q-01. LR-05 still stands: the Iteration budget, the death lump and the win refund belong together in SYS-001 §6 as one block, because the run-length target and the clock are one equation.

## 7. Pacts — the Chalk Desk, one per run

A Pact is the run's contract, written at the Chalk Desk in the Ruins before the run starts (GDD-001 §6.4). Twenty-four exist. Sixteen shape what a run *is for*; eight exist because the warp took a rule and someone has to be able to bargain it back — those eight IDs are reserved by WARP-001 §3.3, and their restore semantics are not ours to change, only to price and to dress.

### 7.1 Pact rules

| Rule | Statement |
|---|---|
| One per run | the Chalk Desk writes **one** Pact per run. The ink is spent whether you use it or not; an unused Pact still counts as the run's Pact |
| When | before the run, in the Ruins. Never mid-run, never at a Seam boundary — a Pact is a promise, and a promise you can change mid-fight is a toggle |
| The price | always paid in run-state or world-state: Composure, Charges, hull, time, information, the Choir's behaviour. **Never in Ember** — a Pact priced in currency would tax the anchored tree, and the tree is the one thing the loop guarantees (§1) |
| Breaking a Pact | a Pact whose text is violated is void for the run: its grant stops, and for a restore Pact the rule returns to eaten at once. A void Pact is still the run's Pact — you do not get a second one. The Codex marks it struck-through, which is the same treatment the warp's eats get, and that equivalence is the point |
| The entity remembers | the Chalk Desk's ledger of which Pacts you have held survives death and Hard Unmaking as *knowledge* (NARR-001), and the entity's counter-behaviour pool draws on it (SYS-001 §2.2). It never draws on it as a *penalty to currency* (SYS-001 §7.4) |
| Solvability | every Pact must leave SYS-001 §4's `Solvability lint` passing while its grant is active and after it is voided. A Pact that rescues an unwinnable seed is a bug in the seed, not a feature of the Pact |
| Restore scope | default is run-scoped (WARP-001 §3.1). A restored rule returns the locked default *exactly*: no buff, no residue of the eaten version (§3.1's restore honesty) |
| Permanence | **declined mechanically.** See §7.6: WARP-001 §3.3 asks whether one Pact may survive death; LOOP-001 answers no at 1.0 and grants the anchored variant instead |
| Pre-attached rule-threads | allowed by WARP-001 §6.1 **D-03**: a pre-attached thread counts as **already latched**. It does not lower the 3-thread requirement, does not reduce SYS-001 §2.1 `Unravel hits`, and does not expose a thread the entity has not exposed. One Pact uses this: PACT-21 |
| The eight reserved IDs | PACT-01, 04, 07, 10, 13, 16, 19, 22 map to H2, H4, H6, H8, H10, H12, H16, H18 in that order. **PACT-01 and PACT-04 are slice-blocking** (WARP-001 §6.1 D-10); the other six are Act-3-and-later content |
| H14 has no Pact | by ruling, not omission (WARP-001 §3.4, §6.1 D-10). There is no PACT for H14 at any price. What LOOP owes instead is §7.5 |

### 7.2 The eight restore Pacts

| ID | Pact | Restores (WARP-001 §3.3) | The price | Bound honoured | Slice |
|---|---|---|---|---|---|
| **PACT-01** | **Open Door, Open Hand** | H2 — no seam closes after a crossing for the run | the seams re-key under W3-01 as usual, and you must *walk* the re-keyed map: the Ledger Compass will not redraw the new pairing for you, so a Pact-held run has one fewer lie **and** one fewer certainty | must not widen W3-01's re-keying; must not re-open a seam H2 closed earlier in the sector | **required for the slice** |
| **PACT-04** | **The Glass Comes** | H4 — the SYS-001 §1.4 magnet row applies at its signed base value again, `Hookline` included | the repulsion is not erased, it is *parked*: the pale ring still draws for one sector after the Pact is voided, and shards skid off it while it fades | must not add magnet radius, must not auto-collect, must not pull through geometry | **required for the slice** |
| **PACT-07** | **The Dark Still Hides** | H6 — the SYS-001 §1.2 detection pair applies again at its stated values | the registry pair goes, and with it LANTERN-5's bonus to the *replaced* pair reverts to the base pair for the run — the node is not lost, its value is returned to where it was authored | must not reduce detection below the base row: it returns a rule, it does not grant stealth | Act 3+ |
| **PACT-10** | **Nine in a Breath** | H8 — SYS-001 §1.3 `Over-fire detonation` fires again | the geode stops eating Mourning Glass, and the shards it had already swallowed stay swallowed: no refund, no double release | must not raise the detonation threshold, must not grant extra shards | Act 3+ |
| **PACT-13** | **Lance Against the Quiet** | H10 — the Arc-Lance damages Oubliette Grubs at SYS-001 §3's HP values | the Grubs keep the E7 opt-in attack rule (SYS-001 §4): the Pact buys the lance back, not your safety | must not reduce Grub HP, must not extend to other Choir units, must not remove the E7 attack rule | Act 4+ |
| **PACT-16** | **Burn It Clean** | H12 — SYS-001 §1.5 `Surgelight` regains its tier condition and the §9 Shroud row offers the Surgelight clear alongside the Ward clear | the cost row's value does not move, and the clear stays single-cell: you are buying back the *condition*, not a stronger burn | must not change the cost value, must not clear Shroud at range or over multiple cells per burn | blocked on the owed SYS-001 §9 Shroud-clear row (LR-06) |
| **PACT-19** | **Name in the Ledger** | H16 — the Compass may show the entity marker again, subject to the ordinary WARP-001 §4.2 lie allowance at T ≥ 3 | the marker is a dot, nothing else: no phase, no segment count, no Waking state — those are §4.7 never-lies elements and the Pact cannot reach them | as stated in WARP-001 §3.3 | Act 4+ |
| **PACT-22** | **Unmake in the Third Sky** | H18 — rule-level unmaking is legal in Act 3 as well as Act 4, at SYS-001 §2 phase 6's latch time | the run must still expose three threads in the open way; nothing about the fight's shape is softened | must not pre-attach or spend a thread, must not reduce the 3-thread requirement or `Unravel hits`, must not stack with itself | Act 5 / NG+ |

### 7.3 The sixteen shape Pacts

| ID | Pact | What it grants | The price | Anchor |
|---|---|---|---|---|
| **PACT-02** | **The Fast Twelve** | the run may ring off at Seam 4: you meet the Waking one Seam early, carrying what you carry | Seam 5's sector is forfeit and counts as **eaten**: +1 Hunger ✱, at most once per Iteration ✱ | SYS-001 §6, §2.2; GDD-001 §6.3 |
| **PACT-03** | **Salt in the Seams** | one ward line drawn on one seam per sector; no eat can close that seam ✱ | you cannot cross it either: a seal you built is a wall you built, and it is not an escape vector for §4's lint | SYS-001 §1.5, §4 |
| **PACT-05** | **The Open Ledger** | you see the next registry eat one Seam before the entity speaks it, in the Codex | when it lands, −1 Composure: knowing it was coming does not make it hurt less | SYS-001 §1.5; WARP-001 §3.1 telegraph law |
| **PACT-06** | **Lampkeeper's Debt** | a fourth Run Sigil, chosen for you, cursed, from the SEAM family | its downside is halved while held, and −1 Composure at every run's end for as long as the Pact is taken | SYS-001 §6 (cursed Sigils at E ≥ 3); §1.5 |
| **PACT-08** | **The Quiet Contract** | the entity may not bring a counter-behaviour into a sector's first 60 s ✱ | you may not fire the Arc-Lance in that window; firing voids the Pact for the run and the rule of silence is written struck-through | SYS-001 §2.2 counter table, §1.3 |
| **PACT-09** | **Grub Promise** | Grub panic never spreads to your position, and Oubliette Grubs within 300 px never rejoin a procession ✱ | every face you leave to the Choir corrupts on the Choir's clock: more Shrines, sooner Hollow (SYS-001 §6) | SYS-001 §3, §3.1, §6 |
| **PACT-11** | **The Higher Sky** | Entropy is read one step above the step you chose; payouts use the higher row (SYS-001 §7.3) | everything the higher step brings arrives: the E6 HUD lie at E5-chosen, the E7 attack rule at E6-chosen. This Pact has no grant — the price *is* the product | SYS-001 §4, §7.3 |
| **PACT-12** | **The Unmade Name** | the entity never counters your most-used tool this run | the counters stop being predictable: one is drawn blind at each sector boundary ✱, and the Codex does not say which | SYS-001 §2.2 |
| **PACT-14** | **Nine for the Sky** | the Hourglass Clock runs 25% slower for the run ✱ | +1 Hunger at the run's end: the star eats one more sector of appetite for the time you took | SYS-001 §2.2, §10 clock lock — see request **LR-01** (REL-14 asks the same question) |
| **PACT-15** | **Bell of the Long Vigil** | killing a named Herald pays one extra Run Sigil pick at the next boundary ✱ | that sector's corruption clock runs 25% faster while the bell is still ringing ✱ | SYS-001 §4, §5.2, §6 |
| **PACT-17** | **Censer Debt** | 2 Charges buy back a fallen geode face: it returns to a mineable state once per sector ✱ | the face carries a fresh corruption clock the moment it returns (SYS-001 §6, geode → Shrine 90 s) | SYS-001 §1.3, §6 |
| **PACT-18** | **Vigil of the Ninth Sky** | the run begins at 1 hull and +2 Composure, and the first rare boundary Sigil offer (§5) is 1-of-2 → **1-of-3** | hull never repairs inside the run; one Listener touch and the run is over where it stands | SYS-001 §1.1, §1.5, §3 |
| **PACT-20** | **Chalk Line Nine** | draw one artificial boundary per sector that only you cross ✱ | 1 Composure to draw, and it is not an escape vector: SYS-001 §4's lint never counts your chalk, so a bad seed stays bad | SYS-001 §4, §1.5 |
| **PACT-21** | **The Unmaking Rehearsal** | the Waking is preceded by the Rehearsal; after it, the run holds **one pre-attached rule-thread** | the scene costs 90 s of the Hourglass Clock, and the thread counts as already latched — the three-thread requirement and SYS-001 §2.1 `Unravel hits` do not move | WARP-001 §6.1 **D-03**, §5 (the Rehearsal and its NG+ re-key, **D-09**); SYS-001 §2.1 |
| **PACT-23** | **Lantern to the Choir** | lighting a face calls an Acolyte to work it with you for 60 s ✱: the face shatters on the earlier schedule and you take 60% of the shards ✱ | the face corrupts at the Choir's rate (SYS-001 §6) and the Litany Ring gains a ninth node, so breaking it now takes five downed nodes ✱ | SYS-001 §3.1, §6 |
| **PACT-24** | **Salt Mother's Favour** | a face you never mine stays clean: no Shrine may form on it this run ✱ | those shards are lost to you for the run — a quiet sector is a poor sector, and the Hollow clock is the only thing this Pact buys | SYS-001 §1.3, §6 |

### 7.4 What H14 actually costs, and what LOOP owes for it

WARP-001 §6.1 **D-10** rules that LOOP-001 owes two slice-blocking Pact rows plus H14's pick logic and its `no_restore = true` flag — not nine Pacts. The pick logic:

| Clause | Spec |
|---|---|
| The pool | the struck Sigil is chosen from the Run Sigils the player **currently holds**, and the pick must come from the run's legal Sigil pool (WARP-001 lint **L-06**) |
| Never struck | a rare boundary Sigil (the former Relics, §5.2: the warp never eats a gift); a Cursed Sigil (its removal would be a reward, not a theft — §4.1); a Sigil a capstone or a branch prerequisite depends on (the tree would silently re-price, §3.3); a Sigil whose removal fails SYS-001 §4's solvability lint |
| The steer | the entity prefers the Sigil the *player is playing* — the one whose effect has fired most often in the run so far ✱. A player can steer the pick by playing the way that build plays (WARP-001 §3.4). There is no counter and no reroll, and the pick is announced in the four channels §3.1 requires |
| The guarantee it trades | GDD-001 §3's pity/choice guarantee for Run Sigils is suspended for this one boundary. WARP-001 §9.2 **C-04** asks the GDD owner to footnote it; the trade is bounded to a single Sigil, one eat per Seam (§3.1), never in the first 2 s, and the run is never left unwinnable |
| Compensation | **REL-18 Mourning Ledger** pays 1 Composure and 60 Ember at the run's end and records the struck Sigil's name. It does not restore, and §5.2 says so in the rules table, so `no_restore = true` and lint L-06 stay satisfied |
| The line | one line of dialogue, plain-spoken, no system vocabulary, spoken at the Chalk Desk by a hand that is not yours. NARR-001 §7/§8 own the text and the Codex entry; LOOP-001 specifies only that the line must name the struck Sigil's own name and nothing else |

### 7.5 Rollup and requests

**Pact rollup.** 24 = 16 shape + 8 restore. Reserved IDs are exactly WARP-001 §3.3's eight; no ninth exists. Prices in Composure (5), Charges (2), hull (1), time (3), world behaviour (9), information (3), Hunger (2), and 1 Pact with no grant at all (PACT-11). Grants that touch the Hourglass Clock: **REL-14, PACT-14** — both wait on LR-01. Grants that touch the Hourglass Clock's *pacing* only (PACT-21 spends clock on a scene, spends no rate) do not.

| Request | To | Ask |
|---|---|---|
| **LR-06** | SYS-001 §9 | PACT-16's restore target is the §9 Shroud-clear row plus §1.5's Surgelight cost row; the Shroud row's per-second clear value is still owed to SYS-001 (§3.3's footnote). PACT-16 is unbuildable until that row exists |
| **LR-07** | GDD-001 §20 | PACT-02's "+1 Hunger per forfeited sector" is the only place in the game where the *player* can add Hunger. LOOP-001 caps it at once per Iteration ✱ and asks that the cap live in SYS-001 §2.2 next to the other Hunger sources, so the entity's escalator cannot be farmed |
| **LR-08** | WARP-001 §3.3 | The restore-permanence request is **answered in §7.6** rather than deferred: mechanical permanence is declined at 1.0; the anchored variant is offered instead. WARP-001's status column should read "answered by LOOP-001 §7.6" |

### 7.6 Ruling on permanent restore (answering WARP-001 §3.3)

WARP-001 §3.3 permits one Pact whose restore survives death, asking only that the eaten state be re-announced next run. **LOOP-001 declines the mechanical version at 1.0 and grants the knowledge version instead.**

| | Decision |
|---|---|
| What is declined | any restore that survives death. A permanent restore of H2 or H4 deletes the loop's first two eats for the rest of the Chronicle, and an escalation ladder with rungs you can permanently saw off is not a ladder |
| What is granted instead | **anchored knowledge**: once a rule has been restored by any Pact, its Codex entry keeps both versions legible forever — the struck line and the restored line, with the Pact that bought it named. The rule is eaten again next run; the *fact that it can be bought back* never is. That is the same class of guarantee the Lantern Tree is, and it costs no escalation |
| Reversal condition | if playtest shows players treating an eat as a permanent loss they cannot reason about — that is, if the Codex's two-line entry is not enough — then one Pact, PACT-01, becomes permanent for the rest of that Iteration (death does not drop it, Hard Unmaking does). That is the middle rung, and it is one flag |
| Why this is the right shape | the loop's law is forward progress, not lost-and-found. WARP-001 §3.1's restore honesty already forbids a restored rule from carrying residue; forbidding it from carrying *permanence* is the same instinct pointed at the save file |

---

## 8. The Codex — knowledge as progress

GDD-001 §8.9 makes reading a mechanical reward. Until Rev 1.3 every entry paid **Unwritten Ink once**; Ink is retired (CHD-15; PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3), and the Codex no longer pays anything. **A stamp now gates:** 27 entries each open one Lantern Tree node (§3.7), so a player who engages with the fiction still gets power for it, by knowing rather than by spending. This section owns the Codex's *mechanics*: what an entry is, what unlocks it, what it gates and what completing it grants. NARR-001 §8 owns every word of entry prose and marginalia; AUDIO-001 E08 owns the stamp cue.

### 8.1 Rules that never move 🔒

| Rule | Statement | Source |
|---|---|---|
| Reading pauses the Hourglass Clock | always, in every Act, at every Warp Tier, in a daily | GDD-001 §6.2; WARP-001 §6.1 D-01 |
| A stamp gates, it does not pay | an entry is *stamped* once (unlocked and opened once). No entry pays a currency: not on the stamp, not on re-reading, not in marginalia. A gating entry's stamp meets its node's gate (§3.7) for the rest of the Chronicle | GDD-001 §8.9 as amended by CHD-15 |
| Payout value | **retired** with Ink: the SYS-001 §7.2 `Codex firsts` row and the §7.3 Entropy Ink multiplier no longer apply (LR-13) | CHD-15 |
| Knowledge is anchored | Codex entries survive death, Hard Unmaking and New Iteration (§2) | GDD-001 §6.2 |
| The Codex never lies | no warp effect may falsify, strike or hide an entry. The Codex is where the warp is *explained after the fact* (WARP-001 §4.2 L8); a struck rule is struck in ink by the Codex, not by the warp | WARP-001 §4.7 |
| Lore is never taxed | nothing in the game costs anything to read, and no Pact, Sigil or eat removes an entry; a stamp is never undone | §6.5 |

### 8.2 Entry classes

Entry IDs are invariant (`cx_<class>_<slug>`), live in data, and are what saves and telemetry store (TECH-001 §7; L10N-001 §4). Counts are the 1.0 plan; §12 costs them.

| Class | Prefix | What it records | Unlocked by | Entries | Tree gates (§3.7) |
|---|---|---|---|---:|---:|
| Bestiary | `cx_choir_` | the eight Choir units, the six named Heralds, the five Rite bosses, the entity (one entry whose seven phase lines fill in as you witness each phase, SYS-001 §2), and **the Choir's sacred things and rites** that are not units: the Shrine, the Litany Ring, the Procession and the saint (widened 2026-11-18, CHD-15) | **first kill** of the variant (GDD-001 §7.1); a Herald or Rite entry on first defeat; the entity entry on first Awakening seen; a sacred thing or rite by its §3.7 discovery source | 24 | 10 |
| The making | `cx_glass_` | Mourning Glass, Null-Iron, the Ninth Light, the Lantern Office's tools — the material history of the failed star | first time you touch the thing in play (first shard banked, first Charge lost to interception, first Sepulchre deposit broken…) and Ruins discoveries | 12 | 2 |
| Rules | `cx_rule_` | **eaten** rules: one entry per WARP-001 §3.2 eaten rule (H2…H18), in the **two-line struck/restored format** of §7.6; and **taught** rules (widened 2026-11-18, CHD-15): one entry per standing rule or state the player meets that is not an eat (`cx_rule_gaze`, `_frayed`, `_lantern_dark`, `_unmoored`, `_bleeding`, `_the_passing`, `_hollowed`, `_inverted`, `_hollow_sector`, `_the_glimpse`), with no struck block (NARR-001 §8.2 additions) | eaten: the **struck line** writes the moment the eat lands; the **restored line** writes the first time any Pact restores it. Taught: its §3.7 discovery source or backstop | 19 (9 eaten + 10 taught) | 10 (all taught) |
| Rare boundary Sigils (former Relics) | `cx_relic_` (invariant id prefix, never shown) | each rare boundary Sigil, with every run you carried it in | first time one is *held* (taken from its 1-of-2) | 18 | 0 |
| Run Sigils | `cx_sigil_` | six family pages (LANTERN, HULL, ORDNANCE, WARD, MADNESS, SEAM); each card Sigil you ever held adds one line to its page | page opens on the family's first Sigil held; completes when all 20 of the family have been held across the Chronicle | 6 | 0 |
| Places | `cx_place_` | the six biomes, the nine skies (each written when it goes dark for the first time), the three Act 0 cabinet stages, and the five biome grief stories filed as places (`cx_place_litany_pew` and four more; NARR-001 §6.5 — The Black's is `cx_vigil_unlit_ring`) | first sector entered of the biome; first darkening of each sky; Act 0 stage clears; a grief story when found | 23 (+4 if the reserve kits get their own entries, NARR-001 §14 Q-13) | 2 |
| The Ruins | `cx_ruins_` | letters and notes from the Ruins cast (NARR-001 §5): Sable Vane ×4, Ilse Marrow ×4, Brother Wick ×4, the Cabinet ×3, plus the Chalk Desk ledger (one page; a line per Pact you have ever signed) | §10.4 Hard Unmaking beats and cast conditions | 16 | 0 |
| Chronicle | `cx_chron_` | what really happened (NARR-001 §10), one page per Hard Unmaking (up to eight), one per ending seen (five), one per Entropy tier first cleared (E1–E10, SYS-001 §7.3's "exclusive Codex entry per E-tier"), and **Chronicle milestones written after the Office** (widened 2026-11-18, CHD-08/CHD-15: `cx_chron_first_absence`, `cx_chron_unmade_at_t3`, `cx_chron_thread_iv`; dated *Undated*, NARR-001 §8.2 additions) | Hard Unmakings, endings, Entropy clears; a milestone when it first happens in the Chronicle (or by §3.7 backstop) | 26 | 2 |
| Your Vigil | `cx_vigil_` | your own Chronicle: every death line the entity spoke to you (SYS-001 §8 composition), Vigil Index bests, the Sigils H14 took; and (widened 2026-11-18, CHD-09/CHD-16) authored pages about your own Chronicle's dead that carry none of your numbers (`cx_vigil_still_lit`, `cx_vigil_unlit_ring`). A `cx_vigil_` entry may gate a node; the class stays outside the counted total and completion | generated from play; an authored page when its condition is met | open-ended | 1 (`cx_vigil_still_lit`) |
| **Total** | | | | **144 + your Vigil** (122 planned + 22 added 2026-11-18; +4 if NARR-001 §14 Q-13 gives the reserve kits their own entries) | **27** |

**Class notes for the gating ids (reconciled 2026-11-18 with NARR-001 §8.6–§8.7; NARR-001 §8 owns the ids, N-4; cosmic horror design call within CHD-15, flagged in the Phase 2 PR).** Four proposed ids folded onto existing or correctly named ids: `cx_choir_vested` → `cx_choir_acolyte`, `cx_choir_comforters` → `cx_choir_deacon` (samples of the same subject), `cx_place_drowned_observatory` → `cx_place_the_drowned_observatory` (the biome naming), and `cx_entity_glimpsed` → `cx_rule_the_glimpse` (a taught rule; there is no `cx_entity_` class). The class descriptions above were widened so every gating id fits a class: taught rules in `cx_rule_`, the Choir's sacred things and rites in `cx_choir_`, Chronicle milestones in `cx_chron_`, authored pages about your dead in `cx_vigil_`. **Recount:** 22 ids join the 122 plan: 17 from the gating map (`cx_choir_shrine`, `_litany_ring`, `_saint`, `_procession`; the ten taught `cx_rule_`; `cx_place_litany_pew`; `cx_chron_unmade_at_t3`, `_thread_iv`) and 5 from NARR-001's revision (`cx_chron_first_absence` and the four other `cx_place_` grief entries), giving 144. Still open: the reserve kits' own entries (NARR-001 §14 Q-13, +4 if adopted) and the Hollow sector's two entries on one subject (`cx_rule_hollow_sector` and the NARR-001 §6.4 `cx_place_` amendment).

### 8.3 The struck/restored rule entry (the format §7.6 promised)

Every `cx_rule_` entry is two lines and a footer. Shape only; NARR-001 §8 writes the words.

| Part | Written when | Looks like |
|---|---|---|
| Line 1 — the trusted rule | at the eat | the rule as the player knew it, **struck through in chalk** |
| Line 2 — what replaced it | at the eat | the eaten version in plain words, the Hunger level and the Seam it happened in |
| Footer — the restore | first restore by any Pact | the restored rule rewritten under the strike, with the Pact named ("bought back by PACT-01, *Open Door, Open Hand*, Iteration 4") |
| H14 footer | every time H14 fires | the struck Sigil's own name and what it had done that run; no restore footer ever exists (WARP-001 §3.4; §7.4) |

The strike stays visible forever, even when restored. That is the anchored knowledge §7.6 grants in place of mechanical permanence: you cannot keep the rule, but you can never lose the fact that it could be bought back.

### 8.4 Marginalia — the Archivist's hand

From **Iteration 2** (after the first Hard Unmaking), Ilse Marrow annotates entries you have already stamped. Marginalia are the Codex's second voice and its quiet retention engine: old entries change, so players reopen them.

| Rule | Value |
|---|---|
| When a note appears | when an entry's subject recurs in a new context: a unit seen at a higher Warp Tier, a rule eaten a second Chronicle-time, a biome entered under a different sky, a cast letter answered by a later one |
| Budget | ≤ 1 note per entry per Iteration ✱; ≤ 3 notes per entry total ✱ (NARR-001 §8 owns the text) |
| Pays | nothing. Marginalia are knowledge, not currency |
| Signals | the entry's spine in the Codex index gets a chalk tick; no pop-up, no badge count (P5: no menu bloat) |
| Ending 5 | the **Archivist** variant (§11.6) rewrites the marginalia of every `cx_choir_` entry as Ilse's corrected record. The original notes stay readable underneath — the Codex never deletes |

### 8.5 Completion milestones

Completion counts the 144 class entries (not `cx_vigil_`; the 122 plan plus the 22 ids reconciled with NARR-001 on 2026-11-18, §8.2; +4 if NARR-001 §14 Q-13 gives the reserve kits their own entries). Every grant is **information or presence, never a stat** — the game's power curve is avoidance and information (GDD-001 §8.1, D-08), and the Codex is the most honest place to pay it.

| Milestone | Grants | Visible as |
|---|---|---|
| 25 % | **The Archive opens** in the Ruins: Ilse's desk, Codex search, and cross-links between entries | a new lit room in the Ruins |
| All of `cx_choir_` | **Annotated Choir** ⚙: every Choir unit's attack tell gains a 1 px chalk tick on its wind-up frame (a legibility aid, toggleable, honoured by Steady Ledger) | the Acolyte's censer shows a tick the frame before it fires |
| 50 % | the Codex index gains the **Chronicle timeline**: every Hard Unmaking, ending and Hunger level you have lived, on one page | a long chalk line in the Archive |
| 75 % | the Lantern Tree **flowers**: cosmetic glass blossoms on every owned node (existing node art, palette-shifted) | the hub is brighter than it has ever been |
| 100 % | Ilse Marrow's own entry (`cx_ruins_ilse_last`), and the achievement **The Record Is Complete** (§11.9) | the Archive's lamp goes out — she is finished |

### 8.6 The Codex on screen (mechanics only)

- Opened with Tab / Right-click-hold in the Ruins (GDD-001 §4.1) and from the pause screen inside a run. In a run it shows only entries already stamped; new stamps queue for the run summary so a fight is never interrupted by a page.
- The **run summary** is where new entries are stamped: up to five per summary ✱, the rest wait in the Archive tray. The stamp is the moment knowledge lands (AUDIO-001 E08's chalk-on-slate sound): a gating entry's stamp also lights its Lantern Tree node as buyable (§3.7), which makes the summary screen a reward beat instead of a stats wall. Two exceptions stamp outside the summary: MADNESS-7 *Hollow Ledger* stamps first kills mid-run while Frayed or worse (no page opens mid-fight), and the §3.7 tier-floor backstop stamps at the start of an Iteration, shown on the next Ruins visit.
- Unread stamped entries carry a chalk tick on their spine. There is no "unread" counter on the HUD.

---

## 9. Economy flow

Three currencies, three jobs, and no exchange rate between them. Unwritten Ink was the fourth until Rev 1.3; it is retired (CHD-15; PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3), its rule nodes are Codex-gated (§3.7), and the 20 : 1 overflow valve that fed it is replaced by the post-tree Ember sink (§9.6). SYS-001 §7 owns every value; this section owns the *flow* and checks it against the tree totals in §3.3.

### 9.1 The currencies

| Currency | Job | Sources (SYS-001) | Sinks | Persists |
|---|---|---|---|---|
| **Ember** | power, then memory | the Act 0 bank, once, at the first Ruins visit, paid out in tickets (1 ticket = 1 Ember; SYS-001 §7.1 `Act 0 bank`, which has a floor so a first T1 node is always affordable; TECH-001 §11.1a Q-T146, Q-T148); score → `floor(score / 200)` + milestones (§7.1); Seam clears 40 each, Seam 5 included (SYS-001 §7.2; Q-T145); elites and Heralds 60–200 per run (§7.2); REL-18; Tithe (SIG-W-08); Shrine purge, first per biome per Iteration (SYS-001 §6; amount value owed, it replaced 15 Ink); the former Ink Sigils SIG-S-04, SIG-S-08, SIG-S-18, SIG-W-20 (amounts value owed) | Lantern Tree Ember nodes (17,480 total, §3.3); in-run Sigil rerolls (SYS-001 §7.7; §4.1), which SIG-S-14 lets banked Ember pay (adopted 2026-11-18, §4.2); REL-17 latches; respec at 10% of banked Ember (§3.5); after the tree, **relighting the Ruins** and **rekindling a death-site Penitent** (§9.6; prices value owed) | death, Hard Unmaking |
| **The Codex** (not a currency) | rules | stamps (§8); the §3.7 backstops (tier floor, death) | nothing is spent: 27 entries each *gate* one node (§3.7); the rest gate nothing | everything (anchored, §2) |
| **Fragments of Unraveling** | the ending | high-tier Wakings, high-tier Rites, Heralds, Hard Unmakings, endings — **all requested SYS-001 rows, §9.4** | the five **Threads of Unraveling** (§9.4) | everything, even the loop (GDD-001 §7.1) |
| **Mourning Glass / Charges** | the run | mining (SYS-001 §1.4) | Charges, interception, Grub theft | never |

Two laws: **no currency buys power inside a run** except the one-line Ember reroll (GDD-001 §3 anti-pillar; §6.1), and **nothing the warp, Hunger or a Pact does ever reduces a banked currency** (SYS-001 §7.4; §7.1 "never in Ember").

### 9.2 Per-run flow (SYS-001 §7.2, T1, E0)

| Outcome | Ember banked | Codex stamps (gates, not currency) | Fragments |
|---|---|---|---|
| Won run (the Waking unmade) | 450–800 (SYS-001 §7.2 run total; plus the former-Ink Sigil and Shrine purge Ember, value owed) | the entries discovered this run, falling as the Codex fills (stamps are finite, §8.2) | per §9.4, only at Warp T ≥ 3 |
| Death run | what the run earned so far — **modelled ✱ at about half a won run** (score and Seam clears stop accruing; this is a model assumption, not a game number) | the stamps it earned (unchanged by death), **plus** one pending gating entry from the death-teaches backstop (§3.7) | none from the Waking |
| Reroll spend | from the first to the sum of all four SYS-001 §7.7 `Run Sigil reroll` prices per run, if all four rerolls are used | — | — |

### 9.3 Knowledge is finite on purpose (formerly "Ink is finite on purpose")

Until Rev 1.3, Ink's largest source was the Codex, so Ink was already a knowledge currency in disguise. CHD-15 removes the disguise: the 27 rule nodes ask for the knowledge itself (§3.7). Knowledge cannot inflate and cannot be farmed: each gate opens once, from one entry, and nothing but discovery or a backstop opens it. The shape GDD-001 §7.2 wants holds, more literally than before: **MADNESS, the Codex branch, is gated by having read the game** — and, through the backstops, by having lived it (a death teaches; an Iteration teaches).

### 9.4 Fragments of Unraveling and the Threads

GDD-001 §7.1 gives Fragments two sources ("entity kills at high Warp Tier, iteration completions") and one sink (the five Threads). SYS-001 has no rows yet; these are **requested SYS-001 rows, all ✱**, tuned so the fifth Thread lands in Iteration 6–8 (the brief's Act 4 window) for a median player:

| Source | Fragments ✱ | Cap |
|---|---:|---|
| Waking unmade at Warp T ≥ 3 | 1 | once per run |
| … and at Warp T ≥ 4 | +1 (2 total) | once per run |
| Rite boss cleared at Warp T ≥ 4 | 1 | once per run |
| Named Herald, first defeat of each per Iteration | 1 | 6 per Iteration |
| Hard Unmaking (the ninth sky closes) | 3 for Hard Unmakings 1–4; **6 from the fifth on** (the catch-up) | per Iteration |
| An ending 2–5 seen for the first time | 2 | 4 lifetime |

| Thread | Cost ✱ | Also requires | Earliest |
|---|---:|---|---|
| I | 4 | 1 Hard Unmaking witnessed | Iteration 2 |
| II | 6 | 2 Hard Unmakings | Iteration 3 |
| III | 8 | 3 Hard Unmakings | Iteration 4 |
| IV | 10 | 4 Hard Unmakings | Iteration 5 |
| V | 12 | 5 Hard Unmakings | Iteration 6 |
| **Total** | **40** | | **Act 4 opens when Thread V is bought** |

The Hard-Unmaking requirement is the important half. It makes the true ending a *story* gate, not a grind gate: an expert cannot farm their way to Act 4 inside one Iteration, and the Hard Unmaking payout (doubling from the fifth) guarantees that a struggling player still reaches Thread V by Iteration 7–8 (§9.5 sensitivity) — the clock that beats you is also the clock that carries you to the ending. Threads are bought at the Lantern Tree's root, where the Observatory's lens-housing broke (NARR-001 §5) — the tree is growing the rope you will use.

### 9.5 Worked example — a median first Chronicle

> **To re-run without Ink (CHD-15, 2026-11-18).** This table is the Rev 1.2 model and has not been re-run. Its *Ink Σ* column, the "Ink per run" assumption and the Iteration-6 "overflow" entry describe a currency that no longer exists; they are kept only as the record of the old run. The re-run must add the former-Ink Ember (Sigils, Shrine purge), the §3.7 gating backstops, and the post-tree Ember sink (§9.6) — all of whose values are owed (LR-14). No new totals are given here until it is done.

Model assumptions ✱ (the model's, not SYS-001's): a won run banks 625 Ember (mid of SYS-001 §7.2), a death run 310; Ink per run falls from 70 to 30 as stamps run out; Entropy chosen rises one step behind its unlock (§6.3), so the Ember multiplier is SYS-001 §7.3's row for the median E; runs per Iteration and the win/death mix follow §6.5; Hunger per §10.3.

| Iter | Act | Runs (won / died) | E (×Ember) | Ember this Iter | Ember Σ | Tree (Ember spent) | Ink Σ | Fragments Σ | Hunger at close | What the player is feeling |
|---:|---|---|---|---:|---:|---|---:|---:|---:|---|
| 1 | 1 | 5 (2/3) | 0–1 (×1.00) | 2,180 | 2,180 | T1 nodes across 3 branches | 380 | 3 | 3–4 | *the loop is real, and it is kind* |
| 2 | 2 | 6 (3/3) | 2 (×1.15) | 3,225 | 5,405 | first T3 nodes; first named node | 785 | 7 → Thread I (4) | 6–8 | *the game is changing under me* |
| 3 | 2 | 6 (4/2) | 3 (×1.15) | 3,590 | 8,995 | two branches at T4 | 1,130 | 13 → Thread II (Σ 10) | 9–12 | *I can lean into the warp* |
| 4 | 2 | 6 (4/2) | 4 (×1.35) | 4,210 | 13,205 | first capstones | 1,445 | 22 → Thread III (Σ 18) | 12–16 | *the Choir is people* |
| 5 | 3 | 7 (5/2) | 5 (×1.35) | 5,055 | 18,260 | **tree complete** (17,480) | 1,690 | 38 → Thread IV (Σ 28) | 15–20 | *I am the only thing that gets stronger* |
| 6 | 3→4 | 7 (5/2) | 6 (×1.60) | 5,990 | overflow (§9.6) | — | 1,900 | 52 → **Thread V** (Σ 40) | 18–24 | *it is eating the rules now — and I can unmake it* |
| 7 | 4 | Act 4 run(s) | 6–7 | — | — | — | — | — | — | *the last clean sky* |

Real time: Act 0 ≈ 0.5 h, Iterations 1–6 ≈ 2–3.5 h each, Act 4 2–4 h → **≈ 15–25 h to the true ending**, overlapping GDD-001 §2's 18–25 h (the low end is an expert's). The tree completes at the start of Act 3, which is exactly GDD-001 §9.1's "Tier 4–5 + MADNESS" for Act 3. In Rev 1.2, MADNESS's Ink nodes completed during Iteration 4–5; under CHD-15 the §3.7 tier floor makes every gated node available by Iteration 5 at the latest, so *Unravel Focus* (MADNESS-17) still arrives with Act 3 as §3.6 intends (to confirm in the re-run).

Sensitivity: an expert (6–7 wins per Iteration, E +2) completes the tree in Iteration 4 and is held at Act 4 by the Hard-Unmaking requirement of Thread V, not by Fragments — the story gate is the one doing the work. A struggling player (1–2 wins per Iteration, E0) completes the tree around Iteration 7–8 and still reaches Thread V by Iteration 7–8 (≈5 Fragments per Iteration from one T ≥ 3 win and the Hard Unmaking, 8 once the payout doubles: Σ 3, 8, 13, 18, 26, 34, 42); Act 4 arrives with a thinner tree, which is what Entropy 0 and the Coma mercy (GDD-001 §8.9) exist to cover.

### 9.6 Inflation and dead-currency checks

| Currency | Risk | Check | Valve |
|---|---|---|---|
| Ember | **dead after the tree completes** (Iteration 4–6) — a currency with nothing to buy breaks the "number goes up" reward at the run summary | §9.5: median saturation in Iteration 5 (to re-run without Ink) | **The post-tree Ember sink** (below; PM-approved, CHD-15), which replaces the Rev 1.2 overflow valve of 20 Ember → 1 Ink. Respec at 10% of banked Ember (§3.5) also draws on it. **The check must be re-run with the sink** once its prices exist: the sink is finite by design (a fixed lamp list, at most one rekindle per kit), so whether it outlasts a long Chronicle depends on the owed prices (LR-14) |
| Ink | — | **retired** (CHD-15). There is no Ink to inflate; the Codex gates instead (§3.7), and a gate cannot inflate | — |
| Fragments | dead after Thread V | by design: Fragments exist to buy the ending | after Thread V, Fragments become the Vigil Index's **Unravel** column (a visible tally the entity comments on, AUDIO-001 §4.12). No new sink is added; adding one would invent a sixth Thread |
| Glass / Charges | none | run-only | — |
| Entropy multipliers | late-game acceleration of the above | only after the tree is complete in practice (E ≥ 6 arrives in Iteration 5+) | the post-tree Ember sink absorbs it, while it lasts (see the Ember row) |

**The post-tree Ember sink: relighting the Ruins and rekindling the dead** (CHD-15; PM-approved 2026-11-18 under owner grant, cosmic horror design rev 3). Once the tree no longer needs it, Ember buys memory, never power. It adds no noun and no meter.

| Spend | What it does | Price | Rules |
|---|---|---|---|
| **Relight the Ruins** | lights one lamp or window from a **fixed, authored list** in the Ruins hub, one per spend (whether the player picks which, or the list sets the order, is owed) | one spend each, at a **rising price** (value owed) | the list and its lit state are part of the **Ruins shape** (anchored, §2), so lit lamps survive death and Hard Unmaking. Purely cosmetic: no lamp changes a stat, a node, a price or a Codex rule. How the list maps onto each §10.4 hub shape is owed (NARR-001 §5 and the Aether art chat) |
| **Rekindle a Penitent** | choose one site from the **death-site list** (§2); that site's Penitent keeps its lamp lit through Hard Unmakings, as a remembered grave | value owed | **at most one per kit** (SYS-001 rekindled Penitents row). A rekindled Penitent is a death-site Penitent that persists: same behaviour (GDD-001 §8.5; ZONES-001 §4.5), no extra power, no new behaviour. It **shares the per-sector Penitent cap** (SYS-001 death-site Penitent cap row); when more than one could claim the slot, precedence is the Coma Penitent, then a rekindled Penitent, then any other death-site Penitent (ZONES-001 §4.5). Stored in anchored state (§2) |

Both are cosmetic plus memory, so the anti-pillar holds (GDD-001 §3: no power bought outside the tree), and leftover currency becomes grief made visible. "Post-tree" is read as: both open once every Ember node is owned, the trigger the old valve had (LR-11); confirm with the PM if either should open earlier. How a rekindled Penitent counts against the per-sector cap is settled (2026-11-18, cosmic horror design call within CHD-09/CHD-15, flagged in the Phase 2 PR): it shares the cap, with the precedence above (ZONES-001 §4.5).

### 9.7 Requests opened by §8–§11

| ID | To | Request |
|---|---|---|
| **LR-09** | SYS-001 §6 | one Hourglass block: Iteration budget 120 🔒; death lump `10 + 2 × (Seam − 1)` ✱; run-won refund +15 ✱ with the 120 ceiling (closes LR-05) |
| **LR-10** | SYS-001 §7 (new rows) | the Fragments of Unraveling source table and the Thread cost/requirement table of §9.4, all ✱ |
| **LR-11** | SYS-001 §7 | ~~the Ember overflow valve, 20 : 1 into Ink~~ — **withdrawn 2026-11-18** (CHD-15): replaced by the post-tree Ember sink (§9.6), whose prices are LR-14. Still active only when every Ember node is owned |
| **LR-12** | SYS-001 §2.2 | write the ninth-sky close as **one** row: "+2 total (Hard Unmaking +1 🔒, Iteration lost +1)", matching GDD-001 §9.3 ending 1, so the two existing rows cannot be read as +3 |
| **LR-13** | SYS-001 §7.2, §7.3 | **changed 2026-11-18** (CHD-15): retire the `Codex firsts` Ink row and the Entropy Ink multiplier; no Codex entry pays any currency. Add the Ink-node Ember price (0), the three gating backstop rows (tier-1 after run 3, tier-t at the start of Iteration t, 1 oldest pending entry per death) and the respec row (10% of banked Ember) in its place |
| **LR-14** | SYS-001 §7 (and TECH-001 §11.1 as one open question) | **values owed** by CHD-15, none invented here: (1) Ember paid by SIG-S-04, SIG-S-08 (per Charge), SIG-S-18 (per reading) and SIG-W-20 (per cast, and its per-run cap); (2) the Shrine purge Ember; (3) the Ruins relight prices (the rising series) and the rekindle price; (4) the §9.5 economy re-run without Ink and the §9.6 dead-currency check with the sink; (5) the counts and durations inside four §3.7 discovery sources (LANTERN-4's dark-flight time, ORDNANCE-5's Acolyte count, ORDNANCE-9's magazine-hold time, MADNESS-18's Glimpse count) |

---

## 10. Iteration unlocks — what each Hard Unmaking adds

The loop's retention machine is the **Hard Unmaking**: the ninth sky closes, the run banks, and the world comes back *different*. Every Hard Unmaking must be a beat a player remembers and a reason to start the next Iteration immediately. Nothing below is announced by UI (GDD-001 §1 design rule); each change is discovered in the Ruins or in the next sector.

### 10.1 Iterations and Acts

| Act | Iterations | Warp ceiling (WARP-001 §1.3) | Biomes in rotation (ZONES-001 §2.2) | Entropy available (§6.3) | Eats legal (WARP-001 §3.2 earliest act) |
|---|---|---|---|---|---|
| 0 — Last Normal Day | prologue, no Iteration | T0 | Act 0 stages (not kits) | — | none |
| 1 — First Loops | 1 | T1 | Pale Marches, Ossuary Belt | 0–1, then 2–3 after the first Rite | none (Hunger accrues, nothing is taken yet) |
| 2 — The Nine Skies | 2–4 | T2–T3 | + The Litany (2), + Green Rot and the Drowned Observatory (3), + The Black (4) | 4–5 from Iteration 2 (Act 1 cleared) | H2, H4, H8 |
| 3 — Revelations | 5–7 (until Thread V) | T3–T4 | all six | 6–7 from Iteration 5 (Act 2 cleared) | + H6, H10, H12, H14, H16, H18 |
| 4 — Unraveling | opens when Thread V is bought (Iteration 6–8) | T5 | the entity's memory (Act 4 arena) | 8–9 once Act 3 is cleared; 10 after any ending 2–5 | full registry |

The Act is a Chronicle fact, not an Iteration count: a player in Iteration 9 without Thread V is still in Act 3, and the Iteration beats of §10.4 keep arriving. Act 3 is the only Act that can last more than three Iterations, and it is the one that is supposed to feel endless until you find the way out.

### 10.2 Biome rotation

Rotation follows ZONES-001 §2.2's "Iterations it appears in" column exactly; LOOP owns only the *arrival*. A biome's first sector is always Seam 1 or 2 of the first run after it unlocks ✱, so the new sky is met while the run is still forgiving, and its `cx_place_` entry stamps on that run's summary.

### 10.3 Hunger cadence

Hunger is Chronicle-long, entity-side and never shown as a number (§6.4; SYS-001 §2.2). Per Iteration it gains **+2 when the ninth sky closes** (GDD-001 §9.3 ending 1; LR-12) and **+1 per sector eaten** (a lost Waking or ten Shrines, SYS-001 §6). A median player loses one or two sectors per Iteration, so:

| End of Iteration | Hunger (median) | Eats that have happened | Next eat waits for |
|---:|---:|---|---|
| 1 | 3–4 | none (Act 1 eats nothing) | Act 2 |
| 2 | 6–8 | H2, then H4 | H8 at Hunger 8 |
| 3 | 9–12 | + H8 | Act 3 (H6, H10 are eligible but act-gated) |
| 4 | 12–16 | — | Act 3 |
| 5 | 15–20 | + H6, H10 | cadence (one eat per Seam, WARP-001 §3.1) |
| 6 | 18–24 | + H12, H14 | |
| 7 | 21–28 | + H16, H18 — registry complete | Act 4 plays at a full registry |

Act 2 takes about one rule per Iteration, Act 3 about two. Eats that are eligible by Hunger but blocked by their earliest act **queue**; when Act 3 opens, the queue fires at the normal one-eat-per-Seam cadence, never as a burst.

### 10.4 The Hard Unmaking beats

Each Hard Unmaking opens with **the Eating of a Sky** (below), plays ending 1, *Nine Hollow Skies* (§11.2), re-keyed to that Iteration, and then returns the player to a Ruins that has changed. GDD-001 §6.4 promises the hub's shape escalates ("ruins become a cathedral becomes a lattice becomes an unlit room"); the eight beats below are that promise, with one unlock, one cast moment and one Chronicle page each. NARR-001 §5 and §10 own the scene and page text.

| # | Beat | The Ruins become | Cast moment | Unlocks | Chronicle page |
|---:|---|---|---|---|---|
| 1 | **The First Dark** | the east wall is gone; through it, the Ninth Sky's scar — the reason the Ruins survive | **Brother Wick** is sitting under the Lantern Tree. He walked out of a Litany Ring; he will not say why yet | The Litany; Entropy 4–5; Ilse's marginalia begin; Thread I purchasable | `cx_chron_hu_01` — the night the Office lit the Ninth Light |
| 2 | **The Bell With No Clapper** | a nave: the rubble has stood itself up into a cathedral nobody built | Wick names the missing ninth syllable. **Sable Vane's sleeve** is seen at the Chalk Desk for the first time | Green Rot, the Drowned Observatory; Thread II; ending 2's option at the Lantern Tree (§11.3) | `cx_chron_hu_02` — the Lampkeepers' conscription |
| 3 | **The Ledger Opens** | the cathedral's floor is a map of the system with three skies inked out | the **Cabinet** on the wall changes its attract text for the first time: it shows *your* Vigil Index under a stranger's initials (§11.6) | The Black; Thread III | `cx_chron_hu_03` — the cabinet halls |
| 4 | **The Cathedral Learns Your Name** | the nave's windows show your past deaths as stained glass (from `cx_vigil_`); one room is gone — **the Wrong Ruins** (below) | Ilse speaks aloud for the first time instead of in the margins | **Act 3**; the entity patrols the macro map (GDD-001 §9.1); Entropy 6–7; Thread IV | `cx_chron_hu_04` — who chose the failure (the Choir's guilty list is wrong) |
| 5 | **Lattice** | the walls are gone; the Ruins hang in a lattice of chalk lines over the dark | Sable Vane offers the **Pact of Ascension** for the first time, if you have ever been Hollowed (§11.4) | **Thread V**; **the Ninth Gate** appears at the Tree's root and opens when Thread V is bought; ending 3's path | `cx_chron_hu_05` — Theodora Lune's resignation letter (redacted) |
| 6 | **The Unlit Room** | one room, one lamp: yours. Everything else is the Archive and the Tree | Wick asks you to put the lamp out (ending 2, if not taken) — or thanks you for not doing it | nothing new to buy: the Ruins are now only what Act 4 needs. If the Gate is still shut, the doubled Hard Unmaking payout (§9.4, from the fifth) is already carrying you there | `cx_chron_hu_06` — the star did not go out; it did not finish |
| 7 | **The Choir Sings Your Name** | the unlit room fills with the chant, from inside the walls | the Penitent drifts through the Ruins — the first time anything from the skies has entered the anchored pocket | nothing new: Act 4 should already be open; if not, the doubled Hard Unmaking payout (§9.4) is carrying you there | `cx_chron_hu_07` — what the Penitents are (NARR-001 §2) |
| 8 | **The Ninth Sky Remembers** | every earlier shape of the Ruins, cycling once per visit | all cast together for one scene | the last Chronicle page | `cx_chron_hu_08` — the chronicle's last line before the ending |
| 9+ | **re-keyed** | the Ruins hold the shape of the Iteration you are in | one rotating cast line | nothing new; ending 1 re-keys to the sky that closed last | none (8 pages total) |

The design guarantee: the first six Hard Unmakings each unlock something *playable* (biome, Act, Thread, ending path) and something *readable* (a cast moment and a page). A player can predict that a Hard Unmaking brings change; they can never predict which change.

**The Eating of a Sky** (CHD-08; PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, design §1.3). Every ninth-sky close, and so every Hard Unmaking after Act 0, is a **playable sector, not a cutscene**. The sector the player is in when the ninth sky closes stays playable while the entity eats the sky in **its order of beauty**, from the most-lit, most-alive element downward: the biome's Presence first (ZONES-001 §2, Presences (CHD-03)), then the crystal sphere, the fog's colour, the stars, the Choir's lamps, the geodes. True black arrives last, at the Vigil's own lantern radius: **the player's own light is always the last thing eaten.** The player cannot stop it; they can keep their lantern lit to the end. No sting: the music loses its stems one by one (AUDIO-001 owns the cue). The **first Unmaking cinematic** (GDD-001 §6.1) stays as Act 0's version; from the first Hard Unmaking on, this playable eating replaces it. Loop rules it keeps: the run has already banked at `sky_9_closing` (§11.2), so nothing in the Eating costs currency, and the Hourglass Clock is spent (§6.5). Owed elsewhere: what plays if the ninth sky closes while the player is in the Ruins rather than a sector; whether anything in the Eating can hurt the Vigil; its length and pacing (GDD-001, ZONES-001, AUDIO-001).

**The Wrong Ruins** (CHD-08; Act 3, design §1.3). From the Hard Unmaking that opens Act 3 (beat 4), **one Ruins room is missing**: its doorway opens onto Aether with a gap in it, the cast never mention it, and the Lantern Tree's light no longer reaches that wall. The room **comes back only after ending 4** (§11.5). **Until ending 4, ending 3 keeps it gone** (§11.4). **Ending 4 always restores it, even if ending 3 was seen earlier**, because ending 4 unwrites the loss (2026-11-18, cosmic horror design call within CHD-08, flagged in the Phase 2 PR; this replaces the earlier reading "ending 3 wins"). The missing room's state is part of the Ruins shape (anchored, §2) and is written as save flags (§11.7). Which room is owed (NARR-001 §5); it cannot be a room a system needs — the Lantern Tree, the Chalk Desk, the Archive or the Cabinet.

---

## 11. Endings

GDD-001 §9.3 promises five endings, all reachable in one Chronicle. Triggers below are canonical (the canon brief of 2026-11-17); NARR-001 §9 owns each ending's fiction, AUDIO-001 its sound, and this section owns the state machines, the flags and how a player finds each one.

### 11.1 Overview

| # | Ending | Trigger (summary) | Ends the Chronicle? | After the credits |
|---|---|---|---|---|
| 1 | **Nine Hollow Skies** | the ninth sky closes | no — it is the Hard Unmaking | the next Iteration begins (§10.4) |
| 2 | **The Lantern Extinguished** | Iteration 3+, at the Lantern Tree: *Let it go out*, confirmed twice | no | next launch offers *Light it again*; the save resumes untouched |
| 3 | **The Choir Crowned** | Act 3+: sign the Pact of Ascension, reach the Waking Hollowed, let the Sepulchre complete with the Vigil inside the Litany Ring | no | the save resumes at the Ruins in the same Iteration; the Chronicle notes a new Waking Dark was crowned |
| 4 | **The Unraveling** (true) | all five Threads → Act 4 → three threads latched in the final encounter (SYS-001 §2 phase 6) | it ends the *story*; the save continues as *the last clean sky* (§11.5) | Entropy 8–10, all Acts replayable from the Ninth Gate |
| 5 | **The Pretence Kept** (secret) | finish Act 0 without ever using Surgelight or Ward Pulse | no | the Archivist variant is unlocked (§8.4, §11.6) |

All five are non-destructive: **no ending ever deletes, resets or locks a save.** That is what lets endings 2 and 3 be what they are: a player who chooses to stop, or to join the Choir, has not lost forty hours.

### 11.2 Ending 1 — Nine Hollow Skies

| State | Enters when | Does | Leaves to |
|---|---|---|---|
| `sky_9_closing` | the Hourglass Clock reaches zero (§6.5) | the run in progress banks (§1); the last sky's chant cuts to silence | `eating_of_a_sky` |
| `eating_of_a_sky` | always, after closing (CHD-08) | the sector stays playable while the sky is eaten in its order of beauty, the player's own light last (§10.4) | `nine_hollow_skies` when the player's light has been eaten |
| `nine_hollow_skies` | always, after the Eating | the ending sequence, re-keyed to this Iteration's last sky, its Hollow sectors and the entity's top-two telemetry keys (SYS-001 §8 composition; NARR-001 §7) | `hard_unmaking` |
| `hard_unmaking` | always | Hunger +2 (§10.3), Fragments +3 (§9.4), Iteration state consumed (§2), §10.4 beat | Ruins, Iteration +1 |

The ending sequence is skippable from its second showing; the first is unskippable once, like the first Unmaking cinematic (GDD-001 §6.1). The Eating is play, not a sequence, so the skip rule does not reach it (whether it may be shortened on repeat is owed, §10.4). It is the only ending the player cannot avoid and must never feel like a game-over screen: the first frame after it is always the changed Ruins.

### 11.3 Ending 2 — The Lantern Extinguished

| State | Enters when | Does | Leaves to |
|---|---|---|---|
| `offer_hidden` | default | — | `offer_visible` after Hard Unmaking 2 (Iteration 3+) |
| `offer_visible` | at the Lantern Tree, a fourth option under *Grow / Respec / Threads*: **Let it go out** | nothing until chosen | `confirm_1` |
| `confirm_1`, `confirm_2` | two confirmations, the second in the player's own Lampkeeper voice (NARR-001 §7), default focus on *Keep it lit* (UI-001 §3 safe default) | — | `eulogy`, or back to `offer_visible` |
| `eulogy` | confirmed | 3 minutes, **no input required**: the observatory idles; the skies you saved and lost are named one by one; the Choir sings far away; the Cabinet plays its attract loop to an empty hall. Any input after 3 min ends it; no input ends it on its own | `credits_2` → title |
| `relight_offer` | next launch | the title screen's primary action reads **Light it again**, which resumes the save exactly where it was | normal play |

Discoverability: Brother Wick mentions it once, after an Iteration in which the player died four or more times ✱ ("Some keepers let it go out. Nobody here would blame you."). It is never on a menu before Iteration 3, and never offered in the middle of a good Iteration. This is the divisive, memorable clip GDD-001 §9.3 wants: a game that offers to let you stop, and means it.

### 11.4 Ending 3 — The Choir Crowned

| State | Enters when | Does | Leaves to |
|---|---|---|---|
| `asc_locked` | default | — | `asc_offered` when **Act 3** is open **and** the player has been Hollowed (Composure 0, SYS-001 §1.5) in at least one run |
| `asc_offered` | the next visit to the Chalk Desk | Sable Vane writes **PACT-ASC, the Pact of Ascension** — outside the 24 (§7; the pool count is unchanged), offered only by Sable, never drawn | `asc_signed` if chosen as the run's Pact |
| `asc_signed` | run start | grant: the Choir will not fire on you while you are Hollowed. Price: Composure cannot rise above 0 once it reaches 0, and the run's Waking cannot be unmade — Unravel hits pass through the entity | `asc_waking` if you reach Seam 5 Hollowed; `asc_void` if Composure is above 0 at Seam 5, or you land an Unravel hit |
| `asc_waking` | Seam 5, Hollowed | the Litany Ring opens a ninth node for you — the missing syllable (NARR-001 §1.5) | `crowned` if the Sepulchre completes (20/20) with the Vigil inside the Ring; `asc_void` if you leave the Ring |
| `crowned` | completion | the ending: you become the next Waking Dark; the Wrong Ruins room stays gone until ending 4 unwrites the loss (§10.4, `wrong_ruins_state = lost`) | `credits_3` → Ruins, same Iteration |
| `asc_void` | any break | the Pact is void like any other (§7.1), the Codex strikes it, the run continues normally | `asc_offered` next run |

Discoverability: being Hollowed is common in Act 2–3, so most players see Sable's offer naturally; the Pact's printed price is honest (§7.1 "the price is printed"). The Choir mode NG+ is post-launch scope (GDD-001 §9.3); at 1.0 the ending sets `choir_crowned_seen` and nothing else.

### 11.5 Ending 4 — The Unraveling (true)

| State | Enters when | Does | Leaves to |
|---|---|---|---|
| `threads_n` (0–4) | Threads bought (§9.4) | each Thread hangs visibly from the Lantern Tree's root | `gate_open` at Thread V |
| `gate_open` | Thread V bought | **the Ninth Gate** at the Tree's root opens; the next run is an Act 4 run (inside the entity's memory, T5, GDD-001 §9.1) | `act4_run` |
| `act4_run` | run start | a full run at T5 with the Unmaking Rehearsal (WARP-001 §6.2) and the final encounter; pre-attached threads per WARP-001 §6.1 D-03 | `unraveled` on three threads latched (SYS-001 §2 phase 6); on death, back to `gate_open` (the Gate stays open; Act 4 runs can be retried for the rest of the Chronicle) |
| `unraveled` | win | the credits peel the arcade shell away to reveal the last clean sky (GDD-001 §9.3) | `clean_sky` |
| `clean_sky` | always | the save continues; the Ruins are lit, and the Wrong Ruins room comes back, even if ending 3 took it earlier, because ending 4 unwrites the loss (§10.4); Entropy 8–10 opens; every Act is replayable from the Ninth Gate; the Hourglass Clock stops (there is nothing left to eat) and resumes only for Entropy runs ✱ | free play |

Discoverability: Threads are visible on the Tree from the first Hard Unmaking, so the true ending is the one goal the player can always see. The game never says "true ending"; it shows a rope.

### 11.6 Ending 5 — The Pretence Kept (secret)

| State | Enters when | Does | Leaves to |
|---|---|---|---|
| `act0_clean` | starting Act 0 | tracked flag `act0_clean_hands = true` | `act0_dirty` the first time Surgelight or Ward Pulse is pressed in Act 0 |
| `act0_dirty` | any use | nothing visible | — |
| `honour_roll_entry` | any Act 0 clear (first play or a Cabinet replay) with a score on the table | the three-letter initials entry screen (UI-001 §1, Cabinet face ART-001 §11); the player's initials are stored as `honour_roll_initials` in the profile and appear in `cx_vigil_honour_roll` | back to the flow above |
| `pretence_kept` | A0-5 cleared while `act0_clean_hands` (A0-3 before the five-stage shift) | after the last credits roll, the **Cabinet's marquee** shows Theodora Lune's message (NARR-001 §9.5), then the Cabinet's last screen *THAT WAS A PRETENCE.* (shown on this path only), then the wordless Decay and the tear (GDD-001 §6.1). On a normal clear the line is never shown (reveal decay, owner direction 2026-11-19; PROPOSED until TECH-001 Q-T180–Q-T185 are ruled) | `archivist_unlocked` |
| `archivist_unlocked` | always | Ilse Marrow completes the record: the Archivist variant of every `cx_choir_` entry (§8.4), plus `cx_chron_end_05` | normal play |

Act 0 is replayable at any time from **the Cabinet in the Ruins** (*Insert credit*): the same authored stages (five since the shift, GDD-001 §6.1), with the cabinet costume, as a self-contained arcade game. A clean-hands run there counts. That replay path is the whole secret: a player who has learned that the Cabinet is playable, and that the tutorial is hiding something, is a player who tells someone.

Word of mouth, by design: the game gives **exactly one** in-world hint and never a direct one. From Hard Unmaking 3, the Cabinet's high-score table lists the initials **T.L.** with the note `0 WARD 0 SURGE` beside the top score ✱. No character mentions it, no Codex entry explains it, no achievement description names the condition (§11.9 lists it as hidden). It must spread from players to players.

### 11.7 Save flags (invariant IDs, profile slot)

| Flag | Type | Set by |
|---|---|---|
| `hard_unmakings` | int | §11.2 |
| `end_01_seen_count` | int | §11.2 |
| `end_02_seen`, `relight_pending` | bool, bool | §11.3 (`relight_pending` clears on resume) |
| `asc_state` | enum id: `locked`, `offered`, `seen` | §11.4 |
| `end_03_seen` | bool | §11.4 |
| `threads_owned` | int 0–5 | §9.4 |
| `ninth_gate_open`, `end_04_seen`, `clean_sky` | bool | §11.5 |
| `act0_clean_hands` | bool (Act 0 progress; reset at each Act 0 start) | §11.6 |
| `end_05_seen`, `archivist_unlocked` | bool | §11.6 |
| `was_hollowed_ever` | bool | SYS-001 §1.5 band 0, any run |
| `wrong_ruins_state` | enum id: `whole`, `missing`, `restored`, `lost` | §10.4 the Wrong Ruins: `missing` at the Hard Unmaking that opens Act 3; `lost` on ending 3 (§11.4); `restored` on ending 4 (§11.5), from either `missing` or `lost` (ending 4 unwrites the loss). Only ending 4 leaves `lost` |
| `ruins_lamps_lit` | list of lamp ids | §9.6 relighting the Ruins (part of the Ruins shape) |
| `rekindled_sites` | list of (kit id, death-site index), at most one per kit | §9.6 rekindling a Penitent; the death-site list itself is anchored state (§2) |

All flags are written only at the save cadence of §2 (never mid-run, SYS-001 §8). Endings that fire mid-run (3, 4) write their flag at the run's end, which is the same boundary.

### 11.8 Discoverability without a wiki

| Ending | How a player finds it | Hint channel |
|---|---|---|
| 1 | cannot be missed | the Hourglass Clock (two redundant channels, WARP-001 §4.6) |
| 2 | Wick's line after a hard Iteration; the option at the Tree | a character, once |
| 3 | Sable's offer after being Hollowed in Act 3 | the Chalk Desk, with the price printed |
| 4 | the Threads hang on the Tree from Iteration 2 | the hub itself |
| 5 | **not findable from inside the game alone**; one cryptic high-score line | other players |

### 11.9 Steam achievements (30, GDD-001 §2)

IDs are invariant; display names live in `locale/` (L10N-001). "Hidden" achievements show no description until earned.

| ID | Earned for | Hidden |
|---|---|---|
| `ach_first_vigil` | clear A0-1 | |
| `ach_pretence` | witness the Pretence: the Decay and the tear at the end of A0-5 (was: see "THAT WAS A PRETENCE" at A0-3; the line is no longer on screen on a normal clear; id unchanged; reveal decay, owner direction 2026-11-19; PROPOSED until TECH-001 Q-T180–Q-T185 are ruled) | |
| `ach_clean_hands` | ending 5 — The Pretence Kept | **yes** |
| `ach_first_dark` | the first Hard Unmaking | |
| `ach_four_darks` | four Hard Unmakings | |
| `ach_extinguished` | ending 2 | yes |
| `ach_crowned` | ending 3 | yes |
| `ach_unraveled` | ending 4 | |
| `ach_all_endings` | all five endings | |
| `ach_first_capstone` | buy any tier-5 node | |
| `ach_full_branch` | own all 18 nodes of one branch | |
| `ach_whole_tree` | own all 90 nodes | |
| `ach_first_thread` | buy Thread I | |
| `ach_archive_opens` | Codex 25 % | |
| `ach_annotated_choir` | complete `cx_choir_` | |
| `ach_record_complete` | Codex 100 % | |
| `ach_first_pact` | finish a run under a Pact | |
| `ach_bought_back` | restore an eaten rule with a Pact | |
| `ach_twelve_pacts` | finish runs under 12 different Pacts | |
| `ach_stagger` | stagger an Awakening (3 hits in the 3 s window, GDD-001 §8.4) | |
| `ach_thirteen_bells` | unmake a complete entity with all 13 hits from one magazine carried into Seam 5 | |
| `ach_held_breath` | win a run without lighting the lantern after Seam 1 | |
| `ach_rite_all` | clear all five Rite bosses | |
| `ach_heralds_all` | defeat all six named Heralds | |
| `ach_entropy_4` | win a run at Entropy 4 | |
| `ach_entropy_8` | win a run at Entropy 8 | |
| `ach_entropy_10` | win a run at Entropy 10 | |
| `ach_unmaking_seen` | play a run at Warp T5 | |
| `ach_grief_ledger` | finish a run in which H14 took a Sigil | yes |
| `ach_vigil_index` | reach a Vigil Index score target ✱ (set by SYS-001 §7.1 tuning) | |

Twenty-six are visible goals and four are hidden. Every ending, every Act and every system layer (tree, Codex, Pacts, Entropy, Rites, Heralds, warp) has at least one; none requires a daily, a second save or online play.

---

## 12. Content cost

Counts are the 1.0 plan. Cost tiers: **S** = data + existing kit art/one line; **M** = new modular parts or a short authored scene; **L** = new encounter, sequence or bespoke art. Art leans on the modular kit (GDD-001 §16 R-03: the kit covers ~80 % of art).

| Content | Count | Art | Audio | Code | Notes |
|---|---:|---|---|---|---|
| Lantern Tree nodes | 90 | S each (node icon on the shared node frame; Sigil art reused per R-03) | S (shared purchase cue; capstones get AUDIO-001 §6.7 stingers ×10) | S data; ~30 rules-bending nodes are M code | §3 |
| Run Sigils | 120 | S (icons reuse Tree node art) | S | S data; 36 rules-bending are M | §4 |
| Rare boundary Sigils (former Relics) | 18 | M (physical objects on the ground) | S | M each (all rules-bending) | §5 |
| The Eating of a Sky; the Wrong Ruins; the Ruins relight list | 1 each | owed (PROD-001) | owed | owed | §10.4, §9.6 (CHD-08, CHD-15) |
| Pacts | 24 + PACT-ASC | S (chalk text) | S | M (8 restore Pacts touch WARP rules) | §7, §11.4 |
| Codex entries | 144 (§8.2, recounted 2026-11-18) + marginalia | S (shared page frame; illustrations reuse sprites) | S (E08 stamp) | S data | §8; prose is NARR-001's largest single cost |
| Hard Unmaking beats | 8 | L (Ruins hub variants ×4 shapes) | M | M | §10.4 |
| Endings | 5 | L (4 sequences; ending 1 re-keyed) | L | M | §11 |
| Threads + Ninth Gate | 5 + 1 | M | S | S | §9.4 |
| Act 4 run | 1 | L | L | L | GDD-001 §9.1 |
| Achievements | 30 | S (icons) | — | S | §11.9 |
| Entity / cast lines this doc needs | 18 eat lines + H14 Chalk Desk line + ending lines + 8 beat scenes | — | M (VO placeholder first) | S | NARR-001 §7, AUDIO-001 |

**Cut order** (continues GDD-001 §16 R-03's "Act 4 variants → 2 biomes → 6 elites"; cut from the top):
1. Hard Unmaking beats 7–8 → collapse into the re-keyed beat (keeps 6 authored beats).
2. Marginalia budget → 1 note per entry total.
3. Codex completion flowering (75 %) → cut; milestones become 25 / 50 / 100.
4. Ending 2's eulogy → 60 s instead of 3 min (the ending survives; its length is the cost).
5. Achievement count → 24 (drop the six skill-flex ones last added).
6. **Never cut:** ending 5 (the cheapest ending and the best word-of-mouth asset in the game), the struck/restored rule entries (they are the warp's honesty), the Thread rope on the Tree (the only always-visible goal).

---

## 13. Coverage — GDD-001 claims and where they live

| GDD-001 claim | Lives in |
|---|---|
| §6.1 Act 0, three authored levels, credits, the Pretence | ZONES-001 (not kits); §11.6 (replay at the Cabinet, ending 5) |
| §6.2 Nine Hollow Skies, Hourglass Clock 120 loop-minutes, deaths spend 10–18 min, wins buy time | §6.5 (per-Iteration ruling), §9.7 LR-09 |
| §6.2 Hard Unmaking keeps the tree, changes the map, raises Hunger | §2, §10.3, §10.4, §11.2 |
| §6.2 anchored pocket stated diegetically once | §2; NARR-001 §5 |
| §6.3 run = 5 Seams, gate at Seam 3, Waking at Seam 5 | §6.1 |
| §6.3 seeded runs, daily/weekly/cursed codes | §6.2 (daily at the first free update, ruling R-16) |
| §6.3 1-of-3 Run Sigils, ~120 pool | §4 |
| §6.3 diegetic cause-of-death, the entity remembers your tool | §8.2 `cx_vigil_`; SYS-001 §2.2, §8; NARR-001 §7 |
| §6.4 Ruins, Lantern Tree, Codex, Chalk Desk one Pact per run | §3, §7, §8 |
| §6.4 escalation contract: the hub changes shape each Iteration | §10.4 |
| §7 90 nodes + 24 Pacts + 18 Relics | §3, §7, §5 (the 18 Relics are rare Run Sigils since CHD-14) |
| §7.1 four currencies, sources and persistence | §9.1 |
| §7.2 five branches, named nodes | §3.2, §3.4 |
| §7.3 legible nodes, ~30 % rules-bending, purchase not roll, reroll, respec (10 % of banked Ember since CHD-15) | §3.1, §3.5, §4.1 |
| §7.4 Entropy 0–10 unlocked by progression | §6.3, §10.1 |
| §7.4 Hunger, one eaten rule per two levels | §6.4, §10.3; WARP-001 §3.2 |
| §8.9 Codex reading is rewarded (since CHD-15: a stamp gates a node instead of paying Ink) | §8.1, §3.7 |
| §8.9 Coma mercy | SYS-001 §8; §9.5 sensitivity |
| §9.1 act map and lengths | §10.1; §9.5 (17–26 h to the true ending) |
| §9.2 five Rite bosses | SYS-001 §5.1; §8.2 `cx_choir_` |
| §9.3 five endings, all reachable | §11 |
| §9.3 ending 3 unlocks Choir mode (post-launch) | §11.4 (flag only at 1.0) |
| §9.4 score → Vigil Index | SYS-001 §7.1; §9.6 Fragments tally |
| §2 30 Steam achievements | §11.9 |
| §2 iteration = 4–7 runs / 2–3 h; first true ending 18–25 h | §6.5, §9.5 |

---

## 14. Open questions (max 8, each with a recommendation)

| # | Question | Recommendation |
|---|---|---|
| Q-01 | GDD-001 §6.2 says "the next sky goes dark, the run ends" each time the clock hits zero. §6.5 now reads it as: eight intermediate darkenings are in-run events; only the ninth ends the run. | Footnote GDD-001 §6.2 to match §6.5. Owner: GDD. |
| Q-02 | Are the Fragment and Thread numbers in §9.4 right? They are tuned to put Thread V in Iteration 6–8 for a median player. | Adopt as ✱ rows in SYS-001 (LR-10); re-tune from the slice's telemetry on wins at T ≥ 3, the one input the model is least sure of. |
| Q-03 | (Rev 1.3; the old Q-03 on the 20 : 1 Ember → Ink rate closed with Ink, CHD-15.) CHD-15 ruled that SIG-S-14 *Ink Eater* gets a new effect but did not name it, and left SIG-M-04 *Nightglass Mind* with no target. Are §4.2's proposals right: SIG-S-14 lets banked Ember pay this run's rerolls; SIG-M-04 lifts the per-summary stamp cap for the run? | **Closed 2026-11-18:** both adopted as proposed (§4.2), a cosmic horror design call within CHD-15, flagged in the Phase 2 PR. Neither adds a number, both stay inside the §9.1 law, and both point at the Codex as the new gate. The name *Ink Eater* stays for now; NARR-001 may rename it later. |
| Q-04 | *Annotated Choir* (§8.5) is a legibility aid earned from the Codex. Is it a power gap in dailies? | Allow it: dailies already differ by tree. Telemetry check: if daily scores split by the flag, move it into Steady Ledger as a universal option. |
| Q-05 | After ending 3, should the next Iteration change (a crowned Waking Dark in the macro map)? | Not at 1.0 (scope). Write the flag now; the post-launch Choir mode reads it. |
| Q-06 | Ending 2 is reversible; should `ach_extinguished` still fire? | Yes. The achievement records the choice, not a loss. |
| Q-07 | The Hunger cadence (§10.3) puts six eats into Act 3. Too dense? | Watch the slice for queue bursts; the lever is SYS-001 §2.2's per-sector source, never a new rule. |
| Q-08 | Should an expert be able to skip the Hard-Unmaking requirement on Threads? | No. The requirement is the story gate that keeps Act 4 after the Chronicle's reveals (§9.4). Experts get Entropy instead. |
