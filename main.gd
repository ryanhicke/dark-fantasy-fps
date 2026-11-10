extends Node
## Entry scene. Starts the run through GameState and swaps level scenes
## under LevelRoot whenever GameState asks for one.

## Level to start from, always with a pistol start. Change it in the
## inspector to jump straight to a later level.
@export var start_level_index: int = 0

var _level: Node

@onready var _level_root: Node = $LevelRoot


func _ready() -> void:
	GameState.level_load_requested.connect(_on_level_load_requested)
	GameState.start_game(start_level_index)


func _on_level_load_requested(scene_path: String) -> void:
	# Deferred: requests arrive mid input handling or physics callbacks.
	_load_level.call_deferred(scene_path)


func _load_level(scene_path: String) -> void:
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("Main: could not load level '%s'." % scene_path)
		return
	if _level != null:
		# Remove before freeing so the old level's player and camera are gone
		# before the new ones enter the tree.
		_level_root.remove_child(_level)
		_level.queue_free()
	_level = scene.instantiate()
	_level_root.add_child(_level)
