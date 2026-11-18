class_name Screen
extends Control
## Base for every full screen and overlay (UI-001 §3).
## - Holds no game state: it reads from services/resources and emits intent signals.
## - Declares one default focus Control (the primary action) and restores focus when re-shown.
## - ui_cancel calls `cancel()`; a Screen that cannot be backed out of overrides it explicitly.

signal closed

## The primary action. Receives focus on open.
@export var default_focus: Control
## If false, ui_cancel does nothing on this screen (e.g. the root attract screen).
@export var cancel_closes: bool = true

var stack: ScreenStack   # set by ScreenStack when pushed; null for route-level screens
var _last_focus: Control


func _ready() -> void:
	focus_entered_screen()


## Focus the remembered control, or the default one.
func focus_entered_screen() -> void:
	var target := _last_focus if is_instance_valid(_last_focus) and _last_focus.is_visible_in_tree() else default_focus
	if target and target.is_inside_tree():
		target.grab_focus.call_deferred()


## Remember focus before another screen covers this one.
func remember_focus() -> void:
	var f := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if f and is_ancestor_of(f):
		_last_focus = f


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or (stack and stack.top() != self):
		return
	if event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		cancel()


## Default back behaviour. Overlays close; route screens override.
func cancel() -> void:
	if cancel_closes:
		close()


func close() -> void:
	if stack:
		stack.pop(self)
	else:
		closed.emit()
		queue_free()
