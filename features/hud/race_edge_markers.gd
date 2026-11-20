class_name RaceEdgeMarkers
extends Control
## Race edge markers (Reviewer v3 gap 6; TECH-001 §5.4; Q-T357). When a part of the race is off the
## screen (a Charge in flight, a Grub carrying glass, the Sepulchre while either happens), a small brass
## chevron sits on the frame's inner band where the line from the screen centre leaves it, pointing at
## the thing, with a pip in the thing's own colour: phosphor for a Charge, Choir for a Grub and the
## Sepulchre (the Sepulchre's chevron is larger). On-screen race parts get no marker.
##
## Honest by construction, like the Surgelight pips: the sector pushes the TRUE offsets each frame
## (`show_race`); there is no HudModel, no lie seam and nothing a warp effect can reach. Steady
## Ledger-safe; never eaten, never moved (WARP-001 §4.1 row "Race edge markers", Q-T357). Still: no
## animation, so reduced motion changes nothing here; under reduced motion these markers are what
## carries the race (the camera does not pull out, Q-T356). Runtime vector, Pal colours only.

const HONEST := true
const KIND_CHARGE := &"charge"
const KIND_GRUB := &"grub"
const KIND_SEPULCHRE := &"sepulchre"
## Draw priority (lower first) when more race parts are off screen than `max_markers`.
const KIND_RANK := {KIND_CHARGE: 0, KIND_SEPULCHRE: 1, KIND_GRUB: 2}

@export var stats: RaceEdgeMarkerStats
## The markers drawn now, in logical px of this control: tip anchor point, unit direction, kind.
var points: PackedVector2Array = PackedVector2Array()
var dirs: PackedVector2Array = PackedVector2Array()
var kinds: Array[StringName] = []
## `_draw` passes (tests read it).
var draw_count := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## The race this frame: `offsets` are screen-px offsets from the screen centre (world offset × zoom,
## nearest torus image), `race_kinds` their kinds, `screen` the logical frame size. Off-screen parts
## become markers, ordered by KIND_RANK then distance, at most `max_markers`.
func show_race(offsets: PackedVector2Array, race_kinds: Array[StringName], screen: Vector2) -> void:
	var half := screen * 0.5
	var order: Array = []
	for i in offsets.size():
		if not RaceFramer.offscreen(offsets[i], half):
			continue
		order.append([int(KIND_RANK.get(race_kinds[i], 9)), offsets[i].length(), i])
	order.sort_custom(func(a: Array, b: Array) -> bool:
		return int(a[0]) < int(b[0]) or (int(a[0]) == int(b[0]) and float(a[1]) < float(b[1])))
	var cap := stats.max_markers if stats else 0
	var band := inner_band(screen)
	points.clear()
	dirs.clear()
	kinds.clear()
	for o: Array in order:
		if points.size() >= cap:
			break
		var i: int = o[2]
		points.append(edge_point(offsets[i], half, band))
		dirs.append(offsets[i].normalized())
		kinds.append(race_kinds[i])
	queue_redraw()


func count() -> int:
	return points.size()


## The band the markers sit on: the frame inset by the stats (clears the HUD plates).
func inner_band(screen: Vector2) -> Rect2:
	if stats == null:
		return Rect2(Vector2.ZERO, screen)
	var tl := Vector2(stats.inset_side_px, stats.inset_top_px)
	var br := screen - Vector2(stats.inset_side_px, stats.inset_bottom_px)
	return Rect2(tl, (br - tl).max(Vector2.ONE))


func _draw() -> void:
	draw_count += 1
	for i in points.size():
		var big := kinds[i] == KIND_SEPULCHRE
		var sz := (stats.sepulchre_size_px if big else stats.size_px) if stats else 5.0
		chevron(self, points[i], dirs[i], sz, color_for(kinds[i]))


# --- pure helpers --------------------------------------------------------------------------------

## Where the ray from the screen centre (`half`) along `d` leaves `band` (a rect inside the frame).
static func edge_point(d: Vector2, half: Vector2, band: Rect2) -> Vector2:
	if d == Vector2.ZERO:
		return half
	var t := INF
	if d.x > 0.0:
		t = minf(t, (band.end.x - half.x) / d.x)
	elif d.x < 0.0:
		t = minf(t, (band.position.x - half.x) / d.x)
	if d.y > 0.0:
		t = minf(t, (band.end.y - half.y) / d.y)
	elif d.y < 0.0:
		t = minf(t, (band.position.y - half.y) / d.y)
	return (half + d * maxf(0.0, t)).clamp(band.position, band.end)


## Role colours (ART-001 §4; phosphor = the Charge's own glass, Choir hue for the Choir).
static func color_for(kind: StringName) -> Color:
	match kind:
		KIND_CHARGE:
			return Pal.PHOS_4
		KIND_GRUB, KIND_SEPULCHRE:
			return Pal.CHOIR_4
	return Pal.BONE_4


## A brass chevron at `p` pointing along `dir` (unit), half length `sz`, with a pip of `pip`.
static func chevron(ci: CanvasItem, p: Vector2, dir: Vector2, sz: float, pip: Color) -> void:
	var side := Vector2(-dir.y, dir.x)
	var tip := p + dir * sz
	var tri := PackedVector2Array([tip, p - dir * sz * 0.6 + side * sz * 0.85, p - dir * sz * 0.6 - side * sz * 0.85])
	var rim := PackedVector2Array([tip + dir, p - dir * (sz * 0.6 + 1.0) + side * (sz * 0.85 + 1.0),
		p - dir * (sz * 0.6 + 1.0) - side * (sz * 0.85 + 1.0)])
	ci.draw_colored_polygon(rim, Pal.GAS_0)
	ci.draw_colored_polygon(tri, Pal.GAS_3)
	ci.draw_line(tip, p - dir * sz * 0.6 + side * sz * 0.85, Pal.GAS_4, 1.0)
	ci.draw_circle(p - dir * sz * 0.1, maxf(1.0, sz * 0.38), Pal.GAS_0)
	ci.draw_circle(p - dir * sz * 0.1, maxf(0.8, sz * 0.28), pip)
