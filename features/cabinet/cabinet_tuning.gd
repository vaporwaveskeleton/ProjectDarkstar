class_name CabinetTuning
extends TunableResource
## Act 0 — the Cabinet (GDD §6.1, NARR-001 §5): every gameplay number of the arcade shell.
## Values are copied from SYS-001 (section in each comment) or marked ✱ (first-pass, owned by
## the cabinet feature, requested as SYS-001 rows in TECH-001 §11.1).

# --- Arc-Lance (SYS-001 §1.3) ---
@export var lance_rate: float = 6.0              ## shots/s 🔒
@export var lance_speed: float = 340.0           ## px/s
@export var lance_length: float = 14.0           ## px (visual)
@export var lance_life: float = 0.9              ## s ✱ (range ≈ 300 px)
@export var face_hits: int = 5                   ## hits to shatter a geode face (0.9 s at base rate) 🔒
@export var overfire_hits: int = 7               ## ✱ hits within the window that detonate a geode (PM 2026-11-18)
@export var overfire_window: float = 1.2         ## s ✱
@export var shards_calm: int = 3                 ## 🔒 shards from a calmly mined geode
@export var shards_detonated_min: int = 4        ## ✱
@export var shards_detonated_max: int = 6        ## ✱
@export var detonation_scatter: float = 140.0    ## px ✱

# --- Glass and Charges (SYS-001 §1.4) ---
@export var magazine: int = 5                    ## Charge pips 🔒
@export var magnet_radius: float = 96.0          ## px ⚙
@export var charge_speed: float = 210.0          ## px/s 🔒
@export var charge_turn_authority: float = 1.6   ## s 🔒 — time to turn a full half-circle
@export var charge_life: float = 6.0             ## s ✱ before it gutters out (counts as lost)

# --- Waking lifecycle (SYS-001 §2, §2.1) ---
@export var segments_total: int = 20             ## 🔒
@export var shards_per_segment: int = 3          ## ✱ (SYS-001 §2 phase 1)
@export var guard_at: int = 6                    ## segments: Litany Ring forms (phase 2)
@export var quickening_at: int = 12              ## 🔒 phase 3
@export var unravel_hits: int = 13               ## 🔒 Charges to unmake the complete entity
@export var stagger_window: float = 3.0          ## s, Awakening stagger window
@export var stagger_hits: int = 3                ## 🔒 hits inside it
@export var awakening_silence: float = 1.2       ## s of silence before the line (GDD §12)
@export var rampage_speed: float = 150.0         ## px/s at Hunger 0 (always slower than the Vigil)
@export var eat_geode_time: float = 2.0          ## s the entity stops to eat a geode
@export var eat_unit_cooldown: float = 6.0       ## s between unit meals (1 restore per 6 s, cap 3)
@export var eat_restore_cap: int = 3
@export var knock_min: int = 1                   ## modules knocked off by a Charge on the Sepulchre
@export var knock_max: int = 3

# --- Choir units (SYS-001 §3) ---
@export var grub_hp: int = 4
@export var grub_speed_carry: float = 130.0
@export var grub_speed_flee: float = 190.0
@export var grub_flee_radius: float = 110.0      ## px ✱ (flees the Vigil's lamp in Act 0)
@export var grub_respawn: float = 6.0            ## s ✱ the Sepulchre births a replacement
@export var acolyte_hp: int = 6
@export var acolyte_speed: float = 150.0
@export var acolyte_shot_speed: float = 240.0
@export var acolyte_cycle: float = 1.8           ## s between shots
@export var acolyte_tell: float = 0.35           ## s (21 frames) 🔒
@export var acolyte_turret_lag: float = 0.25     ## s 🔒
@export var acolyte_range: float = 300.0         ## px ✱ engagement range
@export var acolyte_shot_life: float = 2.2       ## s ✱

# --- Stage pressure (P2, PM Q-T105; per-stage switches live on CabinetStage) ---
@export var reinforce_tell_s: float = 1.0        ## s ✱ censer-bell warning before a reinforcement Acolyte arrives
@export var reinforce_entry_px: float = 24.0     ## px ✱ the arrival point sits this far outside the view edge
@export var geode_drift_floor: float = 0.5       ## ✱ drift-in runs while live geodes < floor(stage.geodes × this)
@export var geode_drift_clear_px: float = 160.0  ## px ✱ a drift-in geode appears at least this far from the Vigil (and off-view)
@export var grub_pilfer_radius: float = 160.0    ## px ✱ how far a pilfering Grub looks for loose glass
@export var escort_distance: float = 60.0        ## px ✱ an escorting Acolyte trails its laden Grub at this distance

# --- Score (SYS-001 §7.1, Act 0 — the 1983 table) and lives (GDD §9.4) ---
@export var score_face: int = 5
@export var score_shard: int = 200
@export var score_grub: int = 150
@export var score_acolyte: int = 500
@export var score_module: int = 500
@export var score_entity: int = 15000
@export var extra_life_first: int = 10000
@export var extra_life_second: int = 30000       ## PM Q-T107 (2026-11-19): 10k, 30k, then every extra_life_every
@export var extra_life_every: int = 40000        ## PM Q-T107: 70k, 110k, …
@export var lives_cap: int = 5
@export var lives_start: int = 3                 ## ✱ arcade convention; requested SYS-001 row

# --- Vigil in the cabinet ---
@export var respawn_delay: float = 2.0           ## s ✱
@export var respawn_shield: float = 2.0          ## s ✱ blinking invulnerability after respawn
@export var surgelight_impulse: float = 200.0    ## px/s burst (SYS-001 §1.1)
@export var surgelight_time: float = 0.18        ## s
@export var surgelight_cooldown: float = 1.6     ## s
@export var hitbox_radius: float = 6.0           ## px — 12 px diameter (SYS-001 §9, R-04)


func tunable_properties() -> PackedStringArray:
	var out := PackedStringArray()
	for p in get_property_list():
		if (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) and p.name != "ds_namespace" and p.name != "source_section":
			out.append(p.name)
	return out
