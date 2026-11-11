extends GutTest
## Pins the design rules for the Level 1-2 enemies (docs/enemies.md) and
## the damage-type split, so tuning can't silently break them.

const BANDIT_PATH: String = "res://enemies/bandit/bandit.tres"
const ARCHER_PATH: String = "res://enemies/bandit_archer/bandit_archer.tres"
const MERCENARY_PATH: String = "res://enemies/armored_mercenary/armored_mercenary.tres"
const SWORD_PATH: String = "res://weapons/sword/sword.tres"
const BOW_PATH: String = "res://weapons/bow/bow.tres"

var _bandit: EnemyData
var _archer: EnemyData
var _mercenary: EnemyData


func before_all() -> void:
	_bandit = load(BANDIT_PATH) as EnemyData
	_archer = load(ARCHER_PATH) as EnemyData
	_mercenary = load(MERCENARY_PATH) as EnemyData


func test_all_load() -> void:
	assert_not_null(_bandit)
	assert_not_null(_archer)
	assert_not_null(_mercenary)


func test_weapon_damage_types() -> void:
	assert_eq((load(SWORD_PATH) as WeaponData).damage_type, Damage.Type.SLASH)
	assert_eq((load(BOW_PATH) as WeaponData).damage_type, Damage.Type.PIERCE)


func test_only_archer_is_ranged() -> void:
	assert_false(_bandit.is_ranged())
	assert_true(_archer.is_ranged())
	assert_false(_mercenary.is_ranged())


func test_archer_shoots_from_beyond_melee_range() -> void:
	assert_gt(_archer.attack_range, _bandit.attack_range * 5.0)


func test_mercenary_slower_than_bandit() -> void:
	assert_lt(_mercenary.move_speed, _bandit.move_speed)


func test_mercenary_armor_resists_sword_and_bow_but_not_blunt() -> void:
	var armor: DamageResistances = _mercenary.resistances
	assert_not_null(armor)
	assert_lt(armor.multiplier_for(Damage.Type.SLASH), 1.0)
	assert_lt(armor.multiplier_for(Damage.Type.PIERCE), 1.0)
	assert_gt(armor.multiplier_for(Damage.Type.BLUNT), 1.0)
