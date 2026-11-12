extends GutTest
## Which sound an enemy's Voice plays for each event. Sounds are set on
## duplicates of the real data, never on the shared .tres resources.

const BANDIT_SCENE: PackedScene = preload("res://enemies/bandit/bandit.tscn")
const DISGUISED_SCENE: PackedScene = preload("res://enemies/werewolf/disguised_bandit.tscn")
## Revive delay plus collapse time, with slack (as in test_werewolf.gd).
const REVIVE_WAIT: float = 2.0
## Enemies on the Effects bus would go silent if this were Master.
const SCENES_WITH_VOICES: Array[String] = [
	"res://enemies/bandit/bandit.tscn",
	"res://enemies/bandit_archer/bandit_archer.tscn",
	"res://enemies/armored_mercenary/armored_mercenary.tscn",
	"res://enemies/werewolf/werewolf.tscn",
	"res://enemies/skeleton/skeleton.tscn",
	"res://enemies/apprentice_wizard/apprentice_wizard.tscn",
	"res://enemies/melee_demon/melee_demon.tscn",
	"res://enemies/imp/imp.tscn",
	"res://enemies/necromancer/necromancer.tscn",
	"res://enemies/great_demon/great_demon.tscn",
]


func _sound(label: String) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.resource_name = label
	return stream


## A bandit whose data carries one test sound per slot, and always staggers.
func _noisy_bandit() -> Enemy:
	var enemy: Enemy = BANDIT_SCENE.instantiate() as Enemy
	var data: EnemyData = enemy.data.duplicate() as EnemyData
	data.alert_sound = _sound("alert")
	data.attack_sound = _sound("attack")
	data.pain_sound = _sound("pain")
	data.death_sound = _sound("death")
	data.pain_chance = 1.0
	enemy.data = data
	add_child_autofree(enemy)
	return enemy


func _voice_of(enemy: Enemy) -> AudioStreamPlayer3D:
	return enemy.get_node("Voice") as AudioStreamPlayer3D


func test_every_enemy_voice_uses_the_effects_bus() -> void:
	for path: String in SCENES_WITH_VOICES:
		var enemy: Enemy = (load(path) as PackedScene).instantiate() as Enemy
		add_child_autofree(enemy)
		assert_eq(_voice_of(enemy).bus, AudioBuses.SFX, path)


func test_waking_plays_the_alert() -> void:
	var enemy: Enemy = _noisy_bandit()
	enemy.wake()
	assert_eq(_voice_of(enemy).stream, enemy.data.alert_sound)


func test_starting_an_attack_plays_the_attack_sound() -> void:
	var enemy: Enemy = _noisy_bandit()
	enemy.wake()
	# Awake, the player in reach and in sight: the brain starts a windup.
	enemy._brain.update(0.0, 0.5, true, true)
	assert_eq(enemy._brain.state, EnemyBrain.State.ATTACK)
	assert_eq(_voice_of(enemy).stream, enemy.data.attack_sound)


func test_a_stagger_plays_the_pain_sound() -> void:
	var enemy: Enemy = _noisy_bandit()
	HealthComponent.find_on(enemy).take_damage(1.0, Damage.Type.SLASH, null)
	assert_eq(enemy._brain.state, EnemyBrain.State.PAIN)
	assert_eq(_voice_of(enemy).stream, enemy.data.pain_sound)


func test_a_hit_without_a_stagger_plays_no_pain_sound() -> void:
	var enemy: Enemy = _noisy_bandit()
	enemy.data.pain_chance = 0.0
	enemy._apply_data()
	HealthComponent.find_on(enemy).take_damage(1.0, Damage.Type.SLASH, null)
	assert_ne(_voice_of(enemy).stream, enemy.data.pain_sound)


func test_dying_plays_the_death_sound() -> void:
	var enemy: Enemy = _noisy_bandit()
	HealthComponent.find_on(enemy).take_damage(10000.0, Damage.Type.SLASH, null)
	assert_eq(_voice_of(enemy).stream, enemy.data.death_sound)


func test_missing_sounds_are_silent() -> void:
	var enemy: Enemy = BANDIT_SCENE.instantiate() as Enemy
	var data: EnemyData = enemy.data.duplicate() as EnemyData
	data.alert_sound = null
	enemy.data = data
	add_child_autofree(enemy)
	enemy.wake()
	assert_null(_voice_of(enemy).stream)


func test_disguised_enemy_dies_as_a_human_and_howls_as_it_rises() -> void:
	var enemy: Enemy = DISGUISED_SCENE.instantiate() as Enemy
	var disguise: EnemyData = enemy.data.duplicate() as EnemyData
	var wolf: EnemyData = disguise.revive_as.duplicate() as EnemyData
	disguise.death_sound = _sound("human death")
	wolf.alert_sound = _sound("howl")
	disguise.revive_as = wolf
	enemy.data = disguise
	add_child_autofree(enemy)
	HealthComponent.find_on(enemy).take_damage(10000.0, Damage.Type.SLASH, null)
	assert_eq(_voice_of(enemy).stream, disguise.death_sound)
	await wait_seconds(REVIVE_WAIT)
	assert_eq(enemy.data, wolf)
	assert_eq(_voice_of(enemy).stream, wolf.alert_sound)
