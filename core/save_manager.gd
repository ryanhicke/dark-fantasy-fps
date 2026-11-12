extends Node
## Quicksave (F5) and quickload (F9): one slot, the current level plus the
## player state bundle. Levels are never revisited, so nothing else persists.
##
## Saving asks the current Level for its state and GameState for progress.
## Loading reloads that level from scratch and lets it apply the saved state
## once built (see Level._apply_save), which is far less fragile than
## rewinding a running level.
##
## Process mode is inherited, so F5/F9 do nothing while the tree is paused
## (intermission). F9 also works from the main menu.

const SAVE_PATH: String = "user://quicksave.sav"
const MESSAGE_SAVED: String = "Game saved"
const MESSAGE_LOADED: String = "Game loaded"
const MESSAGE_CANNOT_SAVE: String = "You can't save now"
const MESSAGE_NO_SAVE: String = "No quicksave to load"

## Set by the Level while one is loaded.
var current_level: Level
## Tests point this elsewhere.
var save_path: String = SAVE_PATH


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quicksave"):
		get_viewport().set_input_as_handled()
		EventBus.hud_message_requested.emit(MESSAGE_SAVED if quicksave() else MESSAGE_CANNOT_SAVE)
	elif event.is_action_pressed("quickload"):
		get_viewport().set_input_as_handled()
		if not quickload():
			EventBus.hud_message_requested.emit(MESSAGE_NO_SAVE)


func has_quicksave() -> bool:
	return not SaveSnapshot.read(save_path).is_empty()


## Returns false when there is nothing to save (no level, dead, exiting) or
## the file couldn't be written.
func quicksave() -> bool:
	if current_level == null or not current_level.can_save():
		return false
	var snapshot: Dictionary = SaveSnapshot.make(GameState.capture_save(), current_level.capture_save())
	var result: Error = SaveSnapshot.write(save_path, snapshot)
	if result != OK:
		push_warning("SaveManager: could not write %s (%s)." % [save_path, error_string(result)])
		return false
	return true


## Returns false when there is no usable save. The level loads deferred, so
## "Game loaded" is shown once it has.
func quickload() -> bool:
	var snapshot: Dictionary = SaveSnapshot.read(save_path)
	if snapshot.is_empty():
		return false
	if not GameState.load_save(snapshot[SaveSnapshot.KEY_GAME], snapshot[SaveSnapshot.KEY_LEVEL]):
		return false
	# Paused only if loading from a paused state; levels run unpaused.
	get_tree().paused = false
	EventBus.hud_message_requested.emit(MESSAGE_LOADED)
	return true
