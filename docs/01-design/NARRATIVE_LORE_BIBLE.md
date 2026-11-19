# DARKSTAR — Narrative & Lore Bible

**Doc ID:** NARR-001 · **Version:** 1.3 · **Date:** 2026-11-18 · **Owner:** narrative · **Status:** complete-draft — §0–§14 written; Codex has 45 sample entries (LOOP-001 §8.2 ID scheme) and a style guide, the full entry set is owed (§14 Q-10)
**Rev 1.2 (2026-11-18):** cosmic horror design rev 3 applied (PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3; CHD-01, -04, -09, -11, -15, -16): N-rules (§3.4), borrowed entity lines and the borrowed face (§3.2, §4.5), Choir liturgy fragments (§2.1), Penitents you meet are you (§2.3, §5.5), L12 discrepancy lines (§7.2), biome grief (§6.5), the Codex gates rule nodes instead of paying Ink, rumours, the 27 gating ids and their reconciliation (§8.3, §8.6, §8.7), new questions Q-11…Q-16 (§14). **Same-day reconciliation (2026-11-18):** gating ids folded (`cx_choir_acolyte`, `cx_choir_deacon`, `cx_place_the_drowned_observatory`, `cx_rule_the_glimpse`) and LOOP-001 §8.2's classes widened, recount 144 (§8.2, §8.6, §8.7); L12 keys are `MSG_DEATH_LIE_*`, Compass live, Charges and Index reserved (§7.2); the D-04 amendment noted under N1 (§3.4); the Procession has no Matron (§8.4); Relic wording retired (§5.3); Q-11, Q-15, Q-16 closed, Q-12 closed except the Hollow sector's two entries.
**Rev 1.3 (2026-11-18):** Act 1 vertical slice applied (PM ruling 2026-11-18 (owner grant), Act 1 vertical slice; `research/act1_vertical_slice.md` beats 7–11): new §5.7 *The first Ruins visit* (who is present, Sable's three first-visit chalk lines, the Cabinet's ticket payout "SCORE BANKED", the stamped Pretence page); §7.5 and §7.7 inventory updated; §4.5's first-words pointer now cites §5.7; `cx_place_act0_3`'s body extended (§8.4), no new Codex id (§8.7). **Same day, amended after The Reviewer's notes:** Q-T102 resolved (on the first visit the chalk writes itself, no hand; line 1 now "You're back. Most aren't."; the old "first visit" Pact line re-triggered to the first Pact offered); §5.7 gains the physical launch gate (Sable's chalk "Light one. The dark is long.") and EMBER printed on the tickets; §3.4 N8 gains the first Unmaking's erasure origin (TECH-001 §11.1 Q-T103, resolved).
**Upstream:** `docs/01-design/GDD_DARKSTAR_v0.2.md` (GDD-001) · `docs/01-design/SYSTEMS_BIBLE_STATS.md` (SYS-001) · `docs/01-design/ROGUELIKE_LOOP_AND_LANTERN_TREE.md` (LOOP-001)
**This doc owns:** the fiction, the factions' theology, the entity's interior logic, the Ruins' cast, the Codex prose, the endings as fiction, the chronicle, the writing's refusals, and the voice/text inventory outside the entity's state announcements.

No number is stated here as a second copy. Where a value exists in SYS-001 it is cited by section (`SYS-001 §2.2`), never restated — the SYS-001 §0 rule. Names invented here that are not in GDD-001 §19 are collected in §2.4 and flagged in §14. The 1983 original is never named in this doc (RES-001 §5).

Parameters invented by narrative with no upstream source carry `✱` (SYS-001 §0 convention: first-pass judgement value, verify in the slice).

---

## 0. How to read this doc

### 0.1 What this doc answers

| If you are… | Read | Then |
|---|---|---|
| new to the project | GDD-001 §1, then §1 here | §3 (the entity), §10 (what really happened) |
| writing a Codex entry or a terminal text | §7, §8 | §11 (what the writing refuses), GDD-001 §19 vocabulary |
| writing NPC dialogue or a hub scene | §5, §8 | §4 (register), §11 |
| placing lore on a sector or a kit | §6, §7 | ZONES-001 §2–§3 (the kit's own fiction column) |
| doing endings, save-state fiction, or NG+ framing | §9 | GDD-001 §9.3, LOOP-001 |
| writing store copy or a press kit | §10's spoiler table, §12 | MARKET-001, RES-001 §5 |
| checking whether a name is allowed | §2.4, §13 | GDD-001 §19 |

Cross-doc IDs used here: GDD-001, SYS-001, LOOP-001, ZONES-001, WARP-001, NARR-001, AUDIO-001, ART-001, ART-002, ASSET-003, TECH-001, PROD-001, MARKET-001, RES-001.

### 0.2 Which doc owns what

| Subject | Owner | This doc's role |
|---|---|---|
| Systems, loops, acts, endings list, pillars | GDD-001 | explains *why* each is true in fiction; never re-decides |
| Every number, budget, threshold, table | SYS-001 | cites rows by section; states no number as a source |
| Lantern Tree nodes, Pacts, Relics, Run Sigils, ending triggers | LOOP-001 | gives each a name-meaning and an in-fiction motive |
| Sectors, biomes, kits, encounter flavour | ZONES-001 | supplies the lore text that sits on those kits; does not place them |
| Warp Tiers, eaten rules, HUD lies | WARP-001 | supplies the in-fiction *cause* of a warp, never its mechanic |
| **The entity's spoken state lines, the chant text, all audio** | **AUDIO-001** | cross-references its IDs; authors only the lines outside its set |
| **Codex prose, the Ruins cast, endings as fiction, the chronicle, voice inventory (non-entity), the writing's refusals** | **NARR-001 (this doc)** | — |
| Palette, silhouette language, Lovecraft rules | ART-001 | states the *meaning* a palette carries, not the values |
| IP guardrails and the 1983 comparison | RES-001 | applies them per-line and per-name; §12 here |

The ownership boundary stated in AUDIO-001 §0 holds: the entity's **state announcements** are audio's; the **Codex prose, the Ruins scene script and the endings' fiction** are narrative's. Where a beat needs both, this doc writes the scene and AUDIO-001 writes the line spoken over it.

### 0.3 Reading rules for anyone writing into this doc

| Rule | Effect |
|---|---|
| **True vs doctrine.** Every cosmological claim is marked `TRUE` (the reference layer, §10 agrees) or `DOCTRINE` (what the Choir believes). A line of in-world prose may be doctrine; a reference row may not be ambiguous | the writers' room never argues about what "actually" happened; the argument happens in the fiction, where it belongs |
| **The entity is never evil.** §3.4 states what writing about it is forbidden | prevents the single most common way this project would become ordinary |
| **Grief is the subject, not the mood.** Every named character, Codex entry and ending is *about* a loss with a fact attached | keeps the horror specific rather than atmospheric |
| **Vocabulary is GDD-001 §19 only**, plus §2.4 of this doc | a name that appears in one place and not in the glossary is a bug |
| **No gore, no jumpscares, no moral-choice HUD** (§11) | the ESRB T target (GDD-001 §2) is a *narrative* constraint, not just a rating strategy |

---

## 1. Cosmology

The reference layer of DARKSTAR is deliberately small. Everything the game says is either a fact the player can verify against state, or a belief a character holds. §1 marks each claim. The chronicle of §10 is the only place the two are merged, and it is written for staff.

### 1.1 The Unborn Dark

| Claim | Status | What it means in play |
|---|---|---|
| Before the star, there was the **Unborn Dark**: not a place and not a god, an *unfinished state* — a stretch of reality that was never given rules | TRUE | the reason the game's rules can be eaten at all: rules here were always provisional (WARP-001 §6) |
| The Unborn Dark has no will, no appetite and no malice. It has **incompleteness** | TRUE | the entity never monologues a plan; it states states (AUDIO-001 §4 rule: a line exists because a SYS-001 row changed) |
| A ruleless region resolves toward *some* order the way water finds a level. It does not choose; it **fills** | TRUE | the entity building itself out of the only material available (SYS-001 §2 phase 1) is physics, not ambition |
| Nothing in the system is *damned* by the Unborn Dark. Unmade things do not suffer; they stop | TRUE | §11's refusal of gore and torment. The horror is subtraction |
| The Unborn Dark is not the enemy of light. Light is one of the orders it can take | TRUE | the Lantern is not a holy symbol; it is a *draft* of the thing the entity is writing (which is why the entity can read a lamp the way it reads a gun) |

The single sentence the writers keep on the wall: **the Dark is not what is left when the light goes out; it is what was there before the light was decided.**

### 1.2 The Ninth Sky, and the star that failed

The system's cosmology, as the Choir teaches it and as §10 confirms it in plain fact:

| # | Claim | Status |
|---|---|---|
| 1 | A star was made in this system — not born, **made**: nine skies were folded into a fuel and lit | TRUE |
| 2 | The making was done by people, with tools, and it cost them something they did not name at the time | TRUE (§10, the chronicle) |
| 3 | The star failed. It did not go out; it **did not finish lighting** | TRUE |
| 4 | A star that does not finish lighting does not stop being a star. It keeps the shape of the intention and loses the light | TRUE |
| 5 | Nine skies were folded into it. When it failed, they were not returned. They became the **Nine Hollow Skies** — layers of reality with the shape of a world and no light in it | TRUE |
| 6 | The failure left a hole in the rules, and the Unborn Dark moved into the hole wearing the star's unfinished shape. That is **Nhael'Gharoth, the Waking Dark** | TRUE (§3) |
| 7 | The star's grief at failing is a *substance*, because in this system an unfinished intention is a substance. That substance is **Mourning Glass** | TRUE |
| 8 | The Choir teaches that the star failed *on purpose*, that it is a wound the universe made to be reopened, and that reopening it is the universe's cure | DOCTRINE (§1.5) |
| 9 | The Choir teaches that the nine skies are a debt being paid back | DOCTRINE |
| 10 | The Church-like phrase "the Ninth Sky" means two different things in two different registers, and the game keeps both | TRUE (§1.4) |

The star that failed is not a sun with a face. In art it is the absence at the centre of the Ledger Compass where a sun should be (ART-001 §2, the ordinary thing that is not ordinary), and in the fiction it is an intention that never completed.

### 1.3 Mourning Glass is grief made mineral

This is the load-bearing fact of the whole fiction, and it is why the core loop *feels* right instead of merely coherent.

| Layer | Statement | Play consequence |
|---|---|---|
| Physical | Mourning Glass is the crystallised residue of an unfinished intention: it forms where something was meant to happen and did not | geodes sit in the ruins of the making, which is why the ore is everywhere and the sky is nowhere |
| Emotional | It is grief made mineral in the strict sense: the substance a loss becomes when the loss was never finished processing | the ore is *not* fuel, not currency and not a MacGuffin. It is unprocessed sorrow with a hardness rating |
| Moral | Glass remembers the shape it was asked to hold. A Charge fired at the entity is a piece of the failed star being handed back to it | SYS-001 §1.4's Unravel hit is diegetically a *return*, which is why the entity calls the glass its own (AUDIO-001 §4.6 "MY GLASS. / MY BODY.") |
| The loop's cruelty | The same glass builds the god and unbuilds it. Segment points and Unravel hits are the same ore moving in opposite directions (SYS-001 §2 phase 1 vs §1.4) | the boss-build race is not a gimmick; it is the theme expressed as a resource conflict |
| The player's position | Mining is not harvesting. It is *excavating an unfinished mourning*, and every shard you take is a shard the dead god will not get back this lap | the Grubs' keening when a deposit dies (SYS-001 §3) is a funeral interrupted by a thief |

Writing rule for all ore text: never describe Mourning Glass as valuable. Describe it as *grieving*. Value is what the Choir and the Ledger Compass disagree about.

### 1.4 Two registers of the same words

| Term | Arcade register (Act 0's costume) | Fiction register (Acts 1–4) |
|---|---|---|
| "the sky" | the level you are on | a completed layer of reality the entity can finish eating |
| "the Ninth Sky" | a high score screen's boast | the hub's own address: the Ruins of the Ninth Sky, the last sky to go dark and the only one with a scar thick enough to hide in (§4.3) |
| "the Choir" | an 8-bit jingle | a congregation with a liturgy, a hierarchy and a funeral for every deposit (§2) |
| "the Dark Star" | the boss sprite | the unfinished star wearing the hole in the rules (§3) |
| "score" | points | the **Vigil Index**: the Choir's way of remembering how much damage you did, spoken back at you (AUDIO-001 §4.12) |
| "extra life" | 1UP | a **Second Vigil**: the Lampkeeper refusing, once per run, to have died (LOOP-001 HULL-6; AUDIO-001 §4.13 "YOU HAVE ONE LEFT.") |

The costume's vocabulary is not a lie the game tells the player; it is the vocabulary of the propaganda the system used to tell itself the loop was a game (§4.4). Act 0's honesty is historical, not cynical: somebody *did* run this as a vigil-quota arcade rotation, and the machine on the wall is their machine.

### 1.5 What the Hollow Choir believes, and why it is internally consistent

The Choir is not a cult of devil-worshippers. It is a funeral society that worked out the physics and reached the wrong conclusion from correct data.

| Choir premise | The evidence | The inference | Is the inference correct |
|---|---|---|---|
| The sky is made of glass that grieves | they can mine it, weigh it, sing to it | grief is the fundamental substance of the world | partly: glass is grief made mineral (§1.3), but it is a *residue*, not a source |
| The star failed, and it was *asked* to fail | the making left tools; the tools were used on the star | therefore someone chose the failure and the choice was a sin | FALSE. §10 states who did what; the Choir's list of guilty is wrong and their list of tools is right |
| A thing that did not finish can be finished | the Sepulchre works: 20 segments and the structure wakes | therefore completing the star is the repair of the universe | FALSE in direction, TRUE in mechanism: the entity does wake, and waking is not repair |
| Nine skies are nine wounds; healing means closing them | the Hourglass Clock darkens skies on a schedule | therefore the darkening is a treatment in progress | FALSE. It is appetite (SYS-001 §2.2) described as medicine |
| The Lampkeeper is an apostate who hoards the medicine | the player steals deposits, every run, forever | therefore the player is an obstacle to salvation | TRUE from inside their premises, which is the point: the Choir is *consistent*, and you are the antagonist of their hymn |
| Every death is a deposit; nothing is wasted | the Grubs mourn a lost deposit audibly (SYS-001 §3) | therefore death is transport, not ending | UNDECIDED by design. No ending confirms or denies an afterlife; the writing refuses the question (§11.6) |

Why the theology holds together (and why the art and audio must never wink at it):

| Property | How it is expressed |
|---|---|
| The Choir is **correct about the physics and wrong about the ethics** | they built a machine that genuinely wakes a god (SYS-001 §2) — the player cannot debunk them by proving the ritual does not work |
| Their ritual has an **honest gap in it** | the Litany Ring is nine syllables with eight nodes, always one short (AUDIO-001 §5.1). Their own ceremony tells them something is missing, and they read the missing node as humility rather than error |
| They grieve in real time | a destroyed deposit produces audible keening (SYS-001 §3, AUDIO-001 §5.2 F06). Killing a Grub procession is interrupting a funeral, and the audio says so |
| They refuse to fire near sacred ground | units hold fire within 120 px of a Shrine (SYS-001 §3.1). Their faith constrains their own violence, which is what makes them people (GDD-001 §3 P2) |
| Nobody in the Choir is lying | no Choir line in this doc is a bluff. When a Deacon casts a phantom, the Deacon *believes the lie is a mercy* (§2.2) |
| Their eschatology is modest | the Choir does not want to rule. It wants the service to finish. Power is a burden they keep declining to take seriously (§2.1) |

The design payoff: because the Choir is coherent, the player's contempt for them curbs itself, and by Act 2 the fiction asks — in the words of §7's Codex and §5's cast — whether refusing to grieve is its own error. That question is the reason GDD-001 §9.1 lists "the Choir's religion becomes sympathetic" as the Act 2 reveal.

### 1.6 The three things the reference layer will not say

| Withheld | Why |
|---|---|
| Whether the Unmaking of a sky is recoverable by any means | it would either cheapen Hard Unmaking or make it a bluff; SYS-001 §8 handles it as a fact of state, and no prose is allowed to editorialise |
| Whether the entity, once unmade, becomes something else | only ending 3 and ending 4 take a position, and they take opposite ones (§9.3, §9.4) |
| Whether any character in the Ruins is a previous Lampkeeper in disguise | §5 leaves exactly one such hint (Sable Vane) unconfirmed on purpose. It is a thread, not a fact, and §14 Q-07 records it as unresolved |

---

## 2. Factions

Three groups have a stake in the Ninth Sky. Only one of them is still alive in the usual sense.

| Faction | Status in play | One-line truth | Section |
|---|---|---|---|
| **The Hollow Choir** | the enemy, present in every Seam | a funeral society that grew into the shape of its grief and kept working | §2.1–§2.2 |
| **The Lantern Office** | gone; survives as buildings, posters, ledgers, the Cabinet and the loop itself | the civic body that tried to light a made star and could not stop trying | §2.3 |
| **The Lampkeepers** | one left: you. Echoes remain (the Penitent) | conscripts who flew the Vigils, were told it was a game, and were not lied to about the danger, only about the odds | §2.3 |

### 2.1 The Hollow Choir — hierarchy and liturgy

The Choir has no pope, no throne and no celebrant. The service is performed *at* the Sepulchre *for* an absent god by people who are not sure the god will come. That is the whole of their humility, and it is why their eschatology stays modest (§1.5): nobody in the Choir expects to be rewarded. They expect the service to be finished.

| Rank (Choir title) | Unit (GDD-001 §19) | Liturgical role | What they believe they are doing | How their death reads in fiction |
|---|---|---|---|---|
| **The Carried** | Oubliette Grub | the laity; they carry glass to the altar | returning a piece of the sky to the one it belongs to. Every shard is a name | a dropped offering. The keening (SYS-001 §3) is the procession mourning the shard, not the Grub |
| **The Vested** | Acolyte (Censer Knight) | guards of the rite; the only rank permitted to mine | keeping the altar safe so the carried can finish | a censer going out. Acolytes are buried with the censer *lit* if anyone survives to do it; nobody usually does |
| **The Comforters** | Deacon of Lies | consolation; the phantoms are their work | showing the grieving that the dead still move (§2.2) | a sentence stopping halfway |
| **The Tithe-Takers** | Grave-Tide Deceiver | collection; they take Charges | returning glass that was stolen from the dead. A Charge in your magazine is, to them, a grave you robbed | a debt left unpaid, which in Choir law passes to the next Deceiver |
| **The Confessors** | Listener | penance; blind, they hear | listening for the sin of the service — and the only sin they can hear is gunfire | a silence that lasts. The Choir considers a Listener's death the one honest death |
| **The Mothers** | Choir Matron | precentors; they lead the Litany and birth the Carried | keeping the count of the hymn so nobody sings out of turn | the chant stopping. A Matron killed rather than silenced leaves the hymn without a count, and the sector *rains* (SYS-001 §3) — the Choir calls it "the weeping without a leader" |
| **The Six** | Herald (SYS-001 §5.2, six named) | emissaries; each carries one memory of you | bringing the god what it asked for: knowledge of its thief | an errand ended. Heralds are the only Choir who are proud |
| **The Rites** | Matron of the Drowned Chorus, the Censer Cardinal, the Unnumbered, Grave Tide, Your Own Vigil (SYS-001 §5.1) | the high ceremonies at Seam 3 and Seam 5 gates | marking that the service has reached a station | a station passed. The Choir does not mourn a Rite; it moves to the next one |

**Not Choir.** The Penitent is not a rank (§2.3, §5.5). The Choir does not shoot it and does not understand it; their scripture calls it "the one who weeps at the wrong funeral".

**The Choir's life cycle (lore only, no mechanic).** A Carried who completes nine deposits without dropping one is *vested* and becomes an Acolyte; an Acolyte who carries a Matron's count through nine services becomes a Mother. Nobody in living memory has done either. The Choir keeps the rule anyway. A rule you never reach is still a direction.

**Liturgy in four parts** (the order the player hears it, AUDIO-001 §5):

| Part | Choir name | What it is | What the player sees |
|---|---|---|---|
| 1 | **The Carrying** | processions bring glass | Grubs on routes (ZONES-001 §6.4) |
| 2 | **The Litany** | written in nine syllables, sung in eight over eight ring-nodes, always one short (AUDIO-001 §5.1) | the Litany Ring (SYS-001 §3.1) |
| 3 | **The Quickening** | the hymn hurries because the body twitches | phase 3 (SYS-001 §2) |
| 4 | **The Silence** | the hymn stops on purpose so the god can speak first | the 1.2 s silence before the Awakening line (GDD-001 §12) — the Choir's most sacred beat is a held breath |

**Liturgy fragments (samples; PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-16).** Choir register (§4.1): sentence case, present tense. The Litany is **written in nine syllables and sung in eight, always one short**: the ninth is the late ninth voice's, and only ending 3 sings it complete (§9.3). The 8-syllable sample lines below are the sung form (§14 Q-11, closed 2026-11-18). Where these appear (Codex *Choir:* quotes, captions, or chant) is open: any sung or spoken form is AUDIO-001 §5's (handed to the Game audio chat).

| # | Line | Who, when | Check |
|---|---|---|---|
| 1 | *Bear the glass where the light was meant.* | a Litany line | 8 syllables |
| 2 | *Carry it gently. It is someone's.* | the Carried's bearing words | present tense (sample read "It was someone's"; fixed to the register's present tense) |
| 3 | *We are not afraid of the dark. We are afraid of it ending unfinished.* | doctrine | — |
| 4 | *The ninth voice is late. The ninth voice is always late.* | doctrine; the gap | — |
| 5 | *Lampkeeper, you carry fire into a house of mourning.* | a Matron, on being silenced | — |
| 6 | *Let it pass. Let it pass. Let it pass over.* | the Comforters, at the leading edge of a Passing (WARP-001, the Passing, CHD-02) | — |

**The Salt Mother.** The Choir's only saint is a Matron who, during the first service anyone remembers, salted her own Sepulchre so it could not take the last deposit, then sang the Litany to the end anyway. The Choir venerates her for finishing the hymn, not for stopping the god; they have never noticed the contradiction, or they have and they keep it. Her favour is the name of PACT-24 (LOOP-001 §7.3): *a face you never mine stays clean.* The Salt Mother is the only Choir figure Brother Wick still prays to (§5.3).

### 2.2 The Deacons, and why a phantom is a mercy

Deacons of Lies cast phantom Grubs and Acolytes (SYS-001 §3). The player experiences them as deception. The Deacons experience them as consolation.

| The player sees | The Deacon means | TRUE |
|---|---|---|
| a phantom Grub that cannot be shot | "the carried are still carrying — look" | the phantom is shaped from the memory of a Grub that died in this sector. Deacons cannot invent; they can only repeat |
| a phantom Acolyte that drains Composure | a eulogy: an honour guard that walks the dead home | the drain is real because grief is a substance here (§1.3). Looking at a eulogy costs something |
| at T3, a phantom of **your own Vigil** (GDD-001 §8.5) | they are mourning you in advance | the Deacons have seen enough Lampkeepers die to know where this goes. It is the kindest thing anyone in the Choir does for you, and it nearly kills you |

**Writing rule:** a Deacon line, a Codex entry about Deacons, or a Deacon's death sound never frames the phantom as a trick. The word "lie" belongs to the GDD-001 §19 unit name, which is what the *Lantern Office* called them (§4.4). The Choir calls them Comforters.

### 2.3 The Lantern Office and the Lampkeepers

**The Lantern Office** was the civic and religious authority of the inhabited system under the old, failing sun. It was not evil. It was a ministry faced with a dark coming slowly and an engineering answer that almost worked. It folded nine skies into fuel, built the **Ninth Sky Observatory** to light the **Ninth Light**, and when the light did not finish, it did what ministries do: it kept the programme running, renamed the failure a vigil, and staffed it (§10).

**The Lampkeepers** were the staff. They flew **Vigils** — brass lantern skiffs — into the Hollow Skies to mine Mourning Glass, on quotas, in shifts the Office called vigils. Recruitment ran through Vigil halls, and every Vigil hall had a training cabinet titled DARKSTAR, built by an Office engineer named **Theodora Lune** (§5.4). Lampkeepers wore a brass ring set with a small lamp; the lamp was lit at enlistment and was supposed to be relit at discharge. Very few were.

**The Penitent** is what is left when a Lampkeeper dies with the lamp lit. It is not a ghost (§11.6 — the writing does not decide whether there is an afterlife). It is a residue, like glass is a residue: an intention to come home, unfinished, drifting through danger because that is where it was last going. Shooting it grants a Vigil Boon (SYS-001 §3) because what it carries is a last act of help that never landed. The Choir took the lanterns of the dead as relics; three of those salvaged lamps are visible on Choir bodies (the Deceiver's offering lamp, an Acolyte's broken halo, the Penitent's own broken ring — ART-001 §4 law 1 exception). None of them is lit. No Choir hand has ever lit a lantern.

**The Penitents you meet are you** (PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-09). The player is the last Lampkeeper, and the player dies with the lamp lit. So in a Chronicle, a Penitent drifting where you once fell (ZONES-001 §4.5, death-site Penitents) is *your* residue: your own intention to come home, still going. It is the same Penitent as any other (shoot it, be blessed; SYS-001 §3) and shares its sector cap with the Coma Penitent (SYS-001, death-site Penitent cap row). `TRUE`: the death sites survive Hard Unmaking (LOOP-001 §2, anchored state) because a lit lamp left behind is an unfinished intention, and unfinished intentions are the one thing in this system that keeps (§1.3). The writing still refuses the afterlife question (§11.6): it is *what you left*, never *where you went*. Never call it a ghost, a copy or "your spirit"; never let a line say "you died here".

### 2.4 Names registry

Every proper name used in any DARKSTAR doc, string or asset that is **not** in GDD-001 §19 must have a row here before it ships (§13). Names in GDD-001 §19 are not repeated.

| Name | Kind | Introduced by | Meaning / note | Spoiler tier (§10.3) | Status |
|---|---|---|---|---|---|
| the Unborn Dark | cosmological state | NARR §1.1 | the ruleless state the entity is made of | S2 | canon |
| the Ninth Light | the made star | NARR §10 | the star that did not finish lighting; the Choir calls it the Star That Failed (GDD-001 §8.4) | S2 | canon |
| the Old Light | the original, failing sun | NARR §10 | dimming for generations before the making | S1 | canon |
| the Lantern Office | faction (historical) | NARR §2.3 | civic-religious ministry of the system | S1 (name) / S3 (what it did) | canon |
| the Ninth Sky Observatory | place | NARR §2.3 | the instrument of the making; today's Ruins | S2 | canon |
| the Ruins of the Ninth Sky | place | GDD-001 §6.4 | the hub; the Observatory's scar | S0 | canon |
| Vigil hall | place type | NARR §2.3 | Office recruitment and duty halls, one Cabinet each | S1 | canon |
| Theodora Lune | person (absent) | NARR §5.4 | the cabinet-maker; Office engineer | S3 (name) / S4 (message) | canon |
| Sable Vane | person | NARR §5.1 | keeper of the Chalk Desk | S1 | canon; Q-07 open |
| Ilse Marrow | person | NARR §5.2 | the Archivist; last Office clerk | S1 | canon |
| Tomas Marrow | person (dead) | NARR §5.2 | Ilse's brother, Lampkeeper | S3 | canon |
| Brother Wick | person | NARR §5.3 | a lapsed Acolyte; tends the Lantern Tree | S1 | canon |
| Mother Ashe | person (dead) | NARR §5.3 | Wick's Matron, killed rather than silenced | S2 | canon |
| the Cabinet | object / presence | NARR §5.4 | Theodora Lune's DARKSTAR training cabinet on the Ruins wall | S0 (object) / S3 (purpose) | canon |
| the Archivist | ending variant / Ilse's title | GDD-001 §9.3 | ending 5's variant | S4 | canon |
| the Carried / the Vested / the Comforters / the Tithe-Takers / the Confessors / the Mothers / the Six / the Rites | Choir rank titles | NARR §2.1 | Choir's own names for its units | S2 | canon |
| the Carrying / the Litany / the Quickening / the Silence | liturgy parts | NARR §2.1 | the four parts of the service | S1 | canon |
| the Salt Mother | Choir saint | NARR §2.1; LOOP-001 PACT-24 | the Matron who salted her own Sepulchre | S2 | canon |
| the Hollow King | entity epithet | GDD-001 §8.4 | Choir name for the entity | S0 | canon |
| the Star That Failed | entity epithet | GDD-001 §8.4 | Choir name for the Ninth Light | S0 | canon |
| the Pretence | Office term | GDD-001 §6.1; NARR §4.4 | the Office's name for the training rotation; "THAT WAS A PRETENCE." | S0 (line) / S3 (meaning) | canon |
| the Chronicle | meta term | LOOP-001 §6 | the whole history of a save across Iterations | S0 | canon |
| the Unmaking Rehearsal | scripted sequence | WARP-001 §6.2 | Act 4's one input-denying beat | S2 | canon |
| Pact of Ascension (**PACT-ASC**) | Pact | GDD-001 §9.3; LOOP-001 §11.4 | a 25th Pact outside the pool, offered only by Sable Vane; ending 3 | S3 | canon |
| the Ninth Gate | place | LOOP-001 §11.5 | opens at the Lantern Tree's root when Thread V is bought; the way into Act 4 | S2 | canon |
| the Archive | room | LOOP-001 §8.5 | Ilse's records room, opened at 25 % of the Codex | S1 | canon |
| the Annotated Choir | Codex milestone | LOOP-001 §8.5 | chalk ticks on Choir wind-up frames, granted by completing `cx_choir_` | S1 | canon |
| The First Dark · The Bell With No Clapper · The Ledger Opens · The Cathedral Learns Your Name · Lattice · The Unlit Room · The Choir Sings Your Name · The Ninth Sky Remembers | Hard Unmaking beats | LOOP-001 §10.4 | §4.3, §5.6 | S1 (names) / S2 (scenes) | canon |
| T.L. · 0 WARD 0 SURGE | Cabinet honour-roll line | LOOP-001 §11.6 | Theodora Lune's own score; the ending 5 hint | S0 (as text) / S3 (meaning) | canon |
| Herald of the Ninth Sky / Salted Chord / Long Vigil / Broken Censer / Quiet Pew / Ninth Reckoning | elites | SYS-001 §5.2 | the Six (§2.1) | S2 | canon |
| Matron of the Drowned Chorus / the Censer Cardinal / the Unnumbered / Grave Tide / Your Own Vigil | Rites | GDD-001 §9.2 | §2.1 | S1 | canon |
| PACT-01…24, REL-01…18, LT/SIG names | Pacts, Relics, nodes, Sigils | LOOP-001 §3–§7 | names are LOOP's; meanings must not contradict §2–§6 here | S1 | canon (LOOP owns list) |
| kit names (PM-01 … BK-04) | Encounter Kits | ZONES-001 §3 | names are ZONES'; §6 gives their fiction | S1 | canon (ZONES owns list) |
| the oubliettes | place type | NARR §6 | the pits under shrines where the Carried are born | S2 | canon |
| the honour roll | Office artefact | NARR §4.4 | the Cabinet's high-score table, which was the enlistment list | S3 | canon |

---

## 3. The entity

### 3.1 What Nhael'Gharoth is

| Claim | Status |
|---|---|
| It is the Unborn Dark wearing the shape of an unfinished star (§1.2 row 6) | TRUE |
| It has no plan. It has a **direction**: toward completion, the way water has a direction toward level (§1.1) | TRUE |
| It builds itself from Mourning Glass because glass is the only material in the system that already has the star's shape in it (§1.3) | TRUE |
| It remembers you because **a habit is an intention**, and in this system an unfinished intention is a substance it can use. It does not study you. It is made, partly, of what you keep doing | TRUE — this is the fiction under SYS-001 §2.2 counters and AUDIO-001 §4.11 |
| It eats skies because a hollow sky is the nearest unfinished thing | TRUE |
| It is a god | DOCTRINE (the Choir's word). The TRUE layer never uses it |
| It hates you | FALSE. Nothing in the TRUE layer hates. "RUN, LITTLE LANTERN" is not a taunt; it is a state |

### 3.2 Where its voice comes from

The entity has no language of its own. **Every word it says is a word somebody in the system said first** — it speaks in the residue of other people's sentences, the way it builds in the residue of other people's grief.

| Source of its words | Example | Where the player can verify it |
|---|---|---|
| the Cabinet's marquee and attract text (§5.4, §7.5) | "LITTLE LANTERN" was the Cabinet's name for a new player: *INSERT CREDIT, LITTLE LANTERN* | the Cabinet in the Ruins still shows it in attract mode |
| Office duty logs | "YOU BUY TIME" was the Office's phrase for a shift that ended without a sky lost | `cx_glass_` Codex entries quote the logs (§8) |
| the Choir's Litany | "THE STRUCTURE TWITCHES" is a line of the Quickening | AUDIO-001 §5.1 |
| your own play | the death clauses (AUDIO-001 §4.10) are your telemetry in its mouth | the keys are printed under the line |

This is a TRUE fact and one of the slow reveals of Act 2–3 (§10.3 tier S3): players who read the Cabinet's attract text in the Ruins will recognise the entity's vocabulary in it. Nothing in the game points this out. The Codex never states it. Ilse's marginalia comes closest, once (§8.4, `cx_ruins_cabinet_02`).

**It borrows the voice and the face** (PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-16). Its lines are borrowed words, delivered unprocessed (AUDIO-001 §4.3: dry, flat, no growl or pitch work): nothing is added to them, because nothing in them is its own. From Act 1 the face its lines are set in is the Cabinet's (§4.5). The cheerful voice of Act 0 is the one that talks to you in the dark.

**Borrowed lines (samples; each line names its source).** Entity register (§4.1): ALL CAPS, 1–8 words, true when spoken (AUDIO-001 L2). AUDIO-001 §4 owns entity lines (§7.1), so these are offered to it, not placed: the rows and keys are handed to the Game audio chat. Each was checked against the §4.1 register and the §3.2 source rule; fixes are noted.

| Line | Words | Source (verify where) | When | Check |
|---|---|---|---|---|
| "RUN, LITTLE LANTERN." | 3 | the Cabinet (§7.5 attract) | existing, AUDIO-001 §4.5 | — |
| "INSERT CREDIT." | 2 | the Cabinet (§7.5; `locale/en.po`) | the start of an Iteration after a Hard Unmaking | sample read "INSERT COIN."; the Cabinet never says COIN, so the borrowed words are fixed to its own |
| "PLAYER 1." | 2 | the Cabinet (§7.5 "PLAYER 1 · STILL ON DUTY"; §4.4) | Act 3, when Your Own Vigil enters (ZONES-001 §7) | sample read "PLAYER ONE."; fixed to the Cabinet's own form (spoken "player one") |
| "QUOTA MET." | 2 | Office duty log (`cx_glass_quota`); the Cabinet credits (`CAB_CREDITS_3`) | when the Sepulchre completes | — |
| "KEEP THE VIGIL." | 3 | the Observatory's last order (`cx_chron_hu_08`) | Act 4, said back sincerely | — |
| "LEFT. LEFT. LEFT." | 3 | your play: turn history (telemetry, as AUDIO-001 §4.10) | Act 3, in a Remembered kit (ZONES-001, kit memory, CHD-11) | — |
| "ONE SHORT." | 2 | the Choir's Litany, "always one short" (§2.1) | when the player is one Charge short of an unmake | must be true at that moment (L2) |
| "STILL ON DUTY." | 3 | the Cabinet (§7.5, Ruins Act 1) | on a late death in a Chronicle (which death: value owed, SYS-001 row requested) | sample read "WELCOME BACK." [cabinet high-score screen]; no Cabinet text says it, so it had no verifiable source. Replaced with a Cabinet line that exists |
| "THANK YOU." | 2 | existing, sincere (AUDIO-001 §4.7) | existing | — |

### 3.3 How it relates to the loop

The entity did not make the loop and does not control it. The loop is the **Ninth Sky Observatory still running its last order** (§10.1, `cx_chron_hu_08`): *KEEP THE VIGIL.* The Office's will to finish the light is, like everything unfinished here, a substance; it crystallised in the Observatory's broken lens housing, and the Lantern Tree grows out of it (§4.3). Each time a sky goes dark the Observatory does the only thing it was built to do: it tries again.

So the system contains two unfinished intentions wearing shapes. The entity is the star's. The loop is the Office's. **The player is the instrument both of them need.** That symmetry is the spine of the endings (§9).

### 3.4 What writing about the entity is forbidden

| Forbidden | Why | Instead |
|---|---|---|
| calling it evil, cruel, malicious, sadistic, monstrous (TRUE layer and all UI text) | §1.1; it would make the game ordinary (§0.3) | describe what it does, in state words |
| giving it a plan, a goal stated as a goal, or a monologue | AUDIO-001 §4 rule: a line exists because a SYS-001 row changed | state the state |
| a line that is false | AUDIO-001 L2; eat lines here obey the same rule | oblique is allowed; wrong is not |
| a face, eyes in a face, a mouth that speaks (art and prose) | ART-001 §2; dread by subtraction | the iris is the CRT curvature at T5 (GDD-001 §8.7), never an eye in a head |
| pity for itself, loneliness, sadness spoken by it | it does not feel; grief is the *material*, not its mood | let the Choir grieve on its behalf |
| torture, gore, bodies (§11) | ESRB T target | subtraction: things stop |
| addressing the real-world player ("you, sitting there") | the entity only knows the Lampkeeper | the Cabinet is the only object allowed a wink, and only before Act 3 (§5.4) |
| the 1983 original's lines or their structures | RES-001 §5; §12 | original lines only |
| a name other than Nhael'Gharoth, the Dark Star, the Waking Dark, the Hollow King, the Star That Failed | §13 | — |
| humour in its mouth | it never jokes. "THANK YOU." (AUDIO-001 §4.7) is not a joke; it is the worst line in the game because it is sincere | — |

**Never fully seen: the N-rules** (PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-01). Horror here is subtraction: the entity is shown only by what stops being there. Horror is an undertone at T1–T2 and overt from T3 (WARP-001, horror reading per tier). The teen envelope holds (§11), and there is zero startle: CH-6 is a hard rule, so nothing about the entity may jump, flash or sting. These rules bind prose and art alike; a line that describes the entity breaking one is cut.

| # | Rule | For the writing |
|---|---|---|
| N1 | Never more than a fraction of its silhouette on screen at once (SYS-001, entity max on-screen silhouette row), except in the Unmaking cinematic (N8) | no text describes its whole shape |
| N2 | At least one of its edges is always off-screen or occluded. Nobody sees where it ends | no text says where it ends |
| N3 | Never lit from the front. It is seen only by what it removes: stars, fog scatter, colour, reflections in crystal spheres | describe the absence, never the surface |
| N4 | No face, mouth, eye, or symmetry that reads as a face (extends the row above) | the entity never gazes, watches or looks, and has no "maw" or "eye". The Choir's gaze cones are theirs, and the gaze in the Waking is the *player's*, at it |
| N5 | A **Glimpse** is a soft rim-light along part of its edge: eased in and out, silent, never a flash (within the WARP-001 §4.5 flicker cap), no longer than SYS-001's Glimpse duration max row, and caused only by the player's own light (a Charge hit, a Surgelight burn). A reveal the player caused, never a startle | a Glimpse is something *you* did |
| N6 | Its scale is never confirmed. No reference object is ever shown beside its whole extent | no size words with a measure in them |
| N7 | It moves like a tide or an eclipse: slow fronts, no limbs, no strikes. Its attacks are subtractions | no "lunges", "strikes", "claws" |
| N8 | It fills the screen only in the Unmaking cinematic, and even then the black spreads from inside the picture, not from the edges. **The first Unmaking** (2026-11-18, PM ruling, Act 1 vertical slice; TECH-001 Q-T103): the erasure begins at a point inside the frame, **off-centre** (behind where the Presence fled, across the crystal-sphere line, so the sphere band visibly stops at its edge; never a centred disc, which reads as an iris or fade-to-black edit), and spreads outward as a moving front, with no full-field luminance step (WARP-001 §4.5). Its edges are never framed until the end of the last-light beat, when the black has filled the frame from the inside; that moment is the single full-body view (D-04, below) | describe a front moving outward, never an edge closing in |
| N9 | It has no sound of its own: its presence is heard as sound being removed. Its spoken lines are borrowed words (§3.2), not its own sound | no roar, no breath, no "it screamed" |
| N10 | It is the only true black (ART-001 §16.1), and so are its projectiles, which are pieces of it; each has a luminous Aether rim so black on colour always reads | — |

**Scope of the N-rules.** N1–N10 govern the **true entity after THE PRETENCE**. The Act 0 costume entity (the Cabinet's boss, its shadow; WARP-001 §5.1 T0, §6.1 D-04) is **exempt**: the Cabinet shows its whole plate ring, because it is the costume.

**N1 and the Awakening (WARP-001 §6.1 D-04, amended 2026-11-18, PM ruling Q-A).** At the *first true Awakening* (the first time after THE PRETENCE that the true entity completes its segments, in Act 1 or later; never A0-3) the entity's full body is present for the first time, every edge of it inside the sector, drawn as an outline of absence. This is its debut. The camera never frames more than the N1 maximum at once and pans along it. The single full-body view is kept for the first Unmaking cinematic (N8). This amends an earlier owner decision under the PM's grant (2026-11-18); the PM has flagged it to the owner for reconfirmation (TECH-001 Q-T73, on this clarified text). For the writing: no text describes the whole body even here; it is crossed, never surveyed.

The art half of these rules is ART-001's: the **ART-001 §16 cross-reference is handed to the Aether art chat**, which owns that doc. Numbers live in SYS-001; this table only names the rows.

---

## 4. Register

### 4.1 The six registers

| Register | Who uses it | Shape | Allowed vocabulary |
|---|---|---|---|
| **Cabinet** | the Cabinet's marquee and attract text; Act 0 HUD | ALL CAPS, arcade imperative, ≤ 6 words | INSERT, CREDIT, PLAYER, 1UP, HIGH SCORE, GAME OVER, LITTLE LANTERN, VIGIL |
| **Office** | posters, duty logs, enlistment forms, the honour roll | civic, passive voice, euphemism, numbers as reassurance | quota, rotation, stand down, the light, service, honour |
| **Choir** | liturgy fragments, rank titles, Herald names | liturgical, "of the" constructions, numbers spelled out, present tense | carry, keep, finish, the count, the silence, the god |
| **Entity** | its lines (AUDIO-001 §4; eat lines §7.3 here) | ALL CAPS, 1–8 words, declarative, state words | only words from §3.2's sources |
| **Ruins** | Sable Vane, Ilse Marrow, Brother Wick | sentence case, spoken, short; one register each (§5) | plain words; no system vocabulary ("Seam", "Sigil" are allowed only from Sable, who writes contracts) |
| **Codex** | Ilse's catalogue and marginalia (§8) | archival; a fact first, a feeling last | precise nouns; dates relative ("the third year of the Vigil") |

Rule of thumb: if a line could be said in two registers, it belongs in neither. Rewrite it.

### 4.2 Register by Act

| Act | Registers on screen | Shift the player should feel without being told |
|---|---|---|
| 0 | Cabinet only (plus one entity line, AUDIO-001 §4.1) | it is a game |
| 1 | Cabinet in the Ruins; Ruins voices; entity | it is a job |
| 2 | Ruins, Choir (via Wick and Codex), entity | it is a funeral |
| 3 | Office (Codex chronicle pages), Ruins, entity | it was a lie told kindly |
| 4 | Entity and Ruins; the Cabinet shows only INSERT CREDIT | it is yours to finish |

### 4.3 The Ruins' scar

The Ruins of the Ninth Sky are the Observatory as it was at the moment of ignition, held in the scar the failed light cut through the ninth sky. The scar is a place where time was **cut**, not bent — which is why the loop cannot reach it and why things that happen in the Ruins stay happened (GDD-001 §6.2: anchored state).

| Element | What it is | Why it survives the loop |
|---|---|---|
| the lens housing | the Observatory's great broken lens; the Lantern Tree's roots are grown into its cracks | it is the crystallised order *KEEP THE VIGIL* (§3.3) |
| the Lantern Tree | Mourning Glass grown along the Office's will instead of the star's; its "leaves" are small lamps | glass remembers the shape it was asked to hold (§1.3); this glass was asked to hold a vigil |
| the Chalk Desk | the Observatory's duty desk; every Lampkeeper signed out here | contracts signed here are part of the scar |
| the Codex alcove | the Office's records room | Ilse never let it be emptied |
| the Cabinet | bolted to the wall of the old Vigil hall wing | it was on when the light failed and it never turned off |

**How the Ruins change.** GDD-001 §6.4 promises ruins → cathedral → lattice → unlit room. LOOP-001 §10.4 schedules it as eight Hard Unmaking beats; this is what each one *is*:

| Beat (LOOP-001 §10.4) | The Ruins become | Fiction |
|---|---|---|
| Act 1 | rubble, chalk marks, one lamp | the scar holds the Observatory at the moment of ignition; nothing has grown yet |
| 1 · The First Dark | the east wall is gone; the scar shows through | the scar is the reason the Ruins survive, and the first loop shows you it |
| 2 · The Bell With No Clapper | a nave nobody built | the Lantern Tree has grown enough to stand the rubble up; Wick starts hanging the Choir's salvaged lanterns in it, unlit, as an apology |
| 3 · The Ledger Opens | the floor is a map of the system with three skies inked out | Ilse's records, laid flat |
| 4 · The Cathedral Learns Your Name | the windows show your past deaths as stained glass | glass remembers the shape it was asked to hold (§1.3); this glass was asked to hold your vigils |
| 5 · Lattice | the walls are gone; the Ruins hang in chalk lines over the dark | the Tree now *is* the building; through it the Hollow Skies stack like panes |
| 6 · The Unlit Room | one room, one lamp: yours | every other lamp is in the Tree; the room is dark because all its light is in the Tree |
| 7 · The Choir Sings Your Name | the chant comes from inside the walls | the Choir has learned the name on the honour roll |
| 8 · The Ninth Sky Remembers | every earlier shape, cycling | the scar replaying itself; the Observatory checking its work |


### 4.4 The propaganda vocabulary

The arcade costume of Act 0 is not the game lying. It is the **Office's vocabulary**, preserved in the Cabinet (§1.4). Each costume word hid a fact.

| Cabinet / Office word | What it meant on paper | What it hid (TRUE) | Where the player meets the truth |
|---|---|---|---|
| INSERT CREDIT | start a game | sign the enlistment line | `cx_ruins_` letters; the Archivist epilogue (§9.5) |
| PLAYER 1 | you | Lampkeeper number *n*; the Cabinet counted | the honour roll (below) |
| 1UP / extra life | another try | a **Second Vigil**: the Office's term for redeploying a recovered pilot | NARR §1.4; LOOP-001 HULL-6 |
| HIGH SCORE | the leaderboard | **the honour roll**: the enlistment list. Every initials entry on a Vigil hall cabinet was a name the Office called up | Theodora Lune's message (§9.5) |
| GAME OVER | you lost | STAND DOWN: the shift ended. The Office never used "dead" on any form | Office duty logs (§8) |
| THE PRETENCE | the training rotation (A0 levels were the "Pretence Hall" curriculum) | a simulation in which the Dark Star always lost, by design | "THAT WAS A PRETENCE." (GDD-001 §6.1) — Theodora put the line at the end of the curriculum herself, as a warning disguised as a twist |
| VIGIL | a shift | a deployment from which the Office did not plan a return | Codex, Act 3 |
| QUOTA | a target | an amount of glass the Office knew would not finish the light | §10.2 |
| THE LIGHT | the goal | the Ninth Light, which could not finish | ending 4 |
| LITTLE LANTERN | the Cabinet's affectionate name for a new player | the youngest recruits. The entity says it now (§3.2) | AUDIO-001 §4.5 "RUN, LITTLE LANTERN." |

### 4.5 The tear, and the borrowed face

PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-16.

| Beat | Rule | Why |
|---|---|---|
| **Cabinet (Act 0)** | imperative, cheerful, transactional: it wants your credit. INSERT CREDIT. PLAYER 1. | the Office's recruitment voice (§4.4) |
| **The tear** | after "THAT WAS A PRETENCE." there is **no text at all** for the opening of the Aether, for SYS-001's tear silence row. Colour, fog and room tone only. No caption, prompt, tooltip or entity line in that time | the first thing the player meets after the lie is a world, not a sentence |
| **First words** | the first words the player reads after the Pretence are in the Ruins, in sentence case, from a person: **Sable Vane** at the Chalk Desk (§5.7; §7.5, first Ruins visit). No other Ruins text (the Cabinet's marquee, Ilse's notes) may be read before it (§14 Q-14) | a human voice, after a machine's |
| **The inversion** | from Act 1, **the Cabinet's face is the one the entity borrows**: its lines are set in the Cabinet's type (ART-001 owns the face). The cheerful voice of Act 0 comes back as the entity's | the player's own training (the Lampkeepers' curriculum) is what talks to them in the dark. AUDIO-001 §4.2 was brought into line by the Game audio chat (§14 Q-15, closed 2026-11-18) |

---

## 5. The Ruins cast

Four people and one machine. None of them is a vendor; each one owns a system (GDD-001 §6.4) and a loss with a fact attached (§0.3).

| Character | Owns | Seen as | Wound (the fact) | Never says |
|---|---|---|---|---|
| Sable Vane | Chalk Desk, Pacts | hands, a sleeve, a ring | unknown, deliberately (§14 Q-07) | anything about their own past |
| Ilse Marrow | Codex | an old clerk at a records desk | filed her brother's discharge card without reading it | "I'm sorry" (she writes it instead) |
| Brother Wick | Lantern Tree | a big man in a stripped Acolyte's vestment, carrying an unlit censer | left his Matron mid-hymn; the sector rained | anything against the Choir |
| the Cabinet | attract mode, Act 0, ending 5 | an arcade machine on the wall | — (it is the wound) | anything after Act 3 except its last message |
| Theodora Lune | — (absent) | a name on a maker's plate | built the machine that recruited children and could not stop it | — |

### 5.1 Sable Vane — the Chalk Desk

**Role.** Writes one Pact per run (GDD-001 §6.4) in chalk on slate, reads it back, and has you sign with the Vigil's own chalk. Speaks only in clauses. Nobody sees more than Sable's hands, a grey sleeve, and on the left hand a Lampkeeper's ring whose lamp is cracked and dark.

**Function in the fiction.** Sable is the keeper of terms. Every Pact is a contract with the system's own rules, and Sable is the only person in the Ruins who can write in the rules' handwriting. That is why the **hand that is not yours** that places the H14 card (WARP-001 §3.2) and draws your Vigil in the Unmaking Rehearsal (WARP-001 §6.2 beat 2) is Sable's: the hand is shown, gloved in chalk dust, and the ring is visible in exactly one frame.

**Voice.** Second person, conditional, present tense. Short. Never a question. Never warm, never cruel. A good Sable line could be printed on a contract.

**The thread (do not resolve).** Sable wears a Lampkeeper's ring. Sable knows how Pacts restore eaten rules, which only someone who has flown under eaten rules would know. Sable never comes out from behind the desk. In Act 4, in the unlit room, Sable's chalk is the same colour as the Vigil's. That is all. §14 Q-07 keeps it open and staff do not answer it, including to each other.

**Arc.** Act 1: a voice and chalk — the Pact writes itself on the slate and no hand is seen. Beat 2 (*The Bell With No Clapper*): the sleeve, for the first time. Act 2 begins writing a second, smaller clause under each Pact that you can read only with Steady Ledger off (it is honest either way; it is just small). Beat 5 (*Lattice*): the whole hand and the ring, offering the Pact of Ascension (**PACT-ASC**, a 25th Pact outside the pool, offered only by Sable — LOOP-001 §11.4). Refused, Sable will not write it again that sky. Act 4: writes nothing; slides you the chalk.

### 5.2 Ilse Marrow — the Archivist

**Role.** Last surviving clerk of the Lantern Office. Keeps the Codex: catalogues every unit, place, rule and relic you encounter and writes marginalia from Iteration 2 (§8.5). Reading with her pauses the Hourglass Clock (GDD-001 §6.2) because, as she puts it, "records are not kept in time".

**Wound.** Ilse's job under the Office was filing Lampkeeper discharge cards. Her younger brother **Tomas Marrow** enlisted at a Vigil hall cabinet at fifteen; she filed his card in the ninth year of the Vigil without turning it over. She has never turned it over. It is in the Codex alcove, face down, and it is the one record she will not catalogue.

**Voice.** Dry, exact, a little prim; catalogues instead of feeling; corrects your terminology. Grief shows only as precision. Her best lines are footnotes.

**Arc.** Act 1: unseen; the Codex is in her handwriting. Iteration 2: marginalia begin. 25 % of the Codex: the Archive opens, and her desk with it. Beat 4 (*The Cathedral Learns Your Name*): she speaks aloud for the first time. Acts 2–3: annotates Choir entries with what she knew of the people and files one Office chronicle page per Hard Unmaking without comment (`cx_chron_hu_01…08`). Ending 5: the Archivist corrections (§9.5). 100 % Codex: she turns Tomas's card over (`cx_ruins_ilse_last`).

### 5.3 Brother Wick — the Lantern Tree

**Role.** Tends the Lantern Tree; explains nothing about nodes (P5: a mechanic that needs a tooltip is a bug) but says one line when a capstone first grows (the entity says the other, AUDIO-001 §4.13).

**Wound.** Wick was an Acolyte. In the Litany he counted the nine syllables against the eight ring-nodes (AUDIO-001 §5.1) and could not stop hearing the gap. One service he put down his censer mid-hymn and walked out of the ring. His Matron, Mother Ashe, kept the count alone until the Seam's Lampkeeper killed her instead of silencing her; the chant stopped and the sector rained. Wick believes his leaving made her the only voice, and so the only target. He does not blame the Lampkeeper. He does not forgive himself.

**Voice.** Slow, kind, liturgical habits he can't shake (counts things under his breath in nines). Calls the player "Lampkeeper", never by number. The only Ruins character who will say the Choir's names for things, and he says them gently.

**Arc.** Arrives at beat 1 (*The First Dark*), sitting under the Tree; in Act 1 the Tree grows alone. Beat 2: names the gap. Act 2 the sympathy vehicle (GDD-001 §9.1): he explains Choir rites when you bring back their salvaged lanterns (rare Run Sigils taken at a Seam boundary, the former Relics; LOOP-001 §5, CHD-14), hangs them unlit in the Tree. Act 3 asks you, once, to silence a Matron instead of killing her "if it costs you nothing" — it always costs something (SYS-001 §3, §1.5). Beat 6: offers ending 2 at the last lamp (§5.6). Ending 3: he is the one who stops you, or tries, with one line (§9.3).

### 5.4 The Cabinet, and Theodora Lune

**The Cabinet** is the DARKSTAR training cabinet from a Vigil hall, bolted to the wall of the Ruins. It is the source of Act 0: when you played Act 0, you were playing this machine (GDD-001 §6.1). It still runs attract mode, and you can **insert credit and play Act 0 again** at any time (LOOP-001 §11.6). Its marquee shows text (§7.5). Its voice is the Cabinet register (§4.1).

**Its jokes.** The Cabinet is the only thing in DARKSTAR allowed deadpan humour, and only before Act 3 (§11.5). Its jokes are recruitment copy that has outlived its context: *INSERT CREDIT. THE SKY IS COUNTING ON YOU.* After Act 3 the jokes stop, because by then the player knows what the copy was for.

**The high-score table.** From Hard Unmaking 3 (*The Ledger Opens*), the honour roll on the Cabinet shows a top score that is not yours, under the initials **T.L.**, with a note beside it: `0 WARD 0 SURGE` (LOOP-001 §11.6). Your best Vigil Index sits one line below it. Nobody comments on it. Nothing explains it. It is Theodora Lune's high score on her own machine, and it tells anyone who reads it how to find her (ending 5).

**Theodora Lune** was the Office engineer who designed the cabinet. She wrote its curriculum, its attract copy, its honour roll — and its last screen, *THAT WAS A PRETENCE.*, which the Office approved as an inspiring twist. She meant it literally. Her one honest act is hidden in the machine (§9.5). She is never seen. Her maker's plate is on the Cabinet's back panel, visible once the Ruins become a lattice (beat 5) and the wall behind it is gone. Her resignation letter is `cx_chron_hu_05`.

### 5.5 The Penitent, as cast

Not a speaker. It first drifts through the Ruins at beat 7 (*The Choir Sings Your Name*, LOOP-001 §10.4) — the first time anything from the skies enters the anchored pocket — and from then on once per Iteration, through the Lantern Tree, leaving a lit lamp on one branch that goes out when you leave. It is the closest the game comes to a ghost and the writing still refuses the question (§11.6).

In the skies, the Penitents you meet where you fell are you (§2.3, CHD-09). A chosen one can be **rekindled** with Ember (LOOP-001, the post-tree Ember sink, CHD-15; the per-kit limit is SYS-001's rekindled Penitents row): it keeps its lamp lit through Hard Unmakings, a remembered grave. It gains no words and no power. Nobody in the Ruins comments on it.

### 5.6 The cast across the Hard Unmaking beats

LOOP-001 §10.4 gives each beat one cast moment. These are the scenes. Each is ≤ 20 s ✱, playable through (no input lock), and ends on one line.

| Beat | Cast moment | Scene | Line |
|---|---|---|---|
| 1 · The First Dark | **Brother Wick** arrives | a big man in a stripped Acolyte's vestment is sitting under the Lantern Tree with an unlit censer across his knees. He does not explain himself | Wick: "I walked out. Don't ask me from what yet." |
| 2 · The Bell With No Clapper | Wick names the gap; **Sable Vane's sleeve** is first seen | Wick counts the Litany on his fingers and stops at eight. Across the nave, a grey sleeve moves at the Chalk Desk for the first time; until now Pacts have written themselves | Wick: "Nine words. Eight stones. I couldn't stop hearing it." |
| 3 · The Ledger Opens | the **Cabinet** changes its attract text | the honour roll shows T.L. — `0 WARD 0 SURGE` — and your Vigil Index beneath it | Cabinet: "HONOUR ROLL · NEW ENTRY" |
| 4 · The Cathedral Learns Your Name | **Ilse Marrow** speaks aloud | an old clerk stands up from the records alcove for the first time; until now she has only written | Ilse: "You keep coming back. Then you should know what you're coming back to." |
| 5 · Lattice | **Sable** offers the Pact of Ascension (if ever Hollowed) | the whole of Sable's hand is visible; the ring with the cracked lamp is on it | Sable: "There is one contract I have only written once." |
| 6 · The Unlit Room | **Wick** and the last lamp | Wick stands by the one lamp left in the room. If ending 2 has not been taken he offers it; if it has, he thanks you for coming back | Wick (offer): "It's only one lamp now. You could let it rest. I'd sit with you." · Wick (after ending 2): "You lit it again. I'm glad. I'd have understood." |
| 7 · The Choir Sings Your Name | the **Penitent** enters | the chant comes through the walls; the Penitent drifts in through the lattice, leaves a lit lamp on the Tree, and goes | none — the chant is the line |
| 8 · The Ninth Sky Remembers | **all cast together** | the Ruins cycle through every shape. Wick, Ilse and Sable are in the same room for the only time. Ilse reads the last chronicle page aloud; Wick lights his censer for the first time; Sable writes nothing | Ilse: "'Keep the vigil.' That was the whole order. We kept it." |

### 5.7 The first Ruins visit

PM ruling 2026-11-18 (owner grant), Act 1 vertical slice, amended the same day after The Reviewer's notes; scene from `research/act1_vertical_slice.md` §2 beats 7–11. This is the first scene after the tear (§4.5) and the M2 slice's diegetic tutorial (PROD-001 §4): no tooltip, no menu, every interaction is a place. SYS-001 owns every number named here; LOOP-001 §10.4 owns the Ruins' Act 1 shape (§4.3: rubble, chalk marks, one lamp).

**Who is present.**

| Character | On the first visit | Why |
|---|---|---|
| the Cabinet | on the wall, attract mode running. Its marquee shows no text until Sable's first line has been written (§4.5, §14 Q-14); then INSERT CREDIT | the machine was on when the light failed (§4.3) |
| Sable Vane | **unseen**: the chalk at the Chalk Desk writes itself, and no hand is seen (§5.1 Arc; the sleeve first appears at Hard Unmaking beat 2, §5.6) | a human voice, after a machine's (§4.5); a person is there, and keeps out of sight |
| Ilse Marrow | unseen. The Codex is in her handwriting; marginalia start at Iteration 2 (§5.2, §8.5) | she writes before she speaks |
| Brother Wick | **absent**. He arrives at beat 1, *The First Dark* (§5.6) | in Act 1 the Tree grows alone (§5.3) |

**The scene, in order** (beats 7–11; the order keeps Sable's first line the first text read after the Pretence, §4.5):

1. **Cold open.** No title card. A lamp catches; one lantern lights a cramped, half-ruined hall. At the Chalk Desk, chalk begins to write on a slate by itself.
2. **The Chalk Desk** (Ruins register, sentence case; key prefix `NARR_SABLE_`). Sable's chalk lines are the first words read after THE PRETENCE:
   - "You're back. Most aren't." (present tense, Sable's voice, §5.1)
   - "What you buy here stays. The rest goes back into the dark." This is the anchoring rule (GDD-001 §6.2; LOOP-001 §2), stated **once**, diegetically. It never appears in a menu.
   - Then a chalk tally: the player's own Act 0 Vigil Index.
3. **The Cabinet pays out.** Brass tickets clatter from the wall Cabinet: the Act 0 score banked as Ember (SYS-001 §7.1; GDD-001 §7.1). Each ticket has **EMBER** printed on it, so the noun arrives with the object. The tickets drift to the Lantern Tree. The Cabinet's one line here, Cabinet register (key prefix `NARR_CAB_`): "SCORE BANKED". Checked against §4.1: ALL CAPS, 2 words (≤ 6), arcade vocabulary (SCORE from HIGH SCORE); a statement rather than an imperative, as the register already allows ("THE LIGHT IS SAFE", §7.5). No period, matching the other marquee lines.
4. **The Lantern Tree.** A bare brass sapling, one unlit lamp per node, each with its cost in tickets. Sable's chalk under the Tree: "Light one. The dark is long." **The gate is physical:** the hangar mouth is dark, lit only by the Tree's lamps, so the Vigil cannot launch until one node is bought and its lamp lights the way. Any T1 node will do.
5. **The Codex desk.** One page has stamped itself, with the chalk-on-slate sound (AUDIO-001 E08): `cx_place_act0_3` (§8.4), stamped at the A0-3 clear (LOOP-001 §8.2, Act 0 stage clears). It is the Pretence page, so **no new Codex id** is added and the §8 counts do not change. Its body carries beat 10's facts (the training rotation; a simulation in which the Dark Star always lost, by design). No marginalia (Iteration 1).
6. **The Hourglass, by the hangar mouth.** A brass Hourglass, full. Under it, Sable's chalk: "The sand starts when you leave." The Hourglass Clock starts at the first launch, not on arrival, on this visit only (GDD-001 §6.2 exception). The Vigil waits, lamp lit, in the light of the Tree's lamp; walking into it launches.

**The noun budget for the first visit:** Ember (printed on the tickets), Lantern Tree, Codex, Hourglass. Nothing else is named on screen. Pacts, Entropy, Threads and the word Composure come later; Sable's Pact line moves to the first time a Pact is offered (§7.5).

*Resolved 2026-11-18 (TECH-001 §11.1 Q-T102, design calls within the PM ruling):* no hand on the first visit (the chalk writes itself, matching §5.1 and §5.6); the old "first visit" Pact line re-triggered; line 1 in the present tense.


---

## 6. Lore on sectors, biomes and kits

ZONES-001 §2 owns biome identity, palette and geometry; §3 owns the kits. This section supplies what the places *were* and the fiction column each kit carries. Lore text sits on kits as Codex `cx_place_` entries and environmental chalk marks; it never places anything.

### 6.1 The six places under the nine skies

The **Nine Hollow Skies** are layers of reality stacked over the system (GDD-001 §6.2); the **six biomes** are the system's places, and every sky holds a layer of every place. The Hourglass Clock is spent per Iteration (LOOP-001 §6.5), and each time a ninth of it is spent a sky goes dark: every place loses a layer of light, the Ledger Compass loses a row, the chant loses a voice. Only the ninth sky's close ends the run.

| Biome (ZONES-001 §2.1) | What the place was before the making (TRUE) | What the Office called it | What the Choir calls it | The grief fact |
|---|---|---|---|---|
| **Pale Marches** | the inhabited lowlands; farms, towns, the first Vigil halls | Home Sky | the Place That Remembers | it still has frost on it because it was folded in winter, and nobody was told the date |
| **Ossuary Belt** | the quarry belt; the Office mined the bones of the old sun's moons for the Observatory's frame | the Works | the Bones | the geodes are dense here because the Office cut too neatly; the glass grew in the cuts |
| **The Litany** | the Office's temple district | the Precinct | the Nave (where the Choir first sang) | the Choir did not build it. They moved into the Office's church and found it fit |
| **Green Rot** | the sea; reefs and fisheries | the Shallows | the Garden | Shroud is coral that grew on glass instead of stone, and it grows best on the drowned |
| **The Drowned Observatory** | the Observatory's second instrument, a twin lens sunk in the sea to calibrate the first | the Calibration Works | the Mirror | it is the Ruins' twin (ZONES-001 §2.1) and it was the last place Theodora Lune worked |
| **The Black** | not a place: the hole the Ninth Light should have filled | the Unassigned | the Unsung | nothing grieves here because nothing was here to lose. That is why it is the hardest |

Each sky's first darkening writes a `cx_place_sky_<n>` entry (LOOP-001 §8.2). The skies have no names of their own in the TRUE layer — the Office numbered them, the Choir counts them — and the writing keeps it that way.


### 6.2 Places inside places

| Place | Where | What it is |
|---|---|---|
| **the oubliettes** | under every Shrine (ZONES-001 §5) | pits where the Carried are born from glass dust and mourners' chalk. Never shown inside |
| **Vigil halls** | Pale Marches, as ruins; visible as set dressing only | where Lampkeepers enlisted. Each one has a dark rectangle on the wall where a cabinet was removed |
| **Sepulchres** | every sector | to the Choir, an altar. TRUE: an Office glass-weighing station the Choir rebuilt out of fused vertebrae; the scales are still in it |
| **Shrines** | converted geodes | Choir sacred ground: a geode they have sung to until it stopped grieving and started listening |

### 6.3 Kit fiction column (sample; ZONES-001 §3 owns the full kit list)

One sentence per kit, written for the `cx_place_` entry and the environmental chalk. Samples from every biome:

| Kit | Fiction |
|---|---|
| PM-01 First Vigil | The first hall's training lane; the chalk arrows on the ice still point to a hangar that is not there. |
| PM-05 Sacred Ground | A village green the Choir consecrated because a Lampkeeper's lamp was found here, still warm. |
| PM-06 Procession Cut | The old market road. The Carried use it because it was always the road things were carried on. |
| OB-04 Buried Lantern | A Lampkeeper's Vigil, crushed in a gallery collapse; the Choir built nothing on it. Even they stepped around it. |
| OB-06 Quiet Gallery | Office surveyors' marks every nine metres. The last one is a tally of the people who went in. |
| LT-03 The Doorway Birth | The Precinct's baptistery. The Mothers birth the Carried here because it was already a font. |
| LT-04 Nine Altars | Nine altars for nine skies, built by the Office; the Choir sings to eight and leaves one bare, out of humility. Wick says it is out of fear. |
| GR-03 Deceiver's Pew | A fishermen's chapel. Every pew has a lamp hook; the Deceivers hang stolen Charges on them like offerings. |
| GR-05 Green Silence | Where the reef grew over a lifeboat with its lamps still lit. Coral will not grow on the lamps. |
| DO-02 Lens Shaft | The calibration lens; at one angle it shows the Ruins' Lantern Tree, right side up, very far away. |
| DO-04 Drowned Bell | The Calibration Works' shift bell. It rings on the Hourglass Clock's schedule. Nobody rings it. |
| BK-01 Void Vigil | No fiction. The Codex entry is one line long: *Unassigned.* |
| BK-04 Ninth Penitent | Nine Penitents are recorded here at once in the Office logs. The Black is where lamps went to go out. |

### 6.4 Hollow sectors

A sector gone **Hollow** (ZONES-001 §1.2, §6.5) gets a Codex `cx_place_` amendment written in the Choir register — the only time the Codex quotes the Choir without Ilse's comment: *Here the service finished.* The original entry stays legible beneath it, struck through, in the same two-line form as an eaten rule (§8.2).

### 6.5 Each biome's grief, told in art

PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-16. Each biome has one environmental story told **only in art**: no caption, no prompt, no chalk label. A Codex entry confirms it *after* the player has seen it, in the `cx_place_` voice (§8.2: the place before and after). ZONES-001 §2 lists each story for placement; the Aether art chat draws it. Entry prose is owed (§8.7).

| Biome | The story in the fog | Codex (after) | Note |
|---|---|---|---|
| Pale Marches | an Office recruitment sign, KEEP THE VIGIL (§7.6), frosted over and still lit | `cx_place_marches_sign` | — |
| Ossuary Belt | survey stakes in the vertebrae, numbered past the last one anyone mined | `cx_place_belt_stakes` | echoes OB-06 Quiet Gallery (§6.3); keep the two distinct |
| The Litany | one pew in the Nave is lit; the others are dark. The Lampkeeper's place, kept | `cx_place_litany_pew` | also gates WARD-9 (§8.6) |
| Green Rot | a Vigil hull grown into the reef, its lamp still lit (§2.3: your dead stay lit) | `cx_place_rot_hull` | close to GR-05 Green Silence's lifeboat (§6.3); one of the two should change |
| The Drowned Observatory | a lantern floating upward through the inverted hall, never arriving | `cx_place_observatory_lantern` | — |
| The Black | a Lampkeeper's brass ring, unlit, turning slowly (§2.3: rings were to be relit at discharge) | `cx_vigil_unlit_ring` | class conflict: `cx_vigil_` is *your* record (§8.2); see §8.6 |

---

## 7. Voice and text inventory

### 7.1 Who owns which words

| Text | Owner | Notes |
|---|---|---|
| Entity **state** lines (Waking, acquisition, Rampage, charges, threads, alternates, telegraphs, Vigil Index, capstones, Hard Unmaking, Ruins lines) | **AUDIO-001 §4** (164 lines) | this doc never restates them; it explains where their words come from (§3.2) |
| Death-line **clauses** and situational overrides | **AUDIO-001 §4.10** | §7.2 here gives the fiction, the printed report format and composed examples |
| The L12 **discrepancy lines** (WARP-001 §4.2) | **NARR-001 §7.2** | text only; Office register |
| The 18 **eat lines** (telegraph + arrival for H2…H18) | **NARR-001 §7.3** | requested by WARP-001 §8 R-08 |
| The **H14 Chalk Desk line** | NARR-001 §7.4 | specified by LOOP-001 §7.4 |
| Ruins cast lines (Sable, Ilse, Wick), Cabinet text, Theodora Lune's message | NARR-001 §7.5, §9.5 | |
| Codex prose and marginalia | NARR-001 §8 | |
| Ending text | NARR-001 §9 | |
| Chant syllables | AUDIO-001 §5 | |

Every string in this section enters `locale/en.po` with the key prefix in the table of §7.7 and a context note quoting this section (L10N-001 §3).

### 7.2 Death lines — the fiction, the report, and composed examples

**Fiction.** When a Lampkeeper stood down, the Office filed a *Vigil Report*: two lines, cause and conduct. The entity learned the form from the reports it ate along with the skies (§3.2). So the personalised death screen is the Office's own paperwork, read back by the thing that ended the shift. That is why it is short, why it is in caps, and why the numbers are printed underneath: it is a form.

**Grammar (AUDIO-001 §4.10 owns the clauses):** `<clause A of the top key>. <clause B of the second key>.` Each clause ≤ 4 words; composed line ≤ 8. Situational overrides (AUDIO-001 §4.10) replace the template when the manner of death is itself the fact.

**The printed report** (new, NARR-owned; the telemetry line AUDIO-001 §4.10 requires beneath the big type):

```
VIGIL REPORT · <KEY A LABEL> <n> · <KEY B LABEL> <n>
```
| Key (SYS-001 §8) | Report label (Office register) |
|---|---|
| `glass_hunted` | GLASS RECOVERED |
| `charges_thrown` | CHARGES RETURNED |
| `charges_lost` | CHARGES FORFEIT |
| `shrine_purged` | SHRINES CLEARED |
| `hollow_sectors` | SECTORS STOOD DOWN |
| `penitent_shot` | PENITENTS ENGAGED |
| `seam_deaths` | SEAM RECURRENCES |
| `iterations` | VIGILS KEPT |
| `hunger` | HUNGER (UNASSIGNED) |
| `warp_max` | SKY DEVIATION |

The labels are the Office's euphemisms (§4.4): it never wrote "killed", and it filed `hunger` under *unassigned* because the Office never admitted there was something on the other side of the ledger.

**The discrepancy line** (WARP-001 §4.2 L12; PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-04). If a HUD lie was live within SYS-001's lie death-attribution window before the death, the death screen prints one more line under the Vigil Report, naming the lied-about reading in the Office register's euphemism. It teaches; it never blames, and it never says *why* (§11.10). Text only: never spoken, never voiced by the entity.

| Lied-about reading | Key (`tr()`) | Line | State |
|---|---|---|---|
| the Ledger Compass | `MSG_DEATH_LIE_COMPASS` | COMPASS READING DISCREPANCY NOTED. | **live** (the Compass lies of WARP-001 §2 can trigger it) |
| the Charge tally | `MSG_DEATH_LIE_CHARGES` | CHARGE TALLY DISCREPANCY NOTED. | **reserved**: authored, no trigger in the current registry (under widened L6 no legal lie concerns the Charge tally) |
| the Vigil Index | `MSG_DEATH_LIE_INDEX` | INDEX READING DISCREPANCY NOTED. | **reserved**: authored, no trigger in the current registry (no current lie targets the Vigil Index) |

The keys were agreed with the Game audio chat and are recorded in AUDIO-001 §12.14 (2026-11-18); they replace the draft `NARR_REPORT_LIE_*` keys, which are not used.

Rules: the line appears **only** for lie-attributed deaths, and it appears with Steady Ledger on as well. There is **no Hourglass line**: the clock never lies (WARP-001 §4.2 L6), so nothing about it can be "noted". If more than one lie was live, the report prints **one line per lying element, the Compass line first** (2026-11-18, cosmic horror design call within CHD-04, flagged in the Phase 2 PR; §14 Q-16).

**Composed examples** (top key first; every one ≤ 8 words; every one true by construction):

| # | Keys (A, B) | Composed line |
|---|---|---|
| 1 | glass_hunted, glass_hunted | YOU HUNTED GLASS. HUNTED GLASS AND DIED. |
| 2 | glass_hunted, charges_lost | YOU HUNTED GLASS. LOST IT AND DIED. |
| 3 | glass_hunted, shrine_purged | YOU HUNTED GLASS. BROKE THEM AND DIED. |
| 4 | charges_thrown, hunger | YOU THREW MY BLOOD. YOU FEED ME STILL. |
| 5 | charges_thrown, glass_hunted | YOU THREW MY BLOOD. HUNTED GLASS AND DIED. |
| 6 | charges_lost, charges_lost | YOU LOST MY GLASS. LOST IT AND DIED. |
| 7 | charges_lost, hollow_sectors | YOU LOST MY GLASS. LEFT THEM AND DIED. |
| 8 | shrine_purged, penitent_shot | YOU BROKE MY SHRINES. SHOT ONE AND DIED. |
| 9 | shrine_purged, seam_deaths | YOU BROKE MY SHRINES. KNEW YOU. YOU DIED. |
| 10 | shrine_purged, hunger | YOU BROKE MY SHRINES. YOU FEED ME STILL. |
| 11 | hollow_sectors, iterations | YOU LEFT SKIES DEAD. TRYING IS DYING. |
| 12 | hollow_sectors, hunger | YOU LEFT SKIES DEAD. YOU FEED ME STILL. |
| 13 | penitent_shot, glass_hunted | YOU SHOT THE PENITENT. HUNTED GLASS AND DIED. |
| 14 | penitent_shot, penitent_shot | YOU SHOT THE PENITENT. SHOT ONE AND DIED. |
| 15 | seam_deaths, iterations | THAT SEAM KNEW YOU. TRYING IS DYING. |
| 16 | seam_deaths, charges_lost | THAT SEAM KNEW YOU. LOST IT AND DIED. |
| 17 | iterations, iterations | YOU KEEP TRYING. TRYING IS DYING. |
| 18 | iterations, hunger | YOU KEEP TRYING. YOU FEED ME STILL. |
| 19 | hunger, warp_max | I EAT YOUR SKIES. BENT. AND YOU DIED. |
| 20 | hunger, iterations | I EAT YOUR SKIES. TRYING IS DYING. |
| 21 | warp_max, charges_thrown | THE SKY IS BENT. THREW ALL AND DIED. |
| 22 | warp_max, seam_deaths | THE SKY IS BENT. KNEW YOU. YOU DIED. |
| 23 | charges_thrown, shrine_purged | YOU THREW MY BLOOD. BROKE THEM AND DIED. |
| 24 | hollow_sectors, penitent_shot | YOU LEFT SKIES DEAD. SHOT ONE AND DIED. |

**Why it works as a screenshot:** the line is about *you*, it is short enough for a thumbnail, and the report underneath proves it is not random. Players will share the strange ones (row 19, row 9). That is the point.

**Writing rule for future clauses:** a clause must be true of the key alone; it may be cruel only by being accurate.

### 7.3 The eat lines (WARP-001 §3.2, R-08)

Eighteen lines: one **telegraph** one Seam before the eat (WARP-001 §3.1 "Telegraph first"), one **arrival** at the eat. Constraints: Entity register (§4.1), ≤ 8 words, ≤ 2 rendered lines, **true at the moment spoken** (AUDIO-001 L2). The entity never states a plan (§3.4), so a telegraph states the *condition* that makes the eat legal (Hunger has reached the rule's level), never the intention. The arrival states the new rule. The eaten rule is named by the Codex strike and the Warp Tier card (AUDIO-001 §4.7), never by the line.

| Rule | What changes (WARP-001 §3.2) | Telegraph (one Seam before) | W | Arrival (at the eat) | W |
|---|---|---|---|---|---|
| **H2** | one-way wrap: the seam you came through closes behind you | "THE EDGES GROW TIRED." | 4 | "THE WAY BACK CLOSES." | 4 |
| **H4** | shard magnetism inverts | "MY GLASS REMEMBERS ME." | 4 | "IT WILL NOT COME." | 4 |
| **H6** | lantern down becomes loud, lantern up quiet | "THEY STUDY YOUR SHADOW." | 4 | "YOUR DARK IS LOUD." | 4 |
| **H8** | over-fire feeds the geode a shard | "THE ROCK GROWS TEETH." | 4 | "HASTE FEEDS THE ROCK." | 4 |
| **H10** | the Arc-Lance cannot harm Grubs — the "holiness line" | "THE CARRIED ARE NEARLY HOLY." | 5 | "THEY ARE HOLY NOW." | 4 |
| **H12** | Surgelight always costs; it no longer clears Shroud | "YOUR LIGHT IS BORROWED." | 4 | "LIGHT COSTS NOW." | 3 |
| **H14** | one Run Sigil per run, chosen by the entity | "I HAVE WATCHED YOU CHOOSE." | 5 | "<SIGIL NAME>. FOR YOU." | ≤ 6 |
| **H16** | the Ledger Compass cannot show the entity | "YOUR LEDGER RUNS SHORT." | 4 | "COUNT ME BY EAR." | 4 |
| **H18** | no rule-level unmaking before Act 4 — the "refusal line" | "MY SEAMS ARE SEALING." | 4 | "NOT IN THIS SKY." | 4 |

Checks: no eat line duplicates an AUDIO-001 §4 line (verified against §4.1–§4.14 on 2026-11-17). H14's arrival is the only templated line: Sigil names (LOOP-001 §4.2) are ≤ 4 words, so the line is ≤ 6. When an eat line plays, it replaces AUDIO-001 §4.7's generic "I TAKE THIS RULE." for that rule; the generic stays as the fallback for any rule added later without a pair (request to AUDIO-001 in the report).

**Restores are silent.** When a Pact restores a rule (WARP-001 §3.1 restore honesty), the entity says nothing — a god does not announce what it was made to give back. The only words are Sable's, at signing (§7.5).

### 7.4 The H14 Chalk Desk line

LOOP-001 §7.4: plain-spoken, no system vocabulary, spoken at the Chalk Desk by a hand that is not yours, naming the struck Sigil's own name and nothing else.

**The line is the name.** Sable Vane (§5.1) writes it in chalk on the slate, says it once, and strikes it through:

> *Stone Hook.*

No verb, no apology, no explanation. Template: `"<STRUCK SIGIL NAME>."` in sentence case (Ruins register), spoken in Sable's voice. The Codex records it under REL-18 Mourning Ledger when that rare Sigil is held (LOOP-001 §7.4), and in the `cx_rule_h14` entry always (§8.4).

### 7.5 Ruins cast and Cabinet line sets

UI copy rule (GDD-001 §10): ≤ 2 lines per screen. Every line below fits one line at 640×360 in the Ledger face (ART-001) at 100 % text, and two lines at 200 %.

**Sable Vane** (Chalk Desk; key prefix `NARR_SABLE_`)

| Trigger | Line |
|---|---|
| first Ruins visit, first chalk (§5.7; the first words after the Pretence, §4.5; the chalk writes itself) | "You're back. Most aren't." |
| first Ruins visit, second chalk (§5.7; the anchoring rule, stated once) | "What you buy here stays. The rest goes back into the dark." |
| first Ruins visit, under the Lantern Tree (§5.7; the launch gate) | "Light one. The dark is long." |
| first Ruins visit, under the Hourglass by the hangar mouth (§5.7) | "The sand starts when you leave." |
| the first time a Pact is offered (was "first visit"; re-triggered 2026-11-18, TECH-001 Q-T102) | "Sign, and the terms hold until the run ends." |
| a Pact is offered | "This is what it costs. This is what it buys." |
| a restore Pact (PACT-01/04/07/10/13/16/19/22) | "Held while you hold it. Not one breath longer." |
| player declines a Pact | "Unsigned is also a term." |
| player signs | "Witnessed." |
| a Pact lapses at run end | "Paid in full." |
| Act 2, second clause appears | "Read the small print. I always write it." |
| Pact of Ascension offered (ending 3) | "There is one contract I have only written once." |
| Pact of Ascension refused | "Then I will not write it again this sky." |
| Act 3, refuses to repeat it | "Once was the offer." |
| Act 4, slides the chalk | "Your hand now." |
| after any Hard Unmaking | "Terms carry over. Skies do not." |
| **community voice** (weekly cursed seed post; MARKET-001 MK-08) | "Terms for the week: seed `<CODE>`. Sign or don't. — S.V." |

Community rule: Sable is the only character who speaks outside the game (Discord, Steam announcements). Sable stays in contract-speak, never confirms anything about their past, never uses an emoji, signs `— S.V.` The writing keeps Sable's gender unstated in all text (§14 Q-07).

**Ilse Marrow** (Codex; prefix `NARR_ILSE_`). Before beat 4 she is never seen or heard: her lines are **written** (handwritten notes on the Codex). From beat 4 she **speaks**.

| Trigger | Mode | Line |
|---|---|---|
| first Codex open | written | "Records are not kept in time. Sit." |
| first entry stamped | written | "Filed. You were thorough. Be thorough again." |
| the Archive opens (LOOP-001 §8.5, 25 %) | written | "This was my desk. It still is." |
| beat 4, first speech | spoken | "You keep coming back. Then you should know what you're coming back to." |
| a Choir entry, Act 2–3 | spoken | "I knew the family name. I will not say it." |
| the clock paused | spoken | "Nothing ages in here except me." |
| a struck rule entry | spoken | "Both versions stay. I do not erase." |
| Hard Unmaking | spoken | "Another sky. I have a drawer for each." |
| the face-down card | spoken | "Not that one." |
| Act 3, chronicle page | spoken | "This was classified. There is no one left to classify it." |
| Act 4 | spoken | "Finish it, and I will finish the record." |
| beat 8 | spoken | "'Keep the vigil.' That was the whole order. We kept it." |
| 100 % Codex, `cx_ruins_ilse_last` read | spoken, last | "There. Now someone else knows." |

**Brother Wick** (Lantern Tree; prefix `NARR_WICK_`). Arrives at beat 1.

| Trigger | Line |
|---|---|
| beat 1, arrival | "I walked out. Don't ask me from what yet." |
| a node grows | "Good. Another one lit." |
| a capstone grows (the entity speaks the other line, AUDIO-001 §4.13) | "That one will be heard a long way off." |
| beat 2 | "Nine words. Eight stones. I couldn't stop hearing it." |
| a salvaged lantern brought back (Act 2) | "That was somebody's. I'll hang it where it can see." |
| Choir rite explained | "We sang the gap for humility." |
| **ending 2 discoverability** — after an Iteration with 4+ deaths ✱, Iteration 3+ (LOOP-001 §11.3; text kept identical) | "Some keepers let it go out. Nobody here would blame you." |
| Act 3, the one request | "If you can silence her instead — do. If you can't, I understand." |
| after a Matron is killed | "She held the count alone. She shouldn't have had to." |
| after a Matron is silenced | "Thank you. She'll sing again somewhere." |
| **ending 2, beat 6 offer** | "It's only one lamp now. You could let it rest. I'd sit with you." |
| **after ending 2 (relit)** | "You lit it again. I'm glad. I'd have understood." |
| ending 2 eulogy (the only line in it) | "Rest, Lampkeeper. I'll keep the count." |
| ending 3, the attempt | "Lampkeeper. You don't have to finish it for them." |
| counting under his breath | "…seven, eight. Nine." |

**The Lampkeeper** (the player's own voice; used only at ending 2's second confirmation, LOOP-001 §11.3; prefix `NARR_KEEPER_`). The player character speaks once in the whole game. The line is a choice, not a cry: it must read as standing down from a duty, never as giving up on living (§11.8).

| Screen | Text | Buttons (default focus first, UI-001 §3) |
|---|---|---|
| `confirm_1` (UI register) | "Let the lamp go out?" | **Keep it lit** · Let it go out |
| `confirm_2` (Lampkeeper's voice) | "I've kept it long enough. Someone else can keep the count." | **Keep it lit** · Let it rest |

**The Cabinet** (marquee and attract; Cabinet register; prefix `NARR_CAB_`)

| When | Text |
|---|---|
| Act 0 attract | "INSERT CREDIT, LITTLE LANTERN" |
| Act 0 attract | "THE SKY IS COUNTING ON YOU" |
| Act 0 attract | "MINE GLASS · MAKE CHARGES · SAVE THE LIGHT" |
| Act 0 high score table header | "HONOUR ROLL" |
| Act 0 game over | "STAND DOWN" |
| Act 0 final screen | "THAT WAS A PRETENCE." |
| Ruins, first visit, the ticket payout (§5.7; after Sable's first line, §4.5) | "SCORE BANKED" |
| Ruins, Act 1 | "PLAYER 1 · STILL ON DUTY" |
| Ruins, Act 1 | "HIGH SCORE: YOU" |
| Ruins, Act 2 | "VIGILS KEPT: <n>" |
| Ruins, Act 2 | "BONUS SKY AT 10,000" |
| beat 3 onward, honour roll | "1. T.L.  ·  0 WARD 0 SURGE" / "2. <your initials>  ·  <Vigil Index>" |
| beat 3, marquee | "HONOUR ROLL · NEW ENTRY" |
| Ruins, Act 2 (last joke) | "PLEASE DO NOT TAP THE GLASS. IT GRIEVES." |
| Ruins, Act 3 onward (jokes stop) | "INSERT CREDIT" — no name, nothing else |
| ending 2 eulogy | attract loop to an empty hall; no text |
| ending 5 | Theodora Lune's message (§9.5) |

**The Cabinet credits roll** (Act 0 stage clear; Cabinet register; prefix `NARR_CAB_`; the code keys are the existing `CAB_CREDITS_*` in `locale/en.po`, not renamed). Wording approved by the owner 2026-11-18. The stage-1 short roll is the first three lines (`CAB_CREDITS_1`..`3`). The stage-2 full roll (after the entity is unmade) inserts the four stat lines after line 3. Stat lines are **true counts** of what the player did this run (never saved; state counts only, §11.10) and appear only in the stage-2 roll.

| Order | Key (`tr()`) | Text |
|---|---|---|
| 1 | `CAB_CREDITS_1` | "CONGRATULATIONS, VIGIL" |
| 2 | `CAB_CREDITS_2` | "THE LIGHT IS SAFE" |
| 3 | `CAB_CREDITS_3` | "YOUR QUOTA IS MET" |
| stat (stage 2 only) | `CAB_CREDITS_STAT_GRUBS` | "GRUBS DESTROYED: %d" |
| stat (stage 2 only) | `CAB_CREDITS_STAT_MINED` | "GLASS MINED: %d" |
| stat (stage 2 only) | `CAB_CREDITS_STAT_CHARGES` | "CHARGES THROWN: %d" |
| stat (stage 2 only) | `CAB_CREDITS_STAT_CARRIED` | "GLASS CARRIED: %d" |
| 4 | `CAB_CREDITS_4` | "DARKSTAR" |
| 5 | `CAB_CREDITS_5` | "A LANTERN OFFICE PRODUCTION" |
| 6 | `CAB_CREDITS_6` | "KEEP THE VIGIL" |
| 7 | `CAB_CREDITS_7` | "THANK YOU FOR YOUR SERVICE" |


### 7.6 Office text (environmental)

Posters and stencils in Act 0 and in Pale Marches / Ossuary Belt ruins. Office register. ≤ 6 words. Examples: "KEEP THE VIGIL" · "EVERY SHARD IS SOMEONE'S SKY" · "QUOTA IS SERVICE" · "THE LIGHT IS NEARLY FINISHED" · "LAMPS LIT, LAMPKEEPERS" · "REPORT TO YOUR VIGIL HALL". The last two are what the Penitent obeys (§2.3).

### 7.7 Inventory

| Set | Count | Key prefix | Status |
|---|---|---|---|
| Eat lines | 18 | `NARR_EAT_H<n>_TEL` / `_ARR` | authored |
| H14 desk template | 1 | `NARR_SABLE_H14` | authored |
| Vigil Report labels | 10 | `NARR_REPORT_` | authored |
| L12 discrepancy lines (§7.2) | 3 | `MSG_DEATH_LIE_` (AUDIO-001 §12.14) | authored 2026-11-18; COMPASS live, CHARGES and INDEX reserved |
| Composed death examples | 24 | (composed at runtime from AUDIO-001 clauses) | examples only |
| Entity borrowed lines (§3.2) | 9 (7 new, 2 existing) | AUDIO-001 §4 keys (handed to the Game audio chat) | samples, not placed |
| Choir liturgy fragments (§2.1) | 6 | `NARR_CHOIR_` (if shown as text) | samples; channel open (§2.1) |
| Sable Vane | 17 (4 first-visit lines added 2026-11-18, §5.7) | `NARR_SABLE_` | authored |
| Ilse Marrow | 13 | `NARR_ILSE_` | authored |
| Brother Wick | 15 | `NARR_WICK_` | authored |
| the Lampkeeper | 2 | `NARR_KEEPER_` | authored |
| Cabinet | 28 (17 marquee/attract + 11 credits; "SCORE BANKED" added 2026-11-18, §5.7) | `NARR_CAB_` | authored |
| First Ruins visit scene (§5.7) | 1 scene (4 Sable lines and 1 Cabinet line, counted in the rows above; the EMBER ticket print; 1 Codex page, the existing `cx_place_act0_3`) | (in the cast sets above) | authored 2026-11-18 (PM ruling, Act 1 vertical slice) |
| Hard Unmaking beat lines | 8 scenes | (in the cast sets above) | authored (§5.6) |
| Office environmental | 6 | `NARR_OFFICE_` | authored |
| Theodora Lune's message | 10 screens | `NARR_LUNE_` | authored (§9.5) |
| Codex samples | 45 | `CX_<CLASS>_<SLUG>` | authored samples (§8.4) of LOOP-001 §8.2's 144 (122 planned plus the 22 ids added 2026-11-18, §8.7); full set owed |
| Codex rumour titles (§8.3) | 4 | title field of the reserve kits' entries (ids owed, §14 Q-13) | authored 2026-11-18 |
| Codex gating entries (§8.6) | 27 | `CX_<CLASS>_<SLUG>` | 7 authored, 20 prose owed |
| Biome grief entries (§6.5) | 6 | `CX_<CLASS>_<SLUG>` | ids set; prose owed |


---

## 8. The Codex

LOOP-001 §8 owns the mechanics (unlocks, which entries gate which Lantern Tree nodes, the backstops, clock pause). This section owns the prose. Since 2026-11-18 the Codex **pays no Unwritten Ink**: a stamp now *gates* (PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-15; §8.3, §8.6).

### 8.1 Entry format

| Field | Rule |
|---|---|
| ID | `cx_<class>_<slug>` (LOOP-001 §8.2), e.g. `cx_choir_grub`, `cx_rule_h14`, `cx_chron_hu_03` — invariant, never localised |
| Title | ≤ 4 words, title case, a noun phrase |
| Body | ≤ 90 words ✱ (two Codex screens at 200 % text). Fact first, feeling last. One sentence may be in the class's source register (Office, Choir) in italics |
| Struck block (rule entries only) | the old rule in chalk, struck through; the new rule beneath; never erased (LOOP-001 §7.6) |
| Marginalia | Ilse Marrow's note, ≤ 15 words, handwritten face, appears from Iteration 2 on entries she has something to say about. Never on `cx_vigil_` (those are yours) |
| Unlock | stated in LOOP-001 §8; shown as a stamp, not a sentence |
| Rumour state | title only, in Sable Vane's chalk, no body, no stamp. The body is written when the thing is found (§8.3). The title is the entry's own title, so it obeys the title rule above |

### 8.2 Class style guide

| Class | Voice | Must contain | Must not |
|---|---|---|---|
| `cx_choir_` bestiary | Ilse's catalogue of a congregation | the Choir rank title (§2.1); one observed behaviour; what they believe they are doing | the word "monster"; HP or numbers (SYS-001 owns them) |
| `cx_glass_` the making | archival, quoting Office documents | one quoted Office line | spoilers above the entry's tier (§10.3) |
| `cx_rule_` rules | two-line struck/restored, then one sentence | the struck rule verbatim as the player knew it | any explanation of *why* (L8: a lie is never a tutorial) |
| `cx_relic_` | provenance: whose it was | a former owner, unnamed or named | stats |
| `cx_sigil_` | a family page (LOOP-001 §8.2); one line per Sigil held: what it is, then what it costs | — | numbers |
| `cx_place_` | the place before and after (§6) | what it was called by the Office | geometry instructions |
| `cx_ruins_` | letters, notes, objects in the Ruins | a physical object | dialogue transcripts |
| `cx_chron_` chronicle | Office minutes and letters: one per Hard Unmaking beat (`hu_01…08`), one per ending (`end_01…05`), one per Entropy tier | a date in Vigil years | the whole truth in one page |
| `cx_vigil_` your record | Office report register about *you* | your own numbers as the Vigil Report prints them | marginalia |

**Additions (2026-11-18, CHD-15/16; LOOP-001 §8.2 widened its classes to match, §8.7):**

| Case | Shape |
|---|---|
| `cx_rule_` **taught** entries: gating entries that name a rule the player meets but that is not an eat (`cx_rule_gaze`, `cx_rule_the_passing`…, §8.6) | no struck block. A fact-first body saying *what* the rule is as the player met it, then at most one Choir quote in italics. Still never *why* (§11.10) |
| `cx_chron_` pages written **after** the Office, in the scar (`cx_chron_first_absence`, `cx_chron_unmade_at_t3`, `cx_chron_thread_iv`) | instead of a Vigil-year date they read *Undated*: the scar keeps no years (§4.3) |
| `cx_choir_` **sacred things and rites** that are not units (`cx_choir_shrine`, `cx_choir_litany_ring`, `cx_choir_procession`, `cx_choir_saint`) | same voice as the bestiary; in place of a rank title, the name the Choir give the thing, and what they believe it does |
| `cx_vigil_` **authored pages** about your own Chronicle's dead (`cx_vigil_still_lit`, `cx_vigil_unlit_ring`) | Office report register about *you*, but no numbers of yours are required; still no marginalia |

### 8.3 What the Codex is for, in fiction

The Codex is the Office's records room kept by its last clerk. Reading it costs no time because the room is in the scar (§4.3). **Knowing an entry opens a rule node** on the Lantern Tree (LOOP-001 §3; CHD-15): a fact written down is a rule the world has to keep, so the Tree, which grows along the Office's will (§4.3), can only grow a rule you already understand. Nothing is paid for it. The 27 entries that gate nodes are listed in §8.6; LOOP-001 owns which node each opens and the backstops that stamp an entry if the player never finds it. (Before 2026-11-18 the Codex paid Unwritten Ink; that currency is retired, and no player-visible text may mention it.)

**Rumours** (PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-11). Some entries arrive before the thing they describe. Sable Vane chalks the **title** up at the Chalk Desk; the entry sits in the Codex in its rumour state (§8.1), title only, until the player finds the place or meets the thing, and then Ilse writes the body. A rumour is an unfinished Codex entry, not a new kind of thing: no new noun, never called "rumour" on screen. Fiction: Sable writes terms, and a place you have heard of but not seen is a term not yet met. Sable never explains a rumour and never says where it is.

| Rumoured | When the title is chalked | Title (≤ 4 words, §8.1) | Kit fiction (§6.3) |
|---|---|---|---|
| PM-05 Sacred Ground (reserve kit, ZONES-001 §3) | Act 2 entry | *The Lamp Still Warm* | the village green consecrated around a still-warm lamp |
| OB-02 Censer Walk (reserve kit) | Act 2 entry | *A Lamp Below* | owed |
| LT-04 Nine Altars (reserve kit) | Act 2 entry | *The Bare Altar* | the ninth altar the Choir leaves bare |
| GR-03 Deceiver's Pew (reserve kit) | Act 2 entry | *The Offering Pew* | the pews hung with stolen Charges |
| the Herald of the run's Seam 2 or Seam 4 | at Seam 1's exit | the Herald's own `cx_choir_` title | §2.1, the Six |

The rumour titles of the design draft (*A Lamp Below the Belt*, *The Sky That Kept Its Stars*, *Where the Pew Is Empty*, *The Observatory's Other Door*) are replaced above: the first three broke the §8.1 title rule (more than 4 words, or not a noun phrase), and the second and fourth matched no reserve kit (no Drowned Observatory kit is held back). The reserve kits' entry ids are owed (§14 Q-13).

### 8.4 Sample entries (45)

IDs and classes follow LOOP-001 §8.2 (`cx_<class>_<slug>`; 144 counted entries at 1.0 since the 2026-11-18 recount (§8.7), plus `cx_vigil_`; none pays Ink since 2026-11-18). Four samples were added 2026-11-18 from the cosmic horror design rev 3 (`cx_choir_procession`, `cx_rule_the_passing`, `cx_chron_first_absence`, `cx_vigil_still_lit`), each checked against §8.1 and §8.5 and fixed where it broke a rule (noted under each). Rule entries follow LOOP-001 §8.3's shape: struck line, replacement line with Hunger and Seam, restore footer.

**Bestiary — `cx_choir_`**

> **cx_choir_grub · The Carried** — Oubliette Grub. Born in the oubliettes under Shrines from glass dust and mourners' chalk. They carry shards to the Sepulchre and flee your lamp. They do not fight. When a deposit is lost the procession keens, and the keening is for the shard.
> *Choir:* "Every shard is a name."
> *— Marginalia:* They are not afraid of you. They are afraid of dropping it.

> **cx_choir_acolyte · The Vested** — Acolyte, the Censer Knight. Guards of the rite and the only rank permitted to mine. The censer turret swings late behind the body; they never corrected it. An Acolyte is buried with its censer lit, when anyone is left to light it.
> *— Marginalia:* Wick still carries his. Unlit. Don't ask him.

> **cx_choir_deacon · The Comforters** — Deacon of Lies, by Office classification. They raise the shapes of the dead and walk them home. What the Office filed as deception the Choir performs as a eulogy. Their phantoms cost you Composure because looking at a eulogy costs something.
> *— Marginalia:* Office name. Not mine. I'd have called them mourners.

> **cx_choir_listener · The Confessors** — Listener. Blind; they hear the service. The only sin they can hear is gunfire. Fly quietly and they lose interest. The Choir calls a Listener's death the one honest death.

> **cx_choir_matron · The Mothers** — Choir Matron. Precentors of the Litany; they keep the count and birth the Carried. Silence one and the hymn rests. Kill one and the hymn loses its count, and the sector rains.
> *— Marginalia:* The rain is the hymn without anyone holding it.
> *— Archivist (ending 5, Act 3+):* Mothers first. They came to the weighing stations to finish their children's quota. I have their names. I am writing them in.

> **cx_choir_entity · Nhael'Gharoth** — The Waking Dark; to the Choir, the Hollow King. Seven lines, written as you witness each phase: *Seed. Procession. Guard. Quickening. Awakening. Rampage. Unravel.* It states what it is. It has never stated what it wants.
> *— Marginalia:* It has a large vocabulary for something that was never taught to speak.

> **cx_choir_procession · The Carried Dead** *(gates MADNESS-11, §8.6)* — The Choir do not bury Mourning Glass. The Carried bear it to the Sepulchre in procession, led by the Comforters, who sing the Litany one syllable short. To the Choir the glass is someone being taken home. A Lampkeeper who lets a procession pass is not attacked. No Office manual records this. Several Lampkeepers did it anyway.
> *(Fixed from the draft: "four bearers" removed, since the class may carry no numbers; a sentence of what they believe added, which the class requires. 2026-11-18: "behind one of the Mothers" replaced, because the Procession has no Matron; the Deacons lead it, ZONES-001 §6.6.)*

**The making — `cx_glass_`**

> **cx_glass_mourning · Mourning Glass** — Crystallised residue of an intention that did not finish. It forms where something was meant to happen. It does not burn, conduct, or sell. It grieves at a measurable hardness.
> *Office survey:* "Abundant. Origin under review."

> **cx_glass_null_iron · Null-Iron Charge** — Glass bound in Null-Iron and thrown back at the thing it came from. The Office called it returning ordnance. A Charge that lands is a piece of the star handed back.
> *Office manual:* "Return what you recover."

> **cx_glass_ninth_light · The Ninth Light** — The made star. Nine skies were folded into fuel at the Ninth Sky Observatory and lit. It did not finish lighting. It kept its shape and lost its light.
> *Office minutes:* "Ignition nominal. Output pending."
> *— Marginalia:* It stayed "pending" in the minutes for nine years.

> **cx_glass_quota · Quota** — The amount of glass a Vigil was expected to recover per shift. Posted in every Vigil hall beside the cabinet. Revised upward eleven times.
> *Office poster:* "Quota is service."

**Rules — `cx_rule_`** (LOOP-001 §8.3)

> **cx_rule_h2 · The Way Back**
> ~~*Every edge leads back to where you left.*~~
> *The seam you cross closes behind you.* — Hunger 2 · Seam 3
> *Bought back by PACT-01, Open Door, Open Hand — Iteration 4.*

> **cx_rule_h4 · The Glass Comes**
> ~~*Shards come to you.*~~
> *Shards slide away from you.* — Hunger 4 · Seam 2

> **cx_rule_h10 · The Carried Are Holy**
> ~~*You can kill anything.*~~
> *Your lance passes through the Carried.* — Hunger 10 · Seam 1
> *— Marginalia:* They can still die. Not to you.

> **cx_rule_h14 · Choose One of Three**
> ~~*Choose one of three.*~~
> *(nothing written beneath)*
> Taken on Seam 1: **<SIGIL NAME>**. That run it had: <the Sigil's one-line effect, LOOP-001 §4.2>.
> *— Marginalia:* I left the line blank on purpose. Some things you file empty.

> **cx_rule_the_passing · What Passes Over** *(taught entry, §8.2 additions; gates LANTERN-11, §8.6; stamped by the first distant Passing witnessed)* — When the Dark Star crosses a sector, lit objects in its path cease. Unlit objects are not affected. The Office logged eleven such crossings, then stopped logging. Survivors reported no sensation, only that the lamp went heavy.
> *Choir:* "It does not take the dark. The dark is already its own."
> *— Marginalia:* The Office stopped logging at eleven. I did not.
> *(Fixed from the draft: its margin, "Lamp down. Do not pray. Prayer is a light too.", was a mechanics hint, which §8.5 forbids; the Choir doctrine moved into the one allowed source-register quote.)*

**Rare boundary Sigils (the former Relics) — `cx_relic_`**

> **cx_relic_wick_left_burning · Wick Left Burning** — A lamp wick that will not go out. It belonged to a Lampkeeper who stood down in the Pale Marches with the lamp lit. The Choir kept it on an altar for a long time without touching it.
> *— Marginalia:* Lit lamps were not supposed to come back. This one did, without its owner.

> **cx_relic_lantern_of_other_days · Lantern of Other Days** — A Vigil lamp of the first issue, older than the Ninth Light. The brass is worn on one side where a thumb rested.

> **cx_relic_mourning_ledger · Mourning Ledger** — A clerk's ledger. When something is taken from you, a name is written in it and struck through. It does not give anything back. It only remembers.
> *— Marginalia:* My handwriting. I don't remember writing it.

**Run Sigils — `cx_sigil_`** (family pages; one line per Sigil ever held)

> **cx_sigil_ordnance · The Ordnance Page** — *Stone Hook:* glass leans toward you from further off; the Choir hears it go. · *Twin Flint:* two Charges leave together; you keep less in reserve.

**Places — `cx_place_`**

> **cx_place_pale_marches · Pale Marches** — Office name: Home Sky. The inhabited place, folded in winter; there is still frost on it. The Vigil halls were here.
> *— Marginalia:* Nobody told them the date. They had the frost to guess by.

> **cx_place_the_litany · The Litany** — Office name: the Precinct. The Office's temple district. The Choir did not build it. They moved in and found it fit.

> **cx_place_the_black · The Black** — Office name: Unassigned.
> *— Marginalia:* That is the whole file.

> **cx_place_sky_4 · The Fourth Sky** — Written the first time it went dark. A sky is one layer of every place at once; when it goes out, every biome loses a layer of light and the Ledger Compass loses a row. *The chant lost a voice.*

> **cx_place_act0_3 · Last Normal Day (cabinet stage)** *(the first Ruins visit's stamped page, §5.7)* — Pretence Hall curriculum, stage three, the last of the training rotation. A simulation: in it the Dark Star always lost, by design. Final screen retained as written by the curriculum's author.

**The Ruins — `cx_ruins_`** (cast letters; LOOP-001 §8.2: Sable ×4, Ilse ×4, Wick ×4, Cabinet ×3, the Chalk Desk ledger)

> **cx_ruins_chalk_desk · The Chalk Desk Ledger** — One line per Pact you have ever signed, in chalk that does not smudge. The first page is older than you. Every name on it is crossed out but one.

> **cx_ruins_sable_01 · Terms** — *(a slate, Sable's hand)* "Every clause is true. Read them all. Most keepers read the first and the price."

> **cx_ruins_ilse_01 · The Face-Down Card** — A discharge card in the records alcove, face down. Not catalogued.
> *— Marginalia:* Leave it.

> **cx_ruins_wick_01 · The Salt Mother** — *(Wick's hand, large and careful)* "Our only saint. She salted her own altar so it couldn't take the last shard, and then she sang the whole service anyway. We loved her for finishing the hymn."
> *— Marginalia:* They have it the wrong way round. I've never had the heart to tell him.

> **cx_ruins_cabinet_01 · The Machine on the Wall** *(unlocks Iteration 2 — the Cabinet breadcrumb, MARKET-001 MK-08)* — A training cabinet, Vigil-hall issue, bolted to the wall of the old hall wing. It has been in attract mode since before the Ruins were ruins. The maker's plate is on the back panel, against the wall. Nobody has moved it to read it.
> *Marquee:* "INSERT CREDIT, LITTLE LANTERN"
> *— Marginalia:* Every hall had one. I filed the requisitions.

> **cx_ruins_cabinet_02 · Attract Mode** *(Act 3)* — The Cabinet's demo text, transcribed in full: INSERT CREDIT, LITTLE LANTERN. THE SKY IS COUNTING ON YOU. YOU BUY TIME. THE DARK IS NOT YOURS.
> *— Marginalia:* I have heard every one of these words somewhere else lately.

> **cx_ruins_ilse_last · The Record** *(100 % of the Codex, LOOP-001 §8.5; the Archive's lamp goes out after it is read)* —
> "Filed, the last card. MARROW, T. Enlisted at a Vigil hall cabinet, ninth year, aged fifteen. Stood down in the Pale Marches. Lamp lit.
> I filed it face down because I knew what the last line would say. Lamp lit means he did not come home and did not stop trying to. I have catalogued every other thing in this system. I could not catalogue that.
> You have read all of it. So now someone else knows, and I can stop keeping it.
> The record is complete. — I. Marrow, Archivist."
> *(No marginalia. It is hers.)*

**Chronicle — `cx_chron_`** (one per Hard Unmaking beat, LOOP-001 §10.4; one per ending; one per Entropy tier)

> **cx_chron_hu_01 · Minutes, the Night of Ignition** — "Ignition nominal. Output pending. Nine skies committed. Recovery programme authorised to complete the light. Programme name: Vigil."
> *— Marginalia:* The surveyors' figure was ten skies. The minutes say nine. Both are in my hand.

> **cx_chron_hu_02 · Order of Conscription** — "All pilots of age report to their Vigil hall. Service is honour. Quota is service. The lamp will be lit at enlistment and relit at discharge."
> *— Marginalia:* We ordered a great many lamps for the first and very few for the second.

> **cx_chron_hu_03 · The Cabinet Halls** — "Requisition: one training cabinet per Vigil hall. Curriculum: Lune, T. Enlistment to be recorded from the honour roll. Approved, with the closing line retained as written."

> **cx_chron_hu_04 · Who Chose the Failure** — "Finding: the Ninth Light failed because the making was one sky short. No person chose it. No tool was misused. The Committee notes the families' petition naming the engineers and declines to publish it."
> *— Marginalia:* The Choir still sings that list. Every name on it is wrong, and every one of them is dead anyway.

> **cx_chron_hu_05 · A Letter of Resignation (redacted)** — "To the Office. I resign my post as curriculum engineer, effective ████. The cabinets do what I designed them to do, and that is the ████ ████. I have left a ████ in each machine for anyone who ████ ████ ████. — T. Lune"

> **cx_chron_hu_06 · The Star Did Not Go Out** — "Clarification for public notices: the Ninth Light has not gone out. It has not finished lighting. The distinction is to be maintained in all Office speech."
> *— Marginalia:* That distinction kept us in work for nine years.

> **cx_chron_hu_07 · On the Penitents** — "Recovered personnel stood down with lamps lit are not to be recorded as returned. They persist in the field as a disturbance of glass. Recommend no engagement. They appear to be trying to help."

> **cx_chron_hu_08 · The Last Order** — "To the Observatory, from the Office, in the event that no member of the Office remains to give further orders: KEEP THE VIGIL."
> *— Marginalia:* We wrote it as a formality. It was the only order anything ever obeyed.

> **cx_chron_first_absence · One Star Less** *(the First Absence, Act 1: GDD-001 act map, CHD-08)* — Iteration log, the Chalk Desk. Undated: the scar keeps no years. During the Waking at the fifth Seam, a star in the outer sky stopped. Not dimmed: stopped. No debris. No light delay. Sable Vane counted the sky twice and recorded the second count. The star was never named in any Office chart. It is now in no sky at all.
> *— Marginalia:* Sable counted three times. Wrote two.
> *(Fixed from the draft: the margin read "She counted three times", which would give Sable a gender, and §5.1 / §14 Q-07 keep that unstated.)*

> **cx_chron_end_05 · The Pretence Kept** — "Archivist's note, appended: the cabinet-maker's message has been recovered and filed. Every Choir entry in this Codex has been corrected. I should have done it years ago. — I.M."

**Your Vigil — `cx_vigil_`** (generated)

> **cx_vigil_first_stand_down · First Stand-Down** — VIGIL REPORT. *(The first death's composed line and report, §7.2.)*

> **cx_vigil_honour_roll · Honour Roll** — The initials you entered on the Cabinet in Act 0, your best Vigil Index beside them, one line below T.L. *(Needs Act 0 initials entry — §14 Q-03.)*

> **cx_vigil_still_lit · Still Lit** *(gates HULL-8, §8.6; stamped by the first death-site Penitent met)* — Penitents are found where Lampkeepers fell with the lamp burning. In this Chronicle, some are found where you fell. They do not speak. They bless whoever fires on them. The Office called this a malfunction of the lamp. It was not a malfunction.
> *(Fixed from the draft: "found only where you fell" was false, since other Penitents exist (§2.3, §6.3 BK-04), and the TRUE layer allows no false line. It carries none of your numbers, which the widened `cx_vigil_` class allows, §8.2 additions, §8.7.)*

### 8.5 Ilse's marginalia — rules

LOOP-001 §8.4 owns timing and budget (from Iteration 2; ≤ 1 note per entry per Iteration ✱; ≤ 3 notes per entry total ✱; a note appears when the entry's subject recurs in a new context). This doc owns the words.

| Rule | Value |
|---|---|
| Length | ≤ 15 words per note |
| Content | a fact she knew that the entry cannot state, or one admission. Never a hint about mechanics |
| Order | the three notes an entry can carry escalate: an observation, then a fact, then an admission |
| Never on | `cx_vigil_` entries (they are yours); `cx_ruins_ilse_last` (it is hers); any entry above the current spoiler tier (§10.3) |
| Archivist variant (ending 5) | every `cx_choir_` entry gains one extra, corrected note signed "— Archivist". **Gating ✱:** the corrected notes that state the families truth (§10.1, tier S4) show only once Act 3 is open, even if ending 5 was earned in Act 0; before Act 3 the corrected notes read "Correction pending. — Archivist." |
| Tone ceiling | she never writes "sorry", "love" or "grief". If she would, she writes a date instead |

### 8.6 The 27 gating entries

PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-15. Each Lantern Tree node that was priced in Unwritten Ink now opens when one Codex entry is known. LOOP-001 owns the node list, the tiers, each entry's discovery source and the backstops (the tier floor and "death teaches"); this table is the prose owner's list of the ids and their state. A backstop can stamp an entry the player never witnessed, so **every gating entry must read well cold**: it may not assume the player saw the event that normally stamps it.

"Sample" = authored in §8.4. "In plan" = inside LOOP-001 §8.2's original 122-entry plan. "Beyond plan" = a new entry outside the 122, now counted in LOOP-001 §8.2's widened classes (144 since 2026-11-18, §8.7).

| Node (LOOP-001) | Node tier | Gating entry | Reconciliation | Prose |
|---|---:|---|---|---|
| WARD-1 Short Rite | 1 | `cx_choir_shrine` | beyond plan (the Shrine is not one of the eight units; `cx_choir_` now covers the Choir's sacred things, LOOP-001 §8.2) | owed |
| MADNESS-2 Look Away | 1 | `cx_rule_gaze` | beyond plan (taught `cx_rule_`) | owed |
| MADNESS-3 Tremor Hand | 1 | `cx_rule_frayed` | beyond plan (taught `cx_rule_`) | owed |
| LANTERN-4 Wick Ledger | 1 | `cx_rule_lantern_dark` | beyond plan (taught `cx_rule_`) | owed |
| HULL-8 Long Watch | 2 | `cx_vigil_still_lit` | `cx_vigil_` (outside the count; the class now admits authored pages that gate, LOOP-001 §8.2) | sample |
| ORDNANCE-5 Pierce | 2 | `cx_choir_acolyte` | **same id** as a sample (*The Vested*; folded from the proposed `cx_choir_vested`, 2026-11-18) | sample |
| WARD-6 Silence the Choir | 2 | `cx_choir_matron` | **same id** as a sample | sample |
| MADNESS-5 Clear Eyed | 2 | `cx_rule_unmoored` | beyond plan (taught `cx_rule_`) | owed |
| MADNESS-7 Hollow Ledger | 2 | `cx_rule_bleeding` | beyond plan (taught `cx_rule_`) | owed |
| LANTERN-10 Keel Light | 3 | `cx_place_the_drowned_observatory` | in plan (a biome); renamed from the proposed `cx_place_drowned_observatory` to match the biome samples' full names (`cx_place_the_litany`, `cx_place_the_black`), 2026-11-18 | owed |
| LANTERN-11 Blackout Dash | 3 | `cx_rule_the_passing` | beyond plan (taught `cx_rule_`) | sample |
| HULL-9 Anchor Field | 3 | `cx_choir_grave_tide` | in plan (a Rite) | owed |
| ORDNANCE-9 Charge Capacity II | 3 | `cx_glass_null_iron` | **same id** as a sample | sample |
| ORDNANCE-11 Homing Song | 3 | `cx_choir_listener` | **same id** as a sample | sample |
| WARD-9 Choir's Own Bell | 3 | `cx_place_litany_pew` | beyond plan; also The Litany's grief entry (§6.5) | owed |
| MADNESS-11 Communion | 3 | `cx_choir_procession` | beyond plan (a rite, not a unit; `cx_choir_` widened) | sample |
| MADNESS-12 Hollow Chain | 3 | `cx_rule_hollowed` | beyond plan (taught `cx_rule_`) | owed |
| HULL-16 Anchor Overdrive | 4 | `cx_choir_unnumbered` | in plan (a Rite) | owed |
| ORDNANCE-13 Nine-Syllable Lance | 4 | `cx_choir_litany_ring` | beyond plan (a rite object, not a unit; `cx_choir_` widened) | owed |
| WARD-13 False Lantern | 4 | `cx_choir_deacon` | **same id** as a sample (*The Comforters*; folded from the proposed `cx_choir_comforters`, 2026-11-18) | sample |
| MADNESS-14 Blessed Fracture | 4 | `cx_rule_inverted` | beyond plan (taught `cx_rule_`) | owed |
| LANTERN-18 Lamp of the Failed Sky | 5 | `cx_glass_ninth_light` | **same id** as a sample | sample |
| HULL-18 Hollow Hull | 5 | `cx_rule_hollow_sector` | beyond plan (taught `cx_rule_`); overlaps the Hollow `cx_place_` amendment of §6.4 (one subject, two entries) | owed |
| ORDNANCE-17 Null-Iron Hymn | 5 | `cx_chron_unmade_at_t3` | beyond plan (a Chronicle milestone; `cx_chron_` widened) | owed |
| WARD-18 Unconsecrated Sky | 5 | `cx_choir_saint` | beyond plan (`cx_choir_` widened); overlaps sample `cx_ruins_wick_01` (*The Salt Mother*, a different class) | owed |
| MADNESS-17 Unravel Focus | 5 | `cx_chron_thread_iv` | beyond plan (a Chronicle milestone; `cx_chron_` widened) | owed |
| MADNESS-18 The Ninth Sky Looks Back | 5 | `cx_rule_the_glimpse` | beyond plan (taught `cx_rule_`); replaces the proposed `cx_entity_glimpsed`, which had no class (2026-11-18) | owed |

Writing notes: `cx_rule_gaze` is the *Choir's* gaze cone, never the entity's (N4); `cx_rule_the_glimpse` describes a part of an edge, never a whole (N1, N2, N5); `cx_choir_saint` must agree with §2.1's Salt Mother and keep Ilse's correction of Wick (`cx_ruins_wick_01`) intact.

### 8.7 Reconciliation with LOOP-001 §8.2, and what is owed

**The sample count (Q-10).** §8.4 holds 41 samples before this revision (counted 2026-11-18: 6 `cx_choir_`, 4 `cx_glass_`, 4 `cx_rule_`, 3 `cx_relic_`, 1 `cx_sigil_`, 5 `cx_place_`, 7 `cx_ruins_`, 9 `cx_chron_`, 2 `cx_vigil_`). §14 Q-10 said 32; that was stale, and is corrected. With the four new samples there are **45**. (2026-11-18, Act 1 vertical slice: the first Ruins visit's page is the existing `cx_place_act0_3`, its body extended with beat 10's facts, §5.7. No id is added, so 45 samples and LOOP-001 §8.2's 144 stand.)

**The gating ids against the plan.** Of the 27 gating ids (§8.6):

| Group | Count | Ids |
|---|---:|---|
| already a sample, same id | 6 | `cx_choir_matron`, `cx_choir_listener`, `cx_glass_null_iron`, `cx_glass_ninth_light`, `cx_choir_acolyte`, `cx_choir_deacon` |
| new sample this revision | 3 | `cx_choir_procession`, `cx_rule_the_passing`, `cx_vigil_still_lit` |
| in plan, prose owed | 3 | `cx_choir_grave_tide`, `cx_choir_unnumbered`, `cx_place_the_drowned_observatory` |
| beyond plan, prose owed | 15 | `cx_choir_shrine`, `cx_choir_litany_ring`, `cx_choir_saint`; the nine taught `cx_rule_` other than `the_passing` (`gaze`, `frayed`, `lantern_dark`, `unmoored`, `bleeding`, `hollowed`, `inverted`, `hollow_sector`, `the_glimpse`); `cx_place_litany_pew`; `cx_chron_unmade_at_t3`, `cx_chron_thread_iv` |

That makes 9 gating entries with prose and 18 owed.

**Folded ids (2026-11-18, cosmic horror design call within CHD-15, flagged in the Phase 2 PR).** The proposed gating ids that duplicated a sample's subject, or had no class, use the existing or correctly named id everywhere (here and in LOOP-001 §3.3, §3.7): `cx_choir_vested` → `cx_choir_acolyte`; `cx_choir_comforters` → `cx_choir_deacon`; `cx_place_drowned_observatory` → `cx_place_the_drowned_observatory`; `cx_entity_glimpsed` → `cx_rule_the_glimpse` (a taught rule; it describes a part of an edge, never a whole). The old ids are not used.

**Count change for LOOP-001 §8.2** (LOOP owns the totals, and has adopted these). New ids beyond the 122-entry plan in the counted classes: 17 from the gating map (the 15 owed above plus `cx_choir_procession` and `cx_rule_the_passing`) and 5 more from this revision (`cx_chron_first_absence` and the four `cx_place_` grief entries other than `litany_pew`): **22**, for **144** in all. Add 4 more if the reserve kits get their own `cx_place_` entries (§14 Q-13). `cx_vigil_still_lit` and `cx_vigil_unlit_ring` are `cx_vigil_` and sit outside the count. The Ink-payout column of §8.2 no longer applies.

**Class scope, settled in LOOP-001 §8.2 by widening the class descriptions** (2026-11-18; §14 Q-12):
1. `cx_rule_` now holds eaten rules (struck/restored) **and taught rules** (the ten taught gating ids; shape in §8.2 additions).
2. `cx_chron_` now holds Chronicle milestones written after the Office (`cx_chron_first_absence`, `cx_chron_unmade_at_t3`, `cx_chron_thread_iv`) as well as beats, endings and Entropy tiers.
3. `cx_vigil_` now admits authored pages about your own Chronicle's dead that carry none of your numbers (`cx_vigil_still_lit`, `cx_vigil_unlit_ring`), and a `cx_vigil_` entry may gate a node; the class stays outside the count and completion (shape in §8.2 additions).
4. No `cx_entity_` class is needed: `cx_entity_glimpsed` became `cx_rule_the_glimpse`.
5. `cx_choir_` now holds the Choir's sacred things and rites (the Shrine, the Litany Ring, the Procession, the saint) as well as units, Heralds, Rites and the entity.
6. **Still open:** the Hollow sector already has a `cx_place_` amendment (§6.4); `cx_rule_hollow_sector` would be a second entry on one subject. Not a class-scope question, so widening does not settle it.

**Prose owed:** the 18 gating entries marked "owed" in §8.6; the six grief entries of §6.5 (`cx_place_litany_pew` is counted in both); the reserve kits' bodies (written on finding) and OB-02's kit fiction line (§6.3).


---

## 9. Endings as fiction

LOOP-001 §11 owns the triggers. AUDIO-001 §4.8 owns the entity's credits line ("THEN I WAS NEVER." in endings 1, 2 and 4; withheld in ending 3). This section owns what the endings *mean* and the words on screen. Every ending is earned, none is a punishment, and none says what happens to the dead (§11.6).

Positions on the question §1.6 withholds — **does the entity, once unmade, become something else?** — are taken by exactly two endings, and they disagree on purpose: **ending 3 says yes (§9.3), ending 4 says no (§9.4).**

### 9.1 Ending 1 — Nine Hollow Skies

**When:** every Hard Unmaking (not a game over; the Chronicle continues).
**What happens:** the ninth sky closes in a named beat (WARP-001 §6.1 D-01). The Ruins dim, then hold. Ilse files the sky. The Lantern Tree loses nothing.
**On screen** (rotated by the count of Hard Unmakings; ≤ 2 lines each):

| Count | Text |
|---|---|
| 1st | "NINE SKIES DARK. THE VIGIL CONTINUES." |
| 2nd | "NINE MORE. THE OBSERVATORY TRIES AGAIN." |
| 3rd | "THE SKIES ARE SHORTER EACH TIME. YOU ARE NOT." |
| 4th+ | "KEEP THE VIGIL." (the Observatory's order, §3.3 — the first time the player sees its exact words) |

**Meaning:** the loop is not the entity's victory; it is the Office's refusal to stop. The player is learning that the thing keeping them alive is the same thing that sent the Lampkeepers out.

### 9.2 Ending 2 — The Lantern Extinguished

**When:** Iteration 3+, at the Lantern Tree, *Let it go out*, confirmed twice — the second time in the Lampkeeper's own voice (LOOP-001 §11.3; lines in §7.5).
**What happens (3 minutes, no input required; LOOP-001 §11.3 owns timing):** the player's lamp on the Tree is lowered and put out by the player's own hand. Then, slowly: Wick sets down his censer and says the only line in the scene — "Rest, Lampkeeper. I'll keep the count." Ilse closes the ledger halfway and leaves her pen in it. Sable's hands rest flat on the desk. The skies you saved and the skies you lost are named one by one, in chalk, by number. Far away the Choir is singing. The Cabinet plays its attract loop to an empty hall. Nothing attacks. The Ruins cannot be eaten.
**On screen** (one line, at the end): "THE OBSERVATORY WILL KEEP ITS VIGIL. YOU MAY REST."
**Meaning:** stopping is allowed. The game does not frame this as giving up and does not frame it as death (§11.8). It is the Lampkeeper standing down with the lamp *out* — the one thing no Lampkeeper was ever allowed to do. The save is untouched; the next launch offers *Light it again*, and Wick's line on return is in §7.5.


### 9.3 Ending 3 — The Choir Crowned

**When:** Act 3+, the Pact of Ascension (PACT-ASC) signed; Seam 5 reached while Hollowed; the Sepulchre allowed to complete with the Vigil inside the Litany Ring (LOOP-001 §11).
**What happens:** the Litany begins. For the first time in the game the ring has **nine** nodes — the Vigil is the ninth. The chant does not stop for the Silence; it finishes. Wick says his line (§7.5). The Awakening does not happen. Something completes instead, and it completes in your shape: the Vigil's lamp module goes dark and the segment art closes around it.
**On screen:** "THE SERVICE IS FINISHED." Credits are sung, not shown, by the Choir in the complete nine-syllable Litany. The entity's credits line is **withheld** (AUDIO-001 §4.8).
**Position (TRUE within this ending):** **yes, it becomes something else** — it becomes the Lampkeeper. The Waking Dark continues with a different shape at its centre. Whether that is mercy or horror is the player's to decide; the text never says.
**Meaning:** the Choir were right that the thing could be finished. They were wrong about what finishing it would make. NG+ Choir mode (post-launch scope) is this ending continuing.

### 9.4 Ending 4 — The Unraveling (true)

**When:** all five Threads of Unraveling; Act 4; three threads latched on the body in the final encounter (SYS-001 §2 phase 6; LOOP-001 §11).
**What happens:** "UNWRITE ME." (AUDIO-001 §4.8). The third thread comes free and the entity does not die: it is **unwritten** — the hole in the rules it was wearing is closed, so there is nothing for the Unborn Dark to fill. The credits peel the arcade shell away layer by layer (GDD-001 §9.3): HUD, bezel, scanlines, the Cabinet's marquee. Underneath is the last clean sky, and in it the Ninth Light finally finishes lighting, because the hole it failed around is no longer occupied. In the Ruins every lamp on the Lantern Tree is lit, and the one that was always dark is yours.
**On screen:** after "THEN I WAS NEVER." — "THE LIGHT IS FINISHED. STAND DOWN, LAMPKEEPER."
**Position (TRUE within this ending):** **no, it does not become anything.** Unmade things stop (§1.1). Nothing of it remains to be redeemed or to return.
**Meaning:** the Office was right about the goal and wrong about the method. You do not finish the light by feeding it. You finish it by removing what was standing in its place.

### 9.5 Ending 5 — The Pretence Kept (secret), and the Archivist

**When:** Act 0 completed without ever using Surgelight or Ward Pulse — on first play or by inserting credit at the Cabinet in the Ruins later (LOOP-001 §11.6). The message plays on the Cabinet's marquee **after the second credits roll and before "THAT WAS A PRETENCE."** It unlocks the **Archivist** variant at once.

**The only hint:** from beat 3 the honour roll's top line is *T.L. · 0 WARD 0 SURGE* (§5.4). The game never explains it.

**Theodora Lune's message.** Cabinet register, one screen per beat, each ≤ 2 lines, held until a button is pressed. The last screen breaks into sentence case: it is the only sentence-case text the Cabinet ever shows. Screen 8 leads directly into the screen it names.

| Screen | Text |
|---|---|
| 1 | THANK YOU FOR PLAYING. |
| 2 | THIS IS THEODORA LUNE. / I BUILT THIS MACHINE. |
| 3 | YOU NEVER USED THE LIGHT. / YOU WERE CAREFUL. |
| 4 | SO I CAN TELL YOU. |
| 5 | THE HONOUR ROLL / IS THE ENLISTMENT LIST. |
| 6 | IN HERE THE DARK STAR ALWAYS LOSES. / I WROTE IT THAT WAY. |
| 7 | OUT THERE IT DOES NOT. |
| 8 | THE NEXT SCREEN SAYS PRETENCE. / THEY THOUGHT I MEANT IT AS A TWIST. |
| 9 | IF YOU HAVE NOT SIGNED, DON'T. |
| 10 | If you already have — bring your lamp home. / Stand down, little lantern. |

Then: *THAT WAS A PRETENCE.* — the same screen every player sees, now read as a warning instead of a twist.

The last line is where the entity's "LITTLE LANTERN" came from (§3.2). Players who reach Act 1's "RUN, LITTLE LANTERN." after this screen will hear it differently, and that is the whole design.

**The Archivist variant** (LOOP-001 §8.4, §11.6). Ilse Marrow corrects the record: every `cx_choir_` entry gains a corrected note signed "— Archivist", and `cx_chron_end_05` is filed. The corrections say plainly what the Codex has only implied: **the Hollow Choir began as the families of Lampkeepers who did not come home**, who went to the weighing stations to finish the quota their children died for, and grew into the shape of what they carried (§10.1). Tier S4: the corrected notes that state it are gated to Act 3+ (§8.5). Before then they read *Correction pending.*

Separately, at 100 % of the Codex, Ilse turns over her brother's card and writes her last entry (`cx_ruins_ilse_last`, §8.4). Ending 5 does not require it and does not grant it; the two together are the complete record.

**Position on §1.6:** ending 5 takes **no** position on whether the entity becomes something else; it is about the people, not the god.


---

## 10. The chronicle (staff only)

The only place TRUE facts are merged into one account. Nothing here is shown to players in this form. Dates are Vigil years (Y1 = the year of ignition).

### 10.1 What really happened

| When | Event | TRUE |
|---|---|---|
| before Y1, generations | **The Old Light** dims. The inhabited system faces a slow dark | yes |
| before Y1 | **The Lantern Office** (civic-religious ministry) commissions the **Ninth Sky Observatory** to make a star from the system's skies | yes |
| before Y1 | Nine skies are folded into fuel. The surveyors' own figures required **one more sky than the system had**. The Office proceeded on the grounds that ingenuity would cover the difference | yes — the "one short" motif: the making was one sky short, the Litany is one node short (AUDIO-001 §5.1), the Act 4 Tree is one lamp short until the end (§4.3) |
| Y1 | Ignition. **The Ninth Light** does not finish lighting. The nine skies are not returned; they become the Nine Hollow Skies | yes |
| Y1 | The hole in the rules fills with the Unborn Dark in the star's unfinished shape: **Nhael'Gharoth** | yes |
| Y1 | Mourning Glass begins to form wherever the making's intentions went unfinished — which is everywhere | yes |
| Y1 | The Office authorises **the Vigil**: Lampkeepers in brass skiffs recover glass "to complete the light". Returning glass to the star (Charges) genuinely unbuilds the entity; nobody yet understands why | yes |
| Y3 | Office minutes: the quota cannot complete the light. The Vigil continues "for public confidence" (`cx_chron_hu_04` cites it) | yes |
| Y4 | Training cabinets, one per Vigil hall, curriculum by **Theodora Lune**. Recruitment rises. The honour roll is the enlistment list | yes |
| Y4–Y9 | Lampkeepers who die with lamps lit leave a residue: **the Penitent** | yes |
| Y5 onward | Families of Lampkeepers who did not come home begin gathering at Office glass-weighing stations, carrying glass themselves to finish the quota. Glass grows on people who carry grief that never finishes (§1.3). They become **the Hollow Choir**. The weighing stations become **Sepulchres** | yes — tier S4 |
| Y7 | The Choir's Litany forms: nine syllables for nine skies, eight stones because a weighing station has eight scale-pans. Nobody designed the gap | yes |
| Y9 | Theodora Lune finds the Y3 minutes. She cannot stop the cabinets. She hides her message behind the one condition a recruit would only meet by refusing to use the tools the curriculum taught (ending 5) | yes |
| Y9 | Ilse Marrow files her brother's card face down (§5.2) | yes |
| Y9, "The Last Normal Day" | The last Vigil hall's last recruit plays the cabinet to the end (Act 0). The Dark Star completes for the first time outside a simulation. The sky is eaten. The Observatory's last standing order, KEEP THE VIGIL, crystallises in the broken lens and begins the loop | yes. **The player is that recruit** |
| the loop | The Observatory budgets each Iteration as one Hourglass Clock (LOOP-001 §6.5); each ninth spent, a sky goes dark. Each time all nine go dark, the Observatory rewinds the Vigil from its scar. The Ruins, the Tree, the Codex and the three survivors are inside the scar and are not rewound | yes |

### 10.2 What each faction knew

| Fact | Office | Choir | Ruins cast | Player, by Act 4 |
|---|---|---|---|---|
| the making was one sky short | knew, before Y1 | no | Ilse (filed it) | if they read every `cx_chron_` page |
| the quota could not finish the light | knew, Y3 | no — they believe it can | Ilse | yes |
| Charges unbuild the entity | observed, not understood | they call it theft | Sable (understands it exactly) | yes |
| the Choir are the families | recommended no action, Y9 | they no longer remember being anything else | Wick suspects; Ilse knows | only via the Archivist variant |
| the cabinet recruited | yes — that was the point | no | Ilse filed the requisitions | Act 3 hints; ending 5 confirms |
| the loop is the Office's will | no — the Office was gone | they call it the god's breathing | none for certain | ending 1's 4th text |

### 10.3 Spoiler tiers (for store copy, press, trailers, community)

MARKET-001 uses this table. A tier may appear in a channel only if the channel's column says so.

| Tier | Contains | Store page | Trailer | Press kit | Community / Discord |
|---|---|---|---|---|---|
| **S0** | arcade shell; boss built from your ore; "THAT WAS A PRETENCE."; it eats a sky; the Ruins exist; the Cabinet exists as an object; Hollow King / Star That Failed | yes | yes | yes | yes |
| **S1** | the loop, Lantern Tree, Pacts, Codex; Sable, Ilse, Wick by name and role; the Lantern Office exists; Rites by name | yes | yes | yes | yes |
| **S2** | the Ninth Light; the Unborn Dark; the Choir is a funeral society; phantoms as mercy; the Salt Mother; rule-eating examples | no | as images only, no words | yes, marked | yes |
| **S3** | the cabinet was a recruitment machine; the honour roll; Theodora Lune by name; the entity's words come from the Cabinet; the Office knew in Y3 | **never** | **never** | embargo / spoiler section | spoiler-tagged only |
| **S4** | the Choir are the Lampkeepers' families; Tomas Marrow; Theodora's message text; ending 3/4 positions | **never** | **never** | **never** | spoiler-tagged; staff never post first |

---

## 11. What the writing refuses

### 11.1 No gore

**No gore, no body horror detail**, no described wounds, no corpses (GDD-001 §2 rating; WARP-001 §5 look contract)

**Applies to:** all text · **Instead:** things stop, go out, are filed

### 11.2 No jumpscares in text

**No jumpscares in text**: no sudden screaming caps outside the entity's display rule

**Applies to:** UI, Codex · **Instead:** the entity's lines are big but never sudden; the Silence precedes them

### 11.3 No moral-choice HUD

**No moral-choice HUD**, karma meter, or "you have chosen evil" text (§0.3)

**Applies to:** endings, Pacts · **Instead:** consequences are shown in the world, never scored

### 11.4 No villain monologue

**No villain monologue**

**Applies to:** entity · **Instead:** states, not plans (§3.4)

### 11.5 No jokes about the dead

**No jokes about the dead**; the Cabinet's deadpan stops at Act 3

**Applies to:** Cabinet, cast · **Instead:** —

### 11.6 The afterlife is not decided

**The afterlife is not decided.** No text, ending, Codex entry or character confirms or denies that the dead go anywhere. The Penitent is a residue, not a ghost. Ilse files the dead; she never says where they are. Wick hopes; he never says what for. The Choir believes "death is transport" (§1.5) and the writing never agrees or disagrees

**Applies to:** everything · **Instead:** write what was left, not where anyone went

### 11.7 No real-world religion

**No real-world religion** quoted, parodied or mapped one-to-one; the Choir's liturgy uses invented forms (§2.1)

**Applies to:** Choir text, chant · **Instead:** —

### 11.8 Ending 2 is never self-harm

**Ending 2 is never framed as suicide or self-harm.** No "end it", "give up on life", "you died by your own hand" language; the lamp is put out, not the Lampkeeper. The text says *rest* and *stand down*

**Applies to:** ending 2 · **Instead:** "YOU MAY REST."

### 11.9 No contempt for the player

**No contempt for the player.** The entity can be accurate; the game is never sneering

**Applies to:** all · **Instead:** —

### 11.10 No explaining a lie or an eat

**No explaining a lie or an eat** in any menu or Codex (WARP-001 L8)

**Applies to:** Codex, UI · **Instead:** the struck/restored form says *what*, never *why*

### 11.11 No romance or sexualised writing

**No sexualised, romantic or flirtatious writing** for any character

**Applies to:** cast · **Instead:** grief, duty, care


---

## 12. IP guardrails, applied (RES-001 §5)

| Guard (RES-001 §5) | Applied to narrative |
|---|---|
| the 1983 trademark is never used | not in any line, name, Codex entry, chant, file name, `en.po` context note or community post. The Cabinet's title is DARKSTAR, never anything else |
| no re-use of original expression | no 1983 voice line, nor a structural paraphrase of one (no "I live", "I hunger", "run, coward", "beware" constructions). Every entity line is checked against this before it is added to AUDIO-001 §4 or §7.3 here |
| mechanics may be reinterpreted | the boss-build race, the speech-as-state idea and the mining-to-bombs loop are reinterpreted, and the fiction gives each one a new reason (§1.3, §3.2) |
| "inspired by the classic arcade boss-you-have-to-build" is fine | MARKET-001 may use it in comps sections only, never in diegetic text |
| names | every §2.4 name gets a store and trademark search before 1.0 (owed; not done) |

---

## 13. Naming rules

| Group | Shape | Examples | Avoid |
|---|---|---|---|
| Lantern Office people | given name + plain surname, civic, a little old-fashioned | Theodora Lune, Ilse Marrow, Tomas Marrow | fantasy apostrophes; titles |
| Office things | functional nouns, capitalised | the Vigil, the honour roll, Vigil hall | anything poetic |
| Choir people | title + one word, often a material | Mother Ashe, Brother Wick, the Salt Mother | surnames (the Choir gave them up) |
| Choir things and ranks | "the" + plural participle, or "of the" constructions; numbers spelled out | the Carried, Herald of the Salted Chord | numerals |
| the entity | GDD-001 §19 names only (§3.4) | — | new epithets |
| Sable Vane | the only name that fits no group | — | do not "fix" it; it is part of Q-07 |

**How a new name enters §2.4:** (1) check GDD-001 §19 and §2.4 for an existing word; (2) pick the group and shape above; (3) check RES-001 §5 and run a store/trademark search (record the date); (4) add a §2.4 row with its spoiler tier; (5) if anything is unresolved, add a §14 question; (6) only then use it in another doc, a string or an asset name. A name used outside §2.4 is a bug (§0.3).

---

## 14. Open questions

| # | Question | Recommendation | Owner |
|---|---|---|---|
| Q-01 | Is the Choir-as-families reveal (S4) too heavy for a T rating? | keep it: it is grief without depiction; nothing is shown. Review with the rating questionnaire | narrative + producer |
| Q-02 | Does the Archivist epilogue need its own credits, or append to the reached ending's? | append: the variant is a reward, not a sixth ending | narrative |
| Q-03 | Act 0 initials entry on the honour roll (needed by `cx_vigil_honour_roll` and by the beat-3 honour roll under T.L., §5.4): is there a high-score initials screen in Act 0? | **add it** (3 letters, Cabinet register). It is the cheapest high-impact line in the game: the player sees their own initials on the Cabinet one line under T.L. Requested of LOOP-001 §11 / UI-001 | design + UI |
| Q-04 | Superseded 2026-11-17: the proposal that the Cabinet replay your deaths as its attract loop is dropped. LOOP-001 §10.4 beat 4 shows past deaths as stained glass instead, which costs no replay system | closed | — |
| Q-05 | ~~Eat lines in other languages~~ | closed 2026-11-17: the game is English only (L10N-001 §1); the ≤ 8-word rule stands | — |
| Q-06 | Should Wick's Matron (Mother Ashe) appear as a Rite or Herald memory? | no; she stays a name. A boss version would cheapen him | narrative |
| **Q-07** | **Is Sable Vane a previous Lampkeeper?** | **Unresolved by design.** Evidence on screen: the ring (one frame in the Rehearsal), knowledge of restores, the chalk colour in Act 4. Staff do not answer it, in docs, in community posts or to each other. Any line that would confirm or deny it is cut | narrative (sealed) |
| Q-08 | Does ending 3's "becomes the Lampkeeper" need a Codex page? | yes, one `cx_chron_` page in Choir register only: "The ninth voice came." | narrative |
| Q-09 | Theodora's message requires never using Surgelight or Ward in Act 0. Is that discoverable without a guide? | yes, eventually, by streamers; seed one community rumour at launch +60 days (MARKET-001), never confirm in official channels | marketing |
| Q-10 | Full Codex: how many entries at 1.0? | owed to LOOP-001 §12 content cost; this doc supplies 45 samples (41 before 2026-11-18; the old "32" here was stale) and the style guide. The cosmic horror design rev 3 adds 22 ids beyond the 122 plan; LOOP-001 §8.2 now counts 144 (2026-11-18), plus up to 4 reserve-kit entries (§8.7, Q-13) | narrative + producer |
| Q-11 | The Litany: the ruling (CHD-16) says a Litany line runs **eight** syllables, "always one short"; §1.5, §2.1 (liturgy row 2), §10.1 (Y7) and AUDIO-001 §5.1 say **nine syllables over eight ring-nodes**, and §9.3 sings the "complete nine-syllable Litany" in ending 3 | **Closed 2026-11-18** (cosmic horror design call within CHD-16, flagged in the Phase 2 PR): written in nine, sung in eight, always one short. The Choir sing eight, one per ring-node, and leave the ninth to "the ninth voice", which is always late; only ending 3 sings all nine. The 8-syllable sample lines (§2.1) are the sung form. §2.1's table now reads "written in nine syllables, sung in eight"; §1.5 and §10.1 Y7 already state the written form and stand | narrative + audio |
| Q-12 | Codex classes: the 27 gating ids (§8.6) collide with LOOP-001 §8.2's class scope and with two sample ids (§8.7: `cx_choir_vested`/`cx_choir_acolyte`, `cx_choir_comforters`/`cx_choir_deacon`, `cx_place_drowned_observatory` naming, no `cx_entity_` class, `cx_rule_`/`cx_chron_`/`cx_vigil_` scope, the Hollow sector's two entries) | **Closed 2026-11-18** (cosmic horror design call within CHD-15, flagged in the Phase 2 PR), except the Hollow sector's two entries, which stay open (§8.7 item 6). WARD-13 gates on `cx_choir_deacon`, ORDNANCE-5 on `cx_choir_acolyte`; LANTERN-10 on `cx_place_the_drowned_observatory`; `cx_entity_glimpsed` became the taught rule `cx_rule_the_glimpse`; LOOP-001 §8.2 widened `cx_rule_` (taught rules), `cx_chron_` (Chronicle milestones), `cx_vigil_` (authored pages; may gate) and `cx_choir_` (sacred things and rites), and recounted to 144. Ids are invariant once saved (LOOP-001 §8.2) | LOOP-001 owner + narrative |
| Q-13 | The reserve kits' rumours (§8.3) need entry ids, but LOOP-001 §8.2 has no per-kit `cx_place_` entries (though §6 here writes a fiction line per kit). The design draft's `cx_place_rumour_*` placeholders are not used: a rumour is a state of an entry, not a second entry | one `cx_place_` entry per reserve kit, id pattern set by LOOP-001; NARR then writes the four bodies | LOOP-001 + ZONES-001 + narrative |
| Q-14 | The tear (§4.5) requires Sable Vane's first line to be the first text read after the Pretence. The Cabinet's Ruins marquee ("PLAYER 1 · STILL ON DUTY", §7.5) and Ilse's first written note could be read first, depending on where the player arrives (LOOP-001 §1) | the Cabinet's marquee stays in attract without text, and the Codex alcove stays unlit, until Sable's first-visit line has been shown | narrative + LOOP-001 + UI |
| Q-15 | The entity's voice and face against the N-rules: AUDIO-001 §4.2's Type row ("the entity's own face") conflicts with CHD-16 (the Cabinet's face from Act 1); AUDIO-001 §4.3 says "the entity has a mouth" (a voicing note) while §3.4 and N4 forbid a mouth that speaks; N9 says it has no sound of its own | **Closed 2026-11-18:** resolved by the Game audio chat in AUDIO-001 §4.2, §4.3 and §12.12 (2026-11-18). (The recommendation was: read N9 as its *presence* being silent, heard as sound removed, and its lines as borrowed words, not its own sound (§3.4 N9); reword AUDIO-001's "mouth" note as a delivery note.) | audio + narrative |
| Q-16 | L12 (§7.2): if two lies were live within the death-attribution window, does the death screen print one discrepancy line or more, and in what order? | **Closed 2026-11-18** (cosmic horror design call within CHD-04, flagged in the Phase 2 PR): one line per lying element, the Compass line first (§7.2). Only the Compass line is live today, so in practice one line prints; CHARGES and INDEX are reserved (WARP-001 Q-14) | WARP-001 owner |
