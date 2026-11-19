class_name AttractPages
extends Control
## The attract loop's instruction cards under the marquee (owner request 2026-11-18; WARP-001
## W0-03), in the order an arcade teaches: the pitch, how to play, the mission, the score table.
## Bindings are read live from the InputMap for the device in use; scores are read from the
## cabinet's own tuning, so the card never disagrees with the game. Costume art: honest at T0.

enum Page { PITCH, CONTROLS, MISSION, SCORES }

const PITCH_KEYS := ["NARR_CAB_ATTRACT_1", "NARR_CAB_ATTRACT_2", "NARR_CAB_ATTRACT_3"]
const ROW := 10.0
const BOX := Vector2(232, 96)     # fits the 256 px screen with 12 px clear each side

@export var tuning: CabinetBootTuning
@export var scores: CabinetTuning

var gamepad := false
var continue_stage := -1          ## 0-based stage on offer after GAME OVER (Q-T104); -1 = no offer. Pins the CONTINUE page.
var page: int = Page.PITCH
var _page_t := 0.0
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = BOX


func reset() -> void:
	page = Page.PITCH
	_page_t = 0.0


func _process(delta: float) -> void:
	_t += delta
	_page_t += delta
	if _page_t >= tuning.page_seconds:
		_page_t = 0.0
		page = (page + 1) % Page.size()
	queue_redraw()


func _draw() -> void:
	_draw_chase_lights()
	if continue_stage >= 0:
		_draw_continue()
		return
	match page:
		Page.PITCH:
			_draw_pitch()
		Page.CONTROLS:
			_draw_controls()
		Page.MISSION:
			_draw_mission()
		Page.SCORES:
			_draw_scores()


## A border of marquee bulbs; every fourth one lit, chasing round (still under reduced motion).
func _draw_chase_lights() -> void:
	var r := Rect2(Vector2(2, 2), size - Vector2(4, 4))
	var still: bool = SettingsService.get_value(&"reduced_motion") or SettingsService.get_value(&"photosensitivity")
	var step := 0 if still else int(_t * 6.0)
	var pts: Array[Vector2] = []
	for x in range(int(r.position.x), int(r.end.x), 8):
		pts.append(Vector2(x, r.position.y))
	for y in range(int(r.position.y), int(r.end.y), 8):
		pts.append(Vector2(r.end.x, y))
	for x in range(int(r.end.x), int(r.position.x), -8):
		pts.append(Vector2(x, r.end.y))
	for y in range(int(r.end.y), int(r.position.y), -8):
		pts.append(Vector2(r.position.x, y))
	for i in pts.size():
		var lit := (i + step) % 4 == 0
		draw_rect(Rect2(pts[i] - Vector2.ONE, Vector2(2, 2)), Look.c(Pal.GAS_4) if lit else Look.c(Pal.GAS_1))


func _header(key: String) -> void:
	PixelText.draw_centered(self, size.x * 0.5, 9.0, tr(key), Look.c(Pal.VOID_5))


## The CONTINUE offer (Q-T104): stage shown 1-based, in the pitch page's hot yellow, steady under reduced motion.
func _draw_continue() -> void:
	var still: bool = SettingsService.get_value(&"reduced_motion") or SettingsService.get_value(&"photosensitivity")
	var lit := still or int(_t * 2.0) % 2 == 0
	var y := size.y * 0.5 - 12.0
	for line in PixelText.wrap(tr("CAB_CONTINUE") % (continue_stage + 1), 1, size.x - 24.0):
		PixelText.draw_centered(self, size.x * 0.5, y, line, Look.c(Pal.GAS_4) if lit else Look.c(Pal.GAS_2))
		y += 12.0


func _draw_pitch() -> void:
	var cols := [Look.c(Pal.GAS_4), Look.c(Pal.BONE_4), Look.c(Pal.PHOS_4)]
	var y := 16.0
	for i in PITCH_KEYS.size():
		for line in PixelText.wrap(tr(PITCH_KEYS[i]), 1, size.x - 24.0):
			PixelText.draw_centered(self, size.x * 0.5, y, line, cols[i] as Color)
			y += 12.0
		y += 8.0


func _draw_controls() -> void:
	_header("CAB_PAGE_CONTROLS")
	var rows := [
		["CAB_CTRL_STEER", InputLabels.vector(&"move_left", &"move_right", &"move_up", &"move_down", gamepad)],
		["CAB_CTRL_AIM", InputLabels.vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down", true) if gamepad else tr("ATTRACT_MOUSE")],
		["CAB_CTRL_FIRE", InputLabels.action(&"fire_lance", gamepad)],
		["CAB_CTRL_CHARGE", InputLabels.action(&"deploy_charge", gamepad)],
		["CAB_CTRL_SURGE", InputLabels.action(&"surgelight", gamepad)],
		["CAB_CTRL_BRAKE", InputLabels.action(&"brake", gamepad)],
		["CAB_CTRL_PAUSE", InputLabels.action(&"pause", gamepad)],
	]
	for i in rows.size():
		var row: Array = rows[i]
		var y := 22.0 + i * ROW
		var value := row[1] as String
		var value_x := size.x - 12.0 - PixelText.width(value)
		PixelText.draw(self, Vector2(12, y), tr(row[0] as String), Look.c(Pal.BONE_3))
		var dots_from := 12.0 + PixelText.width(tr(row[0] as String)) + 4.0
		for dx in range(int(dots_from), int(value_x) - 4, 4):
			draw_rect(Rect2(dx, y + 6, 1, 1), Look.c(Pal.BONE_1))
		PixelText.draw(self, Vector2(value_x, y), value, Look.c(Pal.GAS_4))
	# the Vigil itself, turning slowly, lamp lit, thrusting
	_vigil(Vector2(24, 12), _t * 0.8)


func _draw_mission() -> void:
	_header("CAB_PAGE_MISSION")
	var keys := ["CAB_MISSION_1", "CAB_MISSION_2", "CAB_MISSION_3", "CAB_MISSION_4"]
	var icons := ["geode", "lamp", "grub", "sepulchre"]
	for i in keys.size():
		var y := 26.0 + i * 19.0
		_icon(icons[i] as String, Vector2(16, y + 3))
		PixelText.draw(self, Vector2(30, y), tr(keys[i] as String), Look.c(Pal.BONE_4))


func _draw_scores() -> void:
	_header("CAB_PAGE_SCORES")
	var rows := [
		["shard", "CAB_SCORE_SHARD", scores.score_shard],
		["grub", "CAB_SCORE_GRUB", scores.score_grub],
		["acolyte", "CAB_SCORE_ACOLYTE", scores.score_acolyte],
		["module", "CAB_SCORE_MODULE", scores.score_module],
		["entity", "CAB_SCORE_ENTITY", scores.score_entity],
	]
	for i in rows.size():
		var row: Array = rows[i]
		var y := 22.0 + i * 11.0
		_icon(row[0] as String, Vector2(16, y + 3))
		PixelText.draw(self, Vector2(30, y), tr(row[1] as String), Look.c(Pal.BONE_3))
		var pts := LocFormat.format_int(int(row[2]))
		PixelText.draw(self, Vector2(size.x - 14.0 - PixelText.width(pts), y), pts, Look.c(Pal.GAS_4))
	var extra := tr("CAB_SCORE_EXTRA") % LocFormat.format_int(scores.extra_life_first)
	PixelText.draw_centered(self, size.x * 0.5, 22.0 + rows.size() * 11.0 + 2.0, extra, Look.c(Pal.PHOS_4))


func _vigil(c: Vector2, angle: float) -> void:
	var f := Vector2.from_angle(angle)
	var r := f.orthogonal()
	var hull := PackedVector2Array([c + f * 9.0, c - f * 6.0 + r * 6.0, c - f * 3.0, c - f * 6.0 - r * 6.0])
	Pal.glow_polyline(self, hull, Look.c(Pal.GAS_4), Look.c(Pal.GAS_1))
	draw_rect(Rect2((c + f).round() - Vector2(1, 1), Vector2(3, 3)), Look.c(Pal.GAS_5))
	if int(_t * 15.0) % 2 == 0:
		draw_line(c - f * 4.0, c - f * 10.0, Look.c(Pal.GAS_3), 1.0)


## Small vector icons in the cabinet's own costume colours (the sim's shapes, simplified).
func _icon(kind: String, c: Vector2) -> void:
	match kind:
		"geode":
			var pts := PackedVector2Array()
			for k in 7:
				pts.append(c + Vector2.from_angle(TAU * k / 7.0 + 0.3) * (6.0 if k % 2 == 0 else 4.5))
			Pal.glow_polyline(self, pts, Look.c(Pal.BONE_3), Look.c(Pal.BONE_0))
		"shard":
			Pal.glow_polyline(self, PackedVector2Array([c + Vector2(0, -4), c + Vector2(3, 0), c + Vector2(0, 4), c + Vector2(-3, 0)]), Look.c(Pal.PHOS_4), Look.c(Pal.PHOS_1))
		"lamp":
			var lamp := PackedVector2Array([c + Vector2(0, -6), c + Vector2(4, 0), c + Vector2(0, 6), c + Vector2(-4, 0)])
			draw_colored_polygon(lamp, Look.c(Pal.PHOS_3))
			Pal.glow_polyline(self, lamp, Look.c(Pal.PHOS_4), Look.c(Pal.VOID_2))
		"grub":
			draw_arc(c, 2.5, 0.0, TAU, 8, Look.c(Pal.CHOIR_3), 1.0)
			draw_arc(c - Vector2(4, 0), 2.0, 0.0, TAU, 8, Look.c(Pal.CHOIR_3), 1.0)
			draw_rect(Rect2(c + Vector2(0, -6), Vector2(2, 3)), Look.c(Pal.PHOS_4))
		"acolyte":
			Pal.glow_polyline(self, PackedVector2Array([c + Vector2(0, -5), c + Vector2(5, 4), c + Vector2(-5, 4)]), Look.c(Pal.CHOIR_5), Look.c(Pal.CHOIR_1))
		"module":
			draw_rect(Rect2(c - Vector2(4, 4), Vector2(8, 8)), Look.c(Pal.VOID_5), false, 1.0)
			draw_rect(Rect2(c - Vector2(1, 1), Vector2(2, 2)), Look.c(Pal.CHOIR_4))
		"sepulchre":
			for k in 3:
				draw_rect(Rect2(c + Vector2(-9 + k * 6, -4), Vector2(5, 8)), Look.c(Pal.VOID_5), false, 1.0)
		"entity":
			# the only true black is the entity (ART-001 §16), even in the costume
			draw_rect(Rect2(c - Vector2(5, 5), Vector2(10, 10)), Pal.NULL)
			draw_rect(Rect2(c - Vector2(5, 5), Vector2(10, 10)), Look.c(Pal.PHOS_4), false, 1.0)
