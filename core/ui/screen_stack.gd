class_name ScreenStack
extends CanvasLayer
## Narrowly scoped modal navigation for ONE scene (attract, sector...). Not an autoload.
## push() covers the current top, pop() removes it and restores focus to the screen beneath.

signal screen_pushed(screen: Screen)
signal screen_popped(screen: Screen)
signal emptied

## Screen that sits under the stack (e.g. the attract menu). Gets focus back when the stack empties.
@export var base_screen: Screen
## The menus' costume on this stack (MenuSkin.for_node): Auto follows the fidelity ladder (Look.t); the
## Aether scenes (sector, Ruins) name Brass, so their Pause and Settings wear the brass HUD style.
@export_enum("Auto", "Cabinet", "Brass") var costume: int = 0

var _screens: Array[Screen] = []


func push(screen: Screen) -> Screen:
	var below := top()
	if below:
		below.remember_focus()
	elif base_screen:
		base_screen.remember_focus()
	if base_screen:
		base_screen.set_process_unhandled_input(false)   # only the top screen answers ui_cancel
	screen.stack = self
	_screens.append(screen)
	add_child(screen)
	screen_pushed.emit(screen)
	return screen


func pop(screen: Screen = null) -> void:
	if _screens.is_empty():
		return
	var s: Screen = screen if screen else _screens.back()
	if s != _screens.back():
		push_warning("ScreenStack: popping a screen that is not on top")
	_screens.erase(s)
	s.closed.emit()
	s.queue_free()
	screen_popped.emit(s)
	var t := top()
	if t:
		t.focus_entered_screen()
	else:
		if base_screen:
			base_screen.set_process_unhandled_input(true)
			base_screen.focus_entered_screen()
		emptied.emit()


func top() -> Screen:
	return null if _screens.is_empty() else _screens.back()


func depth() -> int:
	return _screens.size()


func is_empty() -> bool:
	return _screens.is_empty()
