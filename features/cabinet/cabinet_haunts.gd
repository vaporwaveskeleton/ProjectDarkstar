class_name CabinetHaunts
extends Node
## W0-12 Hauntings (WARP-001 T0; TECH-001 Q-T250–Q-T259, PM under owner direction 2026-11-19 overnight push).
## The machine was always watching: from a0_3 on, at moments when nothing is being played, something small
## about the costume is wrong for a moment, rarely, never the same way twice in a visit, and never anything
## the player can prove. One node serves the shift (CabinetGame) and attract (AttractMode); each scene wires
## the parts it has and asks `moment(m)` at its moments. CabinetHauntDeck decides (seeded, once per kind).
##
## Rules (tests: features/cabinet/tests/test_cabinet_haunts.gd):
## - costume only (W0-11): never the HUD strip, never a role register, never a readout, never timing or a
##   hitbox; nothing happens during play (READY cards, stage-end holds, attract and the demo only);
## - not a lie (WARP-001 §4.2): no readout changes; the honour roll's stranger is an extra row, yours is honest;
## - no flash, no startle (D-15): the figure is one dim field, the litany dips stay under 3 per second, every
##   sound fades in; photosensitivity / reduced motion drop the moving kinds (CabinetHauntDeck.MOVING);
## - the Decay is not haunted: it has its own escalation (Q-T260) and subtracts only (NARR-001 §4.5).

signal haunted(kind: StringName)       ## a Haunting began (automation and captures; EVT-001 row)

@export var tuning: CabinetHauntTuning
var deck: CabinetHauntDeck
var hum: CabinetHum
var screen: CabinetHauntScreen          ## the arcade screen layer (figure, after-image)
var marquee: CanvasItem                 ## the backlit sign (litany)
var pages: AttractPages                 ## attract only (stranger)
var ghost_button: ArcadeButton          ## attract only (ghost press)
var rig: Control                        ## where the ember glow is drawn (rig units)
var enabled := false                    ## the scene decides: a0_3 reached (attract) or the stage's wear level
var last_kind := &""
var _litany_t := -1.0
var _ember: _Ember


func _ready() -> void:
	if tuning == null:
		tuning = load("res://data/cabinet/cabinet_haunt.tres") as CabinetHauntTuning
	if deck == null:
		deck = CabinetHauntDeck.for_scene(ArcadeButton.is_still())


## Find the marquee under `root` (the bezel builds it at runtime). Null when the scene has none.
static func find_marquee(root: Node) -> CanvasItem:
	if root is BezelMarquee:
		return root as CanvasItem
	for c in root.get_children():
		var m := find_marquee(c)
		if m != null:
			return m
	return null


## Ask the deck at `moment` and perform what it draws (if enabled). Returns the kind, or &"".
func moment(m: StringName) -> StringName:
	if not enabled or deck == null:
		return &""
	var k := deck.draw(m)
	if k != &"":
		perform(k)
	return k


## Perform one Haunting now (the deck already chose it, or a test / capture asks for it).
func perform(kind: StringName) -> void:
	last_kind = kind
	match kind:
		CabinetHauntDeck.FIGURE:
			if screen != null:
				screen.show_figure()
		CabinetHauntDeck.AFTER_IMAGE:
			if screen != null:
				screen.show_after_image()
		CabinetHauntDeck.BREATH:
			if hum != null:
				hum.breathe()
		CabinetHauntDeck.LITANY:
			_litany_t = 0.0
		CabinetHauntDeck.STRANGER:
			if pages != null:
				pages.show_stranger()
		CabinetHauntDeck.GHOST_PRESS:
			if ghost_button != null:
				ghost_button.ghost_press(tuning.ghost_press_s)
		CabinetHauntDeck.SOUR_JINGLE:
			AudioService.play(&"haunt_jingle")
		CabinetHauntDeck.WARM_COIN:
			_warm_coin()
	haunted.emit(kind)


## Stop everything at once (the reveal, a scene change).
func stop_all() -> void:
	_litany_t = -1.0
	_set_marquee_dim(0.0)
	if screen != null:
		screen.clear()
	if _ember != null:
		_ember.t = -1.0


func is_litany_running() -> bool:
	return _litany_t >= 0.0


func _process(delta: float) -> void:
	if _litany_t >= 0.0:
		_litany_t += delta
		if _litany_t >= tuning.litany_s():
			_litany_t = -1.0
			_set_marquee_dim(0.0)
		else:
			_set_marquee_dim(tuning.litany_dim(_litany_t))


func _set_marquee_dim(d: float) -> void:
	if marquee != null:
		var v := 1.0 - d
		marquee.modulate = Color(v, v, v, 1.0)


func _warm_coin() -> void:
	AudioService.play(&"haunt_coin_return")
	if rig == null:
		return
	if _ember == null:
		_ember = _Ember.new()
		_ember.name = "WarmCoin"
		_ember.tuning = tuning
		rig.add_child(_ember)
	_ember.t = 0.0


## The coin return glowing like an ember after the second coin drops into it, then cooling (no flash:
## it rises over 0.4 s and fades over the rest). Additive GAS amber, the lantern's warm (ART-001 §15).
class _Ember extends Control:
	const RET := Vector2(31.0, 67.0)       ## the return pocket, coin-plate local (coin_door.gdshader RET_C)
	var tuning: CabinetHauntTuning
	var t := -1.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

	func strength() -> float:
		if t < 0.0:
			return 0.0
		var rise := clampf(t / 0.4, 0.0, 1.0)
		return rise * clampf(1.0 - (t - 0.4) / maxf(tuning.warm_coin_s - 0.4, 0.01), 0.0, 1.0)

	func _process(delta: float) -> void:
		if t >= 0.0:
			t += delta
			if t >= tuning.warm_coin_s:
				t = -1.0
			queue_redraw()

	func _draw() -> void:
		var k := strength()
		if k <= 0.0:
			return
		var c := CabinetBezel.coin_plate().position + RET
		for i in 6:
			var r := 9.0 - i * 1.4
			var col := Pal.GAS_2.lerp(Pal.GAS_4, i / 5.0)
			draw_circle(c, r, Color(col.r, col.g, col.b, 0.16 * k))
