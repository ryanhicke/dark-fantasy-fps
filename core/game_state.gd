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
## Skill level of the current run. Set before start_game; kept across levels
## and restarts, and restored by a quickload.
var difficulty: Difficulty.Skill = Difficulty.DEFAULT

## Bundle the current level was entered with, restored on (re)load. Null
## means pistol start: the player keeps the defaults from player.tscn, so
## starting equipment is defined in one place.
var _entry_state: PlayerState
## Bundle captured at the exit, waiting for the intermission to finish.
var _exit_state: PlayerState
## Set while playing a single scene outside the level list (running a level
## on its own from the editor). Finishing it ends the run.
var _single_level_path: String = ""
## Level half of a quickload, waiting for the level it belongs to.
var _pending_snapshot: Dictionary = {}


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
	_single_level_path = ""
	_entry_state = null
	_exit_state = null
	_pending_snapshot = {}
	_request_load()


## Plays just [param scene_path] with a pistol start, e.g. a dev level run
## on its own from the editor. Its exit ends the run like a final level.
func start_single_level(scene_path: String) -> void:
	_single_level_path = scene_path
	_pending_snapshot = {}
	current_level_index = 0
	_entry_state = null
	_exit_state = null
	_request_load()


## Null means pistol start. Returns a copy so the level can't alter the
## stored bundle.
func get_entry_state() -> PlayerState:
	return _entry_state.copy() if _entry_state != null else null


func is_final_level() -> bool:
	return not _single_level_path.is_empty() or level_list.is_last(current_level_index)


## Called by the level when the player reaches the exit.
func finish_level(exit_state: PlayerState, stats: LevelStats) -> void:
	_exit_state = exit_state.copy() if exit_state != null else null
	level_finished.emit(stats, is_final_level())


## Called when the intermission is dismissed. After the final level this
## ends the run instead of loading anything.
func advance_to_next_level() -> void:
	if is_final_level():
		current_level_index = 0
		_single_level_path = ""
		_entry_state = null
		_exit_state = null
		game_completed.emit()
		return
	current_level_index += 1
	_pending_snapshot = {}
	_entry_state = _exit_state
	_exit_state = null
	_request_load()


## Reloads the current level with the bundle it was entered with, so dying
## undoes anything gained or spent during the failed attempt.
func restart_level() -> void:
	_exit_state = null
	_pending_snapshot = {}
	_request_load()


## Progress half of a quicksave: which level, and the bundle it was entered
## with (so dying after a quickload still restarts the level as entered).
func capture_save() -> Dictionary:
	return {
		"level_index": current_level_index,
		"difficulty": difficulty,
		"single_level_path": _single_level_path,
		"entry_state": _entry_state.to_dict() if _entry_state != null else {},
	}


## Loads the saved level from scratch; it then picks up [param level_snapshot]
## through take_pending_snapshot(). Returns false if the level is gone.
func load_save(game: Dictionary, level_snapshot: Dictionary) -> bool:
	var single_path: String = str(game.get("single_level_path", ""))
	var index: int = int(game.get("level_index", 0))
	if single_path.is_empty() and not level_list.has_level(index):
		push_warning("GameState: saved level %d no longer exists." % index)
		return false
	if not single_path.is_empty() and not ResourceLoader.exists(single_path):
		push_warning("GameState: saved level '%s' no longer exists." % single_path)
		return false
	current_level_index = index
	# Saves from before difficulty existed load as the default.
	difficulty = Difficulty.from_variant(game.get("difficulty"))
	_single_level_path = single_path
	var entry: Variant = game.get("entry_state", {})
	_entry_state = PlayerState.from_dict(entry) if entry is Dictionary and not entry.is_empty() else null
	_exit_state = null
	_pending_snapshot = level_snapshot
	_request_load()
	return true


## Hands the waiting quickload state to the level that just loaded, once.
func take_pending_snapshot() -> Dictionary:
	var snapshot: Dictionary = _pending_snapshot
	_pending_snapshot = {}
	return snapshot


func _request_load() -> void:
	if not _single_level_path.is_empty():
		level_load_requested.emit(_single_level_path)
		return
	level_load_requested.emit(level_list.get_level_path(current_level_index))
