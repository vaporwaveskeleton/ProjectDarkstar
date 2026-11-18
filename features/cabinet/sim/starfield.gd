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
var pull_target := Vector2.ZERO    ## screen point the sky drains into (the play view centre, set in reset)
var desaturate := 0.0                ## 0..1, T0→T1 costume removal (W0-08)
var show_seams := true


func reset() -> void:
	_stars.clear()
	pull_target = world.screen_centre
	var r := RandomNumberGenerator.new()
	r.seed = 77
	for layer in LAYERS:
		var pts := PackedVector2Array()
		for i in int(layer.count):
			pts.append(Vector2(r.randf() * world.view_size.x, r.randf() * world.view_size.y))
		_stars.append(pts)


func _draw() -> void:
	if world == null or world.torus == null:
		return
	var cam := world.view_centre
	var tile := world.view_size
	var origin := world.view_rect.position
	for li in LAYERS.size():
		var layer: Dictionary = LAYERS[li]
		var par: float = layer.parallax
		var col: Color = Look.c(layer.color as Color)
		if desaturate > 0.0:
			col = col.lerp(Look.c(Pal.BONE_1), desaturate * 0.6)
		var off := -cam * par
		for i in _stars[li].size():
			var s: Vector2 = _stars[li][i]
			var p := origin + Vector2(fposmod(s.x + off.x, tile.x), fposmod(s.y + off.y, tile.y))
			if pull > 0.0:
				p = p.lerp(pull_target, clampf(pull * (1.0 + par), 0.0, 1.0))
			var twinkle := (i * 7 + int(world.time * 3.0)) % 23 == 0
			draw_rect(Rect2(p.round(), Vector2.ONE), Look.c(Pal.BONE_5) if twinkle else col)
	if show_seams and pull <= 0.0:
		_draw_seams()


## The field's edges, drawn as dashed chalk where they cross the screen.
func _draw_seams() -> void:
	var size := world.torus.size
	var origin := world.to_screen(Vector2.ZERO)
	var view := world.view_rect
	for kx in [-1, 0, 1]:
		var x: float = origin.x + kx * size.x
		if x >= view.position.x and x <= view.end.x:
			for y in range(int(view.position.y), int(view.end.y), 8):
				draw_line(Vector2(x, y), Vector2(x, y + 3), Look.c(Pal.BONE_0))
	for ky in [-1, 0, 1]:
		var y: float = origin.y + ky * size.y
		if y >= view.position.y and y <= view.end.y:
			for x in range(int(view.position.x), int(view.end.x), 8):
				draw_line(Vector2(x, y), Vector2(x + 3, y), Look.c(Pal.BONE_0))
