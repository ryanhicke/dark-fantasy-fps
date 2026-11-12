class_name MenuPage
extends VBoxContainer
## A vertical list of Buttons navigated with the movement keys: W/S (the
## move_forward/move_back actions) move the highlight and wrap at the ends,
## and Enter (ui_accept) presses the highlighted button.
##
## The highlight is plain keyboard focus, so Godot's Button handles Enter
## and mouse clicks. Arrow keys also work through the focus neighbors set
## here. Only direct, visible Button children are part of the list; call
## refresh_buttons() after showing or hiding one.
##
## Moving plays GameSounds.menu_move and pressing plays menu_select, or
## menu_back for [member back_button].

## The page's Back row, which plays the back sound instead of select.
var back_button: Button

var _buttons: Array[Button] = []


func _ready() -> void:
	refresh_buttons()


func refresh_buttons() -> void:
	_buttons.clear()
	for child: Node in get_children():
		var button: Button = child as Button
		if button != null and button.visible:
			_buttons.append(button)
		if button != null and not button.pressed.is_connected(_on_button_pressed):
			button.pressed.connect(_on_button_pressed.bind(button))
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
	AudioManager.play_ui(AudioManager.sounds.menu_move)


static func wrap_index(current: int, step: int, count: int) -> int:
	if count <= 0:
		return 0
	return posmod(current + step, count)


func _on_button_pressed(button: Button) -> void:
	var sounds: GameSounds = AudioManager.sounds
	AudioManager.play_ui(sounds.menu_back if button == back_button else sounds.menu_select)


## Makes the arrow keys wrap the same way W/S do.
func _link_focus_neighbors() -> void:
	var count: int = _buttons.size()
	for i: int in count:
		var button: Button = _buttons[i]
		button.focus_neighbor_top = button.get_path_to(_buttons[wrap_index(i, -1, count)])
		button.focus_neighbor_bottom = button.get_path_to(_buttons[wrap_index(i, 1, count)])
