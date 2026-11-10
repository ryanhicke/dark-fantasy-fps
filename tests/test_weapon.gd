extends GutTest
## Cooldown and trigger gating in the Weapon base class.

const COOLDOWN: float = 0.5
const STEP: float = 0.1


## Minimal weapon that attacks whenever allowed while the trigger is held.
class AutoWeapon:
	extends Weapon
	var attack_count: int = 0

	func _tick(_delta: float) -> void:
		if _trigger_held and can_attack():
			_begin_cooldown()
			attack_count += 1


var _weapon: AutoWeapon


func before_each() -> void:
	_weapon = AutoWeapon.new()
	_weapon.data = WeaponData.new()
	_weapon.data.cooldown = COOLDOWN
	add_child_autofree(_weapon)
	# Skip the draw animation; it needs a ViewModel and real frames.
	_weapon._is_drawn = true
	watch_signals(_weapon)


func _step(seconds: float) -> void:
	var steps: int = roundi(seconds / STEP)
	for i: int in steps:
		_weapon._physics_process(STEP)


func test_attacks_immediately_when_trigger_pressed() -> void:
	_weapon.set_trigger(true)
	_step(STEP)
	assert_eq(_weapon.attack_count, 1)
	assert_signal_emit_count(_weapon, "attacked", 1)


func test_holding_trigger_waits_for_cooldown() -> void:
	_weapon.set_trigger(true)
	_step(0.3)
	assert_eq(_weapon.attack_count, 1, "no second attack inside cooldown")
	_step(0.3)
	assert_eq(_weapon.attack_count, 2, "second attack once cooldown ends")


func test_is_busy_during_cooldown_only() -> void:
	_weapon.set_trigger(true)
	_step(STEP)
	_weapon.set_trigger(false)
	assert_true(_weapon.is_busy())
	_step(COOLDOWN)
	assert_false(_weapon.is_busy())


func test_no_attack_while_holstered() -> void:
	_weapon.holster_immediately()
	_weapon.set_trigger(true)
	_step(STEP)
	assert_eq(_weapon.attack_count, 0)


func test_holster_clears_trigger() -> void:
	_weapon.set_trigger(true)
	_weapon.holster_immediately()
	assert_false(_weapon._trigger_held)
