class_name LanternTreeConfirm
extends Screen
## The Tree station's purchase confirmation (Q-T326): a brass plate over the tree asking to light one
## lamp, with the honest price and the Ember before and after. Two choices; the default focus is
## the safe one ("Not yet", UI-001 §3), so a mashed accept never spends. `ui_cancel` = Not yet.
## Holds no game state: the Tree screen fills it and listens for `confirmed`.

signal confirmed

const SCENE_PATH := "res://features/lantern_tree/lantern_tree_confirm.tscn"
## ✱ plate width (logical px) and the face sizes at text scale 1.
const PLATE_W := 340.0
const TITLE_SIZE := 8.0
const BODY_SIZE := 5.5

## Shown values, set before the screen enters the tree.
var node_name := ""
var price := 0
var ember := 0

var _title: VectorLabel
var _body: VectorLabel
var _light: ChalkButton
var _keep: ChalkButton
var _plate := Rect2()


static func create(p_name: String, p_price: int, p_ember: int) -> LanternTreeConfirm:
	var s := (load(SCENE_PATH) as PackedScene).instantiate() as LanternTreeConfirm
	s.node_name = p_name
	s.price = p_price
	s.ember = p_ember
	return s


func _ready() -> void:
	var k := clampf(float(SettingsService.get_value(&"text_scale")), 1.0, 2.0)
	var base := VectorText.default_face()
	_title = _label("Title", base.duplicate_with(TITLE_SIZE * k, 1.0 * k), Pal.GAS_4)
	_title.key = &"RUINS_TREE_CONFIRM_TITLE"
	_body = _label("Body", base.duplicate_with(BODY_SIZE * k, 0.85 * k), Pal.BONE_4)
	_body.text = tr("RUINS_TREE_CONFIRM_BODY").format({"name": node_name, "cost": price, "ember": ember,
		"after": ember - price})
	_light = _button("ConfirmLight", &"RUINS_TREE_CONFIRM_YES", k)
	_keep = _button("ConfirmKeep", &"RUINS_TREE_CONFIRM_NO", k)
	_light.focus_neighbor_left = _light.get_path_to(_keep)
	_light.focus_neighbor_right = _light.get_path_to(_keep)
	_light.focus_neighbor_top = _light.get_path_to(_light)
	_light.focus_neighbor_bottom = _light.get_path_to(_light)
	_keep.focus_neighbor_left = _keep.get_path_to(_light)
	_keep.focus_neighbor_right = _keep.get_path_to(_light)
	_keep.focus_neighbor_top = _keep.get_path_to(_keep)
	_keep.focus_neighbor_bottom = _keep.get_path_to(_keep)
	_light.focus_next = _light.get_path_to(_keep)
	_light.focus_previous = _light.get_path_to(_keep)
	_keep.focus_next = _keep.get_path_to(_light)
	_keep.focus_previous = _keep.get_path_to(_light)
	_light.pressed.connect(_on_light)
	_keep.pressed.connect(cancel)
	default_focus = _keep
	_layout(k)
	super()


func _label(n: String, face: VectorFace, col: Color) -> VectorLabel:
	var l := VectorLabel.new()
	l.name = n
	l.face = face
	l.color = col
	l.alignment = VectorText.Align.CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _button(n: String, key: StringName, k: float) -> ChalkButton:
	var b := ChalkButton.new()
	b.name = n
	add_child(b)
	b.owner = self
	b.unique_name_in_owner = true
	b.setup(key, k)
	return b


## Centre the plate in the 640×360 logical rect; it grows with the text and stays inside.
func _layout(k: float) -> void:
	var w := minf(PLATE_W * k, 620.0)
	_body.max_width = w - 24.0
	var th := _title.get_combined_minimum_size().y
	var bh := _body.get_combined_minimum_size().y
	var btn_h := maxf(_light.size.y, _keep.size.y)
	var h := 14.0 + th + 8.0 + bh + 12.0 + btn_h + 14.0
	var area := LanternTreeScreen.logical_area(self)
	_plate = Rect2(area.position + (area.size - Vector2(w, h)) * 0.5, Vector2(w, h))
	var y := _plate.position.y + 14.0
	_title.position = Vector2(_plate.position.x, y)
	_title.size = Vector2(w, th)
	y += th + 8.0
	_body.position = Vector2(_plate.position.x + 12.0, y)
	_body.size = Vector2(w - 24.0, bh)
	y += bh + 12.0
	var gap := 16.0
	var total := _light.size.x + gap + _keep.size.x
	var x := _plate.position.x + (w - total) * 0.5
	_light.position = Vector2(x, y)
	_keep.position = Vector2(x + _light.size.x + gap, y)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.VOID_0, 0.55))
	draw_rect(_plate.grow(3.0), Pal.GAS_1)
	draw_rect(_plate, Pal.VOID_1)
	draw_rect(_plate.grow(-4.0), Pal.GAS_2, false, 1.0)


func _on_light() -> void:
	_light.disabled = true   # repeated input: one purchase per plate (UI-001 §4)
	confirmed.emit()
	close()
