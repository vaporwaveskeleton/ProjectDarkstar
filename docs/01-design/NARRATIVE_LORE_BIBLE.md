# DARKSTAR — Narrative & Lore Bible

**Doc ID:** NARR-001 · **Version:** 1.0 · **Date:** 2026-11-16 · **Owner:** narrative · **Status:** complete-draft
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
| writing a Codex entry or a terminal text | §7, §8 | §11 (what the writing refuses), §19 vocabulary |
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
| Whether the entity, once unmade, becomes something else | only ending 4 and ending 3 take a position, and they take opposite ones (§9.4, §9.5) |
| Whether any character in the Ruins is a previous Lampkeeper in disguise | §5 leaves exactly one such hint (Sable Vane) unconfirmed on purpose. It is a thread, not a fact, and §14 Q-07 records it as unresolved |

---
