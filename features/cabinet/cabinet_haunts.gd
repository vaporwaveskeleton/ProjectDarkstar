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
var _crag: _CragFigure
var crag_spot := SUMMIT                 ## where the next crag figure stands (the planted early one: SLOPE, once)

const SUMMIT := &"summit"
const SLOPE := &"slope"
## The early crag figure's printed place (PM 2026-11-20, Fable review item 10): right column, column-local, a gap
## in the Choir's procession on the crag's rim (between the 4th and 5th monk), feet on the rect's bottom edge.
const CRAG_SLOPE_STAND := Rect2(105.0, 196.0, 10.0, 22.0)


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
		CabinetHauntDeck.CRAG_FIGURE:
			_crag_figure()
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
	if _crag != null:
		_crag.frames = 0
		_crag.queue_redraw()


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


## Find the arcade backdrop under `root` (#101 builds it with the bezel). Null when the scene has none.
static func find_backdrop(root: Node) -> CanvasItem:
	if root is ArcadeBackdrop:
		return root as CanvasItem
	for c in root.get_children():
		var b := find_backdrop(c)
		if b != null:
			return b
	return null


## Where the crag figure stands, in rig units, feet on the bottom edge: SUMMIT is the bezel art's `figure` anchor
## (#101); SLOPE is the early, planted place in the procession. Rect2() when the art has no `figure` anchor (then
## the Haunting does nothing, at either place).
static func crag_anchor(spot: StringName = SUMMIT) -> Rect2:
	var a: Dictionary = BezelArt.haunt_anchors()
	var v: Variant = a.get(&"figure", Rect2())
	var summit := v as Rect2 if v is Rect2 else Rect2()
	if spot == SLOPE and summit.size.y > 0.0:
		return CabinetBezel.to_screen(BezelArt.R, CRAG_SLOPE_STAND)
	return summit


## Plant the early crag figure (PM 2026-11-20): the next moment that offers the crag figure shows it, at the
## SLOPE, whatever the odds. Once: the deck spends the kind, so a later crag figure in this visit never comes,
## and the summit one is left to the rare attract draw. Under photosensitivity / reduced motion nothing happens
## (the deck never offers a moving kind).
func plant_crag_slope() -> void:
	if deck == null or deck.still or deck.used(CabinetHauntDeck.CRAG_FIGURE):
		return
	crag_spot = SLOPE
	deck.plant(CabinetHauntDeck.CRAG_FIGURE)


func _crag_figure(frames: int = -1, spot: StringName = &"") -> void:
	var at := crag_spot if spot == &"" else spot
	crag_spot = SUMMIT                   # the slope is planted once; after it, only ever the summit
	if rig == null or crag_anchor(at).size.y <= 0.0:
		return
	if _crag == null:
		_crag = _CragFigure.new()
		_crag.name = "CragFigure"
		_crag.tuning = tuning
		rig.add_child(_crag)
	_crag.spot = at
	_crag.frames = tuning.figure_frames if frames < 0 else frames
	_crag.queue_redraw()


## Dev captures only (AttractMode showcase): hold the crag figure for `frames` fields so a still can catch it.
func show_crag_for_still(frames: int, spot: StringName = SUMMIT) -> void:
	_crag_figure(frames, spot)


## W0-12 crag_figure (TECH-001 Q-T261, PM ruling 2026-11-19 overnight push): for ONE field the side art has one
## more figure in it, standing on the crag summit against the moon in the print's own key black, as if it had
## always been printed there; the next field it never was. Featureless (never a face, N4). A one-field change,
## so it is a moving kind: never under photosensitivity or reduced motion (CabinetHauntDeck.MOVING).
class _CragFigure extends Control:
	var tuning: CabinetHauntTuning
	var frames := 0
	var spot := CabinetHaunts.SUMMIT

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func ink() -> float:
		return 1.0 if frames > 0 else 0.0

	func _process(_delta: float) -> void:
		if frames > 0:
			queue_redraw()

	func _draw() -> void:
		if frames <= 0:
			return
		frames -= 1
		var r := CabinetHaunts.crag_anchor(spot)
		var inks := BezelInks.default() as BezelInks
		var c := inks.key_black
		c.a *= 0.92
		draw_colored_polygon(CabinetHauntScreen.figure_at(Vector2(r.get_center().x, r.end.y), r.size.y), c)
		if frames == 0:
			queue_redraw.call_deferred()   # the next field draws nothing: exactly the asked number of fields
