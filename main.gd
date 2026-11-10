extends Node
## Entry scene. Instances the starting level under LevelRoot and reloads it
## when the player respawns.
##
## Temporary: once GameState owns the LevelList and level loading, this will
## defer to it instead of using a hard-coded starting scene.

@export var start_level: PackedScene

var _level: Node

@onready var _level_root: Node = $LevelRoot


func _ready() -> void:
	if start_level == null:
		push_error("Main: start_level is not assigned.")
		return
	EventBus.player_respawn_requested.connect(_on_player_respawn_requested)
	_load_level()


func _load_level() -> void:
	if _level != null:
		# Remove before freeing so the old level's player and camera are gone
		# before the new ones enter the tree.
		_level_root.remove_child(_level)
		_level.queue_free()
	_level = start_level.instantiate()
	_level_root.add_child(_level)


func _on_player_respawn_requested() -> void:
	# Deferred: the request arrives mid input handling.
	_load_level.call_deferred()
