class_name CabinetHud
extends Control
## The Act 0 costume around the field (WARP-001 W0-01, W0-04): the plain print field and the two printed
## columns flush against the screen hole (BezelField, BezelPrint, drawn behind this control) and the
## coin door. It lives on the cabinet Rig, outside the arcade screen (so the CRT never touches it): the
## bezel is a real object, not a CRT image. It carries no readouts: score, Vigils, scanner, HI, lamps and
## the Sepulchre count are lit on the screen's HUD strip (CabinetScreenHud), to which this node forwards
## every value so the game keeps one place to set them. `peel` 0 → 1 slides the costume away
## (W0-07/W0-08); `eaten` 0 → 1 lets the Unmaking swallow the readouts.

@export var screen_hud: CabinetScreenHud
@export var field: BezelField
@export var light_source: SubViewport   ## the arcade screen's SubViewport: ScreenLight reads its average colour

var score := 0:
	set(v):
		score = v
		if screen_hud != null:
			screen_hud.score = v
var hi_score := 0:
	set(v):
		hi_score = v
		if screen_hud != null:
			screen_hud.hi_score = v
var lives := 3:
	set(v):
		lives = v
		if screen_hud != null:
			screen_hud.lives = v
var charges := 0:
	set(v):
		charges = v
		if screen_hud != null:
			screen_hud.charges = v
var magazine := 5:
	set(v):
		magazine = v
		if screen_hud != null:
			screen_hud.magazine = v
var world: ArcadeWorld:
	set(v):
		world = v
		if screen_hud != null:
			screen_hud.world = v
var eaten := 0.0:
	set(v):
		eaten = v
		if screen_hud != null:
			screen_hud.eaten = v
var peel := 0.0:
	set(v):
		peel = v
		if _left != null:
			_left.peel = v
			_right.peel = v
		if _glass != null:
			_glass.peel = v
		for part in _parts:
			part.visible = v < 1.0
		if field != null:
			field.peel = v
		if screen_hud != null:
			screen_hud.peel = v
var crack := 0.0:
	set(v):
		crack = v
		if _left != null:
			_left.crack = v
			_right.crack = v
var _left: BezelPrint
var _right: BezelPrint
var _door: CoinDoorFace
var _rocker: PowerRocker
var _glass: BezelGlass
var _parts: Array[Control] = []
var _tube: ScreenTube
var _text_cache: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_left = _make_print(&"left")
	_right = _make_print(&"right")
	_door = CoinDoorFace.new()
	add_child(_door)
	_door.fit_to(_door_plate())
	_parts = BezelAssembly.add_sheet_parts(self, get_parent() as ScreenRig)
	_glass = BezelGlass.new()
	_glass.rig = get_parent() as ScreenRig
	add_child(_glass)
	_glass.peel = peel
	_tube = BezelAssembly.add_tube(self)
	BezelAssembly.add_light(self, light_source)
	var rocker_out: Array = []
	_parts.append(ControlPanel.add_decorative(self, rocker_out))   # after the glass, like the attract panel; decoration only
	_rocker = rocker_out[0] as PowerRocker
	_left.peel = peel
	_right.peel = peel
	_left.crack = crack
	_right.crack = crack
	if field != null:
		field.peel = peel
	if screen_hud != null:
		screen_hud.world = world
		screen_hud.score = score
		screen_hud.hi_score = hi_score
		screen_hud.lives = lives
		screen_hud.charges = charges
		screen_hud.magazine = magazine
		screen_hud.eaten = eaten
		screen_hud.peel = peel


func _make_print(column: StringName) -> BezelPrint:
	var p := BezelPrint.new()
	p.column = column
	add_child(p)
	return p


func _process(_delta: float) -> void:
	queue_redraw()
	if _door != null:
		_door.visible = peel < 1.0
		_door.fit_to(_door_plate())
	if _rocker != null:
		_rocker.visible = peel < 1.0
		_rocker.position = CabinetBezel.power_rocker().position + Vector2(peel * (CabinetBezel.SIDE + 20.0), 0.0)


## The coin door rides the right column as it peels away.
func _door_plate() -> Rect2:
	var plate := CabinetBezel.coin_plate()
	plate.position.x += peel * (CabinetBezel.SIDE + 20.0)
	return plate


func _draw() -> void:
	if peel >= 1.0:
		return
	CabinetBezel.draw_price(self, _text_cache, _door_plate(), tr("CAB_COIN_PRICE"))
