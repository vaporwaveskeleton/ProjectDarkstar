# DARKSTAR — Reality Warp Escalation

**Doc ID:** WARP-001 · **Version:** 1.2 · **Date:** 2026-11-17 · **Owner:** Design (systems / reality warp) · **Status:** complete draft, pending review

This is the reality-warp contract. GDD-001 §8.7 promises six Warp Tiers with an explicit acceptance gate; GDD-001 §7.4 and SYS-001 §2.2 promise one eaten rule every two Hunger; GDD-001 §10 promises a HUD that moves, lies and gets eaten beside an honest-HUD accessibility toggle. All of it is written out here.

Numbers do not live in this doc. Every stat, threshold, budget and multiplier is in **SYS-001** (`SYSTEMS_BIBLE_STATS.md`) and is cited here by section and row name. Where WARP-001 needs a number SYS-001 does not yet carry, the number is authored here and marked `✱`, and it is requested of SYS-001 §10 rather than asserted. If a number in this doc and a number in SYS-001 disagree, SYS-001 wins and this doc is a bug. Vocabulary is GDD-001 §19 only; proper names appear only for content this doc introduces. The 1983 original is never named (RES-001 §5).

## 0. How to read this doc

| If you are… | Read | Then |
|---|---|---|
| new to the project | GDD-001 §1–§3, §8.7, §9.1 | §1.1 (definitions), §2 (what the tiers actually do) |
| implementing the warp state machine | §1.2–§1.5, §1.9 | §3.1 (the eaten-rule contract), TECH-001 §6 |
| authoring or tuning an effect | §1.8 (the gate), §2 | §5.2 (cost), §7.3 (warp lint) |
| tuning Hunger or an iteration's difficulty | §3.1, §3.2 | §3.3 (Pact requests), SYS-001 §2.2 |
| building UI/HUD | §4.1, §4.2 | §4.4 (Steady Ledger), §4.5 (photosensitivity parity) |
| doing art or VFX | §2, §5.1 | §5.2 (ms budget per effect), ART-001, ART-002 |
| doing audio | §2 hand-off columns, §5.4 | AUDIO-001 (voice-as-state line set, silence budget) |
| writing fiction or Codex copy | §1.7, §3.2, §6 | NARR-001, LOOP-001 §8 |
| planning the build or QA | §6, §7 | §7.3 (build gate), §9 (conformance map) |

Cross-doc IDs used here: GDD-001, SYS-001, LOOP-001, ZONES-001, NARR-001, AUDIO-001, ART-001, ART-002, ASSET-003, TECH-001, PROD-001, MARKET-001, RES-001.

### 0.1 Ownership boundaries

| This doc owns | This doc does not own |
|---|---|
| The Warp Tier state machine: entry, exit, ratchet, per-act window | Any stat, threshold or multiplier value (SYS-001) |
| The T0–T5 effect registry (§2) and its acceptance evidence | Encounter kits, biomes, sector contents (ZONES-001) |
| The eaten-rule registry and its order, keyed by Hunger (§3) | The Pact, Run Sigil and Lantern Tree pools (LOOP-001 §3–§4) |
| HUD behaviour under warp: movement, lies, eaten elements (§4) | The Codex's fiction text (NARR-001) |
| The warp look contract and the per-frame cost envelope (§5) | Shader implementation detail and scene structure (TECH-001) |
| The warp test plan and the warp lint (§7) | Milestone dates and cut order (PROD-001) |
| Decisions on GDD-001 §20 questions that touch warp (§6) | GDD-001 itself: this doc proposes, the GDD owner amends |

---

## 1. The warp model

### 1.1 Definitions

| Term | Definition as used in this doc |
|---|---|
| **Warp Tier** (`T`, 0–5) | A sector-scoped reality state. GDD-001 §8.7 defines the six tiers; this doc defines how one is entered, lived in and left. |
| **World tier** | The tier the sector is generated at, computed at Seam entry (§1.3). It selects the kit re-key (GDD-001 §8.8) and the standing effect set. |
| **Standing effect** | A tier-level effect, always on while the sector is at that tier or above. Exempt from the per-sector effect budget (§1.8). |
| **Transient effect** | A scheduled or triggered warp event with a start and an end. Budgeted: at most 3 novel transient effects per sector (GDD-001 §16 R-02). |
| **Novel effect** | A transient effect the player has not yet witnessed in the current Iteration. Repeats are still allowed but do not consume budget. `✱` |
| **Personal override** | A player-bought suspension of warp effects on the self only. SYS-001 §1.5 `MADNESS-5` (*Clear Eyed*). It does not change the world tier and does not count as a T0 return. |
| **Lie** | A HUD readout that disagrees with the game state. Legal only under the lie law (§4.2). Every lie carries a tell. |
| **Eaten rule** | A base rule the entity has removed or mutated, keyed to Hunger. Cadence: SYS-001 §2.2. Registry: §3.2. |
| **Agency window** | The interval in which the player cannot act, as opposed to acting at a disadvantage. Bounded by SYS-001 §9 `Player agency loss`. |
| **Tier ratchet** | The rule that a witnessed tier becomes the floor for later sectors (the tier never un-happens) (§1.5). |
| **Pretence** | The Act 0 costume: T0 is a costume the game wears, not a reality state that survives Act 0 (GDD-001 §8.7, §11). |

### 1.2 The four drives (GDD-001 §8.7)

| Drive | Source | How the warp reads it | Limit |
|---|---|---|---|
| (a) Iteration count | SYS-001 §0 `I`, 1–9 | Raises the act window floor at the boundaries in §1.3. | Bounded by the act ceiling, not by `I` directly. |
| (b) Sector consumed | SYS-001 §6 `Corruption` chain and `sector → Hollow`; SYS-001 §2.1 `Post-failure` | Supplies the `hollow term` at Seam entry: +1 world tier if any sector in this run's biome list is Hollow. `✱` | Caps at +1. Two Hollow sectors do not stack. |
| (c) Composure | SYS-001 §1.5 | Drives bands, the forced tier rise at `Hollowed`, and the personal override. It is a lever, never a death clock. | The forced rise ends at sector end (SYS-001 §1.5 `Hollowed`). |
| (d) Entropy | SYS-001 §0 `E`, 0–10, player-selected | Supplies the `entropy term`: +1 world tier at `E` ≥ 4, +2 at `E` ≥ 8. `✱` | Bounded by the act ceiling. Player-selected, so warp severity is always partly chosen. |

### 1.3 Sector-entry tier computation `✱`

Computed once, at Seam entry, from the four drives. Nothing else changes the world tier mid-sector except the `Hollowed` forced rise (SYS-001 §1.5) and Act-4 scripted forcing (§1.7).

```
T_world = clamp( act_floor(A) + hollow_term + entropy_term + composure_term,
                 act_floor(A), act_ceiling(A) )
```

| Term | Value | Notes |
|---|---|---|
| `act_floor(A)` | A0 = 0 · A1 = 1 · A2 = 2 · A3 = 3 · A4 = 5 | From GDD-001 §9.1's Warp column. |
| `act_ceiling(A)` | A0 = 0 · A1 = 1 · A2 = 3 · A3 = 4 · A4 = 5 | From GDD-001 §9.1. A4 is fixed at 5: Act 4 *is* Unmaking. |
| `hollow_term` | 0 or +1 | Drive (b). One per run, not per Hollow sector. `✱` |
| `entropy_term` | 0 / +1 at `E` ≥ 4 / +2 at `E` ≥ 8 | Drive (d). `✱` |
| `composure_term` | +1 while Composure is 0 at Seam entry | This is SYS-001 §1.5 `Hollowed`, not a new rule. |
| `clamp` | act floor → act ceiling | Guarantees the GDD-001 §9.1 act table is never violated by Entropy or corruption math. |

Act window, written out so no kit can be generated outside it:

| Act | Warp permitted | Legal effect set | Reference |
|---|---|---|---|
| 0 — Last Normal Day | T0 only | W0 set | GDD-001 §6.1, §9.1 |
| 1 — First Loops | T1 | W0 standing, W1 set | GDD-001 §9.1 |
| 2 — The Nine Skies | T2–T3 | W0–W3 standing, W2–W3 transient | GDD-001 §9.1 |
| 3 — Revelations | T3–T4 | W0–W4 standing, W3–W4 transient, eaten rules at full cadence | GDD-001 §9.1, SYS-001 §2.2 |
| 4 — Unraveling | T5 fixed | W0–W5 standing, W5 transient, Act-4 scripted sequence (§6.2) | GDD-001 §9.1, §8.7 |

### 1.4 Entry rules, tier by tier

| Transition | Entry condition | What the player is told | First possible point |
|---|---|---|---|
| — → **T0 Pretence** | Act 0 only. GDD-001 §8.7 marks T0 as Act-0-only; there is no legal T0 sector outside Act 0. | The cabinet costume itself: attract mode, honest HUD, chiptune. No fiction warning (GDD-001 §3 design rule: never announce a layer). | Game start |
| **T0 → T1** | The first Unmaking cinematic at the end of A0-3 has played (GDD-001 §6.1). From then on, Act 1 sectors generate at T1. | Nothing is announced. The palette is wrong on the next Seam. | Act 1, Seam 1 |
| **T1 → T2** | `act_floor` reaches 2 (Act 2), or the `hollow_term` or `entropy_term` lifts it there. | The Shroud appears; the chant becomes positional through walls (SYS-001 §3.1 chant row, extended at T2, §2 W2-08 `✱`). | Act 2, first Seam past the entry gate |
| **T2 → T3** | `act_floor` reaches 3 in Act 2's late window, or Entropy/corruption lifts it there within Act 2's ceiling of 3. | The edges of the field stop being edges (W3-01). The Compass begins to lie (SYS-001 §6 `Ledger Compass`). | Act 2 late |
| **T3 → T4** | Act 3. Scripted, never by math alone: the first Act-3 Seam always runs T3 for its first 90 s, then rises. `✱` | The entity's first rule-eat telegraph (SYS-001 §2.2 cadence; §3.1) arrives before the tier does. | Act 3, Seam 1 |
| **T4 → T5** | Act 4 only. The final Unmaking transition is scripted once per Chronicle and is never repeated by math. | Silence, then the field comes apart. No menu, no warning banner. | Act 4, opening Seam |
| Any → **T+1 forced** | SYS-001 §1.5 `Hollowed` band: Composure 0 forces a Warp Tier +1 for the sector, ending at sector end. | The wick goes out. The entity says one line (AUDIO-001). | Any act, at any tier below that act's ceiling |

Rules that hold across every entry:

| Rule | Statement |
|---|---|
| No mid-sector entry except `Hollowed` and Act-4 forcing | The world tier is decided at Seam entry. This keeps kit re-keying and spawn budgets stable (SYS-001 §4). |
| Entry never costs Composure directly | Cost is the SYS-001 §1.5 `Warp Tier passive` drain, not an entry fee. A tier is never a tax the player pays twice. |
| Entry never spawns a jumpscare | No effect may fire within the first 2 s of a Seam at any tier. `✱` No loud sting, no full-field luminance step (GDD-001 §10, anti-jumpscare). |
| Entry never breaks solvability | The world tier only selects a kit re-key that already passes the SYS-001 §4 `Solvability lint`. A warp effect may never remove a vector the lint counted. |

### 1.5 Exit, decay and the ratchet

| Rule | Value / behaviour | Consequence |
|---|---|---|
| Tier ends at the Seam boundary | The world tier is recomputed at every Seam entry (§1.3). A tier is never a permanent flag on the save. | A run can move up and down inside its act window. |
| **Tier ratchet** `✱` | The highest world tier witnessed in an Iteration becomes that Iteration's floor for Act 2 and later. It is consumed by Hard Unmaking, which rewrites the map. | The entity never "gets normal again". GDD-001 P4: escalation replaces gatekeeping. |
| `Hollowed` forced rise ends at sector end | Per SYS-001 §1.5 `Hollowed`. It never persists into the next Seam as a free ratchet. | A player who chooses a Hollowed sector pays for one sector, not the run. |
| Personal override ends on its own timer | SYS-001 §1.5 `MADNESS-5` row (20 s, −1 Composure), and LOOP-001 MADNESS-13 extends it. The world keeps warping throughout. | *Clear Eyed* is a window of legibility, not a cure. |
| Act 0 never returns | Ending 5 (GDD-001 §9.3 *The Pretence Kept*) is an ending, not a T0 sector. | The costume cannot be put back on; that is what the ending *means*. |
| T5 never exits inside Act 4 | T5 holds to the last Seam. The only T5 exit is the run ending or the Iteration ending. | Act 4 is a one-way descent; SYS-001 §8 save cadence at Seam boundaries makes that survivable. |
| Hard Unmaking clears the board | The tier resets to the act floor, the map rewrites, Hunger rises (SYS-001 §2.2), and the ratchet is consumed. | Losing to the clock is a story beat, not a punishment (GDD-001 §6.2). |

### 1.6 What Composure does (SYS-001 §1.5)

| Question | Answer |
|---|---|
| Does Composure set the world tier? | Only at 0: the `Hollowed` forced rise (SYS-001 §1.5, GDD-001 §8.6). Otherwise Composure changes what the warp *feels like*, not which tier the kit is keyed to. |
| Does Composure make the warp worse for everyone? | It sets band magnitudes: false audio cues, chromatic edge, the Compass lie, the inverted-axis burst, phantom geometry (all magnitudes are SYS-001 §1.5 band rows). |
| Does the warp drain Composure? | Yes, one row: SYS-001 §1.5 `Warp Tier passive`, cited not restated. |
| Can a low Composure be good? | Yes by design: the MADNESS branch doubles at `Hollowed` (SYS-001 §1.5) and LOOP-001 MADNESS-10 extends that to Unmoored at T ≥ 3. GDD-001 §8.6 calls this the design inversion. |
| Can the warp take Composure without a tell? | No. Every Composure drain caused by a warp effect must be visible on the wick and in a Codex line at run end. `✱` No hidden sanity cost. |
| Can the warp kill the player by Composure? | No. `Hollowed` grants a free death rather than causing one (SYS-001 §1.5). Composure is never a death clock. |
| Does an eaten rule ever change Composure math? | Only by changing which SYS-001 §1.5 row applies (e.g. H12 removes the free Surgelight, whose cost that row already carries). Eaten rules never add an invisible drain. |

### 1.7 T5 — Unmaking, the endgame state

T5 is not a heavier tier. It is the tier at which the game stops hiding that reality is the boss.

| Property | Value at T5 |
|---|---|
| Where it exists | Act 4 only (GDD-001 §9.1), plus the scripted final Unmaking cinematic of Act 0, which is cinematic and generates no playable sector. |
| How it is entered | The Act 4 opening Seam generates at 5. Once per Chronicle, the T4→T5 rise is scripted (GDD-001 §8.4 phase 6). |
| What is true | The field is chunked (W5-01), sprites show their module ribs (W5-02), the CRT curvature reads as the entity's iris (W5-03), and the camera breathes (SYS-001 §9 `Zoom`). |
| The rule layer | The entity may eat a rule (SYS-001 §2.2 cadence, §3 here) and exposed rule-threads appear on its body (SYS-001 §2 phase 6), latched with Unravel Focus (GDD-001 §4.1 `R`). |
| Availability of the latch | Act 4 by default; from Act 3's first Seam with LOOP-001 MADNESS-17 (*Unravel Focus* capstone). |
| Thread economy | 3 rule-threads unmake the entity (SYS-001 §2 phase 6). The 5 **Threads of Unraveling** are the endgame currency of GDD-001 §7.1 and are not the same objects; this doc never spends one for the other. |
| What T5 never does | Never removes the last open exit vector; never spends banked currency; never hides the Awakening tell; never exceeds the effect cost budget (§5.2). |
| HUD at T5 | The HUD stops lying and re-forms as chalk on the hull (W5-08). At Unmaking the game has stopped pretending, so it has no reason to lie. The Steady Ledger toggle still works; it is simply redundant. |
| Silence budget | T5 strips music stems (W5-07) but the silence budget in GDD-001 §12 is not a warp resource; AUDIO-001 owns it and caps it at two per run. |
| How it ends | Run end, death, or Hard Unmaking. Never by a menu. |

### 1.8 The acceptance gate (GDD-001 §8.7, non-negotiable)

Every effect in §2, and every eaten rule in §3, is judged against all five criteria. Each row names its **primary** criterion — the one it is most likely to fail — so review has somewhere to push.

| ID | Criterion (GDD-001 §8.7) | How it is measured, not asserted |
|---|---|---|
| AC1 | Visible in a 15-second clip without context | A 15 s capture exists in the effect's evidence slot; 5/10 non-players asked "what is this?" (GDD-001 §17 criterion 6). |
| AC2 | Reversible or recoverable | There is a stated end to the effect, or a named restore path (§3.2), and a run-ending fallback. No effect may permanently destroy run progress (GDD-001 §8.9; SYS-001 §8). |
| AC3 | Never removes player agency for more than 1.5 s | The effect's `agency_window` field is asserted ≤ the SYS-001 §9 `Player agency loss` budget by the warp lint (§7.3). |
| AC4 | Always has counterplay | The `counterplay` field names a Pact, a Lantern Tree node (LOOP-001 §3.3) or a Run Sigil (LOOP-001 §4.2) that exists in that build. The lint fails on a dangling ID. **H14 is the one declared exception** (§3.4): it has no restore by design, so its counterplay is the steering rule rather than an ID, and the lint checks it by another route (§7.3 L-06). |
| AC5 | Performance budget ≤ 1.2 ms/frame on minimum spec | Measured against SYS-001 §9 `Frame budget (min spec)` with the tier's whole effect set live (§5.2). |

**Warp Effect Budget** (GDD-001 §16 R-02), written as a rule the generator can enforce:

| Rule | Value |
|---|---|
| Novel transient effects per sector | 3 (GDD-001 §16 R-02) |
| Standing effects per sector | Uncapped, but tier-fixed and costed in §5.2 |
| Repeat of a seen transient effect | Allowed, consumes no budget, costs 0.25 budget units `✱` so a sector can never be nothing but repeats |
| Simultaneous transient effects | 2 at once maximum `✱`; a third queues until the first ends |
| Eaten rules | Not transient. They are standing rules of the sector and are budget-exempt, but each must clear AC1–AC5 individually. |
| The Awakening and the Unmaking | Scripted beats, budget-exempt, capped by GDD-001 §12's silence rule and the §1.4 entry rules |

### 1.9 Hard guards

These bind every row in §2 and §3. The warp lint (§7.3) fails the build on any violation.

| Guard | Statement |
|---|---|
| **Agency** | No effect may deny the ability to act longer than the SYS-001 §9 `Player agency loss` budget. Movement, aim and fire are never simultaneously disabled. |
| **Inverted input is not agency loss** | Ruling: the SYS-001 §1.5 Unmoored `one control axis inverts` burst is authored as a 4 s inversion, which exceeds a literal reading of GDD-001 §8.7 AC3. WARP-001 reads AC3 as inability to act, not input at a disadvantage, and bounds it: one axis only, never two `✱`; never during the Awakening stagger window `✱`; LOOP-001 MADNESS-3 shortens it; Steady Ledger does not remove it because it is a difficulty effect, not a presentation one. Flagged for GDD/SYS confirmation (§9.2). |
| **No permanent run loss** | Nothing here can destroy banked currency, the Lantern Tree, the Codex, iteration count or Fragments (SYS-001 §8; GDD-001 §6.2 anchored state). |
| **Structural locks are not eatable** | The 13 Unravel hits on a complete entity, the 5-Seam run, the one-hit hull default, contact-death-only Rampage, save cadence, and "Hunger never reduces player currency" are never eaten, mutated or bypassed by any warp effect (SYS-001 §1.4, §6, §2 phase 5, §8, §7.4; GDD-001 §8.1, §8.4, D-08). |
| **Locked rows may be eaten only through the registry** | A warp effect may suspend a `🔒` SYS-001 behaviour row only if it is a §3.2 registry row, it has a named restore path, and the locked value returns as the default. Base values remain the default at Hunger 0. |
| **Score never buys in-run power** | Cited not restated: SYS-001 §7.1. The `Warp multiplier` pays Ember outside the run; no warp effect converts score into in-run power (GDD-001 §3 anti-pillar). |
| **No gore, no jumpscares, no QTE** | Dread devices are limited to scale, symmetry-breaking, wrong-count limbs, faces in the wrong place and the ordinary-but-wrong (GDD-001 §11). No effect may require a timed input press to survive. |
| **No unearned information loss** | Any effect that hides a state must leave one redundant channel for the same state (§4.6). |
| **No soft-lock** | An effect may never close the last open exit vector, and the SYS-001 §4 `Solvability lint` must pass after the effect is applied. |
| **Silence is budgeted** | The warp may not spend GDD-001 §12's silence beats; AUDIO-001 caps them at two per run. |
| **Accessibility overrides the costume** | Steady Ledger and photosensitivity may not be eaten, disabled or downgraded by any warp effect or eaten rule (GDD-001 §10). |
| **Mercy is invisible and untouched** | The SYS-001 §8 re-roll mercy may not be warped: a re-rolled kit is never re-keyed to a higher tier than the Seam that re-rolled it. `✱` |

---

## 2. Per-tier effect registry

**Conventions.** `Class` is *standing* (always on at that tier, budget-exempt) or *transient* (scheduled or triggered, budgeted at 3 novel per sector). A higher tier keeps the lower tier's standing set in reduced-cost variants (§5.2). `Primary AC` is the criterion the row is most likely to fail; every row must pass all five (§1.8). Effects are authored content, so their names are this doc's; the mechanics cite SYS-001 rows rather than restating values. `✱` marks a new parameter.

### 2.1 T0 — Pretence (9 effects, Act 0 only)

| ID | Class | Effect | Trigger | What changes in play | Counterplay | Art / audio hand-off | Primary AC |
|---|---|---|---|---|---|---|---|
| W0-01 | standing | Cabinet Frame | Act 0 always | Bezel, scanlines and a 256×304 portrait costume crop the field (TECH-001 §1.1): the crop is the cabinet screen inside a native-resolution printed bezel (owner, 2026-11-18; the bezel leaves at the Act 0 zoom-in). No gameplay change; the crop must never hide a Choir unit or an exit vector. `✱` | none required — no hazard (AC4 satisfied trivially) | ART-001 bezel and scanline kit; AUDIO-001 chiptune stem, arcade chime set | AC1 |
| W0-02 | standing | Honest Ledger | Act 0 always | Every HUD element sits at its home anchor and tells the truth (§4.1). Sets the baseline the later tiers betray. | none required | UI: chalk-and-brass strip, 64×64 modules (GDD-001 §10) | AC1 |
| W0-03 | standing | Attract Mode | 30 s idle on the title screen | A demo loop runs; any input ends it and starts the Vigil (GDD-001 §10 three-clicks-max). | any key or button | ART-001 attract frames; AUDIO-001 attract loop | AC5 |
| W0-04 | standing | 1UP and score strip | Act 0 scoring (SYS-001 §7.1) | Extra-life feedback exists and reads as arcade furniture; from Act 1 on the strip becomes the Vigil Index. | none required | UI type set; AUDIO-001 score chimes | AC1 |
| W0-05 | standing | Cold Sepulchre Read | Act 0 A0-1 | The Sepulchre is visible and unlit; the race is legible before it is dangerous (SYS-001 §2 phase 0). | none required | ART-002 Sepulchre kit, cold variant; no chant stem | AC1 |
| W0-06 | transient | First Crack | A0-2, scripted, once | One chant line under the music. No visual or mechanical change. | none required; a visual chant indicator must exist for it (GDD-001 §10) | AUDIO-001 first chant line; UI caption line | AC1 |
| W0-07 | transient | Pretence Tear | A0-3, scripted, once | The cabinet frame tears and the score strip stops parsing for the 90 s cinematic (GDD-001 §6.1). Agency window 0 s: input is not required and none is lost. | skippable after the first watch (GDD-001 §6.1, §10 no-QTE skip) | ART-001 frame-tear shader; AUDIO-001 first Unmaking sting (inside the silence budget) | AC3 |
| W0-08 | transient | Costume Removal | The T0→T1 rise | The CRT curvature drops and the black vacuum gives way to the aether: colour, fog and drifting life rise into the field (ART-001 §16, amended 2026-11-18; replaces "desaturation begins"). The player never sees a menu explaining it (GDD-001 §3 design rule). | none required | ART-001 tier ramp 0→1; AUDIO-001 stem crossfade | AC1 |
| W0-09 | standing | Honest Seam | Act 0 torus wrap (GDD-001 §4.2) | The field wraps at the edges and every open seam is drawn in chalk `✱`, so the later one-way rule (H2) is felt as a theft rather than a new mechanic. | none required | ART-002 chalk seam decal; AUDIO-001 seam chime | AC4 |

### 2.2 T1 — Frayed (10 effects)

| ID | Class | Effect | Trigger | What changes in play | Counterplay | Art / audio hand-off | Primary AC |
|---|---|---|---|---|---|---|---|
| W1-01 | standing | Wrong Three | T1 sector start | The aether's colour fields settle (ART-001 §16) and three hues arrive that do not belong to any ramp the player has learned (GDD-001 §8.7, §11 ramp rule). Value contrast is preserved so colourblind play is unaffected (ART-001 §4). | none required; colourblind-safe variants ship in the same ramp (GDD-001 §10) | ART-001 tier 1 palette table | AC5 |
| W1-02 | standing | Breathing | T1 sector start | Idle sprites scale by ±1 px on a slow cycle `✱`. Purely visual: hitboxes never move (SYS-001 §9 `Hitbox policy`). | none required | ART-002 idle rig; no audio | AC5 |
| W1-03 | standing | Parallax Arrives | T1 sector start | Parallax layers appear behind the field. Camera rules are untouched: player-centred, no drift at T1 (SYS-001 §9 `Camera follow`). | none required | ART-001 parallax plates | AC5 |
| W1-04 | transient | Phantom Grub | A Deacon of Lies casts one (SYS-001 §3) | A harmless false Grub appears and drains its band's Composure on first sight. It is a hazard and it is counterplay at once. | LOOP-001 MADNESS-6, WARD-7, SIG-M-03; SYS-001 §3 Phantom dispel rules | ART-002 Grub silhouette with a deliberate wrong-count limb; AUDIO-001 keening detune | AC1 |
| W1-05 | standing | Teeth in the Rock | T1 sector start | Geode faces read as teeth. Mining math is unchanged (SYS-001 §1.3); this is dread bought with art. | none required | ART-002 geode swap set | AC1 |
| W1-06 | standing | Chromatic Edge | Composure in the Frayed band (SYS-001 §1.5) | The frame edge splits to its band magnitude. Information is unaffected; the effect sits on the frame, never on a hitbox or a blip. | LOOP-001 HULL-11 halves Frayed magnitudes | ART-001 edge split shader; AUDIO-001 detuned ambience | AC5 |
| W1-07 | transient | False Chant | Frayed band cue rate (SYS-001 §1.5) | A chant line plays from a direction with no procession in it. Positional audio is a real channel, so a false cue is a real cost. | LOOP-001 MADNESS-1 turns false cues toward the true Sepulchre | AUDIO-001 chant stem, positional | AC4 |
| W1-08 | standing | Chant Under Music | T1 sector start | The chiptune gains a buried choral stem (GDD-001 §12). Subtitles and visual chant indicators are mandatory, not optional (GDD-001 §10). | none required | AUDIO-001 decomposition stem 1 | AC1 |
| W1-09 | transient | Smudged Blip | T1, one per sector `✱` | A Compass blip lags its true position by a short interval `✱` and renders smeared. Delayed truth, not a lie; it is drawn smeared so the player can tell. | LOOP-001 HULL-2 chalk-struck readouts; LANTERN-4 honest ring | UI smear glyph; AUDIO-001 soft glass tick | AC1 |
| W1-10 | transient | Ledger Smudge | T1, one per sector `✱` | One digit in the Vigil Index strip renders as the wrong glyph while the underlying value stays correct. The player learns the strip can be wrong before it lies. | none required; Steady Ledger pins the strip honestly (§4.4) | UI glyph corruption set | AC1 |

### 2.3 T2 — Bleeding (10 effects)

| ID | Class | Effect | Trigger | What changes in play | Counterplay | Art / audio hand-off | Primary AC |
|---|---|---|---|---|---|---|---|
| W2-01 | standing | Split Palette | T2 sector start | The field splits into bioluminescent and bruise registers (GDD-001 §8.7, §11). The amber/brass player palette never appears on Choir assets, and the rule is never broken by the split. | none required | ART-001 tier 2 palette table | AC1 |
| W2-02 | standing | Shroud Growth | T2 sector start | Shroud cells tile the field as hazard terrain (SYS-001 §9 `Shroud`). Movement is blocked; the cell is cleared by Ward or Surgelight per that row. | LOOP-001 WARD-4, LANTERN-2, LANTERN-12; SYS-001 §9 clear rules | ART-002 Shroud kit; AUDIO-001 wet cloth ambience | AC4 |
| W2-03 | standing | Wrong Count | T2 sector start | Modular units gain or swap limbs at runtime (GDD-001 §11, ART-002). A swap never changes a hitbox or a stat (SYS-001 §9 `Hitbox policy`). `✱` | none required | ART-002 limb slot table; AUDIO-002 chitin creak | AC1 |
| W2-04 | standing | Consecration | Choir activity, T2 rates (SYS-001 §6 `Corruption: geode → Shrine`) | Unattended geodes become Shrines, then bruises, then Hollow. The war layer becomes visible in play. | LOOP-001 WARD-10 Deconsecrate, SIG-W-11 Toll, SIG-W-06 Shrine Lens | ART-002 Shrine kit; AUDIO-001 mournful sting (in the budget) | AC4 |
| W2-05 | standing | Bruise Bloom | Corruption crosses a shrine threshold (SYS-001 §6) | The macro map shows an advancing bruise; a Hollow sector is drawn black. Information, not hazard. | LOOP-001 SIG-W-11, WARD-10 | ZONES-001 macro map art | AC1 |
| W2-06 | transient | Whisper Line | T2, once per sector | One entity line names something true about the sector (GDD-001 §12 voice-as-state). Never a warning that a jumpscare follows. | LOOP-001 SIG-M-10 Ninth Whisper formalises the channel | AUDIO-001 whisper set; big-type subtitle (GDD-001 §10) | AC1 |
| W2-07 | standing | Boiling Rim | T2 sector start | The light pool's rim boils. Radius and mining math are the SYS-001 §1.2 rows, untouched. | none required | ART-001 light-pool shader variant | AC5 |
| W2-08 | standing | Chant Through Walls | T2 sector start | Chant audibility through geometry is extended beyond the SYS-001 §3.1 row by a fraction `✱`, so a procession can be heard around a corner more reliably. | LOOP-001 SIG-M-06 halves chant Composure cost; visual chant indicator always | AUDIO-001 positional chant bus; occlusion profile | AC1 |
| W2-09 | standing | Flame Bearing | T2 sector start | The Vigil's flame leans toward the nearest Sepulchre `✱`. Free diegetic information; it is the redundant channel that keeps compass lies survivable. | none — it is the counterplay | ART-002 flame module tilt; AUDIO-001 flame gutter | AC1 |
| W2-10 | transient | Hull Chatter | T2, once per sector `✱` | The ship's own module slots creak and chalk-scratch (GDD-001 §12 foley). No mechanical effect; the Codex logs one entry so dread pays knowledge (GDD-001 §8.9). | none required | AUDIO-001 foley set; NARR-001 Codex entry | AC4 |

### 2.4 T3 — Unbound (10 effects)

| ID | Class | Effect | Trigger | What changes in play | Counterplay | Art / audio hand-off | Primary AC |
|---|---|---|---|---|---|---|---|
| W3-01 | standing | Edge-Warp Roulette | T3 Seam entry | Which edge connects to which is re-keyed per Seam (GDD-001 §8.7). Non-adjacent edges link; a link never drops the player into a locked area and never removes the last open vector (§1.9). | LOOP-001 LANTERN-4 Wick Ledger marks exits, SIG-S-03 Cartographer | ART-002 seam decals per link pair; AUDIO-001 seam chime per pair | AC2 |
| W3-02 | transient | Compass Lie | SYS-001 §6 `Ledger Compass` lies at T ≥ 3 or Composure ≤ 3 | One lie per sector: a blip that disagrees with the state. The lie is always legible and always leaves §4.6's redundant channel. | LOOP-001 HULL-2 chalk strike, LANTERN-17 The Ninth Lantern | UI lie glyph | AC4 |
| W3-03 | transient | Gravity Inversion | One per sector `✱`, kit-defined region | A bounded drift field pushes across a region. Control is never taken; the field is drawn and predictable. | LOOP-001 HULL-1, HULL-7 (drag rows), SIG-H-02 Ballast | ART-001 field advection streaks | AC3 |
| W3-04 | standing | Bounded Drift | T3 sector start | Camera drift is permitted, capped at the SYS-001 §9 `Screen shake` budget and re-centred within one second `✱`. GDD-001 §3 P5 wins: input latency and follow constants are untouched. | none required; photosensitivity mode freezes drift entirely (§4.5) | none | AC3 |
| W3-05 | transient | Migrating HUD | T3, dwell `✱` 6 s | An HUD element slides to a new anchor for a bounded interval. Position only: values stay correct. Steady Ledger pins it. | LOOP-001 SIG-M-11, Steady Ledger (§4.4) | UI slide track; AUDIO-001 chalk scrape | AC1 |
| W3-06 | transient | Phantom Geometry | Unmoored band (SYS-001 §1.5) | Non-blocking false terrain appears. It never occupies a real corridor and never blocks an exit. | LOOP-001 WARD-7, MADNESS-6; SYS-001 §1.5 band rows | ART-002 false kit silhouettes | AC3 |
| W3-07 | transient | Borrowed Sky | T3, one per sector `✱` | The Compass shows a Hollow sector that does not exist this Iteration. A legible lie about the macro map; reading it in the Codex reveals the tell. | LOOP-001 SIG-S-18 Archive Seal; HULL-2 | ZONES-001 macro map; NARR-001 entry | AC2 |
| W3-08 | transient | Turned Wheel | Unmoored band (SYS-001 §1.5) | One control axis inverts for the band's authored burst. Bounded by §1.9: one axis, never two, never in the stagger window. | LOOP-001 MADNESS-3 Tremor Hand | UI: the affected key glyph inverts, so the fault is legible as external | AC3 |
| W3-09 | transient | Your Own Shape | A Deacon of Lies mimics at T ≥ 3 (SYS-001 §3) | A fake Vigil appears. It cannot fire; the tell is in the module slots, which copy the previous run's build rather than the current one `✱`. | LOOP-001 WARD-11 Salt Lantern reveals it; MADNESS-6 | ART-002 mirror rig; AUDIO-001 detuned foley | AC1 |
| W3-10 | standing | Seam Echo | T3, replay-derived | Ghosts of the last run's final 10 s of movement drift through the field, harmless (SYS-001 §8 telemetry). Never damages, never masks a unit. | none — it is information about how you died | ART-002 ghost render; AUDIO-001 distant foley | AC3 |

### 2.5 T4 — Inverted (10 effects)

| ID | Class | Effect | Trigger | What changes in play | Counterplay | Art / audio hand-off | Primary AC |
|---|---|---|---|---|---|---|---|
| W4-01 | standing | Inside the Lamp | T4 sector start | The background becomes the inside of the Vigil: ribs, brass, a guttering flame where space was. Movement and hitboxes are untouched. | none required | ART-001 interior plates; AUDIO-001 interior ambience | AC1 |
| W4-02 | standing | Mundane Skins | T4 sector start | Choir silhouettes re-skin as ordinary objects — a lamp, a face, a window (GDD-001 §8.7, §11). Readability is protected: value contrast and faction palette rules hold, and a unit's palette may never match the player's. | LOOP-001 SIG-M-03 Chalk Saint sketches warp geometry first | ART-002 mundane re-skin set; AUDIO-001 household foley on Choir actions | AC1 |
| W4-03 | standing | Corrupt Type | T4 sector start | UI text corrupts at the edges while remaining readable; no line of copy may fall below two-thirds legibility at 100 % scale `✱`. | Steady Ledger (§4.4); text scaling to 200 % (GDD-001 §10) | UI corruption track | AC4 |
| W4-04 | transient | Eaten Element | T4, one per sector (GDD-001 §8.7) | The entity takes one HUD element for a sector (§4.3 table). It returns at Seam end and always has an honest stand-in while eaten. | Steady Ledger; LOOP-001 LANTERN-17 | UI: the element's frame is left in chalk, empty | AC2 |
| W4-05 | standing | The Grub Strike | **Entropy 7 only** (SYS-001 §4 `E7`) | GDD-001 §8.7 names "Grubs can now hit you" as a T4 rule flip. WARP-001 delivers it only through the SYS-001 §4 E7 row, which is a locked, opt-in rule break, so a player can never be surprised by a Choir unit striking who did not opt in. | Player-selected; LOOP-001 SIG-H-09, WARD family | ART-002 Grub strike tell: a raised forelimb, 12 frames `✱` | AC4 |
| W4-06 | transient | Light Bites | T4, one per sector `✱` | The light pool's rim damages Choir units at the rim at a slow authored rate `✱`, expressed in lance-hit equivalents per SYS-001 §3's HP convention. | none — it is a benefit; the cost is that the light also draws them (SYS-001 §1.2 detection rows) | ART-001 rim scorch; AUDIO-001 sizzle | AC1 |
| W4-07 | transient | Eaten Pause | T4, scripted once per sector at most, Act 4 only for the full sequence (§6.2) | Esc opens a screen that is not the pause screen (GDD-001 §4.1 note). Play input is never blocked; only the menu is refused. | Accessibility pause setting (§4.4) always honours Esc; the Codex records the sequence | UI: a chalk frame that will not fill; AUDIO-001 one dead click | AC3 |
| W4-08 | transient | Borrowed Voice | T4, one line per sector `✱` | The HUD types one line in the entity's big type (GDD-001 §10). LOOP-001 MADNESS-18 gives the player the same channel back. | LOOP-001 MADNESS-18 The Ninth Sky Looks Back | UI big-type set; AUDIO-001 voice channel | AC1 |
| W4-09 | transient | Turned Bearing | T4, one per sector `✱` | The Ledger Compass rotates to a false bearing for a bounded interval. The player's own position stays true, and the Flame Bearing channel (W2-09) still points correctly. | Steady Ledger; LOOP-001 LANTERN-4 | UI bearing ring re-skin | AC4 |
| W4-10 | standing | Stems Eaten | T4 sector start | The arcade chiptune stems are removed for the sector (GDD-001 §12 decomposition). Chant is diegetic and the visual chant indicator is mandatory, so silence never costs information. | LOOP-001 SIG-M-10, SIG-W-12; subtitles | AUDIO-001 stem removal map; visual chant indicator | AC1 |

### 2.6 T5 — Unmaking (10 effects)

| ID | Class | Effect | Trigger | What changes in play | Counterplay | Art / audio hand-off | Primary AC |
|---|---|---|---|---|---|---|---|
| W5-01 | standing | Chunked Field | T5 sector start | The field breaks into drifting plates with gaps of nothing between them. Geometry stays passable exactly as generated; the drift is drawn, never applied to hitboxes. | LOOP-001 SIG-H-03 Light Frame, LANTERN-9 | ART-001 plate break shader (cost: §5.2) | AC5 |
| W5-02 | standing | Ribs | T5 sector start | Sprites show their 64×64 module skeleton (GDD-001 §8.7; ART-002; SYS-001 §2.1 body geometry). A unit's hitbox is the sprite alpha per SYS-001 §9 `Hitbox policy`, so the ribs are the honest version of the art. | none required | ART-002 skeleton render pass | AC1 |
| W5-03 | standing | Iris Curvature | T5 sector start | The CRT curvature resolves into the entity's iris and tracks slowly. Pure presentation; the view is never obscured beyond the §4.6 redundant-channel rule. | Steady Ledger pins the frame; photosensitivity freezes the track | ART-001 curvature shader | AC5 |
| W5-04 | standing | Breathing Zoom | T5 sector start | The camera breathes per the SYS-001 §9 `Zoom` row. Photosensitivity substitutes a fixed zoom with a Sepulchre approach marker so the information stays. | §4.5 parity table | none | AC5 |
| W5-05 | standing | Rule-Threads | Act 3–4, SYS-001 §2 phase 6 | Exposed threads appear on the entity and are latched with Unravel Focus (GDD-001 §4.1 `R`). Latch time is the SYS-001 §2 row; 3 threads unmake it. | LOOP-001 MADNESS-17 unlocks the latch in Act 3 and shortens the latch; Pacts may pre-attach threads (LOOP-001 §7, requested §3.3) | ART-002 thread rig; AUDIO-001 thread snap | AC1 |
| W5-06 | standing | The Rule Is Eaten | SYS-001 §2.2 cadence; registry §3.2 | The entity eats a rule. The registry decides which, when and how it is restored. | Per-row restore path in §3.2 | UI: the eaten rule is struck through in the Codex margin `✱` | AC2 |
| W5-07 | standing | Stem Collapse | T5 sector start | Music stems fall away to near-silence (GDD-001 §12). Chant and foley remain, and every state remains visible. | Subtitles and visual chant indicators (GDD-001 §10) | AUDIO-001 stem map; silence budget is not warp-spent | AC1 |
| W5-08 | standing | Chalk HUD | T5 sector start | The HUD stops lying and re-forms as chalk on the hull: honest, hand-drawn, unmoving. | none — the game has stopped pretending | ART-001 chalk UI set | AC1 |
| W5-09 | standing | Sigil Threads | T5, run-derived | The run's Run Sigils render as threads on the Vigil and can be read off it (LOOP-001 §4.1 "stamped onto the Vigil"). Your Own Vigil mirrors the same read (SYS-001 §5.1). | none — it is information about yourself | ART-002 thread overlay per Sigil art | AC1 |
| W5-10 | transient | Unmaking Counter | T5, entity encounter | A visible tally of threads drawn and hits landed appears near the entity, and it never hides or penalises. Score is telemetry, never in-run power (SYS-001 §7.1). | none required | UI tally strip; AUDIO-001 bell per thread | AC4 |

---

## 3. The eaten-rule registry

Nine rules. One table. The entity eats them in the order written, keyed to the Hunger levels SYS-001 §2.2 already carries, and each eat has one named restore path except H14, which has none and is designed to have none.

This section discharges the promise SYS-001 §2.2 makes when it says an eaten rule arrives every 2 Hunger. It also discharges GDD-001 §8.7's Act-3 promise that at least one rule the player trusted is gone by Act 3.

### 3.1 The eaten-rule contract

| Element | Statement |
|---|---|
| ID form | `H` + the Hunger level at which the eat first becomes legal: H2, H4, H6, H8, H10, H12, H14, H16, H18. Cadence is SYS-001 §2.2's row, cited not restated. |
| Namespace | SYS-001 §2.2 also keys its counter-behaviour table to Hunger levels (H4, H6, H8, H10). Those are Choir *behaviour* rows; a registry `H` ID is a *rule* row. Where both are legal at the same level, both are true. Code and lint refer to the rule as `RULE-H4` and to the counter as SYS-001 §2.2 `H4`. A conformance correction is requested (§9.2 C-01). |
| Eligibility | An eat fires at the first Seam entry where: Hunger ≥ the rule's level, the world tier ≥ the rule's minimum tier, and the act permits that tier (§1.3). It never fires in the first 2 s of a Seam (§1.4). |
| Deferral, never downgrade | If the Hunger level is met but the tier is not, the eat waits. It is never run at a lower tier for the sake of the schedule. An eat is Unmaking-grade theatre, and an Unmaking-grade beat at T2 is a bug, not a cheap beat. `✱` |
| One eat per Seam `✱` | At most one registry eat per Seam. Two simultaneous eats are unreadable and would spend the sector's whole novelty budget. |
| Telegraph first | One Seam before an eat, the entity speaks the eat: a Codex-ready line plus one drawn foreshadowing of the rule it is about to take (AUDIO-001, NARR-001). §1.4 already places the first Act-3 telegraph before the tier does. `✱` |
| Announcement law | No menu banner, no tutorial toast, no pause-screen list (GDD-001 §3 design rule: the game never announces a layer). The eat is announced diegetically, in four channels at once: the world state visibly changes; the entity says one line; the Codex marks the old rule struck-through with the new rule under it; the HUD carries a tell in the chalk family (§4.2). Three of the four are required, the Codex entry is never optional. |
| Legibility floor | The eat must be noticeable by a player who reads nothing. §7.2 asserts this per rule with a no-reading pass line. |
| Restore scope | Default: a Pact restores its rule **for the run in which the Pact is held**; when the Pact lapses the rule returns to eaten. LOOP-001 may author a permanent variant; WARP-001 does not require one and does not price one. `✱` |
| Restore honesty | A restored rule returns the locked default exactly. A restore may not buff the rule, may not leave a residue of the eaten version, and may not be worse than the base rule while active. |
| Never eaten | §1.9's never-eaten set holds. A registry row may suspend a locked-row default only if it names its restore path in this section; H14 is the single documented exception to that and it suspends no locked row. |
| Solvability | Every eat must leave the SYS-001 §4 `Solvability lint` passing after it is applied, including the eat's own restriction. The lint is run against the eaten state, not the base state (§1.9 `No soft-lock`). |
| Agency | The eat's own moment is a presentation beat: agency window 0 s unless the row says otherwise, and never above SYS-001 §9 `Player agency loss`. |
| Composure | An eat never adds a drain. It only changes which SYS-001 §1.5 row applies (§1.6). |
| Score | An eat never changes SYS-001 §7.1's scoring rows. Losing a rule does not lower what a good run is worth. |
| Status column | Per-row and honest: authored, SYS rows outstanding, Pact IDs reserved. Nothing in this registry is claimed as built. |

### 3.2 The registry

| Rule ID | Hunger | Tier that eats it | Earliest legal act | What the player trusted | What replaces it | How the eat is announced diegetically | Named restore path | Status |
|---|---|---|---|---|---|---|---|---|
| **H2** — one-way torus wrap | 2 | T3, or above `✱` | Act 2 (A2 ceiling is 3, §1.3) | Edges connect both ways forever, and every open seam is drawn in chalk (GDD-001 §4.2, W0-09). At T3 which edge links to which is re-keyed per Seam (W3-01), but a crossing was always reversible. | Crossing is still free. The seam you came through closes **20 s** after your crossing (`seam_close_after`, **SYS-001 §6** — the row landed on 2026-11-17, so this is no longer this doc's number and a disagreement here is this doc's bug). While closed the boundary refuses the crossing and the Vigil slides along the edge, agency 0 s. Seams re-open at the sector boundary; a closed seam is never a permanent wall. All of W3-01's re-keying still applies on top. | The chalk seam on the far side of the field goes dark and narrows as the 20 s runs; the last chalk pixel goes out with a guttering sound (AUDIO-001 seam chime, reversed). The entity says the crossing line (NARR-001 §7 set, one line per eat). The Codex strikes *two-way wrap* and writes the one-way rule under it. | **PACT-01** — restores two-way wrap: no seam closes while the Pact is held (LOOP-001 §5; request §3.3). | authored · SYS row requested (§8 R-01) · PACT-01 reserved |
| **H4** — shard magnetism inverts | 4 | T3, or above `✱` | Act 2 | Shards come to you. The magnet radius is SYS-001 §1.4 `Shard magnet radius`, widened by `Hookline`; mining has always been a matter of parking near the break. | The same radius, the opposite sign: Mourning Glass is **repelled within 96 px** of the Vigil. Any radius-modifying row in SYS-001 §1.4 inherits its value and flips its sign, so a `Hookline` build is repelled from 190 px instead. Collection still needs contact; overflow shards still stay in the world (SYS-001 §1.4). Mining is unchanged (SYS-001 §1.2, §1.3): you mine from outside your own pull-circle. | A pale ring the size of the magnet radius appears around the Vigil and shards skid outward off it; the Charge-pip strip renders mirrored for the sector as the tell (§4.2 tell family). The Codex strikes *shards come to you*. | **PACT-04** — restores attraction at the base radius while held (LOOP-001 §5). | authored · PACT-04 reserved |
| **H6** — lantern detection semantics flip | 6 | T4, or above `✱` | Act 3 | Lantern up is loud, lantern down is quiet: the pair of detection rows in SYS-001 §1.2, widened by *Dark Lantern* (LANTERN-5). The whole stealth axis rests on which state you are in. | The pair is replaced by the registry pair: **lantern down +40% detection, lantern up −20%**. Composition order is fixed so the code has one answer: SYS-001 §1.2 base rows → upgrades, Run Sigils and branch modifiers → the registry pair, which replaces the pair it modifies rather than multiplying it. `*Dark Lantern*` and LANTERN-5 keep applying to the active pair. | The Choir stops facing your light and turns into your shadow; a lantern-down field draws a pale moth-halo around the Vigil's lamp module (ART-002). The Lantern-state key glyph is drawn upside-down as the tell, the same convention W3-08 uses for a borrowed control (W1-10 family). The Codex strikes *the dark hides you*. | **PACT-07** — restores the SYS-001 §1.2 detection pair while held (LOOP-001 §5). | authored · PACT-07 reserved |
| **H8** — over-fire no longer detonates | 8 | T2, or above `✱` | Act 2 | The SYS-001 §1.3 `Over-fire detonation` rule: nine hits in 1.2 s on one face pops it and scatters 3–5 shards. Fast mining, and the Censer Cardinal puzzle is built on it (SYS-001 §5.1). | Over-fire still registers — hits count, the face still shatters on the normal schedule (SYS-001 §1.3 `Time to shatter`) — but it never detonates. Instead the geode **eats one Mourning Glass shard**: 1 Charge leaves the magazine (SYS-001 §1.4 `Charge magazine`); if the magazine is empty, one shard already in the world is consumed. A shard is paid for every burst, so fast mining becomes rationed mining. | The geode faces stop cracking open and shut instead — W1-05 *Teeth in the Rock* finally bites, at zero art cost — and the glass chime plays backwards as the shard is taken (AUDIO-001). The Codex strikes *hit it fast, it bursts*. | **PACT-10** — restores the SYS-001 §1.3 over-fire detonation while held, with no shard cost (LOOP-001 §5). | authored · PACT-10 reserved |
| **H10** — the Arc-Lance cannot damage Oubliette Grubs | 10 | T4, or above `✱` | Act 3 | Grubs have 4 HP and die to lance fire (SYS-001 §3). Clearing a nest is a two-second errand, and the score table pays 150 for one (SYS-001 §7.1). | Lance shots pass through Grubs with a soft chime and no hit flash. Grub HP, speed, carry behaviour and the score row are untouched — the rule says the lance cannot do it, not that they are immortal. They still die to a geode detonation and to the light rim (W4-06). Killing them stops mattering: what matters was never the Grub, it was the deposit. The counterplay is the one the fiction already owns — a salt ward blocks a deposit for 30 s (SYS-001 §2 phase 0), the Ward Pulse interrupts, and LOOP-001 WARD-6 *Silence the Choir* is built for this exact sentence. | Grubs gain a chalk halo module and nothing else — silhouette language only, hitboxes untouched (§1.9). Shots read as a pass-through with a bell rather than a hit flash. The entity says the holiness line (NARR-001 §7). The Codex strikes *you can kill anything*. | **PACT-13** — restores lance damage against Grubs while held (LOOP-001 §5). | authored · PACT-13 reserved |
| **H12** — the Surgelight stops being free and stops clearing Shroud | 12 | T4, or above `✱` | Act 3 | Two guarantees at once: the SYS-001 §1.5 Surgelight cost row applies *at T ≥ 2*, so the boost has a stated free band, and the SYS-001 §9 `Shroud` row can be cleared by 1 Ward-slice **or** 1 Surgelight burn. | The tier condition is removed: the cost applies whenever the boost is used, and Shroud is cleared by **Ward only**. Inside an Act-3 or Act-4 sector the cost row already fires, so the felt loss is the Shroud half and the loss of the guarantee itself — the stated condition stops being true, which is the point of the eat. The Ward half of the SYS-001 §9 row survives, so the lint's unlit-corridor and escape-vector rows still pass. | The boost's glass arc scorches and does not cut: a Shroud cell touched by a Surgelight heals over rather than opens (ART-001 shroud scorch), and the Surge charge glyph (GDD-001 §4.1 `Shift`) gains a chalk strike. The wick dips visibly on every boost at every tier, which is where the player learns it (§1.6: no hidden drain). The Codex strikes *the light opens the dark*. | **PACT-16** — restores the free band and the Surgelight half of the Shroud clear while held (LOOP-001 §5). | authored · PACT-16 reserved |
| **H14** — one Run Sigil per run, chosen by the entity | 14 | T4, or above `✱` | Act 3 | Choose-1-of-3 at every Seam clear with one paid reroll (SYS-001 §7.2, GDD-001 §6.3, §7.3). The build is yours; three picks per run are your authorship. | One Sigil per run, granted when the first Seam of the run clears `✱`, chosen by the entity from the run's own legal pool weighted by the telemetry keys SYS-001 §8 already emits (`glass_hunted`, `charges_thrown`, `penitent_shot`, `hollow_sectors`): it gives you the tool it expects you to misuse. No reroll is *offered* — the offer is removed rather than disabled, so nothing greys out and nothing lies. The remaining picks are withheld, not lost. **Permanent: not restorable by anything** (§3.4). | The Sigil screen does not appear: the three cards never deal. Instead one card is placed face-up on the Chalk Desk by a hand that is not yours, and the entity names it aloud (AUDIO-001, NARR-001). The Codex entry for *choose one of three* is struck through in chalk and nothing is written under it — the blank is the announcement. | **None.** Not a Pact, not a Run Sigil, not a Lantern Tree node, not a Relic, not an Entropy setting, not an ending, not Steady Ledger and not photosensitivity. H14 is the registry's one irreversibility and §3.4 owns the ruling. | authored · no restore · GDD conformance note §9.2 C-04 |
| **H16** — the Ledger Compass cannot show the entity | 16 | T4, or above `✱` | Act 3 | The SYS-001 §6 `Ledger Compass` row: sector list plus entity marker. At T3 the marker may lie once per sector with a tell; under H16 it cannot represent the entity at all, lie or otherwise. | The entity marker slot is drawn and permanently empty — an honest absence, not a hidden one. The Compass keeps its sector list, its own-position readout (W4-09 keeps the player true) and its lie allowance. Positional information moves to the redundant channels §4.6 already names: the Flame Bearing (W2-09), chant and voice as positional audio (SYS-001 §3.1 chant row, AUDIO-001 voice-as-state), and the Unmaking Counter at the encounter (W5-10). | The marker frame is chalked out on the strip — the same chalk-frame family W4-04 uses when a whole element is taken — and the strip's legend glyph for the entity is struck through. The entity's voice becomes the primary long-range bearing channel for the sector (AUDIO-001 stem map). The Codex strikes *the Compass shows you where it is*. | **PACT-19** — restores the entity marker on the Compass while held, subject to the ordinary T3 lie allowance (LOOP-001 §5). | authored · PACT-19 reserved |
| **H18** — the entity cannot be unmade at the rule level until Act 4 | 18 | T4, or above `✱` | Act 3 | The SYS-001 §2 phase 6 row and GDD-001 §4.1 `R`: threads expose in Act 3–4, and LOOP-001 MADNESS-17 unlocks the latch from Act 3's first Seam. You can already begin the unmaking in Act 3 if you paid for it. | While H18 is active, threads do not expose and the latch is refused: pressing `R` on a body with no thread yields the burnt-out latch glyph, no Composure cost and no input lock. Charges still drive it off — SYS-001 §1.4 `Charge → entity` and the 13-hit count are untouched, and SYS-001 §2.1 `Unravel hits` still climbs with Hunger, which is the bite. H18 also lapses by itself at the Act-4 opening Seam: Act 4 *is* Unmaking (§1.3, §1.7). It is the registry's one scripted lapse; PACT-22 exists to buy the latch inside Act 3. | The thread sockets on the entity's body are drawn but sealed in chalk, and the `R` glyph burns out to ash when pressed (ART-002 thread rig, sealed variant; UI). The entity says the refusal line (NARR-001 §7). The Codex strikes *you can already begin* and writes Act 4 under it. | **PACT-22** — restores the rule-level latch while held, in Act 3 as well as Act 4 (LOOP-001 §5). | authored · PACT-22 reserved · lapses at Act-4 entry |

### 3.3 Pact requests to LOOP-001 §5

WARP-001 reserves eight Pact IDs of LOOP-001's twenty-four (GDD-001 §7.3). The price, the flavour, the risk and the Chalk Desk presentation of each Pact belong to LOOP-001 §5; this doc names only what the restore must do. Nothing here prices a Pact, and nothing here may be read as a LOOP-001 decision.

| Reserved ID | Registry row it restores | What "restored" must mean mechanically | Guarantee it must not exceed | Status |
|---|---|---|---|---|
| **PACT-01** | H2 | No seam closes after a crossing; the SYS-001 §4 escape-vector count is met by open two-way seams as in the base rule. | Must not widen W3-01's re-keying, must not re-open a seam that was closed by H2 before the Pact was taken in that sector `✱`. | reserved · price owned by LOOP-001 §5 |
| **PACT-04** | H4 | The SYS-001 §1.4 magnet row applies at its signed base value again, `Hookline` included. | Must not add magnet radius, must not auto-collect, must not pull shards through geometry. | reserved |
| **PACT-07** | H6 | The SYS-001 §1.2 detection pair applies again at its stated values, with the registry no longer replacing the pair. | Must not reduce detection below the base row; it returns a rule, it does not grant stealth. | reserved |
| **PACT-10** | H8 | SYS-001 §1.3 `Over-fire detonation` fires again, with no shard payment and with the shard-release range and scatter unchanged. | Must not raise the detonation threshold, must not grant extra shards. | reserved |
| **PACT-13** | H10 | The Arc-Lance damages Oubliette Grubs at SYS-001 §3's HP values again. | Must not reduce Grub HP, must not extend to other Choir units, must not remove the E7 opt-in attack rule. | reserved |
| **PACT-16** | H12 | The SYS-001 §1.5 Surgelight cost row regains its tier condition, and the SYS-001 §9 Shroud row again offers the Surgelight clear alongside the Ward clear. | Must not change the cost value, must not clear Shroud at range or over multiple cells per burn. | reserved |
| **PACT-19** | H16 | The Compass may show the entity marker again, subject to the ordinary SYS-001 §6 lie allowance at T ≥ 3. | Must not show the entity's phase, segment count or Waking state — those are §4.7 never-lies elements. | reserved |
| **PACT-22** | H18 | Rule-level unmaking is available: threads expose and Unravel Focus latches in Act 3 as well as Act 4, at SYS-001 §2 phase 6's latch time. | Must not pre-attach or spend a thread, must not reduce the 3-thread requirement or SYS-001 §2.1 `Unravel hits`, must not stack with itself. | reserved |

Requests that are not restores:

| Request | To | Statement | Status |
|---|---|---|---|
| Pre-attached threads | LOOP-001 §5 | W5-05 asks whether a Pact may pre-attach a rule-thread. Ruling in §6.1 D-03: it may, and a pre-attached thread counts as **already latched** — it does not lower the 3-thread requirement, does not reduce SYS-001 §2.1 `Unravel hits`, and does not expose a thread the entity has not exposed. The Pact registry is LOOP-001 §5; the LOOP-001 §7 citation in §2.6 is superseded by this row (byte-frozen, see §9.1). | ruled in §6.1 D-03 |
| Restore permanence | LOOP-001 §5 | §3.1's default is run-scoped restore. If LOOP-001 wants one Pact whose restore survives death, WARP-001 accepts it and asks only that the eaten state be re-announced on the next run so the player never mistakes it for base physics. | requested |
| Nine eat lines | NARR-001, AUDIO-001 | One telegraph line and one arrival line per registry row: 18 lines, plus the death-line vocabulary GDD-001 §10 asks for. The telegraph line must name the rule in the player's own vocabulary ("EDGES DO NOT GO BACK.") and never name a system. | requested |

### 3.4 The H14 ruling

| Item | Ruling |
|---|---|
| The exception | H14 is the only registry row with no restore path, and the only one whose eaten state survives death, Hard Unmaking and every ending short of the Chronicle's end. |
| What it does not touch | Banked currency, the Lantern Tree, the Codex, Iteration count and the run-ending fallback all survive it, because SYS-001 §8's invariants are not a rule the entity can eat. It removes a choice, not a possession. |
| Why it is not a soft-lock | A run under H14 still has a full legal build path: the entity's pick comes from the run's own legal pool, weighted by telemetry the player's own play produced. A player who wants a given build can steer the pick by playing the way that build plays. There is no unwinnable state and no reward loss (SYS-001 §7.4). |
| Why it is not hidden cruelty | It is the Act-3 thesis in one screen: the entity's power is not that it kills you, it is that it decides. The single withheld choice, announced by a hand that is not yours at the Chalk Desk, is worth more than nine of these. |
| GDD conformance | GDD-001 §3 lists a pity/choice guarantee for Run Sigils. H14 trades that guarantee, once, for a Chronicle-long statement. This doc rules that the trade is intended and bounded, and asks the GDD owner to footnote §3 with the exception (requested, §9.2 C-04). WARP-001 does not edit GDD-001. |
| Test consequence | H14's acceptance test is not "the player can undo it". It is "no tester reports an unwinnable run, and every tester can say which rule was taken" (§7.2 `TEST-H14-01`). |

---

## 4. The HUD under warp

GDD-001 §10 makes the HUD diegetic furniture: chalk, brass, an oil wick. That is not decoration, it is a threat model. If the HUD is drawn by the world, then the world can move it, lie with it and eat it — and the warp is exactly that world being wrong. This section owns the element inventory, the lie law, the eaten-element table, the two accessibility guarantees and the channels that keep information honest when a readout is compromised.

The HUD never becomes the difficulty. Difficulty comes from rules; the HUD only reports rules. Every entry below exists to keep that line enforceable by the warp lint (§7.3).

### 4.1 The element inventory and the anchor set

An element may only occupy one of eight named anchor slots. Movement (§4.3) is a move between these slots and nowhere else, so a migrating HUD is a bounded effect and never an unreadable one. Slots are named here; their pixel positions live in the UI layout data (TECH-001). `✱`

| Anchor slot | Occupant at T0 |
|---|---|
| `top-left` | Hourglass (run clock) |
| `top-centre` | Ledger Compass (sector list, entity marker) |
| `top-right` | Vigil Index (score, chain, Warp multiplier; 1UP furniture in Act 0) |
| `bottom-left` | Charge pip strip |
| `bottom-centre` | Seam index and Run Sigil read |
| `bottom-right` | Composure wick |
| `hull-frame` | Flame Bearing (W2-09), Sigil Threads (W5-09) |
| `encounter-frame` | Unmaking Counter (W5-10, entity encounters only) |

| Element | What it shows | Home anchor | Truth at T0 | First legal deviation | May be eaten? | Redundant channel for the same state |
|---|---|---|---|---|---|---|
| **Ledger Compass** | Sector list, open seams, geodes, Shrines, the entity marker; lies at `T ≥ 3` or Composure ≤ 3 (SYS-001 §6 `Ledger Compass`) | `top-centre` | Fully honest | W1-09 smeared blip at T1; W3-02 first true lie at T3; H16 removes the entity axis | No, not as a whole. H16 takes one axis and leaves the frame standing | Chant and voice as positional audio (SYS-001 §3.1 chant row; AUDIO-001), Flame Bearing (W2-09), the Unmaking Counter at the encounter |
| **Hourglass (run clock)** | The Hourglass Clock's remaining hand (GDD-001 §6.2). Its display surface is named here `✱`; its meaning is GDD-001's | `top-left` | Fully honest | Not yet deviated by any §2 effect. Under photosensitivity it is drawn as a numeric read (§4.5) | Yes, one sector, T4 only (W4-04). Never while the run clock is the only warning the clock is about to end — see §4.7 `run clock` exception | Sand-bleed vignette at the field edge tracking the same value `✱`; the kit rotation and entity cadence are unaffected |
| **Vigil Index (score strip)** | Score, chain bonus, Warp multiplier (SYS-001 §7.1); 1UP feedback in Act 0 (W0-04) | `top-right` | Fully honest | W0-07 stops parsing during the scripted cinematic; W1-10 wrong-glyph at T1 | Yes, T4 (W4-04). No stand-in required: score is telemetry, not a state the player acts on (SYS-001 §7.1) | None required (§1.9's information rule covers states the player acts on) |
| **Charge pip strip** | Charges in the magazine and the spares (SYS-001 §1.4 `Charge magazine`) | `bottom-left` | Fully honest | H4 renders it mirrored as a tell while the count stays correct | Yes, T4 (W4-04), with the chalk-tally stand-in: one hand-drawn stroke per Charge on the `hull-frame` `✱` | The load chime the player hears per Charge drawn (AUDIO-001), the chalk tally stand-in, the reload cadence felt in the hands |
| **Composure wick** | The Composure *band*, not a number (SYS-001 §1.5 Clear / Frayed / Unmoored / Hollowed) | `bottom-right` | Fully honest | Never lied about, never smeared, never moved by a lie. It may be displaced only by W3-05 | **No.** Never eaten — this is the channel §1.6 depends on for "no hidden drain" | The band's own mechanical symptoms (aim bloom, chromatic edge, the Compass lie) and the run-end Codex line (§1.6) |
| **Seam index** | Which of the five Seams this is, and how many remain (SYS-001 §6 `Seams per run` 🔒) | `bottom-centre` | Fully honest | Never | **No.** Structural lock (§1.9): a warp effect may not obscure how much run is left | The Chalk Desk deal count, the macro map's visited sectors (ZONES-001) |
| **Run Sigil read** | The run's Sigils, and the one Sigil H14 grants (LOOP-001 §4.1) | `bottom-centre`, right half | Fully honest | W5-09 re-keys its glyphs into threads; H14 changes who chose, never what is shown | No | The Sigil's own behaviour on first use; the threads rendered on the Vigil (W5-09) |
| **Flame Bearing** | The Vigil's flame leans toward the nearest Sepulchre (W2-09) | `hull-frame` | Present and honest from T2 on | Never lied about. It is itself the counterplay | **No.** It is a redundant channel, and §1.9 forbids removing the redundancy it grants | The Compass (when not eaten), chant direction |
| **Unmaking Counter** | Threads latched and hits landed during the entity encounter (W5-10) | `encounter-frame` | n/a at T0 | Never hidden and never penalised, per its own row | **No** | Thread sockets visible on the entity (ART-002 thread rig) |
| **Big-type channel** | One line typed in the entity's big type (W4-08); MADNESS-18 gives the player the same channel | screen edge, fixed band | Unused at T0 | Never corrupted into illegibility | No — subtitles and visual chant indicators are mandatory (GDD-001 §10) | The audio line itself; the visual chant indicator |
| **Codex margin strikes** | The struck-through rule and the replacement text for every eat (§3.1) | Codex screen | n/a at T0 | Never | **No.** It is the announcement channel of record | The world state change, the entity's line, the HUD tell (three of four, §3.1) |

Rules over the inventory:

| Rule | Statement |
|---|---|
| One home anchor per element | Fixed. A deviation may relocate an element to a different slot in the table above and nowhere else (W3-05, W4-04) `✱` |
| Movement never clips | At 200 % text scaling (GDD-001 §10) no element may overlap another or leave the safe area. The safe area is a data value (TECH-001); the SYS-001 rule landed in its §9 on 2026-11-17 (`§8 R-03` closed on the systems side) — TECH-001 still owns the number and the measurement |
| Eaten never means absent without trace | W4-04 leaves the element's frame standing in chalk, empty. The player sees the shape of what was taken |
| An eaten element returns at the Seam boundary | No eaten element persists into the next Seam. The world tier is recomputed at entry (§1.5), and the HUD goes with it `✱` |
| The HUD never gains an element the world does not have | No warp effect adds a readout for a value SYS-001 does not carry. W5-10 shows the counter because SYS-001 §2 phase 6 and §2.1 carry those numbers |
| Act 0 is the calibration | W0-02 is the honest baseline the player memorises. Every later betrayal is measured against the Act-0 layout, which is why the layout itself never changes |

### 4.2 The lie law

A **lie** is defined in §1.1: a readout that disagrees with the game state. A **tell** is the visible defect that marks the lie. The law is short and the lint enforces all of it.

| # | Law |
|---|---|
| L1 | Every lie carries exactly one tell, drawn from a named family below. An effect that lies without naming a family fails the build (§7.3 L-07) |
| L2 | A tell never costs information. It may change which channel carries a fact; it may never be the only reason a fact is missed |
| L3 | A lie is always recoverable by attention: a player who stops, looks and thinks for three seconds can identify what is wrong (§7.2 `TEST-LIE-01`) `✱` |
| L4 | Never two simultaneous lies about the same state. Two wrong readouts of one fact is noise, not dread |
| L5 | A lie never converts an element into a different element. W5-09 re-keys glyphs; it does not make the Sigil read show a Compass |
| L6 | A lie never concerns a countdown that can kill the player. The entity's Waking and Rampage beats are §4.7 territory |
| L7 | At T5 the HUD stops lying (W5-08). The lie budget for a T5 sector is zero, and the lint asserts it |
| L8 | A lie is never a tutorial. Nothing explains a lie in a menu; the Codex may comment after the fact (GDD-001 §3 design rule) |

Deviation classes, so an effect cannot dodge the caps by calling a lie a "render defect". A deviation is the smallest unit the ceiling counts.

| Class | What it does | Is it a lie? | Example |
|---|---|---|---|
| **Lie** | The reading disagrees with the state | Yes | W3-02, W3-07 |
| **Smear** | The reading is true but late or smeared | No — delayed truth, drawn as such | W1-09 |
| **Glyph** | The reading is correct, one symbol is wrong | No, and the underlying value never changes | W1-10, H6's inverted key glyph |
| **Move** | Correct element, different anchor slot, chalk ghost left at home | No | W3-05, W4-04's frame |
| **Absence** | The element, or one axis of it, is not there for the sector | No — an honest gap | W4-04, H16 |

| Tier | Deviations per sector, total `✱` | Of which may be lies `✱` | Notes |
|---|---|---|---|
| T0 | 1 | 0 | W0-07 only, scripted and cinematic, input never required |
| T1 | 2 | 0 | Smear and glyph only: the player learns the strip can be wrong before it lies (W1-10) |
| T2 | 2 | 0 | No HUD lies at T2. T2's horror is the world, not the interface |
| T3 | 4 | 2 | The Compass lies once (SYS-001 §6, cited not restated); W3-07 may add one macro-map lie |
| T4 | 5 | 2 | Plus at most one Move and one Absence per sector (W3-05, W4-04) |
| T5 | 2 | 0 | W5-08 honesty. Only Absences caused by eaten rules (H16) and the encounter tally remain |

The five tell families. Every tell in the game belongs to one of these, which is what lets a player learn the language instead of learning the tricks.

| Family | Device | Where it appears | Used by | Why it reads as wrong rather than as bad UI |
|---|---|---|---|---|
| **Chalk** | The chalk line the HUD is drawn in goes dry: strokes lose their joints, edges flake, the letter thins toward the void side | Compass, Hourglass, Seam index, every eat tell in §3.1 | W1-09, W3-07, H2, H6, H10, H12, H16, W3-05's home ghost | Chalk is the medium of the whole interface, so a dry line is a change in the world, not a fault in the screen (GDD-001 §10) |
| **Glyph** | One symbol is rendered wrong, inverted or replaced by a close neighbour while its value stays correct | Key prompts, Lantern-state glyph, Vigil Index digits, the Surge charge glyph | W1-10, W0-07, H12's chalk-striked Surge glyph, H6 and W3-08's inverted key glyph | A wrong glyph is legible as wrong because the rest of the string is right. Inversion reads as external agency: *something turned my key*, not *the game broke* |
| **Mirror** | Layout or counting direction is reversed; values stay correct | Charge pip strip, kit card, Compass bearing ring | H4 (the shard-magnet tell), W5-06, W4-09 | Counting survives a flip, so the tell never costs the player the number — it only says the world has been turned over |
| **Smear** | A true reading runs toward the nearest wall, or lags its own value | Compass blips, Hourglass digits at T1 | W1-09 | A smeared blip is drawn as smeared, so the player discounts it knowingly. Delayed truth is still truth |
| **Absence** | A chalk frame stands where an element or an axis was; the frame is empty and does not flicker | W4-04's eaten element, H16's marker slot, W3-05's home ghost | W4-04, H16 | Negative space is the least aggressive tell there is, and it survives photosensitivity and 200 % scaling untouched |

### 4.3 Eaten elements

W4-04 is the only effect that takes an element, and it is bounded by this table. An eat removes, a lie corrupts; both are deviations and neither is free (§4.2 ceiling).

| Element | Eatable | Earliest tier | Honest stand-in while eaten | Why this ruling |
|---|---|---|---|---|
| Vigil Index | Yes | T4 | None required | Score is telemetry (SYS-001 §7.1). Taking it costs the player nothing but the pleasure of watching |
| Charge pip strip | Yes | T4 | Chalk tally strokes on the `hull-frame`, one per Charge `✱`; the load chime still fires per Charge drawn | A number the player spends is a state under §1.9, so it must keep a channel. The tally is cheap and diegetic |
| Ledger Compass | No | — | H16 takes the entity axis only; the frame and the sector list remain chalked | The Compass is how a player plans five Seams. Taking it outright would test the §1.9 no-soft-lock guard for no design gain |
| Hourglass | Yes, once per run, Act 4 only `✱` | T4 | Sand-bleed vignette at the field edge, tracking the same value `✱`; a numeric read under photosensitivity | The clock is the run's real pressure (GDD-001 §6.2) and it must always be *somewhere*. One time, in the last act, it is eaten — and that is the beat |
| Composure wick | No | — | n/a | §1.6 promises every drain is visible on the wick. Eating the wick would silently break a promise in another section |
| Seam index | No | — | n/a | Structural lock: five Seams is the shape of a run (SYS-001 §6 🔒, §1.9) |
| Run Sigil read | No | — | n/a | H14 removes authorship, not legibility (§3.4) |
| Flame Bearing | No | — | n/a | It is a redundant channel. §1.9 protects the channel, not just the state |
| Unmaking Counter | No | — | n/a | AC4 requires the counterplay to be visible at the moment it matters |
| Big-type channel | No | — | n/a | Subtitles and visual chant indicators are mandatory (GDD-001 §10) |
| Codex margin | No | — | n/a | It is the announcement channel of record (§3.1: the Codex entry is never optional) |

### 4.4 Steady Ledger (GDD-001 §10 honest-HUD toggle)

Steady Ledger is a save-scoped accessibility toggle. It is free, it is available from Act 0, it changes nothing about damage or reward, and no warp effect may eat, disable, downgrade or mock it (§1.9 `Accessibility overrides the costume`). If an effect makes Steady Ledger do nothing, that effect is a bug.

| What it pins | Behaviour with the toggle on | Why it is pinned |
|---|---|---|
| Compass lies, smears and bearing errors | None ever appear. The Compass shows the state as generated | GDD-001 §10: the honesty toggle re-pins eaten and lying readouts |
| Migrating HUD (W3-05) | Disabled. Elements sit at home anchors all run | Movement is presentation, and presentation is what the toggle governs |
| Eaten elements (W4-04) | The element is never taken. Its chalk frame is still drawn, empty, so the beat still reads | The beat is authored; only the loss of the element is optional |
| Glyph corruption (W1-10, W4-03 edge corruption) | Disabled: type renders clean | Legibility floor below two-thirds is a failure state for text (§2.5 W4-03) |
| Hourglass vignette substitute | Replaced by the numeric run-clock read at `top-left` | A vignette is a felt channel; a number is a legible one |
| Iris curvature track (W5-03) | Frame fixed; the iris still exists, it does not move | Motion is the accessibility surface, not the image |
| Borrowed Voice (W4-08) | **Not** removed. The line is typed and subtitled | It is fiction and communication, not a readout. Removing it would cost information (§1.9) |

| What it deliberately does not touch | Statement |
|---|---|
| Eaten physics rules | H2, H4, H6, H8, H10, H12, H14, H16 (except its marker), H18 all remain. Steady Ledger pins the *interface*; the rules are the difficulty |
| H16's empty marker slot | It remains empty. Absence of an axis is an eaten rule, not a lie, and the toggle does not restore eaten rules |
| The inverted axis (W3-08) | Not removed. §1.9 already rules it a difficulty effect, not presentation |
| Score and reward | Identical with the toggle on and off. Verified by test (§7.4 `TEST-ACC-02`) |
| Fiction and Codex copy | The strikes, the entity's lines and the run-end lines remain. The Chronicle is not an accessibility option |

Second accessibility guarantee, named by W4-07: **Esc always pauses**. When the setting is on — and it ships on — Esc always opens the real pause screen, in every tier, in Act 4, and during a scripted sequence (§6.2). When a player turns it off they are opting into the fiction of a pause screen that will not fill, and play input is never blocked in either case (§2.5 W4-07). A player must never be unable to leave a game they are in distress about.

Third: **photosensitivity** is covered in §4.5 and, like Steady Ledger, is never eatable, never tier-dependent and never scored against.

### 4.5 Photosensitivity parity

The rule that governs this whole subsection, from GDD-001 §10 and repeated here so the lint can cite it: **photosensitivity may never reduce damage taken, may never remove information, and may never make a hazard harder to see.** It changes how motion and luminance are presented, nothing else.

| Warp device | With the mode on | Information preserved by | Never |
|---|---|---|---|
| Breathing zoom (SYS-001 §9 `Zoom`, W5-04) | Zoom fixed at the sector's base value | A Sepulchre approach marker drawn on the frame edge `✱` | Shorter view of the field, no removal of the Sepulchre cue |
| Bounded camera drift (W3-04) | Frozen: camera obeys the base follow constants (SYS-001 §9 `Camera follow`) | Nothing needed: drift was presentation | Drift returning as a "harder mode" |
| Iris curvature tracking (W5-03) | Static curvature, no tracking | The image stays; only motion stops | Hiding the Sepulchre or a Choir unit |
| Chunked field (W5-01) | Plates break once and hold; no drift animation | The gaps stay exactly as generated; hitboxes untouched (§1.9) | Making the gaps harder to judge |
| Boiling rim (W2-07), Shroud growth (W2-02) | Rims render static; cells are fully drawn from the frame they appear in | Cell boundaries drawn at full contrast from frame one | A fade-in that hides a hazard for its first frames |
| Chromatic edge (W1-06), Ink-bleed tells | Colour split disabled; the Smear family tell is replaced by a static edge-notch glyph | The tell family is still named, in a static form | Removing a tell entirely (breaks L1 and L2) |
| Full-field luminance steps | Banned outright in warp presentation, on and off (§1.4 entry rule) | n/a | Any effect whose punch depends on a flash |
| Flicker anywhere | Capped at 3 full luminance cycles per second, on any surface, at any tier `✱` | n/a | A tell that only reads through flashing. (Owner ruling 2026-11-18: the few-pixel Cabinet muzzle star is not a luminance flash under this cap; see AUDIO-001 §8.3.) |
| Big-type typing (W4-08) | Text appears complete, no per-character reveal | Subtitles carry the same line | Delaying the line's content |
| Screen shake (SYS-001 §9 row) | Reduced to 2 px for warp causes; the row's own cap still binds non-warp causes | Hit direction is drawn as a chalk arc on the frame `✱` | Removing the record that you were hit |

Parity is a measured claim, not an intent. §7.4 `TEST-ACC-02` runs the same seed with the mode off and on and asserts the damage and shard totals land within one percent of each other `✱`. Where they do not, the mode is winning and the effect is changed.

### 4.6 Redundant channels

§1.9's guard: any effect that hides a state must leave one redundant channel for the same state. This section defines what counts and maps each state the warp is allowed to obscure.

A channel qualifies only if it is: **(a)** available without spending a resource, **(b)** not hideable by the same effect that hides the primary, **(c)** legible within three seconds, **(d)** still working under photosensitivity, in some form, static is fine.

| State | Primary channel | Redundant channels that always remain | May the primary be hidden? |
|---|---|---|---|
| Entity position, long range | Compass entity marker | Flame Bearing (W2-09), chant and voice positional audio (SYS-001 §3.1; AUDIO-001), the encounter tally | Yes, once per sector (W3-02, W3-07) and permanently under H16 |
| Entity position, short range | On-screen units and their tells | Chant loudness, the Vigil's own foley | No. Nothing in this doc hides an on-screen unit |
| Entity phase (Waking / Rampage / Receding) | Its animation tell | Voice cue, subtitle, visual chant indicator, the Unmaking Counter | **No. Never.** AC4 depends on the tell |
| Segments remaining, threads latched | Unmaking Counter (W5-10) | Thread sockets drawn on the body (ART-002) | No |
| Open exit vectors | Chalk seam decals (W0-09) | The Compass seam list, the lit corridor rule (SYS-001 §4 `Solvability lint`) | Re-keyed (W3-01) and one-way (H2), never removed. §1.9 no-soft-lock |
| Charge count | Pip strip | Load chime per Charge drawn, chalk tally stand-in | Corrupted (H4 mirror), eaten once (W4-04), never unrecorded |
| Composure | Wick, band not number | The band's mechanical symptoms (SYS-001 §1.5), the run-end Codex line | No. The wick is never lied about and never eaten (§1.6) |
| Run clock remaining | Hourglass hand | Sand-bleed vignette, kit rotation cadence, entity phase cadence | Eaten once, Act 4 only, with the vignette live (§4.3) |
| Lantern state and what it does | The Lantern-state key glyph | The light pool itself, the Choir's facing behaviour | Inverted semantics (H6) and an upside-down glyph as the tell — the state itself is never hidden |
| Magnet direction | The pale ring drawn at the radius (H4) | The shards visibly skidding off it | The ring may never be hidden; it is the tell and the counterplay at once |
| Which rules are currently eaten | Codex margin strikes | Every eaten rule changes the world visibly (§3.1 channel one) | No |

The rule in one sentence: the warp may make a channel **unreliable**, and it may take one channel away for a sector, but it may never leave a state with no way to learn it.

### 4.7 Elements and states that never lie

The white list. If an effect touches anything in this table, the lint fails the build and the effect is cut, not tuned.

| Never lies | Why | Source of the invariant |
|---|---|---|
| Entity phase and its tells | The Rampage decision is the player's to make | GDD-001 §11 dread rule, AC4 |
| Segments remaining, thread count, Unravel progress | The endgame counterplay is arithmetic the player is entitled to | SYS-001 §2 phase 6, §2.1 |
| The player's own position and velocity | Every other lie is survivable only because your own ship reads true | W4-09 states it explicitly |
| The Seam index and the count of Seams left | Five Seams is the shape of a run, and a warp effect may not blur it | SYS-001 §6 🔒, §1.9 structural locks |
| Composure drain reads | No hidden sanity cost, ever | §1.6, §3.1 `Composure` |
| Whether a rule is currently eaten | A rule that was eaten must be discoverable, or the eat is a punishment rather than a thesis | §3.1 announcement law |
| The Compass's own-position readout | Bearing may be false, position may not | W4-09 |
| Save state and forward progress | Nothing here can touch banked currency, the Tree, the Codex or Iteration count | §1.9, SYS-001 §8 |
| Accessibility state (Steady Ledger, photosensitivity, Esc-always-pauses, text scale) | The costume never overrides the guarantee | §1.9, GDD-001 §10 |
| The Act-0 layout | The baseline memory the whole HUD language is measured against | W0-02 |

Two narrow exceptions, so the list is honest about where it bends:

| Exception | Scope | Why it is not a hole |
|---|---|---|
| The Hourglass may be **taken**, never falsified | One sector, Act 4 only, with the vignette channel live | Absence under a named channel is not a lie (§4.2 class table) |
| H16 empties one Compass axis | The entity marker frame is drawn and stays empty | The Compass is not lying about the entity; it is honestly unable to show it (§3.2 H16) |

---

## 5. The warp look contract and the cost envelope

Two promises in one section. The look promise: a warp effect is recognisable in a fifteen-second clip to someone who has never seen the game (AC1). The cost promise: every effect sits inside 1.2 ms/frame on minimum spec with the whole tier set running (AC5, SYS-001 §9 `Frame budget (min spec)`). The first is the reason the second matters — an effect the player cannot see is not a warp effect, it is a stat, and this doc does not author stats.

### 5.1 The look contract

| Rule | Statement | Enforced by |
|---|---|---|
| One visual language | Everything the warp does is drawn in the same materials the game is already made of: chalk, brass, glass, oil light, chitin. No new material arrives at any tier | ART-001, review |
| The palette roles are locked | **Amended 2026-11-18 (ART-001 §15):** authored base colours come from the palette (neon at T0, the base palette inside the Aether from T1), and T1's three wrong hues and T2's split registers are chosen *from* its ramps. Lighting, fog, bloom and particles may derive colours beyond it from T1, and their richness is part of the escalation. The role laws (faction hues, phosphor = truth, SIGNAL budget) never bend | review; faction-lock test |
| Faction law holds at every tier | Choir never wears the player's amber/brass, and no tier effect puts a player register on a Choir silhouette (W2-01, W4-02). This is the single most-checked visual rule in the game | ART-002 kit locks |
| Value before hue | Every warp effect must read in greyscale. A tell, a hazard and a unit must all be separable by luminance alone, which is what makes colourblind play real rather than nominal (GDD-001 §10, ART-001 §4) | §7.4 `TEST-ACC-03` |
| Nothing moves a hitbox | The warp re-skins, re-keys and re-draws. It never changes a hitbox, a radius or a speed (SYS-001 §9 `Hitbox policy`, §1.9) | §7.3 L-04 |
| Scale is dread, gore is not | Wrong-count limbs, faces in the wrong place, module skeletons, ordinary objects that should not be there. No blood, no viscera, no jumpscares, no timed inputs (§1.9, GDD-001 §11) | review, §7.3 L-11 |
| Symmetry is the tell of the normal | Act 0 and T0 are symmetrical and static. As tier rises, symmetry breaks before detail does. A tier should read at thumbnail size | AC1 evidence clips |
| An effect must be attributable | A player can point at the frame and say which effect is happening. Two effects that cannot be told apart are one effect, and one of them gets folded | §7.2 `TEST-EAT-*` |
| Cuts are visible at the cut point | Where the warp breaks something (W5-01 plates, W4-01 interior), the break is drawn once and holds. Flickering seams and animated tears cost frames and read as noise | §5.2 reduced variants |
| The entity is never a face | At every tier the entity reads as assembled modules, not as a creature with a face. Its wrongness is construction, not expression (GDD-001 §11, ART-002) | ART-002, NARR-001 |

What a tier should look like, in one line each, so art and design can check they are drawing the same film:

| Tier | The one-line look |
|---|---|
| T0 | A cabinet that works. Symmetry, scanlines, honest brass |
| T1 | The same cabinet, wrong in three places you cannot name |
| T2 | The dark outside the lamp has grown, and it has texture |
| T3 | The edges of the room are suggestions, and the interface has started to move on its own |
| T4 | You are inside the lamp. The Choir is wearing your furniture |
| T5 | The drawing has stopped pretending to be a world. Ribs, plates, chalk, and a hand writing over your own |

### 5.2 Cost envelope

SYS-001 §9 fixes the ceiling at **1.2 ms/frame for warp effects on minimum spec** (GDD-001 §8.7 AC5). Everything below is this doc's budgeting of that ceiling and is marked `✱`; the ceiling itself is SYS-001's and is never restated as a new number.

Every §2 row and every §3.2 registry row carries three cost fields in data: `ms_standing`, `ms_transient`, `ms_reduced` (TECH-001 §6). The lint (§7.3 L-05) computes, per tier, `standing_sum + two largest transient peaks ≤ 1.2` and fails the build on breach — the same formula §1.8's simultaneous-transient cap implies.

| Effect class | Ceiling per instance `✱` | Aggregate rule |
|---|---|---|
| Full-field shader pass (curvature, bezel, plate break, interior) | 0.22 ms | At most 3 concurrent full-field passes per sector. A fourth must fold into one of the three |
| Palette or ramp change | 0.04 ms | Implemented as a table swap, never as a pass. Tiers replace, never stack |
| Per-unit render change (breathing, wrong count, ribs, re-skin) | 0.005 ms/unit | Aggregates against SYS-001 §4's worst-case unit count for the tier, never against the average |
| Cell or region hazard (Shroud, drift field, rim) | 0.06 ms per region | At most 8 regions live at once; overflow re-uses an existing region |
| HUD deviation (one element) | 0.03 ms | Bounded by §4.2's per-sector deviation cap, which is why the cap exists |
| World-state bookkeeping (seam keys, corruption, registry pair swap) | 0.06 ms | Runs at Seam entry, not per frame. Detection-pair replacement is a data swap |
| Audio stem reconfiguration | 0.05 ms on the game thread | No audio work on the render thread, at any tier (TECH-001) |
| Transient effect, peak | 0.25 ms | Two concurrent at most (§1.8), so 0.50 ms of transient headroom is reserved at every tier |

The tier sums, with the reduced-cost variants (§1.2's "a higher tier keeps the lower tier's standing set") already applied:

| Tier | Standing sum `✱` | Reserved transient peak `✱` | Worst-case total | Headroom vs ceiling | Notes |
|---|---|---|---|---|---|
| T0 | 0.20 | 0.10 | 0.30 | 0.90 | The costume is cheap and the slice runs here |
| T1 | 0.42 | 0.20 | 0.62 | 0.58 | Parallax and breathing are the expensive standing items |
| T2 | 0.66 | 0.35 | 1.01 | 0.19 | Shroud cells and the boiling rim are the risk |
| T3 | 0.78 | 0.40 | 1.18 | 0.02 | The tightest tier. Reduced variants are on by default at T3 `✱` |
| T4 | 0.82 | 0.35 | 1.17 | 0.03 | Interior replaces parallax; eaten stems cost nothing |
| T5 | 0.88 | 0.28 | 1.16 | 0.04 | Plate break and the skeleton pass are the tier's whole budget |

| Rule | Statement |
|---|---|
| Where the ceiling is measured | On the profile rig, at the tier's own threat budget from SYS-001 §4's T4–T5 column, with the tier's standing set live and its two most expensive transient effects firing together `✱` |
| What a failed measurement does | The effect's reduced variant becomes that tier's default automatically. Nothing ships over budget and nothing ships invisible |
| What a reduced variant may not do | It may not remove information (§4.5), may not break a tell's family (§4.2), may not change a hitbox. If the reduced variant cannot satisfy those, the effect is a candidate for folding or cutting, and the ladder in §5.3 orders the candidates |
| Standing sets are tier-fixed | A sector never runs two tiers' full standing sets. The higher tier keeps the lower tier's effects *in their reduced variants* (§2 conventions) so the sum is computable at authoring time |
| Registry rows are costed too | An eaten rule is a standing rule of the sector: `ms_standing` for H2's seam bookkeeping, H6's pair swap and H4's ring render are all in the tier sums above |

### 5.3 Refusals, and the ladder for getting back in budget

The refusals are absolute and belong to this doc. The *cut decision* — what does not ship, and when — belongs to PROD-001 (§0.1). What follows is a technical preference order for staying inside the envelope, not a content plan.

| Refusal | Why |
|---|---|
| No full-field luminance step, ever, in any tier | §1.4's entry rule and GDD-001 §10's anti-jumpscare rule. An effect whose punch comes from a flash was never a warp effect |
| No flicker above 3 cycles per second | §4.5, and it keeps the tier readable on a handheld |
| No colour-only information, at any tier | §5.1 value-before-hue. A tell that needs hue to read is a tell that fails half the audience |
| No new palette roles | ART-001's 32 roles; the warp re-reads them and lights them, it does not invent new ones (amended 2026-11-18: derived colours from lighting and effects are allowed from T1, ART-001 §15) |
| No shader that obscures the field for more than 12 % of pixels with noise `✱` | Readability, and the AC5 measurement gets worse the more of the screen is noise |
| No effect that dims the lamp below its SYS-001 §1.2 radius | The light pool is the game's core verb. W2-07 boils its rim; nothing shrinks it |
| No gore, no corpse language, no timed inputs | GDD-001 §11, §10 |
| No letterboxing except once per run, in a scripted beat | A black band is a lie about the aspect ratio, and the player will spend the rest of the run looking for the second one |
| No warp effect that hides the entity's silhouette during the encounter | AC4 and the fiction both require the entity to be legible at its own climax |

| Priority | First to reduce | Why it is cheap |
|---|---|---|
| 1 | Per-unit render changes (breathing, ribs) | They are dread bought with frames, and they hurt least when static |
| 2 | Boiling rims and animated edges | Static equivalents keep every piece of information |
| 3 | Cell and region hazard visuals (draw the cell once, hold it) | The mechanic is in the collision data, not in the animation |
| 4 | Parallax plates | Removed entirely at T4 already (W4-01); the look survives |
| 5 | Full-field passes | Last to touch, because they are what a tier *is*. Cutting one is a design decision, and design decides it with PROD |

### 5.4 Audio hand-off

AUDIO-001 owns the audio design; this section is the invoice, tier by tier, plus the requests already filed in §3.3.

| Tier | What the warp asks audio to do | What it must never take away |
|---|---|---|
| T0 | Chiptune and arcade chimes at full strength; one buried chant line at A0-2 (W0-06) | The visual chant indicator for that line (GDD-001 §10) |
| T1 | A choral stem under the chiptune (W1-08); positional false chant cues at the Frayed band rate (W1-07, SYS-001 §1.5) | The true procession's positional chant: a false cue never replaces a real one, it competes with it |
| T2 | Chant audible through geometry beyond the SYS-001 §3.1 rate `✱`; Shroud and foley beds; the flame gutter (W2-09) | Foley that tells you you have been hit |
| T3 | Seam chimes per link pair (W3-01, W0-09 extended), chalk scrape for migrated elements (W3-05), reversed glass chime for H8's shard payment | The seam chime that marks an open exit vector |
| T4 | Stem removal map (W4-10), household foley on Choir actions (W4-02), one dead click for the refused pause (W4-07), the big-type line's voice channel (W4-08) | Subtitles and the chant indicator: silence never costs information |
| T5 | Stem collapse to near-silence (W5-07), bell per thread latched (W5-10), thread snap (W5-05) | The entity's voice. At T5 it is the primary long-range bearing channel (H16) |

| Hand-off item | Statement | Status |
|---|---|---|
| Eighteen eat lines | Nine telegraph lines and nine arrival lines, one pair per §3.2 row. The telegraph names the rule in the player's own vocabulary and never names a system | Requested (§3.3) · NARR-001 writes, AUDIO-001 casts |
| Death-line vocabulary | Composed from SYS-001 §8's telemetry keys as that row already specifies; the warp never adds a hidden input to the compositor | Cited, not extended |
| The silence budget | GDD-001 §12's silence beats are capped at two per run by AUDIO-001 and the warp never spends them (§1.9 `Silence is budgeted`) | Standing rule, restated here so nobody double-counts |
| Tell sounds | Every §4.2 tell family has a sound except Absence, which is deliberately silent. A silent tell is allowed once, because a chalked-out frame already says enough | Authored here |
| Voice as state | Entity lines are state readouts, not dialogue, whenever they carry position, phase or rule information (GDD-001 §12) | Cited |
| Reversed-chime convention | Anything the entity takes plays its own confirmation backwards: the seam chime reversed (H2), the glass chime reversed (H8). This is the audio twin of the chalk family | Authored here · requested of AUDIO-001 |

---

## 6. Decisions on the questions GDD-001 §20 leaves open, where they touch warp

GDD-001 §20 lists four open questions; three of them are warp questions. Two more decisions are recorded here because §2 and §3 cannot be implemented without them. Ruling numbers run continuously: D-01 to D-06 answer the design doc and the mechanics, D-07 to D-11 answer the questions §10 was carrying.

Namespace note: `D-nn` in this section is WARP-001's own decision namespace and is always written with this doc in scope. GDD-001 §18's decisions are cited as GDD-001 D-nn. A conformance ask is filed so the two namespaces never collide in a citation (§9.2 C-06).

Delegation, dated 2026-11-17: the owner handed this doc the calls that would otherwise have waited on them — GDD-001 §20's open questions and the design questions carried in §10 — with the standing instruction that any of them may be reversed when playtesting says so. D-07 to D-11 are made here on that authority. Each one names the evidence that would change it, because a provisional ruling without a reversal condition is just an opinion with a table around it.

### 6.1 The rulings

| ID | Question | Ruling | Consequence |
|---|---|---|---|
| **D-01** | GDD-001 §20 Q1 — is the Hourglass Clock a hard timer, or does it pause during exploration? | **Hard, diegetic, and never touched by the warp.** The clock runs through combat, mining, exploration and the Ruins. It does not advance during: a pause screen, the Codex (GDD-001 §6.2 already), a scripted cinematic, or attract mode. It is never the only warning of anything (§4.6 gives it two redundant channels). When it reaches zero the iteration ends in a named, authored beat — the sky closes — and anchored progress survives it (GDD-001 §8.9, SYS-001 §8). The clock may be **hidden** (§4.3, once, Act 4) and may never be frozen, slowed, reversed or spent by any warp effect. | Variant B (pauses during exploration) stays buildable as one data flag, `clock_runs_during_exploration`, and the A/B happens at the demo as GDD-001 §20 asks: if more than 30 % of first-time players report the clock as the reason they quit `✱`, we ship B. The lock row landed in SYS-001 §10 on 2026-11-17 (§8 R-04 closed), which is what keeps the A/B honest: whichever variant ships, the warp never owns the clock |
| **D-02** | GDD-001 §20 Q2 — does Act 4 keep the same controls, or is the "controls get eaten" moment one scripted sequence? | **One scripted sequence, once per run, never permanent** — GDD-001 §20's current answer is correct and is now defined (§6.2). Outside that sequence, Act 4 changes *rules*, never inputs: W3-08's inversion remains a Composure-band effect (SYS-001 §1.5), not an Act-4 effect, and H10/H12 change what tools do rather than what buttons mean. A control that is eaten is not a control the player can practice against, so we refuse it as a standing state | The sequence needs an author, a beat sheet and a test. §6.2 is the beat sheet; §7.2 `TEST-SEQ-01` is the test |
| **D-03** | May a Pact pre-attach an Unraveling thread? | **Yes, and it counts as already latched** — the ruling is byte-frozen at §3.3 and restated here so the mechanic has one home. A pre-attached thread does not lower the 3-thread requirement (SYS-001 §2 phase 6), does not reduce `Unravel hits` (SYS-001 §2.1), and does not expose a thread the entity has not exposed. It removes travel time, not the fight | Mechanical spec: the thread is drawn from socket to Focus at encounter start, chalked and slack rather than taut, and it becomes live the moment that socket opens. If the Pact lapses mid-encounter the thread goes slack and stops counting; nothing snaps and no progress is clawed back (AC2) |
| **D-04** | GDD-001 §20 Q4 — how much of the entity is seen in Act 0? | **A silhouette and nothing else.** Three signature frames exist in Act 0 (the distant shape, the shadow across the Sepulchre, the shape inside the Pretence Tear at W0-07), all silhouette, all at the field's edge, never centred, never lit. The full modular body debuts at the Awakening, exactly once. T5's ribcage (W5-02) is a *disassembled* body and must not be cut to look like the Awakening reveal, or the one reveal we paid for is spent twice | Three silhouette frames named for ART-002 and ASSET-003 (§8 R-07). The entity kit itself does not exist yet (ASSET-003 §6) and this ruling is the cheapest thing art can build for Act 0 |
| **D-05** | What may outlive a run? §3.2 says H14 survives death and Hard Unmaking; §1.9 says nothing here destroys run progress. Where is the line? | **The line is choice, not possession.** The table below is the boundary; the warp may take a choice permanently and may never take a thing. H14 is the only permanent effect in the game and it takes a single pick from a single screen | §9.2 C-04 asks the GDD owner to footnote GDD-001 §3's Sigil choice guarantee with this exception. WARP-001 does not edit GDD-001 |
| **D-06** | GDD-001 §20 Q3 — daily challenge at 1.0? | **Not this doc's call, and this doc must not make it impossible.** The warp's requirement of any daily mode: a deterministic warp state per seed. A daily runs a fixed world tier and a fixed Hunger preset so the §3.2 registry is knowable `✱`; H14 never fires in a daily, because a Chronicle-permanent effect would leak across seeds and break a leaderboard `✱`; Steady Ledger and photosensitivity work in dailies exactly as elsewhere | The seed contract is locked in SYS-001 §10 as of rev 1.1; what is still owed is TECH-001's implementation of the seed model (§8 R-05). The date decision stays with PROD-001 and MARKET-001 |
| **D-07** | Does Act 4 eat exactly one rule, or as many as the cadence allows? | **As many as the cadence allows, and not one more scheduled by hand.** Act 4 fires eats on SYS-001 §2.2's cadence, inside §3.1's one-eat-per-Seam rule and §4.2's deviation ceiling. The scripted sequence's on-screen eat (§6.2 beat 4) is scripted and does not consume a cadence slot, and it never eats twice in one sector. At T5 an eat is the *only* deviation channel available, so Act 4 escalates by taking rules rather than by lying about them — which is the whole reason T5's lie ceiling is zero | Hand-scheduling eats turns Act 4 into a queue of set pieces and makes the cadence a fiction. The ceiling already bounds how loud it can get. Revisit when `TEST-RULE-01` shows Act-3 players naming more than two lost rules and sounding numb rather than unsettled |
| **D-08** | Is H14 too strong for a game that promises no permanent loss? | **It ships at 1.0**, behind the §3.4 ruling that the warp takes a choice and never a thing, and behind three hard conditions: the eat is telegraphed a Seam early (§3.1), the Codex entry states plainly which sigil the entity took and what that sigil had done, and `TEST-H14-01`'s unwinnable-run assertion is a build failure rather than a warning | If the demo audience rejects it, the fallback is one line of data and it costs nothing else: run-scoped H14, where the entity's pick stands for that run and the Chalk Desk reverts to the player in the next Iteration. The statement survives as a beat; only its permanence goes. That fallback is authored here so the reversal is a switch and not a redesign |
| **D-09** | Should the Unmaking Rehearsal repeat in New Game Plus? | **Yes, once per run, rotated and skippable from the first watch.** A player in a later Iteration has already seen it, so repeating it verbatim is a punishment rather than a statement. The frame beats stay (1, 3, 5, 7, 8); the content beats re-key to what is actually eaten in that run, so beat 2's drawing and beat 4's eaten rule are different rules in different Iterations | Rotation is re-keying existing beats against the §3.2 registry, not new content. If a later audience says the beat wears out even rotated, the answer is one watch per Chronicle and the whole sequence becomes memory — which costs nothing and is the cheaper thing to keep |
| **D-10** | The eaten-rule counterplay Pacts: how much does the loop doc actually owe, and when? | **Two Pact rows for the slice, and H14 without one.** The slice's tranche is H2, H4 and H14 (Q-08, §10). Two of the three need a restore Pact — PACT-01 and PACT-04, whose clauses §3.3 already writes — and the third needs the opposite: its pick logic, its explicit no-restore flag, one line of dialogue. The other six Pact clauses stay authored requests until Act 3 content is scheduled. AC4 is enforced per effect in the build that ships it: L-06 fails a dangling ID, and fails an H14 that forgot to declare itself the exception | LOOP-001 §5 owes two rows for the slice, which is a buildable number. Revisit when Act 3's sector list is fixed; the six remaining clauses are already specified in §3.3 and need authoring, not design |
| **D-11** | The warp build gate is not in CI yet. What is the enforcement path until it is? | **Blocking before the first slice build, with a named interim.** `warp_lint` must be a CI step (TECH-001 §1.4) before the slice builds. Until it exists, §7.3 runs as a manual checklist at every milestone close, owned by this doc, with the fifteen rule IDs as the items and every failure recorded in §9.2. The rules split into two tiers of cost: **L-01, L-02, L-06, L-10, L-13, L-14** are data-only and can be checked against the registry alone; **L-03, L-04, L-05, L-08, L-09, L-11, L-12, L-15** need engine or art hooks and come later | A data-only first pass of the gate is a script, not a system, and it catches the failure mode that actually happens in production: an author writing an effect with no counterplay, no tell family or a dangling ID. Revisit when engineering has the collision and profile hooks to hang the rest on |

The D-05 boundary, in the only form that can be linted:

| Thing | May the warp take it permanently? | Basis |
|---|---|---|
| Banked currency, Lantern Tree, Codex, Iteration count, Fragments | Never | SYS-001 §8 🔒, §1.9 |
| A Run Sigil already held | Never. H14 does not remove, it adds and it chooses | §3.4 |
| The run's Sigil *choice* at the Chalk Desk | Yes, once, Chronicle-wide | H14, §3.4 |
| The Compass's ability to show the entity | Yes, but only for the run in which the eat fires | H16, §3.1 `Restore scope` |
| Base physics (wrap, magnet, detection, over-fire, Surgelight cost) | Yes, for the run; each with a named Pact restore | §3.2 |
| The Arc-Lance's ability to damage Grubs | Yes, for the run; the registry pair is the only legal way | H10, §1.9 `Locked rows` |
| The ability to unmake the entity at the rule level | Yes, until Act 4 | H18, §3.2 |
| The player's trust that the HUD reports the world | No, and that is the point: every lie carries a tell (§4.2) | §4 |

### 6.2 The one scripted sequence: the Unmaking Rehearsal

The Act-4 beat that D-02 permits. It fires on entry to the first Act-4 T5 Seam of a run, once per run, and it fires again in a later Iteration rotated rather than repeated (D-09). Title of record: **the Unmaking Rehearsal**. It is not a cutscene — input is live for all but three of its beats.

| Beat | Duration | What the player can do | Agency window |
|---|---|---|---|
| 1. The sky stops | 3 s | Move, aim, fire. The music stems drop out (already true of W5-07) | 0 s |
| 2. Your own Vigil is drawn by a hand that is not yours | 6 s | Move and fire normally; the drawing is an overlay, not an input hijack | 0 s |
| 3. The chalk line crosses the field | 4 s | Move only. Aim is not locked; firing is simply not required | 0 s |
| 4. A rule is eaten on screen, visibly, in the chalk family | 5 s | Move, aim, fire | 0 s |
| 5. The hand takes the pause screen | 1.4 s | Nothing. Esc answers with a dead click, and only if the player has turned Esc-always-pauses off (§4.4) | 1.4 s |
| 6. Your Charge strip empties and refills, chalked | 1.4 s | Nothing. No Charge is actually spent | 1.4 s |
| 7. The Vigil's own lamp goes out and comes back | 1.2 s | Nothing. No Lantern state change | 1.2 s |
| 8. Everything returns and the Seam begins | 3 s | Everything | 0 s |
| Total | ≈24 s | Three beats deny action; none exceeds the SYS-001 §9 `Player agency loss` budget, and their sum is 4.0 s `✱` | 4.0 s |

| Rule | Statement |
|---|---|
| Esc always wins | With the accessibility setting at its shipped default the sequence yields to a real pause screen at any beat, mid-beat, without penalty (§4.4) |
| Skippable after one watch | Same rule as W0-07 and GDD-001 §6.1's no-QTE skip. The first watch is not skippable; every later one is. In a later Iteration the first watch counts as a later one, since the Chronicle has already seen it (D-09) |
| It spends no effect budget | Scripted beats are budget-exempt (§1.8) and the sequence costs the tier's transient envelope 0.25 ms at its peak (§5.2) |
| It changes no state | Nothing in the sequence alters Charge, Lantern state, Composure, Hunger or the registry. It is a rehearsal, and a rehearsal that costs resources is a mechanic |
| It is the run's only input denial | Across a full run, the total agency window a player spends in warp-caused input denial is bounded by the lint at 1.5 s per effect and by this sequence's 4.0 s `✱` (§7.3 L-03) |
| Silence budget | Beat 1 and beat 8 sit inside GDD-001 §12's silence beats, which AUDIO-001 caps at two per run and the warp never spends (§1.9) |

### 6.3 What these decisions cost, and who acts next

| Decision | Doc that must change | Ask | Size |
|---|---|---|---|
| D-01 | SYS-001 §10, TECH-001 | Lock the clock rate against warp interference; one data flag for the A/B | Small · one row, one flag |
| D-02, §6.2 | ZONES-001 §3 (Act 4 kits), NARR-001, AUDIO-001 | Author the sequence as a scripted kit; two lines of entity speech | Medium · one kit |
| D-03 | LOOP-001 §5 | Implement thread pre-attach as a Pact clause with the D-03 bounds | Small · one clause |
| D-04 | ART-002, ASSET-003 | Three silhouette frames, and the entity kit gap stays on the record | Small, but see the gap |
| D-05 | GDD-001 §3 | Footnote the choice guarantee with the H14 exception | One sentence, owner's call |
| D-06 | SYS-001 §10, PROD-001, MARKET-001 | Seeded warp state; the date stays a release decision | Small now, decides later |
| D-07 | ZONES-001 §3, this doc | Nothing new to build: Act 4 fires the existing cadence. Pacing note only, so no hand-placed eat appears in an Act-4 kit | Free |
| D-08 | LOOP-001 §4 (the H14 pick comes from the run's legal Sigil pool), NARR-001 §7 (its eat line), NARR-001's Codex section (the struck entry), `TEST-H14-01` | Author H14 as specified, with `no_restore = true` explicit in data and the run-scoped variant as a second flag. No Pact is requested for it | Small · two flags, one line, one Codex entry |
| D-09 | ZONES-001 §3 (the §6.2 kit), LOOP-001's NG+ plan | Re-key beats 2, 4 and 6 against that run's eaten rules. No new beats | Small · re-keying, not authoring |
| D-10 | LOOP-001 §5 | Two Pact rows for the slice (PACT-01, PACT-04), clauses already written in §3.3. The other six wait for Act 3's schedule | Small · two rows, and it unblocks AC4 in the slice build |
| D-11 | TECH-001 §1.4, §8 | `warp_lint`: six data-only rules first, the other eight when the engine hooks exist. Manual checklist in the meantime | Medium · the script is a registry query, the hooks are not free |

---

## 7. The warp test plan and the warp lint

The gate in §1.8 is a claim until something measures it. This section is the measurement: a data lint that fails the build, a per-rule test set, and an audience protocol with pass lines written in the player's own words.

### 7.1 What is tested, and how often

| Family | Covers | Cadence | Owner |
|---|---|---|---|
| Data lint (§7.3) | Every §2 row and §3.2 row, all fifteen rules, on every commit | Per commit, CI step `warp_lint` (TECH-001 §1.4) | Systems |
| Cost profile | AC5, the sums in §5.2 | Nightly on the profile rig, plus before every milestone | Engineering |
| Scripted soak | §1.9 guards under random seeded runs: 200 seeds per tier, every eat legal at that Hunger | Nightly | Systems |
| Legibility and audience (§7.4) | AC1, AC2's felt reversibility, the no-reading pass lines, accessibility parity | Per milestone, with a fresh panel | Design + producer |
| Evidence clips | AC1 for each effect: one 15 s capture per row, unedited, no HUD annotation | Authored with the effect; missing clip fails the lint (L-01) | Design + art |

### 7.2 Per-rule eat tests

One row per §3.2 entry. The **no-reading pass line** is what a tester must be able to say, unprompted, without having opened a menu, a Codex entry or this document. It is the legibility floor from §3.1, made into a sentence.

| Test | Rule | What is asserted | Method | No-reading pass line |
|---|---|---|---|---|
| `TEST-H2-01` | H2 one-way wrap | The seam closes 20 s after crossing and never earlier; the Vigil slides rather than stops; the far-side chalk darkens over the whole 20 s; the solvability lint still passes with the seam closed | Seeded run, forced H2, timed crossing, then a scripted re-cross attempt at 19 s and 21 s | "I went through the wall and the way back shut." |
| `TEST-H4-01` | H4 magnet inverts | Repulsion radius equals SYS-001 §1.4's magnet value with the sign flipped; a `Hookline` build is repelled at its widened radius; the drawn ring and the collision ring match to the pixel | Drawn-ring overlay capture, then a scripted shard flight across the radius | "The glass ran away from me." |
| `TEST-H6-01` | H6 detection flips | The registry pair replaces the SYS-001 §1.2 pair rather than multiplying it; *Dark Lantern* still applies; a lantern-down field is more dangerous than a lantern-up field by exactly the pair's ratio | Two scripted runs, same seed, opposite lantern state, detection counters logged | "The dark attracted them. The light hid me." |
| `TEST-H8-01` | H8 over-fire | The geode never detonates from over-fire; exactly 1 Charge leaves the magazine per over-fire event; with an empty magazine nothing is taken and the event still reads | Two scripted runs, one with a full magazine, one deliberately empty | "I kept hitting one face and it ate a charge instead of breaking." |
| `TEST-H10-01` | H10 Grub immunity | The Arc-Lance deals no damage to Grubs and no damage to a Grub's carrying shard; mining still kills them in 3 hits; keening still happens; the geode still converts | Damage-log diff against the non-eaten state; must be zero collateral outside Grub contact damage | "My lance did nothing to them. I had to dig them out." |
| `TEST-H12-01` | H12 Surgelight | Every Surge costs Composure at the registry pair's rate and clears no Shroud; *WARD-15* restores both halves in the same run; the Surge charge glyph stays legible | Two scripted runs with the counterplay held and not held | "The bright flash cost me something, and it stopped burning the webbing." |
| `TEST-H14-01` | H14 the picked Sigil | No tester reports an unwinnable run, and every tester can say which rule was taken. The pick is never re-rolled by the §8 mercy, and the Chalk Desk shows a hand that is not the player's | Seeded run, forced H14, then the §7.4 interview. Pass line is verbatim: no unwinnable reports, 100 % rule identification | "A hand that wasn't mine picked my sigil." |
| `TEST-H16-01` | H16 the blind Compass | The marker slot is drawn and empty for the whole sector; geodes, Shrines, the Sepulchre and seams are still shown; the voice and Flame Bearing channels are both live | Compass frame capture against the generated state, channel availability assert | "The compass had no dot for it." |
| `TEST-H18-01` | H18 unmaking refused | Threads never latch before Act 4; segments still detach, shards still drop, the entity still recedes on schedule; the counterplay path in §3.2's row is the only legal answer | Scripted encounter with the Focus held; assert latching count is zero and the encounter still ends | "I had the threads and it still would not come apart." |

Cross-rule tests, which is where the failure mode actually lives — not one eat, but two at once:

| Test | What is asserted |
|---|---|
| `TEST-EAT-01` | Three of the four announcement channels fire for every eat (§3.1), and the Codex entry is always one of the three |
| `TEST-EAT-02` | At most one eat per Seam, and an eat deferred for a tier deficit is never run at a lower tier (§3.1 `Deferral`) |
| `TEST-EAT-03` | Two eats legal at the same Hunger level (a registry rule and a SYS-001 §2.2 counter) both apply without cancelling each other |
| `TEST-EAT-04` | A restored rule returns the locked default exactly: no residue of the eaten version, no buff, no visual carry-over |
| `TEST-SEQ-01` | The Unmaking Rehearsal (§6.2) fires once per run, its agency windows sum to ≤ 4.0 s, no single window exceeds the SYS-001 §9 budget, and Esc interrupts it with the accessibility setting at default |
| `TEST-LIE-01` | With a lie active, a tester who stops and looks for three seconds can name what is wrong (§4.2 L3). Pass at 8/10 `✱` |
| `TEST-BUD-01` | No sector exceeds 3 novel transients, 2 simultaneous transients, or its §4.2 deviation cap, across 200 seeded runs |

### 7.3 The warp lint

A build gate. If any rule below fails, the build fails — this is how a document with fifteen invariants survives eight months of content production.

| Rule | Assertion | Why it is here |
|---|---|---|
| **L-01** | Every §2 and §3.2 row carries: `id`, `class`, `tier`, `trigger`, `agency_window`, `ms_standing`, `ms_transient`, `ms_reduced`, `tell_family`, `counterplay`, `restore`, `evidence_clip`. A missing field fails | The gate in §1.8 is only as real as the data behind it |
| **L-02** | No effect fires outside its act/tier window (§1.3); no eat fires below its Hunger level (SYS-001 §2.2) | §1.4's "never at a lower tier for the schedule" |
| **L-03** | `agency_window` ≤ SYS-001 §9 `Player agency loss` for every effect, and a scripted sequence's sum ≤ 4.0 s `✱`; movement, aim and fire are never simultaneously disabled | AC3, and the one place we let the number be checked rather than argued |
| **L-04** | Collision data is byte-identical before and after any effect, at the same tier and kit state | §5.1, §1.9, SYS-001 §9 `Hitbox policy` |
| **L-05** | `standing_sum + two largest transient peaks ≤ 1.2 ms` measured on the profile rig (SYS-001 §9 `Frame budget (min spec)`) | AC5 |
| **L-06** | Every `counterplay` names a Pact, Lantern Tree node or Run Sigil that exists in the build. A dangling ID fails. **H14 is the one declared exception** and must carry `no_restore = true` explicitly: the lint then requires instead that its pick is drawn from that run's legal Sigil pool, so the exception cannot become a hole (§3.4, `TEST-H14-01`) | AC4 |
| **L-07** | Every lie names one of the five tell families (§4.2), and no effect lies at T5 | §4.2 L1 and L7 |
| **L-08** | Any effect that hides a state names a redundant channel from §4.6 that the same effect cannot itself hide | §1.9 `No unearned information loss` |
| **L-09** | The SYS-001 §4 `Solvability lint` passes **in the eaten state**, and after every kit re-key at the sector's world tier. A re-key that breaks solvability fails the tier, not the kit | §1.9 `No soft-lock`, §3.1 `Solvability` |
| **L-10** | No effect or eat names a §1.9 never-eaten item, and no effect targets Steady Ledger, photosensitivity, text scale or Esc-always-pauses | §1.9, GDD-001 §10 |
| **L-11** | No flash, flicker above 3 cycles/s `✱`, gore flag, jumpscare flag or timed-input requirement anywhere in warp content | §1.9, §5.3, GDD-001 §11 |
| **L-12** | No base colour outside an ART-002 kit lock on a faction-restricted unit (derived lighting colours are exempt from T1, ART-001 §15) | §5.1, ART-001, ART-002 |
| **L-13** | Per sector: ≤3 novel transients, ≤2 simultaneous, ≤1 eat, and within the §4.2 deviation cap for that tier | §1.8, §4.2 |
| **L-14** | Registry rules are referenced as `RULE-Hn`; SYS-001 §2.2 counter rows keep their own IDs. No citation collapses one into the other | §3.1 `Namespace`, §9.2 C-01 |
| **L-15** | Every eat has a named restore path, and H14 is the only permitted exception in the whole registry | §3.1, §3.4 |

### 7.4 Accessibility and audience tests

The human half of the gate. Panel: ten people per milestone, at least five of whom have never seen the game, matching GDD-001 §17 criterion 6's standard.

| Test | Method | Pass line |
|---|---|---|
| `TEST-ACC-01` | Steady Ledger on, full Act 1 run, HUD frame captures compared against generated state | Zero lies, zero migrations, zero eaten elements; the chalk frames still drawn; the run clock shows numerically |
| `TEST-ACC-02` | Same seed, photosensitivity off then on, run replayed by script; damage taken and shards collected compared | Within 1 % of each other `✱`. Any divergence means the mode is costing the player something, and the effect changes |
| `TEST-ACC-03` | Every tier's evidence clip converted to greyscale and shown to five people | Each clip's active effects and hazards named by four of five. §5.1 value-before-hue |
| `TEST-ACC-04` | Text scale at 200 %, subtitles on, a T4 sector with three HUD deviations active | No overlap, no clipping, every deviation still attributable (GDD-001 §10) |
| `TEST-ONB-01` | A first-time player runs Act 1 with the death box enabled and a fixed 25-minute window | They finish Act 1 alive at least once in five attempts `✱`, which is GDD-001 §8.7's stated onboarding test |
| `TEST-ONB-02` | Immediately after Act 1, ask the player, in their own words, what happened to the game | The verbatim quote is logged. The pass condition is not comprehension, it is the reaction GDD-001 §8.7 asks for: "what the hell was that" in some wording of it |
| `TEST-RULE-01` | After Act 3, ask each tester to name a rule the game used to have, and to say what replaced it | Eight of ten can name at least one and its replacement. This is GDD-001 §8.7's Act-3 promise, measured |
| `TEST-EV-01` | Show each effect's 15 s clip, unlabelled, to five non-players | Five of five can say something changed on screen; three of five can say roughly what (AC1) |
| `TEST-CUT-01` | Ask testers which warp effect they would remove, if allowed to remove one | Recorded, not passed. If the same effect is nominated by six of ten twice running, it is either broken or too expensive, and it goes on the §5.3 ladder for PROD-001 to weigh |

Two things this plan deliberately does not test, so nobody expects them: it does not test whether the warp is *scary* — dread is measured in the audience interview, not by us — and it does not test whether a player enjoys losing a rule, which is a taste question for the demo (GDD-001 §17).

---

## 8. Requests to other documents

WARP-001 does not edit another doc's rows. Where the warp needs a number that is not its own, it files a numbered request and the owning doc writes the row. Requests are cited as **WARP-001 §8 R-nn**; GDD-001 §16 keeps its own request namespace (§9.2 C-05).

| ID | Ask | Target | Who acts | Blocks what | Status |
|---|---|---|---|---|---|
| **R-01** | A tunables row: `seam_close_after` = **20 s** — the delay before a crossed seam seals behind the Vigil under H2. It is the number H2's whole threat rests on, and it cannot live in a design doc | SYS-001 §10 | Systems (this doc's owner) | H2's tuning, `TEST-H2-01` | **Applied 2026-11-17** — the value sits in SYS-001 §6 next to the other sector numbers, and its trigger-to-change row sits in SYS-001 §10. It is no longer this doc's number to quote |
| **R-02** | A sub-row under `Screen shake`: warp-caused shake capped at **2 px / 0.20 s** `✱`, inside the existing 4 px / 0.25 s row. Warp motion should read as wrongness, not as impact | SYS-001 §9 | Systems | §4.5 parity, AC5 comfort | **Applied 2026-11-17** — SYS-001 §9 now carries the sub-row and states that warp shake stacks *within* the ceiling rather than on top of it |
| **R-03** | A safe-area row: at **200 % text scaling**, the HUD anchors in §4.1 must not overlap each other or clip the frame, at 640×360 logical resolution | SYS-001 §10, TECH-001 §7 | Systems, engineering | §4.4, `TEST-ACC-04` | **SYS half applied 2026-11-17** (SYS-001 §9: warp may hide an element, never displace one). The engineering half is open, and it is where the actual measurement of overlap happens at 200 % text |
| **R-04** | A lock row: the Hourglass Clock's rate is **not writable by any warp effect**. Hiding the clock is legal (§4.3); stopping, slowing, reversing or spending it is not | SYS-001 §10 | Systems | D-01, the H14 clock question | **Applied 2026-11-17** — locked in SYS-001 §10, with the A/B flag `clock_runs_during_exploration` named there as the only open question about the clock. That flag is an experiment, not a warp permission |
| **R-05** | A seed contract: a warp state must be derivable from a seed alone — world tier, Hunger preset and the §3.2 registry state all deterministic per seed `✱` | SYS-001 §10, TECH-001 §7 | Systems, engineering | D-06, any daily or challenge mode | **SYS half applied 2026-11-17** (locked in SYS-001 §10, which now says plainly that no daily or weekly mode exists without it). TECH-001 §7 still owes the implementation of the seed model |
| **R-06** | The eaten-rule Pact registry: the **eight** Pact IDs §3.3 reserves, with their clauses, as real Lantern Tree rows (nine registry rows; H14 has no restore by design and is handled at L-06), and the pre-attach clause bounded by D-03 | LOOP-001 §5 | Loop owner | AC4 (every eat needs a named counterplay), the slice's buildable counterplays | Requested (§3.3) · **blocking for the slice, scoped to two for the slice by D-10** |
| **R-07** | Three Act-0 silhouette frames for the entity (D-04), and an explicit note that the 20-module entity kit does not yet exist in the manifest. This doc does not schedule art work | ART-002, ASSET-003 §6 | Art, producer | D-04, Act 0's whole pretence | Requested · art pass owns it |
| **R-08** | Eighteen eat lines (nine telegraph, nine arrival) in NARR-001 §7's voice set, the reversed-chime convention, and the T4 stem-removal map | NARR-001 §7, AUDIO-001 | Narrative, audio | §3.1 channel two and three, §5.4 | **Delivered 2026-11-17** (NARR-001 §7.3: nine telegraph + nine arrival lines) |
| **R-09** | The Unmaking Rehearsal (§6.2) as a ZONES-001 scripted kit, and a binding contract for the `UiEatAnchor` scene node: an anchor a warp effect can address by name, never by position, so §4.1's anchor set survives level authoring | ZONES-001 §3, TECH-001 §4 | Zone owner, engineering | §4.1, D-02, §7.3 L-10 | Open |
| **R-10** | Two GDD edits this doc will not make itself: a footnote to §3's Run Sigil choice guarantee naming the H14 exception (C-04), and the closure of §20 Q1, Q2 and Q4 with this doc's §6.1 D-01, D-02 and D-04 (not GDD-001 §18's D-01, D-02, D-04) | GDD-001 §3, §18, §20 | Owner | The open-question list in §10 | Raised · the questions are ruled here under the 2026-11-17 delegation (C-08); the GDD edit itself is still the owner's |
| **R-11** | `warp_lint` as a named CI step alongside `manifest_import`, `data_lint` and `palette_lint`, running the fifteen rules in §7.3. D-11 splits it: six data-only rules first, eight needing engine or art hooks second | TECH-001 §1.4 | Engineering | The whole gate. A gate that is not in CI is a suggestion | Requested · **blocking before the first slice build**; interim is a manual checklist at milestone close (D-11) |

Priority, as ruled: **R-06 and R-11 are blocking, and both are now smaller than they looked** — R-06 is two Pact clauses plus one flag rather than nine (D-10), and R-11 has a data-only first tier that needs no engine work (D-11). R-01 to R-05 are closed on the systems side: SYS-001 rev 1.1 took all five rows on 2026-11-17, and only the TECH-001 halves of R-03 and R-05 stay open. R-07 to R-10 belong to other owners.

---

## 9. Conformance

### 9.1 Frozen citations and supersession

Some rows in this doc quote or point at text that another section will later rewrite. The rule for those:

| Rule | Statement |
|---|---|
| Frozen text | A row marked **byte-frozen** may not be reworded, re-ordered or "cleaned up" by a later revision of this doc or of a doc citing it. Its wording is the contract |
| Supersession | Where a frozen citation points at a section that later changes, **the citing row is superseded and the cited text is not**. A pointer written before the target exists is provisional, and the target wins |
| The known case | §2.6 cites LOOP-001 §7 for thread pre-attachment. That pointer was written before LOOP-001 §7 existed and is **superseded** by the byte-frozen pre-attached-threads row in §3.3 and by the ruling in §6.1 D-03. The mechanic is D-03; the LOOP pointer is history |
| Why it is written down | Because a doc that grows in eight chunks will otherwise contain two truths about the same mechanic, and the second one is usually a paraphrase of the first. A paraphrase drifts |
| What a reviewer should do on finding one | Record it as a conformance note in §9.2 rather than silently rewording the frozen row |

### 9.2 Conformance notes

| ID | Finding | Ruling | Action |
|---|---|---|---|
| **C-01** | SYS-001 §2.2 keys its Choir counter-behaviour rows to Hunger levels (`H4`, `H6`, `H8`, `H10`), and this doc keys its eaten-rule registry to the same levels (`H2`, `H4`, …). Two different tables, one namespace | Legitimate but ambiguous. Registry rules are cited as `RULE-Hn` in prose and data; SYS-001's counter rows keep their bare `Hn` | Enforced by lint L-14. No SYS-001 edit needed |
| **C-02** | SYS-001 §2.2 says the eaten-rule list and order are owned by "WARP-001 §6". This doc's registry is at **§3**, and §6 is decisions | This doc's numbering moved during drafting | SYS-001 §2.2's pointer corrected to §3 by the systems owner. This doc does not edit SYS-001 |
| **C-03** | SYS-001 §7.1 carries a `Warp multiplier` (×1.0 / ×1.2 / ×1.5) and GDD-001 §9.1's act table carries a Warp column | Both are per **world tier at run end**, not per sector-local tier. §1.4's rule that a local tier rise pays no score is the same rule seen from the other side | No conflict. Restated in §1.9 so a level designer cannot read the multiplier as a per-sector bonus |
| **C-04** | GDD-001 §3 lists a pity/choice guarantee for Run Sigils. H14 removes a choice, Chronicle-wide | Real tension, resolved in §3.4: the guarantee survives as "no pick is ever taken away", and the loss is the addition of a forced one plus a statement about the entity's reach | Raised as R-10 · owner footnotes GDD-001, not this doc |
| **C-05** | GDD-001 §16 numbers its own open requests (`R-nn`), and this doc numbers §8's requests `R-nn` | Two request namespaces, one vocabulary. GDD-001 §16's effect-budget request is the same shape as this doc's §5.2 envelope | Cite as `WARP-001 §8 R-nn` and `GDD-001 §16 R-nn`. No renumbering — the numbers are already in other docs' text |
| **C-06** | GDD-001 §18 numbers locked decisions `D-nn`; this doc's §6.1 rulings are also `D-nn` | Same finding, same remedy | Cite as `WARP-001 §6.1 D-nn`. D-03's frozen citation in §3.3 already reads that way |
| **C-07** | GDD-001 §9.1 gives Act 4 a Warp column value of 5 with no T4 phase, but §2.5's W4 set is authored as standing content that appears "T4, or above" | Not a conflict: `act_ceiling(4) = 5` is a ceiling and `act_floor(4) = 5` is a floor, so Act 4 is T5 — the W4 set therefore reaches Act 4 through the **Act 3** band where T4 is legal, which is what "or above" means | Recorded so the W4 set is not re-timed by someone reading the act table literally. ZONES-001 schedules Act 3 as the W4 showcase |
| **C-09** | SYS-001 rev 1.1 applied the systems halves of R-01 to R-05: `seam_close_after` in its §6, the warp-shake sub-row and the 200 % safe-area rule in its §9, the clock lock and the seed contract in its §10. It also corrected §2.2's pointer, which closes C-02 | The five requests were written in this doc and taken by the same owner, which is the only reason both files moved in one day | **Applied 2026-11-17.** The `✱` marks on those numbers in this doc are now citations, not inventions; where this doc and SYS-001 disagree about 20 s, 2 px or 0.20 s, SYS-001 is right |
| **C-08** | GDD-001 §20 still carries four open questions. Three are answered here (§6.1 ruling IDs, distinct from GDD-001 §18): D-01 closes Q1 (the clock runs, and is never warp-writable), D-02 closes Q2 (one scripted sequence, never permanent), D-04 closes Q4 (Act 0 shows a silhouette and nothing more). Q3 stays a release decision, bounded by D-06 | The owner delegated these calls on 2026-11-17 (§6.1), so GDD-001 §20 is stale in three of its four rows while the answers live in a doc the owner reads second | Closing §20 in GDD-001 is the owner's edit, not this doc's (§8 R-10). Until it happens, cite the rulings as `WARP-001 §6.1 D-nn`, never as closed GDD questions |

### 9.3 What this doc answers

The coverage claim: which GDD and SYS promises WARP-001 discharges, and where.

| Source promise | Where answered | State |
|---|---|---|
| GDD-001 §8.7 — six tiers with an acceptance gate | §1.1–§1.8 (gate = AC1–AC5), §2 (the sets) | Authored · AC1 clips owed per effect |
| GDD-001 §8.7 — "one trusted rule gone by Act 3" | §3.1–§3.4, `TEST-RULE-01` | Authored · needs the R-06 registry to be playable |
| GDD-001 §8.7 — the onboarding reaction | §1.4 entry rules, §7.4 `TEST-ONB-02` | Authored · measured at a milestone |
| GDD-001 §7.4 and SYS-001 §2.2 — eat cadence and the eat list | §3.2 (nine rows), SYS-001 §2.2 pointer (C-02) | Authored |
| GDD-001 §9.1 — the act/tier table | §1.3 computation, §1.4 entry, §1.5 exit, C-07 | Authored |
| GDD-001 §8.9 — no permanent run loss | §1.9, D-05 and its boundary table | Authored · H14 is the declared exception |
| GDD-001 §10 — HUD that lies and gets eaten, *Steady Ledger*, photosensitivity, 200 % text | §4.1–§4.7, R-02, R-03, `TEST-ACC-01…04` | Authored |
| GDD-001 §11 — art direction, T0 as a costume | §5.1, §5.3, W0 set | Authored · hand-off to ART-001/ART-002 |
| GDD-001 §12 — silence beats and voice as state | §1.9, §5.4 | Restated, not owned |
| GDD-001 §16 — effect budget | §1.8 budget table, §5.2 envelope | Authored |
| GDD-001 §17 criterion 6 — visible in a clip, non-player comprehension | §7.1, §7.4 `TEST-EV-01` | Authored |
| GDD-001 §20 — Q1, Q2, Q3, Q4 | §6.1 D-01, D-02, D-06, D-04 | Ruled under the 2026-11-17 delegation; the GDD edit that closes the list is R-10 (C-08) |
| SYS-001 §2 phase 6 / §2.1 — the Unmaking and its counters | §1.7, W5 set, D-03, H18 | Authored |
| SYS-001 §9 — frame budget, agency loss, shake, zoom | §5.2 (AC5), §7.3 L-03/L-05, R-02, R-04 | Authored |
| SYS-001 §7.1 — score never buys in-run power, Warp multiplier | §1.9, C-03 | Restated, not owned |

---

## 10. Open questions

Ten things this doc cannot close by itself. Each has an owner and a thing it blocks, so the list is a queue and not a wish.

| ID | Question | Owner | Blocks | Working answer until it closes |
|---|---|---|---|---|
| **Q-01** | Does Act 4 eat exactly one rule, or as many as the cadence allows? GDD-001 §20's question about Act 4 is about controls, but the same instinct applies to eats: Act 4 is already the loudest act, and the §4.2 ceiling there is the *lowest* deviation cap in the game precisely because the eaten rules are doing the talking | **Ruled · D-07** | The §3.1 deferral rule, Act 4's pacing | Cadence decides, nothing hand-scheduled; §3.1's one-eat-per-Seam still binds, and the scripted beat in §6.2 does not consume a slot. D-07 names the evidence that would change it |
| **Q-02** | Is 20 s the right seal delay for H2, or does it read as a punishment rather than a consequence? | Systems, resolved by `TEST-H2-01` and the slice | R-01, H2's whole design | 20 s, because it is long enough to matter and short enough that a mistake is recoverable |
| **Q-03** | T3's cost headroom is 0.02 ms in §5.2 — the tightest number in the game. Does the T3 standing set carry one effect too many? | Systems + engineering, at the first profile-rig run | Whether W3-04 or W3-05 gets a permanent reduced variant | Reduced variants are already on by default at T3; the rig decides which of the two pays |
| **Q-04** | Do mirrored HUD elements (the Mirror tell family, W3-03, W3-08, W5-06) need their own accessibility treatment? Mirrored type is a known legibility problem for some readers, and unlike colour it is not covered by any existing setting | Design + accessibility review | §4.4's toggle list, possibly a new SYS-001 accessibility row | For now the Mirror family never mirrors **type**, only layout and glyph position. If a tester reports mirrored text as unreadable, the family loses text mirrors entirely |
| **Q-05** | Should photosensitivity default to on for the T5 plate-break and ribcage passes specifically, even when the global mode is off? T5 is the tier most likely to trip it and the least likely to be missed | Engineering + design | §4.5 defaults | No. A global setting that changes itself per sector is a setting players cannot trust |
| **Q-06** | Is H14 too strong for a game that sells itself on no permanent loss? §3.4 argues the distinction between choice and possession holds, and it may be the single most divisive call in the design | **Ruled · D-08** | C-04, R-10, and whether H14 ships at 1.0 at all | It ships at 1.0 behind §3.4's three hard conditions, with the run-scoped fallback authored in D-08 as a one-line reversal |
| **Q-07** | Should the Unmaking Rehearsal exist in NG+ at all, or is a once-per-Chronicle beat the right size for a game people will play forty Iterations of? | **Ruled · D-09** | §6.2's once-per-run scope, LOOP-001's NG+ plan | Once per run, content beats rotated against that run's eaten rules, skippable from the first watch in NG+ |
| **Q-08** | Which three of the nine registry rules ship in the slice? All nine are authored, and the slice cannot afford nine eats plus nine Pact counterplays plus nine tests | **Ruled · D-10** with the producer | Slice scope, R-06's first tranche | H2, H4 and H14: two Pact clauses (PACT-01, PACT-04), and H14 carrying its no-restore flag instead of a Pact. The other six clauses stay requests until Act 3 is scheduled |
| **Q-09** | Does the Chalk tell family need a colour that no one else uses? Chalk is currently BONE registers, which the Vigil's own feedback also draws on, so at T4 the chalk frame and the player's hit feedback are neighbours | ART-001, ART-002 | §4.2's tell families, the palette's 32 entries | Chalk stays BONE. If the collision reads as clutter in the slice, the tell moves to a line weight, not to a new colour (§5.1) |
| **Q-10** | Is the effect budget right at three novel transients per sector? It is inherited from GDD-001 §16's request and has never been measured against a played sector | Systems, after the first vertical slice | §1.8, L-13 | Three. It has never yet felt like too many on paper, and paper is not evidence |

Four of these are ruled as of 2026-11-17 — Q-01, Q-06, Q-07 and Q-08, at D-07 to D-10 — on the owner's delegation recorded in §6.1. Each carries its own reversal condition inside its ruling, so a later reversal is a recorded change rather than a rewrite of this doc. The remaining six resolve against a measurement: a test result, a profile rig, or a played sector. That is the preferred way for this system to change its mind, and it is why the numbers in §5.2 are marked `✱` rather than defended.

---

*End of WARP-001. Where a number here and a number in SYS-001 disagree, SYS-001 wins and this doc is the bug.*
