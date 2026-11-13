extends CanvasLayer
## Welcome screen: New Game, Options, Exit. New Game opens the skill page,
## and picking a skill there starts the run. Main decides what that and Exit
## do; this screen only reports the choice.
##
## DEV ONLY: debug builds also list the enemy gallery and the great demon
## arena, played on their own outside the level list. Release builds never
## show them. Remove once everything is playtested.
##
## Runs with process_mode ALWAYS so it works whatever the pause state is.

signal new_game_selected(difficulty: Difficulty.Skill)
signal exit_selected
## DEV ONLY: play [param scene_path] on its own (see GameState.start_single_level).
signal dev_level_selected(scene_path: String)

@export_file("*.tscn") var enemy_gallery_path: String = "res://levels/enemy_gallery.tscn"
@export_file("*.tscn") var great_demon_arena_path: String = "res://levels/great_demon_arena.tscn"
## Looping menu track. Empty fades out whatever the last level was playing.
@export var music: AudioStream

@onready var _main_page: MenuPage = $MainPage
@onready var _options_page: OptionsMenu = $OptionsMenu
@onready var _skill_page: MenuPage = $SkillPage
@onready var _skill_description: Label = $SkillPage/DescriptionLabel
@onready var _skill_back_button: Button = $SkillPage/BackButton
## Skill rows by Difficulty.Skill.
@onready var _skill_buttons: Dictionary[Difficulty.Skill, Button] = {
	Difficulty.Skill.EASY: $SkillPage/EasyButton,
	Difficulty.Skill.NORMAL: $SkillPage/NormalButton,
	Difficulty.Skill.HARD: $SkillPage/HardButton,
}
@onready var _new_game_button: Button = $MainPage/NewGameButton
@onready var _options_button: Button = $MainPage/OptionsButton
@onready var _exit_button: Button = $MainPage/ExitButton
@onready var _gallery_button: Button = $MainPage/GalleryButton
@onready var _arena_button: Button = $MainPage/ArenaButton


func _ready() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_setup_skill_page()
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
	_skill_page.visible = false


func _show_page(page: MenuPage) -> void:
	_main_page.visible = page == _main_page
	_options_page.visible = page == _options_page
	_skill_page.visible = page == _skill_page
	# Deferred: focus can only be grabbed once the page is visible.
	page.focus_first.call_deferred()


func _setup_skill_page() -> void:
	_skill_page.back_button = _skill_back_button
	_skill_back_button.pressed.connect(_on_skill_back)
	_skill_back_button.focus_entered.connect(_skill_description.set_text.bind(""))
	for level: Difficulty.Skill in _skill_buttons:
		var button: Button = _skill_buttons[level]
		button.text = Difficulty.title(level)
		button.pressed.connect(_on_skill_pressed.bind(level))
		# The titles are jokes, so the highlighted one is spelled out below.
		button.focus_entered.connect(
			_skill_description.set_text.bind(Difficulty.description(level))
		)


func _on_new_game_pressed() -> void:
	_show_page(_skill_page)
	# Queued after _show_page's focus_first, so the default skill wins.
	_skill_buttons[Difficulty.DEFAULT].grab_focus.call_deferred()


func _on_skill_pressed(level: Difficulty.Skill) -> void:
	close()
	new_game_selected.emit(level)


func _on_skill_back() -> void:
	_show_page(_main_page)
	_new_game_button.grab_focus.call_deferred()


func _on_options_back() -> void:
	_show_page(_main_page)
	# Return the highlight to Options, where the player left.
	_options_button.grab_focus.call_deferred()
