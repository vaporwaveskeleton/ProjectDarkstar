class_name HudModel
extends RefCounted
## HudModel (TECH-001 §5.2, §5.4): the truth the HUD reads, sampled from world state every tick.
## No warp code may write to it. Built so far: the Ledger Compass slice only (M1).
##
## Honesty seam: the drawing code reads `presented()`, never the world. With `SettingsService`
## `steady_ledger` on (the default, WARP-001 §4.4) that is this honest model, always. With it off,
## the state passes through `lie_hook()`, the place where `HudLiar` will plug in later; `HudLiar` is
## not built, so the hook returns the honest state unchanged. The own-position readout never lies
## (WARP-001 §4.7): a lie hook may not change `own_position`.
##
## Entity marker: no entity exists in M1, so `entity_marker_visible` is false and the compass draws
## the entity frame empty (the WARP-001 §4.7 / §3.2 H16 shape: drawn, honestly empty).

const STEADY_LEDGER_KEY := &"steady_ledger"

## True world position of the Vigil (wrapped into the sector when a torus is set).
var own_position: Vector2 = Vector2.ZERO
var has_own_position: bool = false
## True world positions of the compass targets (wrapped), the Vigil first, at most the cap.
var marker_world: PackedVector2Array = PackedVector2Array()
var marker_kinds: Array[StringName] = []
## Always false in M1 (no entity). H16 and PACT-19 will drive it later (WARP-001 §3.2).
var entity_marker_visible: bool = false
## Sector list: a one-cell STUB. No doc specifies a sector entry's fields yet, so the list holds only
## how many cells to draw (1: the current sector). Fields are added when ZONES-001 names them.
var sector_list_cells: int = 1


## Samples the registered compass targets from the tree: the Vigil (group `vigil_group`) first,
## then `ranked` (already rank-ordered) up to `cap` in total. Positions are wrapped by `torus`.
func sample_compass(vigils: Array[Node], ranked: Array[Node], torus: Torus, cap: int) -> void:
	marker_world.resize(0)
	marker_kinds.clear()
	has_own_position = false
	var nodes: Array[Node] = []
	nodes.append_array(vigils)
	nodes.append_array(ranked)
	for n in LedgerCompass.collect(nodes, cap):
		var p := torus.wrap(n.global_position) if torus != null else n.global_position
		var kind := LedgerCompass.kind_of(n)
		if kind == LedgerCompass.KIND_VIGIL and not has_own_position:
			own_position = p
			has_own_position = true
		marker_world.append(p)
		marker_kinds.append(kind)


## What the view may draw. Steady Ledger on: this honest model. Off: the lie hook (honest for now).
func presented() -> HudModel:
	if steady_ledger_on():
		return self
	return lie_hook(self)


## The seam where `HudLiar` (TECH-001 §5.2) will apply lies. Not built: returns the honest state.
static func lie_hook(model: HudModel) -> HudModel:
	return model


static func steady_ledger_on() -> bool:
	var loop := Engine.get_main_loop() as SceneTree
	var svc: Node = loop.root.get_node_or_null(^"SettingsService") if loop else null
	if svc == null:
		return true   # no settings service: the default, which ships ON (WARP-001 §4.4)
	var v: Variant = svc.call(&"get_value", STEADY_LEDGER_KEY)
	return v != false
