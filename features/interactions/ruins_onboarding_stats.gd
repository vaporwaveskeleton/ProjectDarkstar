class_name RuinsOnboardingStats
extends TunableResource
## The first Ruins visit as diegetic onboarding (LOOP-001 §10.5; NARR-001 §5.7). Values live in
## data/interactions/ruins_onboarding.tres (`ds_ruins.onboarding.*`). Every value here is ✱
## engineering: pacing and layout of the scene, never a game rule. No SYS-001 number is copied here.

## ✱ seconds from arrival before the chalk starts to write (after the hall lantern has caught).
@export var chalk_start_s: float = 4.0
## ✱ chalk writing pace, characters per second (any input completes the line: assist X-4/A1).
@export var chalk_chars_per_s: float = 16.0
## ✱ seconds a finished chalk line rests before the next begins.
@export var chalk_line_rest_s: float = 1.1
## ✱ seconds a ticket takes from the Cabinet to the Tree.
@export var ticket_flight_s: float = 1.6
## ✱ seconds between two tickets leaving the Cabinet.
@export var ticket_stagger_s: float = 0.05
## ✱ at most this many tickets are drawn in flight (1 ticket = 1 Ember; the plate shows the total).
@export var tickets_drawn_max: int = 40
## ✱ pilot lamp walking speed (logical px/s).
@export var lamp_speed_px_s: float = 150.0
## ✱ a station is in reach of the pilot lamp within this many px (x distance).
@export var lamp_reach_px: float = 24.0
## ✱ where the pilot lamp first appears (logical x; beside the Chalk Desk).
@export var lamp_start_x: float = 232.0
## ✱ the walkable floor (logical x).
@export var lamp_min_x: float = 104.0
@export var lamp_max_x: float = 600.0
## ✱ with the hangar mouth dark, the pilot lamp gutters and stops here.
@export var dark_threshold_x: float = 476.0
## ✱ the pilot lamp at or past this x, with the mouth lit, launches.
@export var launch_x: float = 520.0
## ✱ seconds of lamp-down in the Ruins before the hidden chalk shows (the beat 15 pre-echo).
@export var dark_reveal_s: float = 1.5


func tunable_properties() -> PackedStringArray:
	return PackedStringArray([
		"chalk_start_s", "chalk_chars_per_s", "chalk_line_rest_s", "ticket_flight_s", "ticket_stagger_s",
		"tickets_drawn_max", "lamp_speed_px_s", "lamp_reach_px", "lamp_start_x", "lamp_min_x", "lamp_max_x",
		"dark_threshold_x", "launch_x", "dark_reveal_s",
	])
