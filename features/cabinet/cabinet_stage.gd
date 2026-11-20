class_name CabinetStage
extends Resource
## One authored Act 0 level (GDD §6.1). Content, not tuning: which units, how the Sepulchre starts,
## and what ends the stage. Per-stage counts are the Act 0 stage table, SYS-001 §1.6 (PM 2026-11-19).
## The five stages run in order from CabinetStageRoster (data/cabinet/stage_roster.tres).

enum Goal { CLEAR_SEPULCHRE, UNMAKE_ENTITY }

@export var id: StringName = &"a0_1"
@export var title_key: String = ""                  ## shown on the READY card
@export var subtitle_key: String = ""
@export var zone_key: String = ""                   ## zone name line on the READY card; empty = none
@export var zone_cue: StringName = &""              ## AUDIO-001 jingle under the READY card (unknown id = silent no-op); empty = none
@export var music: StringName = &""                 ## the stage loop on BUS-MUS (chirp render id; CabinetStageMusic), detuned by W0-11 Wear; empty = none (Q-T188: a0_4, a0_5)
@export var field_size: Vector2 = Vector2(65536, 65536) ## ✱ torus field: 256 × 256 screens (SYS-001 §1.7, Q-T366)
@export var geodes: int = 10                         ## ≥ 24 shards of supply (SYS-001 §4 lint)
@export var grubs: int = 4
@export var acolytes: int = 1
@export var guard_acolytes: int = 1                  ## join at the Guard phase
@export var sepulchre_start_segments: int = 0
@export var sepulchre_wakes: bool = true             ## false = Cold Sepulchre (W0-05)
@export var chant: bool = true                       ## A0-2 rule: the chant is heard under the music
@export var goal: Goal = Goal.UNMAKE_ENTITY
@export var seed: int = 1
@export var spine_stars: bool = false                ## S8: 20 faint stars trace the entity's spine (THE LAST NORMAL DAY, a0_5, only)
@export var backdrop: StringName = &""                 ## stage signature drawn behind the stars (Starfield.BACKDROPS): "" plain, currents, chains, shoal, horizon

# --- P2 "pressure" switches (PM Q-T105, 2026-11-19). Every default reproduces the pre-P2 game. ---
@export var acolyte_reinforce_s: float = 0.0         ## s of play between censer bells (Acolyte reinforcements); 0 = off (Acolytes never respawn)
@export var acolyte_cap: int = 0                     ## a bell brings one Acolyte only while fewer than this many live (guard ring included)
@export var reinforce_after_wake: bool = true         ## false = the bells stop once the Sepulchre wakes (a pending one is called off)
@export var geode_drift_s: float = 0.0               ## s between drift-in geodes once the field is thinned (CabinetTuning.geode_drift_floor); 0 = off
@export var grubs_after_wake: bool = false           ## the Sepulchre keeps birthing replacement Grubs after the wake
@export var grub_pilfer: bool = false                ## Grubs snatch nearby loose glass the Vigil's magnet is not pulling
@export var acolyte_escort: bool = false             ## idle non-guard Acolytes trail laden Grubs instead of mining
@export var carry_charges_in: bool = false           ## as the next stage of a running shift, start with the Charges held at the last stage's end
@export var acolyte_mine: bool = false               ## idle Acolytes with no Vigil in range fly to the nearest geode and lance it (SYS-001 §1.7; a0_3–a0_5)
