class_name CabinetFxTuning
extends TunableResource
## Act 0 — the Cabinet: presentation numbers for bursts, rings and shake, one field per event.
## All ✱ engineering presentation params (TECH-001); SYS-001 §9 holds only the shake caps
## (4.0 px / 0.25 s), which stay literal 🔒 constants in ArcadeWorld.shake().

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
@export var ritual_lance_burst_count: int = 3             ## ✱ the lance does not bite
@export var ritual_lance_burst_speed: float = 30.0        ## px/s ✱
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


func tunable_properties() -> PackedStringArray:
	var out := PackedStringArray()
	for p in get_property_list():
		if (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) and p.name != "ds_namespace" and p.name != "source_section":
			out.append(p.name)
	return out
