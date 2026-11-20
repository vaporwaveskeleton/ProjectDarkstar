class_name UserVolume
extends RefCounted
## The player's volume sliders (AUDIO-001 §8.4): which setting key drives which bus(es), the floor
## each may not go below, the preview cue, and the slider-to-dB curve. Static data only; the values
## live in SettingsService and the buses are set by AudioService (TECH-001 §2.7).

## ✱ Slider step for the settings row (percent per key press).
const STEP := 5
const MAX := 100
## ✱ Slider-to-gain curve: amplitude = (value / 100) ^ CURVE_EXPONENT, so 100 is unity, 70 is
## about -6 dB, 50 is -12 dB, and 0 is muted. Squared amplitude tracks loudness far better than
## a straight line, which crams all the change into the bottom of the slider.
const CURVE_EXPONENT := 2.0
const SILENT_DB := -80.0

## In row order, as AUDIO-001 §8.4 lists them. `buses` are the AUDIO-001 §2.0 bus names the slider
## drives ("Master" is BUS-MST, Godot's bus 0). `floor` is the lowest value the player can set
## (0 = the slider can mute). `preview` is an existing cue that plays on the slider's own bus when
## it changes; &"" = none (Music has no cue yet, and the Entity cues are protected set pieces).
const SLIDERS: Array[Dictionary] = [
	{"row": &"VolMaster", "key": &"vol_master", "buses": [&"Master"], "floor": 0, "preview": &"menu_accept"},
	{"row": &"VolMusic", "key": &"vol_music", "buses": [&"BUS-MUS"], "floor": 0, "preview": &""},
	{"row": &"VolChoir", "key": &"vol_choir", "buses": [&"BUS-CHO"], "floor": 0, "preview": &"grub_keen"},
	{"row": &"VolEntity", "key": &"vol_entity", "buses": [&"BUS-ENT"], "floor": 40, "preview": &""},
	{"row": &"VolUi", "key": &"vol_ui", "buses": [&"BUS-UI"], "floor": 0, "preview": &"menu_move"},
	{"row": &"VolFoley", "key": &"vol_foley", "buses": [&"BUS-AMB", &"BUS-FLY"], "floor": 40, "preview": &"shard_chime"},
]


## Linear amplitude gain for slider `value` (0 = silent).
static func gain(value: int) -> float:
	return pow(clampf(float(value) / MAX, 0.0, 1.0), CURVE_EXPONENT)


## Bus offset in dB for slider `value`; SILENT_DB at 0.
static func to_db(value: int) -> float:
	if value <= 0:
		return SILENT_DB
	return maxf(linear_to_db(gain(value)), SILENT_DB)


## The slider entry for setting `key`, or {}.
static func entry_for_key(key: StringName) -> Dictionary:
	for e in SLIDERS:
		if e["key"] == key:
			return e
	return {}


static func floor_for(key: StringName) -> int:
	return int(entry_for_key(key).get("floor", 0))


## `value` held inside 0..100 and above the slider's floor.
static func clamp_value(key: StringName, value: int) -> int:
	return clampi(value, floor_for(key), MAX)
