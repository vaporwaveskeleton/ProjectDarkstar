class_name AetherBackdrop
extends Node2D
## The Aether world backdrop (ART-001 §15–§16): a lit sea of coloured fog inside a glass sky, with
## far set pieces, life, and the entity's presence. Back to front: far fog (stars), the far halves of the
## armillary rings, crystal sphere (orrery shells) + cracks + smudge, set pieces + orrery ribs, mid fog,
## the Presence (leviathan), mid fog, god-rays, life, near fog, veil fog, entity, grade.
## Every layer can be switched off to measure its cost. A quality rung (AetherQuality, CH-7)
## trades octaves, resolution and particle counts; every rung keeps the sphere curve, the entity's
## exact black and the play-band fog cap. Owns no game state; callers drive it with
## apply_look / apply_quality / set_tier / set_drain / set_time / set_camera / set_lantern.

signal sphere_glinted
signal leviathan_entered
signal leviathan_closest

const LAYERS: Array[StringName] = [&"far_fog", &"sky", &"cracks", &"smudge", &"set_pieces", &"orrery", &"mid_fog",
	&"leviathan", &"shafts", &"life", &"near_fog", &"entity", &"grade"]
## ✱ every full-coverage layer rect: oversized so camera drift and parallax never show an edge.
const COVER := Rect2(-240.0, -200.0, 1120.0, 760.0)
## ✱ the main entity's anchor in its layer (top right, so its extent runs off the frame) and its
## radius at full drain.
const ENTITY_ANCHOR := Vector2(585.0, 30.0)
const ENTITY_MAX_RADIUS := 215.0
## ✱ T5: pieces of torn edges entering from the frame borders (layer position, radius).
const HOLES: Array[Vector3] = [Vector3(-40.0, 150.0, 120.0), Vector3(700.0, 345.0, 150.0), Vector3(285.0, -78.0, 96.0)]
## ✱ edge-fracture growth of the T5 edges (the main entity's grows with drain).
const HOLE_GROWTH := 0.55
## ✱ seconds per full turn of the shared life current (the field turns as one).
const CURRENT_TURN_S := 40.0
## ✱ the T2 school: loop centre/size in life-layer px, loop period, scatter window (s) and the empty patch.
const SCHOOL_LOOP := Rect2(-150.0, -70.0, 300.0, 130.0)
const SCHOOL_PERIOD_S := 22.0
const SCATTER_WINDOW := Vector2(6.0, 10.0)
const SCATTER_PATCH := Vector2(40.0, -10.0)
const DEFAULT_QUALITY := "res://data/aether/quality/quality_high.tres"

## Freezes drift and halves parallax (accessibility). Read from SettingsService when present.
@export var reduced_motion: bool = false

var look: AetherLook
var quality: AetherQuality
var tier: int = 1
var drain: float = 0.0
var time_s: float = 0.0
var camera_centre := Vector2(320.0, 180.0)
var camera_zoom := 1.0
var lantern_screen := Vector2(320.0, 200.0)
var lantern_radius := 120.0
var lantern_colour := Pal.GAS_4
var lantern_energy := 1.6
var _enabled: Dictionary = {}
var _mats: Array[ShaderMaterial] = []

@onready var _far_layer: Parallax2D = %FarLayer
@onready var _sky_layer: Parallax2D = %SkyLayer
@onready var _rib_layer: Parallax2D = %RibLayer
@onready var _rib_back_layer: Parallax2D = %RibBackLayer
@onready var _mid_a_layer: Parallax2D = %MidLayerA
@onready var _lev_layer: Parallax2D = %LeviathanLayer
@onready var _mid_b_layer: Parallax2D = %MidLayerB
@onready var _life_layer: Parallax2D = %LifeLayer
@onready var _near_layer: Parallax2D = %NearLayer
@onready var _veil_layer: Parallax2D = %VeilLayer
@onready var _entity_layer: Parallax2D = %EntityLayer
@onready var _bands: Array[AetherFogBand] = [%FarFog, %MidFogA, %MidFogB, %NearFog, %VeilFog]
@onready var _sphere: CrystalSphere = %Sphere
@onready var _cracks: AetherShaderRect = %Cracks
@onready var _cracks_copy: BackBufferCopy = %CracksCopy
@onready var _smudge: StillSmudge = %Smudge
@onready var _set_pieces: FarSetPieces = %SetPieces
@onready var _set_pieces_back: FarSetPieces = %SetPiecesBack
@onready var _ribs: OrreryRibs = %Ribs
@onready var _far_life: Node2D = %FarLife
@onready var _leviathan: AetherLeviathan = %Leviathan
@onready var _shafts: AetherShaderRect = %Shafts
@onready var _grade: AetherShaderRect = %Grade
@onready var _grade_copy: BackBufferCopy = %GradeCopy
@onready var _entity: EntityPresence = %Entity
@onready var _holes: Array[EntityPresence] = [%Hole1, %Hole2, %Hole3]
@onready var _life: Array[AetherLife] = [%Motes, %Jellies, %Spores, %School, %VastJellies]


func _ready() -> void:
	for l in LAYERS:
		_enabled[l] = true
	if SettingsService.DEFAULTS.has(&"reduced_motion"):
		reduced_motion = bool(SettingsService.get_value(&"reduced_motion"))
	if quality == null:
		quality = load(DEFAULT_QUALITY) as AetherQuality
	for band in _bands:
		_cover(band)
	_cover(_sphere)
	_cover(_cracks)
	_entity.centre = ENTITY_ANCHOR
	for i in _holes.size():
		_holes[i].centre = Vector2(HOLES[i].x, HOLES[i].y)
	_sphere.sphere_glinted.connect(sphere_glinted.emit)
	_leviathan.leviathan_entered.connect(leviathan_entered.emit)
	_leviathan.leviathan_closest.connect(leviathan_closest.emit)
	_collect_materials()
	if look != null:
		apply_look(look)


func _cover(r: Control) -> void:
	r.position = COVER.position
	r.size = COVER.size


func _collect_materials() -> void:
	_mats.clear()
	var rects: Array[AetherShaderRect] = []
	rects.append_array(_bands)
	rects.append_array([_sphere, _cracks, _leviathan, _shafts, _grade])
	for r in rects:
		_mats.append(r.ensure_material())


## Switch quality rung (high / medium / low). Re-applies the look.
func apply_quality(q: AetherQuality) -> void:
	if q == null:
		return
	quality = q
	if not is_node_ready():
		return
	for band in _bands:
		var mid := band == _bands[1] or band == _bands[2]
		band.set_offscreen_scale(minf(q.mid_fog_resolution_scale, q.fog_resolution_scale) if mid else q.fog_resolution_scale)
	_shafts.set_offscreen_scale(q.shaft_resolution_scale)
	for e: EntityPresence in [_entity] + _holes:
		e.set_edge_octaves(q.entity_edge_octaves)
	if look != null:
		apply_look(look)


## Configure every layer from a look. Also sets the tier from the look.
func apply_look(new_look: AetherLook) -> void:
	look = new_look
	if not is_node_ready() or look == null:
		return
	tier = look.tier
	var q := quality
	var band_count := mini(look.fog_band_count, q.max_fog_bands)
	for i in _bands.size():
		_bands[i].configure(look, q)
		_bands[i].set_drawn(i < band_count and _layer_on_for_band(i))
	_sphere.set_param(&"glass_col", look.sphere_glass)
	_sphere.set_param(&"seam_col", Pal.PHOS_5)
	_sphere.set_param(&"crack_col", Pal.BONE_4)
	_sphere.set_param(&"brass_col", look.brass)
	_sphere.set_param(&"brass_hi", Pal.BONE_4)
	_sphere.set_param(&"brass_shadow", Pal.VOID_3)
	_sphere.set_param(&"floor_col", Pal.VOID_0)
	_sphere.set_param(&"refraction_px", look.refraction_strength if (look.refraction and q.sphere_refraction == 1) else 0.0)
	_sphere.set_param(&"shells", q.nested_shells)
	_sphere.set_param(&"wrong_strength", look.wrong_seam_strength)
	_sphere.set_param(&"crack_amount", look.sphere_crack)
	_sphere.set_param(&"numerals", 1 if look.meridian_numerals else 0)
	_cracks.set_param(&"edge_col", look.crack_edge)
	_cracks.set_param(&"seam_col", Pal.PHOS_5)
	_cracks.set_param(&"behind_a", look.behind_a)
	_cracks.set_param(&"behind_b", look.behind_b)
	_cracks.set_param(&"behind_star", Pal.BONE_4)
	_cracks.set_param(&"floor_col", Pal.VOID_0)
	_cracks.set_param(&"amount", look.crack_amount)
	_cracks.set_param(&"sphere_c", _sphere.sphere_centre - COVER.position)
	_cracks.set_param(&"sphere_r", _sphere.sphere_radius)
	_shafts.set_param(&"ray_col", look.shaft_tint)
	_shafts.set_param(&"intensity", look.shaft_intensity)
	_shafts.set_param(&"octaves", 4 if q.animated_shafts == 1 else 2)
	_grade.set_param(&"floor_col", Pal.VOID_0)
	_grade.set_param(&"chalk_col", Pal.BONE_2)
	_grade.set_param(&"void_lo", Pal.VOID_1)
	_grade.set_param(&"void_hi", Pal.VOID_4)
	_grade.set_param(&"subtraction", look.subtraction_amount if look.subtraction else 0.0)
	_leviathan.configure(look)
	_leviathan.set_param(&"edge_octaves", 3 if q.fog_octave_drop == 0 else 2)
	_ribs.configure(look)
	_smudge.configure(look)
	_set_pieces.configure(look)
	_set_pieces_back.configure(look)
	var counts: Array[int] = [look.mote_count if look.motes else 0, look.jelly_count if look.jellies else 0,
		look.spore_count if look.spores else 0, look.school_count if look.school else 0,
		look.vast_jelly_count if look.jellies else 0]
	for i in _life.size():
		_life[i].configure(look, counts[i], q.particle_scale)
	_apply_parallax()
	set_drain(look.base_drain)


## Tier on its own (the look normally sets it). Drives the tier-specific shader paths.
func set_tier(new_tier: int) -> void:
	tier = clampi(new_tier, 1, 5)
	for m in _mats:
		m.set_shader_parameter(&"tier", tier)


## 0 = the world untouched … 1 = the entity has drunk it. Grows the main entity and its fractures,
## gives the world its cold cast, stops life. Never drains below VOID_0.
func set_drain(amount: float) -> void:
	drain = clampf(amount, 0.0, 1.0)
	if not is_node_ready():
		return
	var base := look.base_drain if look != null else 0.0
	var growth := clampf((drain - base) / maxf(1.0 - base, 0.001), 0.0, 1.0)
	_entity.radius = ENTITY_MAX_RADIUS * smoothstep(0.0, 1.0, growth)
	_entity.set_growth(smoothstep(0.1, 1.0, growth))
	for i in _holes.size():
		_holes[i].radius = HOLES[i].z if (look != null and look.black_holes) else 0.0
		_holes[i].set_growth(HOLE_GROWTH)
	_refresh_visibility()


func set_time(seconds: float) -> void:
	time_s = seconds


func set_camera(centre: Vector2, zoom: float) -> void:
	camera_centre = centre
	camera_zoom = zoom


## Lantern position on screen (logical px), its light radius, colour and energy: the fog pools
## its warm light analytically and the grade spares this pool.
func set_lantern(screen_pos: Vector2, radius: float, colour: Color = Pal.GAS_4, energy: float = 1.6) -> void:
	lantern_screen = screen_pos
	lantern_radius = radius
	lantern_colour = colour
	lantern_energy = energy


func set_layer_enabled(layer: StringName, on: bool) -> void:
	_enabled[layer] = on
	if look != null:
		apply_look(look)


func is_layer_enabled(layer: StringName) -> bool:
	return bool(_enabled.get(layer, false))


## Layers currently drawing something (for the cost log).
func active_layers() -> PackedStringArray:
	var out := PackedStringArray()
	if look == null:
		return out
	for l in LAYERS:
		if _layer_active(l):
			out.append(String(l))
	return out


## Offscreen viewports currently rendering (their GPU time is not in the world viewport's).
func offscreen_rids() -> Array[RID]:
	var out: Array[RID] = []
	var rects: Array[AetherShaderRect] = []
	rects.append_array(_bands)
	rects.append(_shafts)
	for r in rects:
		var rid := r.offscreen_rid()
		if rid.is_valid():
			out.append(rid)
	return out


func _any_entity() -> bool:
	return _entity.radius > 0.5 or (look != null and look.black_holes)


func _layer_active(l: StringName) -> bool:
	if not is_layer_enabled(l):
		return false
	match l:
		&"far_fog", &"sky":
			return true
		&"grade":
			return look.subtraction or drain > 0.001 or _any_entity()
		&"cracks":
			return look.sky_cracks
		&"smudge":
			return look.still_smudge
		&"set_pieces":
			return quality.set_pieces == 1 and _set_pieces.any_shown()
		&"orrery":
			return look.orrery
		&"mid_fog":
			return mini(look.fog_band_count, quality.max_fog_bands) > 1
		&"near_fog":
			return mini(look.fog_band_count, quality.max_fog_bands) > 3
		&"leviathan":
			return look.leviathan
		&"shafts":
			return look.god_rays
		&"life":
			return look.life
		&"entity":
			return _any_entity()
	return false


func _layer_on_for_band(i: int) -> bool:
	if i == 0:
		return is_layer_enabled(&"far_fog")
	return is_layer_enabled(&"mid_fog") if i < 3 else is_layer_enabled(&"near_fog")


func _refresh_visibility() -> void:
	if look == null:
		return
	_sphere.visible = _layer_active(&"sky")
	_cracks.visible = _layer_active(&"cracks")
	_cracks_copy.visible = _cracks.visible
	_smudge.visible = _layer_active(&"smudge")
	_set_pieces.visible = _layer_active(&"set_pieces")
	_set_pieces_back.visible = _set_pieces.visible and _set_pieces_back.any_shown()
	_ribs.visible = _layer_active(&"orrery")
	_leviathan.visible = _layer_active(&"leviathan")
	_shafts.set_drawn(_layer_active(&"shafts"))
	_grade.visible = _layer_active(&"grade")
	_grade_copy.visible = _grade.visible
	_life_layer.visible = _layer_active(&"life")
	_far_life.visible = _life_layer.visible
	_entity_layer.visible = is_layer_enabled(&"entity")


func _apply_parallax() -> void:
	var layers: Array[Parallax2D] = [_far_layer, _mid_a_layer, _mid_b_layer, _near_layer, _veil_layer]
	for i in layers.size():
		_set_scroll(layers[i], look.band_scroll(i))
	_set_scroll(_sky_layer, look.band_scroll(0) * 1.5)
	_set_scroll(_rib_layer, look.band_scroll(0) * 2.5)
	_set_scroll(_rib_back_layer, look.band_scroll(0) * 2.5)
	_set_scroll(_lev_layer, (look.band_scroll(1) + look.band_scroll(2)) * 0.5)
	_set_scroll(_life_layer, look.band_scroll(2) * 1.7)
	_set_scroll(_entity_layer, look.band_scroll(1) * 1.6)


func _set_scroll(layer: Parallax2D, s: float) -> void:
	# reduced motion halves the parallax: the layer moves halfway toward moving with the camera
	var k := s if not reduced_motion else s + (1.0 - s) * 0.5
	layer.scroll_scale = Vector2(k, k)


func _process(_delta: float) -> void:
	refresh()


## Upload the current time, camera, screen-size, drain and lantern state to every layer now, without
## advancing time. _process calls it each frame; a caller that sets state outside _process (e.g. a
## route entered by a deferred call, after this frame's _process) calls it so the first drawn frame
## is already correct.
func refresh() -> void:
	if look == null or not is_node_ready():
		return
	var t := 0.0 if reduced_motion else time_s
	var screen := get_viewport_rect().size
	var masks: Array[Vector4] = [_entity.screen_mask(), _holes[0].screen_mask(), _holes[1].screen_mask(), _holes[2].screen_mask()]
	var seeds := Vector4(_entity.seed, _holes[0].seed, _holes[1].seed, _holes[2].seed)
	var cam_off := camera_centre - screen * 0.5
	var sph_xf := _sphere.get_global_transform_with_canvas()
	var sph := sph_xf * (_sphere.sphere_centre - _sphere.position)
	var sphere_screen := Vector3(sph.x, sph.y, _sphere.sphere_radius)
	for m in _mats:
		m.set_shader_parameter(&"time_s", t)
		m.set_shader_parameter(&"drain", drain)
		m.set_shader_parameter(&"screen_size", screen)
		m.set_shader_parameter(&"entity_0", masks[0])
		m.set_shader_parameter(&"entity_1", masks[1])
		m.set_shader_parameter(&"entity_2", masks[2])
		m.set_shader_parameter(&"entity_3", masks[3])
		m.set_shader_parameter(&"entity_seeds", seeds)
		m.set_shader_parameter(&"entity_time", time_s)
		m.set_shader_parameter(&"sphere_screen", sphere_screen)
	for band in _bands:
		band.set_param(&"lantern_px", lantern_screen)
		band.set_param(&"lantern_r", lantern_radius)
		band.set_param(&"lantern_col", lantern_colour)
		band.set_param(&"lantern_outer", Pal.GAS_3)
		band.set_param(&"lantern_energy", lantern_energy if look.lantern_light else 0.0)
	_sphere.set_param(&"camera_offset", cam_off)
	_sphere.update_glint(time_s, camera_centre - _sky_layer.position)
	_cracks.set_param(&"camera_offset", cam_off)
	_cracks.set_param(&"lantern_px", lantern_screen)
	_grade.set_param(&"lantern_px", lantern_screen)
	_grade.set_param(&"lantern_r", lantern_radius)
	_grade.size = screen
	_shafts.size = screen
	_shafts.set_param(&"source_px", Vector2(screen.x * 0.66, -screen.y * 0.35))
	if quality.animated_shafts == 0:
		_shafts.set_param(&"time_s", 0.0)
	_leviathan.screen_width = screen.x
	_leviathan.advance(time_s, drain)
	var lev_on := _leviathan.visible
	_shafts.set_param(&"lev_presence", _leviathan.presence() if lev_on else 0.0)
	_shafts.set_param(&"lev_origin", _leviathan.screen_origin())
	_shafts.set_param(&"lev_quad", _leviathan.quad_size)
	_shafts.set_param(&"lev_thick", _leviathan.thickness)
	_shafts.set_param(&"lev_time", t)
	_entity.set_time(time_s)
	for h in _holes:
		h.set_time(time_s)
	_ribs.set_time(t)
	_set_pieces.set_time(t)
	_set_pieces_back.set_time(t)
	_update_life(t, masks[0])
	var px := get_viewport().get_visible_rect().size
	var vp := get_viewport()
	var px_size := Vector2i(px)
	if vp is SubViewport:
		px_size = (vp as SubViewport).size
	for band in _bands:
		band.sync_offscreen(px_size, screen)
	_shafts.sync_offscreen(px_size, screen)


func _update_life(t: float, mask: Vector4) -> void:
	var heading := TAU * fposmod(t / CURRENT_TURN_S, 1.0)
	var fade := 1.0 - smoothstep(0.15, 0.85, drain - (look.base_drain if look != null else 0.0))
	for life in _life:
		if not life.visible:
			continue
		var flee_local := Vector2(9999.0, 9999.0)
		var flee_r := 0.0
		if mask.w > 0.5:
			flee_local = life.get_global_transform_with_canvas().affine_inverse() * Vector2(mask.x, mask.y)
			flee_r = mask.z
		life.update_motion(t, fade, heading, flee_local, flee_r)
		if life.kind == AetherLife.Kind.SCHOOL:
			var cyc := fposmod(t, SCHOOL_PERIOD_S)
			var scatter := smoothstep(SCATTER_WINDOW.x, SCATTER_WINDOW.x + 0.6, cyc) * (1.0 - smoothstep(SCATTER_WINDOW.y - 1.5, SCATTER_WINDOW.y, cyc))
			# the empty patch: where the school was heading when it broke
			var patch := _school_centre(t - cyc + SCATTER_WINDOW.x) + SCATTER_PATCH
			life.update_school(_school_centre(t), _school_heading(t), scatter, patch)


func _school_centre(t: float) -> Vector2:
	var ph := TAU * t / SCHOOL_PERIOD_S
	return SCHOOL_LOOP.get_center() + Vector2(cos(ph), sin(ph * 2.0) * 0.5) * SCHOOL_LOOP.size * 0.5


func _school_heading(t: float) -> float:
	var ph := TAU * t / SCHOOL_PERIOD_S
	return Vector2(-sin(ph), cos(ph * 2.0) * 2.0 * 0.5).angle()


## Cost sweep helper: every layer on except `layer` ("" = all on), applied once.
func set_only_layer_off(layer: StringName) -> void:
	for l in LAYERS:
		_enabled[l] = l != layer
	if look != null:
		apply_look(look)
