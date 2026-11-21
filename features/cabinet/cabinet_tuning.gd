class_name CabinetTuning
extends TunableResource
## Act 0 — the Cabinet (GDD §6.1, NARR-001 §5): every gameplay number of the arcade shell.
## Values are copied from SYS-001 (section in each comment) or marked ✱ (first-pass, owned by
## the cabinet feature, requested as SYS-001 rows in TECH-001 §11.1). The Act 0 scale block is SYS-001 §1.7.

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

# --- Ship handling (owner F-9, Q-T445; PROVISIONAL, retuned by playing; source ratios in research/sinistar_player_movement.md) ---
enum MoveModel { DIRECT, MOMENTUM }
@export var move_model: MoveModel = MoveModel.MOMENTUM   ## DIRECT = the old SYS-001 §1.1 twin-stick (accel/drag/brake); MOMENTUM = the arcade original's one-stick tank. Switch in data to compare
@export var momentum_max_speed: float = 340.0     ## px/s ✱ the same cap at any deflection (source: fixed target speed); = the Vigil's max_speed 🔒, so the ceiling does not move
@export var momentum_ease_rate: float = 3.8       ## 1/s ✱ full-stick rate at which velocity closes on heading × max (source ≈ 3.6–4.0/s, 95 % in ≈ 0.8 s); scales with deflection
@export var momentum_turn_rate: float = 40.0      ## 1/s ✱ full-stick rate at which the hull heading closes on the stick (source ≈ 0.45–0.5 of the gap per 16 ms tick, ≈ 3 ticks to face it); scales with deflection
@export var momentum_thrust_arc_deg: float = 45.0 ## deg ✱ thrust only while the stick is within this angle of the heading (source ±$20 of 256 = ±45°)

# --- Waking lifecycle (SYS-001 §2, §2.1) ---
@export var segments_total: int = 20             ## 🔒
@export var shards_per_segment: int = 3          ## ✱ (SYS-001 §2 phase 1)
@export var guard_at: int = 6                    ## segments: Litany Ring forms (phase 2)
@export var quickening_at: int = 12              ## 🔒 phase 3
@export var unravel_hits: int = 13               ## 🔒 Charges to unmake the complete entity
@export var stagger_window: float = 3.0          ## s, Awakening stagger window
@export var stagger_hits: int = 3                ## 🔒 hits inside it
@export var awakening_silence: float = 1.2       ## s of silence before the line (GDD §12)
@export var rampage_speed: float = 150.0         ## px/s ✱ code default; data/cabinet/cabinet_tuning.tres sets the PROVISIONAL awake chase speed 380, FASTER than the Vigil (owner F-4, Q-T441)
@export var entity_turn_rad_s: float = 2.2       ## rad/s ✱ the awake entity's steering: kite-able, never twitchy (was the ENTITY_TURN constant; Q-T444)
@export var rampage_catchup_px: float = 0.0       ## px ✱ PROVISIONAL (Q-T447): beyond this Vigil↔entity distance the awake entity sprints on its first approach (the source Sinistar sprints when far, Q-T446); 0 = off. Data sets 640 (the neighbourhood half-size, the Compass edge)
@export var rampage_catchup_speed: float = 0.0    ## px/s ✱ PROVISIONAL (Q-T447): the sprint speed (data: 680 = 2× the Vigil max_speed 340); never below rampage_speed
@export var rampage_ease_rate: float = 0.0         ## 1/s ✱ PROVISIONAL (Q-T446, owner F-9): the awake entity's velocity closes on (toward the Vigil × speed) at this rate (source `asrd` shift 4 ≈ 4/s); 0 = the old fixed-speed, turn-capped chase (entity_turn_rad_s). Data sets 4.0
@export var rampage_catchup_ease_rate: float = 0.0 ## 1/s ✱ PROVISIONAL (Q-T446): the same ease on the far sprint row (source top row, shift 5 ≈ 2/s). Data sets 2.0
@export var eat_geode_time: float = 2.0          ## s the entity stops to eat a geode
@export var eat_unit_cooldown: float = 6.0       ## s between unit meals (1 restore per 6 s, cap 3)
@export var eat_restore_cap: int = 3
@export var knock_min: int = 1                   ## modules knocked off by a Charge on the Sepulchre
@export var knock_max: int = 3

# --- Choir units (SYS-001 §3) ---
@export var grub_hp: int = 2                      ## SYS-001 §3 (F-11, owner 2026-11-20: 50% of the old 4)
@export var grub_speed_carry: float = 130.0
@export var grub_speed_flee: float = 190.0
@export var grub_mine_period_s: float = 0.0        ## s ✱ PROVISIONAL (Q-T451): a mining Grub gnaws its geode once per this many seconds; 0 = off 
@export var grub_mine_range_px: float = 240.0      ## px ✱ PROVISIONAL (Q-T451): an idle Grub with no loose glass looks for a geode this near (about one screen)
@export var grub_mine_max: int = 0                 ## ✱ PROVISIONAL (Q-T451): at most this many Grubs mine at once (data 3); the rest keep shadowing the Vigil
@export var grub_mine_clear_px: float = 0.0        ## px ✱ PROVISIONAL (Q-T451): they only mine rock at least this far from the Vigil, out of its lance's line (data 160)
@export var grub_mine_standoff_px: float = 6.0     ## px ✱ PROVISIONAL (Q-T451): it hovers this far past the geode's edge
@export var grub_haul_catchup_px: float = 0.0      ## px ✱ PROVISIONAL (Q-T449): a laden Grub farther than this from the Sepulchre hauls at grub_haul_catchup_speed; 0 = off (data sets 600)
@export var grub_haul_catchup_speed: float = 0.0   ## px/s ✱ PROVISIONAL (Q-T449): the far haul speed (data 260: above the 190 flee speed, below the Vigil's 340); never below grub_speed_carry
@export var grub_ease_rate: float = 5.0           ## 1/s ✱ exponential ease of a Grub's velocity toward its wanted velocity (was a code literal; the reference's `asrdN` shift, larger = snappier; Q-T444)
@export var grub_flee_radius: float = 70.0        ## px ✱ (flees the Vigil's lamp in Act 0; was 110, which pushed them off a 128 px half-view)
@export var grub_shadow_radius: float = 100.0     ## px ✱ an idle Grub circles the Vigil at about this distance (the reference's workers wait near the player)
@export var grub_shadow_band: float = 24.0        ## px ✱ ± spread of that orbit radius, per Grub
@export var acolyte_hold_px: float = 120.0          ## px ✱ an engaged Acolyte holds this far from the Vigil (was the HOLD_DISTANCE constant)
@export var acolyte_patrol_min_px: float = 160.0  ## px ✱ an idle Acolyte patrols the Vigil from this distance …
@export var acolyte_patrol_max_px: float = 220.0  ## px ✱ … to this one
@export var grub_respawn: float = 6.0            ## s ✱ the Sepulchre births a replacement
@export var acolyte_hp: int = 6
@export var grub_intercept_range: float = 150.0   ## px ✱ PROVISIONAL (Q-T440): a Grub this close to a Charge flying at the Sepulchre dives into its path and dies (Sinibomb-intercept analogue)
@export var grub_intercept_speed: float = 220.0   ## px/s ✱ PROVISIONAL (Q-T440): the Grub's dive speed
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
@export var geode_drift_floor: float = 0.8       ## ✱ drift-in runs while live geodes < floor(stage.geodes × this)
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

# --- Act 0 scale (SYS-001 §1.7, Q-T365–Q-T377; every row PROPOSED ✱, retuned after a human plays it) ---
@export var field_neighbourhood_half_px: float = 640.0    ## px ✱ half-size of the box round the Vigil the free units live in (= the Compass range ±640; 1,280 px box, 25 screens)
@export var field_sepulchre_start_px: float = 2560.0      ## px ✱ the Sepulchre starts this far straight ahead of the Vigil's heading
@export var field_sepulchre_leash_px: float = 4096.0      ## px ✱ beyond this Vigil↔Sepulchre distance the Sepulchre drifts toward the Vigil…
@export var field_sepulchre_drift_px_s: float = 90.0      ## px/s ✱ …at this speed (slower than the Vigil, so it is never escaped for good)
@export var compass_px_per_dot: float = 32.0              ## world px per Ledger Compass px ✱ (inner 40 px = 1,280 world px)
@export var size_grub_px: float = 11.0                    ## px ✱ Grub's longest drawn extent; hurt radius = size / 2 − 1
@export var size_acolyte_px: float = 15.0                 ## px ✱ Acolyte's longest drawn extent; hurt radius = size / 2 − 1
@export var size_geode_radii: Array[float] = [9.0, 12.0, 15.0]   ## px ✱ geode radius by size class 0..2
@export var size_shard_px: float = 5.0                    ## px ✱ Mourning Glass shard's drawn length (pickup and magnet unchanged)
@export var acolyte_enter_hold_s: float = 1.0             ## s ✱ an Acolyte entering the view holds fire this long before its tell
@export var acolyte_mine_range_px: float = 640.0          ## px ✱ ENGINEERING (not a SYS-001 §1.7 row): how far an Acolyte looks for a geode to mine; = the neighbourhood half-size
@export var acolyte_mine_standoff_px: float = 36.0           ## px ✱ ENGINEERING (not a SYS-001 §1.7 row): a mining Acolyte hovers this far beyond the geode's edge
@export var unmakings_required: int = 2                         ## Act 0 ends at the last stage's Unmaking: 2 on [a0_1, a0_4, a0_5] (SYS-001 §1.7, Q-T365, Q-T452); = the roster's UNMAKE_ENTITY stages (a test asserts it)

# --- The stage card (SYS-001 §1.7, Q-T371–Q-T374; UI-001 §11; PROPOSED ✱) ---
@export var brief_arm_s: float = 0.35                    ## s ✱ fire_lance is ignored until the card has been up this long (and it needs a fresh press)
@export var brief_prompt_duty: float = 0.7                ## fraction ✱ of each blink cycle PRESS FIRE is lit (was 0.5: stills could miss it)
@export var brief_prompt_blink_hz: float = 1.5            ## Hz ✱ PRESS FIRE blinks (under the 3 Hz flash rule); steady under photosensitivity or reduced motion
@export var brief_ready_after_s: float = 1.5              ## s ✱ the READY card after the press (was 2.5 s)
@export var brief_autopilot_s: float = 1.0                ## s ✱ --autopilot and --smoke dismiss the card after this long


func tunable_properties() -> PackedStringArray:
	var out := PackedStringArray()
	for p in get_property_list():
		if (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) and p.name != "ds_namespace" and p.name != "source_section":
			out.append(p.name)
	return out
