class_name Starfield
extends ArcadeLayer
## Three parallax star layers plus the chalk seam of the torus (WARP-001 W0-09 "Honest Seam").
## `pull` > 0 drags every star toward a point: the Unmaking eats the sky (W0-07, the reveal).

const LAYERS := [
	{"count": 90, "parallax": 0.25, "color": Pal.VOID_4},
	{"count": 60, "parallax": 0.5, "color": Pal.VOID_5},
	{"count": 30, "parallax": 0.8, "color": Pal.BONE_2},
]

var _stars: Array[PackedVector2Array] = []
var pull := 0.0                      ## 0..1, set by the reveal
var pull_target := Vector2(320, 180) ## screen point the sky drains into
var desaturate := 0.0                ## 0..1, T0→T1 costume removal (W0-08)
var show_seams := true


func reset() -> void:
	_stars.clear()
	var r := RandomNumberGenerator.new()
	r.seed = 77
	for layer in LAYERS:
		var pts := PackedVector2Array()
		for i in int(layer.count):
			pts.append(Vector2(r.randf() * 640.0, r.randf() * 360.0))
		_stars.append(pts)


func _draw() -> void:
	if world == null or world.torus == null:
		return
	var cam := world.view_centre
	for li in LAYERS.size():
		var layer: Dictionary = LAYERS[li]
		var par: float = layer.parallax
		var col: Color = layer.color
		if desaturate > 0.0:
			col = col.lerp(Pal.BONE_1, desaturate * 0.6)
		var off := -cam * par
		for i in _stars[li].size():
			var s: Vector2 = _stars[li][i]
			var p := Vector2(fposmod(s.x + off.x, 640.0), fposmod(s.y + off.y, 360.0))
			if pull > 0.0:
				p = p.lerp(pull_target, clampf(pull * (1.0 + par), 0.0, 1.0))
			var twinkle := (i * 7 + int(world.time * 3.0)) % 23 == 0
			draw_rect(Rect2(p.round(), Vector2.ONE), Pal.BONE_5 if twinkle else col)
	if show_seams and pull <= 0.0:
		_draw_seams()


## The field's edges, drawn as dashed chalk where they cross the screen.
func _draw_seams() -> void:
	var size := world.torus.size
	var origin := world.to_screen(Vector2.ZERO)
	for kx in [-1, 0, 1]:
		var x: float = origin.x + kx * size.x
		if x >= 0.0 and x <= 640.0:
			for y in range(0, 360, 8):
				draw_line(Vector2(x, y), Vector2(x, y + 3), Pal.BONE_0)
	for ky in [-1, 0, 1]:
		var y: float = origin.y + ky * size.y
		if y >= 0.0 and y <= 360.0:
			for x in range(0, 640, 8):
				draw_line(Vector2(x, y), Vector2(x + 3, y), Pal.BONE_0)
