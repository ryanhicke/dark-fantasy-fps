class_name Level
extends Node3D
## Root script for every playable map scene. Spawns the player at the map's
## info_player_start, restores the carried player state, and tallies kills,
## secrets, and time for the intermission screen.

## FuncGodot puts info_player_start entities in this group at map build.
const PLAYER_START_GROUP: StringName = &"player_start"

@export var player_scene: PackedScene
## Name shown on the intermission screen. Empty uses the root node's name.
@export var display_name: String = ""
## Effects drawn once at load so their first real use doesn't hitch.
@export var prewarm_list: EffectPrewarmList = preload("res://levels/effect_prewarm_list.tres")

var _player: Player
var _stats: LevelStats = LevelStats.new()
var _finished: bool = false


func _ready() -> void:
	_stats.level_name = get_display_name()
	_stats.total_kills = _count_enemies(self)
	# No secret entities exist yet, so total_secrets stays 0.
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.secret_found.connect(_on_secret_found)
	EventBus.level_completed.connect(_on_level_completed)
	_spawn_player()
	_prewarm_effects()


func _physics_process(delta: float) -> void:
	# Pausing (intermission, menus) stops this, so paused time isn't counted.
	if not _finished:
		_stats.time_seconds += delta


func get_display_name() -> String:
	return display_name if not display_name.is_empty() else String(name).capitalize()


func _spawn_player() -> void:
	if player_scene == null:
		push_error("%s: player_scene is not assigned." % name)
		return
	var start: Node3D = _find_player_start()
	_player = player_scene.instantiate() as Player
	add_child(_player)
	# After add_child, so the player's own _ready defaults are overwritten.
	var entry: PlayerState = GameState.get_entry_state()
	if entry != null:
		_player.apply_state(entry)
	if start == null:
		push_warning("%s: no info_player_start in the map; spawning at the origin." % name)
		return
	_player.global_position = start.global_position
	# Yaw only: the player body must stay upright.
	_player.rotation.y = start.global_rotation.y


func _prewarm_effects() -> void:
	if prewarm_list == null or prewarm_list.scenes.is_empty():
		return
	# The player's camera, now that the player is in the tree.
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		push_warning("%s: no active camera; effects not prewarmed." % name)
		return
	EffectPrewarmer.start(camera, prewarm_list.scenes)


func _find_player_start() -> Node3D:
	for node: Node in get_tree().get_nodes_in_group(PLAYER_START_GROUP):
		if is_ancestor_of(node):
			return node as Node3D
	return null


## Runs once at load, so walking the tree here costs nothing per frame.
static func _count_enemies(node: Node) -> int:
	var count: int = 0
	for child: Node in node.get_children():
		if child is Enemy and (child as Enemy).counts_for_stats:
			count += 1
		count += _count_enemies(child)
	return count


func _on_enemy_killed(enemy: Node) -> void:
	var counted: bool = not (enemy is Enemy) or (enemy as Enemy).counts_for_stats
	if counted and is_ancestor_of(enemy):
		_stats.kills += 1


func _on_secret_found() -> void:
	_stats.secrets += 1


func _on_level_completed() -> void:
	if _finished:
		return
	_finished = true
	var exit_state: PlayerState = _player.capture_state() if _player != null else null
	GameState.finish_level(exit_state, _stats)
