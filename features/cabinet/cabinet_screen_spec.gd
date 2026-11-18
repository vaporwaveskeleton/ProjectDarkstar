class_name CabinetScreenSpec
extends TunableResource
## The Act 0 arcade screen's grid (TECH-001 §1.3): the SubViewport size the tube is drawn at.
## ✱ engineering parameter, not a SYS-001 number. 640×360 until the portrait grid lands.

@export var grid: Vector2i = Vector2i(640, 360)   ## ✱ texels (width, height) of the arcade screen


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["grid"])
