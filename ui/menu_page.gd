class_name MenuPage
extends VBoxContainer
## A vertical list of Buttons navigated with the movement keys: W/S (the
## move_forward/move_back actions) move the highlight and wrap at the ends,
## and Enter (ui_accept) presses the highlighted button.
##
## The highlight is plain keyboard focus, so Godot's Button handles Enter
## and mouse clicks. Arrow keys also work through the focus neighbors set
## here. Only direct Button children are part of the list.

var _buttons: Array[Button] = []


func _ready() -> void:
	for child: Node in get_children():
		var button: Button = child as Button
		if button != null:
			_buttons.append(button)
	_link_focus_neighbors()


func _unhandled_input(event: InputEvent) -> void:
	# Hidden pages share the scene with the visible one; only it may react.
	if not is_visible_in_tree():
		return
	var step: int = 0
	if event.is_action_pressed("move_forward"):
		step = -1
	elif event.is_action_pressed("move_back"):
		step = 1
	if step == 0:
		return
	get_viewport().set_input_as_handled()
	move_focus(step)


func focus_first() -> void:
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


## Moves the highlight [param step] items down (negative is up), wrapping.
func move_focus(step: int) -> void:
	if _buttons.is_empty():
		return
	var current: int = _buttons.find(get_viewport().gui_get_focus_owner() as Button)
	if current < 0:
		focus_first()
		return
	_buttons[wrap_index(current, step, _buttons.size())].grab_focus()


static func wrap_index(current: int, step: int, count: int) -> int:
	if count <= 0:
		return 0
	return posmod(current + step, count)


## Makes the arrow keys wrap the same way W/S do.
func _link_focus_neighbors() -> void:
	var count: int = _buttons.size()
	for i: int in count:
		var button: Button = _buttons[i]
		button.focus_neighbor_top = button.get_path_to(_buttons[wrap_index(i, -1, count)])
		button.focus_neighbor_bottom = button.get_path_to(_buttons[wrap_index(i, 1, count)])
