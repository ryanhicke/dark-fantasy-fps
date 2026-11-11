extends GutTest
## Doom/Hexen damage feel (docs/enemies.md): enemies hit lightly so the
## player can tank crowds; werewolves are the exception and hit hard.

const PLAYER_HEALTH: float = 100.0
## Most a non-werewolf hit may take off a full-health player.
const LIGHT_HIT_CAP: float = 12.0
const WEREWOLF_PATH: String = "res://enemies/werewolf/werewolf.tres"
const ENEMY_PATHS: Array[String] = [
	"res://enemies/bandit/bandit.tres",
	"res://enemies/bandit_archer/bandit_archer.tres",
	"res://enemies/armored_mercenary/armored_mercenary.tres",
	"res://enemies/skeleton/skeleton.tres",
	"res://enemies/apprentice_wizard/apprentice_wizard.tres",
	"res://enemies/melee_demon/melee_demon.tres",
	"res://enemies/imp/imp.tres",
	"res://enemies/necromancer/necromancer.tres",
	"res://enemies/great_demon/great_demon_final.tres",
	"res://enemies/werewolf/disguised_bandit.tres",
	"res://enemies/werewolf/disguised_bandit_archer.tres",
	"res://enemies/werewolf/disguised_armored_mercenary.tres",
]


## Direct hit plus any splash, the worst one attack can do.
func _worst_hit(data: EnemyData) -> float:
	var total: float = data.attack_damage
	var spell: SpellData = data.projectile_data as SpellData
	if spell != null:
		total += spell.splash_damage
	return total


func test_non_werewolves_hit_lightly() -> void:
	for path: String in ENEMY_PATHS:
		var data: EnemyData = load(path) as EnemyData
		assert_lte(data.attack_damage, LIGHT_HIT_CAP, path)
		assert_lt(_worst_hit(data), PLAYER_HEALTH * 0.25, path)


func test_werewolves_hit_much_harder_than_anything_else() -> void:
	var werewolf: EnemyData = load(WEREWOLF_PATH) as EnemyData
	for path: String in ENEMY_PATHS:
		var data: EnemyData = load(path) as EnemyData
		assert_gte(werewolf.attack_damage, data.attack_damage * 1.8, path)
