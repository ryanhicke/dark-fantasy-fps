extends GutTest
## Wand of healing and armor spell (docs/weapons.md), on the real player.

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const HEALING: SpellData = preload("res://spells/healing/healing.tres")
const ARMOR: SpellData = preload("res://spells/armor/armor.tres")
const ARMOR_WAIT: float = 0.3
const SETTLE_FRAMES: int = 2

var _player: Player
var _health: HealthComponent
var _inventory: Inventory


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_health = HealthComponent.find_on(_player)
	_inventory = _player.get_node("Inventory") as Inventory


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _wand(spell: SpellData) -> SpellWeapon:
	for child: Node in _player.get_node("Head/Camera3D/WeaponHolder").get_children():
		var weapon: SpellWeapon = child as SpellWeapon
		if weapon != null and weapon.data == spell:
			return weapon
	return null


## Casts once with the weapon drawn, ignoring the switch animation.
func _cast(spell: SpellData) -> void:
	var wand: SpellWeapon = _wand(spell)
	wand._is_drawn = true
	wand.set_trigger(true)
	wand._physics_process(1.0 / 60.0)
	wand.set_trigger(false)


func test_canon_costs() -> void:
	assert_eq(HEALING.ammo_cost, 20)
	assert_eq(HEALING.effect_amount, 10.0)
	assert_eq(ARMOR.ammo_cost, 75)
	assert_eq(ARMOR.effect_duration, 5.0)


func test_heal_restores_10_for_20_mana() -> void:
	_health.take_damage(30.0, Damage.Type.SLASH, null)
	var mana: int = _inventory.get_ammo(&"mana")
	_cast(HEALING)
	assert_eq(_health.current_health, _health.max_health - 20.0)
	assert_eq(_inventory.get_ammo(&"mana"), mana - 20)


func test_heal_at_full_health_spends_nothing() -> void:
	var mana: int = _inventory.get_ammo(&"mana")
	_cast(HEALING)
	assert_eq(_inventory.get_ammo(&"mana"), mana)


func test_heal_never_exceeds_max() -> void:
	_health.take_damage(4.0, Damage.Type.SLASH, null)
	_cast(HEALING)
	assert_eq(_health.current_health, _health.max_health)


func test_armor_blocks_all_damage_then_wears_off() -> void:
	_cast(ARMOR)
	assert_true(_player.is_invulnerable())
	_health.take_damage(50.0, Damage.Type.FIRE, null)
	assert_eq(_health.current_health, _health.max_health)
	var invulnerability: Invulnerability = _player.get_node("Invulnerability") as Invulnerability
	invulnerability.start(0.1)
	await wait_seconds(ARMOR_WAIT)
	assert_false(_player.is_invulnerable())
	_health.take_damage(50.0, Damage.Type.FIRE, null)
	assert_eq(_health.current_health, _health.max_health - 50.0)


func test_armor_costs_75_and_cannot_be_recast_while_active() -> void:
	_cast(ARMOR)
	assert_eq(_inventory.get_ammo(&"mana"), 100 - 75)
	_inventory.add_ammo(&"mana", 100)
	_wand(ARMOR)._cooldown_remaining = 0.0
	_cast(ARMOR)
	assert_eq(_inventory.get_ammo(&"mana"), 100, "second cast refused, nothing spent")


func test_armor_announces_start_warning_and_end() -> void:
	watch_signals(EventBus)
	_player.make_invulnerable(0.2)
	assert_signal_emitted_with_parameters(EventBus, "player_invulnerability_changed", [true])
	await wait_seconds(ARMOR_WAIT)
	assert_signal_emitted(EventBus, "player_invulnerability_ending")
	assert_signal_emitted_with_parameters(EventBus, "player_invulnerability_changed", [false])
