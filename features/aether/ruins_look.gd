class_name RuinsLook
extends Node
## The LOOK of the Ruins of the Ninth Sky on the first visit (NARR-001 §5.7, GDD §6.4, ART-001 §16):
## a cramped, half-ruined cathedral-observatory hall lit by one warm hall lantern, deep VOID
## shadows, brass and glass and chalk, and the Aether felt OUTSIDE, through the hangar mouth and the
## torn vault, veiled so it reads far. The hangar mouth stays dark until a Lantern Tree lamp is lit.
## Look only: owns no game state, no input, no save, no text. M1's Ruins scene instances it (an
## exported reference), sets the markers to its layout, and forwards the Tree's lit nodes here.
##
## API for the Ruins scene:
##   light_lamp(pos, instant = false)  a lamp at `pos` (logical px) catches: a slow warm bloom, no
##                                     flash; its light reaches the hangar mouth. Repeatable; a second
##                                     call at the same place is ignored. `instant` for lamps already
##                                     lit on an earlier visit.
##   set_first_visit(on)               on: the cold open (no title card; the hall lantern catches over
##                                     entry_catch_s ✱ after entry_delay_s ✱, then holds). off: the hall
##                                     lantern is lit from the first frame.
##   stage                             a Node2D inside the lit hall: visual props put here are lit by
##                                     the hall's lights (input does not reach it; keep interaction
##                                     in the Ruins scene's own nodes).
##   hangar_mouth_rect, hall_lantern_pos, chalk_desk_pos, cabinet_pos, codex_desk_pos,
##   hourglass_pos, floor_y            exported layout markers (logical px, 640×360 frame).
##   mouth_light()                     0 (dark) … 1: how much lamp light reaches the hangar mouth.
##                                     Before any lamp the mouth is near-black (veil `mouth_veil_dark`
##                                     ✱ over VOID-1); `mouth_aether_hint` ✱ lets a dim Aether glimpse
##                                     back in (Q-T156).
## Visual-only prop mirrors (Q-T158, agreed with M1): M1 keeps its Area2D/focus logic in its own
## nodes and puts a lit visual copy of each prop here. No input reaches these.
##   add_prop(id, node, pos)           put `node` under `stage` at `pos` (same space as light_lamp);
##                                     an existing prop with that id is freed first.
##   set_prop_state(id, state)         &"idle", &"focused" (a gentle chalk lift), &"used" (dimmed);
##                                     eases at most max_step_per_frame ✱ per 60 Hz frame, no motion.
##   has_prop(id), prop_state(id), prop_node(id), remove_prop(id)
##   set_sand(fraction, falling)       the stand-in Hourglass's sand (the Ruins mirrors RunSession).

## ✱ at most this many lamps feed the haze (every lamp still lights the hall).
const MAX_HAZE_LAMPS := 8
## ✱ two lamps closer than this (px) are the same lamp.
const SAME_LAMP_PX := 1.0
## ✱ the torn vault: centre and radii (logical px).
const HOLE_C := Vector2(150.0, 10.0)
const HOLE_R := Vector2(122.0, 70.0)
## ✱ the Aether's camera: the frame centre (no Camera2D in the view: identity canvas transform).
const OUTSIDE_CAMERA := Vector2(320.0, 180.0)
## ✱ the Aether's lantern parked far off-frame (the lantern is indoors).
const OUTSIDE_NO_LANTERN := Vector2(320.0, 2000.0)
## The states a prop mirror shows.
const PROP_IDLE := &"idle"
const PROP_FOCUSED := &"focused"
const PROP_USED := &"used"
const PROP_STATES: Array[StringName] = [PROP_IDLE, PROP_FOCUSED, PROP_USED]

@export var data: RuinsLookData = preload("res://data/aether/ruins/ruins_look.tres")
## Gallery-only stand-ins for the objects M1 owns (desk, Cabinet, Codex desk, Hourglass, Tree).
@export var show_placeholders: bool = false:
	set(v):
		show_placeholders = v
		if is_node_ready():
			_placeholders.visible = v
@export var hangar_mouth_rect := Rect2(484.0, 116.0, 132.0, 186.0):
	set(v):
		hangar_mouth_rect = v
		_layout()
@export var floor_y: float = 300.0:
	set(v):
		floor_y = v
		_layout()
@export var hall_lantern_pos := Vector2(266.0, 128.0):
	set(v):
		hall_lantern_pos = v
		_layout()
@export var chalk_desk_pos := Vector2(204.0, 300.0):
	set(v):
		chalk_desk_pos = v
		_layout()
@export var cabinet_pos := Vector2(74.0, 214.0):
	set(v):
		cabinet_pos = v
		_layout()
@export var codex_desk_pos := Vector2(300.0, 300.0):
	set(v):
		codex_desk_pos = v
		_layout()
@export var hourglass_pos := Vector2(438.0, 300.0):
	set(v):
		hourglass_pos = v
		_layout()
## Where the gallery's placeholder Tree stands (M1 owns the real Tree and its node positions).
@export var placeholder_tree_pos := Vector2(392.0, 300.0):
	set(v):
		placeholder_tree_pos = v
		_layout()

var first_visit: bool = false
var time_s: float = 0.0
var _entry_wait: float = 0.0
var _lamps: Array[RuinsLamp] = []
## id → RuinsLook.Prop (the mirrors in `stage`).
var _props: Dictionary = {}
## Props added before the look was ready: [id, node, pos], attached in _ready.
var _pending_props: Array = []


## One visual prop mirror: its node, its own modulate, its state and its eased tint.
class Prop:
	var node: Node2D
	var base: Color
	var state: StringName = &"idle"
	var tint: Color = Color.WHITE

@onready var view: AetherView = %View
@onready var backdrop: AetherBackdrop = %Backdrop
@onready var stage: Node2D = %Stage
@onready var hall_lantern: RuinsLamp = %HallLantern
@onready var _ambient: CanvasModulate = %Ambient
@onready var _hall: CanvasLayer = %Hall
@onready var _surface: ColorRect = %Surface
@onready var _set: RuinsSet = %Set
@onready var _foreground: RuinsForeground = %Foreground
@onready var _placeholders: RuinsPlaceholders = %Placeholders
@onready var _lamp_root: Node2D = %Lamps
@onready var _haze: ColorRect = %Haze
@onready var _mouth_light: PointLight2D = %MouthLight
@onready var _hourglass_light: PointLight2D = %HourglassLight
@onready var _cabinet_light: PointLight2D = %CabinetLight
@onready var _floor_pool: PointLight2D = %FloorPool


func _ready() -> void:
	var tex := RuinsLamp.radial_texture()
	for l: PointLight2D in [_mouth_light, _hourglass_light, _cabinet_light, _floor_pool]:
		l.texture = tex
		l.blend_mode = Light2D.BLEND_MODE_ADD
		l.shadow_enabled = false
		l.range_layer_min = _hall.layer
		l.range_layer_max = _hall.layer
	_ambient.color = data.ambient
	hall_lantern.configure(data.lantern_colour, data.lantern_energy, data.lantern_radius, data.lantern_core_hdr,
		data.entry_catch_s, data.breath_hz, data.breath_depth)
	_set.configure(data)
	_foreground.configure(data)
	_placeholders.configure(data)
	_placeholders.visible = show_placeholders
	_surface_params()
	if data.outside_look != null:
		view.apply_glow(data.outside_look)
		backdrop.apply_look(data.outside_look)
	_layout()
	set_first_visit(first_visit)
	for p: Array in _pending_props:
		add_prop(p[0] as StringName, p[1] as Node2D, p[2] as Vector2)
	_pending_props.clear()
	_sync()


## The cold open (on) or a later visit (off). Safe before or after the node is ready.
func set_first_visit(on: bool) -> void:
	first_visit = on
	if not is_node_ready():
		return
	if on:
		hall_lantern.snuff()
		_entry_wait = data.entry_delay_s
	else:
		_entry_wait = 0.0
		hall_lantern.light_now()
	_sync()


## A Lantern Tree lamp at `pos` (RuinsLook-local logical px) catches; its light reaches the mouth.
func light_lamp(pos: Vector2, instant: bool = false) -> void:
	for l in _lamps:
		if l.position.distance_to(pos) < SAME_LAMP_PX:
			return
	var lamp := RuinsLamp.new()
	lamp.name = "Lamp%d" % _lamps.size()
	lamp.position = pos
	_lamp_root.add_child(lamp)
	lamp.configure(data.lamp_colour, data.lamp_energy, data.lamp_radius, data.lamp_core_hdr, data.lamp_catch_s,
		data.breath_hz, data.breath_depth)
	_lamps.append(lamp)
	if instant:
		lamp.light_now()
	else:
		lamp.catch_light()
	_sync()


func lamp_count() -> int:
	return _lamps.size()


func lamps() -> Array[RuinsLamp]:
	return _lamps


## How much lamp light reaches the hangar mouth: 0 dark … 1. Each lamp takes `mouth_share` ✱ of
## the darkness that is left, by its catch level, so it only ever rises as lamps catch.
func mouth_light() -> float:
	var dark := 1.0
	for l in _lamps:
		dark *= 1.0 - data.mouth_share * l.level
	return 1.0 - dark


## The hangar mouth's veil alpha now: near-black before any lamp (lifted only by
## `mouth_aether_hint` ✱), the dim glimpse once the first lamp has caught, then clearing toward
## `mouth_veil_lit` as more lamps catch. Only ever falls as lamps catch.
func mouth_veil() -> float:
	var m := mouth_light()
	var pre := lerpf(data.mouth_veil_dark, data.mouth_veil_glimpse, clampf(data.mouth_aether_hint, 0.0, 1.0))
	var first := clampf(m / maxf(data.mouth_share, 0.001), 0.0, 1.0)
	return lerpf(lerpf(pre, data.mouth_veil_glimpse, first), data.mouth_veil_lit, m)


## Put the visual prop `node` under the lit `stage` at `pos` (RuinsLook-local logical px). A prop
## already under `id` is freed first. Visual only: input never reaches `stage`.
func add_prop(id: StringName, node: Node2D, pos: Vector2) -> void:
	if node == null:
		push_warning("RuinsLook.add_prop: no node for prop '%s'" % id)
		return
	if not is_node_ready():
		_pending_props.append([id, node, pos])
		return
	var old: Prop = _props.get(id) as Prop
	if old != null and old.node != node:
		remove_prop(id)
	var p := Prop.new()
	if old != null and old.node == node:
		p = old
	else:
		p.node = node
		p.base = node.modulate
	if node.get_parent() != stage:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		stage.add_child(node)
	node.position = pos
	_props[id] = p
	_apply_prop(p)


## Show prop `id` as &"idle", &"focused" or &"used"; an unknown state or id is ignored (warning).
func set_prop_state(id: StringName, state: StringName) -> void:
	if state not in PROP_STATES:
		push_warning("RuinsLook.set_prop_state: unknown state '%s'" % state)
		return
	var p: Prop = _props.get(id) as Prop
	if p == null:
		push_warning("RuinsLook.set_prop_state: no prop '%s'" % id)
		return
	p.state = state


func has_prop(id: StringName) -> bool:
	return _props.has(id)


## The prop's state, or &"" when there is no prop `id`.
func prop_state(id: StringName) -> StringName:
	var p: Prop = _props.get(id) as Prop
	return p.state if p != null else &""


func prop_node(id: StringName) -> Node2D:
	var p: Prop = _props.get(id) as Prop
	return p.node if p != null else null


## Take prop `id` out of `stage` and free it.
func remove_prop(id: StringName) -> void:
	var p: Prop = _props.get(id) as Prop
	if p == null:
		return
	_props.erase(id)
	if is_instance_valid(p.node):
		if p.node.get_parent() != null:
			p.node.get_parent().remove_child(p.node)
		p.node.queue_free()


## The tint a prop eases toward in its state: focused lifts toward chalk, used dims.
func prop_target_tint(state: StringName) -> Color:
	match state:
		PROP_FOCUSED:
			var t := Color.WHITE.lerp(data.prop_focus_tint, 0.5) * (1.0 + data.prop_focus_lift)
			t.a = 1.0
			return t
		PROP_USED:
			var d := 1.0 - data.prop_used_dim
			return Color(d, d, d, 1.0)
	return Color.WHITE


func _step_props(delta: float) -> void:
	# never a flash: each channel moves at most max_step_per_frame per 60 Hz frame
	var most := data.max_step_per_frame * delta * 60.0
	for k: Variant in _props.keys():
		var p: Prop = _props[k] as Prop
		if not is_instance_valid(p.node):
			_props.erase(k)
			continue
		var want := prop_target_tint(p.state)
		p.tint = Color(move_toward(p.tint.r, want.r, most), move_toward(p.tint.g, want.g, most),
			move_toward(p.tint.b, want.b, most), 1.0)
		_apply_prop(p)


func _apply_prop(p: Prop) -> void:
	p.node.modulate = Color(p.base.r * p.tint.r, p.base.g * p.tint.g, p.base.b * p.tint.b, p.base.a)


## The stand-in Hourglass's sand above the neck (0…1) and whether it is falling (the Ruins scene
## mirrors RunSession here; the look owns no clock).
func set_sand(fraction: float, falling: bool) -> void:
	_placeholders.sand = fraction
	_placeholders.sand_falling = falling


## Where the placeholder Tree hangs its lamps (gallery use).
func placeholder_lamp_positions() -> PackedVector2Array:
	return _placeholders.lamp_positions()


## Forward a quality rung to the Aether outside.
func set_quality(q: AetherQuality) -> void:
	backdrop.apply_quality(q)
	view.environment().glow_enabled = q.glow == 1


func _process(delta: float) -> void:
	step(delta)


## Advance the look by `delta` seconds (the tests step it frame by frame).
func step(delta: float) -> void:
	time_s += delta
	if first_visit and _entry_wait > 0.0:
		_entry_wait -= delta
		if _entry_wait <= 0.0:
			hall_lantern.catch_light()
	hall_lantern.step(delta)
	for l in _lamps:
		l.step(delta)
	_step_props(delta)
	_sync()


func _logical_size() -> Vector2:
	var vp := view.world
	if vp.size_2d_override != Vector2i.ZERO:
		return Vector2(vp.size_2d_override)
	return Vector2(640.0, 360.0)


func _layout() -> void:
	if not is_node_ready():
		return
	hall_lantern.position = hall_lantern_pos
	hall_lantern.chain_px = maxf(hall_lantern_pos.y - 10.0, 0.0)
	_set.set_layout(hangar_mouth_rect, floor_y, HOLE_C, HOLE_R)
	_set.orrery_at = Vector2(lerpf(hall_lantern_pos.x, hangar_mouth_rect.position.x, 0.5), 92.0)
	_placeholders.set_markers(chalk_desk_pos, cabinet_pos, codex_desk_pos, hourglass_pos, placeholder_tree_pos)
	_mouth_light.position = Vector2(hangar_mouth_rect.get_center().x, floor_y - 14.0)
	_hourglass_light.position = hourglass_pos + Vector2(0.0, -18.0)
	_cabinet_light.position = cabinet_pos + Vector2(0.0, -10.0)
	_floor_pool.position = Vector2(hall_lantern_pos.x, floor_y + 8.0)
	_floor_pool.scale = Vector2(1.0, data.floor_pool_squash)
	_surface_params()


func _surface_params() -> void:
	var s := _surface.material as ShaderMaterial
	s.set_shader_parameter(&"stone_a", data.stone_a)
	s.set_shader_parameter(&"stone_b", data.stone_b)
	s.set_shader_parameter(&"mortar", data.mortar)
	s.set_shader_parameter(&"floor_a", data.floor_a)
	s.set_shader_parameter(&"floor_b", data.floor_b)
	s.set_shader_parameter(&"veil_col", data.veil)
	s.set_shader_parameter(&"hole_veil", data.hole_veil)
	s.set_shader_parameter(&"mouth", _rect_vec(hangar_mouth_rect))
	s.set_shader_parameter(&"floor_y", floor_y)
	s.set_shader_parameter(&"hole_c", HOLE_C)
	s.set_shader_parameter(&"hole_r", HOLE_R)
	var xs := _set.pilaster_xs()
	s.set_shader_parameter(&"bays", Vector4(xs[0] + 12.0, xs[1] - 12.0, xs[1] + 12.0, xs[2] - 12.0))
	var h := _haze.material as ShaderMaterial
	h.set_shader_parameter(&"warm", data.lamp_colour)
	h.set_shader_parameter(&"warm_hi", data.lantern_colour)
	h.set_shader_parameter(&"spill", data.spill)
	h.set_shader_parameter(&"mote", data.chalk)
	h.set_shader_parameter(&"haze", data.haze)
	h.set_shader_parameter(&"spill_strength", data.spill_strength)
	h.set_shader_parameter(&"mouth", _rect_vec(hangar_mouth_rect))
	h.set_shader_parameter(&"floor_y", floor_y)
	h.set_shader_parameter(&"hole_c", HOLE_C)
	h.set_shader_parameter(&"hole_r", HOLE_R)


static func _rect_vec(r: Rect2) -> Vector4:
	return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)


## Push the current light state to the hall, the haze and the Aether outside.
func _sync() -> void:
	if not is_node_ready():
		return
	var size := _logical_size()
	_surface.size = size
	_haze.size = size
	_foreground.set_size(size)
	var m := mouth_light()
	var s := _surface.material as ShaderMaterial
	s.set_shader_parameter(&"size_px", size)
	s.set_shader_parameter(&"mouth_veil", mouth_veil())
	_mouth_light.energy = data.mouth_energy * m
	_mouth_light.color = data.lamp_colour
	_mouth_light.texture_scale = data.mouth_radius * 2.0 / float(RuinsLamp.LIGHT_TEX)
	_mouth_light.enabled = m > 0.0
	_hourglass_light.energy = data.hourglass_energy * m
	_hourglass_light.color = data.lamp_colour
	_hourglass_light.texture_scale = 60.0 * 2.0 / float(RuinsLamp.LIGHT_TEX)
	_hourglass_light.enabled = m > 0.0
	_cabinet_light.energy = data.cabinet_energy
	_floor_pool.energy = data.lantern_energy * data.floor_pool_share * hall_lantern.output()
	_floor_pool.color = data.lantern_colour
	_floor_pool.texture_scale = data.floor_pool_radius * 2.0 / float(RuinsLamp.LIGHT_TEX)
	_floor_pool.enabled = hall_lantern.output() > 0.0
	_cabinet_light.color = Pal.PHOS_3
	_cabinet_light.texture_scale = 70.0 * 2.0 / float(RuinsLamp.LIGHT_TEX)
	var h := _haze.material as ShaderMaterial
	h.set_shader_parameter(&"size_px", size)
	h.set_shader_parameter(&"time_s", time_s)
	h.set_shader_parameter(&"hall", Vector4(hall_lantern_pos.x, hall_lantern_pos.y, hall_lantern.output(), data.lantern_radius))
	var arr: Array[Vector4] = []
	for i in MAX_HAZE_LAMPS:
		if i < _lamps.size():
			var l := _lamps[i]
			arr.append(Vector4(l.position.x, l.position.y, l.output(), data.lamp_radius))
		else:
			arr.append(Vector4.ZERO)
	h.set_shader_parameter(&"lamps", arr)
	h.set_shader_parameter(&"lamp_count", mini(_lamps.size(), MAX_HAZE_LAMPS))
	h.set_shader_parameter(&"mouth_light", m)
	_set.set_time(time_s)
	# the Aether outside: its own time, a fixed far view, and the lamps' light spilling out of the mouth
	backdrop.set_time(time_s)
	backdrop.set_camera(OUTSIDE_CAMERA, 1.0)
	# no lantern out there: the Aether's lantern pool (and its capped play core) sits far below the
	# frame, so every opening shows free fog; the lamps' light at the mouth is the hall's own haze
	backdrop.set_lantern(OUTSIDE_NO_LANTERN, 1.0, data.lamp_colour, 0.0)
