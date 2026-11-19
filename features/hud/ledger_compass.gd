class_name LedgerCompass
extends Control
## Ledger Compass stub (WARP-001 §4.1: top-centre; TECH-001 §5.4). A small honest map of the
## sector: one dot per registered target, the Vigil first. No sector list or corruption layer yet.
##
## honest := true — this is the T0 compass and it never lies. Lies (and H16) belong to
## HudModel/HudLiar upstream (TECH-001 §5.2, §5.4), never to this drawing code.
##
## Registration: the Vigil is found by its group &"vigil"; anything else joins with
## `LedgerCompass.register(node, kind)` (group &"compass_marker" + meta "compass_kind").
## Marker positions are sampled and redrawn at most `redraw_hz` times a second (≤ 10 Hz ✱).

const HONEST := true
const GROUP := &"compass_marker"
const VIGIL_GROUP := &"vigil"
const KIND_META := &"compass_kind"
const KIND_VIGIL := &"vigil"
const KIND_DEFAULT := &"marker"
const KIND_THREAT := &"threat"

@export var stats: LedgerCompassStats
## The world area the widget maps (the sector's bounds).
@export var world_rect: Rect2 = Rect2(0, 0, 640, 360)

## Widget-local marker positions and kinds from the last refresh (≤ max_markers).
var marker_points: PackedVector2Array = PackedVector2Array()
var marker_kinds: Array[StringName] = []
var refresh_count: int = 0
var _since_refresh: float = INF


## Adds `node` to the compass as a marker of `kind`.
static func register(node: Node2D, kind: StringName = KIND_DEFAULT) -> void:
	node.set_meta(KIND_META, kind)
	node.add_to_group(GROUP)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	tick(delta)


## Advances the throttle; refreshes and redraws when due. Returns true on a refresh.
func tick(delta: float) -> bool:
	_since_refresh += delta
	if stats == null or not should_refresh(_since_refresh, stats.redraw_hz):
		return false
	_since_refresh = 0.0
	refresh()
	return true


## Samples the registered targets now and queues one redraw.
func refresh() -> void:
	marker_points = PackedVector2Array()
	marker_kinds.clear()
	if is_inside_tree():
		var nodes: Array[Node] = []
		nodes.append_array(get_tree().get_nodes_in_group(VIGIL_GROUP))
		nodes.append_array(get_tree().get_nodes_in_group(GROUP))
		for n in collect(nodes, stats.max_markers if stats else 0):
			marker_points.append(map_point(n.global_position, world_rect, size))
			marker_kinds.append(kind_of(n))
	refresh_count += 1
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Pal.VOID_1, true)
	draw_rect(r, Pal.PHOS_2, false, 1.0)
	for i in marker_points.size():
		draw_circle(marker_points[i], 1.5, color_for(marker_kinds[i]))


# --- pure helpers --------------------------------------------------------------------------------

## True when a refresh is due: at most `hz` per second (a small epsilon absorbs float drift).
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


static func kind_of(n: Node) -> StringName:
	if n.is_in_group(VIGIL_GROUP):
		return KIND_VIGIL
	var k: Variant = n.get_meta(KIND_META, KIND_DEFAULT)
	return StringName(str(k))


## World position -> widget-local point, clamped to the widget (off-map targets sit on the edge).
static func map_point(world: Vector2, world_area: Rect2, widget_size: Vector2) -> Vector2:
	if world_area.size.x <= 0.0 or world_area.size.y <= 0.0:
		return widget_size * 0.5
	var t := (world - world_area.position) / world_area.size
	t = t.clamp(Vector2.ZERO, Vector2.ONE)
	return t * widget_size


## Role colours (ART-001 §4 palette only): the Vigil in gas-gold, threats in SIGNAL, others bone.
static func color_for(kind: StringName) -> Color:
	match kind:
		KIND_VIGIL:
			return Pal.GAS_4
		KIND_THREAT:
			return Pal.SIGNAL
	return Pal.BONE_4
