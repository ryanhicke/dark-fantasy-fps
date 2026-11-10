class_name Level
extends Node3D
## Root script for every playable map scene. Spawns the player at the map's
## info_player_start. Step 6 adds kill/secret/time tracking here.

## FuncGodot puts info_player_start entities in this group at map build.
const PLAYER_START_GROUP: StringName = &"player_start"

@export var player_scene: PackedScene


func _ready() -> void:
	if player_scene == null:
		push_error("%s: player_scene is not assigned." % name)
		return
	var start: Node3D = _find_player_start()
	var player: Node3D = player_scene.instantiate() as Node3D
	add_child(player)
	if start == null:
		push_warning("%s: no info_player_start in the map; spawning at the origin." % name)
		return
	player.global_position = start.global_position
	# Yaw only: the player body must stay upright.
	player.rotation.y = start.global_rotation.y


func _find_player_start() -> Node3D:
	for node: Node in get_tree().get_nodes_in_group(PLAYER_START_GROUP):
		if is_ancestor_of(node):
			return node as Node3D
	return null
