class_name LanternTreeScreen
extends Screen
## The Lantern Tree station in the Ruins (LOOP-001 §3; Q-T326): a lamp-lit brass tree pushed on the
## Ruins' ScreenStack. Five boughs (the branches, LOOP-001 §3.1), lamps hung by tier (tier 1 low,
## tier 2 above), chains for the hard prerequisites. Owned lamps burn; the slice's tier-2 lamps
## hang dark (PROD-001 M2). The plate below names the focused lamp, its one-line effect and the
## honest reason it can or cannot be lit; the Ember readout is the banked Ember, never a lie.
##
## Holds no game state (UI-001 §2): the Ruins passes the tree data, the owned ids and the Ember in,
## and `purchase_confirmed` out after the confirmation plate; it buys (RunSessionCore, one
## `tree_purchase` save) and calls `show_state` with the new values. `ui_cancel` closes.
## Every lamp is focusable (arrow keys / d-pad / stick; explicit neighbours, wrapping), with a
## scene-unique name `Lamp_<BRANCH>_<n>` (its automation id, UI-001 §7).

signal purchase_confirmed(node_id: StringName)

const SCENE_PATH := "res://features/lantern_tree/lantern_tree_screen.tscn"
## The logical layout space (TECH-001 §1.1); the screen centres it in whatever it is given.
const LOGICAL := Vector2(640, 360)
## ✱ layout, logical px inside LOGICAL: branch centres, bough heights and lamp rows per tier.
const BRANCH_X0 := 72.0
const BRANCH_DX := 124.0
const BOUGH_Y: Array[float] = [0.0, 212.0, 116.0]   ## by tier (index 0 unused)
const LAMP_Y: Array[float] = [0.0, 244.0, 148.0]
const LAMP_DX: Array[float] = [0.0, 28.0, 40.0]
const BRANCH_LABEL_Y := 266.0
## ✱ face sizes (cap height, logical px) at text scale 1.
const READOUT_SIZE := 9.0
const BRANCH_SIZE := 5.0
const NAME_SIZE := 7.5
const BODY_SIZE := 5.5
## Branch name keys, in LanternTreeData.BRANCHES order.
const BRANCH_KEYS: Array[StringName] = [&"RUINS_TREE_BRANCH_LANTERN", &"RUINS_TREE_BRANCH_HULL",
	&"RUINS_TREE_BRANCH_ORDNANCE", &"RUINS_TREE_BRANCH_WARD", &"RUINS_TREE_BRANCH_MADNESS"]

var tree: LanternTreeData
var owned: Array[StringName] = []
var ember := 0
## Stamped Codex entry ids (the profile's Codex record, Q-T350), set by the Ruins before the push.
var known: Array[StringName] = []

## id -> TreeLantern
var lamps: Dictionary = {}
var _rows: Dictionary = {}          # tier -> Array[TreeLantern], left to right
var _shown: StringName = &""
var _k := 1.0
var _area := Rect2(Vector2.ZERO, LOGICAL)
var _plate_top := 284.0
var _still := false
var _ember_label: VectorLabel
var _name: VectorLabel
var _fx: VectorLabel
var _status: VectorLabel
var _branch_labels: Array[VectorLabel] = []


static func create(p_tree: LanternTreeData, p_owned: Array[StringName], p_ember: int) -> LanternTreeScreen:
	var s := (load(SCENE_PATH) as PackedScene).instantiate() as LanternTreeScreen
	s.tree = p_tree
	s.owned = p_owned.duplicate()
	s.ember = p_ember
	return s


## The 640×360 logical rect centred in `c`'s own rect (the whole rect when it has no size yet).
static func logical_area(c: Control) -> Rect2:
	var s := c.size
	if s.x <= 0.0 or s.y <= 0.0:
		s = LOGICAL
	return Rect2(((s - LOGICAL) * 0.5).max(Vector2.ZERO), LOGICAL)


func _ready() -> void:
	_k = clampf(float(SettingsService.get_value(&"text_scale")), 1.0, 2.0)
	_still = bool(SettingsService.get_value(&"reduced_motion"))
	_area = logical_area(self)
	_build_labels()
	_build_lamps()
	_link_focus()
	_refresh()
	var first := LanternTreeRules.suggested(tree, owned, ember, known)
	default_focus = lamps.get(first) as Control
	_show(first)
	super()


## New owner values after a purchase (or any change): re-reads every lamp and the plate.
func show_state(p_owned: Array[StringName], p_ember: int) -> void:
	owned = p_owned.duplicate()
	ember = p_ember
	_refresh()


## The node the plate describes (the focused or hovered lamp).
func shown_id() -> StringName:
	return _shown


func state_of(id: StringName) -> StringName:
	return LanternTreeRules.state_of(tree, id, owned, ember, known)


# --- build ----------------------------------------------------------------------------------------

func _face(cap: float, stroke: float) -> VectorFace:
	return VectorText.default_face().duplicate_with(cap * _k, stroke * _k)


func _label(n: String, face: VectorFace, col: Color, align: VectorText.Align) -> VectorLabel:
	var l := VectorLabel.new()
	l.name = n
	l.face = face
	l.color = col
	l.alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _build_labels() -> void:
	var o := _area.position
	# No title: the tree is the place itself, and its name arrives in the Codex (LOOP-001 §10.5.3).
	# phosphor = truth (ART-001 role law): the Ember count is the banked value, never a lie
	_ember_label = _label("Ember", _face(READOUT_SIZE, 1.1), Pal.PHOS_4, VectorText.Align.RIGHT)
	_ember_label.position = o + Vector2(324, 10)
	_ember_label.size = Vector2(300, _ember_label.get_combined_minimum_size().y)
	for b in LanternTreeData.BRANCHES.size():
		var l := _label("Branch_%s" % LanternTreeData.BRANCHES[b], _face(BRANCH_SIZE, 0.8), Pal.BONE_2,
			VectorText.Align.CENTER)
		l.key = BRANCH_KEYS[b]
		l.size = Vector2(BRANCH_DX - 4.0, l.get_combined_minimum_size().y)
		l.position = o + Vector2(_branch_x(b) - l.size.x * 0.5, BRANCH_LABEL_Y)
		_branch_labels.append(l)
	_name = _label("NodeName", _face(NAME_SIZE, 1.0), Pal.BONE_5, VectorText.Align.LEFT)
	_fx = _label("NodeEffect", _face(BODY_SIZE, 0.85), Pal.BONE_3, VectorText.Align.LEFT)
	_status = _label("NodeStatus", _face(BODY_SIZE, 0.85), Pal.GAS_4, VectorText.Align.LEFT)
	for l: VectorLabel in [_name, _fx, _status]:
		l.max_width = LOGICAL.x - 40.0


func _branch_x(b: int) -> float:
	return BRANCH_X0 + BRANCH_DX * float(b)


func _build_lamps() -> void:
	for b in LanternTreeData.BRANCHES.size():
		var by_tier := {}
		for n in tree.nodes_in(LanternTreeData.BRANCHES[b]):
			if n.tier < 1 or n.tier >= LAMP_Y.size():
				continue   # this layout hangs tiers 1–2 only (the M2 stub)
			if not by_tier.has(n.tier):
				by_tier[n.tier] = []
			(by_tier[n.tier] as Array).append(n)
		for tier: int in by_tier:
			var list: Array = by_tier[tier]
			for i in list.size():
				var n: LanternTreeNode = list[i]
				var lamp := TreeLantern.new()
				lamp.name = "Lamp_%s" % String(n.id).replace("-", "_")
				lamp.node_id = n.id
				lamp.still = _still
				var dx := (float(i) - float(list.size() - 1) * 0.5) * float(LAMP_DX[tier])
				lamp.position = _area.position + Vector2(_branch_x(b) + dx, float(LAMP_Y[tier])) - TreeLantern.BOX * 0.5
				add_child(lamp)
				lamp.owner = self
				lamp.unique_name_in_owner = true
				lamp.pressed.connect(_on_lamp_pressed.bind(n.id))
				lamp.focus_entered.connect(_show.bind(n.id))
				lamp.mouse_entered.connect(_show.bind(n.id))
				lamps[n.id] = lamp
				if not _rows.has(tier):
					_rows[tier] = []
				(_rows[tier] as Array).append(lamp)
	for tier: int in _rows:
		(_rows[tier] as Array).sort_custom(func(a: TreeLantern, c: TreeLantern) -> bool: return a.position.x < c.position.x)


## Explicit neighbours (UI-001 §4): left/right along a tier row, wrapping; up/down to the nearest
## lamp of the next tier row, wrapping from the top row to the bottom one.
func _link_focus() -> void:
	var tiers: Array = _rows.keys()
	tiers.sort()
	for ti in tiers.size():
		var row: Array = _rows[tiers[ti]]
		var above: Array = _rows[tiers[(ti + 1) % tiers.size()]]
		var below: Array = _rows[tiers[(ti - 1 + tiers.size()) % tiers.size()]]
		for i in row.size():
			var lamp: TreeLantern = row[i]
			var left: TreeLantern = row[(i - 1 + row.size()) % row.size()]
			var right: TreeLantern = row[(i + 1) % row.size()]
			lamp.focus_neighbor_left = lamp.get_path_to(left)
			lamp.focus_neighbor_right = lamp.get_path_to(right)
			lamp.focus_previous = lamp.get_path_to(left)
			lamp.focus_next = lamp.get_path_to(right)
			lamp.focus_neighbor_top = lamp.get_path_to(_nearest(above, lamp.position.x))
			lamp.focus_neighbor_bottom = lamp.get_path_to(_nearest(below, lamp.position.x))


static func _nearest(row: Array, x: float) -> TreeLantern:
	var best: TreeLantern = row[0]
	for l: TreeLantern in row:
		if absf(l.position.x - x) < absf(best.position.x - x):
			best = l
	return best


# --- state ----------------------------------------------------------------------------------------

func _refresh() -> void:
	for id: StringName in lamps:
		(lamps[id] as TreeLantern).state = state_of(id)
	_ember_label.text = tr("RUINS_TREE_EMBER").format({"n": ember})
	if _shown != &"":
		_show(_shown)
	queue_redraw()


## Fill the plate for one node: name, effect line, and the honest state line.
func _show(id: StringName) -> void:
	var n := tree.get_node_def(id)
	if n == null:
		return
	_shown = id
	_name.text = tr(n.name_key)
	_fx.text = tr(n.effect_key)
	var st := state_of(id)
	_status.text = status_text(n, st)
	_status.color = Pal.GAS_4 if st == LanternTreeRules.BUYABLE or st == LanternTreeRules.OWNED else Pal.BONE_2
	_layout_plate()


## The plate's state line for a node in state `st` (all tr() keys, L10N-001).
func status_text(n: LanternTreeNode, st: StringName) -> String:
	var cost := tree.price_of(n)
	match st:
		LanternTreeRules.OWNED:
			return tr("RUINS_TREE_STATE_OWNED")
		LanternTreeRules.BUYABLE:
			return tr("RUINS_TREE_STATE_BUY").format({"cost": cost})
		LanternTreeRules.SHORT:
			return tr("RUINS_TREE_STATE_SHORT").format({"cost": cost, "ember": ember})
		LanternTreeRules.NEEDS_PREREQ:
			var names := PackedStringArray()
			for r in n.requires:
				var p := tree.get_node_def(StringName(r))
				if p != null and not owned.has(p.id):
					names.append(tr(p.name_key))
			return tr("RUINS_TREE_STATE_PREREQ").format({"names": ", ".join(names)})
		LanternTreeRules.NEEDS_TIER:
			return tr("RUINS_TREE_STATE_TIER").format({"n": tree.gate_for_tier(n.tier)})
		LanternTreeRules.NEEDS_CODEX:
			return tr("RUINS_TREE_STATE_CODEX")
		LanternTreeRules.NOT_IN_SLICE:
			return tr("RUINS_TREE_STATE_DARK")
		LanternTreeRules.UNWIRED:
			return tr("RUINS_TREE_STATE_UNWIRED")
	return ""


## Stack the plate's three lines up from the bottom of the logical area (grows upward at 200 %).
func _layout_plate() -> void:
	var o := _area.position
	var y := LOGICAL.y - 10.0
	for l: VectorLabel in [_status, _fx, _name]:
		var h := l.get_combined_minimum_size().y
		y -= h
		l.position = o + Vector2(20, y)
		l.size = Vector2(LOGICAL.x - 40.0, h)
		y -= 5.0
	_plate_top = y - 3.0
	queue_redraw()


func _on_lamp_pressed(id: StringName) -> void:
	_show(id)
	if state_of(id) != LanternTreeRules.BUYABLE or stack == null:
		return
	var n := tree.get_node_def(id)
	var confirm := LanternTreeConfirm.create(tr(n.name_key), tree.price_of(n), ember)
	confirm.confirmed.connect(func() -> void: purchase_confirmed.emit(id))
	stack.push(confirm)


func _process(delta: float) -> void:
	for id: StringName in lamps:
		(lamps[id] as TreeLantern).tick(delta)


# --- the tree itself (drawn under the lamps and the labels) ---------------------------------------

func _draw() -> void:
	var o := _area.position
	# ✱ the hall stays faintly visible behind the tree, too dim for its chalk to compete
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.VOID_0, 0.95))
	# the trunk, rising from the floor to the low bough
	var trunk := PackedVector2Array([o + Vector2(312, LOGICAL.y), o + Vector2(316, 260), o + Vector2(320, BOUGH_Y[1])])
	draw_polyline(trunk, Pal.GAS_0, 9.0)
	draw_polyline(trunk, Pal.GAS_1, 5.0)
	for b in LanternTreeData.BRANCHES.size():
		var cx := _branch_x(b)
		var branch := LanternTreeData.BRANCHES[b]
		var t2_open := tree.max_tier_on_sale >= 2
		# the low bough: a sagging arm from the trunk out to the branch, then across its lamps
		var root := o + Vector2(320, BOUGH_Y[1])
		var arm := o + Vector2(cx, BOUGH_Y[1] - 6.0)
		draw_polyline(_sag(root, arm, 8.0), Pal.GAS_1, 3.0)
		draw_line(o + Vector2(cx - 52, BOUGH_Y[1]), o + Vector2(cx + 52, BOUGH_Y[1]), Pal.GAS_1, 3.0)
		# the high bough (tier 2): brass where it is on sale, bone-dark where it is not grown yet
		var col := Pal.GAS_1 if t2_open else Pal.BONE_0
		draw_line(o + Vector2(cx, BOUGH_Y[1]), o + Vector2(cx, BOUGH_Y[2]), col, 2.0)
		draw_line(o + Vector2(cx - 34, BOUGH_Y[2]), o + Vector2(cx + 34, BOUGH_Y[2]), col, 2.0)
		for n in tree.nodes_in(branch):
			var lamp := lamps.get(n.id) as TreeLantern
			if lamp == null:
				continue
			var top := lamp.position + Vector2(TreeLantern.BOX.x * 0.5, 0)
			draw_line(Vector2(top.x, o.y + BOUGH_Y[n.tier]), top, Pal.BONE_1, 1.0)   # its hook chain
			for r in n.requires:
				var from := lamps.get(StringName(r)) as TreeLantern
				if from != null:
					_chain(from.position + TreeLantern.BOX * 0.5, lamp.position + TreeLantern.BOX * 0.5,
						Pal.GAS_3 if owned.has(StringName(r)) else Pal.BONE_1)
	# the plate under the focused lamp's words
	var plate := Rect2(o + Vector2(10, _plate_top), Vector2(LOGICAL.x - 20.0, LOGICAL.y - 4.0 - _plate_top))
	draw_rect(plate, Color(Pal.VOID_1, 0.94))
	draw_rect(plate, Pal.BONE_1, false, 1.0)


## A sagging bough between two points (a shallow parabola).
static func _sag(a: Vector2, b: Vector2, depth: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		pts.append(a.lerp(b, t) + Vector2(0, depth * 4.0 * t * (1.0 - t)))
	return pts


## A prerequisite chain: brass links from one lamp to the next.
func _chain(a: Vector2, b: Vector2, col: Color) -> void:
	var steps := maxi(2, int(a.distance_to(b) / 5.0))
	for i in steps + 1:
		draw_circle(a.lerp(b, float(i) / float(steps)), 1.0, col)
