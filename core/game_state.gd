extends Node
## Owns level progression and the player state bundle carried between levels.
##
## Decides which level comes next; Main does the scene-tree work of loading
## it when level_load_requested fires. Levels report back through
## finish_level(), and the intermission screen calls advance_to_next_level().
## Main opens the main menu again on game_completed.

## Main loads [param scene_path] in place of the current level.
signal level_load_requested(scene_path: String)
## The exit was reached. The intermission screen shows [param stats].
signal level_finished(stats: LevelStats, is_final: bool)
## The final level's intermission was dismissed. The run is over.
signal game_completed

const DEFAULT_LEVEL_LIST_PATH: String = "res://levels/level_list.tres"

var level_list: LevelList
var current_level_index: int = 0

## Bundle the current level was entered with, restored on (re)load. Null
## means pistol start: the player keeps the defaults from player.tscn, so
## starting equipment is defined in one place.
var _entry_state: PlayerState
## Bundle captured at the exit, waiting for the intermission to finish.
var _exit_state: PlayerState


func _ready() -> void:
	# Tests assign their own list and never add this node to the tree.
	if level_list == null:
		level_list = load(DEFAULT_LEVEL_LIST_PATH) as LevelList
	EventBus.player_respawn_requested.connect(restart_level)


## Starts a fresh run at [param index] with a pistol start.
func start_game(index: int = 0) -> void:
	if not level_list.has_level(index):
		push_error("GameState: no level at index %d; starting at 0." % index)
		index = 0
	current_level_index = index
	_entry_state = null
	_exit_state = null
	_request_load()


## Null means pistol start. Returns a copy so the level can't alter the
## stored bundle.
func get_entry_state() -> PlayerState:
	return _entry_state.copy() if _entry_state != null else null


func is_final_level() -> bool:
	return level_list.is_last(current_level_index)


## Called by the level when the player reaches the exit.
func finish_level(exit_state: PlayerState, stats: LevelStats) -> void:
	_exit_state = exit_state.copy() if exit_state != null else null
	level_finished.emit(stats, is_final_level())


## Called when the intermission is dismissed. After the final level this
## ends the run instead of loading anything.
func advance_to_next_level() -> void:
	if is_final_level():
		current_level_index = 0
		_entry_state = null
		_exit_state = null
		game_completed.emit()
		return
	current_level_index += 1
	_entry_state = _exit_state
	_exit_state = null
	_request_load()


## Reloads the current level with the bundle it was entered with, so dying
## undoes anything gained or spent during the failed attempt.
func restart_level() -> void:
	_exit_state = null
	_request_load()


func _request_load() -> void:
	level_load_requested.emit(level_list.get_level_path(current_level_index))
