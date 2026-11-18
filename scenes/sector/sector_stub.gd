extends Node2D
## SectorHost stub — owns one sector's lifetime (TECH-001 §2.1): spawn, run, tear down.
## Bootstrap scope: one empty arena, the Vigil, a hull readout and the pause flow.
## No kit assembly yet (SeamAssembler is future work).

const PAUSE_SCENE := preload("res://scenes/sector/pause_screen.tscn")

@export var vigil_scene: PackedScene

@onready var _spawn: Marker2D = %VigilSpawn
@onready var _actors: Node2D = %Actors
@onready var _hull_label: Label = %HullLabel
@onready var _overlays: ScreenStack = %Overlays

var vigil: Vigil


func _ready() -> void:
	vigil = vigil_scene.instantiate() as Vigil
	vigil.position = _spawn.position
	_actors.add_child(vigil)
	vigil.health.damaged.connect(func(_a, _r): _refresh_hud())
	vigil.hull_breached.connect(_on_hull_breached)
	_overlays.emptied.connect(_on_overlays_emptied)
	_refresh_hud()


func _exit_tree() -> void:
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not event.is_echo() and _overlays.is_empty():
		get_viewport().set_input_as_handled()
		open_pause()


func open_pause() -> Screen:
	get_tree().paused = true
	var pause := PAUSE_SCENE.instantiate()
	pause.abandon_requested.connect(_on_abandon_requested)
	return _overlays.push(pause)


func _on_overlays_emptied() -> void:
	get_tree().paused = false


func _on_abandon_requested() -> void:
	get_tree().paused = false
	SceneRouter.go_to(&"attract")


func _refresh_hud() -> void:
	_hull_label.text = LocFormat.tr_count("HUD_HULL_COUNT", vigil.health.current_hp)


func _on_hull_breached() -> void:
	_hull_label.text = tr("HUD_HULL_BREACHED")
