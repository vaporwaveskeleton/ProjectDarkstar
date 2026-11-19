class_name LedgerCompass
extends Control
## Ledger Compass (WARP-001 §4.1: still, top-centre; TECH-001 §5.4). A 64 × 64 module (ART-001
## §12.5, Q-T120): brass bezel, VOID-1 face, chalk ticks, the sector cell with its grid, a one-cell
## sector list STUB, an empty entity marker frame, and one dot per registered target.
##
## Two layers (TECH-001 §5.4): `LedgerCompassStatic` draws the frame, ticks, map grid, sector list
## and entity frame only when invalidated (macro map, size or sector list changed), coalesced to at
## most `redraw_hz` (≤ 10 Hz ✱); between redraws the canvas keeps its recorded commands (the cache).
## `LedgerCompassMarkers` draws the markers every frame.
##
## Honesty: the world is sampled into a `HudModel`; the drawing reads only `HudModel.presented()`.
## With Steady Ledger on (default) that is the honest model. Lies (and H16) belong to
## HudModel/HudLiar upstream (TECH-001 §5.2, §5.4), never to this drawing code. HONEST stays true.
##
## Registration: the Vigil is found by its group &"vigil"; anything else joins with
## `LedgerCompass.register(node, kind, rank)` (group &"compass_marker" + metas "compass_kind",
## "compass_rank"). Lower ranks are listed first (stable), so under the cap a Sepulchre and its
## Grubs are not crowded out by geodes. With a `torus` set, positions are wrapped into the sector
## first (actors sit on the image nearest the Vigil, possibly outside [0, size)).

const HONEST := true
const GROUP := &"compass_marker"
const VIGIL_GROUP := &"vigil"
const KIND_META := &"compass_kind"
const RANK_META := &"compass_rank"
const RANK_DEFAULT := 100
const KIND_VIGIL := &"vigil"
const KIND_DEFAULT := &"marker"
const KIND_THREAT := &"threat"
const KIND_SEPULCHRE := &"sepulchre"
const KIND_GRUB := &"grub"

@export var stats: LedgerCompassStats
## The world area the widget maps (the sector's bounds). Changing it invalidates the static layer.
@export var world_rect: Rect2 = Rect2(0, 0, 640, 360):
	set(v):
		world_rect = v
		invalidate_static()
## The sector's torus when it wraps (injected by the sector). Null = off-map targets are clamped.
var torus: Torus:
	set(v):
		torus = v
		invalidate_static()

## The truth the compass reads (TECH-001 §5.2). The drawing reads `model.presented()` only.
var model: HudModel = HudModel.new()
## W1-09 (presented model): the smeared slot (-1 none) and the widget point of its true position.
var smear_slot: int = -1
var smear_tail_point: Vector2 = Vector2.ZERO
## Widget-local marker positions and kinds from the last sample (≤ max_markers).
var marker_points: PackedVector2Array = PackedVector2Array()
var marker_kinds: Array[StringName] = []
## Marker samples taken (one per frame while processing).
var refresh_count: int = 0
## Static-layer redraws requested so far (at most one per invalidation burst, ≤ redraw_hz).
var static_redraw_count: int = 0
var layout: LedgerCompassLayout

var _static: LedgerCompassStatic
var _markers: LedgerCompassMarkers
var _static_dirty: bool = true
var _since_static: float = INF


## Adds `node` to the compass as a marker of `kind`.
static func register(node: Node2D, kind: StringName = KIND_DEFAULT, rank: int = RANK_DEFAULT) -> void:
	node.set_meta(KIND_META, kind)
	node.set_meta(RANK_META, rank)
	node.add_to_group(GROUP)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if stats:
		custom_minimum_size = stats.size_px
		size = stats.size_px
	_static = LedgerCompassStatic.new()
	_static.name = &"Static"
	_markers = LedgerCompassMarkers.new()
	_markers.name = &"Markers"
	for layer: Control in [_static, _markers]:
		add_child(layer)
		layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	invalidate_static()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		invalidate_static()


func _process(delta: float) -> void:
	tick(delta)


## One frame: samples and redraws the markers, and redraws the static layer if it is invalid and
## at least 1 / redraw_hz has passed since its last redraw. Returns true when the static layer redrew.
func tick(delta: float) -> bool:
	refresh()
	_since_static += delta
	if not _static_dirty or stats == null or not should_refresh(_since_static, stats.redraw_hz):
		return false
	_redraw_static()
	return true


## Marks the static layer for a redraw (macro map, size or sector list changed).
func invalidate_static() -> void:
	_static_dirty = true
	_relayout()


## Samples the registered targets into the model now and queues one marker redraw.
func refresh() -> void:
	if is_inside_tree():
		model.sample_compass(get_tree().get_nodes_in_group(VIGIL_GROUP),
			by_rank(get_tree().get_nodes_in_group(GROUP)), torus, stats.max_markers if stats else 0)
	if layout == null:
		_relayout()
	var shown := model.presented()
	marker_points.resize(shown.marker_world.size())
	marker_kinds.assign(shown.marker_kinds)
	for i in shown.marker_world.size():
		marker_points[i] = layout.to_widget(shown.marker_world[i], world_rect)
	smear_slot = shown.smear_slot
	if smear_slot >= 0:
		smear_tail_point = layout.to_widget(shown.smear_tail, world_rect)
	refresh_count += 1
	if _markers:
		_markers.points = marker_points
		_markers.kinds = marker_kinds
		_markers.smear_slot = smear_slot
		_markers.smear_tail = smear_tail_point
		_markers.queue_redraw()


## Widget-local position of the own-position readout (the Vigil), from the presented model.
func own_position_point() -> Vector2:
	if layout == null:
		_relayout()
	return layout.to_widget(model.presented().own_position, world_rect)


func _relayout() -> void:
	var px := stats.size_px if stats and stats.size_px != Vector2.ZERO else size
	layout = LedgerCompassLayout.make(px, stats.bezel_px if stats else 0.0, world_rect.size)


func _redraw_static() -> void:
	_static_dirty = false
	_since_static = 0.0
	static_redraw_count += 1
	if _static == null:
		return
	_static.layout = layout
	_static.world_rect = world_rect
	_static.grid_world_px = stats.grid_world_px
	_static.sector_list_cells = model.sector_list_cells
	_markers.radius_px = stats.marker_radius_px
	_static.queue_redraw()


# --- pure helpers --------------------------------------------------------------------------------

## True when a redraw is due: at most `hz` per second (a small epsilon absorbs float drift).
static func should_refresh(elapsed: float, hz: float) -> bool:
	return hz <= 0.0 or elapsed + 1e-6 >= 1.0 / hz


## Unique, live Node2D targets in order, at most `cap`.
static func collect(nodes: Array[Node], cap: int) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for n in nodes:
		if out.size() >= cap:
			break
		if n is Node2D and is_instance_valid(n) and not out.has(n):
			out.append(n as Node2D)
	return out


## `nodes` ordered by compass rank, lowest first; equal ranks keep their order (stable).
static func by_rank(nodes: Array[Node]) -> Array[Node]:
	var keyed: Array = []
	for i in nodes.size():
		keyed.append([int(nodes[i].get_meta(RANK_META, RANK_DEFAULT)), i, nodes[i]])
	keyed.sort_custom(func(a: Array, b: Array) -> bool:
		return int(a[0]) < int(b[0]) or (int(a[0]) == int(b[0]) and int(a[1]) < int(b[1])))
	var out: Array[Node] = []
	for k: Array in keyed:
		out.append(k[2] as Node)
	return out


static func kind_of(n: Node) -> StringName:
	if n.is_in_group(VIGIL_GROUP):
		return KIND_VIGIL
	var k: Variant = n.get_meta(KIND_META, KIND_DEFAULT)
	return StringName(str(k))


## World position -> point in an area of `area_size`, clamped (off-map targets sit on the edge).
static func map_point(world: Vector2, world_area: Rect2, area_size: Vector2) -> Vector2:
	if world_area.size.x <= 0.0 or world_area.size.y <= 0.0:
		return area_size * 0.5
	var t := (world - world_area.position) / world_area.size
	t = t.clamp(Vector2.ZERO, Vector2.ONE)
	return t * area_size


## Role colours (ART-001 §4 palette only): the Vigil in gas-gold, threats in SIGNAL, the Choir's
## Sepulchre and Grubs in Choir hue, others bone.
static func color_for(kind: StringName) -> Color:
	match kind:
		KIND_VIGIL:
			return Pal.GAS_4
		KIND_THREAT:
			return Pal.SIGNAL
		KIND_SEPULCHRE, KIND_GRUB:
			return Pal.CHOIR_4
	return Pal.BONE_4
