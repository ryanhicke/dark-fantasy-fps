extends Node
## Entry scene. Opens on the main menu; New Game starts the run through
## GameState, and Main swaps level scenes under LevelRoot whenever GameState
## asks for one. Finishing the final level returns to the menu.
##
## LevelRoot and the HUD live inside GameView so they render at the low
## internal resolution. The menus stay outside it so they're always crisp.

## Level New Game starts from, always with a pistol start. Change it in the
## inspector to jump straight to a later level while testing.
@export var start_level_index: int = 0
## Set by a Level that was run on its own (F6): skip the menu and play just
## that scene, so it gets the HUD and the low-resolution view.
var standalone_level_path: String = ""

var _level: Node

@onready var _game_view: GameView = $GameView
@onready var _level_root: Node = $GameView/SubViewport/LevelRoot
@onready var _main_menu: CanvasLayer = $MainMenu


func _ready() -> void:
	GameState.level_load_requested.connect(_on_level_load_requested)
	GameState.game_completed.connect(_show_main_menu)
	_main_menu.new_game_selected.connect(_on_new_game_selected)
	_main_menu.exit_selected.connect(_on_exit_selected)
	if not standalone_level_path.is_empty():
		# The menu scene starts visible; hide it or it covers the level and
		# its New Game would start the normal run instead.
		_main_menu.close()
		_play_single_level(standalone_level_path)
		return
	_show_main_menu()


func _show_main_menu() -> void:
	_unload_level()
	# Hidden, the GameView stops rendering and forwarding input.
	_game_view.visible = false
	_main_menu.open()


func _on_new_game_selected() -> void:
	_game_view.visible = true
	GameState.start_game(start_level_index)


## Plays one scene outside the level list (dev levels). Its exit returns
## to the menu.
func _play_single_level(scene_path: String) -> void:
	_game_view.visible = true
	GameState.start_single_level(scene_path)


func _on_exit_selected() -> void:
	get_tree().quit()


func _on_level_load_requested(scene_path: String) -> void:
	# Deferred: requests arrive mid input handling or physics callbacks.
	_load_level.call_deferred(scene_path)


func _load_level(scene_path: String) -> void:
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("Main: could not load level '%s'." % scene_path)
		return
	_unload_level()
	_level = scene.instantiate()
	_level_root.add_child(_level)


func _unload_level() -> void:
	if _level == null:
		return
	# Remove before freeing so the old level's player and camera are gone
	# before the new ones enter the tree.
	_level_root.remove_child(_level)
	_level.queue_free()
	_level = null
