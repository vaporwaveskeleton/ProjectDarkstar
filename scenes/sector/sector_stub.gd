extends Node2D
## SectorHost stub — owns one sector's lifetime (TECH-001 §2.1): spawn, run, tear down.
## Bootstrap scope: one empty wrapping arena, the Vigil, a hull readout and the pause flow.
## No kit assembly yet (SeamAssembler is future work).
## The run's back door (Q-T275..Q-T279): SeamExit opens the exit throat when the Sepulchre is unmade;
## flying into it reports the Seam (`take_exit`). A hull breach (`die`) and Abandon Run
## (`abandon_from_seam`) end the run; every run end routes to the Ruins, never the title.
## Q-T58: the M1 sandbox is a torus of 1,920 × 720 px (SYS-001 §9 sandbox row ✱; it was the Cabinet's field until
## SYS-001 §1.7 grew Act 0 to 65,536 px, so it is now its own `arena_size`); real kit bounds come from ZONES-001 later.

const PAUSE_SCENE := preload("res://scenes/sector/pause_screen.tscn")
const EXIT_STATS := preload("res://data/sector/seam_exit.tres")
## Race edge marker layout (`ds_hud.race_marks`, Q-T357).
const RACE_MARKS := preload("res://data/hud/race_edge_markers.tres")
## Where a run goes when it ends (Q-T152 (d), Q-T279): the hub, never the title.
const RUINS_ROUTE := &"ruins"
const SECTOR_ROUTE := &"sector"
## Route param the Ruins receives: the outcome the run ended with (`RunSessionCore.OUTCOME_*`).
const PARAM_RUN_OUTCOME := "run_outcome"

@export var vigil_scene: PackedScene
## How this Seam clears and is left (Q-T275, Q-T278).
@export var exit_stats: SeamExitStats = EXIT_STATS
## The sandbox torus size (SYS-001 §9 sandbox row ✱); no longer the Cabinet field (SYS-001 §1.7).
@export var arena_size: Vector2 = Vector2(1920, 720)
## Legacy link to a Cabinet stage; the arena size no longer comes from it.
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
## Frames the race (Charge, Grub, Sepulchre): a box-centre lean and a fitted pull-out (Q-T354, Q-T355).
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
## Warp T1 (TECH-001 §5.1a): the sector's single warp owner (W1-10 smudges the brass HUD's Vigil Index).
@onready var _warp: WarpComposer = %WarpComposer

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
## The sector bed and the Vigil's flight voice (AUDIO-001 §12.19), built in _start_sound.
var soundscape: SectorSoundscape
var flight_voice: VigilFlightVoice
## Brass chevrons on the frame for race parts off screen (Q-T357), built in _start_race_marks.
var race_marks: RaceEdgeMarkers
var _breached := false
## The Seam's clear rule and exit throat (built in _start_exit).
var seam_exit: SeamExit
## Who receives route requests (SceneRouter unless a test injects one): needs go_to(id, params).
var router: Object
## True once this sector has asked to leave (exit, death or abandon): one request per sector.
var left := false
## Seconds left before a breached hull returns to the Ruins (< 0 = none pending).
var _return_in := -1.0
## The outcome the pending return carries.
var _return_outcome: StringName = &""

## Read-only scalars for the automation id `sector/run` (exit). Dev/QA reads.
var seam_cleared: bool:
	get: return seam_exit.cleared if seam_exit else false
var exit_taken: bool:
	get: return seam_exit.entered if seam_exit else false
## Torus offset (px) from the Vigil to the open throat: steer by it in captures.
var throat_dx: float:
	get: return seam_exit.throat_offset().x if seam_exit else 0.0
var throat_dy: float:
	get: return seam_exit.throat_offset().y if seam_exit else 0.0

## Read-only scalars for the automation id `sector/run` (the golden path). Dev/QA reads.
var seam_index: int:
	get: return session.run().seam_index if session else 0
## True when a run was handed in through the route (RunSession), false on the throwaway core.
var run_session: bool:
	get: return not throwaway_session
## The far layer's look id (`ds_aether.<biome>_t<n>` namespace), "" without a far layer.
var far_look: String:
	get: return str(_far.look.ds_namespace) if _far and _far.look else ""

## Read-only scalars for the automation id `sector/warp` (TECH-001 §9.1). Dev/QA reads.
var warp_tier: int:
	get: return _warp.current_tier() if _warp else 0
var warp_live: int:
	get: return _warp.live_count() if _warp else 0
var warp_novel: int:
	get: return _warp.schedule.novel_used if _warp else 0
var warp_cost_ms: float:
	get: return _warp.live_cost_ms() if _warp else 0.0
var warp_smear: bool:
	get: return _warp.is_live(&"W1-09") if _warp else false
var warp_glyph: bool:
	get: return _hud.index_smudged() if _hud else false
var warp_frayed_edge: bool:
	get: return _warp.is_live(&"W1-06") if _warp else false
var warp_false_chant: bool:
	get: return _warp.is_live(&"W1-07") if _warp else false
var warp_teeth: int:
	get: return get_tree().get_nodes_in_group(LedgerCompass.GROUP).filter(
		func(n: Node) -> bool: return n.has_node(^"WarpTeeth")).size() if _warp else 0

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
## The camera zoom now (1 = Z1; below 1 only during a race pull-out, Q-T211 / Q-T355).
var camera_zoom: float:
	get: return _camera.zoom.x if _camera else 1.0
var race_points: int:
	get: return race_points_now().size()
## Race points on screen now (inside the 640×360 view around the camera): the race-framing check.
var race_on_screen: int:
	get: return _race_on_screen()
var compass_markers: int:
	get: return _compass.marker_points.size() if _compass else 0
## Race edge markers drawn now (Q-T357) and whether the race pull-out is on.
var race_markers: int:
	get: return race_marks.count() if race_marks else 0
var race_pulling: bool:
	get: return _framer.pulling if _framer else false
## Race parts neither on screen nor marked at the edge: the Reviewer's gap-6 check, 0 when the race
## reads (both ends on screen or signposted).
var race_unsignposted: int:
	get: return maxi(0, race_points - race_on_screen - race_markers)
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
var segments_knocked: int:
	get: return _procession.sepulchre.segments_knocked if _procession and is_instance_valid(_procession.sepulchre) else 0
var deposited_shards: int:
	get: return _procession.sepulchre.deposited_shards if _procession and is_instance_valid(_procession.sepulchre) else 0
var sepulchre_complete: bool:
	get: return _procession.sepulchre.is_complete() if _procession and is_instance_valid(_procession.sepulchre) else false


func _ready() -> void:
	torus = Torus.new(arena_size)
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
	_framer.charge_flying = func() -> bool: return _launcher != null and _launcher.in_flight() > 0
	vigil.cockpit_flame.composure = _composure
	_wick.composure = _composure
	vigil.health.damaged.connect(func(_a, _r): _refresh_hud())
	vigil.hull_breached.connect(_on_hull_breached)
	_overlays.emptied.connect(_on_overlays_emptied)
	_start_sound()
	_start_exit()
	_start_race_marks()
	if router == null:
		router = get_node_or_null(^"/root/SceneRouter")
	_use_session(_throwaway_session(), true)
	_start_far()
	_bind_warp()
	_refresh_hud()


## Route entry: a handed-in `session` replaces the throwaway core and seeds Composure and Charges.
func on_route_entered(params: Dictionary) -> void:
	for key: Variant in ["session", &"session"]:
		if params.has(key) and params[key] is RunSessionCore:
			_use_session(params[key] as RunSessionCore, false)
			_apply_bought_nodes()
			_bind_warp()
			return


## The sound of this sector (AUDIO-001 §12.19): the PM-01 bed with its threat stems, and the Vigil's
## flight voice (engine, boiler, rigging, lantern). Both are code-built children, so the scenes they
## read (vigil.tscn, this sector's tscn) stay untouched.
func _start_sound() -> void:
	soundscape = SectorSoundscape.new()
	soundscape.name = "SectorSoundscape"
	soundscape.composure = _composure
	soundscape.grubs = _grubs
	soundscape.sepulchre = _procession.sepulchre if _procession else null
	add_child(soundscape)
	flight_voice = VigilFlightVoice.new()
	flight_voice.name = "FlightVoice"
	flight_voice.vigil = vigil
	vigil.add_child(flight_voice)


## The Seam's clear rule and its exit throat (Q-T275, Q-T278). Added last, so its physics tick runs
## after SectorWrap's (the Vigil is on the canonical field when the pass is checked). Dev switches
## `--clear-knocks=N` / `--sepulchre-start=N` (captures) apply in dev builds only.
func _start_exit() -> void:
	seam_exit = SeamExit.new()
	seam_exit.name = "SeamExit"
	seam_exit.stats = exit_stats
	var sep: Sepulchre = _procession.sepulchre if _procession else null
	seam_exit.bind(torus, vigil, sep, _actors, bool(SettingsService.get_value(&"reduced_motion")))
	if LaunchRoute.is_dev_build():
		seam_exit.apply_dev_args(OS.get_cmdline_user_args())
	seam_exit.throat_entered.connect(take_exit)
	add_child(seam_exit)


## The Lantern Tree nodes bought in the Ruins shape the Vigil's Aether handling (Q-T191). A `--tree=`
## tester override (captures) wins; the throwaway core owns nothing, so it leaves the Vigil alone.
func _apply_bought_nodes() -> void:
	if throwaway_session or session == null or not is_instance_valid(vigil):
		return
	if not HandlingTree.parse_args(OS.get_cmdline_user_args()).is_empty():
		return
	var ids := PackedStringArray()
	for id in session.profile().tree_nodes:
		ids.append(String(id))
	vigil.set_tree_nodes(ids)


## New sector for the far layer: its field, then the camera's first centre becomes the origin.
func _start_far() -> void:
	_far_last = _camera.global_position
	far_centre = _far_last
	_far.set_field(torus.size)
	_far.set_camera(far_centre, _camera.zoom.x)
	# TODO(M1 lantern API, TECH-001 §2.9): call _far.set_lantern(vigil.lantern_world_pos(),
	# vigil.lantern_radius, vigil.lantern_lit) each frame once the Vigil exposes them.


func _process(delta: float) -> void:
	_step_far()
	_step_race_marks()
	_refresh_hud()
	if _return_in >= 0.0:
		_return_in -= delta
		if _return_in < 0.0:
			_return_to_ruins(_return_outcome)


## Warp at Seam entry (WARP-001 §1.3): the composer reads the session's drives and builds the tier's set.
func _bind_warp() -> void:
	if _warp:
		_warp.bind(session, _composure, _far, _compass, _hud, _camera, torus, vigil)


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
	for item: Array in race_items_now():
		out.append(item[0] as Vector2)
	return out


## The race with kinds: [world position, RaceEdgeMarkers kind] per part, Charges first, the Sepulchre
## last (only while a Charge flies or a Grub carries).
func race_items_now() -> Array:
	var out: Array = []
	if _launcher:
		for c in _launcher.flying:
			if is_instance_valid(c):
				out.append([c.global_position, RaceEdgeMarkers.KIND_CHARGE])
	if _grubs:
		for g in _grubs.grubs:
			if is_instance_valid(g) and g.carrying and not g.dead:
				out.append([g.global_position, RaceEdgeMarkers.KIND_GRUB])
	if not out.is_empty() and _procession and is_instance_valid(_procession.sepulchre):
		out.append([_procession.sepulchre.global_position, RaceEdgeMarkers.KIND_SEPULCHRE])
	return out


## The race edge markers (Q-T357) on the HUD canvas layer, above the brass plates.
func _start_race_marks() -> void:
	race_marks = RaceEdgeMarkers.new()
	race_marks.name = "RaceEdgeMarkers"
	race_marks.stats = RACE_MARKS
	_hud.get_parent().add_child(race_marks)


## Pushes the true screen offsets of the race to the edge markers each frame (honest by construction:
## world truth, no HudModel, no lie seam; Q-T357).
func _step_race_marks() -> void:
	if race_marks == null or torus == null or _camera == null:
		return
	var centre := _camera.get_screen_center_position()
	var z := _camera.zoom.x
	var offsets := PackedVector2Array()
	var kinds: Array[StringName] = []
	for item: Array in race_items_now():
		offsets.append(torus.delta(centre, item[0] as Vector2) * z)
		kinds.append(item[1] as StringName)
	race_marks.show_race(offsets, kinds, get_viewport_rect().size)


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
## `end_seam` only (no route); the exit throat goes through `take_exit`.
func clear_seam() -> bool:
	return session.end_seam(seam_report())


## The SeamReport of this Seam now: Composure, Charges, and Ember = floor(score / divisor) (SYS-001 §7.1).
func seam_report() -> SeamReport:
	var report := SeamReport.new()
	_composure.report_into(report)
	_magazine.report_into(report)
	var per_ember := maxi(1, session.stats.score_per_ember) if session and session.stats else 1
	report.ember_earned = floori(float(score) / float(per_ember))
	return report


## The Vigil passed the open throat (Q-T278): report the Seam and route on. At the slice frontier
## (Q-T276) the run ends `returned` and the hub follows; otherwise the next Seam is entered (a fifth
## clear wins and returns to the hub). The throwaway core (dev route) reports in memory and stays.
func take_exit() -> bool:
	if left or session == null:
		return false
	var frontier := session.at_frontier()
	if not session.return_from_frontier(seam_report()):
		return false
	if is_instance_valid(vigil):
		vigil.motor.enabled = false
	if throwaway_session:
		return true
	if session.run().is_active():
		left = true
		return bool(router.call("go_to", SECTOR_ROUTE, session.enter_seam())) if router else false
	return _return_to_ruins(RunSessionCore.OUTCOME_RETURNED if frontier else RunSessionCore.OUTCOME_WON)


## The run is over: back to the Ruins (Q-T279), where `arrive_at_ruins` writes `ruins_entry`.
## The throwaway core (dev route, M1 sandboxes) never leaves for the hub.
func _return_to_ruins(outcome: StringName) -> bool:
	_return_in = -1.0
	if left or throwaway_session or router == null:
		return false
	left = true
	get_tree().paused = false
	return bool(router.call("go_to", RUINS_ROUTE, {PARAM_RUN_OUTCOME: String(outcome)}))


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


## Abandon Run (Q-T277, Q-T279): the session prices it as a death and banks the run's Ember, then the
## Ruins. The throwaway core (dev route) has no run to abandon and leaves for the title as before.
func _on_abandon_requested() -> void:
	get_tree().paused = false
	if throwaway_session:
		if router:
			router.call("go_to", &"attract")
		return
	if _return_in >= 0.0:   # already breached: the death stands, only the wait is cut short
		_return_to_ruins(_return_outcome)
		return
	if session and not left:
		session.abandon_from_seam()
	_return_to_ruins(RunSessionCore.OUTCOME_ABANDONED)


## Pushes the honest values into the brass HUD (it redraws only on a change).
func _refresh_hud() -> void:
	if _hud == null or not is_instance_valid(vigil):
		return
	var seams := session.stats.seams_per_run if session and session.stats else 0
	var tier := _far.look.tier if _far and _far.look else 0
	_hud.set_values(score, charges, _magazine.capacity() if _magazine else 0, seam_index, seams, tier,
		vigil.health.current_hp, vigil.get_hull_max_hp(), _breached)
	var m := vigil.motor
	if m.aether_active:
		_hud.set_handling(m.surge_charges_left, m.aether_stats.surge_charges, vigil.lantern.is_up)
	else:
		_hud.set_handling(0, 0, true)
	if session and session.stats and session.stats.iteration_budget_loop_min > 0.0:
		_hud.set_hourglass(session.loop_min_left() / session.stats.iteration_budget_loop_min,
			session.hourglass_visible())


func _on_hull_breached() -> void:
	_breached = true
	_refresh_hud()
	if session and not left:
		session.die()   # §4.2a: on death the sector calls session.die(); the core saves at run_end
	# Q-T279: the breach plays, then the hub (D-08 stays data: whatever hull HP breaches, this follows).
	if not throwaway_session and not left and _return_in < 0.0:
		_return_outcome = RunSessionCore.OUTCOME_DIED
		_return_in = maxf(0.0, exit_stats.return_hold_s if exit_stats else 0.0)
