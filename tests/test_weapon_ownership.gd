extends GutTest
## Weapon ownership, slots, pickups, and the player state bundle, using the
## real player scene.

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const SWORD: WeaponData = preload("res://weapons/sword/sword.tres")
const BOW: WeaponData = preload("res://weapons/bow/bow.tres")
const FIRE_STAFF: WeaponData = preload("res://spells/fireball/fireball.tres")
const BOW_PICKUP: PackedScene = preload("res://levels/entities/weapon_bow.tscn")
const MANA_PICKUP: PackedScene = preload("res://levels/entities/ammo_mana.tscn")
const MANA_CAP: int = 100

var _player: Player
var _holder: WeaponHolder
var _inventory: Inventory


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_holder = _player.get_node("Head/Camera3D/WeaponHolder") as WeaponHolder
	_inventory = _player.get_node("Inventory") as Inventory


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_pistol_start_owns_only_the_sword() -> void:
	assert_eq(_holder.get_owned(), [SWORD.id] as Array[StringName])


func test_weapon_ids_and_slots_are_unique() -> void:
	var ids: Array[StringName] = []
	var slots: Array[int] = []
	for data: WeaponData in _holder.get_all_weapon_data():
		assert_ne(data.id, &"", data.display_name)
		assert_false(ids.has(data.id), "duplicate id %s" % data.id)
		assert_false(slots.has(data.slot), "duplicate slot %d" % data.slot)
		ids.append(data.id)
		slots.append(data.slot)


func test_mana_caps_at_100() -> void:
	assert_eq(_inventory.get_max_ammo(&"mana"), MANA_CAP)


func test_giving_a_weapon_owns_it_and_adds_its_ammo() -> void:
	var arrows_before: int = _inventory.get_ammo(&"arrows")
	assert_true(_player.give_weapon(BOW))
	assert_true(_holder.owns(BOW.id))
	assert_eq(_inventory.get_ammo(&"arrows"), arrows_before + BOW.pickup_ammo)


func test_owned_weapon_with_full_ammo_is_not_taken_again() -> void:
	_player.give_weapon(BOW)
	_inventory.add_ammo(&"arrows", 1000)
	assert_false(_player.give_weapon(BOW))


func test_owned_weapon_still_taken_for_its_ammo() -> void:
	_player.give_weapon(BOW)
	assert_true(_player.give_weapon(BOW), "arrows not full yet")


func test_state_bundle_carries_owned_weapons() -> void:
	_player.give_weapon(FIRE_STAFF)
	var state: PlayerState = _player.capture_state().copy()
	assert_true(state.owned_weapons.has(FIRE_STAFF.id))
	var fresh: Player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(fresh)
	fresh.apply_state(state)
	var fresh_holder: WeaponHolder = fresh.get_node("Head/Camera3D/WeaponHolder") as WeaponHolder
	assert_true(fresh_holder.owns(FIRE_STAFF.id))
	assert_false(fresh_holder.owns(BOW.id))


func test_unknown_ids_are_ignored() -> void:
	_holder.set_owned([&"sword", &"no_such_weapon"] as Array[StringName])
	assert_eq(_holder.get_owned(), [SWORD.id] as Array[StringName])


func test_give_everything_owns_all_and_fills_ammo() -> void:
	_player.give_everything()
	for data: WeaponData in _holder.get_all_weapon_data():
		assert_true(_holder.owns(data.id), data.display_name)
	assert_eq(_inventory.get_ammo(&"mana"), MANA_CAP)


func test_weapon_pickup_is_consumed_and_gives_the_weapon() -> void:
	var pickup: WeaponPickup = BOW_PICKUP.instantiate() as WeaponPickup
	add_child_autofree(pickup)
	pickup._on_body_entered(_player)
	assert_true(_holder.owns(BOW.id))
	assert_true(pickup.is_queued_for_deletion())


func test_ammo_pickup_stays_while_full() -> void:
	var pickup: AmmoPickup = MANA_PICKUP.instantiate() as AmmoPickup
	add_child_autofree(pickup)
	pickup._on_body_entered(_player)
	assert_false(pickup.is_queued_for_deletion(), "mana starts full")
	_inventory.consume_ammo(&"mana", 50)
	pickup._on_body_entered(_player)
	assert_true(pickup.is_queued_for_deletion())
	assert_eq(_inventory.get_ammo(&"mana"), 50 + pickup.amount)
