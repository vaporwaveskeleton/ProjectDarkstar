class_name CabinetFxTuning
extends TunableResource
## Act 0 — the Cabinet: presentation numbers for bursts, rings and shake, one field per event.
## All ✱ engineering presentation params (TECH-001); SYS-001 §9 holds only the shake caps
## (4.0 px / 0.25 s), which stay literal 🔒 constants in ArcadeWorld.shake().

# --- Stage hand-off (Q-T457, owner 2026-11-20: the 4 s hold was too long; feedback at the fall; the sky warps into the next stage) ---
@export var handoff_collapse_s: float = 0.5               ## s ✱ PROVISIONAL: the beat after the last module falls (caption up, sim running), mid-shift ends only
@export var handoff_morph_s: float = 0.9                  ## s ✱ PROVISIONAL: the sky dissolves and warps into the next stage's look; then its stage card opens
@export var handoff_warp_px: float = 9.0                  ## px ✱ the sky's low-frequency bend, peak mid-morph (0 under photosensitivity / reduced motion)
@export var handoff_tear_px: float = 12.0                 ## px ✱ the high-frequency tear: a third of the 5 px row bands jump by up to this
@export var handoff_ghost_px: float = 3.0                 ## px ✱ colour-register separation: a second VOID register slips off every other mark
@export var handoff_wash: float = 0.16                    ## ✱ peak alpha of the one kill-frame wash over the playfield (VOID_5, a single pulse)
@export var handoff_wash_s: float = 0.3                   ## s ✱ the wash falls over this long (one event, never a strobe)
@export var handoff_wear_gain: float = 0.35               ## ✱ every displacement x (1 + wear level x this): later stages tear harder
@export var sepulchre_down_burst_count: int = 60          ## ✱
@export var sepulchre_down_burst_speed: float = 150.0     ## px/s ✱
@export var sepulchre_down_ring_radius: float = 90.0      ## px ✱
@export var sepulchre_down_shake_amp: float = 4.0         ## px ✱ (≤ 4.0 cap)
@export var sepulchre_down_shake_dur: float = 0.25        ## s ✱ (≤ 0.25 cap)

# --- Ring spawn / deposit / pickup ---
@export var acolyte_guard_ring_radius: float = 24.0       ## px ✱ guard acolyte spawns
@export var ritual_deposit_ring_radius: float = 16.0      ## px ✱ a Grub delivers a shard
@export var shard_pickup_ring_radius: float = 14.0        ## px ✱ Vigil collects a shard
@export var heal_ring_radius: float = 44.0                ## px ✱ the entity restores a hit

# --- Acolyte death ---
@export var acolyte_death_burst_count: int = 22           ## ✱
@export var acolyte_death_burst_speed: float = 110.0      ## px/s ✱
@export var acolyte_death_ring_radius: float = 30.0       ## px ✱
@export var acolyte_death_shake_amp: float = 2.0          ## px ✱ (≤ 4.0 cap)
@export var acolyte_death_shake_dur: float = 0.15         ## s ✱ (≤ 0.25 cap)

# --- Geode ---
@export var geode_devour_burst_count: int = 14            ## ✱ entity eats a geode
@export var geode_devour_burst_speed: float = 60.0        ## px/s ✱
@export var geode_break_burst_count: int = 14             ## ✱ calm break
@export var geode_break_burst_speed: float = 70.0         ## px/s ✱
@export var geode_violent_burst_count: int = 26           ## ✱ detonation
@export var geode_violent_burst_speed: float = 140.0      ## px/s ✱
@export var geode_break_ring_scale: float = 1.6           ## x geode radius ✱ calm
@export var geode_violent_ring_scale: float = 3.0         ## x geode radius ✱ detonation
@export var geode_violent_shake_amp: float = 3.0          ## px ✱ (≤ 4.0 cap)
@export var geode_violent_shake_dur: float = 0.2          ## s ✱ (≤ 0.25 cap)

# --- Charges ---
@export var charge_lost_burst_count: int = 10             ## ✱
@export var charge_lost_burst_speed: float = 50.0         ## px/s ✱
@export var charge_intercepted_ring_radius: float = 18.0  ## px ✱

# --- Grub ---
@export var grub_death_burst_count: int = 12              ## ✱
@export var grub_death_burst_speed: float = 70.0          ## px/s ✱

# --- Sepulchre and entity ---
@export var ritual_bare_hit_burst_count: int = 6          ## ✱ Charge on a bare Sepulchre
@export var ritual_bare_hit_burst_speed: float = 40.0     ## px/s ✱
@export var modules_knocked_burst_per_module: int = 10    ## ✱ x modules knocked
@export var modules_knocked_burst_speed: float = 120.0    ## px/s ✱
@export var modules_knocked_ring_radius: float = 40.0     ## px ✱
@export var modules_knocked_shake_amp: float = 3.0        ## px ✱ (≤ 4.0 cap)
@export var modules_knocked_shake_dur: float = 0.2        ## s ✱ (≤ 0.25 cap)
@export var entity_hit_burst_count: int = 16              ## ✱ a Charge on the entity
@export var entity_hit_burst_speed: float = 140.0         ## px/s ✱
@export var entity_hit_ring_radius: float = 50.0          ## px ✱
@export var entity_hit_shake_amp: float = 4.0             ## px ✱ (≤ 4.0 cap)
@export var entity_hit_shake_dur: float = 0.25            ## s ✱ (≤ 0.25 cap)
@export var entity_unmade_burst_a_count: int = 80         ## ✱
@export var entity_unmade_burst_a_speed: float = 220.0    ## px/s ✱
@export var entity_unmade_burst_b_count: int = 40         ## ✱
@export var entity_unmade_burst_b_speed: float = 160.0    ## px/s ✱
@export var entity_unmade_ring_radius: float = 160.0      ## px ✱
@export var entity_unmade_shake_amp: float = 4.0          ## px ✱ (≤ 4.0 cap)
@export var entity_unmade_shake_dur: float = 0.25         ## s ✱ (≤ 0.25 cap)
@export var it_wakes_shake_amp: float = 4.0               ## px ✱ (≤ 4.0 cap)
@export var it_wakes_shake_dur: float = 0.25              ## s ✱ (≤ 0.25 cap)
@export var it_wakes_ring_radius: float = 200.0           ## px ✱

# --- Vigil ---
@export var vigil_death_burst_a_count: int = 40           ## ✱
@export var vigil_death_burst_a_speed: float = 160.0      ## px/s ✱
@export var vigil_death_burst_b_count: int = 20           ## ✱
@export var vigil_death_burst_b_speed: float = 90.0       ## px/s ✱
@export var vigil_death_ring_radius: float = 60.0         ## px ✱
@export var vigil_death_shake_amp: float = 4.0            ## px ✱ (≤ 4.0 cap)
@export var vigil_death_shake_dur: float = 0.25           ## s ✱ (≤ 0.25 cap)


@export_group("lance bite ⚙ owner-approved 2026-11-18, SYS-001 §9")
@export var muzzle_star_px: int = 3                       ## px ⚙ owner-approved 2026-11-18, SYS-001 §9: arm length of the muzzle plus
@export var muzzle_star_frames: int = 1                   ## drawn frames ⚙ owner-approved 2026-11-18, SYS-001 §9: how long the muzzle star shows
@export var recoil_px: int = 1                            ## px ⚙ owner-approved 2026-11-18, SYS-001 §9: visual-only draw nudge opposite the aim (never moves pos/vel, SYS-001 §1.3)
@export var recoil_frames: int = 2                        ## drawn frames ⚙ owner-approved 2026-11-18, SYS-001 §9
@export var fleck_speed_px_s: float = 60.0                ## px/s ⚙ owner-approved 2026-11-18, SYS-001 §9: impact flecks leave perpendicular to the shot
@export var fleck_life_s: float = 0.12                    ## s ⚙ owner-approved 2026-11-18, SYS-001 §9
@export var tick_len_px: int = 3                          ## px ⚙ owner-approved 2026-11-18, SYS-001 §9: the chalk tick where the lance cannot bite
@export var tick_life_s: float = 0.15                     ## s ⚙ owner-approved 2026-11-18, SYS-001 §9
@export var lance_dull_db: float = 0.0                    ## dB ⚙ owner-approved 2026-11-18, SYS-001 §9: lance_dull cue volume
@export_group("")

@export_group("readable death ⚙ PM-approved 2026-11-18, SYS-001 §9")
@export var death_ring_pad_px: float = 6.0                ## px ⚙ PM-approved 2026-11-18, SYS-001 §9: dashed chalk gap beyond the outermost drawn part of the killer (for a shot: the shooter Acolyte, drawn radius + this) (wider than the entity plate spacing, ~5 px)
@export var death_big_killer_px: float = 12.0             ## px ✱ engineering (TECH-001, not a SYS-001 row): killers drawn larger than this (the entity) are tracked live by the leader
@export var death_arrow_px: float = 30.0                  ## px ⚙ PM-approved 2026-11-18, SYS-001 §9: arrow shaft length = VigilShip.HULL_LENGTH x death_outline_scale
@export var death_outline_scale: float = 2.0              ## x ⚙ PM-approved 2026-11-18, SYS-001 §9: the coroner outline (and arrow, tip inset, head) is this many times the hull size
@export var death_chalk_delay_s: float = 0.5              ## s sim ⚙ PM-approved 2026-11-18, SYS-001 §9: no chalk until the Vigil's GAS death burst ring has faded (effective delay = max(this, FxLayer.ring_life(vigil_death_ring_radius)) = 0.5); applies under Reduced Motion too
@export var death_outline_draw_s: float = 0.15            ## s sim ⚙ PM-approved 2026-11-18, SYS-001 §9: the coroner outline draws on first (full at once under Reduced Motion)
@export var death_arrow_draw_s: float = 0.12              ## s sim ⚙ PM-approved 2026-11-18, SYS-001 §9: then the arrow draws on, then it all holds until respawn
@export var death_edge_tick_px: float = 5.0               ## px ⚙ PM-approved 2026-11-18, SYS-001 §9: chalk tick on the view edge pointing at an off-view killer
@export_group("")

@export_group("surge afterimage ⚙ PM-approved 2026-11-18, SYS-001 §9")
@export var ghost_count: int = 3                          ## ⚙ PM-approved 2026-11-18, SYS-001 §9: hull outlines trailing a Surgelight burst
@export var ghost_spacing_ticks: int = 3                  ## sim ticks ⚙ PM-approved 2026-11-18, SYS-001 §9: base spacing; ghost k sits spacing*k*(k+1)/2 ticks back (3, 9, 18)
@export var ghost_hold_s: float = 0.1                     ## s sim ⚙ PM-approved 2026-11-18, SYS-001 §9: ghosts linger this long after the surge ends
@export var ghost_bracket_frac_1: float = 0.6             ## x edge length ⚙ PM-approved 2026-11-18, SYS-001 §9: corner bracket length, nearest ghost (capped at 0.4 on the two nose edges so no edge closes)
@export var ghost_bracket_frac_2: float = 0.32            ## x edge length ⚙ PM-approved 2026-11-18, SYS-001 §9
@export var ghost_bracket_frac_3: float = 0.2             ## x edge length ⚙ PM-approved 2026-11-18, SYS-001 §9: farthest ghost
@export var wake_dots: int = 6                            ## ⚙ PM-approved 2026-11-18, SYS-001 §9: 1x1 dots trailing a thrusting Vigil
@export var wake_spacing_ticks: int = 2                   ## sim ticks ⚙ PM-approved 2026-11-18, SYS-001 §9: ticks back between wake dots
@export_group("")

@export_group("true-body frame ⚙ PM-approved 2026-11-19, SYS-001 §9")
@export var true_frame_frames: int = 1                    ## drawn frames ⚙ PM-approved 2026-11-19, SYS-001 §9: a Charge hit on the costume entity shows its true silhouette this long (GDD §20: silhouette only)
@export_group("")

@export_group("star spine ⚙ PM-approved 2026-11-19, SYS-001 §9")
@export var spine_hold_pull: float = 0.02                 ## Starfield.pull ⚙ PM-approved 2026-11-19, SYS-001 §9: the spine stars brighten and hold below this pull (~1.1 s of the 8 s ease-in quad)
@export var spine_pull_span: float = 0.07                 ## Starfield.pull ⚙ PM-approved 2026-11-19, SYS-001 §9: pull range over which they travel to the vertebrae; 0.07 lands them at pull 0.09 (~2.4 s), before reveal starts showing vertebrae (~2.5 s, pull ~0.098)
@export_group("")

# --- Hit-stop ⚙ (owner-approved 2026-11-18, SYS-001 §9) ---
# Sim frames (physics ticks at 60 Hz). Freezes the sim only: audio, CRT, state timers and input keep running.
@export var hitstop_charge_hits_entity_frames: int = 3    ## frames ⚙ owner-approved 2026-11-18, SYS-001 §9 (_hit_entity)
@export var hitstop_entity_unmade_frames: int = 8         ## frames ⚙ owner-approved 2026-11-18, SYS-001 §9 (_unmake)
@export var hitstop_vigil_death_frames: int = 6           ## frames ⚙ owner-approved 2026-11-18, SYS-001 §9 (VigilShip.kill)
@export var hitstop_it_wakes_frames: int = 4              ## frames ⚙ owner-approved 2026-11-18, SYS-001 §9 (AWAKENING "IT WAKES")
@export var hitstop_modules_knocked_frames: int = 2       ## frames ⚙ owner-approved 2026-11-18, SYS-001 §9 (_knock_modules)
@export var hitstop_max_frames: int = 10                  ## frames ⚙ owner-approved 2026-11-18, SYS-001 §9: hard cap on any freeze or stack
@export var hitstop_reduced_motion_scale: float = 0.5     ## ⚙ owner-approved 2026-11-18, SYS-001 §9: frames x this under Reduced Motion; 0 disables

@export_group("credits ⚙ owner-approved 2026-11-18, SYS-001 §9")
@export var credits_scroll_px_per_s: float = 24.0         ## px/s ⚙ owner-approved 2026-11-18, SYS-001 §9: the roll's scroll speed (was a literal)
@export var credits_full_seconds: float = 13.0            ## s ⚙ owner-approved 2026-11-18, SYS-001 §9: the full stage-2 roll with the service record (was 9.0)
@export_group("")

@export_group("slow-mo ⚙ owner-approved 2026-11-18, SYS-001 §9")
@export var slowmo_scale: float = 0.25                    ## sim speed during the last-Charge slow-mo, 0.25..1.0 (audio clamps there) ⚙ owner-approved 2026-11-18, SYS-001 §9
@export var slowmo_trigger_px: float = 130.0              ## px: the lethal Charge this close to the entity starts slow-mo; measured 0.83-0.85 s real in the last episode (autopilot, stage 2, 3 seeds) ⚙ owner-approved 2026-11-18, SYS-001 §9
@export var slowmo_ramp_in_s: float = 0.15                ## s real: 1.0 -> slowmo_scale ⚙ owner-approved 2026-11-18, SYS-001 §9
@export var slowmo_ramp_out_s: float = 0.2                ## s real: back to 1.0 when the lethal condition clears ⚙ owner-approved 2026-11-18, SYS-001 §9
@export var slowmo_max_real_s: float = 2.5                ## s real: failsafe cap on one episode ⚙ owner-approved 2026-11-18, SYS-001 §9


func tunable_properties() -> PackedStringArray:
	var out := PackedStringArray()
	for p in get_property_list():
		if (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) and p.name != "ds_namespace" and p.name != "source_section":
			out.append(p.name)
	return out

# --- Starfield: rare distant streaks (draw-only; Starfield's own RNG) ---
@export var streak_interval_min_s: float = 6.0            ## s ✱ shortest wait between distant streaks
@export var streak_interval_max_s: float = 14.0           ## s ✱ longest wait
@export var streak_length_min_px: float = 10.0            ## px ✱
@export var streak_length_max_px: float = 18.0            ## px ✱
@export var streak_cross_s: float = 0.5                   ## s ✱ one streak crosses the view in this long (dim, 1 px)
