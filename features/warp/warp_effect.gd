class_name WarpEffect
extends Resource
## One warp effect row (TECH-001 §5.1 `WarpEffect`; WARP-001 §2). Authored content: the id is the
## WARP-001 W-code, the mechanics are the composer's. A WarpEffect never moves a hitbox, a radius or a
## speed (WARP-001 §5.1 "Nothing moves a hitbox"); it only says what to draw, when, and at what cost.

enum Kind { STANDING, TRANSIENT }
## Where the effect draws (TECH-001 §5.1 layers). `audio` effects draw their mandatory visual chant
## indicator on the HUD layer (GDD §10) but are costed as audio.
enum Layer { WORLD, UNITS, HUD, POST, AUDIO }
## What starts it (WARP-001 §2.2 Trigger column).
enum Trigger { TIER_START, FRAYED_BAND, SCHEDULED, FRAYED_CUE }
## WARP-001 §4.2 deviation classes. NONE = not a HUD deviation (world, unit, audio effects).
enum Deviation { NONE, SMEAR, GLYPH, LIE, MOVE, ABSENCE }
## How the effect behaves with photosensitivity / reduced motion on (WARP-001 §4.5): SAME = no
## flicker or motion to remove; STATIC = drawn, but frozen (no animation, no twinkle); OFF = not drawn
## (only legal when another channel carries the same state, WARP-001 §4.6).
enum Variant { SAME, STATIC, OFF }

## WARP-001 W-code, e.g. &"W1-02".
@export var id: StringName = &""
## The tier whose set this row belongs to (WARP-001 §2.x).
@export var tier: int = 1
@export var kind: Kind = Kind.STANDING
@export var layer: Layer = Layer.WORLD
@export var trigger: Trigger = Trigger.TIER_START
@export var deviation: Deviation = Deviation.NONE
## Text key of the effect's name for dev overlays / Codex (never shown raw).
@export var name_key: StringName = &""
## Set when another owner already draws the effect (e.g. `aether_look`: the PM-01 look's
## `warp_effects`). The composer then only checks that owner lists it.
@export var represented_by: StringName = &""
## WARP-001 §5.2 cost fields (ms/frame on min spec) ✱ — budgeted, not measured (TECH-001 §8.5).
@export var ms_standing: float = 0.0
@export var ms_transient: float = 0.0
@export var ms_reduced: float = 0.0
@export var photosensitive_variant: Variant = Variant.SAME
@export var reduced_motion_variant: Variant = Variant.SAME
## GDD §8.7 criterion 1 review checkbox (TECH-001 §5.1 `clip_readable`). Set by review, not code.
@export var clip_readable: bool = false


func is_standing() -> bool:
	return kind == Kind.STANDING


func is_hud_deviation() -> bool:
	return deviation != Deviation.NONE


## A HUD deviation Steady Ledger pins off (WARP-001 §4.4: lies, smears, glyph corruption, moves).
## An Absence keeps its chalk frame, so it is not pinned here (§4.4 "Eaten elements").
func pinned_by_steady_ledger() -> bool:
	return deviation in [Deviation.SMEAR, Deviation.GLYPH, Deviation.LIE, Deviation.MOVE]


## Cost of the effect while live: the reduced variant when `reduced`, else its class's cost.
func cost_ms(reduced: bool = false) -> float:
	if reduced:
		return ms_reduced
	return ms_standing if is_standing() else ms_transient
