# DARKSTAR — Roguelike Loop, Run Sigils, Pacts, Relics and the Lantern Tree

**Doc ID:** LOOP-001 · **Version:** 1.1 · **Date:** 2026-11-17 · **Owner:** Design (systems / progression) · **Status:** §0–§7 authored · §8–§14 owed (Codex, economy flow, Iteration unlocks, endings, content cost, coverage, open questions)

Rev 1.1 (2026-11-17): §5 Relics, §6 run shape and the two escalators, §7 Pacts written out in full; the §4.1 Run-Sigil pick count corrected to SYS-001 §7.2's three; HULL-17's "Anchor ring" renamed to the **Anchor field** to match SYS-001 §1.1 and GDD-001 D-11. The 90 / 24 / 18 counts GDD-001 §7 promises are now all on disk. Requests **LR-01…LR-08** are open against SYS-001 and GDD-001 and are listed in §5.5, §6.5 and §7.5.

This is the progression contract. GDD-001 §6–§7 promises a run structure, a between-run tree, **90 nodes + 24 Pacts + 18 Relics** and "~120 Run Sigil pool entries". All of it is here, written out. Numbers do not live in this doc: every stat, cost floor, yield and multiplier is in **SYS-001** (`SYSTEMS_BIBLE_STATS.md`), and where this doc needs a number it points at a SYS-001 row instead of inventing one. If a number here and a number in SYS-001 disagree, SYS-001 wins and this doc is a bug.

## 0. How to read this doc

| If you are… | Read | Then |
|---|---|---|
| new to the project | GDD-001 §1–§3, §6, then §1–§2 here | §3 (Lantern Tree), §7 (Pacts) |
| designing or tuning a node | §3 conventions, then SYS-001 §1, §7 | the branch table for your node |
| building the save/persistence layer | §2 save layers, §9 economy flow | SYS-001 §8 invariants |
| authoring content (kits, rites) | §6.1 run anatomy, §10 iteration unlocks | ZONES-001 |
| writing fiction or UI copy | §11 endings, §8 Codex | NARR-001 |
| planning the build | §12 content cost, §13 coverage | PROD-001 |

Cross-doc IDs used here: GDD-001, SYS-001, ZONES-001, WARP-001, NARR-001, AUDIO-001, ART-001, ART-002, ASSET-003, TECH-001, PROD-001, MARKET-001.

Vocabulary is GDD-001 §19 only. The 1983 arcade original is never named in this doc (RES-001 §5).

## 1. The loop in one page

Four nested layers, from tightest to loosest. A player is always inside exactly one of the outer three and always inside the innermost.

| Layer | Length | What the player is doing | What persists when it ends | Ends when |
|---|---|---|---|---|
| **Seam** | 4–6 min (SYS-001 §6) | mine, shoot, run one encounter kit | nothing except the run's state | kit cleared or the Vigil is destroyed |
| **Run** (5 Seams) | 25–35 min | build a Vigil from Run Sigils, reach the Waking at Seam 5, bank | Ember, Ink, Fragments, Codex, tree | Seam 5 ends, or death, or the clock |
| **Iteration** | ~120 loop-minutes (GDD-001 §6.2) | spend the Hourglass Clock across runs and the Ruins; the Nine Skies go dark one by one | Lantern Tree, Ruins, Codex (anchored) | the ninth sky goes dark → **Hard Unmaking** |
| **Chronicle** | 20–40 h | the whole saved game: acts, endings, Vigil Index, Hunger | everything except the run | credits, or you stop playing |

**Forward progress is a law, not a feature.** Every terminal state produces banked currency, a Codex entry and an iteration modifier. There is no state in this game in which the player loses the run and also gains nothing. GDD-001 §18 locks it; §8.9 implements it; SYS-001 §7.4 forbids Hunger from reducing player currency.

## 2. Save layers and the three persistence classes

| Class | Contents | Survives death | Survives Hard Unmaking | Survives "New Iteration" from the menu | Where in TECH-001 |
|---|---|---|---|---|---|
| **Run state** | Seam index, seed, Run Sigils, Relics, active Pact, Charges, Composure, in-run Ember/Ink | no | no | no | run slot, written between Seams only |
| **Iteration state** | Hourglass Clock, sky count, Hunger, sector corruption map, Hollow sector list, entity memory (telemetry counters) | yes | **consumed** by Hard Unmaking, which raises Hunger and rewrites the map | reset deliberately | iteration slot |
| **Anchored state** | Lantern Tree purchases, banked Ember/Ink/Fragments, Codex, Ruins shape, endings seen, Vigil Index bests, accessibility settings | yes | yes | yes | profile slot |

The diegetic reason is GDD-001 §6.2: the Lantern Tree, the Ruins and the Codex sit in a pocket the loop cannot touch. It is stated once, in the first Ruins scene, and never in a menu.

**Save cadence is a SYS-001 §8 invariant: never mid-run.** A run writes at Seam boundaries only, so a crash costs at most one Seam.

## 3. The Lantern Tree — 90 nodes

The tree grows in the Ruins (GDD-001 §6.4). Five branches, 18 nodes each, tiers 1–5, purchased with Ember or Unwritten Ink. Nothing is rolled. Capstones are named in GDD-001 §7.2 and are honoured below.

### 3.1 Node conventions

| Convention | Rule |
|---|---|
| ID | `<BRANCH>-<1..18>` where BRANCH ∈ LANTERN, HULL, ORDNANCE, WARD, MADNESS |
| Tier | nodes 1–4 = T1, 5–8 = T2, 9–12 = T3, 13–16 = T4, 17–18 = T5 (capstones) |
| Cost | Ember for numeric nodes; Ink for rule nodes; both for a minority of numeric rule-adjacent nodes. Cost floors and the exact split are in the tables below and roll up in §3.4; the respec tax is GDD-001 §7.3 (10% of banked Ink) |
| Requires | at least one node of a lower tier in the same branch; capstones require both T4 nodes of the branch. Cross-branch prerequisites are used **exactly twice in 90 nodes**, both in MADNESS, and both exist to make leaning into warp feel like a commitment |
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

[^tier]: **Tier gate.** A tier-2 node needs any 2 nodes in tier 1 of the same branch; tier 3 needs any 2 in tier 2; and so on. The `Requires` column lists only *hard* named prerequisites on top of that gate. Tier 1 = nodes 1–4, tier 2 = 5–8, tier 3 = 9–12, tier 4 = 13–16, tier 5 (capstones) = 17–18.

[^speed]: **Speed budget.** SYS-001 §1.1 locks `max_speed` 340 px/s as the base and `Full reversal` 0.28 s as design identity; speed nodes are capped at **+12% total across the whole tree** (SYS-001 §1.1). LANTERN-10 (+6%) and LANTERN-13 (+6%) are the entire budget — no other node in this file adds speed, drift or brake in a way that raises it. Both scale `accel` and `brake` by the same percentage so the 0.28 s reversal is unchanged. `accel` itself is 🔒 GDD and is never a node target.

[^gap]: **Rows SYS-001 still owes us** (all `✱`, first-pass, none contradicting an existing row): Ward Pulse base cooldown (proposed 8 s) and base radius (proposed 180 px) plus cooldown/radius ceilings; damage-vs-Choir scaling for Blessed Fracture (GDD-001 §7.2 states +30% per Warp Tier); Shroud-clear-per-second from lamplight; lantern toggle fade time; a shard-yield ceiling now that three nodes raise yield; a drift floor (1.0 body-lengths) and a brake ceiling; a `Surgelight` cooldown floor (0.55 s); a Communion Composure-per-second cost. Each flagged node says which row it needs.

#### LANTERN (branch L) — light, mining, movement

| ID | Node | Tier | Cost | Currency | Effect (numbers reference SYS-001) | Rules-bending? | Requires | Visible in play |
|---|---|---|---:|---|---|---|---|---|
| LANTERN-1 | Surgelight Charges | 1 | 40 | Ember | SYS-001 §1.1 `Surgelight impulse` becomes a stored charge: 2 held, spent at the row's 1.6 s cooldown. | yes | — | Two wick pips on the HUD; the stern brass vent stands open with a second flare |
| LANTERN-2 | Wide Bellows | 1 | 40 | Ember | SYS-001 §1.1 `Surgelight Shroud burn` radius +25%. | no | — | Each dash opens a shoulder-wide smoking gap in Shroud |
| LANTERN-3 | Full Wick | 1 | 40 | Ember | SYS-001 §1.2 `Lantern radius` 260 → 340 px (that row's stated ceiling). | no | — | The amber pool spans a whole Encounter Kit; rim geodes pop into view |
| LANTERN-4 | Wick Ledger | 1 | 15 | Unwritten Ink | The Ledger Compass draws your true light ring and marks the nearest unlit corridor (SYS-001 §6 solvability lint). Does not replace the Steady Ledger toggle (GDD-001 §10). | no | — | An honest amber ring on the compass strip with one chalk tick |
| LANTERN-5 | Dark Lantern | 2 | 120 | Ember | SYS-001 §1.2: `Mining speed, lantern down` 65% → 85% and `Choir detection, lantern down` −60% → −75%; mining dark becomes legal below T3 (row 🔒). | yes | LANTERN-3 | A shuttered cowl module on the bow; your flame shrinks to a coin |
| LANTERN-6 | Long Burn | 2 | 120 | Ember | SYS-001 §1.1 `Surgelight impulse` +20% (⚙). | no | LANTERN-1 | One dash clears a whole kit corridor in a stretched amber smear |
| LANTERN-7 | Brass Bellows | 2 | 120 | Ember | SYS-001 §1.1 `Surgelight` cooldown −25%. | no | LANTERN-1 | Three boosts inside one Acolyte duel |
| LANTERN-8 | Spare Wick | 2 | 120 | Ember | Toggling the lantern down fades the pool over 2 s instead of cutting it (new SYS-001 row `✱`). | no | LANTERN-3 | The light lingers like an afterimage; Choir heads turn a beat late |
| LANTERN-9 | Long Glide | 3 | 260 | Ember | SYS-001 §1.1 `drag` −20% (⚙); `max_speed` and `Full reversal` untouched [^speed]. | no | — | The skiff slides two body-lengths past the geode before settling |
| LANTERN-10 | Keel Light | 3 | 45 | Unwritten Ink | +6% on SYS-001 §1.1 `max_speed`, with `accel` and `brake` scaled by the same 6% so `Full reversal` stays 0.28 s 🔒. Half of the +12% budget [^speed]. | no | LANTERN-9 | The bow module leans forward; your wake thread lengthens |
| LANTERN-11 | Blackout Dash | 3 | 45 | Unwritten Ink | A Surgelight that ends inside a Choir sweep puts your lantern out at the far end for 2 s and the Choir loses acquisition — you are buying back against SYS-001 §1.2 `Acquisition loss timer`. | yes | LANTERN-1, LANTERN-5 | You arrive dark, the flame gutters, Choir heads swing through where you were |
| LANTERN-12 | Hot Lantern | 3 | 260 | Ember | Your light pool eats Shroud at 1 HP / 6 s (SYS-001 §9 `Shroud` HP 3; row needed [^gap]). | no | LANTERN-3 | Shroud curls back from your lamplight, steaming at the rim |
| LANTERN-13 | Keel Deep | 4 | 520 | Ember | +6% on SYS-001 §1.1 `max_speed`, same scaling rule as LANTERN-10; with it this node is the whole +12% budget [^speed]. | no | LANTERN-10 | The stern grows a second vent; a chase now closes visibly slower |
| LANTERN-14 | Phosphor Trail | 4 | 520 | Ember | Each Surgelight leaves a phosphor lane for 3 s; Choir crossing it take one lance hit (SYS-001 §3 unit HP: Grub 4, Acolyte 6, Listener 12) and the Listener's arc resets. | yes | LANTERN-1 | A bruise-cyan road behind you; Grubs that touch it light up and pop |
| LANTERN-15 | Lantern Inferno | 4 | 520 | Ember | Light-pool Shroud clear rate 1 HP / 6 s → 2 HP / 6 s (SYS-001 §9 `Shroud`). | no | LANTERN-12 | A corridor of bone-pale ground opens behind you in one pass |
| LANTERN-16 | Oiler's Chain | 4 | 520 | Ember | SYS-001 §1.1 `Surgelight` cooldown a further −20%, to a 0.55 s floor (`✱` ceiling row [^gap]). | no | LANTERN-7 | You boost three times inside one Grave-Tide wave |
| LANTERN-17 | The Ninth Lantern | 5 | 900 | Ember | Capstone: inside your light pool the HUD cannot lie (WARP-001 §4 `HUD lies` row, SYS-001 §6 `Ledger Compass`), Deacon of Lies phantoms break apart, and Choir units hold fire at the pool's rim (SYS-001 §3.1 `Shrine hold-fire` extended to the lamp). | yes | LANTERN-3, LANTERN-5 | A clean circle of honest gaslight cut into a T4 sky; the chant stops at the rim |
| LANTERN-18 | Lamp of the Failed Sky | 5 | 90 | Unwritten Ink | Capstone: at full radius the Waking Dark treats your lantern as a Shrine and holds for 3 s, once per sector (extends SYS-001 §3.1 hold-fire law to the entity; new `✱` row). | yes | LANTERN-17 | The Dark Star turns its face away from one small lamp, and the sector goes quiet |

#### HULL (branch H) — plating, drift, braking, survival

| ID | Node | Tier | Cost | Currency | Effect (numbers reference SYS-001) | Rules-bending? | Requires | Visible in play |
|---|---|---|---:|---|---|---|---|---|
| HULL-1 | Drift Control | 1 | 40 | Ember | SYS-001 §1.1 `drag` +25% (⚙): terminal drift falls from the ≈1.4 body-lengths of GDD-001 §4.2 to ≈1.1. | no | — | The skiff stops where you let go instead of sliding past the geode |
| HULL-2 | Dead Reckoning | 1 | 40 | Ember | The Compass lie (SYS-001 §6 `Ledger Compass`, lies at T ≥ 3 or Composure ≤ 3) now carries a chalk strike, so you can see that it is a lie. | yes | — | A barred scratch across one compass blip; you learn to distrust it |
| HULL-3 | Brake Radius | 1 | 40 | Ember | SYS-001 §1.1 `brake` +25%, and the same row's 0.2 s confirmed-stop window is drawn as a chalk ring. | no | — | A chalk circle blooms under the ship whenever Space is held |
| HULL-4 | Plating | 1 | 40 | Ember | SYS-001 §1.2 `Hull HP` 1 → 2 (that row names HULL-4); the first hit of a run shears the plate instead of killing you. | no | — | A brass plate module bolts to the flank (ART-002); the first hit rings off it like a bell |
| HULL-5 | Deep Anchor | 2 | 120 | Ember | SYS-001 §1.1 `brake` a further +15%; the confirmed-stop window 0.2 → 0.3 s (⚙). | no | HULL-3 | You park dead still on a geode face and mine without drifting |
| HULL-6 | Second Vigil | 2 | 120 | Ember | One revive per run: the first lethal hit puts you back in the same Seam at full lantern. The SYS-001 §1.5 `Death` Composure penalty and §1.2 `Acquisition loss timer` both still apply. | yes | HULL-4 | The screen cracks, one bell, and the skiff re-forms out of brass dust |
| HULL-7 | Drift Baffles | 2 | 120 | Ember | SYS-001 §1.1 `drag` +30% more, to a drift floor of 1.0 body-lengths (floor row needed [^gap]). | no | HULL-1 | The ship lands on a geode and stays there; no bounce-off |
| HULL-8 | Long Watch | 2 | 30 | Unwritten Ink | SYS-001 §1.2 `Acquisition loss timer` 2.2 → 3.0 s, so a dark break shakes the Dark Star sooner. Meaningless at Hunger ≥ 6 (SYS-001 §2.2: it never loses you). | no | — | The Dark Star's face turns away a full second after your light dies |
| HULL-9 | Anchor Field | 3 | 45 | Unwritten Ink | Holding Space plants the skiff and drops the Anchor field: SYS-001 §1.1 `anchor` rows, ring 190 px, freezing nearby Choir for 6.0 s on a 20 s rearm. Hangs off the SYS-001 §1.1 `brake` note about Anchor nodes widening the confirmed-stop window. | yes | HULL-3 | A chalk circle blooms; Grubs stop mid-carry and the censer swings and halts |
| HULL-10 | Anchor Ring | 3 | 260 | Ember | The Anchor field ring radius +35% (same row as HULL-9). | no | HULL-9 | The chalk ring is wide enough to cover a whole geode cluster |
| HULL-11 | Unshakeable | 3 | 260 | Ember | While Frayed, the SYS-001 §1.5 Frayed-band magnitudes (all `✱`) are halved. | no | — | The chromatic edge and the sliding HUD numbers settle while your wick is low |
| HULL-12 | Chalkfast | 3 | 260 | Ember | The Anchor field's rearm 20 → 14 s (SYS-001 §1.1 `anchor` rows). | no | HULL-9 | The ring chimes again before the Grub procession can re-form |
| HULL-13 | Wide Anchor | 4 | 520 | Ember | Anchor ring radius +70% over HULL-10; ring ceiling flagged in [^gap]. | no | HULL-10 | The ring covers a whole Encounter Kit and every Grub in it |
| HULL-14 | Plate Remembers | 4 | 520 | Ember | Plating re-arms at the start of each Seam instead of once per run; the SYS-001 §1.2 `Hull HP` ceiling of 2 is unchanged. | yes | HULL-4 | A fresh plate welds itself on at every Seam with a shower of sparks |
| HULL-15 | Hard Vigil | 4 | 520 | Ember | SYS-001 §1.1 `brake` a further +25%; confirmed-stop window 0.3 → 0.4 s (brake ceiling needed [^gap]). | no | HULL-5 | Braking throws visible chalk dust and the ship plants like a stake |
| HULL-16 | Anchor Overdrive | 4 | 60 | Unwritten Ink | The Anchor field's freeze 6.0 → 8.0 s, with the ring at its 436 px ceiling (SYS-001 §1.1 `anchor` rows). | no | HULL-9, HULL-13 | Choir units stand frozen while their chant frays at the edges |
| HULL-17 | Anchor Against God | 5 | 900 | Ember | Capstone: the Anchor field suspends the Waking Dark's contact death for you for 1.5 s, once per rampage (extends SYS-001 §2 phase 4 and the §1.1 Anchor note to the entity; new `✱` row). Stays inside the agency-loss budget of GDD-001 §8.7 criterion 3. | yes | HULL-9, HULL-13 | The Dark Star stops dead on a chalk circle drawn by a lamp |
| HULL-18 | Hollow Hull | 5 | 90 | Unwritten Ink | Capstone: while Frayed or worse your silhouette reads to the Choir as one of its own (SYS-001 §3.1 `Targeting law`, §3 `Deacon of Lies` phantoms); units will not fire first, and mining or lance fire breaks it. | yes | HULL-6 | Grubs walk past you mid-carry — but the Ledger Compass still reads you as you, and that is the tell |

#### ORDNANCE (branch O) — Arc-Lance and Null-Iron Charges

No node here adds a lance fuel bar, a reload meter or an in-run upgrade roll (GDD-001 §3 anti-pillars 1, 2, 8). Charges stay fire-and-forget (GDD-001 §8.3) and the 13-hits-to-unmake requirement (GDD-001 §8.3) is never lowered.

| ID | Node | Tier | Cost | Currency | Effect (numbers reference SYS-001) | Rules-bending? | Requires | Visible in play |
|---|---|---|---:|---|---|---|---|---|
| ORDNANCE-1 | Hookline | 1 | 40 | Ember | SYS-001 §1.4 `Shard magnet radius` 96 → 190 px. | no | — | A brass line trails from the bow and shards hook themselves onto it |
| ORDNANCE-2 | First Sermon | 1 | 40 | Ember | The first Charge of each sector cannot be intercepted (SYS-001 §1.4 `Charge HP (interceptable)`; the §2.2 Hunger-4 interception rule does not apply to it). | yes | — | It flies through a wall of Grubs untouched, one chime on the way out |
| ORDNANCE-3 | Lance Rate I | 1 | 40 | Ember | SYS-001 §1.3 `Fire rate` 6/s → 7/s (base 🔒; the 9/s ceiling is the capstone chain). | no | — | The muzzle glow runs continuous and a small geode face gives way inside the 0.9 s row |
| ORDNANCE-4 | Charge Capacity I | 1 | 40 | Ember | SYS-001 §1.4 `Charge magazine` 5 → 6 (ceiling chain 7 / 9 / 13; the row's per-run Sigil cap is untouched). | no | — | Two more lamp pips along the ship's spine |
| ORDNANCE-5 | Pierce | 2 | 30 | Unwritten Ink | SYS-001 §1.3 `Hits per projectile` 1 → 2: lance shots now pass through the first Acolyte they hit. | no | — | The bolt exits the far side trailing a thread of glass |
| ORDNANCE-6 | Twin Vigil | 2 | 120 | Ember | SYS-001 §1.4 `Charge cap gain per run` 1 → 2 — the chain that row names: two capacity upgrades may stack inside one run. | yes | — | Two spare charge racks bolt onto the hull at every Seam |
| ORDNANCE-7 | Lance Rate II | 2 | 120 | Ember | SYS-001 §1.3 `Fire rate` 7/s → 8/s. | no | ORDNANCE-3 | The flame-pipe barrel runs amber-hot and audibly hisses |
| ORDNANCE-8 | Fourth Shard | 2 | 120 | Ember | SYS-001 §1.3 `Shards per geode (calm kill)` base 3 → 4 (yield ceiling flagged in [^gap]). | no | — | Every shattered geode coughs out one more shard |
| ORDNANCE-9 | Charge Capacity II | 3 | 45 | Unwritten Ink | SYS-001 §1.4 `Charge magazine` 6 → 7 — that row's tree ceiling, paid for with the Codex's record of the charge-rites. | no | ORDNANCE-4 | The spine rail fills with a third rack of glass bells |
| ORDNANCE-10 | Bomb Casing | 3 | 260 | Ember | SYS-001 §1.4 `Charge HP (interceptable)` 1 → 2 dmg unit; Listener shots on it 2 → 3 (`✱`). | no | — | Grub jaws clang off the casing instead of popping it |
| ORDNANCE-11 | Homing Song | 3 | 45 | Unwritten Ink | SYS-001 §1.4: `Charge speed` 210 → 250 px/s and `Turn authority` 1.6 → 2.6 s, at the Composure cost that row already carries. | yes | ORDNANCE-4 | Charges curve wide around geodes humming a choir note, and the Choir turns toward the sound |
| ORDNANCE-12 | Detonation Discipline | 3 | 260 | Ember | SYS-001 §1.3 `Over-fire detonation` threshold 9 hits in 1.2 s → 12 hits, and `Shards per geode (detonated)` scatter 140 px → 90 px (⚙/`✱`). | no | — | Panic fire no longer scatters glass to the Grubs; the shards drop at your feet |
| ORDNANCE-13 | Nine-Syllable Lance | 4 | 60 | Unwritten Ink | SYS-001 §1.3 `Fire rate` 8/s → 9/s — that row's ceiling, bought with the Choir's own firing litany transcribed into the Codex. | no | ORDNANCE-7 | Every muzzle flash leaves a nine-petal flower of light on the glass |
| ORDNANCE-14 | Charge Capacity III | 4 | 520 | Ember | SYS-001 §1.4 `Charge magazine` 7 → 9 (the chain's next step; 13 stays with ORDNANCE-18 and Run Sigils). | no | ORDNANCE-4, ORDNANCE-6 | Nine pips, the spine rail full; the HUD strip spans half the ship |
| ORDNANCE-15 | Shatter Shot | 4 | 520 | Ember | SYS-001 §1.3 `Hits per projectile` 2 → 3 — the `Shatter Shot` chain that row names. | yes | ORDNANCE-5 | The bolt bursts on impact into three splinters that each find a body |
| ORDNANCE-16 | Fifth Shard | 4 | 520 | Ember | SYS-001 §1.3 `Shards per geode (calm kill)` base 4 → 5; the combined-yield ceiling is flagged in [^gap]. | no | ORDNANCE-8 | A geode breaks into a fistful and the Grubs get nothing extra from it |
| ORDNANCE-17 | Null-Iron Hymn | 5 | 90 | Unwritten Ink | Capstone: Charges also home on Sepulchre processions and knock 1 segment point off the deposit they intercept (SYS-001 §2 phase 1 and the §2.1 module row). A race-mechanic win, not a kill-mechanic discount. | yes | ORDNANCE-11 | Charges swerve off the entity and slam into the choir line; a censer goes dark |
| ORDNANCE-18 | Thirteen Bells | 5 | 900 | Ember | Capstone: SYS-001 §1.4 `Charge magazine` ceiling 13 — the row's top step, with the ORDNANCE-6 chain intact. You can enter a Seam carrying a full unmake-load; the 13 hits needed for a complete entity (GDD-001 §8.3) are unchanged. | yes | ORDNANCE-14, ORDNANCE-17 | Thirteen lamp pips along the spine, and one pass is now enough to empty them into the Dark Star |

#### WARD (branch W) — rites, salt, silencing the litany

| ID | Node | Tier | Cost | Currency | Effect (numbers reference SYS-001) | Rules-bending? | Requires | Visible in play |
|---|---|---|---:|---|---|---|---|---|
| WARD-1 | Short Rite | 1 | 15 | Unwritten Ink | Ward Pulse cooldown −25% against the proposed base row (SYS-001 owes this row [^gap]). | no | — | The pulse chime comes sooner and the chalk sigil on the hull blinks faster |
| WARD-2 | Salt Glass Mines | 1 | 40 | Ember | SYS-001 §2 phase 0 carries the number: a salt ward blocks 1 deposit for 30 s. You now place them from the Tree instead of only via Pact. | yes | — | A jar of salt-glass at the Sepulchre's foot; the Grub walks in and the keening starts |
| WARD-3 | Ward Reach | 1 | 40 | Ember | Ward Pulse radius +30% (proposed base 180 px [^gap]). | no | — | The pulse ring crosses the whole kit and lifts phantoms off the floor |
| WARD-4 | Salt the Wound | 1 | 40 | Ember | Each pulse removes 2 of a Shroud cell's 3 HP (SYS-001 §9 `Shroud`, baseline 1 Ward-slice). | no | — | Shroud peels back in a ring and the floor beneath it is bone-pale |
| WARD-5 | Ward Reach II | 2 | 120 | Ember | Ward Pulse radius +30% more (ceiling flagged [^gap]). | no | WARD-3 | The ring now covers a whole geode cluster and every Grub working it |
| WARD-6 | Silence the Choir | 2 | 30 | Unwritten Ink | A Ward Pulse on the Sepulchre halts deposits for 4 s — the SYS-001 §3.1 `Litany Ring` deposit-halt number, aimed straight at the phase-0 timer (GDD-001 §13 P1). | yes | WARD-2 | The chant cuts out mid-syllable; every Grub in the procession drops and the deposit bar stops |
| WARD-7 | Deacon Bane | 2 | 120 | Ember | Phantoms dispelled by Ward (SYS-001 §3 `Deacon of Lies`, `Phantom`) refund the 0.3 Composure they drain on first sight (new `✱` row). | no | — | The false Grub bursts and your vision clears with a bell |
| WARD-8 | Ward Rite Fast | 2 | 120 | Ember | Ward Pulse cooldown −20% more. | no | WARD-1 | Two pulses inside one Acolyte duel |
| WARD-9 | Choir's Own Bell | 3 | 45 | Unwritten Ink | The Ward's silence on Rite bosses 3 → 6 s; the base 3 s lives in the SYS-001 §5.1 `Ash Matron` row and the §5.1 `Unnumbered` re-skin row. | no | WARD-8 | The Matron hangs mid-hymn, its mouth working with no sound in it |
| WARD-10 | Deconsecrate | 3 | 260 | Ember | Warding a Shrine collapses it: you collect the SYS-001 §6 `Shrine purge reward` (+1 Composure, −1 Corruption, 15 Ink — that row, not ours) and the §3.1 120 px hold-fire law stops applying to that spot. | yes | WARD-3 | The shrine's chalk floor caves in; the Choir around it turns and fires |
| WARD-11 | Salt Lantern | 3 | 260 | Ember | The pulse reveals phantoms and the Grave-Tide Deceiver's decoy lantern (SYS-001 §3, base decoy 2 s) for 3 s. | no | WARD-3 | Decoy lanterns look visibly wrong in pulse-light; yours casts a shadow |
| WARD-12 | Long Silence | 3 | 260 | Ember | Ward Pulse cooldown a further −15%, to a 3 s floor (floor row needed [^gap]). | no | WARD-1, WARD-8 | You answer two processions in one crossing |
| WARD-13 | False Lantern | 4 | 60 | Unwritten Ink | You drop a decoy lamp — the Grave-Tide Deceiver's own trick (SYS-001 §3): Choir units acquire it instead of you for 3 s, and for that time your light reads to them as a Shrine under the §3.1 law. | yes | WARD-11 | A second lamp of your own burns on the ground and the whole Choir turns to it |
| WARD-14 | Ringbreaker | 4 | 520 | Ember | The Litany Ring break threshold drops from 4 nodes down to 3 (SYS-001 §3.1 `Litany Ring`: 8 nodes at the Sepulchre; the row's halt duration is untouched). | no | WARD-6 | Three dark censers and the whole procession kneels |
| WARD-15 | Wide Reach III | 4 | 520 | Ember | Ward Pulse radius +40% more (radius ceiling flagged [^gap]). | no | WARD-5 | The pulse reaches the next Encounter Kit through the corridor |
| WARD-16 | Salt Hoard | 4 | 520 | Ember | The salt ward's duration 30 → 45 s (extends the SYS-001 §2 phase 0 row; `✱`). | no | WARD-2 | You carry two jars and the keening lasts a whole crossing |
| WARD-17 | The Quiet Ninth | 5 | 900 | Ember | Capstone: the Ward may be *held*. While held, Choir inside the radius stop chanting, mining and depositing until you take any action (extends the §3.1 `Litany Ring` halt and the §5.1 silence rows; new `✱` row). | yes | WARD-6, WARD-10 | Total silence: the censer frozen mid-swing, your own flame stretched thin |
| WARD-18 | Unconsecrated Sky | 5 | 90 | Unwritten Ink | Capstone: Ward a Shrine and carry it — the §3.1 120 px hold-fire law follows the carried shrine for one Seam, and the §6 purge reward applies when you set it down. | yes | WARD-10 | You walk with a broken altar on your back, and the Choir will not shoot near it |

#### MADNESS (branch M) — Composure, Warp Tiers, the voice that answers

MADNESS is the Ink branch: 9 of its 18 nodes are bought with Unwritten Ink, more than any other branch, because its power comes from what you have *learned* about the entity (GDD-001 §7.1). It buys power with dread, never with a survival meter — no node here adds HP, a hunger bar or a second life beyond HULL-6 and the SYS-001 §1.5 Hollowed free death, and none of them stack.

| ID | Node | Tier | Cost | Currency | Effect (numbers reference SYS-001) | Rules-bending? | Requires | Visible in play |
|---|---|---|---:|---|---|---|---|---|
| MADNESS-1 | Fray Reading | 1 | 40 | Ember | SYS-001 §1.5 Frayed-band `false audio cues` (1 per 40 s) halves to 1 per 80 s, and each cue instead points at the nearest real procession (new `✱` row). | no | — | The false chant arrives from the direction of the true Sepulchre |
| MADNESS-2 | Look Away | 1 | 15 | Unwritten Ink | While you sit inside the entity's acquisition cone and are not firing, the §1.5 `-1.0/s in gaze cone` drain stops: the stare becomes readable instead of expensive. | yes | — | The great eye holds on you and your wick stops guttering |
| MADNESS-3 | Tremor Hand | 1 | 15 | Unwritten Ink | The Unmoored-band inverted-axis bursts (SYS-001 §1.5, `✱` magnitudes) shorten from 4 s to 2 s. | no | — | Your hands stop fighting the wheel for two seconds instead of four |
| MADNESS-4 | Bitter Candy | 1 | 40 | Ember | While Frayed or worse, SYS-001 §7.1 `Chain bonus` caps at +80% instead of +50% (`✱` row) — madness pays in Ember, not in score-only pride. | no | — | The Vigil Index strip runs red and keeps climbing while the screen shakes |
| MADNESS-5 | Clear Eyed | 2 | 30 | Unwritten Ink | SYS-001 §1.5 `MADNESS-5` row exactly as written: spend 1 Composure to set your own Warp Tier effect off for 20 s. | yes | MADNESS-2 | The palette snaps back to honest gaslight, phantoms fall apart, the HUD stops moving |
| MADNESS-6 | One-Syllable Truth | 2 | 120 | Ember | Phantoms die to 1 lance hit while you are Frayed or worse (SYS-001 §3 `Deacon of Lies`, `Phantom`: base 2 hits or a Ward). | no | — | The false Grub bursts from one shot, and the real ones now look wrong to you |
| MADNESS-7 | Hollow Ledger | 2 | 30 | Unwritten Ink | While Frayed or worse, the SYS-001 §7.2 `Codex firsts` Ink that each first kill pays is +5 (`✱`) — the branch feeds on its own currency. | no | — | The Codex stamp glows bruise-magenta on a first kill |
| MADNESS-8 | Cheap Ecstasy | 2 | 120 | Ember | `Clear Eyed` costs 0.5 Composure instead of 1 (adjusts the cost half of the SYS-001 §1.5 `MADNESS-5` row; ⚙). | no | MADNESS-5 | The snap-back costs half a wick and leaves no ring of pain behind it |
| MADNESS-9 | Warp Bounty | 3 | 260 | Ember | While Frayed or worse, the SYS-001 §7.1 `Warp multiplier` (⚙ rows: ×1.2 at T2–T3, ×1.5 at T4–T5) steps up one band. | no | — | The score strip bruises purple and runs hotter than the sky above it |
| MADNESS-10 | Deep Fracture | 3 | 260 | Ember | The SYS-001 §1.5 Hollowed rule `MADNESS branch effects ×2` also applies at Warp T ≥ 3 while you are Unmoored. | no | — | A bruise-coloured ring brightens along your own hull |
| MADNESS-11 | Communion | 3 | 45 | Unwritten Ink | The entity speaks its next action 2 s before it acts — the voice-as-state channel of GDD-001 §12 and SYS-001 §2.2, pushed one step further; costs 0.5 Composure/s while up (row needed [^gap]). | yes | MADNESS-5 | One big word arrives before the lunge, and you were already leaving |
| MADNESS-12 | Hollow Chain | 3 | 45 | Unwritten Ink | While Hollowed, the SYS-001 §7.1 `Chain bonus` never resets on hit-taken (`✱`) — a hit still kills you, which is the point. | no | — | The Index keeps climbing while the screen cracks around it |
| MADNESS-13 | Long Clear | 4 | 520 | Ember | `Clear Eyed` runs 30 s instead of the 20 s of the SYS-001 §1.5 `MADNESS-5` row (extends that row; `✱`). | no | MADNESS-5, MADNESS-8 | Half a minute of honest HUD inside a warped sky |
| MADNESS-14 | Blessed Fracture | 4 | 60 | Unwritten Ink | GDD-001 §7.2: damage +30% per Warp Tier. SYS-001 has no damage-vs-Choir row to hang this on yet, so the scaling is ours to place ([^gap]). | yes | MADNESS-10 | Each Warp Tier adds another bruise ring on the lance muzzle, and your shots leave the hull trailing glass |
| MADNESS-15 | Communion Held | 4 | 520 | Ember | `Communion` costs 0.25 Composure/s instead of 0.5 (same row as MADNESS-11). | no | MADNESS-11 | You can keep listening to the Dark Star without paying for it in wick |
| MADNESS-16 | Hunger Feast | 4 | 520 | Ember | While Frayed or worse, SYS-001 §1.3 calm-kill shard yield gains +1; the combined-yield ceiling with ORDNANCE-8 and ORDNANCE-16 is flagged in [^gap]. | no | — | Geodes burst fat when your wick is low, and the Grubs scramble too late |
| MADNESS-17 | Unravel Focus | 5 | 90 | Unwritten Ink | Capstone: GDD-001 §4.1's R key becomes available from the first Seam of Act 3 instead of Act 4 only, and the SYS-001 §2 phase 6 `latch time` 1.4 → 1.0 s (⚙). | yes | MADNESS-11, MADNESS-14 | The white reticle opens on a lunge and you push the world back a hand's width |
| MADNESS-18 | The Ninth Sky Looks Back | 5 | 90 | Unwritten Ink | Capstone: once per run you speak in the entity's own voice-channel (GDD-001 §12; SYS-001 §2.2): one Choir unit stands down for 6 s and the nearest Sepulchre's current procession is spent (SYS-001 §2 phase 1, §3.1 `Litany Ring`). | yes | MADNESS-11 | Your HUD types in the entity's big type, and a censer goes out mid-hymn |

#### Node rollup

| Branch | Nodes | Ember total | Unwritten Ink total | Rules-bending nodes |
|---|---:|---:|---:|---:|
| LANTERN | 18 | 4,100 | 195 | 6 |
| HULL | 18 | 3,760 | 225 | 6 |
| ORDNANCE | 18 | 3,500 | 270 | 6 |
| WARD | 18 | 3,720 | 240 | 6 |
| MADNESS | 18 | 2,400 | 420 | 6 |
| **Total** | **90** | **17,480** | **1,350** | **30** |

Counts by purchase currency: 63 nodes bought with Ember, 27 with Unwritten Ink (12 numeric + 15 rules-bending). 30 of 90 nodes (33%) are rules-bending, against the ~30% target in GDD-001 §7.3. All 10 tier-5 capstones are rules-bending: the cost model prices tier 5 only as 900 Ember or 90 Ink, so a purely numeric capstone has no legal price — a judgement call worth confirming.

Pacing against the ~450–800 Ember and 40–100 Ink per run in SYS-001 §7.2. Ember is the binding currency in four branches: LANTERN 6–10 runs, HULL 5–9, ORDNANCE 5–8, WARD 5–9 to full-clear; MADNESS needs only 3–6 runs of Ember but 5–11 runs of Ink for its 420 Ink, so **MADNESS is gated by Ink, not Ember** — endgame power comes from engaging the Codex (first kills, revelations, WARP-001 conditions) rather than from farming. The whole tree costs 17,480 Ember plus 1,350 Ink: 22–39 runs at Entropy 0 on Ember alone, 14–34 runs on Ink alone, so a completionist pass is roughly 30–39 Iteration-clean runs and MADNESS arrives last by design.


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

- Respec costs **10% of banked Ink** (GDD-001 §7.3). It is a convenience tax and never gates progress.
- A respec refunds Ember and Ink in full for everything below the highest purchased tier; MADNESS nodes bought with Composure refund the Composure only if you are currently **Clear** (SYS-001 §1.5 band), otherwise the Composure is gone — that is the branch's price.
- **One respec per iteration, free after Hard Unmaking.** The loop's reset is a build-reset, which is the roguelike convention the GDD's macro layer is built on.
- No node is ever sold by the game. No node is randomly removed. GDD-001 §7.3: purchased, not rolled.

### 3.6 The ten tier-5 capstones

Tier 5 is the top of a branch (two capstones per branch, 17th and 18th node). All ten are rules-bending, all ten are priced at 900 Ember or 90 Unwritten Ink, and each one has a named counterplay so it never becomes a win button.

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
| MADNESS-17 | Unravel Focus | MADNESS | the Unravel key is live from the first Seam of Act 3 instead of Act 4, and latch time drops 1.4 → 1.0 s | it spends Unwritten Ink, not Ember, so it arrives only if the Codex was read |
| MADNESS-18 | The Ninth Sky Looks Back | MADNESS | once per run you speak in the entity's own voice-channel: one Choir unit stands down for 6 s and the nearest Sepulchre's procession is spent | once per run only, and it speaks with the entity's voice — the Composure band you are in is visible in the tell |

## 4. Run Sigils — the in-run build layer (120-entry pool)

GDD-001 §6.3 promises "~120 pool entries". Here they are. A Run Sigil is stamped onto the Vigil for the rest of the run and **shows up on the sprite** in one of the four module slots (ART-002 §6). A Sigil you cannot see on the ship is a Sigil that does not ship.

### 4.1 Selection rules

| Rule | Value |
|---|---|
| Choices | **3 per run**, after Seams 1–3 (SYS-001 §7.2 `Run-Sigil picks`). Seam 4 pays a **Relic** instead (§5), and Seam 5 is the Waking, which offers neither. This row used to say "one after each of Seams 1–4", which disagreed with the SYS row above it: SYS-001 wins, and the fifth boundary now belongs to the relic layer rather than being a choice that does not exist |
| Slots | 4. The choice is always 1-of-3; a fourth option appears only when the entity is offering a **Cursed** Sigil, drawn in a visibly different frame |
| Reroll | bought in-run with Ember, 40 / 90 / 160 / 240 by choice number (GDD-001 §7.3) |
| No duplicates | anything you already hold is removed from later pools |
| Rarity | Common 60 · Uncommon 40 · Rare 16 · **Cursed 4** = 120 |
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
| SIG-W-20 | Heresy | Cursed | Ward stops protecting you entirely; each cast grants +1 Ink immediately, to 10 per run (SYS-001 §7.1) | **You trade the bell for the book** | ✔ |

#### MADNESS family (20) — paying in Composure

| ID | Sigil | Rarity | Effect | Tell / catch | RB |
|---|---|---|---|---|---|
| SIG-M-01 | Steady Gaze | Common | Warp Composure drain −15% (SYS-001 §1.5) | The wick burns slower | |
| SIG-M-02 | Borrowed Calm | Common | At Composure ≤ 3, lance damage +25% (SYS-001 §1.5) | The shots bite when you are bad at this | |
| SIG-M-03 | Chalk Saint | Common | At Warp ≥ 2, warped geometry and phantom units show a bone outline first (SYS-001 §4) | The room sketches itself before it lies | |
| SIG-M-04 | Nightglass Mind | Common | Codex reading grants +50% Ink (SYS-001 §7.2) | The pages come out darker | |
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
| SIG-S-04 | Salver | Common | First-kill Ink on each Choir variant pays +1 (SYS-001 §7.1) | The book thickens as you learn | |
| SIG-S-05 | Chalk Ledger | Common | One free respec at the Desk this run (SYS-001 §7.3) | The desk has your name on it | |
| SIG-S-06 | Miner's Tithe | Common | A geode face already cracked scores +50% (SYS-001 §7.1) | Finishing pays better than starting | |
| SIG-S-07 | Quiet Victory | Common | Clearing a Seam without killing a Choir unit grants +1 Composure (SYS-001 §1.5) | Nothing followed you out | |
| SIG-S-08 | Nine Coins | Common | Charges left in the magazine at run's end convert to Ink, 1 each | The lamps you did not throw become pages | |
| SIG-S-09 | Threnody | Common | The Vigil Index is shown, and grants +5% score per 1000 Index (SYS-001 §7.1) | The Choir reads your numbers aloud | |
| SIG-S-10 | Small Hours | Common | Death spends 10% less clock time (GDD-001 §6.2) | The sand forgives a little | |
| SIG-S-11 | Hourglass Mercy | Uncommon | The Hourglass Clock pauses for 60 s once per run | The sand stops for a breath | ✔ |
| SIG-S-12 | Seed Whisperer | Uncommon | Re-key one kit in the run to its Warp-3 version (ZONES-001 §3) | You ask the map for worse, and mean it | ✔ |
| SIG-S-13 | Ledger Thief | Uncommon | The compass shows the entity at all times; the score readout is corrupted (SYS-001 §6) | You know where it is, and not what you are worth | ✔ |
| SIG-S-14 | Ink Eater | Uncommon | You may spend banked Ink on Sigils mid-run (SYS-001 §7.1) | **You are reaching outside the loop for power** | ✔ |
| SIG-S-15 | Hollow Broker | Uncommon | One Hollow sector in this run escorts you instead of hunting you; its geodes yield +30% (SYS-001 §6) | You made a deal with a dead sky | ✔ |
| SIG-S-16 | Chained Run | Uncommon | The run is 6 Seams at +1 Entropy and pays the higher table (SYS-001 §4, §6) | One more room, one worse world | ✔ |
| SIG-S-17 | Long Vigil | Rare | The run's final Seam is the same kit every run, and grants +1 Sigil choice there | You learn one room perfectly | ✔ |
| SIG-S-18 | Archive Seal | Rare | The Codex records every rule eaten this iteration, and reading one grants 3 Ink (SYS-001 §7.2) | Grief with a footnote | ✔ |
| SIG-S-19 | Threnody Lost | Cursed | No Ledger Compass all run; everything banked is ×1.5 (SYS-001 §7.2) | You navigate by the chant | ✔ |
| SIG-S-20 | Unwritten | Cursed | You do not choose Sigils: the game picks four, each one rarity higher | It is building something out of your run | ✔ |

### 4.3 Ceiling lint (a build gate, not a wish)

Sigils compose additively and can silently break the game. TECH-001 §6 ships a **stack lint**: a unit test that builds the 20 worst-case Sigil combinations against the Lantern Tree's capstone loadout and fails the build if any combination crosses a SYS-001 §1 ceiling — speed, fire rate, pierce, magnet, magazine cap, light radius. The ceilings exist so the run's power curve stays inside the playtest envelope (SYS-001 §10 tunables register). A Sigil that would break a ceiling is authored *with* its own ceiling clause instead of being vetoed late, which is why rows such as SIG-O-01, SIG-O-07 and SIG-O-10 name the SYS-001 row inside the effect line.

**Sigil rollup.** Common 60, Uncommon 40, Rare 16, Cursed 4 = **120**. Rules-bending **36** (30%). Family totals: LANTERN 20 (10 Common / 6 Uncommon / 3 Rare / 1 Cursed), HULL 20 (10/6/3/1), ORDNANCE 20 (10/6/3/1), WARD 20 (10/6/3/1), MADNESS 20 (11/6/2/1), SEAM 20 (10/6/2/2).

## 5. Relics — what the run *is* (18-entry pool)

A Sigil is what your Vigil does. A Relic is what the run is. The distinction is the reason the GDD budgets both: Sigils are chosen cards that move numbers and small rules (§4), Relics are *objects the world hands you* at fixed boundaries, each one a verb you did not have, each one with a price printed on it. GDD-001 §7 promises **18 Relics**; all eighteen are below, with their prices. No Relic is a percentage. If a candidate Relic only moves a number, it is a Sigil that was written in the wrong file.

### 5.1 The three choice-layers, side by side

| | **Run Sigil** (§4) | **Relic** (§5) | **Pact** (§7) |
|---|---|---|---|
| Where it comes from | the Chalk Desk's card fan at a Seam boundary | the world: a kit's authored reward, or a gate boss | you, once per run, at the Chalk Desk in the Ruins — before the run starts |
| When | after Seams 1–3 | after Seam 2, at the Seam-3 gate, after Seam 4 | chosen once, at the start |
| Chosen or given | chosen 1-of-3, rerollable for Ember | **given**, 1-of-2, never rerolled | chosen outright, one from 24 |
| Bends | numbers mostly (84 of 120 are numeric) | rules only (18 of 18) | the run's win condition and its shape |
| Lost on death | yes | yes | the Pact is re-chosen next run; its *cost* is remembered by the entity |
| Eaten by the warp | **H14 takes one** (WARP-001 §3.2) | **never** — see §5.2 | never mid-run; a Pact's *restore* is what the warp answers to (WARP-001 §3.3) |

### 5.2 Relic rules

| Rule | Value |
|---|---|
| Slots | **3**, one per boundary. A slot is never empty at the moment its boundary is passed: you always take one of the two |
| Boundaries | Slot 1 after Seam 2 · Slot 2 on clearing the Seam-3 gate (SYS-001 §5.1, GDD-001 §6.3) · Slot 3 after Seam 4, immediately before the Waking |
| Presentation | 1-of-2, shown as two physical objects on the ground where the kill happened. No chest, no glow, no loot pop — the Choir's leftovers are the loot box |
| No reroll | a Relic is not bought and not re-rolled. There is no Ember price for a second look: the offer is what the world chose, which is the whole point of the layer |
| Rarity = tier = slot | **Found** (8, slot 1) · **Consecrated** (6, slot 2) · **Struck** (4, slot 3). The slot *is* the rarity: heavier objects arrive later, and the Struck four are the ones that shape the boss fight |
| Pool hygiene | a seed cannot offer the same Relic twice in one run, and a Relic offered in slot 1 is removed from slot 2's pair |
| Death | all three are lost with the run (SYS-001 §2 class: run state). The Codex records every Relic you held, so the knowledge is anchored (§8) |
| The warp never eats one | 🔒 a Relic is a thing the world already gave you; the warp takes *choices* and *rules*, not gifts. **H14 takes a Run Sigil and nothing else** (WARP-001 §3.2, §3.4). REL-18 pays you when the warp takes a Sigil, and it is explicitly **not** a restore — H14 stays `no_restore = true` and lint L-06 is unaffected |
| Ceilings | Relics enter §4.3's stack lint alongside Sigils: the 20 worst-case combinations are built against the capstone loadout, and any Relic that could push a SYS-001 §1 ceiling is authored *with* its own ceiling clause |
| Rules-bending share | 18 of 18. The 30% discipline in GDD-001 §7.3 governs nodes and Sigils; the relic budget was always a rules budget, and a Relic that is only a number has failed its own layer |

### 5.3 The pool

Column three states what the run now *does*, column four is the price, printed on the object's one-line description in the UI. Every row names the SYS-001 row or cross-doc clause it leans on. `✱` marks a number this doc is proposing for SYS-001 to own; those are gathered as requests in §5.5.

#### Found (8) — slot 1, after Seam 2

| ID | Relic | What the run now does | The price | Anchor |
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

| ID | Relic | What the run now does | The price | Anchor |
|---|---|---|---|---|
| REL-09 | The Unnumbered Bell | one Choir unit per sector stops rejoining its procession for the rest of the run | a thinner procession is a *faster* deposit tell: 6 frames shorter on the Sepulchre's cycle | SYS-001 §2, §3 (tell frames) |
| REL-10 | Censer of the Long Fast | an Acolyte mining a face gives that face up the moment you take it | taking a face from an Acolyte counts as Choir activity: the sector's corruption clock runs 25% faster ✱ | SYS-001 §3, §6 |
| REL-11 | Glass Tithe | at each Seam's end, 1 Charge becomes 1 Shard | the Tithe also takes the last Charge before the Waking: the boss begins with one fewer than your magazine says | SYS-001 §1.4 |
| REL-12 | The Vigil's Own Chalk | you may draw a ward on a seam boundary; it fires once when a Choir unit crosses it | drawing costs 1 Composure and 2 s of standing still | SYS-001 §1.5, §2 phase 0 (salt), §1.1 (brake) |
| REL-13 | Second Name | the first death you would take is survived at 1 hull, once per run | the entity learns your name: it swaps one counter-behaviour for this run, and the swap is shown to you before it acts | SYS-001 §2.2, §7.4 (the price is knowledge, never currency) |
| REL-14 | Hourglass in the Pocket | the Hourglass Clock stops while you stand inside your own Ward radius, **60 s per run** ✱ | the Ward is doing nothing else while it holds time, and the paused seconds do not raise Hunger — you are buying room inside the sky that is already going dark | GDD-001 §6.2; SYS-001 §10 clock lock (see request **LR-01**) |

#### Struck (4) — slot 3, after Seam 4, before the Waking

| ID | Relic | What the run now does | The price | Anchor |
|---|---|---|---|---|
| REL-15 | The Unmake-Load | you may carry 2 extra Charges into Seam 5 only | the Waking spends its remaining processions on interceptors and opens with +2 units: everything you carry is announced | SYS-001 §1.4 (and the §4.3 ceiling lint), §2 phases |
| REL-16 | Wound That Remembers | the Waking opens carrying the segment damage you dealt it in your **previous run's** Waking, for the first 20 s ✱ | it also opens carrying your previous run's most-used tool as its counter: the mirror improves for both of you | SYS-001 §2.1, §2.2 |
| REL-17 | Choir Broken Open | Unravel Focus is live in this run without MADNESS-17 | every latch costs 1 Composure and 40 Ember, and the Act 3 gate in GDD-001 §7.2 still holds — this Relic buys the node's mechanic, never the campaign's permission | SYS-001 §1.5, §7.2 |
| REL-18 | Mourning Ledger | when the warp takes a Run Sigil, this pays 1 Composure and 60 Ember at the run's end, and the Codex records the Sigil's name | it does not give the Sigil back. Grief is monetised once per iteration, and the slot stays empty until the next Seam's card | WARP-001 §3.2 H14, §3.4 (the ruling that there is no restore), lint L-06 |

### 5.4 Four loadouts the build matrix must clear

These are not recommendations, they are the QA matrix: four three-Relic sets at named Entropy levels, each one a build the game must be able to finish and be able to beat. They run in the same test pass as §4.3's stack lint and are named in GDD-001 §8.7.

| Loadout | E | Relics (slots 1/2/3) | What it must prove | Test |
|---|---:|---|---|---|
| **Salt Procession** | 6 | REL-04 / REL-09 / REL-15 | the Ward path is a real boss answer: hold-fire cover, thinned processions, and a full unmake-load land the Waking inside 90 s at E6 payouts | `TEST-REL-01` |
| **Tithe and Bell** | 8 | REL-08 / REL-11 / REL-17 | a Composure economy survives a T3 run while paying Charges away: the player stays in the Clear band through a ×1.2 warp score multiplier (SYS-001 §7.1) | `TEST-REL-02` |
| **Glass Name** | 8 | REL-14 / REL-13 / REL-16 | time and death are spendable and *bounded*: the 60 s clock cap cannot be looped, and a survived death hands the entity a visible counter the player can read back | `TEST-REL-03` |
| **Ledger Nine** | 10 | REL-02 / REL-18 / REL-15 | a lie-proof channel exists at E10, where the warp lies every sector (WARP-001 §4.2) and H14 is live: the run still finishes, and this is the clip build for the flex run | `TEST-REL-04` |

### 5.5 Rollup and requests

**Relic rollup.** 18 total = Found 8 + Consecrated 6 + Struck 4. Rules-bending 18 (100%). Slots 3 per run, boundaries Seams 2–4. `✱` numbers proposed for SYS-001: REL-01 (3 s at 60%), REL-07 (4 s), REL-08 (+0.2/+1.0 caps), REL-10 (+25%), REL-14 (60 s), REL-15 (2 Charges, Seam 5 only), REL-16 (20 s), REL-18 (1 Composure / 60 Ember, once per iteration).

| Request | Ask | Why it needs a SYS row, not a LOOP line |
|---|---|---|
| **LR-01** | Does anything other than the warp get to touch the Hourglass Clock rate? REL-14 asks for a pause permission with a 60 s per-run cap | SYS-001 §10 locks the clock rate as *not warp-writable* and names `clock_runs_during_exploration` as an A/B flag. A relic is not the warp, so the lock does not decide this. Left unruled, REL-14 ships by default, and a clock-affecting item is exactly the kind of number that must be in the bible with a trigger attached |
| **LR-02** | A per-run shard-yield ceiling that includes REL-05's face-splitting | §3.3's footnote already asks SYS-001 for a shard-yield ceiling because three nodes raise yield; REL-05 is a fourth input to the same row, so the ceiling should be written once, not per item |
| **LR-03** | Confirm that a Relic may never be counted as "player currency" for the purposes of SYS-001 §7.4 | REL-13 and REL-18 both pay in Composure and Ember. §7.4 protects currency from Hunger; it should say out loud that a Relic's payout is not a Hunger credit and not a Hunger debt, so the two systems cannot argue in code |

## 6. The shape of a run, and the two escalators

SYS-001 owns every number in this section's tables. What this section owns is the *shape*: what a run is made of, what a seed fixes, which escalators the player can pull and which pull themselves.

### 6.1 Run anatomy

Five Seams, two gates, three cards, three objects, one clock (SYS-001 §6 `Seams per run` 5 🔒, GDD-001 §6.3).

| Boundary | Threat budget (SYS-001 §4) | What you are given | What the player should feel |
|---|---|---|---|
| Seam 1 | 8–12 / 14–18 / 18–24 by Warp Tier | Run Sigil 1-of-3 | *I know this ship.* Act 0's vocabulary still works |
| Seam 2 | 12–18 / 20–26 / 26–32 | Run Sigil **and** Relic slot 1 (Found) | *the world started handing me things* |
| Seam 3 — gate | Sepulchre active, Litany Ring; Rite boss from SYS-001 §5.1 | Run Sigil **and** Relic slot 2 (Consecrated) | *this run has a shape now, and I chose it on purpose* |
| Seam 4 | 20–28 / 28–36 / 36–44, Herald at E ≥ 4 | Relic slot 3 (Struck) — the boss-shaping slot | *the last thing I chose is the answer I am carrying into the Waking* |
| Seam 5 — the Waking | budget is the boss | nothing; the run ends and banks | *what I built is what I get to find out about* |

- A run is 25–35 min 🔒 and a Seam is 4–6 min ✱ (SYS-001 §6). SIG-S-16 *Chained Run* is the one legal way to make it six Seams, and it pays the Entropy table one step up (SYS-001 §4, §7.3).
- Score never buys power inside a run (GDD-001 §3 anti-pillar). Ember is banked at the run's end: `Ember = floor(score / 200)` plus milestone bonuses (SYS-001 §7.1). The run's whole economy is *spend on the build now, bank the rest later*.
- Death inside a run is not the run's end unless it is final: Second Vigil (HULL-6) and REL-13 both spend a survival, and the entity's memory of your most-used tool survives either way (SYS-001 §2.2, GDD-001 §6.3).

### 6.2 Seeds, and what a seed fixes

| Seed kind | Who sets it | Fixed by the seed | Notes |
|---|---|---|---|
| Open run | the player | world layout, kit order, geode and Shrine placement, Sigil pools, Relic pools and which half of each 1-of-2 pair is offered, warp state, the entity's counter-behaviour order | the default; a run with no seed is still seeded, just from a rolling number |
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
| 10 | any ending seen | the entity opens each sector at 6 segments ✱ (SYS-001 §4); the flex tier, and the tier the four loadouts in §5.4 are stress-tested against |

- **Entropy is the only difficulty the game lets the player choose**, and the only one that pays (SYS-001 §7.3 Ember ×1.15→2.30, Ink ×1.10→2.00). It never touches the player's side of the ledger in any other direction.
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

**Pacing budget ✱** (the loop's own arithmetic, not SYS-001's, and the first thing to move when playtest data arrives): the game expects to spend **Hunger 0 → ~8 across Acts 1–3** and the full **0 → 18** by Act 5 and into NG+. Nine eaten rules on an even-numbered ladder is a 18-level runway, and at ~2–4 rules taken per Iteration (§6.5) a 20–40 h Chronicle consumes the whole registry exactly once. If playtest says the registry spends too fast, the fix is the *cadence* in SYS-001 §2.2 — the +1-per-sector-eaten source is the one to stretch — and not a new eaten rule.

### 6.5 The Hourglass Clock, and what spends it

| Fact | Value | Consequence for the loop |
|---|---|---|
| Clock per **sky** | 120 loop-minutes at Entropy 0 (GDD-001 §6.2) | a sky holds **3–4 completed runs** (SYS-001 §6: 25–35 min) or **7–12 deaths** (a death spends 10–18 min, GDD-001 §6.2). The clock is per sky, not per iteration — see the ruling below |
| Skies per Iteration | 9 🔒 | an Iteration runs **≈3.5–6 loop-hours**, so a 20–40 h Chronicle is **4–8 Iterations**, and Hard Unmaking lands 4–8 times: enough content-unlock beats to be a retention machine and few enough to stay sacred |
| Runs per Iteration | ≈30–40 completed, more if the player dies well | matches the tree math in §3.4 (17,480 Ember / 1,350 Ink = 22–39 clean runs): **one well-played Iteration can finish the Lantern Tree**, which is what GDD-001 §6.4's escalation contract promises — the tree outgrows the loop, not the other way round |
| Reading the Codex | pauses the clock 🔒 (GDD-001 §6.2) | the Codex is free, and §8 makes sure of it: lore is never taxed |
| A sky going dark mid-run | the run ends where it stands and **banks what it earned** | forward progress is a law (§1). The Seam in progress is lost, never more — the same ceiling SYS-001 §8 sets for a crash |
| Hunger from skies | none directly | the star grows from the sectors it eats under that sky (SYS-001 §2.2), not from the darkening itself |

**Ruling (LR-04).** GDD-001 §6.2 writes "120 loop-minutes **per iteration**" in its first line and then says Hard Unmaking ends the Iteration after nine skies — which would put 13 loop-minutes on each sky, less than half a run, and make most sky-darkenings interrupt a run the player never got to finish. The loop doc reads the clock as **per sky** and asks the owner to correct the GDD's wording (GDD-001 §20 has no row for this yet). The reversal condition is stated up front: if playtest wants Iterations to be short and brutal — one night, one sky-map, one Hard Unmaking — then the per-iteration reading is the right one, and the correct fix is to cut Skies per Iteration rather than leave 13 minutes on a sky. Either way the two numbers must be written down together in SYS-001 §6 as a single row (LR-05), because the run-length target and the clock are one equation.

## 7. Pacts — the Chalk Desk, one per run

A Pact is the run's contract, written at the Chalk Desk in the Ruins before the run starts (GDD-001 §6.4). Twenty-four exist. Sixteen shape what a run *is for*; eight exist because the warp took a rule and someone has to be able to bargain it back — those eight IDs are reserved by WARP-001 §3.3, and their restore semantics are not ours to change, only to price and to dress.

### 7.1 Pact rules

| Rule | Statement |
|---|---|
| One per run | the Chalk Desk writes **one** Pact per run. The ink is spent whether you use it or not; an unused Pact still counts as the run's Pact |
| When | before the run, in the Ruins. Never mid-run, never at a Seam boundary — a Pact is a promise, and a promise you can change mid-fight is a toggle |
| The price | always paid in run-state or world-state: Composure, Charges, hull, time, information, the Choir's behaviour. **Never in Ember or Ink** — a Pact priced in currency would tax the anchored tree, and the tree is the one thing the loop guarantees (§1) |
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
| **PACT-18** | **Vigil of the Ninth Sky** | the run begins at 1 hull and +2 Composure, and the first Relic offer is 1-of-2 → **1-of-3** | hull never repairs inside the run; one Listener touch and the run is over where it stands | SYS-001 §1.1, §1.5, §3 |
| **PACT-20** | **Chalk Line Nine** | draw one artificial boundary per sector that only you cross ✱ | 1 Composure to draw, and it is not an escape vector: SYS-001 §4's lint never counts your chalk, so a bad seed stays bad | SYS-001 §4, §1.5 |
| **PACT-21** | **The Unmaking Rehearsal** | the Waking is preceded by the Rehearsal; after it, the run holds **one pre-attached rule-thread** | the scene costs 90 s of the Hourglass Clock, and the thread counts as already latched — the three-thread requirement and SYS-001 §2.1 `Unravel hits` do not move | WARP-001 §6.1 **D-03**, §5 (the Rehearsal and its NG+ re-key, **D-09**); SYS-001 §2.1 |
| **PACT-23** | **Lantern to the Choir** | lighting a face calls an Acolyte to work it with you for 60 s ✱: the face shatters on the earlier schedule and you take 60% of the shards ✱ | the face corrupts at the Choir's rate (SYS-001 §6) and the Litany Ring gains a ninth node, so breaking it now takes five downed nodes ✱ | SYS-001 §3.1, §6 |
| **PACT-24** | **Salt Mother's Favour** | a face you never mine stays clean: no Shrine may form on it this run ✱ | those shards are lost to you for the run — a quiet sector is a poor sector, and the Hollow clock is the only thing this Pact buys | SYS-001 §1.3, §6 |

### 7.4 What H14 actually costs, and what LOOP owes for it

WARP-001 §6.1 **D-10** rules that LOOP-001 owes two slice-blocking Pact rows plus H14's pick logic and its `no_restore = true` flag — not nine Pacts. The pick logic:

| Clause | Spec |
|---|---|
| The pool | the struck Sigil is chosen from the Run Sigils the player **currently holds**, and the pick must come from the run's legal Sigil pool (WARP-001 lint **L-06**) |
| Never struck | a Cursed Sigil (its removal would be a reward, not a theft — §4.1); a Sigil a capstone or a branch prerequisite depends on (the tree would silently re-price, §3.3); a Sigil whose removal fails SYS-001 §4's solvability lint |
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
