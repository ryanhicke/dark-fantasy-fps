extends CanvasLayer
## Welcome screen: New Game, Options, Exit. Main decides what New Game and
## Exit do; this screen only reports the choice.
##
## DEV ONLY: debug builds also list the enemy gallery and the great demon
## arena, played on their own outside the level list. Release builds never
## show them. Remove once everything is playtested.
##
## Runs with process_mode ALWAYS so it works whatever the pause state is.

signal new_game_selected
signal exit_selected
## DEV ONLY: play [param scene_path] on its own (see GameState.start_single_level).
signal dev_level_selected(scene_path: String)

@export_file("*.tscn") var enemy_gallery_path: String = "res://levels/enemy_gallery.tscn"
@export_file("*.tscn") var great_demon_arena_path: String = "res://levels/great_demon_arena.tscn"
## Looping menu track. Empty fades out whatever the last level was playing.
@export var music: AudioStream

@onready var _main_page: MenuPage = $MainPage
@onready var _options_page: OptionsMenu = $OptionsMenu
@onready var _new_game_button: Button = $MainPage/NewGameButton
@onready var _options_button: Button = $MainPage/OptionsButton
@onready var _exit_button: Button = $MainPage/ExitButton
@onready var _gallery_button: Button = $MainPage/GalleryButton
@onready var _arena_button: Button = $MainPage/ArenaButton


func _ready() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_options_button.pressed.connect(_show_page.bind(_options_page))
	_exit_button.pressed.connect(exit_selected.emit)
	_options_page.back_selected.connect(_on_options_back)
	_setup_dev_buttons()


func _setup_dev_buttons() -> void:
	var show_dev: bool = OS.is_debug_build()
	_gallery_button.visible = show_dev
	_arena_button.visible = show_dev
	_main_page.refresh_buttons()
	if not show_dev:
		return
	_gallery_button.pressed.connect(_on_dev_level_pressed.bind(enemy_gallery_path))
	_arena_button.pressed.connect(_on_dev_level_pressed.bind(great_demon_arena_path))


func _on_dev_level_pressed(scene_path: String) -> void:
	close()
	dev_level_selected.emit(scene_path)


func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_music(music)
	_show_page(_main_page)


func close() -> void:
	visible = false
	# Hidden pages ignore W/S, so gameplay movement never moves the menu.
	_main_page.visible = false
	_options_page.visible = false


func _show_page(page: MenuPage) -> void:
	_main_page.visible = page == _main_page
	_options_page.visible = page == _options_page
	# Deferred: focus can only be grabbed once the page is visible.
	page.focus_first.call_deferred()


func _on_new_game_pressed() -> void:
	close()
	new_game_selected.emit()


func _on_options_back() -> void:
	_show_page(_main_page)
	# Return the highlight to Options, where the player left.
	_options_button.grab_focus.call_deferred()
