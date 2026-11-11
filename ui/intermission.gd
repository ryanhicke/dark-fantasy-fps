extends CanvasLayer
## Between-levels stats screen: kills, secrets, and time. Pauses the game
## while shown; confirming moves GameState on to the next level.
##
## Runs with process_mode ALWAYS so it still takes input while paused.

## Seconds before the prompt appears and input is accepted, so a key held
## while walking into the exit (e.g. jump on Space) doesn't skip the screen.
@export var input_delay: float = 0.75

var _accepting_input: bool = false

@onready var _title_label: Label = $Panel/Stats/TitleLabel
@onready var _kills_label: Label = $Panel/Stats/KillsLabel
@onready var _secrets_label: Label = $Panel/Stats/SecretsLabel
@onready var _time_label: Label = $Panel/Stats/TimeLabel
@onready var _prompt_label: Label = $Panel/Stats/PromptLabel


func _ready() -> void:
	visible = false
	GameState.level_finished.connect(_on_level_finished)


func _unhandled_input(event: InputEvent) -> void:
	if not _accepting_input or not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	_accepting_input = false
	visible = false
	get_tree().paused = false
	GameState.advance_to_next_level()


func _on_level_finished(stats: LevelStats, is_final: bool) -> void:
	_title_label.text = "%s Complete" % stats.level_name
	_kills_label.text = "Kills: %d / %d" % [stats.kills, stats.total_kills]
	_secrets_label.text = "Secrets: %d / %d" % [stats.secrets, stats.total_secrets]
	_time_label.text = "Time: %s" % LevelStats.format_time(stats.time_seconds)
	_prompt_label.text = (
		"The End. Press Enter to return to the menu" if is_final else "Press Enter to continue"
	)
	_prompt_label.visible = false
	_accepting_input = false
	visible = true
	get_tree().paused = true
	# Timers from create_timer run while paused by default.
	await get_tree().create_timer(input_delay).timeout
	_prompt_label.visible = true
	_accepting_input = true
