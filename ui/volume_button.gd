class_name VolumeButton
extends Button
## Options row for one bus volume. Left/right (A/D or the arrow keys) step
## it down or up; Enter or a click steps it up and wraps from 100% to Off,
## so the row also works with only the keys every other menu row uses.

const STEP: int = 10

## Bus in AudioBuses.DEFAULT_VOLUMES that this row controls.
@export var bus: StringName = AudioBuses.MASTER
## Row name, e.g. "Music" shows as "Music: 70%".
@export var label: String = "Volume"


func _ready() -> void:
	pressed.connect(_on_pressed)
	Settings.volume_changed.connect(_on_volume_changed)
	_refresh(Settings.get_volume(bus))


func _gui_input(event: InputEvent) -> void:
	var step: int = 0
	if event.is_action_pressed(&"move_left", true) or event.is_action_pressed(&"ui_left", true):
		step = -STEP
	elif event.is_action_pressed(&"move_right", true) or event.is_action_pressed(&"ui_right", true):
		step = STEP
	if step == 0:
		return
	# Accepted, so left/right never move the highlight off this row.
	accept_event()
	Settings.set_volume(bus, Settings.get_volume(bus) + step)
	# Heard at the new volume, so the player can judge it.
	AudioManager.play_ui(AudioManager.sounds.menu_move)


## E.g. "Music: 70%", or "Music: Off" at 0.
static func label_for(row_label: String, percent: int) -> String:
	if percent <= 0:
		return "%s: Off" % row_label
	return "%s: %d%%" % [row_label, percent]


## The volume after Enter: one step up, wrapping from 100% to 0.
static func next_on_press(percent: int) -> int:
	if percent >= AudioBuses.MAX_PERCENT:
		return 0
	return mini(percent + STEP, AudioBuses.MAX_PERCENT)


func _on_pressed() -> void:
	Settings.set_volume(bus, next_on_press(Settings.get_volume(bus)))


func _on_volume_changed(changed_bus: StringName, percent: int) -> void:
	if changed_bus == bus:
		_refresh(percent)


func _refresh(percent: int) -> void:
	text = label_for(label, percent)
