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
@onready var _camera: SectorCamera = %SectorCamera
@onready var _compass: LedgerCompass = %LedgerCompass

var vigil: Vigil

## Read-only scalars for the automation id `sector/vigil` (core/automation/ui_view.gd). Dev/QA reads.
var vigil_x: float:
	get: return vigil.global_position.x if is_instance_valid(vigil) else 0.0
var vigil_y: float:
	get: return vigil.global_position.y if is_instance_valid(vigil) else 0.0
var vigil_speed: float:
	get: return vigil.velocity.length() if is_instance_valid(vigil) else 0.0
var hull_max_hp: int:
	get: return vigil.get_hull_max_hp() if is_instance_valid(vigil) else 0
var camera_x: float:
	get: return _camera.global_position.x if _camera else 0.0
var compass_markers: int:
	get: return _compass.marker_points.size() if _compass else 0


func _ready() -> void:
	vigil = vigil_scene.instantiate() as Vigil
	vigil.position = _spawn.position
	_actors.add_child(vigil)
	# Shots belong to this sector, so they are torn down with it (not parked on Boot/current_scene).
	vigil.emitter.projectile_parent = _actors
	_camera.target = vigil
	_camera.snap_to_target()
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
