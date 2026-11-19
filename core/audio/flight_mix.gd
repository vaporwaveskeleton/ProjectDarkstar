class_name FlightMix
extends RefCounted
## Pure mapping from the Aether Vigil's motion to its four flight layers (AUDIO-001 §12.18, C11–C14).
## Inputs are fractions the game computes from its own SYS-001 values: speed / max_speed, thrust (the
## stick's push, 0 while braking), turn rate / snap_turn. Output: per layer id, Vector2(volume_db,
## pitch_scale). AudioService smooths and applies it; tests call it directly.
##   engine  — always on while flying: idle chuff at rest, faster and higher with speed;
##   boiler  — the firebox: opens with thrust only;
##   rigging — the current in the stays: drift (speed with no thrust) and hard turns;
##   lantern — the gas hiss: the ship's room tone, a little brighter with speed.

const ENGINE := &"flight_engine"
const BOILER := &"flight_boiler"
const RIGGING := &"flight_rigging"
const LANTERN := &"flight_lantern"
const LAYERS: Array[StringName] = [ENGINE, BOILER, RIGGING, LANTERN]


static func targets(speed01: float, thrust01: float, turn01: float, s: AudioMixStats) -> Dictionary:
	var sp := clampf(speed01, 0.0, 1.0)
	var th := clampf(thrust01, 0.0, 1.0)
	var tu := clampf(turn01, 0.0, 1.0)
	var drive := maxf(sp, th * 0.6)
	var drift := sp * (1.0 - th)
	var rig := clampf(drift + tu * s.rigging_turn_weight, 0.0, 1.0)
	return {
		ENGINE: Vector2(lerpf(s.engine_idle_db, s.engine_full_db, drive),
			lerpf(s.engine_pitch_min, s.engine_pitch_max, sp) + 0.05 * th),
		BOILER: Vector2(_fade(s.flight_floor_db, s.boiler_full_db, th), 1.0 + s.boiler_pitch_lift * th),
		RIGGING: Vector2(_fade(s.flight_floor_db, s.rigging_full_db, rig), 0.9 + 0.2 * sp + 0.06 * tu),
		LANTERN: Vector2(s.lantern_db + s.lantern_speed_db * sp, 1.0),
	}


## Equal-power style fade in dB: `floor` at k = 0, `full` at k = 1, following 20·log10(sin(k·π/2)).
static func _fade(floor_db: float, full_db: float, k: float) -> float:
	if k <= 0.0:
		return floor_db
	return maxf(floor_db, full_db + linear_to_db(sin(clampf(k, 0.0, 1.0) * PI * 0.5)))


## Threat 0..1 from the sector's state (SectorSoundscape): the strongest of the Composure band, the
## Grubs carrying glass, and the Sepulchre's completion. `band` is Composure.Band as an int.
static func sector_threat(band: int, carriers: int, sepulchre01: float, s: AudioMixStats) -> float:
	var by_band := 0.0
	match band:
		1: by_band = s.threat_frayed
		2: by_band = s.threat_unmoored
		3: by_band = s.threat_hollowed
	var by_grubs := minf(s.threat_carrier_cap, s.threat_per_carrier * maxi(carriers, 0))
	var by_sep := clampf(sepulchre01, 0.0, 1.0) * s.threat_sepulchre_weight
	return clampf(maxf(by_band, maxf(by_grubs, by_sep)), 0.0, 1.0)


## Linear gain 0..1 of threat stem `index` of `count`: each stem owns an equal slice of the threat range
## and enters smoothly across it, so stem 1 is full at 1/count and the last at 1.0.
static func stem_gain(threat01: float, index: int, count: int) -> float:
	if count <= 0:
		return 0.0
	var lo := float(index) / count
	var hi := float(index + 1) / count
	return smoothstep(lo, hi, clampf(threat01, 0.0, 1.0))
