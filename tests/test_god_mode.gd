extends GutTest
## The Tab invulnerability cheat (GodMode), on the real player and HUD.

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const HUD_SCENE: PackedScene = preload("res://ui/hud.tscn")
const HIT: float = 30.0

var _player: Player
var _health: HealthComponent
var _god_mode: GodMode


func before_each() -> void:
	GodMode.active = false
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_health = HealthComponent.find_on(_player)
	_god_mode = _player.get_node("GodMode") as GodMode


func after_each() -> void:
	# Static, so it would leak into every later test.
	GodMode.active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _press_tab() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_TAB
	event.pressed = true
	_god_mode._unhandled_input(event)


func test_off_by_default_and_damage_lands() -> void:
	_health.take_damage(HIT, Damage.Type.SLASH, null)
	assert_eq(_health.current_health, _health.max_health - HIT)


func test_tab_blocks_all_damage() -> void:
	_press_tab()
	assert_true(GodMode.active)
	_health.take_damage(HIT, Damage.Type.SLASH, null)
	_health.take_damage(_health.max_health * 10.0, Damage.Type.FIRE, null)
	assert_eq(_health.current_health, _health.max_health)


func test_tab_again_turns_it_off() -> void:
	_press_tab()
	_press_tab()
	assert_false(GodMode.active)
	_health.take_damage(HIT, Damage.Type.SLASH, null)
	assert_eq(_health.current_health, _health.max_health - HIT)


func test_other_keys_do_nothing() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_Q
	event.pressed = true
	_god_mode._unhandled_input(event)
	assert_false(GodMode.active)


func test_armor_spell_ending_leaves_the_cheat_on() -> void:
	_press_tab()
	# What the armor spell does when it wears off.
	_health.invulnerable = false
	_health.take_damage(HIT, Damage.Type.SLASH, null)
	assert_eq(_health.current_health, _health.max_health)


func test_cheat_carries_to_the_next_levels_player() -> void:
	_press_tab()
	var next_player: Player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(next_player)
	var next_health: HealthComponent = HealthComponent.find_on(next_player)
	next_health.take_damage(HIT, Damage.Type.SLASH, null)
	assert_eq(next_health.current_health, next_health.max_health)


func test_hud_shows_cheater_only_while_on() -> void:
	var hud: CanvasLayer = HUD_SCENE.instantiate() as CanvasLayer
	add_child_autofree(hud)
	var label: Label = hud.get_node("CheaterLabel") as Label
	assert_false(label.visible)
	_press_tab()
	assert_true(label.visible)
	assert_eq(label.text, "CHEATER")
	_press_tab()
	assert_false(label.visible)
