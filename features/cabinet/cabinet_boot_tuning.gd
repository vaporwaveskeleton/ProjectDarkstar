class_name CabinetBootTuning
extends TunableResource
## The Cabinet's power-on and attract cycle (WARP-001 W0-01/W0-03; TECH-001 §2.10): the self-test,
## the instruction pages, and the taped coin slot. Every value is ✱ — a first-pass presentation
## timing owned by the cabinet feature, requested as SYS-001 rows in TECH-001 §11.1.

# --- Power-on self-test ---
@export var warmup_seconds: float = 0.4          ## s ✱ the CRT line opening to a full raster
@export var noise_seconds: float = 2.0           ## s ✱ uninitialised video RAM before the test clears it
@export var noise_scroll: float = 90.0           ## px/s ✱ the garbage drifts (a scroll, never a full-field flash; frozen under photosensitivity)
@export var test_line_seconds: float = 0.4       ## s ✱ between self-test lines
@export var test_hold_seconds: float = 1.2       ## s ✱ on "SELF TEST COMPLETE" before attract

# --- Attract pages ---
@export var page_seconds: float = 7.0            ## s ✱ per instruction page

# --- Coin slot ---
@export var tape_hint_delay: float = 5.0         ## s ✱ of attract before the peel / insert prompt appears
@export var tape_hold_seconds: float = 1.5       ## s ✱ holding accept to peel the tape off (gamepad / keys)
@export var tape_drag_px: float = 40.0           ## px ✱ of mouse drag to peel the tape off
@export var tape_fall_seconds: float = 0.7       ## s ✱ the peeled tape falls off the bezel
@export var coin_drop_seconds: float = 0.45      ## s ✱ the coin's travel into the slot

# --- Power switch ---
@export var power_off_seconds: float = 0.5       ## s ✱ the CRT collapse after the player confirms POWER (a plain fade of the same length under photosensitivity / reduced motion)


func tunable_properties() -> PackedStringArray:
	var out := PackedStringArray()
	for p in get_property_list():
		if (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) and p.name != "ds_namespace" and p.name != "source_section":
			out.append(p.name)
	return out
