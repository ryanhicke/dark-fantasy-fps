extends CanvasLayer
## Between-levels stats screen: kills, secrets, time, and a few lines of
## story. Pauses the game while shown; confirming moves GameState on to the
## next level. After the final level an ending page follows the stats.
##
## Runs with process_mode ALWAYS so it still takes input while paused.

## Seconds before the prompt appears and input is accepted, so a key held
## while walking into the exit (e.g. jump on Space) doesn't skip the screen.
@export var input_delay: float = 0.75
## Seconds each counter takes to tally up, Doom-style.
@export var tally_duration: float = 0.6
@export var ending_title: String = "Epilogue"

var _accepting_input: bool = false
var _is_final: bool = false
## Ending page still to show after the stats page; empty when none.
var _pending_ending: String = ""
var _tally: Tween

@onready var _title_label: Label = $Panel/Stats/TitleLabel
@onready var _kills_label: Label = $Panel/Stats/KillsLabel
@onready var _secrets_label: Label = $Panel/Stats/SecretsLabel
@onready var _time_label: Label = $Panel/Stats/TimeLabel
@onready var _story_label: Label = $Panel/Stats/StoryLabel
@onready var _prompt_label: Label = $Panel/Stats/PromptLabel


func _ready() -> void:
	visible = false
	GameState.level_finished.connect(_on_level_finished)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	# The first press during the tally skips it, like Doom's intermission.
	if _tally != null and _tally.is_running():
		_tally.custom_step(INF)
		return
	if not _accepting_input:
		return
	_accepting_input = false
	AudioManager.play_ui(AudioManager.sounds.intermission_continue)
	if not _pending_ending.is_empty():
		var ending: String = _pending_ending
		_pending_ending = ""
		_show_ending(ending)
		return
	visible = false
	get_tree().paused = false
	GameState.advance_to_next_level()


func _on_level_finished(stats: LevelStats, is_final: bool) -> void:
	_is_final = is_final
	_pending_ending = stats.ending_text if is_final else ""
	_title_label.text = "%s Complete" % stats.level_name
	for label: Label in [_kills_label, _secrets_label, _time_label]:
		label.visible = true
	_story_label.text = stats.story_text
	_story_label.visible = not stats.story_text.is_empty()
	_prompt_label.text = _prompt_text()
	_prompt_label.visible = false
	_accepting_input = false
	visible = true
	get_tree().paused = true
	_start_tally(stats)
	await _reveal_prompt_after_delay()


func _start_tally(stats: LevelStats) -> void:
	if _tally != null:
		_tally.kill()
	_set_kills(0, stats)
	_set_secrets(0, stats)
	_set_time(0.0)
	# Tweens made with create_tween stop while paused unless told otherwise.
	_tally = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tally.tween_method(_set_kills.bind(stats), 0, stats.kills, tally_duration)
	_tally.tween_method(_set_secrets.bind(stats), 0, stats.secrets, tally_duration)
	_tally.tween_method(_set_time, 0.0, stats.time_seconds, tally_duration)


func _set_kills(value: int, stats: LevelStats) -> void:
	_kills_label.text = "Kills: %d / %d" % [value, stats.total_kills]


func _set_secrets(value: int, stats: LevelStats) -> void:
	_secrets_label.text = "Secrets: %d / %d" % [value, stats.total_secrets]


func _set_time(value: float) -> void:
	_time_label.text = "Time: %s" % LevelStats.format_time(value)


func _show_ending(text: String) -> void:
	_title_label.text = ending_title
	for label: Label in [_kills_label, _secrets_label, _time_label]:
		label.visible = false
	_story_label.text = text
	_story_label.visible = true
	_prompt_label.text = _prompt_text()
	_prompt_label.visible = false
	await _reveal_prompt_after_delay()


func _prompt_text() -> String:
	if _is_final and _pending_ending.is_empty():
		return "The End. Press Enter to return to the menu"
	return "Press Enter to continue"


func _reveal_prompt_after_delay() -> void:
	# Timers from create_timer run while paused by default.
	await get_tree().create_timer(input_delay).timeout
	_prompt_label.visible = true
	_accepting_input = true
