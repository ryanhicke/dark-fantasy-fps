extends GutTest
## End to end on a real level: quicksave, change things, quickload, and the
## saved state comes back. Drives the real autoloads and Main.

const MAIN_SCENE: PackedScene = preload("res://main.tscn")
const PATH: String = "user://test_quicksave_integration.sav"
## Frames for a deferred level load plus the deferred state apply.
const LOAD_FRAMES: int = 6

var _main: Node
var _old_path: String


func before_each() -> void:
	_old_path = SaveManager.save_path
	SaveManager.save_path = PATH
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	GameState.start_game(0)
	await wait_process_frames(LOAD_FRAMES)


func after_each() -> void:
	SaveManager.save_path = _old_path
	_main.queue_free()
	await wait_process_frames(2)
	get_tree().paused = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func _player() -> Player:
	return get_tree().get_first_node_in_group(Player.GROUP) as Player


func test_player_position_health_and_keys_come_back() -> void:
	var player: Player = _player()
	assert_not_null(player)
	player.global_position += Vector3(1.0, 0.0, 0.5)
	var saved_position: Vector3 = player.global_position
	(player.get_node("KeyRing") as KeyRing).add_key(KeyRing.KeyType.SILVER)
	(player.get_node("HealthComponent") as HealthComponent).set_health(37.0)
	assert_true(SaveManager.quicksave())

	player.global_position += Vector3(10.0, 0.0, 0.0)
	(player.get_node("HealthComponent") as HealthComponent).set_health(90.0)
	assert_true(SaveManager.quickload())
	await wait_process_frames(LOAD_FRAMES)

	var loaded: Player = _player()
	assert_ne(loaded, player, "the level was reloaded")
	assert_almost_eq(loaded.global_position, saved_position, Vector3.ONE * 0.2)
	assert_eq((loaded.get_node("HealthComponent") as HealthComponent).current_health, 37.0)
	assert_true((loaded.get_node("KeyRing") as KeyRing).has_key(KeyRing.KeyType.SILVER))


func test_cannot_save_while_dead() -> void:
	var player: Player = _player()
	(player.get_node("HealthComponent") as HealthComponent).take_damage(9999.0, Damage.Type.SLASH, null)
	assert_false(SaveManager.quicksave())


func test_level_8_boss_fight_round_trip() -> void:
	GameState.start_game(7)
	await wait_process_frames(LOAD_FRAMES)
	var demon: Enemy = get_tree().get_first_node_in_group(ExitTrigger.BOSS_GROUP) as Enemy
	assert_not_null(demon)
	var phases: GreatDemonPhases = demon.get_node("Phases") as GreatDemonPhases
	demon.wake()
	phases.on_obelisk_destroyed()
	await wait_process_frames(LOAD_FRAMES)
	assert_true(SaveManager.quicksave())
	assert_true(SaveManager.quickload())
	await wait_process_frames(LOAD_FRAMES)
	var loaded: Enemy = get_tree().get_first_node_in_group(ExitTrigger.BOSS_GROUP) as Enemy
	assert_ne(loaded, demon, "the level was reloaded")
	assert_eq((loaded.get_node("Phases") as GreatDemonPhases).obelisks_destroyed, 1)
