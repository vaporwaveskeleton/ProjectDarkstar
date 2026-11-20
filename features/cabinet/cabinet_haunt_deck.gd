class_name CabinetHauntDeck
extends RefCounted
## W0-12 Hauntings: which one, if any, happens at a moment (TECH-001 Q-T250–Q-T252). Pure and seeded: the
## same seed gives the same Hauntings at the same moments, so captures and tests can rely on it, while a
## new shift (a new seed) haunts differently and the player can never learn the pattern.
## Rules: at most one Haunting per moment; each kind at most once per deck (one scene visit); a moment
## only offers kinds that belong to it; photosensitivity / reduced motion remove the kinds that move or
## change light quickly (the figure, the litany, the ghost press), never the quiet ones.
## Dev only: `-- --haunt=<kind>` makes that kind happen at the first moment that offers it (captures).

const FIGURE := &"field_figure"         ## attract / demo: a standing figure in the field for one field
const STRANGER := &"roll_stranger"      ## attract honour roll: a row that is not yours, tied with your score
const GHOST_PRESS := &"ghost_press"     ## attract: the service button sinks by itself
const SOUR_JINGLE := &"sour_jingle"     ## attract: a tune from a machine with no attract tune, flat and one note short
const WARM_COIN := &"warm_coin"         ## coin: a second coin drops into the return cup, and the cup glows like an ember
const AFTER_IMAGE := &"after_image"     ## READY card: the tube holds an after-image of something never drawn
const BREATH := &"breath"               ## any: the cabinet hum breathes once
const LITANY := &"marquee_litany"       ## any: the marquee light dips in the litany's rhythm

const READY := &"ready"
const HOLD := &"hold"
const ATTRACT := &"attract"
const COIN := &"coin"
const DEMO := &"demo"

## The kinds each moment may offer, in a fixed order (the rng picks among the unused ones).
const MOMENT_KINDS := {
	&"ready": [&"after_image", &"breath", &"marquee_litany"],
	&"hold": [&"breath", &"marquee_litany"],
	&"attract": [&"roll_stranger", &"ghost_press", &"sour_jingle", &"breath", &"marquee_litany", &"field_figure"],
	&"coin": [&"warm_coin"],
	&"demo": [&"field_figure"],
}
## Kinds that move or change light quickly: never offered under photosensitivity or reduced motion.
const MOVING := [&"field_figure", &"marquee_litany", &"ghost_press"]
const AUTOPILOT_SEED := 1983           ## ✱ `--autopilot` runs (captures, scenarios) always tell the same story

var tuning: CabinetHauntTuning
var still := false
var forced := &""                        ## dev: the kind `--haunt=` asks for ("" = none)
var _rng := RandomNumberGenerator.new()
var _used: Dictionary = {}


func _init(p_tuning: CabinetHauntTuning = null, p_seed: int = 0, p_still: bool = false) -> void:
	tuning = p_tuning if p_tuning != null else (load("res://data/cabinet/cabinet_haunt.tres") as CabinetHauntTuning)
	_rng.seed = p_seed
	still = p_still


## A deck for a scene: seeded from the clock unless dev `--haunt-seed=N` fixes it; `--haunt=<kind>` forces one.
static func for_scene(p_still: bool) -> CabinetHauntDeck:
	var s := int(Time.get_ticks_usec()) ^ int(Time.get_unix_time_from_system())
	var force := &""
	if OS.get_cmdline_user_args().has("--autopilot"):
		s = AUTOPILOT_SEED              # captures and scenarios repeat
	if OS.is_debug_build():
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--haunt-seed="):
				s = int(a.trim_prefix("--haunt-seed="))
			elif a.begins_with("--haunt="):
				force = StringName(a.trim_prefix("--haunt="))
	var d := CabinetHauntDeck.new(null, s, p_still)
	d.forced = force
	return d


## The odds for a moment (SYS-001 ds_cabinet.haunt.chance_*).
func chance(moment: StringName) -> float:
	match moment:
		READY:
			return tuning.chance_ready
		HOLD:
			return tuning.chance_hold
		ATTRACT:
			return tuning.chance_attract
		COIN:
			return tuning.chance_coin
		DEMO:
			return tuning.chance_demo
	return 0.0


## The kinds `moment` may still offer (unused, allowed by the motion settings).
func offered(moment: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var kinds: Array = MOMENT_KINDS.get(moment, [])
	for k: StringName in kinds:
		if _used.has(k):
			continue
		if still and MOVING.has(k):
			continue
		out.append(k)
	return out


## Draw for `moment`: a kind, or &"" (nothing happens). Consumes rng in a fixed pattern (one roll, then one
## pick when it fires), so a seed always tells the same story.
func draw(moment: StringName) -> StringName:
	var kinds := offered(moment)
	if forced != &"" and kinds.has(forced):
		_used[forced] = true
		var f := forced
		forced = &""
		return f
	var roll := _rng.randf()
	if kinds.is_empty() or roll >= chance(moment):
		return &""
	var k := kinds[_rng.randi_range(0, kinds.size() - 1)]
	_used[k] = true
	return k


func used(kind: StringName) -> bool:
	return _used.has(kind)
