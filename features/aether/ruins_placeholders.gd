class_name RuinsPlaceholders
extends Node2D
## The stand-in Lantern Tree (a bare brass sapling, one unlit lamp housing per node, NARR-001 §5.7)
## until the Tree feature lands its own art (TECH-001 Q-T193). Lit by the hall like everything else;
## no text, no gameplay. The other Ruins objects are RuinsObjects (lamp-lit vector art, Q-T193).

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
	_draw_tree()


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

