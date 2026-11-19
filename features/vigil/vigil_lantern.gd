class_name VigilLantern
extends Node
## The Vigil's lantern state (up = lit, down = running dark; SYS-001 §1.2). Pure state: the motor
## reads it for the Aether thrust/drag multipliers, the rig draws it. No signal (EVT-001).

var is_up: bool = true


func toggle() -> void:
	is_up = not is_up
