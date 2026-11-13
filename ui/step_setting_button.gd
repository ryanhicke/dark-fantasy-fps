class_name StepSettingButton
extends Button
## Options row for a stepped number in Settings (field of view or mouse
## sensitivity). Works like VolumeButton: left/right (A/D or the arrow keys)
## step it down or up; Enter or a click steps it up and wraps from the
## maximum back to the minimum.

enum Setting { FOV, MOUSE_SENSITIVITY }

## Which Settings value this row controls.
@export var setting: Setting = Setting.FOV
## Row name, e.g. "Field of View" shows as "Field of View: 75".
@export var label: String = "Setting"


func _ready() -> void:
	pressed.connect(_on_pressed)
	match setting:
		Setting.FOV:
			Settings.fov_changed.connect(_refresh)
		Setting.MOUSE_SENSITIVITY:
			Settings.mouse_sensitivity_changed.connect(_refresh)
	_refresh(_value())


func _gui_input(event: InputEvent) -> void:
	var direction: int = 0
	if event.is_action_pressed(&"move_left", true) or event.is_action_pressed(&"ui_left", true):
		direction = -1
	elif event.is_action_pressed(&"move_right", true) or event.is_action_pressed(&"ui_right", true):
		direction = 1
	if direction == 0:
		return
	# Accepted, so left/right never move the highlight off this row.
	accept_event()
	_set_value(_value() + direction * step_of(setting))
	AudioManager.play_ui(AudioManager.sounds.menu_move)


## E.g. "Field of View: 75" or "Mouse Sensitivity: 100%".
static func label_for(row_label: String, row_setting: Setting, value: int) -> String:
	if row_setting == Setting.MOUSE_SENSITIVITY:
		return "%s: %d%%" % [row_label, value]
	return "%s: %d" % [row_label, value]


## The value after Enter: one step up, wrapping from the maximum to the minimum.
static func next_on_press(value: int, minimum: int, maximum: int, step: int) -> int:
	if value >= maximum:
		return minimum
	return mini(value + step, maximum)


static func step_of(row_setting: Setting) -> int:
	if row_setting == Setting.MOUSE_SENSITIVITY:
		return Settings.MOUSE_SENSITIVITY_STEP
	return Settings.FOV_STEP


func _on_pressed() -> void:
	if setting == Setting.MOUSE_SENSITIVITY:
		_set_value(next_on_press(
			_value(), Settings.MIN_MOUSE_SENSITIVITY, Settings.MAX_MOUSE_SENSITIVITY,
			Settings.MOUSE_SENSITIVITY_STEP
		))
	else:
		_set_value(next_on_press(_value(), Settings.MIN_FOV, Settings.MAX_FOV, Settings.FOV_STEP))


func _value() -> int:
	if setting == Setting.MOUSE_SENSITIVITY:
		return Settings.mouse_sensitivity
	return Settings.fov


func _set_value(value: int) -> void:
	if setting == Setting.MOUSE_SENSITIVITY:
		Settings.set_mouse_sensitivity(value)
	else:
		Settings.set_fov(value)


func _refresh(value: int) -> void:
	text = label_for(label, setting, value)
