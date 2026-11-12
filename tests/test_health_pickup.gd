extends GutTest
## Health pickups heal the player and stay put while health is full.

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const SMALL_PICKUP: PackedScene = preload("res://levels/entities/health_small.tscn")
const LARGE_PICKUP: PackedScene = preload("res://levels/entities/health_large.tscn")

var _player: Player
var _health: HealthComponent


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_health = HealthComponent.find_on(_player)


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _spawn(scene: PackedScene) -> HealthPickup:
	var pickup: HealthPickup = scene.instantiate() as HealthPickup
	add_child_autofree(pickup)
	return pickup


func test_stays_while_health_is_full() -> void:
	var pickup: HealthPickup = _spawn(SMALL_PICKUP)
	pickup._on_body_entered(_player)
	assert_false(pickup.is_queued_for_deletion())
	assert_eq(_health.current_health, _health.max_health)


func test_heals_and_is_consumed_when_hurt() -> void:
	_health.set_health(50.0)
	var pickup: HealthPickup = _spawn(SMALL_PICKUP)
	pickup._on_body_entered(_player)
	assert_true(pickup.is_queued_for_deletion())
	assert_eq(_health.current_health, 50.0 + pickup.amount)


func test_large_heals_more_than_small() -> void:
	var small: HealthPickup = _spawn(SMALL_PICKUP)
	var large: HealthPickup = _spawn(LARGE_PICKUP)
	assert_gt(large.amount, small.amount)


func test_healing_is_capped_at_max() -> void:
	_health.set_health(_health.max_health - 1.0)
	var pickup: HealthPickup = _spawn(LARGE_PICKUP)
	pickup._on_body_entered(_player)
	assert_true(pickup.is_queued_for_deletion())
	assert_eq(_health.current_health, _health.max_health)


func test_dead_player_cannot_collect() -> void:
	_health.set_health(0.0)
	var pickup: HealthPickup = _spawn(SMALL_PICKUP)
	pickup._on_body_entered(_player)
	assert_false(pickup.is_queued_for_deletion())
