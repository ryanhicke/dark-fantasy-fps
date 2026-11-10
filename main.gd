extends Node
## Entry scene. Instances the starting level under LevelRoot.
##
## Temporary: once GameState owns the LevelList and level loading, this will
## defer to it instead of using a hard-coded starting scene.

@export var start_level: PackedScene

@onready var _level_root: Node = $LevelRoot


func _ready() -> void:
	if start_level == null:
		push_error("Main: start_level is not assigned.")
		return
	_level_root.add_child(start_level.instantiate())
