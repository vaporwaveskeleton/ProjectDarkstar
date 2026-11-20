class_name AcolyteView
extends Node2D
## Draws its parent AetherAcolyte (runtime vector, Aether tier; ART-001 §15). A tall, narrow hooded
## knight about 2.5 Grubs high, Choir hues only (never GAS on Choir): CHOIR_1 plates with CHOIR_2 light
## faces, BONE_2/BONE_3 trim, CHOIR_0 shadow, a faceless hood in VOID_2 (never pure black) and a soft halo.
## The censer hangs on a short chain and swings toward the lagged aim; its CHOIR_4 ember is self-lit and
## brightens while the cage lifts during the tell. Death: the ember gutters out over `die_s`, no flash.
## Reduced Motion holds the sway still. Reads only; no RNG.

const HALO_RINGS := 3         ## drawing
const HALO_RADIUS_PX := 17.0  ## drawing
const HALO_ALPHA := 0.06      ## drawing
const SWAY_RATE := 1.6        ## rad/s, drawing
const FLASH_DECAY := 5.0      ## 1/s, drawing
const CHAIN_PX := 8.0         ## drawing
const HAND := Vector2(5, -1)  ## drawing

@export var acolyte: AetherAcolyte

var _flash := 0.0
var _time := 0.0


func flash() -> void:
	_flash = 1.0


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(0.0, _flash - delta * FLASH_DECAY)
	queue_redraw()


func _still() -> bool:
	return bool(SettingsService.get_value(&"reduced_motion"))


## 1 alive ... 0 gone: how much of the knight remains while the ember gutters.
func life_frac() -> float:
	if acolyte == null or not acolyte.dead:
		return 1.0
	return clampf(1.0 - acolyte.die_s / maxf(0.001, acolyte.stats.die_s), 0.0, 1.0)


## Where the censer cage hangs (local px): on its chain toward the aim, lifting while telling.
func censer_pos() -> Vector2:
	var aim := acolyte.aim if acolyte != null else Vector2.DOWN
	var phase := float(acolyte.index) if acolyte != null else 0.0
	var sway := 0.0 if _still() else sin(_time * SWAY_RATE + phase) * 0.12
	var lift := (acolyte.tell_frac() if acolyte != null else 0.0) * 4.0
	return (HAND + aim.rotated(sway) * CHAIN_PX + Vector2(0, -lift)).round()


func _draw() -> void:
	if acolyte == null:
		return
	var life := life_frac()
	var hot := _flash > 0.4
	var a := life
	for r in HALO_RINGS:
		draw_circle(Vector2(0, -2), HALO_RADIUS_PX * float(r + 1) / HALO_RINGS, Color(Pal.CHOIR_3, HALO_ALPHA * a))
	# cloak (shadow) and plated body
	draw_colored_polygon(PackedVector2Array([Vector2(-4, 11), Vector2(-5, -1), Vector2(5, -1), Vector2(4, 11)]), Color(Pal.CHOIR_0, a))
	draw_colored_polygon(PackedVector2Array([Vector2(-3, 9), Vector2(-4, -1), Vector2(4, -1), Vector2(3, 9)]),
		Color(Pal.CHOIR_4 if hot else Pal.CHOIR_1, a))
	draw_rect(Rect2(-3, 0, 2, 8), Color(Pal.CHOIR_2, a))                   # light face of the plates
	draw_line(Vector2(-4, 4), Vector2(4, 4), Color(Pal.BONE_2, a), 1.0)    # belt trim
	draw_rect(Rect2(-5, -2, 3, 2), Color(Pal.BONE_3, a))                   # pauldrons
	draw_rect(Rect2(2, -2, 3, 2), Color(Pal.BONE_3, a))
	# hood: faceless, VOID_2 with a bone rim
	var hood := PackedVector2Array([Vector2(-3, -1), Vector2(-3, -7), Vector2(0, -11), Vector2(3, -7), Vector2(3, -1)])
	draw_colored_polygon(hood, Color(Pal.VOID_2, a))
	draw_polyline(hood, Color(Pal.BONE_2, a), 1.0)
	# censer: chain, CHOIR_0 cage with CHOIR_3 bands, a self-lit CHOIR_4 ember inside
	var c := censer_pos()
	draw_line(HAND, c, Color(Pal.BONE_2, a), 1.0)
	var tell := acolyte.tell_frac()
	draw_circle(c, 3.5, Color(Pal.CHOIR_0, a))
	draw_arc(c, 3.5, 0.0, TAU, 12, Color(Pal.CHOIR_3, a), 1.0)
	draw_line(c + Vector2(-3, 0), c + Vector2(3, 0), Color(Pal.CHOIR_3, a), 1.0)
	var ember_a := (0.55 + 0.45 * tell) * life * life
	draw_circle(c, 4.0 + 5.0 * tell, Color(Pal.CHOIR_4, 0.10 * ember_a))
	draw_circle(c, 1.5 + 0.8 * tell, Color(Pal.CHOIR_4, ember_a))
	if tell > 0.6 and life > 0.5:
		draw_rect(Rect2(c - Vector2.ONE * 0.5, Vector2.ONE), Pal.CHOIR_5)
