class_name TreeLantern
extends Button
## One lamp on the Lantern Tree station (LOOP-001 §3): a brass cage and a glass globe hung from the
## bough. Lit (amber, haloed) once its node is owned; a cold ember when it can be bought; dark when
## locked; a cold unhung cage when the tier is not on sale (the slice's dark lamps, PROD-001 M2); a
## chalk blank in the glass when it waits on a Codex entry (LOOP-001 §3.7). Focus is the 2 px GAS-3
## ring of UI-001 §5 (the lamp cursor). Pure view: the screen sets `node_id` and `state`.

## ✱ lamp hit box (logical px); at least the UI-001 §4 22 px touch-safe height.
const BOX := Vector2(24, 28)

## The node this lamp shows.
var node_id: StringName = &""
## LanternTreeRules state (OWNED, BUYABLE, SHORT, NEEDS_*, NOT_IN_SLICE).
var state: StringName = LanternTreeRules.NEEDS_PREREQ:
	set(v):
		state = v
		queue_redraw()
## Halo breathing phase (seconds); held still when `still` (reduced motion).
var t := 0.0
var still := false


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = BOX
	size = BOX
	add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())   # the lamp draws its own focus ring


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_FOCUS_ENTER, NOTIFICATION_FOCUS_EXIT, NOTIFICATION_MOUSE_ENTER, NOTIFICATION_MOUSE_EXIT:
			queue_redraw()


func is_lit() -> bool:
	return state == LanternTreeRules.OWNED


func tick(delta: float) -> void:
	if still or not is_lit():
		return
	t += delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5 + Vector2(0, 2)
	var cold := state == LanternTreeRules.NOT_IN_SLICE or state == LanternTreeRules.UNWIRED
	var brass := Pal.BONE_0 if cold else (Pal.GAS_3 if is_lit() else Pal.GAS_1)
	if is_lit():
		var breathe := 0.0 if still else 0.06 * sin(t * 2.1)
		draw_circle(c, 13.0, Color(Pal.GAS_2, 0.18 + breathe))
		draw_circle(c, 9.0, Color(Pal.GAS_3, 0.28 + breathe))
	# the hook and the cap
	draw_line(Vector2(c.x, 0), Vector2(c.x, c.y - 10), brass, 1.0)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -10), c + Vector2(4, -10),
		c + Vector2(6, -7), c + Vector2(-6, -7)]), brass)
	# the glass
	var glass := Pal.VOID_1
	match state:
		LanternTreeRules.OWNED:
			glass = Pal.GAS_4
		LanternTreeRules.BUYABLE:
			glass = Pal.VOID_3
		LanternTreeRules.SHORT:
			glass = Pal.VOID_2
		LanternTreeRules.NOT_IN_SLICE, LanternTreeRules.UNWIRED:
			glass = Pal.VOID_0
	var globe := Rect2(c + Vector2(-5, -7), Vector2(10, 13))
	draw_rect(globe, glass)
	if is_lit():
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -4), c + Vector2(2, 1), c + Vector2(0, 3),
			c + Vector2(-2, 1)]), Pal.GAS_5)
	elif state == LanternTreeRules.BUYABLE:
		draw_circle(c + Vector2(0, 2), 1.5, Pal.GAS_2)    # a wick waiting for flame
	elif state == LanternTreeRules.NEEDS_CODEX:
		draw_line(c + Vector2(-3, 2), c + Vector2(3, 2), Pal.BONE_2, 1.0)   # the chalk blank
	# the cage bars and the foot
	for x: float in [-5.0, 0.0, 5.0]:
		draw_line(c + Vector2(x, -7), c + Vector2(x, 6), brass, 1.0)
	draw_line(c + Vector2(-6, 6), c + Vector2(6, 6), brass, 2.0)
	if is_hovered() and not has_focus():
		draw_arc(c, 12.0, 0.0, TAU, 24, Pal.BONE_3, 1.0)
	if has_focus():
		draw_arc(c, 13.0, 0.0, TAU, 28, Pal.GAS_3, 2.0)
