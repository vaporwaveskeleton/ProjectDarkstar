extends Node2D
## SectorHost stub — owns one sector's lifetime (TECH-001 §2.1): spawn, run, tear down.
## Bootstrap scope: one empty wrapping arena, the Vigil, a hull readout and the pause flow.
## No kit assembly yet (SeamAssembler is future work).
## Q-T58: the M1 sandbox is a torus the size of the Cabinet's field. The size has ONE source, the
## Cabinet stage's `field_size` (`arena_source`); real kit bounds come from ZONES-001 later.

const PAUSE_SCENE := preload("res://scenes/sector/pause_screen.tscn")

@export var vigil_scene: PackedScene
## Where the arena size comes from: the Cabinet stage resource (its `field_size`, 1920×720 ✱).
@export var arena_source: CabinetStage
## Stats for the throwaway run core built when no `session` route param is handed in (§4.2a).
@export var session_stats: RunSessionStats

@onready var _spawn: Marker2D = %VigilSpawn
@onready var _actors: Node2D = %Actors
## The Aether-tier brass HUD (TECH-001 §5.4): Vigil Index, Charge strip, Seam index, Steady Ledger, hull line.
@onready var _hud: BrassHud = %BrassHud
## Near depth (Q-T163 resolved): fog wisps and glass motes behind and in front of the play layer.
@onready var _depth_back: SectorDepth = %DepthBack
@onready var _depth_front: SectorDepth = %DepthFront
## Leans the camera toward the race (Charge, Grub, Sepulchre) without zoom (Q-T25 Z1).
@onready var _framer: RaceFramer = %RaceFramer
@onready var _overlays: ScreenStack = %Overlays
@onready var _camera: SectorCamera = %SectorCamera
@onready var _compass: LedgerCompass = %LedgerCompass
@onready var _wrap: SectorWrap = %SectorWrap
@onready var _geodes: GeodeSandbox = %GeodeSandbox
@onready var _shards: ShardField = %ShardField
@onready var _magazine: ChargeMagazine = %ChargeMagazine
@onready var _launcher: ChargeLauncher = %ChargeLauncher
@onready var _procession: ProcessionSandbox = %ProcessionSandbox
@onready var _grubs: GrubProcession = %GrubProcession
## Sector-scoped for M1 (Q-T118); moves to RunSession when that is built (TECH-001 §2.8).
@onready var _composure: Composure = %Composure
@onready var _wick: ComposureWick = %ComposureWick
## The Aether behind the play layer (TECH-001 §2.9; look PM-01 Pale Marches T1, M2 slice beat 12).
@onready var _far: AetherFarLayer = %AetherFarLayer

var vigil: Vigil
## The sector's wrap-around space. Features that need positions or distances on this sector take it
## from here (injected; never built twice): SectorWrap, SectorCamera, ShardField, GeodeSandbox,
## LedgerCompass, ProcessionSandbox (Sepulchre + Grubs), ChargeLauncher.
var torus: Torus
## The run this sector plays a Seam of (TECH-001 §4.2a). Route param `session`; absent (dev
## `--route=sector`, M1 sandboxes, tests) = a throwaway core with the dev seed and no saver, so
## nothing is ever saved. Sector code reaches the run only through this reference.
var session: RunSessionCore
## True when `session` is the throwaway core (no session was handed in).
var throwaway_session := true
## The clock-pause reason this sector holds on `session` while the pause menu is open.
var _menu_paused := false
## The camera centre with every torus rebase accumulated (Q-T127 option B): continuous across the seam.
var far_centre := Vector2.ZERO
var _far_last := Vector2.ZERO
var _breached := false

## Read-only scalars for the automation id `sector/run` (the golden path). Dev/QA reads.
var seam_index: int:
	get: return session.run().seam_index if session else 0
## True when a run was handed in through the route (RunSession), false on the throwaway core.
var run_session: bool:
	get: return not throwaway_session
## The far layer's look id (`ds_aether.<biome>_t<n>` namespace), "" without a far layer.
var far_look: String:
	get: return str(_far.look.ds_namespace) if _far and _far.look else ""

## Read-only scalars for the automation id `sector/vigil` (core/automation/ui_view.gd). Dev/QA reads.
var vigil_x: float:
	get: return vigil.global_position.x if is_instance_valid(vigil) else 0.0
var vigil_y: float:
	get: return vigil.global_position.y if is_instance_valid(vigil) else 0.0
var vigil_speed: float:
	get: return vigil.velocity.length() if is_instance_valid(vigil) else 0.0
var hull_max_hp: int:
	get: return vigil.get_hull_max_hp() if is_instance_valid(vigil) else 0
## The Facing node's rotation in degrees, wrapped to (-180, 180]; 0 = right, 90 = down (y-down).
var facing_deg: float:
	get: return rad_to_deg(wrapf(vigil.motor.facing_node.rotation, -PI, PI)) \
		if is_instance_valid(vigil) and vigil.motor.facing_node else 0.0
## The aim the Vigil's input resolves this frame (unit vector, or zero when there is none).
var aim_x: float:
	get: return vigil.input.aim_dir(vigil.global_position).x if is_instance_valid(vigil) else 0.0
var aim_y: float:
	get: return vigil.input.aim_dir(vigil.global_position).y if is_instance_valid(vigil) else 0.0
var camera_x: float:
	get: return _camera.global_position.x if _camera else 0.0
## The race framing lean now (world px, length) and how many race points are in play.
var race_lean: float:
	get: return _framer.lean.length() if _framer else 0.0
## The camera zoom now (1 = Z1; below 1 only during a Q-T211 pull-out).
var camera_zoom: float:
	get: return _camera.zoom.x if _camera else 1.0
var race_points: int:
	get: return race_points_now().size()
## Race points on screen now (inside the 640×360 view around the camera): the race-framing check.
var race_on_screen: int:
	get: return _race_on_screen()
var compass_markers: int:
	get: return _compass.marker_points.size() if _compass else 0
## Shortest (torus) distance from the camera to the Vigil; stays small through the seam.
var camera_gap: float:
	get: return torus.distance(_camera.global_position, vigil.global_position) \
		if torus and _camera and is_instance_valid(vigil) else 0.0
## Composure 0–10 and its band name (clear / frayed / unmoored / hollowed), SYS-001 §1.5.
var composure: float:
	get: return _composure.value if _composure else 0.0
var composure_band: String:
	get: return _composure.band_name() if _composure else ""

## Read-only scalars for the automation id `sector/field` (glass economy). Dev/QA reads.
var geodes_alive: int:
	get: return _geodes.alive_count() if _geodes else 0
var geodes_detonated: int:
	get: return _geodes.detonated_count() if _geodes else 0
var shards_free: int:
	get: return _shards.free_count() if _shards else 0
## Shards lying in the world, claimed by a Grub or not (`shards_free` counts unclaimed ones only).
var shards_live: int:
	get: return _shards.live_count() if _shards else 0
var charges: int:
	get: return _magazine.count if _magazine else 0
## Shards + Grubs killed + Sepulchre segments knocked off (SYS-001 §7.1).
var score: int:
	get: return (_shards.score if _shards else 0) + (_grubs.score if _grubs else 0) \
		+ (_procession.sepulchre.score if _procession and is_instance_valid(_procession.sepulchre) else 0)
var charges_in_flight: int:
	get: return _launcher.in_flight() if _launcher else 0
## Charges destroyed by an interceptor (Grub or geode); guttered ones are not counted here.
var charges_lost: int:
	get: return _launcher.lost() if _launcher else 0
var charges_hit: int:
	get: return _launcher.hits() if _launcher else 0
var charges_guttered: int:
	get: return _launcher.guttered() if _launcher else 0
var dry_fires: int:
	get: return _launcher.dry_fires if _launcher else 0

## Read-only scalars for the automation id `sector/choir` (Grubs and the Sepulchre). Dev/QA reads.
var grubs_alive: int:
	get: return _grubs.alive_count() if _grubs else 0
var grubs_carrying: int:
	get: return _grubs.carrying_count() if _grubs else 0
var segments: int:
	get: return _procession.sepulchre.segments if _procession and is_instance_valid(_procession.sepulchre) else 0
var deposited_shards: int:
	get: return _procession.sepulchre.deposited_shards if _procession and is_instance_valid(_procession.sepulchre) else 0
var sepulchre_complete: bool:
	get: return _procession.sepulchre.is_complete() if _procession and is_instance_valid(_procession.sepulchre) else false


func _ready() -> void:
	torus = Torus.new(arena_source.field_size)
	_compass.world_rect = Rect2(Vector2.ZERO, torus.size)
	vigil = vigil_scene.instantiate() as Vigil
	vigil.position = _spawn.position
	_actors.add_child(vigil)
	# Shots belong to this sector, so they are torn down with it (not parked on Boot/current_scene).
	vigil.emitter.projectile_parent = _actors
	_wrap.torus = torus
	_wrap.anchor = vigil
	_camera.torus = torus
	_camera.target = vigil
	_camera.snap_to_target()
	_shards.setup(torus)
	_shards.collector = vigil
	_shards.collector_radius_px = vigil.motor.stats.hitbox_circle_px * 0.5
	_geodes.populate(torus, _spawn.position, vigil)
	_compass.torus = torus
	_procession.populate(torus, _actors, vigil)
	_launcher.torus = torus
	_launcher.vigil = vigil
	_launcher.projectile_parent = _actors
	_launcher.target = _procession.sepulchre.hurtbox
	_launcher.composure = _composure
	_framer.anchor = vigil
	_framer.points = race_points_now
	_framer.pull_target = race_pull_target
	vigil.cockpit_flame.composure = _composure
	_wick.composure = _composure
	vigil.health.damaged.connect(func(_a, _r): _refresh_hud())
	vigil.hull_breached.connect(_on_hull_breached)
	_overlays.emptied.connect(_on_overlays_emptied)
	_use_session(_throwaway_session(), true)
	_start_far()
	_refresh_hud()


## Route entry: a handed-in `session` replaces the throwaway core and seeds Composure and Charges.
func on_route_entered(params: Dictionary) -> void:
	for key: Variant in ["session", &"session"]:
		if params.has(key) and params[key] is RunSessionCore:
			_use_session(params[key] as RunSessionCore, false)
			return


## New sector for the far layer: its field, then the camera's first centre becomes the origin.
func _start_far() -> void:
	_far_last = _camera.global_position
	far_centre = _far_last
	_far.set_field(torus.size)
	_far.set_camera(far_centre, _camera.zoom.x)
	# TODO(M1 lantern API, TECH-001 §2.9): call _far.set_lantern(vigil.lantern_world_pos(),
	# vigil.lantern_radius, vigil.lantern_lit) each frame once the Vigil exposes them.


func _process(_delta: float) -> void:
	_step_far()
	_refresh_hud()


## Accumulate the camera's travel through torus rebases (the shortest step each frame), so the far
## layer sees one continuous centre (AetherFarLayer.set_camera).
func _step_far() -> void:
	if _far == null or torus == null:
		return
	var now := _camera.global_position
	far_centre += torus.delta(_far_last, now)
	_far_last = now
	_far.set_camera(far_centre, _camera.zoom.x)
	_depth_back.set_camera(far_centre)
	_depth_front.set_camera(far_centre)


## The race this frame (world px): every Charge in flight, every Grub carrying glass, and the
## Sepulchre while either is happening (the moments the camera must show, Reviewer rank 6).
func race_points_now() -> PackedVector2Array:
	var out := PackedVector2Array()
	if _launcher:
		for c in _launcher.flying:
			if is_instance_valid(c):
				out.append(c.global_position)
	if _grubs:
		for g in _grubs.grubs:
			if is_instance_valid(g) and g.carrying and not g.dead:
				out.append(g.global_position)
	if not out.is_empty() and _procession and is_instance_valid(_procession.sepulchre):
		out.append(_procession.sepulchre.global_position)
	return out


## The Sepulchre while it is a race target (Q-T211 pull-out), else empty.
func race_pull_target() -> PackedVector2Array:
	var pts := race_points_now()
	return PackedVector2Array([pts[pts.size() - 1]]) if pts.size() >= 2 else PackedVector2Array()


func _race_on_screen() -> int:
	if torus == null or _camera == null:
		return 0
	var half := _camera.visible_size() * 0.5
	var centre := _camera.get_screen_center_position()
	var n := 0
	for p in race_points_now():
		var d := torus.delta(centre, p)
		if absf(d.x) <= half.x and absf(d.y) <= half.y:
			n += 1
	return n


func _throwaway_session() -> RunSessionCore:
	var core := RunSessionCore.new(session_stats, null)
	core.start_run(session_stats.dev_seed if session_stats else 0)
	core.enter_seam()
	return core


func _use_session(s: RunSessionCore, throwaway: bool) -> void:
	_release_menu_pause()
	session = s
	throwaway_session = throwaway
	_composure.load_from(session.run())
	_magazine.load_from(session.run())
	_refresh_hud()


## Seam clear (TECH-001 §4.2a): the only write-back, a SeamReport built from the live nodes.
## The M1 sandbox has no exit yet, so nothing in the sector calls this; tests and tools do.
func clear_seam() -> bool:
	var report := SeamReport.new()
	_composure.report_into(report)
	_magazine.report_into(report)
	var per_ember := maxi(1, session.stats.score_per_ember) if session and session.stats else 1
	report.ember_earned = floori(float(score) / float(per_ember))
	return session.end_seam(report)


func _exit_tree() -> void:
	_release_menu_pause()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not event.is_echo() and _overlays.is_empty():
		get_viewport().set_input_as_handled()
		open_pause()


func open_pause() -> Screen:
	get_tree().paused = true
	if session and not _menu_paused:
		session.pause_clock(RunSessionCore.PAUSE_MENU)   # Q-T138: the pause menu stops the clock
		_menu_paused = true
	var pause := PAUSE_SCENE.instantiate()
	pause.abandon_requested.connect(_on_abandon_requested)
	return _overlays.push(pause)


func _on_overlays_emptied() -> void:
	get_tree().paused = false
	_release_menu_pause()


func _release_menu_pause() -> void:
	if _menu_paused and session:
		session.resume_clock(RunSessionCore.PAUSE_MENU)
	_menu_paused = false


func _on_abandon_requested() -> void:
	get_tree().paused = false
	SceneRouter.go_to(&"attract")


## Pushes the honest values into the brass HUD (it redraws only on a change).
func _refresh_hud() -> void:
	if _hud == null or not is_instance_valid(vigil):
		return
	var seams := session.stats.seams_per_run if session and session.stats else 0
	var tier := _far.look.tier if _far and _far.look else 0
	_hud.set_values(score, charges, _magazine.capacity() if _magazine else 0, seam_index, seams, tier,
		vigil.health.current_hp, vigil.get_hull_max_hp(), _breached)
	if session and session.stats and session.stats.iteration_budget_loop_min > 0.0:
		_hud.set_hourglass(session.loop_min_left() / session.stats.iteration_budget_loop_min,
			session.hourglass_visible())


func _on_hull_breached() -> void:
	_breached = true
	_refresh_hud()
	if session:
		session.die()   # §4.2a: on death the sector calls session.die(); the core saves at run_end
