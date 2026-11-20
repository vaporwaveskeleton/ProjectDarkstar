class_name AudioMixStats
extends TunableResource
## Mix tunables for the ducking chain, the Aether Vigil's flight layers and the ambience threat stems
## (AUDIO-001 §7.2, §12.19; TECH-001 §2.7). Every value is an audio engineering ✱ value, mirrored in
## TECH-001 §2.7 and listed as proposed in SYS-001 §10 (ds_audio.mix.*). None is a gameplay number:
## the game supplies speed, thrust, turn and threat as 0..1 fractions of its own SYS-001 values.

# --- ducking (AUDIO-001 §7.2) ---------------------------------------------------------------------
## dB a sounding cue of priority P0..P5 takes off the buses AUDIO-001 §7.2 lists for it.
@export var duck_db_p0 := -6.0
@export var duck_db_p1 := -5.0
@export var duck_db_p2 := -5.0
@export var duck_db_p3 := -4.0
@export var duck_db_p4 := -3.0
## §7.2 gives no amount for P5 (mining ducks ambience): proposed.
@export var duck_db_p5 := -2.0
## Sidechain attack / release (s), §7.2: 60 ms and 400 ms.
@export var duck_attack_s := 0.06
@export var duck_release_s := 0.4

# --- flight layers (C11–C16) -----------------------------------------------------------------------
## A layer at or below this level is stopped.
@export var flight_floor_db := -40.0
## Engine: level at rest and at full speed, pitch_scale at rest and at full speed.
@export var engine_idle_db := -16.0
@export var engine_full_db := -5.0
@export var engine_pitch_min := 0.75
@export var engine_pitch_max := 1.3
## Boiler: level at full thrust (floor at none); pitch_scale lift at full thrust.
@export var boiler_full_db := -6.0
@export var boiler_pitch_lift := 0.15
## Rigging: level at full drift (speed with no thrust) or a full-rate turn.
@export var rigging_full_db := -6.0
## How much a turn (0..1 of snap_turn) adds to the rigging's drive.
@export var rigging_turn_weight := 0.6
## Lantern hiss: steady level, plus this much at full speed (air across the glass).
@export var lantern_db := -14.0
@export var lantern_speed_db := 3.0
## Layer smoothing time constants (s).
@export var flight_attack_s := 0.08
@export var flight_release_s := 0.35
## After a silence the ship returns over this time (AUDIO-001 §1.4 return rule, >= 0.6 s).
@export var flight_return_s := 0.8
## Creak fires when the turn fraction rises through `creak_turn_on`; it re-arms below `creak_turn_off`.
@export var creak_turn_on := 0.6
@export var creak_turn_off := 0.3
## Ballast fires when the brake engages at or above this speed fraction.
@export var ballast_min_speed := 0.25

# --- ambience threat stems ---------------------------------------------------------------------------
## The bed's level offset at full threat (threat adds layers, never level: the bed gives way).
@export var threat_bed_dip_db := -3.0
## Stem level relative to the bed's level.
@export var threat_stem_db := 0.0
## Seconds for threat to travel the full range up / down (stems enter slowly, leave slower).
@export var threat_rise_s := 4.0
## ✱
@export var threat_fall_s := 8.0
## Sector threat inputs (SectorSoundscape): per Composure band (frayed, unmoored, hollowed), per
## Grub carrying glass (capped), and the weight of the Sepulchre's completion.
@export var threat_frayed := 0.35
@export var threat_unmoored := 0.7
@export var threat_hollowed := 1.0
@export var threat_per_carrier := 0.2
@export var threat_carrier_cap := 0.6
@export var threat_sepulchre_weight := 0.9
## Seconds between threat pushes from the sector (a control rate, not per frame, AUDIO-001 §7.5).
@export var threat_poll_s := 0.25


func tunable_properties() -> PackedStringArray:
	return PackedStringArray([
		"duck_db_p0", "duck_db_p1", "duck_db_p2", "duck_db_p3", "duck_db_p4", "duck_db_p5",
		"duck_attack_s", "duck_release_s",
		"flight_floor_db", "engine_idle_db", "engine_full_db", "engine_pitch_min", "engine_pitch_max",
		"boiler_full_db", "boiler_pitch_lift", "rigging_full_db", "rigging_turn_weight", "lantern_db",
		"lantern_speed_db", "flight_attack_s", "flight_release_s", "flight_return_s",
		"creak_turn_on", "creak_turn_off", "ballast_min_speed",
		"threat_bed_dip_db", "threat_stem_db", "threat_rise_s", "threat_fall_s",
		"threat_frayed", "threat_unmoored", "threat_hollowed", "threat_per_carrier", "threat_carrier_cap",
		"threat_sepulchre_weight", "threat_poll_s"])


## Duck depth (dB, <= 0) of a cue at `priority` 0..5; 0 for anything else.
func duck_db(priority: int) -> float:
	match priority:
		0: return duck_db_p0
		1: return duck_db_p1
		2: return duck_db_p2
		3: return duck_db_p3
		4: return duck_db_p4
		5: return duck_db_p5
	return 0.0
