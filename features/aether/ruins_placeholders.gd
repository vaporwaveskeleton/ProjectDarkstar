class_name RuinsPlaceholders
extends Node2D
## Optional stand-ins (gallery only; RuinsLook.show_placeholders, default off) for the Ruins
## objects M1 owns: the Chalk Desk, the wall Cabinet, the Codex desk, the Hourglass and the Lantern
## Tree (a bare brass sapling, one unlit lamp housing per node, NARR-001 §5.7). Lit by the hall like
## everything else; no text, no gameplay. Never shipped as the real objects.

## ✱ placeholder Tree node offsets from the Tree's base (logical px): where its lamps hang.
const TREE_NODES: Array[Vector2] = [Vector2(-22, -58), Vector2(19, -66), Vector2(-9, -84), Vector2(28, -40),
	Vector2(-30, -34)]

var chalk_desk := Vector2(190, 300)
var cabinet := Vector2(74, 214)
var codex_desk := Vector2(300, 300)
var hourglass := Vector2(438, 300)
var tree := Vector2(392, 300)
var brass := Pal.BONE_2
var brass_hi := Pal.BONE_4
var brass_shadow := Pal.VOID_3
var wood := Pal.BONE_0


func configure(data: RuinsLookData) -> void:
	brass = data.brass
	brass_hi = data.brass_hi
	brass_shadow = data.brass_shadow
	queue_redraw()


func set_markers(p_chalk: Vector2, p_cabinet: Vector2, p_codex: Vector2, p_hourglass: Vector2, p_tree: Vector2) -> void:
	chalk_desk = p_chalk
	cabinet = p_cabinet
	codex_desk = p_codex
	hourglass = p_hourglass
	tree = p_tree
	queue_redraw()


## Where the placeholder Tree's lamps hang (RuinsLook-local logical px).
func lamp_positions() -> PackedVector2Array:
	var out := PackedVector2Array()
	for o in TREE_NODES:
		out.append(tree + o)
	return out


func _draw() -> void:
	_draw_cabinet()
	_draw_chalk_desk()
	_draw_codex_desk()
	_draw_tree()
	_draw_hourglass()


func _draw_chalk_desk() -> void:
	var b := chalk_desk
	# a slanted desk on two legs, a slate on it
	draw_rect(Rect2(b.x - 20, b.y - 18, 3, 18), wood)
	draw_rect(Rect2(b.x + 16, b.y - 18, 3, 18), wood)
	draw_colored_polygon(PackedVector2Array([b + Vector2(-24, -18), b + Vector2(22, -22), b + Vector2(22, -19),
		b + Vector2(-24, -15)]), brass.lerp(wood, 0.6))
	draw_colored_polygon(PackedVector2Array([b + Vector2(-16, -20), b + Vector2(12, -23), b + Vector2(12, -35),
		b + Vector2(-16, -32)]), Pal.VOID_2)
	draw_polyline(PackedVector2Array([b + Vector2(-16, -20), b + Vector2(12, -23), b + Vector2(12, -35),
		b + Vector2(-16, -32), b + Vector2(-16, -20)]), brass, 1.0, true)


func _draw_cabinet() -> void:
	var c := cabinet
	var body := Rect2(c.x - 13, c.y - 30, 26, 60)
	draw_rect(body, Pal.VOID_3)
	draw_rect(Rect2(body.position.x, body.position.y, 26, 8), Pal.VOID_4)   # marquee (dark until Sable writes)
	draw_rect(Rect2(c.x - 9, c.y - 18, 18, 15), Pal.PHOS_0)                 # the screen
	draw_rect(Rect2(c.x - 7, c.y - 16, 14, 11), Pal.PHOS_1)
	draw_rect(Rect2(c.x - 11, c.y + 2, 22, 5), Pal.VOID_4)                  # control panel
	draw_rect(body, brass_shadow, false, 1.0)


func _draw_codex_desk() -> void:
	var b := codex_desk
	draw_rect(Rect2(b.x - 3, b.y - 24, 6, 24), wood)
	draw_colored_polygon(PackedVector2Array([b + Vector2(-16, -26), b + Vector2(16, -30), b + Vector2(16, -26),
		b + Vector2(-16, -22)]), brass.lerp(wood, 0.5))
	# an open book: two pale pages
	draw_colored_polygon(PackedVector2Array([b + Vector2(-12, -27), b + Vector2(0, -30), b + Vector2(0, -27),
		b + Vector2(-12, -24)]), Pal.BONE_3)
	draw_colored_polygon(PackedVector2Array([b + Vector2(0, -30), b + Vector2(12, -32), b + Vector2(12, -29),
		b + Vector2(0, -27)]), Pal.BONE_2)


func _draw_tree() -> void:
	var b := tree
	# a bare brass sapling: a trunk and thin branches out to each node
	draw_colored_polygon(PackedVector2Array([b + Vector2(-4, 0), b + Vector2(-1.5, -70), b + Vector2(1.5, -70),
		b + Vector2(4, 0)]), brass)
	draw_line(b + Vector2(-3, 0), b + Vector2(-1, -70), brass_hi, 0.8, true)
	draw_colored_polygon(PackedVector2Array([b + Vector2(-9, 0), b + Vector2(9, 0), b + Vector2(5, -4),
		b + Vector2(-5, -4)]), brass_shadow.lerp(brass, 0.4))
	for o in TREE_NODES:
		var root := b + Vector2(0, clampf(o.y * 0.6, -66.0, -12.0))
		var mid := root.lerp(b + o, 0.5) + Vector2(0, 4)
		draw_polyline(PackedVector2Array([root, mid, b + o + Vector2(0, -5)]), brass, 1.1, true)
		_housing(b + o)


func _housing(p: Vector2) -> void:
	# an unlit lamp housing hung from its node: a small brass cage round dark glass
	draw_line(p + Vector2(0, -5), p + Vector2(0, -3.5), brass, 0.8)
	draw_rect(Rect2(p.x - 2.5, p.y - 3.5, 5, 6), Color(Pal.VOID_3, 0.6))
	draw_rect(Rect2(p.x - 2.5, p.y - 3.5, 5, 6), brass, false, 0.7)
	draw_line(p + Vector2(-3, -3.5), p + Vector2(3, -3.5), brass_hi, 0.8)


func _draw_hourglass() -> void:
	var b := hourglass
	draw_rect(Rect2(b.x - 8, b.y - 3, 16, 3), brass)
	draw_rect(Rect2(b.x - 8, b.y - 30, 16, 3), brass)
	for x in [-7.0, 7.0]:
		draw_line(b + Vector2(x, -27), b + Vector2(x, -3), brass, 1.2)
	draw_colored_polygon(PackedVector2Array([b + Vector2(-5, -27), b + Vector2(5, -27), b + Vector2(0.8, -15),
		b + Vector2(5, -3), b + Vector2(-5, -3), b + Vector2(-0.8, -15)]), Color(Pal.PHOS_1, 0.35))
	# full: all the sand above
	draw_colored_polygon(PackedVector2Array([b + Vector2(-4.5, -26), b + Vector2(4.5, -26), b + Vector2(0.8, -16),
		b + Vector2(-0.8, -16)]), Pal.BONE_3)
