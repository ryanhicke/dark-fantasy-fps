extends GutTest

const ARROWS: StringName = &"arrows"
const MAX_ARROWS: int = 100
const START_ARROWS: int = 50

var _inventory: Inventory


func before_each() -> void:
	_inventory = Inventory.new()
	_inventory.max_ammo = {ARROWS: MAX_ARROWS}
	_inventory.starting_ammo = {ARROWS: START_ARROWS}
	add_child_autofree(_inventory)
	watch_signals(_inventory)


func test_starts_with_starting_ammo() -> void:
	assert_eq(_inventory.get_ammo(ARROWS), START_ARROWS)
	assert_eq(_inventory.get_max_ammo(ARROWS), MAX_ARROWS)


func test_consume_spends_ammo_and_signals() -> void:
	assert_true(_inventory.consume_ammo(ARROWS, 1))
	assert_eq(_inventory.get_ammo(ARROWS), START_ARROWS - 1)
	assert_signal_emitted_with_parameters(_inventory, "ammo_changed", [ARROWS, START_ARROWS - 1, MAX_ARROWS])


func test_consume_fails_without_spending_when_short() -> void:
	assert_true(_inventory.consume_ammo(ARROWS, START_ARROWS))
	assert_false(_inventory.consume_ammo(ARROWS, 1))
	assert_eq(_inventory.get_ammo(ARROWS), 0)


func test_consume_rejects_negative_amount() -> void:
	assert_false(_inventory.consume_ammo(ARROWS, -5))
	assert_eq(_inventory.get_ammo(ARROWS), START_ARROWS)


func test_add_caps_at_max_and_reports_amount_added() -> void:
	assert_eq(_inventory.add_ammo(ARROWS, 80), MAX_ARROWS - START_ARROWS)
	assert_eq(_inventory.get_ammo(ARROWS), MAX_ARROWS)
	assert_eq(_inventory.add_ammo(ARROWS, 10), 0, "full inventory accepts nothing")


func test_unknown_ammo_type_is_empty_and_cannot_be_added() -> void:
	assert_eq(_inventory.get_ammo(&"mana_crystals"), 0)
	assert_false(_inventory.has_ammo(&"mana_crystals", 1))
	assert_eq(_inventory.add_ammo(&"mana_crystals", 5), 0)


func test_reset_restores_starting_ammo() -> void:
	_inventory.consume_ammo(ARROWS, 30)
	_inventory.reset_to_starting()
	assert_eq(_inventory.get_ammo(ARROWS), START_ARROWS)
