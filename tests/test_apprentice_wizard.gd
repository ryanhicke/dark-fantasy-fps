extends GutTest
## Apprentice wizard rules (docs/enemies.md): a ranged caster that shoots
## fireballs the player can learn to dodge.

const WIZARD_PATH: String = "res://enemies/apprentice_wizard/apprentice_wizard.tres"
const PLAYER_FIREBALL_PATH: String = "res://spells/fireball/fireball.tres"

var _wizard: EnemyData
var _player_fireball: SpellData


func before_all() -> void:
	_wizard = load(WIZARD_PATH) as EnemyData
	_player_fireball = load(PLAYER_FIREBALL_PATH) as SpellData


func test_shoots_fireballs() -> void:
	assert_true(_wizard.is_ranged())
	assert_eq(_wizard.projectile_scene, _player_fireball.projectile_scene, "same scene, so it's prewarmed")
	assert_eq(_wizard.attack_damage_type, Damage.Type.FIRE)


func test_fireball_is_dodgeable() -> void:
	assert_lt(_wizard.projectile_speed, _player_fireball.projectile_speed)
	assert_gt(_wizard.attack_windup, 0.5, "long telegraph")


func test_has_splash_but_never_hurts_itself() -> void:
	var spell: SpellData = _wizard.projectile_data as SpellData
	assert_not_null(spell)
	assert_gt(spell.splash_radius, 0.0)
	assert_eq(spell.caster_splash_scale, 0.0)
	assert_lt(spell.splash_damage, _player_fireball.splash_damage, "weaker than the player's")
