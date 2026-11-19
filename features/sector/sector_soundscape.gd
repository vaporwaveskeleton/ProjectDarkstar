class_name SectorSoundscape
extends Node
## The sector's bed (AUDIO-001 §2.3, §12.18): on entry, the biome bed with its threat stems; every
## `mix.threat_poll_s` the threat (FlightMix.sector_threat: the Composure band, Grubs carrying glass,
## the Sepulchre's completion) is pushed to AudioService.set_threat, so the bed escalates by adding
## layers (Deep, then Wrong), never level (§1.1). On exit the slot fades out, unless another scene has
## already claimed it. PM-01 "First Vigil" (Pale Marches T1) is the default.

@export var bed: StringName = &"aether_bed_t1"
@export var stems: Array[StringName] = [&"pm01_threat_1", &"pm01_threat_2"]
@export var mix: AudioMixStats = preload("res://data/audio/mix_stats.tres")
## Threat sources (the sector injects them; any may be null).
var composure: Composure
var grubs: GrubProcession
var sepulchre: Sepulchre
## Who receives the bed and threat (AudioService unless a test injects a spy).
var sink: Object
## Last pushed threat (tests, diagnostics).
var threat := 0.0

var _poll := 0.0


func _ready() -> void:
	if sink == null:
		sink = get_node_or_null(^"/root/AudioService")
	_call(&"set_ambience", [bed, 1.0, stems])
	_call(&"set_threat", [0.0])


func _exit_tree() -> void:
	_call(&"set_threat", [0.0])
	if sink != null and is_instance_valid(sink) and sink.has_method(&"ambience_id") \
			and StringName(sink.call(&"ambience_id")) == bed:
		_call(&"set_ambience", [&""])


func _process(delta: float) -> void:
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = mix.threat_poll_s
	threat = current_threat()
	_call(&"set_threat", [threat])


## The sector's threat 0..1 now.
func current_threat() -> float:
	var band := -1
	if composure != null and composure.stats != null:
		band = int(Composure.band_for(composure.value, composure.stats))
	var carriers := grubs.carrying_count() if grubs != null else 0
	var sep := 0.0
	if sepulchre != null and is_instance_valid(sepulchre) and sepulchre.stats != null and sepulchre.stats.segments_total > 0:
		sep = float(sepulchre.segments) / sepulchre.stats.segments_total
	return FlightMix.sector_threat(band, carriers, sep, mix)


func _call(method: StringName, args: Array) -> void:
	if sink != null and is_instance_valid(sink) and sink.has_method(method):
		sink.callv(method, args)
