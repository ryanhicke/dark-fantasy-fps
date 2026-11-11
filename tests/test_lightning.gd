extends GutTest
## Lightning (docs/weapons.md): instant hit, the only thing that hurts the
## unsealed great demon, and its pickup appears only once it is unsealed.

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const LIGHTNING: SpellData = preload("res://spells/lightning/lightning.tres")
const BANDIT_SCENE: PackedScene = preload("res://enemies/bandit/bandit.tscn")
const FINAL_DEMON: EnemyData = preload("res://enemies/great_demon/great_demon_final.tres")
const LIGHTNING_PICKUP: PackedScene = preload("res://levels/entities/weapon_lightning.tscn")
const SETTLE_FRAMES: int = 3

var _arena: Node3D


func before_each() -> void:
	_arena = Node3D.new()
	add_child_autofree(_arena)


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_lightning_has_real_stats() -> void:
	assert_eq(LIGHTNING.damage_type, Damage.Type.LIGHTNING)
	assert_gt(LIGHTNING.damage, 0.0)
	assert_gt(LIGHTNING.ammo_cost, 0)
	assert_gt(LIGHTNING.hitscan_range, 0.0)
	assert_null(LIGHTNING.projectile_scene, "instant hit, no projectile")


## With a full 100 mana the final phase must be winnable.
func test_full_mana_kills_the_unsealed_demon() -> void:
	var casts: int = floori(100.0 / LIGHTNING.ammo_cost)
	assert_gte(casts * LIGHTNING.damage, FINAL_DEMON.max_health)


func test_cast_hits_the_enemy_in_the_crosshair() -> void:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	_arena.add_child(player)
	var bandit: Enemy = BANDIT_SCENE.instantiate() as Enemy
	_arena.add_child(bandit)
	# The player looks down -Z from its start.
	bandit.global_position = Vector3(0.0, 0.0, -8.0)
	await wait_physics_frames(SETTLE_FRAMES)
	var wand: SpellWeapon = null
	for child: Node in player.get_node("Head/Camera3D/WeaponHolder").get_children():
		if child is SpellWeapon and (child as SpellWeapon).data == LIGHTNING:
			wand = child as SpellWeapon
	wand._is_drawn = true
	wand.set_trigger(true)
	wand._physics_process(1.0 / 60.0)
	var health: HealthComponent = HealthComponent.find_on(bandit)
	assert_lt(health.current_health, health.max_health)


func test_pickup_hidden_until_the_demon_is_unsealed() -> void:
	var pickup: WeaponPickup = LIGHTNING_PICKUP.instantiate() as WeaponPickup
	_arena.add_child(pickup)
	await wait_physics_frames(SETTLE_FRAMES)
	assert_false(pickup.visible)
	assert_false(pickup.monitoring)
	EventBus.great_demon_unsealed.emit()
	await wait_physics_frames(SETTLE_FRAMES)
	assert_true(pickup.visible)
	assert_true(pickup.monitoring)


func test_final_obelisk_unseals() -> void:
	var demon: Enemy = (load("res://enemies/great_demon/great_demon.tscn") as PackedScene).instantiate() as Enemy
	_arena.add_child(demon)
	await wait_physics_frames(SETTLE_FRAMES)
	watch_signals(EventBus)
	var phases: GreatDemonPhases = demon.get_node("Phases") as GreatDemonPhases
	for i: int in phases.obelisk_count - 1:
		phases.on_obelisk_destroyed()
	assert_signal_not_emitted(EventBus, "great_demon_unsealed")
	phases.on_obelisk_destroyed()
	assert_signal_emitted(EventBus, "great_demon_unsealed")
