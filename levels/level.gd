class_name Level
extends Node3D
## Root script for every playable map scene. Spawns the player at the map's
## info_player_start, restores the carried player state, and tallies kills,
## secrets, and time for the intermission screen.

## FuncGodot puts info_player_start entities in this group at map build.
const PLAYER_START_GROUP: StringName = &"player_start"
## The game's entry scene. A level run on its own reloads inside it.
const MAIN_SCENE_PATH: String = "res://main.tscn"

@export var player_scene: PackedScene
## Name shown on the intermission screen. Empty uses the root node's name.
@export var display_name: String = ""
## Two to four lines of story shown under the stats when this level ends.
@export_multiline var intermission_text: String = ""
## Shown on its own page after the final intermission. Only the last level
## sets this.
@export_multiline var ending_text: String = ""
## Looping track for this level (tick Loop in the Import dock). Empty fades
## the previous music out.
@export var music: AudioStream
## Effects drawn once at load so their first real use doesn't hitch.
@export var prewarm_list: EffectPrewarmList = preload("res://levels/effect_prewarm_list.tres")

var _player: Player
var _stats: LevelStats = LevelStats.new()
var _finished: bool = false


func _ready() -> void:
	if _is_running_on_its_own():
		_run_inside_main.call_deferred()
		return
	_stats.level_name = get_display_name()
	_stats.story_text = intermission_text
	_stats.ending_text = ending_text
	_stats.total_kills = _count_enemies(self)
	_stats.total_secrets = _count_secrets()
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.secret_found.connect(_on_secret_found)
	EventBus.level_completed.connect(_on_level_completed)
	_spawn_player()
	_prewarm_effects()
	AudioManager.play_music(music)


func _physics_process(delta: float) -> void:
	# Pausing (intermission, menus) stops this, so paused time isn't counted.
	if not _finished:
		_stats.time_seconds += delta


## True when this level was launched directly (Run Current Scene, F6)
## instead of being loaded by Main.
func _is_running_on_its_own() -> bool:
	return get_tree().current_scene == self and not scene_file_path.is_empty()


## Without Main there is no HUD, low-resolution view, or intermission, so
## a level run on its own swaps itself for Main playing just this scene.
func _run_inside_main() -> void:
	var main: Node = (load(MAIN_SCENE_PATH) as PackedScene).instantiate()
	main.set(&"standalone_level_path", scene_file_path)
	var tree: SceneTree = get_tree()
	tree.root.add_child(main)
	tree.current_scene = main
	queue_free()


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


## Only this level's secrets, in case another scene shares the tree.
func _count_secrets() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group(SecretTrigger.SECRET_GROUP):
		if is_ancestor_of(node):
			count += 1
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
