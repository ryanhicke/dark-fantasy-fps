extends CanvasLayer
## Welcome screen: New Game, Options, Exit. Main decides what New Game and
## Exit do; this screen only reports the choice.
##
## Runs with process_mode ALWAYS so it works whatever the pause state is.

signal new_game_selected
signal exit_selected

@onready var _main_page: MenuPage = $MainPage
@onready var _options_page: OptionsMenu = $OptionsMenu
@onready var _new_game_button: Button = $MainPage/NewGameButton
@onready var _options_button: Button = $MainPage/OptionsButton
@onready var _exit_button: Button = $MainPage/ExitButton


func _ready() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_options_button.pressed.connect(_show_page.bind(_options_page))
	_exit_button.pressed.connect(exit_selected.emit)
	_options_page.back_selected.connect(_on_options_back)


func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
