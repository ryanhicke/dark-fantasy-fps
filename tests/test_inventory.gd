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


# --- Regen -------------------------------------------------------------------

const MANA: StringName = &"mana"
const MAX_MANA: int = 200
const MANA_REGEN: float = 2.0


func _setup_mana(start: int) -> void:
	_inventory.max_ammo = {ARROWS: MAX_ARROWS, MANA: MAX_MANA}
	_inventory.starting_ammo = {ARROWS: START_ARROWS, MANA: start}
	_inventory.regen_per_second = {MANA: MANA_REGEN}
	_inventory.reset_to_starting()
	# Stop the real physics tick so only the test drives regen.
	_inventory.set_physics_process(false)


func test_regen_adds_whole_points_over_time() -> void:
	_setup_mana(100)
	_inventory.regenerate(1.0)
	assert_eq(_inventory.get_ammo(MANA), 102)


func test_regen_accumulates_fractions_across_ticks() -> void:
	_setup_mana(100)
	for i: int in 60:
		_inventory.regenerate(1.0 / 60.0)
	# Float residue can leave the 2nd point a hair short; allow for it.
	assert_between(_inventory.get_ammo(MANA), 101, 102)
	_inventory.regenerate(0.1)
	assert_eq(_inventory.get_ammo(MANA), 102)


func test_regen_stops_at_max() -> void:
	_setup_mana(MAX_MANA - 1)
	_inventory.regenerate(10.0)
	assert_eq(_inventory.get_ammo(MANA), MAX_MANA)


func test_regen_does_not_touch_other_ammo() -> void:
	_setup_mana(100)
	_inventory.regenerate(5.0)
	assert_eq(_inventory.get_ammo(ARROWS), START_ARROWS)


func test_zero_regen_rate_disables_regen() -> void:
	_setup_mana(100)
	_inventory.regen_per_second = {MANA: 0.0}
	_inventory.regenerate(5.0)
	assert_eq(_inventory.get_ammo(MANA), 100)


func test_all_ammo_round_trips_into_a_fresh_inventory() -> void:
	_inventory.consume_ammo(ARROWS, 8)
	var saved: Dictionary[StringName, int] = _inventory.get_all_ammo()
	var other: Inventory = Inventory.new()
	other.max_ammo = {ARROWS: MAX_ARROWS}
	add_child_autofree(other)
	other.set_all_ammo(saved)
	assert_eq(other.get_ammo(ARROWS), START_ARROWS - 8)


func test_set_all_ammo_zeroes_missing_types_and_clamps() -> void:
	_inventory.set_all_ammo({} as Dictionary[StringName, int])
	assert_eq(_inventory.get_ammo(ARROWS), 0)
	_inventory.set_all_ammo({ARROWS: MAX_ARROWS + 50} as Dictionary[StringName, int])
	assert_eq(_inventory.get_ammo(ARROWS), MAX_ARROWS)
